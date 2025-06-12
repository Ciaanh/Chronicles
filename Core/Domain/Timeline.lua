local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

-- Create convenience accessor for TimelineBusiness (accessed lazily)
local function getTimelineBusiness()
    return private.Core.Data.TimelineBusiness
end

-- -------------------------
-- Timeline
-- -------------------------
local Timeline = {}
Timeline.MaxStepIndex = #private.constants.config.stepValues
Timeline.Periods = {}

local function getCurrentStepValue()
    local value = private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("currentStep"))

    return value
end

local function getCurrentPage()
    local value = private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("currentPage"))

    return value
end

local function getSelectedYear()
    local value = private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("selectedYear"))

    return value
end

local function setCurrentStepValue(value, description)
    private.Core.StateManager.setState(
        private.Core.StateManager.buildTimelineKey("currentStep"),
        value,
        description or "Timeline step changed"
    )
end

local function setCurrentPage(value, description)
    private.Core.StateManager.setState(
        private.Core.StateManager.buildTimelineKey("currentPage"),
        value,
        description or "Timeline page changed"
    )
end

local function setSelectedYear(value, description)
    private.Core.StateManager.setState(
        private.Core.StateManager.buildTimelineKey("selectedYear"),
        value,
        description or "Timeline year changed"
    )
end

local function GetDateCurrentStepIndex(date)
    return getTimelineBusiness().getDateCurrentStepIndex(date)
end

local function GetCurrentStepPeriodsFilling()
    return getTimelineBusiness().getCurrentStepPeriodsFilling()
end

local function CountEvents(block)
    return getTimelineBusiness().countEventsInPeriod(block)
end

local function GetTimelineConfig(minYear, maxYear, stepValue)
    return getTimelineBusiness().calculateTimelineConfig(minYear, maxYear, stepValue)
end

local function GetStepValueIndex(stepValue)
    return getTimelineBusiness().getStepValueIndex(stepValue)
end

local function GetYearPageIndex(year)
    return getTimelineBusiness().getYearPageIndex(year, Timeline.Periods)
end

function private.Core.Timeline.ChangePage(value)
    local currentPage = getCurrentPage() or 1
    local newPage = currentPage + value

    setCurrentPage(newPage, "Timeline page changed via navigation")

    private.Core.Timeline.DisplayTimelineWindow()
end

function private.Core.Timeline.SetYear(year)
    setSelectedYear(year, "Timeline year set")
end

function private.Core.Timeline.ComputeTimelinePeriods()
    Timeline.Periods = getTimelineBusiness().computeTimelinePeriods()

    return Timeline.Periods
end

local function SafeTriggerEvent(eventName, eventData, source)
    private.Core.triggerEvent(eventName, eventData, source)
end

local function CalculateTimelinePagination()
    return getTimelineBusiness().calculateTimelinePagination(Timeline.Periods, getCurrentPage())
end

local function UpdateNavigationButtons(paginationData)
    SafeTriggerEvent(
        private.constants.events.TimelinePreviousButtonVisible,
        paginationData.showPrevious and {visible = true} or {visible = false},
        "Timeline:UpdateNavigationButtons"
    )

    SafeTriggerEvent(
        private.constants.events.TimelineNextButtonVisible,
        paginationData.showNext and {visible = true} or {visible = false},
        "Timeline:UpdateNavigationButtons"
    )
end

local function DistributeTimelineLabels(paginationData)
    local firstIndex = paginationData.firstIndex
    local pageSize = paginationData.pageSize
    local eventNamePrefix = private.constants.events.DisplayTimelineLabel

    for labelIndex = 1, pageSize + 1, 1 do
        local periodIndex = firstIndex + labelIndex - 1
        local labelData = Timeline.Periods[periodIndex]
        local eventName = eventNamePrefix .. tostring(labelIndex)
        local isLastLabel = (labelIndex == pageSize + 1)

        local labelText = ""

        if labelData and not isLastLabel then
            if labelData.upper == private.constants.config.futur then
                -- Future period: get previous period's upper bound
                local prevPeriodIndex = firstIndex + labelIndex - 2
                local prevPeriodData = Timeline.Periods[prevPeriodIndex]
                labelText = prevPeriodData and tostring(prevPeriodData.upper) or ""
            elseif labelData.lower == private.constants.config.mythos then
                -- Mythos period: use localized text
                labelText = Locale["Mythos"]
            else
                -- Standard period: use lower bound
                labelText = tostring(labelData.lower)
            end
        elseif isLastLabel then
            -- Special case: no data for last label, check if previous period is future
            local prevPeriodIndex = firstIndex + labelIndex - 2
            local prevPeriodData = Timeline.Periods[prevPeriodIndex]
            if prevPeriodData and prevPeriodData.upper == private.constants.config.futur then
                labelText = Locale["Futur"]
            elseif prevPeriodData then
                labelText = tostring(prevPeriodData.upper)
            end
        end

        SafeTriggerEvent(eventName, labelText, "Timeline:DistributeTimelineLabels")
    end
