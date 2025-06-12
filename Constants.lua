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
	mythos = -999999,
	futur = 999999,
	timeline = {
		pageSize = 8
	},
	eventList = {
		pageSize = 6
	},
	eventFilter = {
		pageSize = 7
	},
	collectionsFilter = {
		pageSize = 7
	},
	myJournal = {
		eventListPageSize = 9,
		factionListPageSize = 9,
		characterListPageSize = 9,
		characterFactionsPageSize = 8,
		eventFactionsPageSize = 8,
		eventCharactersPageSize = 8
	},
	-- stepValues = {1000, 500, 250, 100, 50, 10, 1}
	stepValues = {1000, 500, 100, 10}
}

constants.configurationName = {
	myjournal = "myjournal"
}

constants.events = {
	-- Application lifecycle events
	AddonStartup = "Addon.STARTUP",
	AddonShutdown = "Addon.SHUTDOWN",
	TimelineInit = "Timeline.INIT",
	UIRefresh = "Timeline.CLEAN",
	TimelinePeriodSelected = "Timeline.PERIOD_SELECTED",
	TimelinePreviousButtonVisible = "Timeline.PREVIOUS_VISIBLE",
	TimelineNextButtonVisible = "Timeline.NEXT_VISIBLE",
	EventSelected = "Event.SELECTED",
	CharacterSelected = "Character.SELECTED",
	FactionSelected = "Faction.SELECTED",
	DisplayTimelineLabel = "Timeline.DisplayLabel",
	DisplayTimelinePeriod = "Timeline.DisplayPeriod",
	TabUITabSet = "TabUI.TabSet",
	MainFrameUIOpenFrame = "MainFrameUI.OpenFrame",
	MainFrameUICloseFrame = "MainFrameUI.CloseFrame",
	SettingsTabSelected = "Settings.TAB_SELECTED",
	SettingsEventTypeChecked = "Settings.EVENT_TYPE_CHECKED",
	SettingsCollectionChecked = "Settings.COLLECTION_CHECKED",
	-- New event management events
	EventManagerError = "EventManager.ERROR",
	EventValidationFailed = "EventManager.VALIDATION_FAILED",
	EventBatchExecuted = "EventManager.BATCH_EXECUTED"
}

-- Event system configuration
constants.eventSystem = {
	enableValidation = true,
	enableErrorLogging = true,
	maxEventHistory = 100,
	batchTimeout = 100, -- milliseconds
	enableAsyncEvents = false
}

-- Event priority levels for batching and processing
constants.eventPriority = {
	CRITICAL = 1, -- UI state changes, errors
	HIGH = 2, -- User interactions, selections
	NORMAL = 3, -- Data updates, refreshes
	LOW = 4 -- Background tasks, logging
}

-- Event categories for organization and filtering
constants.eventCategories = {
	UI = "UI",
	DATA = "DATA",
	USER_INTERACTION = "USER_INTERACTION",
	SYSTEM = "SYSTEM",
	PLUGIN = "PLUGIN",
	ERROR = "ERROR"
}

constants.templateKeys = {
	EVENTLIST_TITLE = "EVENTLIST_TITLE",
	EVENT_DESCRIPTION = "EVENT_DESCRIPTION",
	EVENT_TITLE = "EVENT_TITLE",
	CHARACTER_TITLE = "CHARACTER_TITLE",
	VERTICAL_CHARACTER_LIST_ITEM = "VERTICAL_CHARACTER_LIST_ITEM",
	FACTION_TITLE = "FACTION_TITLE",
	FACTION_LIST_ITEM = "FACTION_LIST_ITEM",
	EMPTY = "EMPTY",
	AUTHOR = "AUTHOR",
	HEADER = "HEADER",
	TEXT_CONTENT = "TEXT_CONTENT",
	HTML_CONTENT = "HTML_CONTENT"
}

constants.colors = {
	white = "|cFFFFFFFF",
	red = "|cFFFF0000",
	darkred = "|cFFF00000",
	green = "|cFF00FF00",
	orange = "|cFFFF7F00",
	yellow = "|cFFFFFF00",
	gold = "|cFFFFD700",
	teal = "|cFF00FF9A",
	cyan = "|cFF1CFAFE",
	lightBlue = "|cFFB0B0FF",
	battleNetBlue = "|cff82c5ff",
	grey = "|cFF909090",
	-- classes
	classMage = "|cFF69CCF0",
	classHunter = "|cFFABD473",
	-- recipes
	recipeGrey = "|cFF808080",
	recipeGreen = "|cFF40C040",
	recipeOrange = "|cFFFF8040",
	-- rarity : http://wow.gamepedia.com/Quality
	common = "|cFFFFFFFF",
	uncommon = "|cFF1EFF00",
	rare = "|cFF0070DD",
	epic = "|cFFA335EE",
	legendary = "|cFFFF8000",
	heirloom = "|cFFE6CC80",
	Alliance = "|cFF2459FF",
	Horde = "|cFFFF0000"
}
