local FOLDER_NAME, private = ...

private.Core.Business = private.Core.Business or {}
private.Core.Business.FilterEngine = {}

local FilterEngine = private.Core.Business.FilterEngine

-- Note: Utilities are accessed as globals since they're loaded before this module

--[[
    Filter Configuration Structure:
    {
        yearRange = {
            enabled = [boolean],
            startYear = [number],
            endYear = [number]
        },
        eventTypes = {
            enabled = [boolean],
            allowedTypes = { [number] }  -- Array of event type IDs
        },
        collections = {
            enabled = [boolean],
            allowedCollections = { [string] }  -- Array of collection names
        },
        timelines = {
            enabled = [boolean],
            allowedTimelines = { [number] }  -- Array of timeline IDs
        },
        characters = {
            enabled = [boolean],
            allowedCharacters = { [number] }  -- Array of character IDs
        },
        factions = {
            enabled = [boolean],
            allowedFactions = { [number] }  -- Array of faction IDs
        },
        search = {
            enabled = [boolean],
            searchText = [string],
            searchFields = { [string] }  -- Fields to search: "label", etc.
        }
    }
]]
--[[
    Apply filters to a list of events
    @param events [table] List of events to filter
    @param filters [table] Filter configuration
    @return [table] Filtered events
]]
function FilterEngine.ApplyFilters(events, filters)
    if not ValidationUtils.IsValidTable(events) then
        return {}
    end

    if not ValidationUtils.IsValidTable(filters) then
        return events
    end

    local filteredEvents = events

    -- Apply year range filter
    if filters.yearRange and filters.yearRange.enabled then
        filteredEvents =
            FilterEngine.FilterByYearRange(filteredEvents, filters.yearRange.startYear, filters.yearRange.endYear)
    end

    -- Apply event type filter
    if filters.eventTypes and filters.eventTypes.enabled then
        filteredEvents = FilterEngine.FilterByEventTypes(filteredEvents, filters.eventTypes.allowedTypes)
    end

    -- Apply collection filter
    if filters.collections and filters.collections.enabled then
        filteredEvents = FilterEngine.FilterByCollections(filteredEvents, filters.collections.allowedCollections)
    end

    -- Apply timeline filter
    if filters.timelines and filters.timelines.enabled then
        filteredEvents = FilterEngine.FilterByTimelines(filteredEvents, filters.timelines.allowedTimelines)
    end

    -- Apply character filter
    if filters.characters and filters.characters.enabled then
        filteredEvents = FilterEngine.FilterByCharacters(filteredEvents, filters.characters.allowedCharacters)
    end

    -- Apply faction filter
    if filters.factions and filters.factions.enabled then
        filteredEvents = FilterEngine.FilterByFactions(filteredEvents, filters.factions.allowedFactions)
    end

    -- Apply search filter
    if filters.search and filters.search.enabled then
        filteredEvents =
            FilterEngine.FilterBySearch(filteredEvents, filters.search.searchText, filters.search.searchFields)
    end

    return filteredEvents
end

--[[
    Filter events by year range
    @param events [table] List of events
    @param startYear [number] Start year (inclusive)
    @param endYear [number] End year (inclusive)
    @return [table] Filtered events
]]
function FilterEngine.FilterByYearRange(events, startYear, endYear)
    if not ValidationUtils.IsValidTable(events) then
        return {}
    end

    if not ValidationUtils.IsValidYear(startYear) or not ValidationUtils.IsValidYear(endYear) then
        return events
    end

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            -- Event overlaps with the year range
            return not (event.yearEnd < startYear or event.yearStart > endYear)
        end
    )
end

--[[
    Filter events by event types
    @param events [table] List of events
    @param allowedTypes [table] Array of allowed event type IDs
    @return [table] Filtered events
]]
function FilterEngine.FilterByEventTypes(events, allowedTypes)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(allowedTypes) then
        return events
    end

    local allowedTypeSet = TableUtils.Set(allowedTypes)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            return allowedTypeSet[event.eventType] == true
        end
    )
end

--[[
    Filter events by collection sources
    @param events [table] List of events
    @param allowedCollections [table] Array of allowed collection names
    @return [table] Filtered events
]]
function FilterEngine.FilterByCollections(events, allowedCollections)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(allowedCollections) then
        return events
    end

    local allowedCollectionSet = TableUtils.Set(allowedCollections)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            return allowedCollectionSet[event.source] == true
        end
    )
end