end

local function DistributeTimelinePeriods(paginationData)
    local firstIndex = paginationData.firstIndex
    local pageSize = paginationData.pageSize

    for periodIndex = 1, pageSize, 1 do
        local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(periodIndex)
        local periodData = Timeline.Periods[firstIndex + periodIndex - 1]

        SafeTriggerEvent(eventName, periodData, "Timeline:DistributeTimelinePeriods")
    end
end

function private.Core.Timeline.DisplayTimelineWindow()
    local paginationData = CalculateTimelinePagination()
    UpdateNavigationButtons(paginationData)

    DistributeTimelineLabels(paginationData)
    DistributeTimelinePeriods(paginationData)
end

function private.Core.Timeline.ChangeCurrentStepValue(direction)
    -- TODO investigate performance issue with step 1 and 10
    local currentStepValue = getCurrentStepValue()
    local curentStepIndex = GetStepValueIndex(currentStepValue)
    local nextStepValue = private.constants.config.stepValues[1]

    if direction == 1 then
        if (curentStepIndex == Timeline.MaxStepIndex) then
            return
        end

        nextStepValue = private.constants.config.stepValues[curentStepIndex + 1]
    else
        if (curentStepIndex == 1) then
            return
        end

        nextStepValue = private.constants.config.stepValues[curentStepIndex - 1]
    end
    setCurrentStepValue(nextStepValue, "Timeline step changed via zoom")

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.MaintainSelectedYear()

    private.Core.Timeline.DisplayTimelineWindow()
end

function private.Core.Timeline.MaintainSelectedYear()
    local selectedYear = getSelectedYear()

    if not selectedYear then
        selectedYear = private.constants.config.currentYear
    end

    local newPage = GetYearPageIndex(selectedYear)

    if not newPage then
        return
    end

    setCurrentPage(newPage, "Timeline page updated after step change")

    local selectedPeriod = nil

    for i, period in ipairs(Timeline.Periods) do
        local containsYear = false

        if period.lower == private.constants.config.mythos then
            containsYear = (selectedYear < private.constants.config.historyStartYear)
        elseif period.upper == private.constants.config.futur then
            containsYear = (selectedYear > private.constants.config.currentYear)
        else
            containsYear = (selectedYear >= period.lower and selectedYear <= period.upper)
        end

        if containsYear then
            selectedPeriod = period
            break
        end
    end

    if selectedPeriod then
        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        private.Core.StateManager.setState(
            selectedPeriodKey,
            selectedPeriod,
            "Timeline period selected after step change"
        )
    end
end

-- -------------------------
-- Initialization
-- -------------------------

function private.Core.Timeline.Init()
    local currentStep = getCurrentStepValue()
    if not currentStep then
        local defaultStep = private.constants.config.stepValues[1]
        setCurrentStepValue(defaultStep, "Timeline step initialized to default")
    end

    local currentPage = getCurrentPage()
    if not currentPage then
        setCurrentPage(1, "Timeline page initialized to default")
    end

    private.Core.StateManager.addListener(
        private.Core.StateManager.buildTimelineKey("currentPage"),
        onCurrentPageChanged
    )

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    SafeTriggerEvent(private.constants.events.TimelineInit, {}, "Timeline:Init")
end

local function onCurrentPageChanged(newPage, oldPage, description)
    if newPage ~= oldPage and oldPage ~= nil then
        private.Core.Timeline.DisplayTimelineWindow()
    end
end
