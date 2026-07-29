local FOLDER_NAME, private = ...

private.Core.Factions = {}

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
    Transform the faction into a unified book (primary method)
    @param faction [faction] Faction object
    @return [table] Unified book representation of the faction
]]
function private.Core.Factions.TransformFactionToBook(faction)
    if not faction then
        return nil
    end

    if not private.Core.Utils.ContentUtils then
        error("TransformFactionToBook: ContentUtils not loaded")
    end

    if not private.Core.Utils.ContentUtils.TransformEntityToBook then
        error("TransformFactionToBook: ContentUtils.TransformEntityToBook not available")
    end

    return private.Core.Utils.ContentUtils.TransformEntityToBook(faction)
end
