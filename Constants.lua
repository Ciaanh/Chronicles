local FOLDER_NAME, private = ...
private.addon_name = "Chronicles"

private.Core = {}

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

constants.defaultIcon = "Interface\\ICONS\\SPELL_HOLY_BORROWEDTIME"

constants.viewWidth = 425

constants.eventType = {
	[0] = "undefined",
	[1] = "event",
	[2] = "era",
	[3] = "war",
	[4] = "battle",
	[5] = "death",
	[6] = "birth",
	[7] = "other"
}

constants.timelines = {
	[0] = "undefined",
	[1] = "main",
	[2] = "dreanor",
	[3] = "eot",
	[4] = "wota"
}

constants.config = {
	currentYear = 42,
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

constants.events = {
	TimelineInit = "TIMELINE_INIT",
	TimelinePeriodSelected = "TIMELINE_PERIOD_SELECTED",
	
	TimelinePreviousButtonVisible = "Timeline.PREVIOUS_VISIBLE",
	TimelineNextButtonVisible = "Timeline.NEXT_VISIBLE",

	TimelineStepChanged="Timeline.STEP_CHANGED",

	EventDetailPageEventSelected = "EVENT_SELECTED",

	DisplayTimelineLabel = "DisplayTimelineLabel",
	DisplayTimelinePeriod = "DisplayTimelinePeriod",

	TabUITabSet = "TabUI.TabSet",
	MainFrameUIOpenFrame = "MainFrameUI.OpenFrame",
	MainFrameUICloseFrame = "MainFrameUI.CloseFrame"
}
