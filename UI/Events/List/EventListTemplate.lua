local FOLDER_NAME, private = ...

-----------------------------------------------------------------------------------------
-- Templates ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

EventListItemMixin = {}
function EventListItemMixin:Init(eventData)
	self.Text:SetText(eventData.text)
	self.Event = eventData.event

	local contentTexture = self.Content
	local sideTexture = self.Side

	if self:GetParent().side == "right" then
		contentTexture:SetTexCoord(1, 0, 0, 1)
		sideTexture:SetTexCoord(1, 0, 0, 1)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("LEFT", self, "RIGHT", 0, 0)
		sideTexture:SetSize(50, self.textureHeight)
	else
		contentTexture:SetTexCoord(0, 1, 0, 1)
		sideTexture:SetTexCoord(0, 1, 0, 1)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("RIGHT", self, "LEFT", 0, 0)
		sideTexture:SetSize(50, self.textureHeight)
	end
end

function EventListItemMixin:OnClick()
	-- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		-- Pass both event ID and collection name for unique identification
		local eventSelection = nil
		if self.Event and self.Event.id then
			eventSelection = {
				eventId = self.Event.id,
				collectionName = self.Event.source or "Origins" -- Default to Origins if source not available
			}
		end
		private.Core.StateManager.setState("ui.selectedEvent", eventSelection, "Event selected from list")
	end
end

EventListTitleMixin = {}
function EventListTitleMixin:Init(eventData)
	self.Text:SetText(eventData.text)
end

-----------------------------------------------------------------------------------------
-- Event List ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
EventListMixin = {}
function EventListMixin:OnLoad()
	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
	-- Use state-based subscription for period selection
	-- This aligns with the architectural direction of using state for UI updates
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedPeriod",
			function(newPeriod, oldPeriod)
				if newPeriod then
					private.Core.Logger.trace("EventListMixin", "Received selectedPeriod state change notification")
					self:UpdateFromSelectedPeriod(newPeriod)
				else
					private.Core.Logger.trace("EventListMixin", "Received selectedPeriod state change with nil period")
				end
			end,
			"EventListMixin"
		)
	end
	self.PagedEventList:SetElementTemplateData(private.constants.templates)
end

function EventListMixin:OnUIRefresh()
	private.Core.Logger.trace("EventListMixin", "OnUIRefresh triggered - clearing event list data")

	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	private.Core.Logger.trace("EventListMixin", "Setting empty data provider to PagedEventList")
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)

	private.Core.Logger.trace("EventListMixin", "OnUIRefresh completed - event list cleared")
end

function EventListMixin:OnTimelinePeriodSelected(period)
	self:UpdateFromSelectedPeriod(period)
end

function EventListMixin:UpdateFromSelectedPeriod(period)
	private.Core.Logger.trace(
		"EventListMixin",
		"UpdateFromSelectedPeriod called with period: " ..
			tostring(period and period.lower) .. "-" .. tostring(period and period.upper)
	)

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
