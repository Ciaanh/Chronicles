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
	era = "Era",
	war = "War",
	battle = "Battle",
	death = "Death",
	birth = "Birth",
	other = "Other"
}

constants.timelines = {
	undefined = 0,
	main = 1,
	dreanor = 2,
	eot = 3,
	wota = 4
}

constants.config = {
	timeline = {
		yearStart = -200000,
		yearEnd = 33,
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
	myJournal =  {
		eventListPageSize = 9
	}
}

constants.configurationName = {
	myjournal = "myjournal"
}
