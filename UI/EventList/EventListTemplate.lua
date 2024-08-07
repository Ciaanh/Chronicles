local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

-----------------------------------------------------------------------------------------
-- Templates ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

EventListItemMixin = {}
function EventListItemMixin:Init(eventData)
	self.Text:SetText(eventData.text)
	self.Event = eventData.event
end

function EventListItemMixin:OnClick()
	EventRegistry:TriggerEvent(private.constants.events.EventDetailPageEventSelected, self.Event)
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
	EventRegistry:RegisterCallback(private.constants.events.TimelinePeriodSelected, self.OnTimelinePeriodSelected, self)

	self.PagedEventList:SetElementTemplateData(
		{
			["PERIOD_TITLE"] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
			["EVENT"] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init}
		}
	)
end

function EventListMixin:OnTimelinePeriodSelected(period)
	-- print("EventListMixin:OnTimelinePeriodSelected " .. tostring(period.lower) .. " " .. tostring(period.upper))
	local data = {}

	local eventList = Chronicles.DB:SearchEvents(period.lower, period.upper)
	private.Core.Timeline:SetYear(math.floor((period.lower + period.upper) / 2))

	local content = {
		header = {
			templateKey = "PERIOD_TITLE",
			text = tostring(period.lower) .. " " .. tostring(period.upper)
		},
		elements = {}
	}

	local filteredEvents = private.Core.Events.FilterEvents(eventList)
	-- print(tostring(#filteredEvents))
	for key, event in pairs(filteredEvents) do
		-- print(event.label)
		local eventSummary = {
			templateKey = "EVENT",
			text = event.label,
			event = event
		}
		-- print(eventSummary.templateKey .. " " .. eventSummary.text)

		table.insert(content.elements, eventSummary)
	end

	table.insert(data, content)

	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end
