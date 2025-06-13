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
	self.Event = eventData.event

	if self:GetParent().side == "right" then
		contentTexture:SetTexCoord(1, 0, 0, 1)
		sideTexture:SetTexCoord(1, 0, 0, 1)

		contentTexture:ClearAllPoints()
		contentTexture:SetPoint("LEFT", self, nil, 0, 0)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("RIGHT", self, nil, 0, 0)

		text:ClearAllPoints()
		text:SetPoint("LEFT", self, nil, 0, 0)
	else
		contentTexture:SetTexCoord(0, 1, 0, 1)
		sideTexture:SetTexCoord(0, 1, 0, 1)

		contentTexture:ClearAllPoints()
		contentTexture:SetPoint("RIGHT", self, nil, 0, 0)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("LEFT", self, nil, 0, 0)

		text:ClearAllPoints()
		text:SetPoint("RIGHT", self, nil, 0, 0)
	end
end

function EventListItemMixin:OnClick()
	-- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		-- Use the centralized state key builder for entity selection
		local selectionKey = private.Core.StateManager.buildSelectionKey("event")

		-- Pass both event ID and collection name for unique identification
		local eventSelection = nil
		if self.Event and self.Event.id then
			eventSelection = {
				eventId = self.Event.id,
				collectionName = self.Event.source or "Origins" -- Default to Origins if source not available
			}
		end
		private.Core.StateManager.setState(selectionKey, eventSelection, "Event selected from list")
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
	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	-- Use state-based subscription for period selection
	-- This aligns with the architectural direction of using state for UI updates
	if private.Core.StateManager then
		local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
		private.Core.StateManager.subscribe(
			selectedPeriodKey,
			function(newPeriod, oldPeriod)
				if newPeriod then
					self:UpdateFromSelectedPeriod(newPeriod)
				end
			end,
			"EventListMixin"
		)
	end

	self.PagedEventList:SetElementTemplateData(private.constants.templates)
end

function EventListMixin:OnUIRefresh()
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end

function EventListMixin:OnTimelinePeriodSelected(period)
	self:UpdateFromSelectedPeriod(period)
end

function EventListMixin:UpdateFromSelectedPeriod(period)
	local eventList = private.Core.Cache.getSearchEvents(period.lower, period.upper)
	private.Core.Timeline.SetYear(math.floor((period.lower + period.upper) / 2))

	local content = {
		elements = {}
	}

	local filteredEvents = private.Core.Events.FilterEvents(eventList)
	for key, event in pairs(filteredEvents) do
		local eventSummary = {
			templateKey = private.constants.templateKeys.EVENT_DESCRIPTION,
			text = event.label,
			event = event
		}

		table.insert(content.elements, eventSummary)
	end

	local data = {}
	table.insert(data, content)

	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end
