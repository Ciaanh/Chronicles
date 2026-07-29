local FOLDER_NAME, private = ...

private.Core.Characters = {}

--[[
    Character Data Structure:
    id = [integer]					-- Id of the character
    name = [string]				    -- Character name
    chapters = { [chapter] }		-- Character chapters/content
    timeline = [integer]			-- Timeline ID
    factions = { [faction] }		-- Associated factions
    author = [string]				-- Author of the character entry
    description = [string]          -- Character description
    image = [string]                -- Character portrait/image path
]]
--[[
    Transform the character into a unified book
    @param character [character] Character object
    @return [table] Unified book representation of the character
]]
function private.Core.Characters.TransformCharacterToBook(character)
    if not character then
        return nil
    end

    if not private.Core.Utils.ContentUtils then
        error("TransformCharacterToBook: ContentUtils not loaded")
    end

    if not private.Core.Utils.ContentUtils.TransformEntityToBook then
        error("TransformCharacterToBook: ContentUtils.TransformEntityToBook not available")
    end

    return private.Core.Utils.ContentUtils.TransformEntityToBook(character)
end
