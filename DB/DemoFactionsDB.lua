local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

DemoFactionsDB = {
	--[[ structure:
		[factionId] = {
            id=[integer],				-- Id of the faction
			name=[string], 				-- name of the faction
			description=[string],		-- description
			timeline=[integer],    		-- id of the timeline 
		},
	--]]
	
}
