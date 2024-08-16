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
    -- print("TimelineMixin:TimelinePrevious")
    private.Core.Timeline:ChangePage(-1)
end

function TimelineMixin:OnTimelinePreviousVisible(isVisible)
    -- print("TimelineMixin:OnTimelinePreviousVisible " .. tostring(isVisible))
    if isVisible then
        -- print("Previous Enabled")
        self.Previous:Enable()
    else
        -- print("Previous Disabled")
        self.Previous:Disable()
    end
end

function TimelineMixin:TimelineNext()
    -- print("TimelineMixin:TimelineNext")
    private.Core.Timeline:ChangePage(1)
end

function TimelineMixin:OnTimelineNextVisible(isVisible)
    -- print("TimelineMixin:OnTimelineNextVisible " .. tostring(isVisible))
    if isVisible then
        -- print("Next Enabled")
        self.Next:Enable()
    else
        -- print("Next Disabled")
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
    -- print("OnZooming: " .. GetTime())
    private.Core.Timeline:ChangeCurrentStepValue(self.direction)
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
    -- print("Set label text " .. data)
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

function TimelinePeriodMixin:OnDisplayTimelinePeriod(eventData)
    self.data = eventData

    -- print(tostring(eventData.hasEvents))

    if eventData.hasEvents then
        self.Text:SetText(eventData.nbEvents)
        self:Show()
    else
        self:Hide()
    end
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
