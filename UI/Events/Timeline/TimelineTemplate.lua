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
    -- Set localized button text
    self.ZoomOut:SetText(Locale["Zoom Out"])
    self.ZoomIn:SetText(Locale["Zoom In"])
    
    self.ZoomOut:SetScript("OnClick", self.OnZooming)
    self.ZoomIn:SetScript("OnClick", self.OnZooming)
    self.Previous:SetScript("OnClick", self.TimelinePrevious)
    self.Next:SetScript("OnClick", self.TimelineNext)

    -- Use safe event registration for events that don't have state equivalents
    private.Core.registerCallback(private.constants.events.TimelineInit, self.OnTimelineInit, self)
    private.Core.registerCallback(
        private.constants.events.TimelinePreviousButtonVisible,
        self.OnTimelinePreviousButtonVisible,
        self
    )
    private.Core.registerCallback(
        private.constants.events.TimelineNextButtonVisible,
        self.OnTimelineNextButtonVisible,
        self
    )

    -- Use state-based subscription for timeline step changes
    -- This provides a single source of truth for the current timeline step
    if private.Core.StateManager then
        private.Core.StateManager.subscribe(
            "timeline.currentStep",
            function(newStep, oldStep)
                if newStep then
                    self:OnTimelineStepChanged(newStep)
                end
            end,
            "TimelineMixin"
        )
    end
end

function TimelineMixin:OnTimelineInit(eventData)
    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()
end

function TimelineMixin:TimelinePrevious()
    private.Core.Timeline:ChangePage(-1)
end

function TimelineMixin:OnTimelinePreviousButtonVisible(isVisible)
    if isVisible then
        self.Previous:Enable()
    else
        self.Previous:Disable()
    end
end

function TimelineMixin:TimelineNext()
    private.Core.Timeline:ChangePage(1)
end

function TimelineMixin:OnTimelineNextButtonVisible(isVisible)
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
    -- Use safe event registration
    private.Core.registerCallback(eventName, self.OnDisplayTimelineLabel, self)
end

function TimelineLabelMixin:OnDisplayTimelineLabel(data)
    if (data ~= nil and data ~= "") then
        self:Show()
        self.Text:SetText(tostring(data))
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
    -- Use safe event registration
    private.Core.registerCallback(eventName, self.OnDisplayTimelinePeriod, self)
end

function TimelinePeriodMixin:OnDisplayTimelinePeriod(periodData)
    self.data = periodData

    if (periodData ~= nil and periodData.hasEvents) then
        self.Text:SetText(periodData.nbEvents)
        if periodData.nbEvents < 10 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\low-events")
        elseif periodData.nbEvents < 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\medium-events")
        elseif periodData.nbEvents >= 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\high-events")
        end
    else
        self.Text:SetText("")
        self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\no-events")
    end
end

function TimelinePeriodMixin:OnClick()
    -- Create a period data structure for state storage
    -- Only store essential data, not calculated values
    local periodData = {
        lower = self.data.lowerBound,
        upper = self.data.upperBound,
        text = self.data.text
    } -- Update state instead of triggering event - provides single source of truth
    if private.Core.StateManager then
        private.Core.StateManager.setState("ui.selectedPeriod", periodData, "Timeline period selected")
    end

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
