local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

GlobalEventsDB = {
    --[[ structure:
		[eventId] = {
            id=[integer],				-- Id of the event
			label=[string], 			-- label: text that'll be the label
			description=table[string], 	-- description: text that give informations about the event
			yearStart=[integer],		-- 
			yearEnd=[integer],			-- 
			eventType=[string],			-- type of event defined in constants

		},
	--]]
    [1] = {
        id = 1,
        label = Locale["Dark Portal label"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = 0,
        yearEnd = 0,
        eventType = Chronicles.constants.eventType.other
    }
}
