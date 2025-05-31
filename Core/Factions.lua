local FOLDER_NAME, private = ...

private.Core.Factions = {}

-- Import utilities
local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Faction Data Structure:
    id = [integer]					-- Id of the faction
    name = [string]				    -- Faction name
    description = { [string] }		-- Faction descriptions/history
    chapters = { [chapter] }		-- Faction chapters/content
    yearStart = [integer]			-- Foundation/first appearance year
    yearEnd = [integer]				-- Dissolution/last appearance year (optional)
    timeline = [integer]			-- Timeline ID
    parentFactionId = [integer]		-- Parent faction ID (for sub-factions)
    leaderIds = { [integer] }		-- Character IDs of faction leaders
    territories = { [string] }		-- Controlled territories
    factionType = [string]			-- Type: "nation", "organization", "guild", etc.
    alignment = [string]			-- Alignment: "alliance", "horde", "neutral", etc.
    author = [string]				-- Author of the faction entry
]]
--[[
    Transform the faction into a book
    @param faction [faction] Faction object
    @return [table] Book representation of the faction
]]
function private.Core.Factions.TransformFactionToBook(faction)
    if (faction == nil) then
        return nil
    end

    local data = {}

    -- Add faction title page
    local title = {
        header = {
            templateKey = private.constants.templateKeys.FACTION_TITLE or private.constants.templateKeys.HEADER,
            text = faction.name,
            yearStart = faction.yearStart,
            yearEnd = faction.yearEnd
        },
        elements = {}
    }

    -- Add author information if available
    local author = ""
    if (faction.author ~= nil) then
        author = "Author: " .. faction.author
    end

    table.insert(
        title.elements,
        {
            templateKey = private.constants.templateKeys.AUTHOR,
            text = author
        }
    )
    table.insert(data, title)

    -- Add faction information
    if ValidationUtils.IsValidTable(faction.description) then
        for key, description in pairs(faction.description) do
            local chapter = private.Core.Events.CreateChapter(nil, {description})
            table.insert(data, chapter)
        end
    end

    return data
end

--[[
    Get factions by timeline ID
    @param factions [table] List of factions
    @param timelineId [number] Timeline ID to filter by
    @return [table] Factions from the specified timeline
]]
function private.Core.Factions.GetFactionsByTimeline(factions, timelineId)
    if not ValidationUtils.IsValidTable(factions) or not ValidationUtils.IsValidNumber(timelineId) then
        return {}
    end

    return TableUtils.Filter(
        factions,
        function(faction)
            return ValidationUtils.IsValidFaction(faction) and faction.timeline == timelineId
        end
    )
end

--[[
    Get factions within a year range (active during that period)
    @param factions [table] List of factions
    @param startYear [number] Start year of range
    @param endYear [number] End year of range
    @return [table] Factions active within the year range
]]
function private.Core.Factions.GetFactionsByYearRange(factions, startYear, endYear)
    if
        not ValidationUtils.IsValidTable(factions) or not ValidationUtils.IsValidYear(startYear) or
            not ValidationUtils.IsValidYear(endYear)
     then
        return {}
    end

    return TableUtils.Filter(
        factions,
        function(faction)
            if not ValidationUtils.IsValidFaction(faction) then
                return false
            end

            -- Check if faction was active during the year range
            local factionStart = faction.yearStart or startYear
            local factionEnd = faction.yearEnd or endYear

            return not (factionEnd < startYear or factionStart > endYear)
        end
    )
end

--[[
    Search factions by name or description
    @param factions [table] List of factions
    @param searchText [string] Text to search for
    @return [table] Factions matching the search text
]]
function private.Core.Factions.SearchFactions(factions, searchText)
    if not ValidationUtils.IsValidTable(factions) or not ValidationUtils.IsValidString(searchText) then
        return {}
    end

    local lowerSearchText = string.lower(searchText)

    return TableUtils.Filter(
        factions,
        function(faction)
            if not ValidationUtils.IsValidFaction(faction) then
                return false
            end

            -- Search in name
            if string.find(string.lower(faction.name), lowerSearchText) then
                return true
            end

            -- Search in descriptions
            if ValidationUtils.IsValidTable(faction.description) then
                for _, desc in pairs(faction.description) do
                    if string.find(string.lower(desc), lowerSearchText) then
                        return true
                    end
                end
            end

            -- Search in territories
            if ValidationUtils.IsValidTable(faction.territories) then
                for _, territory in pairs(faction.territories) do
                    if string.find(string.lower(territory), lowerSearchText) then
                        return true
                    end
                end
            end

            return false
        end
    )
end

--[[
    Sort factions by multiple criteria
    @param factions [table] List of factions to sort
    @param sortBy [string] Sort criteria: "name", "year", "type", "alignment"
    @param ascending [boolean] Sort direction (default: true)
    @return [table] Sorted factions
]]
function private.Core.Factions.SortFactions(factions, sortBy, ascending)
    if not ValidationUtils.IsValidTable(factions) then
        return {}
    end

    local sortedFactions = TableUtils.DeepCopy(factions)
    ascending = ascending ~= false -- default to true

    table.sort(
        sortedFactions,
        function(a, b)
            local comparison = false

            if sortBy == "name" then
                comparison = a.name < b.name
            elseif sortBy == "year" then
                local aYear = a.yearStart or 0
                local bYear = b.yearStart or 0
                if aYear == bYear then
                    comparison = a.name < b.name
                else
                    comparison = aYear < bYear
                end
            elseif sortBy == "type" then
                local aType = a.factionType or ""
                local bType = b.factionType or ""
                if aType == bType then
                    comparison = a.name < b.name
                else
                    comparison = aType < bType
                end
            elseif sortBy == "alignment" then
                local aAlignment = a.alignment or ""
                local bAlignment = b.alignment or ""
                if aAlignment == bAlignment then
                    comparison = a.name < b.name
                else
                    comparison = aAlignment < bAlignment
                end
            else
                -- Default sort by name
                comparison = a.name < b.name
            end

            return ascending and comparison or not comparison
        end
    )

    return sortedFactions
end
