local FOLDER_NAME, private = ...
local Chronicles = private.Core
local modules = Chronicles.constants.modules

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

MythosCharactersDB = {
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
			[modules.mythos] = {1},
		}
	}
}
