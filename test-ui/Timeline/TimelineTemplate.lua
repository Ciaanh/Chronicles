local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

-----------------------------------------------------------------------------------------
-- Timeline -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelineMixin = {}

function TimelineMixin:OnLoad()
    EventRegistry:RegisterCallback(private.constants.events.TimelineInit, self.OnTimelineInit, self)

    -- EventRegistry:RegisterCallback(private.constants.events.EventDetailPageEventSelected, self.OnTimelineLoad, self)
    -- EventRegistry:RegisterCallback(private.constants.events.EventDetailPageEventSelected, self.OnTimelineNext, self)
    -- EventRegistry:RegisterCallback(private.constants.events.EventDetailPageEventSelected, self.OnTimelinePrevious, self)
    -- EventRegistry:RegisterCallback(private.constants.events.EventDetailPageEventSelected, self.OnTimelineChangeStep, self)
end

function TimelineMixin:OnTimelineInit(eventData)
    -- load data
    private.Core.Timeline.ComputeTimelinePeriods()

    local timelineData = private.Core.Timeline.ComputeDisplayedTimeline()
    -- for k, v in pairs(timelineData) do
    --     print(k)
    --     print(v)
    -- end
    private.Core.Timeline.ComputeTimelineWindow()
end

function TimelineMixin:OnTimelineNext(eventData)
end

function TimelineMixin:OnTimelinePrevious(eventData)
end

function TimelineMixin:OnTimelineChangeStep(eventData)
end

-----------------------------------------------------------------------------------------
-- TimelineLabel ------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelineLabelMixin = {}
function TimelineLabelMixin:OnLoad()
    -- print(self.index)

    local eventName = private.constants.events.DisplayTimelineLabel .. tostring(self.index)
    -- print("Register " .. eventName)
    EventRegistry:RegisterCallback(eventName, self.OnDisplayTimelineLabel, self)
end

function TimelineLabelMixin:OnDisplayTimelineLabel(data)
    print("Set label text " .. data)
    self.Text:SetText(data)
end

-----------------------------------------------------------------------------------------
-- TimelinePeriod -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelinePeriodMixin = {}
function TimelinePeriodMixin:OnLoad()
    -- print(self.index)

    local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(self.index)
    -- print("Register " .. eventName)
    EventRegistry:RegisterCallback(eventName, self.OnDisplayTimelinePeriod, self)
end

function TimelinePeriodMixin:OnDisplayTimelinePeriod(data)
    self.data = data
    -- print("OnDisplayTimelinePeriod")
    -- EventRegistry:TriggerEvent(
    --     private.constants.events.TimelinePeriodSelected,
    --     {
    --         lower = data.lowerBound,
    --         upper = data.upperBound
    --     }
    -- )
end

function TimelinePeriodMixin:OnClick()
    -- print("OnDisplayTimelinePeriod")
    EventRegistry:TriggerEvent(
        private.constants.events.TimelinePeriodSelected,
        {
            lower = self.data.lowerBound,
            upper = self.data.upperBound
        }
    )
end
