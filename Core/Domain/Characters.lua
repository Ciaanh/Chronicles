local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Characters = {}

-- Import utilities
local BookUtils = private.Core.Utils.BookUtils
local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Character Data Structure:
    id = [integer]					-- Id of the character
    name = [string]				    -- Character name
    chapters = { [chapter] }		-- Character chapters/content
    timeline = [integer]			-- Timeline ID
    factions = { [faction] }		-- Associated factions
    author = [string]				-- Author of the character entry
    description = [string]          -- Character description
]]
--[[
    Transform the character into a book
    @param character [character] Character object
    @return [table] Book representation of the character
]]
function private.Core.Characters.TransformCharacterToBook(character)
    if not character then
        return nil
    end

    if not BookUtils then
        -- Fallback implementation if BookUtils isn't loaded
        return {
            {
                templateKey = private.constants.bookTemplateKeys.SIMPLE_TITLE,
                text = character.name or "Unknown Character"
            }
        }
    end

    local result = BookUtils.TransformCharacterToBook(character)
    return result
end

--[[
    Get characters by faction ID
    @param characters [table] List of characters
    @param factionId [number] Faction ID to filter by
    @return [table] Characters associated with the faction
]]
function private.Core.Characters.GetCharactersByFaction(characters, factionId)
    if not ValidationUtils.IsValidTable(characters) or not ValidationUtils.IsValidNumber(factionId) then
        return {}
    end

    return TableUtils.Filter(
        characters,
        function(character)
            if not ValidationUtils.IsValidTable(character.factions) then
                return false
            end

            for _, faction in pairs(character.factions) do
                if faction.id == factionId then
                    return true
                end
            end
            return false
        end
    )
end

--[[
    Search characters by name
    @param characters [table] List of characters
    @param searchText [string] Text to search for
    @return [table] Characters matching the search text
]]
function private.Core.Characters.SearchCharacters(characters, searchText)
    if not ValidationUtils.IsValidTable(characters) or not ValidationUtils.IsValidString(searchText) then
        return {}
    end

    local lowerSearchText = string.lower(searchText)

    return TableUtils.Filter(
        characters,
        function(character)
            if not ValidationUtils.IsValidCharacter(character) then
                return false
            end

            -- Search in name
            if string.find(string.lower(character.name), lowerSearchText) then
                return true
            end

            return false
        end
    )
end

--[[
    Sort characters by multiple criteria
    @param characters [table] List of characters to sort
    @param sortBy [string] Sort criteria: "name", "year", "faction"
    @param ascending [boolean] Sort direction (default: true)
    @return [table] Sorted characters
]]
function private.Core.Characters.SortCharacters(characters, sortBy, ascending)
    if not ValidationUtils.IsValidTable(characters) then
        return {}
    end

    local sortedCharacters = TableUtils.DeepCopy(characters)
    ascending = ascending ~= false -- default to true

    table.sort(
        sortedCharacters,
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
            elseif sortBy == "faction" then
                local aFaction =
                    (ValidationUtils.IsValidTable(a.factions) and a.factions[1] and a.factions[1].name) or ""
                local bFaction =
                    (ValidationUtils.IsValidTable(b.factions) and b.factions[1] and b.factions[1].name) or ""
                if aFaction == bFaction then
                    comparison = a.name < b.name
                else
                    comparison = aFaction < bFaction
                end
            else
                -- Default sort by name
                comparison = a.name < b.name
            end

            return ascending and comparison or not comparison
        end
    )
    return sortedCharacters
end

--[[
    Returns an empty book representation for characters
    @return [table] Empty book display when no character is selected
]]
function private.Core.Characters.EmptyBook()
    return {
        {
            templateKey = private.constants.bookTemplateKeys.EMPTY,
            text = "No character selected"
        }
    }
end
