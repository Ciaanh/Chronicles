local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-----------------------------------------------------------------------------------------
-- Timeline -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelineMixin = {}

-- arrow CovenantSanctum-Renown-Arrow-Depressed
-- CovenantSanctum-Renown-DoubleArrow
-- cyphersetupgrade-arrow-full
-- helptip-arrow
-- wowlabs-spectatecycling-arrowleft

-- ui color ideas UI-Tuskarr-Highlight-Middle

function TimelineMixin:OnLoad()
    self.ZoomOut:SetScript("OnClick", self.OnZooming)
    self.ZoomIn:SetScript("OnClick", self.OnZooming)

    self.Previous:SetScript("OnClick", self.TimelinePrevious)
    self.Next:SetScript("OnClick", self.TimelineNext)

    EventRegistry:RegisterCallback(private.constants.events.TimelineInit, self.OnTimelineInit, self)

    EventRegistry:RegisterCallback(
        private.constants.events.TimelinePreviousButtonVisible,
        self.OnTimelinePreviousVisible,
        self
    )
    EventRegistry:RegisterCallback(private.constants.events.TimelineNextButtonVisible, self.OnTimelineNextVisible, self)
    EventRegistry:RegisterCallback(private.constants.events.TimelineStepChanged, self.OnTimelineStepChanged, self)
end

function TimelineMixin:OnTimelineInit(eventData)
    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()
end

function TimelineMixin:TimelinePrevious()
    private.Core.Timeline:ChangePage(-1)
end

function TimelineMixin:OnTimelinePreviousVisible(isVisible)
    if isVisible then
        self.Previous:Enable()
    else
        self.Previous:Disable()
    end
end

function TimelineMixin:TimelineNext()
    private.Core.Timeline:ChangePage(1)
end

function TimelineMixin:OnTimelineNextVisible(isVisible)
    if isVisible then
        self.Next:Enable()
    else
        self.Next:Disable()
    end
end

function TimelineMixin:OnMouseWheel(value)
    if (value > 0) then
        private.Core.Timeline:ChangePage(-1)
    else
        private.Core.Timeline:ChangePage(1)
    end
end

function TimelineMixin:OnTimelineStepChanged(eventData)
end

function TimelineMixin:OnZooming()
    private.Core.Timeline:ChangeCurrentStepValue(self.direction)
end
-----------------------------------------------------------------------------------------
-- TimelineLabel ------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelineLabelMixin = {}
function TimelineLabelMixin:OnLoad()
    local eventName = private.constants.events.DisplayTimelineLabel .. tostring(self.index)
    EventRegistry:RegisterCallback(eventName, self.OnDisplayTimelineLabel, self)
end

function TimelineLabelMixin:OnDisplayTimelineLabel(data)
    if (data ~= nil) then
        self:Show()
        self.Text:SetText(data)
    else
        self:Hide()
    end
end

-----------------------------------------------------------------------------------------
-- TimelinePeriod -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TimelinePeriodMixin = {}
function TimelinePeriodMixin:OnLoad()
    local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(self.index)
    EventRegistry:RegisterCallback(eventName, self.OnDisplayTimelinePeriod, self)
end

function TimelinePeriodMixin:OnDisplayTimelinePeriod(periodData)
    self.data = periodData

    if (periodData ~= nil and periodData.hasEvents) then
        self.Text:SetText(periodData.nbEvents)
        self:Show()
    else
        self.Text:SetText("")
        self:Hide()
    end

    -- EventRegistry:TriggerEvent(
    --     private.constants.events.TimelinePeriodSelected,
    --     {
    --         lower = data.lowerBound,
    --         upper = data.upperBound
    --     }
    -- )
end

function TimelinePeriodMixin:OnClick()
    EventRegistry:TriggerEvent(
        private.constants.events.TimelinePeriodSelected,
        {
            lower = self.data.lowerBound,
            upper = self.data.upperBound
        }
    )

    Timeline.Period:Show()

    if self.data.lowerBound == private.constants.config.mythos then
        Timeline.Period.Text:SetText(Locale["Mythos"])
        return
    end

    if self.data.upperBound == private.constants.config.futur then
        Timeline.Period.Text:SetText(Locale["Futur"])
        return
    end

    local left = tostring(self.data.lowerBound)
    local right = tostring(self.data.upperBound)
    if self.data.lowerBound == self.data.upperBound then
        Timeline.Period.Text:SetText(left)
    else
        Timeline.Period.Text:SetText(left .. " / " .. right)
    end
end
