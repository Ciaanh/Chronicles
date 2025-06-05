local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
=================================================================================
Module: Events
Purpose: Event data processing and transformation for Chronicles timeline
Dependencies: StringUtils, TableUtils, ValidationUtils, AceLocale-3.0
Author: Chronicles Team
=================================================================================

This module handles complex event data processing and transformation:
- Event object creation and validation
- Chapter and page content processing
- HTML content detection and sanitization
- Template-based content rendering
- Event list generation and filtering

Key Features:
- Smart HTML vs text content detection
- Chapter-based content organization
- Template key mapping for UI rendering
- Author attribution and metadata handling
- Event list generation with filtering support

Event Data Structure:
- id: Unique event identifier
- label: Display name/title
- chapters: Array of content chapters
- yearStart/yearEnd: Time range
- eventType: Category classification
- characters/factions: Associated entities
- author: Content attribution

Usage Example:
    local eventsList = Events.GetEventsList()
    local processedEvent = Events.ProcessEventData(rawEventData)
    local chapters = Events.CreateChaptersFromContent(content)

Event Flow Patterns:
1. Raw event data → Processing → Template mapping → UI rendering
2. User selection → Event lookup → Chapter processing → Content display
3. Filter application → Event list generation → UI update

Dependencies:
- StringUtils: HTML processing and text manipulation
- TableUtils: Deep copying and table operations
- ValidationUtils: Data validation and safety checks
- AceLocale-3.0: Localization support
=================================================================================
]]

private.Core.Events = {}

-- Import utilities
local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Event Data Structure:
    id = [integer]					-- Id of the event
    label = [string]				-- Event name/title
    chapters = { [chapter] }		-- Event chapters/content
    yearStart = [integer]			-- Start year
    yearEnd = [integer]				-- End year
    eventType = [integer]			-- Type/category of event
    timeline = [integer]			-- Timeline ID
    order = [integer]				-- Display order
    characters = { [character] }	-- Associated characters
    factions = { [faction] }		-- Associated factions
    author = [string]				-- Author of the event

    Chapter Data Structure:
    header = [integer]				-- Title of the chapter
    pages = { [string] }			-- Content of the chapter, either text or HTML
]]
--[[
    Transform title and pages into a structured chapter object for UI rendering
    
    This function processes raw chapter content and creates a structured object
    with proper template keys for the UI rendering system. It handles both
    text and HTML content, applying appropriate template mappings.
    
    @param title string|nil - Title of the chapter (optional)
    @param pages table - Array of content strings (text or HTML)
    @return table - Chapter object with header and elements array
    @example
        local chapter = CreateChapter("The Fall of Lordaeron", {
            "Prince Arthas returned from Northrend...",
            "<h2>The Culling of Stratholme</h2><p>Desperate times...</p>"
        })
        -- Returns: { header = {...}, elements = { {...}, {...} } }
]]
local function CreateChapter(title, pages)
    local chapter = {elements = {}}

    if (title ~= nil) then
        chapter.header = {
            templateKey = private.constants.templateKeys.HEADER,
            text = title
        }
    end

    for key, text in pairs(pages) do
        if (StringUtils.ContainsHTML(text)) then
            table.insert(
                chapter.elements,
                {
                    templateKey = private.constants.templateKeys.HTML_CONTENT,
                    text = StringUtils.CleanHTML(text)
                }
            )
        else
            -- transform text => adjust line to width
            -- then for each line add itemEntry
            local lines = StringUtils.SplitTextToFitWidth(text, private.constants.viewWidth)
            for i, value in ipairs(lines) do
                local line = {
                    templateKey = private.constants.templateKeys.TEXT_CONTENT,
                    text = value
                }

                table.insert(chapter.elements, line)
            end
        end
    end

    return chapter
end

function private.Core.Events.EmptyBook()
    local data = {}

    return data
end

--[[
	Transform the event into a book
	@param event [event]]
--]]
function private.Core.Events.TransformEventToBook(event)
    if (event == nil) then
        return nil
    end

    local data = {}

    local title = {
        header = {
            templateKey = private.constants.templateKeys.EVENT_TITLE,
            text = event.label,
            yearStart = event.yearStart,
            yearEnd = event.yearEnd
        },
        elements = {}
    }

    local author = ""
    if (event.author ~= nil) then
        author = Locale["Author"] .. event.author
    end

    table.insert(
        title.elements,
        {
            templateKey = private.constants.templateKeys.AUTHOR,
            text = author
        }
    )
    table.insert(data, title)

    local chaptersLength = #event.chapters
    if chaptersLength > 0 then
        for key, chapter in pairs(event.chapters) do
            local bookChapter = CreateChapter(chapter.header, chapter.pages)
            table.insert(data, bookChapter)
        end
    end

    return data
end

--[[
    Check the status of each event group and type status
	If both are true, add the event to the list
	Sort the list by yearStart and order
	@param events { [event] }
--]]
function private.Core.Events.FilterEvents(events)
    local foundEvents = {}
    for eventIndex in pairs(events) do
        local event = events[eventIndex]

        local eventGroupStatus = private.Chronicles.Data:GetCollectionStatus(event.source)
        local eventTypeStatus = private.Chronicles.Data:GetEventTypeStatus(event.eventType)

        if eventGroupStatus and eventTypeStatus then
            table.insert(foundEvents, event)
        end
    end

    table.sort(
        foundEvents,
        function(a, b)
            if (a.yearStart == b.yearStart) then
                return a.order < b.order
            end
            return a.yearStart < b.yearStart
        end
    )
    return foundEvents