--[[
    Filter events by timelines
    @param events [table] List of events
    @param allowedTimelines [table] Array of allowed timeline IDs
    @return [table] Filtered events
]]
function FilterEngine.FilterByTimelines(events, allowedTimelines)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(allowedTimelines) then
        return events
    end

    local allowedTimelineSet = TableUtils.Set(allowedTimelines)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            return allowedTimelineSet[event.timeline] == true
        end
    )
end

--[[
    Filter events by associated characters
    @param events [table] List of events
    @param allowedCharacters [table] Array of allowed character IDs
    @return [table] Filtered events
]]
function FilterEngine.FilterByCharacters(events, allowedCharacters)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(allowedCharacters) then
        return events
    end

    local allowedCharacterSet = TableUtils.Set(allowedCharacters)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) or not ValidationUtils.IsValidTable(event.characters) then
                return false
            end

            for _, character in pairs(event.characters) do
                if allowedCharacterSet[character.id] == true then
                    return true
                end
            end

            return false
        end
    )
end

--[[
    Filter events by associated factions
    @param events [table] List of events
    @param allowedFactions [table] Array of allowed faction IDs
    @return [table] Filtered events
]]
function FilterEngine.FilterByFactions(events, allowedFactions)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(allowedFactions) then
        return events
    end

    local allowedFactionSet = TableUtils.Set(allowedFactions)

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) or not ValidationUtils.IsValidTable(event.factions) then
                return false
            end

            for _, faction in pairs(event.factions) do
                if allowedFactionSet[faction.id] == true then
                    return true
                end
            end

            return false
        end
    )
end

--[[
    Filter events by search text
    @param events [table] List of events
    @param searchText [string] Text to search for
    @param searchFields [table] Fields to search in (optional)
    @return [table] Filtered events
]]
function FilterEngine.FilterBySearch(events, searchText, searchFields)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidString(searchText) then
        return events
    end

    local lowerSearchText = string.lower(searchText)
    searchFields = searchFields or {"label"}

    return TableUtils.Filter(
        events,
        function(event)
            if not ValidationUtils.IsValidEvent(event) then
                return false
            end

            -- Search in specified fields
            for _, field in pairs(searchFields) do
                if field == "label" and event.label then
                    if string.find(string.lower(event.label), lowerSearchText) then
                        return true
                    end
                elseif field == "author" and event.author then
                    if string.find(string.lower(event.author), lowerSearchText) then
                        return true
                    end
                end
            end

            return false
        end
    )
end

--[[
    Create a filter configuration
    @param options [table] Filter options
    @return [table] Filter configuration
]]
function FilterEngine.CreateFilterConfig(options)
    options = options or {}

    return {
        yearRange = {
            enabled = options.enableYearRange or false,
            startYear = options.startYear,
            endYear = options.endYear
        },
        eventTypes = {
            enabled = options.enableEventTypes or false,
            allowedTypes = options.allowedEventTypes or {}
        },
        collections = {
            enabled = options.enableCollections or false,
            allowedCollections = options.allowedCollections or {}
        },
        timelines = {
            enabled = options.enableTimelines or false,
            allowedTimelines = options.allowedTimelines or {}
        },
        characters = {
            enabled = options.enableCharacters or false,
            allowedCharacters = options.allowedCharacters or {}
        },
        factions = {
            enabled = options.enableFactions or false,
            allowedFactions = options.allowedFactions or {}
        },
        search = {
            enabled = options.enableSearch or false,
            searchText = options.searchText or "",
            searchFields = options.searchFields or {"label"}
        }
    }
end

--[[
    Get filter statistics
    @param originalEvents [table] Original list of events
    @param filteredEvents [table] Filtered list of events
    @return [table] Filter statistics
]]
function FilterEngine.GetFilterStatistics(originalEvents, filteredEvents)
    local originalCount = ValidationUtils.IsValidTable(originalEvents) and TableUtils.Length(originalEvents) or 0
    local filteredCount = ValidationUtils.IsValidTable(filteredEvents) and TableUtils.Length(filteredEvents) or 0

    return {
        originalCount = originalCount,
        filteredCount = filteredCount,
        removedCount = originalCount - filteredCount,
        retentionRate = originalCount > 0 and (filteredCount / originalCount) or 0
    }
end

--[[
    Check if any filters are active
    @param filters [table] Filter configuration
    @return [boolean] True if any filters are enabled
]]
function FilterEngine.HasActiveFilters(filters)
    if not ValidationUtils.IsValidTable(filters) then
        return false
    end

    for _, filterGroup in pairs(filters) do
        if ValidationUtils.IsValidTable(filterGroup) and filterGroup.enabled then
            return true
        end
    end

    return false
end

-- Export FilterEngine globally for access by other modules
_G.FilterEngine = FilterEngine
