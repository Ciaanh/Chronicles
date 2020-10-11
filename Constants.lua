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
	[1] = "era",
	[2] = "war",
	[3] = "battle",
	[4] = "death",
	[5] = "birth",
	[6] = "other"
}

constants.timelines = {
	[1] = "undefined",
	[2] = "main",
	[3] = "dreanor",
	[4] = "eot",
	[5] = "wota"
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
		characterListPageSize = 9
	}
}

constants.configurationName = {
	myjournal = "myjournal"
}
