local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

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
	-- Use safe event triggering
	private.Core.triggerEvent(private.constants.events.EventSelected, self.Event, "EventListItem:OnClick")
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
	-- Use safe event registration
	private.Core.registerCallback(
		private.constants.events.TimelinePeriodSelected,
		self.OnTimelinePeriodSelected,
		self
	)
	private.Core.registerCallback(private.constants.events.TimelineClean, self.OnTimelineClean, self)

	self.PagedEventList:SetElementTemplateData(private.constants.templates)
end

function EventListMixin:OnTimelineClean()
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end

function EventListMixin:OnTimelinePeriodSelected(period)
	local data = {}

	local eventList = Chronicles.Data:SearchEvents(period.lower, period.upper)
	private.Core.Timeline:SetYear(math.floor((period.lower + period.upper) / 2))

	-- TODO find other place for the dates of the period
	local content = {
		-- header = {
		-- 	templateKey = private.constants.templateKeys.PERIOD_TITLE,
		-- 	text = tostring(period.lower) .. " " .. tostring(period.upper)
		-- },
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

	table.insert(data, content)

	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end
