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
    },




    [2] = {
        id = 2,
        label = Locale["Test 2"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [3] = {
        id = 3,
        label = Locale["Test 3"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [4] = {
        id = 4,
        label = Locale["Test 4"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [5] = {
        id = 5,
        label = Locale["Test 5"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [6] = {
        id = 6,
        label = Locale["Test 6"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [7] = {
        id = 7,
        label = Locale["Test 7"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [8] = {
        id = 8,
        label = Locale["Test 8"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [9] = {
        id = 9,
        label = Locale["Test 9"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    },
    [10] = {
        id = 10,
        label = Locale["Test 10"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        yearStart = -15000,
        yearEnd = -15000,
        eventType = Chronicles.constants.eventType.other
    }
}
