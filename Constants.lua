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
	-- stepValues = {1000, 500, 250, 100, 50, 10, 1}
	stepValues = {1000, 500, 100, 10}
}

constants.configurationName = {}

constants.events = {
	-- Application lifecycle events
	AddonStartup = "Addon.STARTUP",
	AddonShutdown = "Addon.SHUTDOWN",
	TimelineInit = "Timeline.INIT",
	UIRefresh = "Timeline.CLEAN",
	TimelinePreviousButtonVisible = "Timeline.PREVIOUS_VISIBLE",
	TimelineNextButtonVisible = "Timeline.NEXT_VISIBLE",
	DisplayTimelineLabel = "Timeline.DisplayLabel",
	DisplayTimelinePeriod = "Timeline.DisplayPeriod",
	DisplayEventsForYear = "Timeline.DisplayEventsForYear",
	TabUITabSet = "TabUI.TabSet",
	SettingsEventTypeChecked = "Settings.EVENT_TYPE_CHECKED",
	SettingsCollectionChecked = "Settings.COLLECTION_CHECKED"
}

constants.templateKeys = {
	EVENTLIST_TITLE = "EVENTLIST_TITLE",
	EVENT_DESCRIPTION = "EVENT_DESCRIPTION",
	GENERIC_LIST_ITEM = "GENERIC_LIST_ITEM" -- For the shared vertical list template
}

-- Book-specific template keys used in the BookContainerTemplate system
constants.bookTemplateKeys = {
	-- Title templates for different content types
	EVENT_TITLE = "EVENT_TITLE", -- Complex title with date ranges
	SIMPLE_TITLE = "SIMPLE_TITLE", -- Simple title for characters and factions
	-- Cover page template
	COVER_PAGE = "COVER_PAGE", -- Cover page with name only
	COVER_IMAGE = "COVER_IMAGE", -- Cover page image element
	-- Unified content keys - primary templates
	UNIFIED_CONTENT = "UNIFIED_CONTENT", -- Unified HTML content template
	COVER_WITH_CONTENT = "COVER_WITH_CONTENT", -- Cover page with integrated content
	PAGE_BREAK = "PAGE_BREAK", -- For pagination
	-- Content structure templates (needed for old format compatibility)
	EMPTY = "EMPTY",
	AUTHOR = "AUTHOR",
	CHAPTER_HEADER = "CHAPTER_HEADER", -- For chapter headers
	TEXT_CONTENT = "TEXT_CONTENT", -- For regular text lines
	HTML_CONTENT = "HTML_CONTENT" -- For HTML formatted content
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
