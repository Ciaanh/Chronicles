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
    self.ZoomOut:SetScript(
        "OnClick",
        function()
            private.Core.Timeline.ChangeCurrentStepValue(-1)
        end
    )
    self.ZoomIn:SetScript(
        "OnClick",
        function()
            private.Core.Timeline.ChangeCurrentStepValue(1)
        end
    )
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

    -- Immediately initialize the timeline when UI is loaded
    -- This ensures timeline is populated even if TimelineInit event hasn't been triggered
    C_Timer.After(
        0.1,
        function()
            self:OnTimelineInit()
        end
    )

    -- Use state-based subscription for timeline step changes
    -- This provides a single source of truth for the current timeline step
    if private.Core.StateManager then
        private.Core.StateManager.subscribe(
            "timeline.currentStep",
            function(newStep, oldStep)
                -- Timeline step changed - update zoom level indicator
                self:UpdateZoomLevelIndicator(newStep)
                private.Core.Logger.trace(
                    "TimelineMixin",
                    "Timeline step changed from " .. tostring(oldStep) .. " to " .. tostring(newStep)
                )
            end,
            "TimelineMixin"
        )
    end

    -- Initialize zoom level indicator
    self:UpdateZoomLevelIndicator(
        private.Core.StateManager.getState("timeline.currentStep") or private.constants.config.stepValues[1]
    )
end

function TimelineMixin:OnTimelineInit(eventData)
    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()
end

function TimelineMixin:TimelinePrevious()
    private.Core.Timeline.ChangePage(-1)
end

function TimelineMixin:OnTimelinePreviousButtonVisible(isVisible)
    if isVisible then
        self.Previous:Enable()
    else
        self.Previous:Disable()
    end
end

function TimelineMixin:TimelineNext()
    private.Core.Timeline.ChangePage(1)
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
        private.Core.Timeline.ChangePage(-1)
    else
        private.Core.Timeline.ChangePage(1)
    end
end

function TimelineMixin:UpdateZoomLevelIndicator(stepValue)
    if not self.ZoomLevelIndicator or not self.ZoomLevelIndicator.Text then
        return
    end

    local displayText = ""
    if stepValue then
        displayText = tostring(stepValue) .. Locale["years"]
    else
        displayText = "?" .. Locale["years"]
    end

    self.ZoomLevelIndicator.Text:SetText(displayText)
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

    -- Highlight logic
    local selectedPeriod = private.Core.StateManager.getState("ui.selectedPeriod")
    local isSelected =
        selectedPeriod and periodData and selectedPeriod.lower == periodData.lowerBound and
        selectedPeriod.upper == periodData.upperBound

    if (periodData ~= nil and periodData.hasEvents) then
        self.Text:SetText(periodData.nbEvents)
        local select = isSelected and "-selected" or "" -- gold for selected, white for unselected

        if periodData.nbEvents < 10 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\low-events" .. select)
        elseif periodData.nbEvents < 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\medium-events" .. select)
        elseif periodData.nbEvents >= 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\high-events" .. select)
        end
    else
        self.Text:SetText("")
        self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\no-events")
    end

    -- Always reset background color to normal
    self.Background:SetVertexColor(1, 1, 1)
end

function TimelinePeriodMixin:ResetAllPeriodTextures()
    local periods = {
        Period1,
        Period2,
        Period3,
        Period4,
        Period5,
        Period6,
        Period7,
        Period8
    }

    for _, period in ipairs(periods) do
        if period.data and period.data.hasEvents then
            if period.data.nbEvents < 10 then
                period.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\low-events")
            elseif period.data.nbEvents < 25 then
                period.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\medium-events")
            elseif period.data.nbEvents >= 25 then
                period.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\high-events")
            end
        else
            period.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\no-events")
        end
    end

    -- Highlight the period when hovered
end

function TimelinePeriodMixin:OnClick()
    -- Create a period data structure for state storage
    -- Only store essential data, not calculated values
    local periodData = {
        lower = self.data.lowerBound,
        upper = self.data.upperBound,
        text = self.data.text,
        nbEvents = self.data.nbEvents,
        hasEvents = self.data.hasEvents
    }

    -- Update state instead of triggering event - provides single source of truth
    if private.Core.StateManager then
        private.Core.StateManager.setState("ui.selectedPeriod", periodData, "Timeline period selected")
    end

    self:ResetAllPeriodTextures()

    -- Set the selected texture for this period
    if (periodData ~= nil and periodData.hasEvents) then
        if periodData.nbEvents < 10 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\low-events-selected")
        elseif periodData.nbEvents < 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\medium-events-selected")
        elseif periodData.nbEvents >= 25 then
            self.Background:SetTexture("Interface\\AddOns\\Chronicles\\Art\\timeline\\high-events-selected")
        end
    end
end
