local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

-----------------------------------------------------------------------------------------
-- Templates ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

EventListItemMixin = {}
function EventListItemMixin:Init(text)
	print("EventListItemMixin:Init")

	self.Text:SetText(text)
end

function EventListItemMixin:OnClick()
	print("EventListItemMixin:OnClick")
end

EventListTitleMixin = {}
function EventListTitleMixin:Init(text)
	if text ~= nil then
		self.Text:SetText(text)
	end
end

-----------------------------------------------------------------------------------------
-- Event List ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- local Templates = {
-- 	["TITLE"] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
-- 	["ITEM"] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init}
-- }

EventListMixin = {}
function EventListMixin:OnLoad()
	EventRegistry:RegisterCallback(private.constants.events.TimelinePeriodSelected, self.OnTimelinePeriodSelected, self)

	self.PagedEventList:SetElementTemplateData(
		{
			["TITLE"] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
			["ITEM"] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init}
		}
	)
end

function EventListMixin:OnTimelinePeriodSelected(period)
	print("EventListMixin:OnTimelinePeriodSelected " .. tostring(period.lower) .. " " .. tostring(period.upper))
	local data = {}

	local eventList = Chronicles.DB:SearchEvents(period.lower, period.upper)
	private.Core.Timeline.SetYear(math.floor((period.lower + period.upper) / 2))

	local content = {
		header = {
			templateKey = "TITLE",
			text = tostring(period.lower) .. " " .. tostring(period.upper)
		},
		elements = {}
	}

	local filteredEvents = private.Core.Events.FilterEvents(eventList)
	print(tostring(#filteredEvents))
	for key, event in pairs(filteredEvents) do
		print(event.label)
		table.insert(
			content.elements,
			{
				templateKey = "ITEM",
				text = event.label
			}
		)
	end

	table.insert(data, content)

	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	self.PagedEventList:SetDataProvider(dataProvider, retainScrollPosition)
end
