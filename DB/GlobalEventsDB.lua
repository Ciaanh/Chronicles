local FOLDER_NAME, private = ...
local Chronicles = private.Core

GlobalEventsDB = {
    --[[ structure:
		[eventId] = {
            id=[integer],				-- Id of the event
			label=[string], 			-- label: text that'll be the label
			description=table[string], 	-- description: text that give informations about the event
			icon=[string], 				-- the pre-define icon type which can be found in Constant.lua
			yearStart=[integer],		-- 
			yearEnd=[integer],			-- 
			eventType=[string],			-- type of event defined in constants

		},
	--]]
    [1] = {
        id = 1,
        label = Locale["Dark Portal label"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        icon = "research",
        yearStart = 0,
        yearEnd = 0,
        eventType = Chronicles.constants.eventType.other
    }
}
