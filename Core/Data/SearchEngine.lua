local FOLDER_NAME, private = ...

-- Initialize SearchEngine module with proper namespace creation
if not private.Core then
    private.Core = {}
end
if not private.Core.Data then
    private.Core.Data = {}
end
private.Core.Data.SearchEngine = {}

local SearchEngine = private.Core.Data.SearchEngine

-----------------------------------------------------------------------------------------
-- Constants and Configuration ---------------------------------------------------------
-----------------------------------------------------------------------------------------

local MIN_CHARACTER_SEARCH = 3

-----------------------------------------------------------------------------------------
-- Event Search Operations --------------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Search for events within a given year range
    @param yearStart [integer] Start year for search
    @param yearEnd [integer] End year for search
    @return [table] Array of found events
]]
function SearchEngine.searchEvents(yearStart, yearEnd)
    -- Validate input parameters
    if not yearStart or not yearEnd then
        private.Core.Logger.warn("SearchEngine", "Invalid parameters: yearStart and yearEnd must not be nil")
        return {}
    end

    private.Core.Logger.trace(
        "SearchEngine",
        "Searching events from " .. tostring(yearStart) .. " to " .. tostring(yearEnd)
    )

    local foundEvents = {}
    if yearStart > yearEnd then
        private.Core.Logger.warn("SearchEngine", "Invalid date range: start year is after end year")
        return foundEvents
    end
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when searching events")
        return foundEvents
    end
    for libraryName, eventsGroup in pairs(chronicles.Data.Events) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        private.Core.Logger.trace(
            "SearchEngine",
            "Checking library: " .. libraryName .. " (active: " .. tostring(isLibraryActive) .. ")"
        )

        if isLibraryActive and eventsGroup and eventsGroup.data then
            local pluginEvents = SearchEngine.searchEventsInDB(yearStart, yearEnd, eventsGroup.data)

            for _, event in pairs(pluginEvents) do
                local cleanEvent = SearchEngine.cleanEventObject(event, libraryName)
                if cleanEvent then
                    table.insert(foundEvents, cleanEvent)
                end
            end
        end
    end

    private.Core.Logger.trace("SearchEngine", "Found " .. #foundEvents .. " events in range")
    return foundEvents
end

--[[
    Search for events within a specific database
    @param yearStart [integer] Start year for search
    @param yearEnd [integer] End year for search
    @param db [table] Database to search in
    @return [table] Array of found events
]]
function SearchEngine.searchEventsInDB(yearStart, yearEnd, db)
    local foundEvents = {}
    if not db then
        return foundEvents
    end
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when searching events in DB")
        return foundEvents
    end

    for _, event in pairs(db) do
        if event then
            local isEventTypeActive = chronicles.Data:GetEventTypeStatus(event.eventType)

            if isEventTypeActive and SearchEngine.isEventInRange(event, yearStart, yearEnd) then
                table.insert(foundEvents, event)
            end
        end
    end

    return foundEvents
end

--[[
    Check if an event falls within the specified year range
    @param event [table] Event object to check
    @param yearStart [integer] Start year of range
    @param yearEnd [integer] End year of range
    @return [boolean] True if event is in range
]]
function SearchEngine.isEventInRange(event, yearStart, yearEnd)
    if not event or not event.yearStart or not event.yearEnd then
        return false
    end

    -- Event starts within range
    if yearStart <= event.yearStart and event.yearStart <= yearEnd then
        return true
    end

    -- Event ends within range
    if yearStart <= event.yearEnd and event.yearEnd <= yearEnd then
        return true
    end

    -- Single year search: event spans the target year
    if yearStart == yearEnd then
        if event.yearStart <= yearStart and yearStart <= event.yearEnd then
            return true
        end
    end

    return false
end

--[[
    Clean and format an event object for consumption
    @param event [table] Raw event object
    @param libraryName [string] Source library name
    @return [table] Cleaned event object
]]
function SearchEngine.cleanEventObject(event, libraryName)
    if not event then
        return nil
    end

    local cleanEvent = {
        id = event.id,
        label = event.label,
        yearStart = event.yearStart,
        yearEnd = event.yearEnd,
        chapters = event.chapters or {},
        eventType = event.eventType,
        factions = event.factions or {},
        characters = event.characters or {},
        source = libraryName,
        order = event.order or 0,
        author = event.author,
        timeline = event.timeline
    }

    return cleanEvent
end

-----------------------------------------------------------------------------------------
-- Faction Search Operations -----------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Search for factions by name
    @param name [string] Faction name to search for (optional)
    @return [table] Array of found factions
]]
function SearchEngine.searchFactions(name)
    private.Core.Logger.trace("SearchEngine", "Searching factions with name: " .. tostring(name or "all"))

    local foundFactions = {}
    local searchTerm = name and string.lower(name) or nil
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when searching factions")
        return foundFactions
    end

    for libraryName, factionsGroup in pairs(chronicles.Data.Factions) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        if isLibraryActive and factionsGroup and factionsGroup.data then
            for _, faction in pairs(factionsGroup.data) do
                if SearchEngine.matchesFactionSearch(faction, searchTerm) then
                    local cleanFaction = SearchEngine.cleanFactionObject(faction, libraryName)
                    if cleanFaction then
                        table.insert(foundFactions, cleanFaction)
                    end
                end
            end
        end
    end

    private.Core.Logger.trace("SearchEngine", "Found " .. #foundFactions .. " factions")
    return foundFactions
end

--[[
    Check if a faction matches the search criteria
    @param faction [table] Faction object to check
    @param searchTerm [string] Lowercase search term (optional)
    @return [boolean] True if faction matches search
]]
function SearchEngine.matchesFactionSearch(faction, searchTerm)
    if not faction or not faction.name then
        return false
    end

    -- If no search term, include all factions
    if not searchTerm then
        return true
    end

    -- Require minimum characters for search
    if string.len(searchTerm) < MIN_CHARACTER_SEARCH then
        return true -- Return all if search term too short
    end

    -- Check if faction name contains search term
    local factionName = string.lower(faction.name)
    return string.find(factionName, searchTerm) ~= nil
end

--[[
    Find factions by their IDs across libraries
    @param ids [table] Table mapping library names to arrays of faction IDs
    @return [table] Array of found factions
]]
function SearchEngine.findFactions(ids)
    private.Core.Logger.trace("SearchEngine", "Finding factions by IDs")

    local foundFactions = {}
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when finding factions")
        return foundFactions
    end

    for libraryName, factionIds in pairs(ids) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        if isLibraryActive then
            local factionsGroup = chronicles.Data.Factions[libraryName]

            if factionsGroup and factionsGroup.data and #factionsGroup.data > 0 then
                for _, faction in pairs(factionsGroup.data) do
                    for _, targetId in ipairs(factionIds) do
                        if faction.id == targetId then
                            local cleanFaction = SearchEngine.cleanFactionObject(faction, libraryName)
                            if cleanFaction then
                                table.insert(foundFactions, cleanFaction)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    return foundFactions
end

--[[
    Clean and format a faction object for consumption
    @param faction [table] Raw faction object
    @param libraryName [string] Source library name
    @return [table] Cleaned faction object
]]
function SearchEngine.cleanFactionObject(faction, libraryName)
    if not faction then
        return nil
    end

    -- Convert string description to chapter structure if needed
    local chapters = faction.chapters
    if not chapters and faction.description and type(faction.description) == "string" then
        chapters = {
            {
                header = faction.name,
                pages = {faction.description}
            }
        }
    end

    return {
        id = faction.id,
        name = faction.name,
        description = faction.description,
        chapters = chapters,
        timeline = faction.timeline,
        source = libraryName
    }
end

-----------------------------------------------------------------------------------------
-- Character Search Operations ---------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Search for characters by name
    @param name [string] Character name to search for (optional)
    @return [table] Array of found characters
]]
function SearchEngine.searchCharacters(name)
    private.Core.Logger.trace("SearchEngine", "Searching characters with name: " .. tostring(name or "all"))
    local foundCharacters = {}
    local searchTerm = name and string.lower(name) or nil
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when searching characters")
        return foundCharacters
    end

    for libraryName, charactersGroup in pairs(chronicles.Data.Characters) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        if isLibraryActive and charactersGroup and charactersGroup.data then
            for _, character in pairs(charactersGroup.data) do
                if SearchEngine.matchesCharacterSearch(character, searchTerm) then
                    local cleanCharacter = SearchEngine.cleanCharacterObject(character, libraryName)
                    if cleanCharacter then
                        table.insert(foundCharacters, cleanCharacter)
                    end
                end
            end
        end
    end

    private.Core.Logger.trace("SearchEngine", "Found " .. #foundCharacters .. " characters")
    return foundCharacters
end

--[[
    Check if a character matches the search criteria
    @param character [table] Character object to check
    @param searchTerm [string] Lowercase search term (optional)
    @return [boolean] True if character matches search
]]
function SearchEngine.matchesCharacterSearch(character, searchTerm)
    if not character or not character.name then
        return false
    end

    -- If no search term, include all characters
    if not searchTerm then
        return true
    end

    -- Require minimum characters for search
    if string.len(searchTerm) < MIN_CHARACTER_SEARCH then
        return true -- Return all if search term too short
    end

    -- Check if character name contains search term
    local characterName = string.lower(character.name)
    return string.find(characterName, searchTerm) ~= nil
end

--[[
    Find characters by their IDs across libraries
    @param ids [table] Table mapping library names to arrays of character IDs
    @return [table] Array of found characters
]]
function SearchEngine.findCharacters(ids)
    private.Core.Logger.trace("SearchEngine", "Finding characters by IDs")

    local foundCharacters = {}
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when finding characters")
        return foundCharacters
    end

    for libraryName, characterIds in pairs(ids) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        if isLibraryActive then
            local charactersGroup = chronicles.Data.Characters[libraryName]

            if charactersGroup and charactersGroup.data and #charactersGroup.data > 0 then
                for _, character in pairs(charactersGroup.data) do
                    for _, targetId in ipairs(characterIds) do
                        if character.id == targetId then
                            local cleanCharacter = SearchEngine.cleanCharacterObject(character, libraryName)
                            if cleanCharacter then
                                table.insert(foundCharacters, cleanCharacter)
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    return foundCharacters
end

--[[
    Clean and format a character object for consumption
    @param character [table] Raw character object
    @param libraryName [string] Source library name
    @return [table] Cleaned character object
]]
function SearchEngine.cleanCharacterObject(character, libraryName)
    if not character then
        return nil
    end

    -- Convert string description to chapter structure if needed
    local chapters = character.chapters
    if not chapters and character.description and type(character.description) == "string" then
        chapters = {
            {
                header = character.name,
                pages = {character.description}
            }
        }
    end

    return {
        id = character.id,
        name = character.name,
        description = character.description,
        chapters = chapters,
        timeline = character.timeline,
        factions = character.factions or {},
        source = libraryName
    }
end

-----------------------------------------------------------------------------------------
-- Utility Functions -------------------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Check if there are any events in the specified year range
    @param yearStart [integer] Start year of range
    @param yearEnd [integer] End year of range
    @return [boolean] True if events exist in range
]]
function SearchEngine.hasEvents(yearStart, yearEnd)
    if yearStart > yearEnd then
        return false
    end
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("SearchEngine", "Chronicles.Data not initialized when checking for events")
        return false
    end

    for libraryName, eventsGroup in pairs(chronicles.Data.Events) do
        local isLibraryActive = chronicles.Data:GetLibraryStatus(libraryName)

        if isLibraryActive and eventsGroup and eventsGroup.data then
            if SearchEngine.hasEventsInDB(yearStart, yearEnd, eventsGroup.data) then
                return true
            end
        end
    end

    return false
end

--[[
    Check if there are any events in a specific database within the year range
    @param yearStart [integer] Start year of range
    @param yearEnd [integer] End year of range
    @param db [table] Database to check
    @return [boolean] True if events exist in range
]]
function SearchEngine.hasEventsInDB(yearStart, yearEnd, db)
    if not db then
        return false
    end
    for _, event in pairs(db) do
        if event then
            local isEventTypeActive =
                private.Core.Utils.HelperUtils.getChronicles().Data:GetEventTypeStatus(event.eventType)

            if isEventTypeActive and SearchEngine.isEventInRange(event, yearStart, yearEnd) then
                return true
            end
        end
    end

    return false
end

-----------------------------------------------------------------------------------------
-- Module Initialization ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

function SearchEngine.init()
    private.Core.Logger.trace("SearchEngine", "SearchEngine module initialized")
end

-- Auto-initialize when module is loaded
SearchEngine.init()
