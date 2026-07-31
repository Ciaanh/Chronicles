local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

local Spacing = private.Core.Utils.Spacing

-- How long to wait after the last keystroke before re-filtering. Same value the other rail uses.
local SEARCH_THROTTLE_SECONDS = 0.3

-- -------------------------
-- Event List
--
-- Rows are VerticalListItemMixin (UI/VerticalListTemplate.lua). This file no longer declares a row
-- mixin of its own: the Events row template and the shared one drew the same bookmark art at two
-- heights, and only the shared one carried hover and a selected state. What stays here is the list
-- itself, which is period-driven rather than search-driven: the timeline decides which events are here
-- and the search box narrows that set, where VerticalListMixin searches its whole collection.
-- -------------------------
EventListMixin = {}
function EventListMixin:OnLoad()
	self:InitializeEventList()

	-- The period's unfiltered events, so clearing the search box restores them without a refetch
	self.periodEvents = {}
	self.currentSearchTerm = ""

	self:InitializeSearchPlaceholder()

	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
	private.Core.registerCallback(private.constants.events.TimelineInit, self.OnTimelineInit, self)

	-- Use state-based subscription for period selection
	-- This aligns with the architectural direction of using state for UI updates
	if private.Core.StateManager then
		local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
		private.Core.StateManager.subscribe(
			selectedPeriodKey,
			function(newPeriod, oldPeriod)
				if newPeriod then
					self:UpdateFromSelectedPeriod(newPeriod)
				else
					self:OnUIRefresh()
				end
			end,
			"EventListMixin"
		)

		-- Selection, so the row for the open book stays lit however the selection was made: from this
		-- rail, or from a timeline period that changed which event is current. Two fields identify an
		-- event, not one -- ids are only unique within a collection.
		local selectedEventKey = private.Core.StateManager.buildSelectionKey("event")
		private.Core.StateManager.subscribe(
			selectedEventKey,
			function()
				self:SyncWithCurrentSelection()
			end,
			"EventListMixin:selection"
		)

		self:HydrateFromState()
	else
		self:OnUIRefresh()
	end
end

--[[
    Wire the event scroll box to its scroll bar with a linear, single-column view

    EventScrollList is a WowScrollBoxList and EventScrollBar a MinimalScrollBar, both declared in
    EventListTemplate.xml. A view must be attached before any data provider is assigned, so this
    runs once and is idempotent. The row template is resolved through the shared template registry
    so templateKeys.EVENT_DESCRIPTION stays the single source of truth for what an event row looks
    like.
]]
function EventListMixin:InitializeEventList()
	if self._eventViewReady or not self.EventScrollList or not self.EventScrollBar then
		return
	end

	local rowTemplate = private.constants.templates[private.constants.templateKeys.EVENT_DESCRIPTION]
	if not rowTemplate or not rowTemplate.template then
		return
	end

	local view = CreateScrollBoxListLinearView(Spacing.xs, Spacing.xs, 0, 0, Spacing.xs)
	view:SetElementInitializer(
		rowTemplate.template,
		function(row, elementData)
			row:Init(elementData)
		end
	)
	-- Fixed row height; skips the per-frame measurement pass that can otherwise yield a zero extent.
	-- Must stay equal to VerticalListItemTemplate's <Size y> in VerticalListTemplate.xml and to the
	-- extent the Characters/Factions rail sets: one row template, one height, declared three times
	-- because the view reads the extent and never the template's Size.
	view:SetElementExtent(88)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.EventScrollList, self.EventScrollBar, view)
	self._eventViewReady = true
end

--[[
    Replace the rail contents with a flat list of event rows

    @param elements [table] Sequential array of event row descriptors (may be empty)
]]
function EventListMixin:SetEventDataProvider(elements)
	self:InitializeEventList()

	if not self._eventViewReady or not self.EventScrollList.SetDataProvider then
		return
	end

	self.EventScrollList:SetDataProvider(CreateDataProvider(elements or {}), ScrollBoxConstants.DiscardScrollPosition)
end

function EventListMixin:OnUIRefresh()
	self.periodEvents = {}
	self:SetEventDataProvider({})
	self:UpdateItemCount(0)
end

local MAX_RETRY_ATTEMPTS = 3
local RETRY_DELAY_SECONDS = 0.2

local function scheduleRetry(handler, delay)
	if not handler then
		return
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(delay, handler)
	end
end

local function hasEventsMeta(period)
	if not period then
		return false
	end

	if period.nbEvents and period.nbEvents > 0 then
		return true
	end

	return period.hasEvents == true
end

function EventListMixin:UpdateFromSelectedPeriod(period, attempt)
	if not self.EventScrollList then
		return
	end

	local currentAttempt = attempt or 0
	local eventList = private.Core.Cache.getSearchEvents(period.lower, period.upper)
	private.Core.Timeline.SetYear(math.floor((period.lower + period.upper) / 2))

	local filteredEvents = private.Core.Events.FilterEvents(eventList)
	local numberOfEvents = #filteredEvents

	if numberOfEvents == 0 and hasEventsMeta(period) and currentAttempt < MAX_RETRY_ATTEMPTS then
		scheduleRetry(
			function()
				self:UpdateFromSelectedPeriod(period, currentAttempt + 1)
			end,
			RETRY_DELAY_SECONDS
		)
		return
	end

	-- The period's events, cached unfiltered so clearing the search box restores them without going
	-- back to the cache or re-running the event-type filter.
	self.periodEvents = filteredEvents

	self:DisplayEvents(self:FilterEventsByLabel(filteredEvents, self.currentSearchTerm))
