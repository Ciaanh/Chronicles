local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Factions = {}

-- Import utilities
local BookUtils = private.Core.Utils.BookUtils
--local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Faction Data Structure:
    id = [integer]					-- Id of the faction
    name = [string]				    -- Faction name
    chapters = { [chapter] }		-- Faction chapters/content
    timeline = [integer]			-- Timeline ID
    author = [string]				-- Author of the faction entry
    description = [string]          -- Faction description
    image = [string]                -- Faction image/crest path
]]
--[[
    Transform the faction into a book
    @param faction [faction] Faction object
    @return [table] Book representation of the faction
]]
function private.Core.Factions.TransformFactionToBook(faction)
    if not faction then
        return nil
    end

    if not BookUtils then
        -- Fallback implementation if BookUtils isn't loaded
        return {
            {
                templateKey = private.constants.bookTemplateKeys.SIMPLE_TITLE,
                text = faction.name or "Unknown Faction"
            }
        }
    end

    local result = BookUtils.TransformFactionToBook(faction)
    return result
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
    Search factions by name
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
            elseif sortBy == "timeline" then
                local aTimeline = a.timeline or 0
                local bTimeline = b.timeline or 0
                if aTimeline == bTimeline then
                    comparison = a.name < b.name
                else
                    comparison = aTimeline < bTimeline
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

function private.Core.Factions.EmptyBook()
    local data = {}
    return data
end
