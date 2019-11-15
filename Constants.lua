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

local OBJECTICONS = "Interface\\MINIMAP\\OBJECTICONS"
constants.icon_texture = {
	research = "Interface\\ICONS\\INV_Scroll_11",
	borrowedtime = "Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME"
}

-- Define the default icon here
constants.defaultIcon = constants.icon_texture["borrowedtime"]

constants.eventType = {
	era = "Era",
	war = "War",
	battle = "Battle",
	death = "Death",
	birth = "Birth"
}

constants.timeline = {
	yearStart = -15000,
	yearEnd = 33,
	defaultStep = 1000,
	pageSize = 8
}

constants.eventList = {
	pageSize = 6
}