end

--[[
    Turn a list of events into rail rows and hand it to the scroll box.

    @param events [table] Sequential array of event records
]]
function EventListMixin:DisplayEvents(events)
	events = events or {}

	-- ipairs, not pairs: the caller passes a sequential array and the rail's order must be
	-- reproducible from one selection to the next.
	local elements = {}
	for _, event in ipairs(events) do
		-- The shared row reads item.name at three sites (the Init guard, the label, the tooltip) and
		-- events carry their display string as label, so give the record a name here rather than
		-- teaching the row a second field. Safe to write onto: getSearchEvents hands back
		-- SearchEngine.cleanEventObject projections, not the DB records.
		event.name = event.name or event.label

		table.insert(
			elements,
			{
				templateKey = private.constants.templateKeys.EVENT_DESCRIPTION,
				item = event,
				-- itemType and stateManagerKey travel with each row; see VerticalListItemMixin:Init.
				-- "event" is what makes OnClick write {eventId, collectionName}, which is the only
				-- shape MainFrameUI:UpdateEventBookContent will open a book for.
				itemType = "event",
				stateManagerKey = "event"
			}
		)
	end

	self:SetEventDataProvider(elements)
	self:UpdateItemCount(#elements)
	self:SyncWithCurrentSelection()
end

-- =============================================================================================
-- SEARCH, COUNT AND SELECTION
-- =============================================================================================

function EventListMixin:InitializeSearchPlaceholder()
	if self.SearchBox and self.SearchBox.PlaceholderText then
		self.SearchBox.PlaceholderText:SetText(Locale["SearchEventsPlaceholder"])
		self.SearchBox.PlaceholderText:Show()
	end
end

--[[
    Narrow the current period's events by label.

    Scoped to the period on purpose: the period is what put these rows here, and a box that sometimes
    searched the whole database and sometimes the current period would be two features wearing one
    control. Searching across periods is a real want, and a different surface: see the note in
    vnext/IMPL-Chronicles-UI.md A2b.

    @param events [table] Sequential array of event records
    @param searchTerm [string|nil]
    @return [table] Sequential array, the input unchanged when there is no term
]]
function EventListMixin:FilterEventsByLabel(events, searchTerm)
	if not events or not searchTerm or searchTerm == "" then
		return events or {}
	end

	local filtered = {}
	local lowerSearchTerm = string.lower(searchTerm)

	for _, event in ipairs(events) do
		local label = event.name or event.label
		if label and string.find(string.lower(label), lowerSearchTerm, 1, true) then
			table.insert(filtered, event)
		end
	end

	return filtered
end

function EventListMixin:OnSearchTextChanged(text)
	self.currentSearchTerm = text or ""

	-- Throttle: re-filtering on every keystroke rebuilds the whole data provider
	if self.searchThrottle then
		self.searchThrottle:Cancel()
	end

	self.searchThrottle =
		C_Timer.NewTimer(
		SEARCH_THROTTLE_SECONDS,
		function()
			self:DisplayEvents(self:FilterEventsByLabel(self.periodEvents, self.currentSearchTerm))
		end
	)
end

function EventListMixin:UpdateItemCount(count)
	if self.CountLabel then
		self.CountLabel:SetText(string.format(Locale["ListCountEvents"], count or 0))
	end
end

--[[
    Light the row whose event is the current selection, and unlight the rest.

    An event needs both its id and its collection to be identified: ids are unique within a collection,
    not across them. The character and faction rails compare one field; this one compares two.
]]
function EventListMixin:SyncWithCurrentSelection()
	if not private.Core.StateManager or not self._eventViewReady then
		return
	end

	if not self.EventScrollList or type(self.EventScrollList.ForEachFrame) ~= "function" then
		return
	end

	local selection = private.Core.StateManager.getState(private.Core.StateManager.buildSelectionKey("event"))
	local selectedId = selection and selection.eventId
	local selectedCollection = selection and selection.collectionName

	self.EventScrollList:ForEachFrame(
		function(row)
			if row and row.SetSelected then
				local item = row.Item
				local isSelected =
					selectedId ~= nil and item ~= nil and item.id == selectedId and item.source == selectedCollection

				row:SetSelected(isSelected)
			end
		end
	)
end

function EventListMixin:HydrateFromState()
	if not private.Core.StateManager then
		self:OnUIRefresh()
		return
	end

	local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
	local currentPeriod = private.Core.StateManager.getState(selectedPeriodKey)
	if currentPeriod then
		self:UpdateFromSelectedPeriod(currentPeriod)
	else
		self:OnUIRefresh()
	end
end

function EventListMixin:OnTimelineInit(eventData)
	self:HydrateFromState()
end
