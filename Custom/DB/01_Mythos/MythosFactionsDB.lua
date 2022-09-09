local FOLDER_NAME, private = ...
local Chronicles = private.Core
local modules = Chronicles.constants.modules

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

MythosFactionsDB = {
	--[[ structure:
		[factionId] = {
            id=[integer],				-- Id of the faction
			name=[string], 				-- name of the faction
			description=[string],		-- description
			timeline=[integer],    		-- id of the timeline 
		},
	--]]
	[1] = {
		id = 1,
		name = Locale["Titans"],
		description = Locale["Titans description"],
		timeline = 2
	},
	[2] = {
		id = 2,
		name = Locale["OldGods"],
		description = Locale["OldGods description"],
		timeline = 2
	}
}