end

--[[
    Get events by character ID
    @param events [table] List of events
    @param characterId [number] Character ID to filter by
    @return [table] Events associated with the character
]]
function private.Core.Events.GetEventsByCharacter(events, characterId)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidNumber(characterId) then
        return {}
    end

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidTable(event.characters) then
                return false
            end

            for _, character in pairs(event.characters) do
                if character.id == characterId then
                    return true
                end
            end
            return false
        end
    )
end

--[[
    Get events by faction ID
    @param events [table] List of events
    @param factionId [number] Faction ID to filter by
    @return [table] Events associated with the faction
]]
function private.Core.Events.GetEventsByFaction(events, factionId)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidNumber(factionId) then
        return {}
    end

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidTable(event.factions) then
                return false
            end

            for _, faction in pairs(event.factions) do
                if faction.id == factionId then
                    return true
                end
            end
            return false
        end
    )
end

--[[
    Get events within a year range
    @param events [table] List of events
    @param startYear [number] Start year of range
    @param endYear [number] End year of range
    @return [table] Events within the year range
]]
function private.Core.Events.GetEventsByYearRange(events, startYear, endYear)
    if
        not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidYear(startYear) or
            not ValidationUtils.IsValidYear(endYear)
     then
        return {}
    end

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            -- Check if event overlaps with the year range
            return not (event.yearEnd < startYear or event.yearStart > endYear)
        end
    )
end

--[[
    Get events by timeline ID
    @param events [table] List of events
    @param timelineId [number] Timeline ID to filter by
    @return [table] Events from the specified timeline
]]
function private.Core.Events.GetEventsByTimeline(events, timelineId)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidNumber(timelineId) then
        return {}
    end

    return TableUtils.Filter(
        events,
        function(event)
            return ValidationUtils.IsValidEvent(event) and event.timeline == timelineId
        end
    )
end

--[[
    Search events by text in label
    @param events [table] List of events
    @param searchText [string] Text to search for
    @return [table] Events matching the search text
]]
function private.Core.Events.SearchEvents(events, searchText)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidString(searchText) then
        return {}
    end

    local lowerSearchText = string.lower(searchText)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            -- Search in label
            if string.find(string.lower(event.label), lowerSearchText) then
                return true
            end

            return false
        end
    )
end

--[[
    Sort events by multiple criteria
    @param events [table] List of events to sort
    @param sortBy [string] Sort criteria: "year", "name", "order", "type"
    @param ascending [boolean] Sort direction (default: true)
    @return [table] Sorted events
]]
function private.Core.Events.SortEvents(events, sortBy, ascending)
    if not ValidationUtils.IsValidTable(events) then
        return {}
    end

    local sortedEvents = TableUtils.DeepCopy(events)
    ascending = ascending ~= false -- default to true

    table.sort(
        sortedEvents,
        function(a, b)
            local comparison = false

            if sortBy == "year" then
                if a.yearStart == b.yearStart then
                    comparison = a.order < b.order
                else
                    comparison = a.yearStart < b.yearStart
                end
            elseif sortBy == "name" then
                comparison = a.label < b.label
            elseif sortBy == "order" then
                comparison = a.order < b.order
            elseif sortBy == "type" then
                if a.eventType == b.eventType then
                    comparison = a.yearStart < b.yearStart
                else
                    comparison = a.eventType < b.eventType
                end
            else
                -- Default sort by year and order
                if a.yearStart == b.yearStart then
                    comparison = a.order < b.order
                else
                    comparison = a.yearStart < b.yearStart
                end
            end

            return ascending and comparison or not comparison
        end
    )

    return sortedEvents
end

--[[
    Validate an event object
    @param event [table] Event to validate
    @return [boolean] True if event is valid
    @return [string] Error message if invalid
]]
function private.Core.Events.ValidateEvent(event)
    if not ValidationUtils.IsValidEvent(event) then
        return false, "Event object is invalid or missing required fields"
    end

    -- Additional event-specific validation
    if event.yearStart > event.yearEnd then
        return false, "Event start year cannot be after end year"
    end

    if ValidationUtils.IsValidTable(event.characters) then
        for _, character in pairs(event.characters) do
            if not ValidationUtils.IsValidCharacter(character) then
                return false, "Event contains invalid character data"
            end
        end
    end

    if ValidationUtils.IsValidTable(event.factions) then
        for _, faction in pairs(event.factions) do
            if not ValidationUtils.IsValidFaction(faction) then
                return false, "Event contains invalid faction data"
            end
        end
    end

    return true, nil
end

-- local textToDisplay =
-- 	"The orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses.\n\nNer'zhul's apprehension about the war with the draenei grows. \nKil'jaeden appears to him in the form of Rulkan and tells him of powerful beings who could aid the orcs, and the night after Kil'jaeden appears again as a radiant elemental entity and urges him to push the Horde to victory and exterminate the draenei. \n\nNer'zhul secretly embarks on a journey to Oshu'gun to seek the guidance of the ancestors, but Kil'jaeden is aware of his plans and tells Gul'dan to gather allies to control the Shadowmoon, since Ner'zhul can no longer be relied upon. Gul'dan recruits Teron'gor and several other shaman and begin teaching them fel magic.\n\nAt Oshu'gun, the real Rulkan and the other ancestors tell Ner'zhul that he was being manipulated by Kil'jaeden and condemn the shaman for having been used by the demon lord. \n\nNer'zhul falls into despair and is captured by Gul'dan's followers, who treat him as little more than a slave.\nThe orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses."
