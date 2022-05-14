local FOLDER_NAME, private = ...
local Chronicles = private.Core
local modules = Chronicles.constants.modules

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

MythosEventsDB = {
	--[[ structure:
		[eventId] = {
            id=[integer],				-- Id of the event
			label=[string], 			-- label: text that'll be the label
			description=table[string], 	-- description: text that give informations about the event
			yearStart=[integer],		-- 
			yearEnd=[integer],			-- 
			eventType=[integer],		-- type of event defined in constants
			timeline=[integer],    		-- id of the timeline 
			date=[integer],    			-- number to specify the date to order event in a year (timestamp)
			characters=table[integer], 	-- concerned characters
            factions=table[integer], 	-- concerned factions
		},
	--]]
	[1] = {
		id = 1,
		label = Locale["MythosEvent"],
		description = {Locale["MythosEvent page 1"], Locale["MythosEvent page 2"]},
		yearStart = -200000,
		yearEnd = -200000,
		eventType = 2,
		timeline = 2
	},
}
