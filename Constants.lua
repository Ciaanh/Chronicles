local FOLDER_NAME, private = ...
private.addon_name = "Chronicles"

private.Core = {}

local constants = {}
private.constants = constants

-- Minimap button / DataBroker launcher icon.
constants.minimapIcon = "Interface\\ICONS\\Inv_scroll_04"

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

-- Encoding of the `timeline` field carried by every event record. No Lua reads it today; it is the
-- documented contract for the value external data addons write, per PLUGINS.md.
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
		pageSize = 8,
		--[[
			Event-density ladder for the timeline's crystals. Ordered low to high: the first tier whose
			ceiling the count is under wins, and anything above them all is dense.

			Here rather than file-local in TimelineTemplate.lua because there are now two consumers in
			the addon (the period mixin that paints a crystal and the legend that explains what the
			colours mean), and the Chronicles-tauri companion's period band needs the same numbers.
			Three copies of a ladder is how the legend ends up describing a threshold the crystals do
			not use. The tier wording in the legend is built from these numbers, never restated in a
			locale string.
		]]
		densityTiers = {
			{below = 10, texture = "low-events"},
			{below = 25, texture = "medium-events"}
		},
		denseTexture = "high-events",
		noEventsTexture = "no-events"
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
	book = {
		-- How many documents share one displayed page. The book is a spread: two documents side by
		-- side, front matter facing the first body page.
		--
		-- This number exists twice by necessity. BookContainerTemplate.xml declares it as the
		-- PagedDetails viewsPerPage KeyValue, which is what the pager actually obeys and which XML
		-- cannot read from Lua; this copy is what HTMLBuilder uses to print a contents page number
		-- that matches what the pager will show. Change one, change the other. Code holding a frame
		-- should ask the frame (GetPageForViewDataIndex) instead of reading this.
		viewsPerPage = 2
	},
	stepValues = {1000, 500, 100, 10}
}

constants.events = {
	-- Application lifecycle events
	AddonStartup = "Addon.STARTUP",
	TimelineInit = "Timeline.INIT",
	UIRefresh = "UI.REFRESH",
	TimelinePreviousButtonVisible = "Timeline.PREVIOUS_VISIBLE",
	TimelineNextButtonVisible = "Timeline.NEXT_VISIBLE",
	DisplayTimelineLabel = "Timeline.DisplayLabel",
	DisplayTimelinePeriod = "Timeline.DisplayPeriod",
	DisplayEventsForYear = "Timeline.DisplayEventsForYear",
	SettingsEventTypeChecked = "Settings.EVENT_TYPE_CHECKED",
	SettingsCollectionChecked = "Settings.COLLECTION_CHECKED"
}

constants.eventPayloadSchemas = constants.eventPayloadSchemas or {}

constants.templateKeys = {
	EVENT_DESCRIPTION = "EVENT_DESCRIPTION",
	GENERIC_LIST_ITEM = "GENERIC_LIST_ITEM" -- For the shared vertical list template
}

-- Book content template keys. A key here must have a template registered against it in
-- UI/PageTemplatesRegistration.lua and a producer that sets it on an element, or it renders nothing
-- while looking wired up. The book renders one HTML document per page, so there is one key.
constants.bookTemplateKeys = {
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
