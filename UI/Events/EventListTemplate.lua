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

	-- Period breakdown: a slice of the period (index into self.buckets) and an event type, each nil
	-- when not narrowing. Both reset when another period is selected.
	self.buckets = {}
	self.activeBucket = nil
	self.activeType = nil
	self.barPool = {}
	self.chipPool = {}

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
	self.currentPeriod = nil
	self.activeBucket = nil
	self.activeType = nil
	self:RefreshBreakdown()
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

	-- A new period starts un-narrowed; the same period re-delivered (a settings change, a refresh)
	-- keeps the reader's narrowing.
	local isSamePeriod =
		self.currentPeriod and self.currentPeriod.lower == period.lower and self.currentPeriod.upper == period.upper
	if not isSamePeriod then
		self.activeBucket = nil
		self.activeType = nil
	end
	self.currentPeriod = period

	self:RefreshBreakdown()
	self:DisplayEvents(self:ApplyFilters())
end

--[[
    The period's events narrowed by the selected slice, the selected type and the search box

    @return [table] Sequential array, still in FilterEvents order (yearStart, then order)
]]
function EventListMixin:ApplyFilters()
	local bucket = self.activeBucket and self.buckets[self.activeBucket]
	local activeType = self.activeType
	local period = self.currentPeriod
	local business = private.Core.Data.TimelineBusiness

	local narrowed = {}
	for _, event in ipairs(self.periodEvents or {}) do
		local inBucket = not bucket or not period or business.isEventInBucket(event, bucket, period.lower, period.upper)
		local isType = not activeType or (event.eventType or 0) == activeType
		if inBucket and isType then
			table.insert(narrowed, event)
		end
	end

	return self:FilterEventsByLabel(narrowed, self.currentSearchTerm)
end

-- =============================================================================================
-- PERIOD BREAKDOWN (bars per slice, chips per event type)
-- =============================================================================================

local BAR_MAX_HEIGHT = 28
local BUCKET_COUNT = 10
local CHIP_GAP = 6
local CHIP_HEIGHT = 22
-- The label plate's scroll ends take about 14 on each side; the text must sit between them
local CHIP_TEXT_PADDING = 32

-- The row frames can report a zero width before the first layout pass; the rail's geometry is fixed
-- (292 wide, controls 12 in on the left and 24 on the right), so fall back to it.
local function rowWidth(frame)
	local width = frame and frame:GetWidth() or 0
	if width and width > 0 then
		return width
	end
	return 256
end

function EventListMixin:RefreshBreakdown()
	local business = private.Core.Data.TimelineBusiness
	local period = self.currentPeriod

	self.buckets = {}
	if period and business then
		self.buckets = business.buildYearBuckets(self.periodEvents, period.lower, period.upper, BUCKET_COUNT)
	end

	self:BuildYearBars()
	self:BuildTypeChips()
end

function EventListMixin:BuildYearBars()
	local UIUtils = private.Core.Utils.UIUtils
	local row = self.YearBars
	if not row or not UIUtils then
		return
	end

	local buckets = self.buckets or {}
	local count = #buckets

	-- Mythos and Futur are unbounded: there is no slice to draw, so the row folds away
	if count == 0 then
		UIUtils.ReleaseFramesAbove(self.barPool, 0)
		row:SetHeight(1)
		return
	end
	row:SetHeight(42)

	local maxCount = 0
	for _, bucket in ipairs(buckets) do
		maxCount = math.max(maxCount, bucket.count)
	end

	local barWidth = rowWidth(row) / count
	local singleYears = buckets[1].lower == buckets[1].upper

	for index, bucket in ipairs(buckets) do
		local bar = UIUtils.AcquirePooledFrame(self.barPool, "EventListYearBarTemplate", row, index, "Button")
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * barWidth, 0)
		bar:SetSize(barWidth, 42)

		-- One label per bar when a bar is one year; otherwise only the two ends, which is all that
		-- fits in a 25 wide slot once years run to four or five digits.
		local labelText = nil
		if singleYears then
			labelText = tostring(bucket.lower)
		elseif index == 1 then
			labelText = tostring(bucket.lower)
		elseif index == count then
			labelText = tostring(bucket.upper)
		end

		bar:Init(self, index, bucket, maxCount, labelText, self.activeBucket == index)
	end
	UIUtils.ReleaseFramesAbove(self.barPool, count)
end

