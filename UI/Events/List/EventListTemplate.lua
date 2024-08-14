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
		-- print("right " .. eventData.text)

		-- self.Text:SetJustifyH("LEFT")

		contentTexture:SetTexCoord(1, 0, 0, 1)
		sideTexture:SetTexCoord(1, 0, 0, 1)

		--actionButton:GetWidth(), actionButton:GetHeight()
		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("LEFT", self, "RIGHT", 0, 0)
		sideTexture:SetSize(50, self.textureHeight)
	else
		-- self.Text:SetJustifyH("RIGHT")

		contentTexture:SetTexCoord(0, 1, 0, 1)
		sideTexture:SetTexCoord(0, 1, 0, 1)

		sideTexture:ClearAllPoints()
		sideTexture:SetPoint("RIGHT", self, "LEFT", 0, 0)
		sideTexture:SetSize(50, self.textureHeight)
	end
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

	self.PagedEventList:SetElementTemplateData(private.constants.templates)
end

function EventListMixin:OnTimelinePeriodSelected(period)
	-- print("EventListMixin:OnTimelinePeriodSelected " .. tostring(period.lower) .. " " .. tostring(period.upper))
	local data = {}

	local eventList = Chronicles.DB:SearchEvents(period.lower, period.upper)
	private.Core.Timeline:SetYear(math.floor((period.lower + period.upper) / 2))

	-- //TODO find other place for the dates of the period
	local content = {
		-- header = {
		-- 	templateKey = private.constants.templateKeys.PERIOD_TITLE,
		-- 	text = tostring(period.lower) .. " " .. tostring(period.upper)
		-- },
		elements = {}
	}

	local filteredEvents = private.Core.Events.FilterEvents(eventList)
	-- print(tostring(#filteredEvents))
	for key, event in pairs(filteredEvents) do
		-- print(event.label)
		local eventSummary = {
			templateKey = private.constants.templateKeys.EVENT_DESCRIPTION,
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
