local _G = getfenv(0)

local FOLDER_NAME, private = ...
private.addon_name = "Chronicles"

local constants = {}
private.constants = constants

constants.defaults = {
	profile = {},
	global = {
		options = {
			version = "",
			minimap = {
				hide = false
			}
		}
	}
}

-- Define the default icon here
constants.defaultIcon = "Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME"

constants.eventType = {
	[0] = "undefined",
	[1] = "era",
	[2] = "war",
	[3] = "battle",
	[4] = "death",
	[5] = "birth",
	[6] = "other"
}

constants.timelines = {
	[0] = "undefined",
	[1] = "main",
	[2] = "dreanor",
	[3] = "eot",
	[4] = "wota"
}

constants.config = {
	currentYear = 33,
	historyStartYear = -150000,
	timeline = {
		pageSize = 8
	},
	eventList = {
		pageSize = 6
	},
	eventFilter = {
		pageSize = 7
	},
	librariesFilter = {
		pageSize = 7
	},
	myJournal = {
		eventListPageSize = 9,
		factionListPageSize = 9,
		characterListPageSize = 9,
		characterFactionsPageSize = 8,
		eventFactionsPageSize = 8,
		eventCharactersPageSize = 8
	}
}

constants.configurationName = {
	myjournal = "myjournal"
}