function EventListMixin:BuildTypeChips()
	local UIUtils = private.Core.Utils.UIUtils
	local business = private.Core.Data.TimelineBusiness
	local row = self.TypeRow
	if not row or not UIUtils or not business then
		return
	end

	local counts, total = business.countEventsByType(self.periodEvents)
	if total == 0 then
		UIUtils.ReleaseFramesAbove(self.chipPool, 0)
		row:SetHeight(1)
		return
	end

	-- "All" first, then each type present, in the order of constants.eventType
	local chips = {{typeId = nil, text = string.format(Locale["EventListTypeChip"], Locale["EventListTypeAll"], total)}}
	for typeId = 0, #private.constants.eventType do
		local typeCount = counts[typeId]
		if typeCount and typeCount > 0 then
			local typeName = private.constants.eventType[typeId]
			table.insert(chips, {typeId = typeId, text = string.format(Locale["EventListTypeChip"], Locale[typeName] or typeName, typeCount)})
		end
	end

	-- Flow layout: chips wrap onto a new line when the next one would pass the row's right edge
	local width = rowWidth(row)
	local x, y, lines = 0, 0, 1
	for index, chipData in ipairs(chips) do
		local chip = UIUtils.AcquirePooledFrame(self.chipPool, "EventListTypeChipTemplate", row, index, "Button")
		chip:Init(self, chipData.typeId, chipData.text, self.activeType == chipData.typeId)

		local chipWidth = math.min(width, chip.Text:GetStringWidth() + CHIP_TEXT_PADDING)
		if x > 0 and x + chipWidth > width then
			x = 0
			y = y + CHIP_HEIGHT + CHIP_GAP
			lines = lines + 1
		end

		chip:ClearAllPoints()
		chip:SetPoint("TOPLEFT", row, "TOPLEFT", x, -y)
		chip:SetSize(chipWidth, CHIP_HEIGHT)
		x = x + chipWidth + CHIP_GAP
	end
	UIUtils.ReleaseFramesAbove(self.chipPool, #chips)

	row:SetHeight(lines * CHIP_HEIGHT + (lines - 1) * CHIP_GAP)
end

function EventListMixin:ToggleBucket(index)
	self.activeBucket = (self.activeBucket ~= index) and index or nil
	self:BuildYearBars()
	self:DisplayEvents(self:ApplyFilters())
end

function EventListMixin:ToggleType(typeId)
	-- The "All" chip carries no type and always clears the narrowing
	if typeId == nil or self.activeType == typeId then
		self.activeType = nil
	else
		self.activeType = typeId
	end
	self:BuildTypeChips()
	self:DisplayEvents(self:ApplyFilters())
end

-- -------------------------
-- Year bar
-- -------------------------
EventListYearBarMixin = {}

function EventListYearBarMixin:Init(list, index, bucket, maxCount, labelText, selected)
	self.list = list
	self.index = index
	self.bucket = bucket

	if bucket.count > 0 and maxCount > 0 then
		self.Bar:SetHeight(math.max(2, math.floor(BAR_MAX_HEIGHT * bucket.count / maxCount)))
		self.Bar:Show()
	else
		self.Bar:Hide()
	end

	-- Gold when it is the slice narrowing the rail, bronze otherwise
	if selected then
		self.Bar:SetColorTexture(1, 0.82, 0, 1)
	else
		self.Bar:SetColorTexture(0.55, 0.43, 0.23, 1)
	end

	self.Label:SetText(labelText or "")
	if selected then
		self.Label:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	elseif bucket.count > 0 then
		self.Label:SetTextColor(0.8, 0.8, 0.8)
	else
		self.Label:SetTextColor(0.45, 0.45, 0.45)
	end
end

function EventListYearBarMixin:OnClick()
	if self.list then
		self.list:ToggleBucket(self.index)
	end
end

function EventListYearBarMixin:OnEnter()
	local bucket = self.bucket
	if not bucket then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	if bucket.lower == bucket.upper then
		GameTooltip:SetText(string.format(Locale["EventListBucketYear"], bucket.lower), 1, 1, 1)
	else
		GameTooltip:SetText(string.format(Locale["EventListBucketYears"], bucket.lower, bucket.upper), 1, 1, 1)
	end
	GameTooltip:AddLine(string.format(Locale["EventListBucketCount"], bucket.count))
	GameTooltip:Show()
end

function EventListYearBarMixin:OnLeave()
	GameTooltip:Hide()
end

-- -------------------------
-- Event-type chip
-- -------------------------
EventListTypeChipMixin = {}

function EventListTypeChipMixin:Init(list, typeId, text, selected)
	self.list = list
	self.typeId = typeId
	self:SetText(text)
	self.SelectedGlow:SetShown(selected)
end

function EventListTypeChipMixin:OnClick()
	if self.list then
		self.list:ToggleType(self.typeId)
	end
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
			self:DisplayEvents(self:ApplyFilters())
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
