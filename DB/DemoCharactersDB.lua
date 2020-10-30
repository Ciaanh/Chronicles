local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

DemoCharactersDB = {
	--[[ structure:
		[characterId] = {
 			id=[integer],				-- Id of the character
			name=[string], 				-- name of the character
			biography=[string],			-- small biography
			timeline=[integer],    		-- id of the timeline
            factions=table[integer], 	-- concerned factions
		},
	--]]
	[1] = {
		id = 1,
		name = Locale["Norgannon"],
		biography = Locale["Norgannon biography"],
		timeline = 2,
		factions = {
			["Demo"] = {2, 1, 1, 1, 2, 2, 2},
			["myjournal"] = {1, 1, 1, 1, 1}
		}
	}
}
