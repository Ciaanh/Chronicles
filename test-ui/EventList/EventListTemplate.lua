local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

EventListMixin = {}

function EventListMixin:OnLoad()
	EventRegistry:RegisterCallback(private.constants.events.TimelinePeriodSelected, self.OnTimelinePeriodSelected, self)
end

function EventListMixin:OnTimelinePeriodSelected(eventData)
	-- self:ShowEvent(eventData)
	print(tostring(eventData.lower) .. " " .. tostring(eventData.upper))
end
