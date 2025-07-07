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

-- -------------------------
-- Constants and Configuration
-- -------------------------

local MIN_CHARACTER_SEARCH = 3

-- -------------------------
-- Event Search Operations
-- -------------------------

--[[
    Search for events within a given year range
    @param yearStart [integer] Start year for search
    @param yearEnd [integer] End year for search
    @return [table] Array of found events
]]
function SearchEngine.searchEvents(yearStart, yearEnd)
    if not yearStart or not yearEnd then
        return {}
    end

    local foundEvents = {}
    if yearStart > yearEnd then
        return foundEvents
    end
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return foundEvents
    end
    for collectionName, eventsGroup in pairs(chronicles.Data.Events) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive and eventsGroup and eventsGroup.data then
            local pluginEvents = SearchEngine.searchEventsInDB(yearStart, yearEnd, eventsGroup.data)

            for _, event in pairs(pluginEvents) do
                local cleanEvent = SearchEngine.cleanEventObject(event, collectionName)
                if cleanEvent then
                    table.insert(foundEvents, cleanEvent)
                end
            end
        end
    end

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
    @param collectionName [string] Source collection name
    @return [table] Cleaned event object
]]
function SearchEngine.cleanEventObject(event, collectionName)
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
        source = collectionName,
        order = event.order or 0,
        author = event.author,
        timeline = event.timeline
    }

    return cleanEvent
end

--[[
    Find a single event by ID and collection name
    @param eventId [number] Event ID to find
    @param collectionName [string] Collection name to search in
    @return [table|nil] Found event or nil if not found
]]
function SearchEngine.findEventByIdAndCollection(eventId, collectionName)
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return nil
    end

    local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)
    if not isCollectionActive then
        return nil
    end

    local eventsGroup = chronicles.Data.Events[collectionName]
    if not eventsGroup or not eventsGroup.data then
        return nil
    end

    for _, event in pairs(eventsGroup.data) do
        if event and event.id == eventId then
            return SearchEngine.cleanEventObject(event, collectionName)
        end
    end

    return nil
end

-- -------------------------
-- Faction Search Operations
-- -------------------------

--[[
    Find a single faction by ID and collection name
    @param factionId [number] Faction ID to find
    @param collectionName [string] Collection name to search in
    @return [table|nil] Found faction or nil if not found
]]
function SearchEngine.findFactionByIdAndCollection(factionId, collectionName)
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return nil
    end

    local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)
    if not isCollectionActive then
        return nil
    end

    local factionsGroup = chronicles.Data.Factions[collectionName]
    if not factionsGroup or not factionsGroup.data then
        return nil
    end

    for _, faction in pairs(factionsGroup.data) do
        if faction and faction.id == factionId then
            return SearchEngine.cleanFactionObject(faction, collectionName)
        end
    end

    return nil
end

--[[
    Search for factions by name
    @param name [string] Faction name to search for (optional)
    @return [table] Array of found factions
]]
function SearchEngine.searchFactions(name)
    local foundFactions = {}
    local searchTerm = name and string.lower(name) or nil
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return foundFactions
    end

    for collectionName, factionsGroup in pairs(chronicles.Data.Factions) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive and factionsGroup and factionsGroup.data then
            for _, faction in pairs(factionsGroup.data) do
                if SearchEngine.matchesFactionSearch(faction, searchTerm) then
                    local cleanFaction = SearchEngine.cleanFactionObject(faction, collectionName)
                    if cleanFaction then
                        table.insert(foundFactions, cleanFaction)
                    end
                end
            end
        end
    end

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

    if not searchTerm then
        return true
    end

    if string.len(searchTerm) < MIN_CHARACTER_SEARCH then
        return true
    end

    local factionName = string.lower(faction.name)
    return string.find(factionName, searchTerm) ~= nil
end

