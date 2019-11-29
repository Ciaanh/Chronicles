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

constants.timeline = {
	yearStart = -15000,
	yearEnd = 33,
	pageSize = 8
}

constants.eventList = {
	pageSize = 6
}