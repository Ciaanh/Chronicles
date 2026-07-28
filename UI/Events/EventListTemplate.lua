local FOLDER_NAME, private = ...

-- -------------------------
-- Templates
-- -------------------------

EventListItemMixin = {}
function EventListItemMixin:Init(eventData)
	local text = self.Text
	local contentTexture = self.Content
	local sideTexture = self.Side

	text:SetText(eventData.text)
	text:SetWordWrap(true)
	text:SetMaxLines(2)
	text:SetJustifyV("MIDDLE")
	self.Event = eventData.event

	local isRightSide = self:GetParent().side == "right"
	local textMargin = 5

	-- Configure bookmark-style positioning based on side
	if isRightSide then
		contentTexture:SetTexCoord(1, 0, 0, 1)
		sideTexture:SetTexCoord(1, 0, 0, 1)

		contentTexture:ClearAllPoints()
		contentTexture:SetPoint("LEFT", self, "LEFT", 0, 0)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	else
		contentTexture:SetTexCoord(0, 1, 0, 1)
		sideTexture:SetTexCoord(0, 1, 0, 1)

		contentTexture:ClearAllPoints()
		contentTexture:SetPoint("RIGHT", self, "RIGHT", 0, 0)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("LEFT", self, "LEFT", 0, 0)
	end

	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", contentTexture, "TOPLEFT", 10, -12)
	text:SetPoint("BOTTOMRIGHT", contentTexture, "BOTTOMRIGHT", -10, 18)
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

EventListTitleMixin = {}
function EventListTitleMixin:Init(eventData)
	self.Text:SetText(eventData.text)
end

-- -------------------------
-- Event List
-- -------------------------
EventListMixin = {}
function EventListMixin:OnLoad()
	-- Ensure the paged list is configured before any data providers are applied
	if self.PagedEventList then
		self.PagedEventList:SetElementTemplateData(private.constants.templates)
		self._templatesInitialized = true
	end

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

function EventListMixin:OnUIRefresh()
	if not self.PagedEventList then
		return
	end

	if not self._templatesInitialized then
		self.PagedEventList:SetElementTemplateData(private.constants.templates)
		self._templatesInitialized = true
	end

	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
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
	if not self.PagedEventList then
		return
	end

	if not self._templatesInitialized then
		self.PagedEventList:SetElementTemplateData(private.constants.templates)
		self._templatesInitialized = true
	end

	local currentAttempt = attempt or 0
	local eventList = private.Core.Cache.getSearchEvents(period.lower, period.upper)
	private.Core.Timeline.SetYear(math.floor((period.lower + period.upper) / 2))

	local content = {
		elements = {}
	}

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
	for key, event in pairs(filteredEvents) do
		local eventSummary = {
			templateKey = private.constants.templateKeys.EVENT_DESCRIPTION,
			text = event.label,
			event = event
		}

		table.insert(content.elements, eventSummary)
	end

	local data = {}
	if numberOfEvents > 0 then
		table.insert(data, content)
	end

	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
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
