local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

GlobalCharactersDB = {
	--[[ structure:
		[characterId] = {
 			id=[integer],				-- Id of the character
			name=[string], 				-- name of the character
			biography=[string],			-- small biography
			timeline=[integer],    		-- id of the timeline 
            factions=table[integer], 	-- concerned factions
		},
	--]]
}
