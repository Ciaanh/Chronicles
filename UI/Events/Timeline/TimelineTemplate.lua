local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- -------------------------
-- Timeline
-- -------------------------
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
            private.Core.StateManager.buildTimelineKey("currentStep"),
            function(newStep, oldStep)
                self:UpdateZoomLevelIndicator(newStep)
            end,
            "TimelineMixin"
        )
    end -- Initialize zoom level indicator
    self:UpdateZoomLevelIndicator(
        private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("currentStep")) or
            private.constants.config.stepValues[1]
    )

    -- Initialize date search
    self:InitializeDateSearch()

    -- Register for year-specific event display
    private.Core.registerCallback(private.constants.events.DisplayEventsForYear, self.OnDisplayEventsForYear, self)
end

-- -------------------------
-- Year-Specific Event Display
-- -------------------------

function TimelineMixin:OnDisplayEventsForYear(eventData)
    if not eventData or not eventData.year or not eventData.events then
        return
    end

    local year = eventData.year
    local events = eventData.events

    -- Update the selected period to show year-specific information
    if private.Core.StateManager then
        -- Create a special period data for year-specific display
        local yearSpecificPeriod = {
            lower = year,
            upper = year,
            text = "Year " .. year,
            nbEvents = #events,
            hasEvents = #events > 0,
            isYearSpecific = true
        }

        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        private.Core.StateManager.setState(selectedPeriodKey, yearSpecificPeriod, "Year-specific period selected")
    end
end

-- -------------------------
-- Date Search Functionality
-- -------------------------

function TimelineMixin:InitializeDateSearch()
    -- Set initial state
    if self.DateSearchInput then
        self.DateSearchInput:SetText("")
        -- Set localized placeholder text
        if self.DateSearchInput.PlaceholderText then
            self.DateSearchInput.PlaceholderText:SetText(Locale["Enter year..."] or "Enter year...")
        end
        self:UpdateDateSearchPlaceholder()
    end

    -- Set localized button text
    if self.DateSearchButton then
        self.DateSearchButton:SetText(Locale["Go"] or "Go")
    end
end

function TimelineMixin:OnDateSearchFocusGained()
    if self.DateSearchInput.PlaceholderText then
        self.DateSearchInput.PlaceholderText:Hide()
    end
end

function TimelineMixin:OnDateSearchFocusLost()
    self:UpdateDateSearchPlaceholder()
end

function TimelineMixin:OnDateSearchTextChanged()
    self:UpdateDateSearchPlaceholder()
end

function TimelineMixin:UpdateDateSearchPlaceholder()
    if not self.DateSearchInput or not self.DateSearchInput.PlaceholderText then
        return
    end

    local text = self.DateSearchInput:GetText()
    if text and text ~= "" then
        self.DateSearchInput.PlaceholderText:Hide()
    else
        self.DateSearchInput.PlaceholderText:Show()
    end
end

function TimelineMixin:OnDateSearchEnterPressed()
    self:PerformDateSearch()
end

function TimelineMixin:OnDateSearchEscapePressed()
    if self.DateSearchInput then
        self.DateSearchInput:SetText("")
        self.DateSearchInput:ClearFocus()
        self:UpdateDateSearchPlaceholder()
    end
end

function TimelineMixin:OnDateSearchButtonClick()
    self:PerformDateSearch()
end

function TimelineMixin:PerformDateSearch()
    if not self.DateSearchInput then
        return
    end

    local searchText = self.DateSearchInput:GetText()
    if not searchText or searchText == "" then
        return
    end
    -- Parse the year from input
    local year = tonumber(searchText)
    if not year then
        -- Show error message for invalid input
        local errorMsg =
            Locale["Invalid year format. Please enter a number (e.g., -10000, 25, 2024)"] or
            "Invalid year format. Please enter a number (e.g., -10000, 25, 2024)"
        private.Chronicles:Print(errorMsg)
        return
    end

    -- Validate year range
    local minYear = private.constants.config.historyStartYear
    local maxYear = private.constants.config.futur

    if year < minYear or year > maxYear then
        local errorMsg =
            string.format(
            Locale["Year must be between %d and %d"] or "Year must be between %d and %d",
            minYear,
            maxYear
        )
        private.Chronicles:Print(errorMsg)
        return
    end

    self:NavigateToYear(year)
    self.DateSearchInput:ClearFocus()
end

function TimelineMixin:NavigateToYear(year)
    -- Find the period containing this year and display events
    if not year then
        return
    end

    -- Use Timeline business logic to find the correct page for this year
    if private.Core.Timeline and private.Core.Timeline.NavigateToYear then
        private.Core.Timeline.NavigateToYear(year)
    else
        -- Fallback implementation
        self:FallbackNavigateToYear(year)
    end
end

function TimelineMixin:FallbackNavigateToYear(year)
    -- Simple fallback that sets the selected year and refreshes timeline
    if private.Core.StateManager then
        private.Core.StateManager.setState(
            private.Core.StateManager.buildTimelineKey("selectedYear"),
            year,
            "Date search navigation"
        )
    end

    -- Trigger timeline refresh
    if private.Core.Timeline and private.Core.Timeline.ComputeTimelinePeriods then
        private.Core.Timeline.ComputeTimelinePeriods()
        private.Core.Timeline.DisplayTimelineWindow()
    end
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

-- -------------------------
-- TimelineLabel
-- -------------------------
TimelineLabelMixin = {}
function TimelineLabelMixin:OnLoad()
    local eventName = private.constants.events.DisplayTimelineLabel .. tostring(self.index)
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

-- -------------------------
-- TimelinePeriod
-- -------------------------
TimelinePeriodMixin = {}
function TimelinePeriodMixin:OnLoad()
    local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(self.index)
    private.Core.registerCallback(eventName, self.OnDisplayTimelinePeriod, self)
end

function TimelinePeriodMixin:OnDisplayTimelinePeriod(periodData)
    self.data = periodData

    local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
    local selectedPeriod = private.Core.StateManager.getState(selectedPeriodKey)
    local isSelected =
        selectedPeriod and periodData and selectedPeriod.lower == periodData.lower and
        selectedPeriod.upper == periodData.upper

    if (periodData ~= nil and periodData.hasEvents) then
        self.Text:SetText(periodData.nbEvents)
        local select = isSelected and "-selected" or ""

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
end

function TimelinePeriodMixin:OnClick()
    -- Clear year-specific mode when clicking on timeline periods (normal navigation)
    if private.Core.StateManager then
        private.Core.StateManager.setState(
            private.Core.StateManager.buildTimelineKey("yearSpecificMode"),
            false,
            "Year-specific mode cleared due to period selection"
        )
    end

    -- Create a period data structure for state storage
    -- Only store essential data, not calculated values
    local periodData = {
        lower = self.data.lower,
        upper = self.data.upper,
        text = self.data.text,
        nbEvents = self.data.nbEvents,
        hasEvents = self.data.hasEvents
    }

    -- Update state instead of triggering event - provides single source of truth
    if private.Core.StateManager then
        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        private.Core.StateManager.setState(selectedPeriodKey, periodData, "Timeline period selected")
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
