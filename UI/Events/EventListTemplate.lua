local FOLDER_NAME, private = ...

local Spacing = private.Core.Utils.Spacing

-- -------------------------
-- Templates
-- -------------------------

EventListItemMixin = {}
function EventListItemMixin:Init(eventData)
	local text = self.Text

	text:SetText(eventData.text)
	text:SetWordWrap(true)
	text:SetMaxLines(2)
	text:SetJustifyV("MIDDLE")
	self.Event = eventData.event

	-- Texture and text placement is entirely the template's. This used to mirror the bookmark art
	-- for right-hand rows, driven by a "side" KeyValue on the row's parent that went away with the
	-- two-column split; re-applying single points here would now collapse the Content texture,
	-- which stretches between two anchors.
end

function EventListItemMixin:OnClick()
	-- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		-- Use the centralized state key builder for entity selection
		local selectionKey = private.Core.StateManager.buildSelectionKey("event")
		local currentSelection = private.Core.StateManager.getState(selectionKey)

		-- Pass both event ID and collection name for unique identification
		local eventSelection = nil
		if self.Event and self.Event.id then
			local collectionName = self.Event.source or "Origins"

			if currentSelection and currentSelection.eventId == self.Event.id and currentSelection.collectionName == collectionName then
				return
			end

			eventSelection = {
				eventId = self.Event.id,
				collectionName = collectionName
			}
		elseif currentSelection == nil then
			-- No change required when clearing an already empty selection
			return
		end
		private.Core.StateManager.setState(selectionKey, eventSelection, "Event selected from list", {skipIfUnchanged = true})
	end
end

-- -------------------------
-- Event List
-- -------------------------
EventListMixin = {}
function EventListMixin:OnLoad()
	self:InitializeEventList()

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

		self:HydrateFromState()
	else
		self:OnUIRefresh()
	end
end

--[[
    Wire the event scroll box to its scroll bar with a linear, single-column view

    The row template is resolved through the shared template registry so
    templateKeys.EVENT_DESCRIPTION stays the single source of truth for what an event row looks like.
]]
function EventListMixin:InitializeEventList()
	if not self.EventScrollList or not self.EventScrollBar then
		return
	end

	local rowTemplate = private.constants.templates[private.constants.templateKeys.EVENT_DESCRIPTION]
	if not rowTemplate or not rowTemplate.template then
		return
	end

	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer(
		rowTemplate.template,
		function(row, elementData)
			row:Init(elementData)
		end
	)
	view:SetPadding(Spacing.xs, Spacing.xs, 0, 0, Spacing.xs)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.EventScrollList, self.EventScrollBar, view)
end

--[[
    Replace the rail contents with a flat list of event rows

    @param elements [table] Sequential array of event row descriptors (may be empty)
]]
function EventListMixin:SetEventDataProvider(elements)
	if not self.EventScrollList then
		return
	end

	local dataProvider = CreateDataProvider(elements or {})
	local retainScrollPosition = false
	self.EventScrollList:SetDataProvider(dataProvider, retainScrollPosition)
end

function EventListMixin:OnUIRefresh()
	self:SetEventDataProvider({})
end

function EventListMixin:OnTimelinePeriodSelected(period)
	self:UpdateFromSelectedPeriod(period)
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

	-- ipairs, not pairs: FilterEvents returns a sequential array and the rail's order must be
	-- reproducible from one selection to the next.
	local elements = {}
	for _, event in ipairs(filteredEvents) do
		table.insert(
			elements,
			{
				templateKey = private.constants.templateKeys.EVENT_DESCRIPTION,
				text = event.label,
				event = event
			}
		)
	end

	self:SetEventDataProvider(elements)
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
