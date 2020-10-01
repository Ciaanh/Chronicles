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
			eventType=[integer],		-- type of event defined in constants
			timeline=[integer],    		-- id of the timeline 
			date=[integer],    			-- number to specify the date to order event in a year (timestamp)
			characters=table[integer], 	-- concerned characters
            factions=table[integer], 	-- concerned factions
		},
	--]]
	[1] = {
		id = 1,
		label = Locale["The War of the Ancients label"],
		description = {Locale["The War of the Ancients page 1"], Locale["The War of the Ancients page 2"]},
		yearStart = -10000,
		yearEnd = -10000,
		eventType = 2,
		timeline = 2
	},
	[2] = {
		id = 2,
		label = Locale["Quel'Thalas Founded	 label"],
		description = {Locale["Quel'Thalas Founded page 1"]},
		yearStart = -6800,
		yearEnd = -6800,
		eventType = 6,
		timeline = 2
	},
	[3] = {
		id = 3,
		label = Locale["The Troll Wars label"],
		description = {Locale["The Troll Wars page 1"]},
		yearStart = -2800,
		yearEnd = -2800,
		eventType = 2,
		timeline = 2
	},
	[4] = {
		id = 4,
		label = Locale["War of the Three Hammers label"],
		description = {Locale["War of the Three Hammers page 1"]},
		yearStart = -230,
		yearEnd = -230,
		eventType = 2,
		timeline = 2
	},
	[5] = {
		id = 5,
		label = Locale["The First War label"],
		description = {Locale["The First War page 1"]},
		yearStart = 0,
		yearEnd = 0,
		eventType = 2,
		timeline = 2
	},
	[6] = {
		id = 6,
		label = Locale["The Fall of Stormwind label"],
		description = {Locale["The Fall of Stormwind page 1"]},
		yearStart = 3,
		yearEnd = 5,
		eventType = 6,
		timeline = 2
	},
	[7] = {
		id = 7,
		label = Locale["The Second War label"],
		description = {Locale["The Second War page 1"]},
		yearStart = 6,
		yearEnd = 6,
		eventType = 2,
		timeline = 2
	},
	[8] = {
		id = 8,
		label = Locale["The Destruction of Draenor label"],
		description = {Locale["The Destruction of Draenor page 1"]},
		yearStart = 8,
		yearEnd = 8,
		eventType = 3,
		timeline = 2
	},
	[9] = {
		id = 9,
		label = Locale["The New Horde label"],
		description = {Locale["The New Horde page 1"]},
		yearStart = 18,
		yearEnd = 18,
		eventType = 6,
		timeline = 2
	},
	[10] = {
		id = 10,
		label = Locale["The Third War label"],
		description = {Locale["The Third War page 1"]},
		yearStart = 20,
		yearEnd = 20,
		eventType = 2,
		timeline = 2
	},
	[11] = {
		id = 11,
		label = Locale["The Battle of Mount Hyjal"],
		description = {Locale["The Battle of Mount Hyjal page 1"]},
		yearStart = 21,
		yearEnd = 21,
		eventType = 3,
		timeline = 2
	},
	[12] = {
		id = 12,
		label = Locale["Rise of the Lich King label"],
		description = {Locale["Rise of the Lich King page 1"]},
		yearStart = 22,
		yearEnd = 22,
		eventType = 6,
		timeline = 2
	},
	[13] = {
		id = 13,
		label = Locale["The Gathering Storm label"],
		description = {Locale["The Gathering Storm page 1"]},
		yearStart = 25,
		yearEnd = 25,
		eventType = 6,
		timeline = 2
	},
	[14] = {
		id = 14,
		label = Locale["The Burning Crusade label"],
		description = {Locale["The Burning Crusade page 1"]},
		yearStart = 26,
		yearEnd = 26,
		eventType = 6,
		timeline = 2
	},
	[15] = {
		id = 15,
		label = Locale["The Wrath of the Lich King label"],
		description = {Locale["The Wrath of the Lich King page 1"]},
		yearStart = 27,
		yearEnd = 27,
		eventType = 6,
		timeline = 2
	},
	[16] = {
		id = 16,
		label = Locale["The Cataclysm label"],
		description = {Locale["The Cataclysm page 1"]},
		yearStart = 28,
		yearEnd = 28,
		eventType = 6,
		timeline = 2
	},
	[17] = {
		id = 17,
		label = Locale["The Invasion of Pandaria label"],
		description = {Locale["The Invasion of Pandaria page 1"]},
		yearStart = 30,
		yearEnd = 30,
		eventType = 2,
		timeline = 2
	},
	[18] = {
		id = 18,
		label = Locale["Assault of the Dark Portal label"],
		description = {Locale["Assault of the Dark Portal page 1"]},
		yearStart = 31,
		yearEnd = 31,
		eventType = 6,
		timeline = 2
	},

	[19] = {
		id = 19,
		label = Locale["Example event"],
		description = {Locale["Example event page 1"], Locale["Example event page 2"]},
		yearStart = 0,
		yearEnd = 0,
		eventType = 6,
		timeline = 2
	}
}
