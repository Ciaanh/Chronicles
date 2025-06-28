local FOLDER_NAME, private = ...

private.Core.Characters = {}

-- Import utilities
local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Character Data Structure:
    id = [integer]					-- Id of the character
    name = [string]				    -- Character name
    chapters = { [chapter] }		-- Character chapters/content
    yearStart = [integer]			-- Birth/first appearance year
    yearEnd = [integer]				-- Death/last appearance year
    timeline = [integer]			-- Timeline ID
    factions = { [faction] }		-- Associated factions
    author = [string]				-- Author of the character entry
]]
--[[
    Transform the character into a book
    @param character [character] Character object
    @return [table] Book representation of the character
]]
function private.Core.Characters.TransformCharacterToBook(character)
    if (character == nil) then
        return nil
    end

    -- Implementation similar to Events.TransformEventToBook
    -- This would create a book format for character display
    local data = {}

    -- Add cover page as first element
    table.insert(data, {
        templateKey = private.constants.bookTemplateKeys.COVER_PAGE,
        name = character.name or "Unknown Character",
        description = character.description or "No description available.",
        image = character.image,
        entityType = "character"
    })

    -- Add character title page
    local title = {
        header = {
            templateKey = private.constants.bookTemplateKeys.SIMPLE_TITLE,
            text = character.name,
            yearStart = character.yearStart,
            yearEnd = character.yearEnd
        },
        elements = {}
    }

    -- Add author information if available
    local author = ""
    if (character.author ~= nil) then
        author = "Author: " .. character.author
    end

    table.insert(
        title.elements,
        {
            templateKey = private.constants.bookTemplateKeys.AUTHOR,
            text = author
        }
    )
    table.insert(data, title)

    return data
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
    Get characters within a year range (active during that period)
    @param characters [table] List of characters
    @param startYear [number] Start year of range
    @param endYear [number] End year of range
    @return [table] Characters active within the year range
]]
function private.Core.Characters.GetCharactersByYearRange(characters, startYear, endYear)
    if
        not ValidationUtils.IsValidTable(characters) or not ValidationUtils.IsValidYear(startYear) or
            not ValidationUtils.IsValidYear(endYear)
     then
        return {}
    end

    return TableUtils.Filter(
        characters,
        function(character)
            if not ValidationUtils.IsValidCharacter(character) then
                return false
            end

            -- Check if character was active during the year range
            local charStart = character.yearStart or startYear
            local charEnd = character.yearEnd or endYear

            return not (charEnd < startYear or charStart > endYear)
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
            elseif sortBy == "year" then
                local aYear = a.yearStart or 0
                local bYear = b.yearStart or 0
                if aYear == bYear then
                    comparison = a.name < b.name
                else
                    comparison = aYear < bYear
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
    )    return sortedCharacters
end

--[[
    Returns an empty book representation for characters
    @return [table] Empty book display when no character is selected
]]
function private.Core.Characters.EmptyBook()
    return {
        {
            template = private.constants.bookTemplateKeys.EMPTY,
            text = "No character selected"
        }
    }
end