--[[
    Find factions by their IDs across collections
    @param ids [table] Table mapping collection names to arrays of faction IDs
    @return [table] Array of found factions
]]
function SearchEngine.findFactions(ids)
    local foundFactions = {}
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return foundFactions
    end

    for collectionName, factionIds in pairs(ids) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive then
            local factionsGroup = chronicles.Data.Factions[collectionName]

            if factionsGroup and factionsGroup.data and #factionsGroup.data > 0 then
                for _, faction in pairs(factionsGroup.data) do
                    for _, targetId in ipairs(factionIds) do
                        if faction.id == targetId then
                            local cleanFaction = SearchEngine.cleanFactionObject(faction, collectionName)
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
    @param collectionName [string] Source collection name
    @return [table] Cleaned faction object
]]
function SearchEngine.cleanFactionObject(faction, collectionName)
    if not faction then
        return nil
    end

    return {
        id = faction.id,
        name = faction.name,
        chapters = faction.chapters,
        timeline = faction.timeline,
        author = faction.author,
        description = faction.description,
        image = faction.image,
        source = collectionName
    }
end

-- -------------------------
-- Character Search Operations
-- -------------------------

--[[
    Find a single character by ID and collection name
    @param characterId [number] Character ID to find
    @param collectionName [string] Collection name to search in
    @return [table|nil] Found character or nil if not found
]]
function SearchEngine.findCharacterByIdAndCollection(characterId, collectionName)
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return nil
    end

    local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)
    if not isCollectionActive then
        return nil
    end

    local charactersGroup = chronicles.Data.Characters[collectionName]
    if not charactersGroup or not charactersGroup.data then
        return nil
    end

    for _, character in pairs(charactersGroup.data) do
        if character and character.id == characterId then
            return SearchEngine.cleanCharacterObject(character, collectionName)
        end
    end

    return nil
end

--[[
    Search for characters by name
    @param name [string] Character name to search for (optional)
    @return [table] Array of found characters
]]
function SearchEngine.searchCharacters(name)
    local foundCharacters = {}
    local searchTerm = name and string.lower(name) or nil
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return foundCharacters
    end

    for collectionName, charactersGroup in pairs(chronicles.Data.Characters) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive and charactersGroup and charactersGroup.data then
            for _, character in pairs(charactersGroup.data) do
                if SearchEngine.matchesCharacterSearch(character, searchTerm) then
                    local cleanCharacter = SearchEngine.cleanCharacterObject(character, collectionName)
                    if cleanCharacter then
                        table.insert(foundCharacters, cleanCharacter)
                    end
                end
            end
        end
    end

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

    if not searchTerm then
        return true
    end

    if string.len(searchTerm) < MIN_CHARACTER_SEARCH then
        return true
    end

    local characterName = string.lower(character.name)
    return string.find(characterName, searchTerm) ~= nil
end

--[[
    Find characters by their IDs across collections
    @param ids [table] Table mapping collection names to arrays of character IDs
    @return [table] Array of found characters
]]
function SearchEngine.findCharacters(ids)
    local foundCharacters = {}
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        return foundCharacters
    end

    for collectionName, characterIds in pairs(ids) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive then
            local charactersGroup = chronicles.Data.Characters[collectionName]

            if charactersGroup and charactersGroup.data and #charactersGroup.data > 0 then
                for _, character in pairs(charactersGroup.data) do
                    for _, targetId in ipairs(characterIds) do
                        if character.id == targetId then
                            local cleanCharacter = SearchEngine.cleanCharacterObject(character, collectionName)
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
    @param collectionName [string] Source collection name
    @return [table] Cleaned character object
]]
function SearchEngine.cleanCharacterObject(character, collectionName)
    if not character then
        return nil
    end

    return {
        id = character.id,
        name = character.name,
        chapters = character.chapters,
        timeline = character.timeline,
        factions = character.factions or {},
        author = character.author,
        description = character.description,
        image = character.image,
        source = collectionName
    }
end

-- -------------------------
-- Utility Functions
-- -------------------------

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
        return false
    end

    for collectionName, eventsGroup in pairs(chronicles.Data.Events) do
        local isCollectionActive = chronicles.Data:GetCollectionStatus(collectionName)

        if isCollectionActive and eventsGroup and eventsGroup.data then
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

-- -------------------------
-- Module Initialization
-- -------------------------

function SearchEngine.init()
    -- SearchEngine module initialized
end

-- Auto-initialize when module is loaded
SearchEngine.init()
