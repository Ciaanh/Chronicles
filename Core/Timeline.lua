local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

local Chronicles = private.Chronicles

-- Create convenience accessor for TimelineBusiness (accessed lazily)
local function getTimelineBusiness()
    return private.Core.Data.TimelineBusiness
end

-----------------------------------------------------------------------------------------
-- Timeline -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
local Timeline = {}
-- KEEP: Core timeline data that's not in state
Timeline.MaxStepIndex = #private.constants.config.stepValues
Timeline.Periods = {}

-- Helper functions to access state values
local function getCurrentStepValue()
    local value = private.Core.StateManager.getState("timeline.currentStep")
    private.Core.Logger.trace("Timeline", "Retrieved current step value: " .. tostring(value))
    return value
end

local function getCurrentPage()
    local value = private.Core.StateManager.getState("timeline.currentPage")
    private.Core.Logger.trace("Timeline", "Retrieved current page: " .. tostring(value))
    return value
end

local function getSelectedYear()
    local value = private.Core.StateManager.getState("timeline.selectedYear")
    private.Core.Logger.trace("Timeline", "Retrieved selected year: " .. tostring(value))
    return value
end

local function setCurrentStepValue(value, description)
    private.Core.Logger.trace("Timeline", "Setting timeline step to: " .. tostring(value))
    private.Core.StateManager.setState("timeline.currentStep", value, description or "Timeline step changed")
end

local function setCurrentPage(value, description)
    private.Core.Logger.trace("Timeline", "Setting timeline page to: " .. tostring(value))
    private.Core.StateManager.setState("timeline.currentPage", value, description or "Timeline page changed")
end

local function setSelectedYear(value, description)
    private.Core.Logger.trace("Timeline", "Setting selected year to: " .. tostring(value))
    private.Core.StateManager.setState("timeline.selectedYear", value, description or "Timeline year changed")
end

-- Delegate to business logic module
local function GetDateCurrentStepIndex(date)
    -- Phase 3 Debug: Log delegation
    private.Core.Logger.trace("Timeline", "Delegating GetDateCurrentStepIndex to TimelineBusiness")
    return getTimelineBusiness().getDateCurrentStepIndex(date)
end

-- Delegate to business logic module
local function GetCurrentStepPeriodsFilling()
    return getTimelineBusiness().getCurrentStepPeriodsFilling()
end

-- Delegate to business logic module
local function CountEvents(block)
    return getTimelineBusiness().countEventsInPeriod(block)
end

-- Delegate to business logic module
local function GetTimelineConfig(minYear, maxYear, stepValue)
    return getTimelineBusiness().calculateTimelineConfig(minYear, maxYear, stepValue)
end

-- Delegate to business logic module
local function GetStepValueIndex(stepValue)
    return getTimelineBusiness().getStepValueIndex(stepValue)
end

-- Delegate to business logic module
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
    -- Delegate to business logic module and store result in Timeline.Periods
    Timeline.Periods = getTimelineBusiness().computeTimelinePeriods()
    return Timeline.Periods
end

-- Helper function to safely trigger events
local function SafeTriggerEvent(eventName, eventData, source)
    private.Core.triggerEvent(eventName, eventData, source)
end

-- Calculate pagination parameters for the timeline window using business logic
local function CalculateTimelinePagination()
    return getTimelineBusiness().calculateTimelinePagination(Timeline.Periods, getCurrentPage())
end

-- Update navigation button visibility based on pagination state
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

-- Helper function to generate label text based on period data and position
local function GenerateLabelText(labelData, isLastLabel, firstIndex, labelIndex)
    if not labelData then
        return ""
    end

    -- For the last label (boundary label), always show upper bound
    if isLastLabel then
        return tostring(labelData.upperBound)
    end

    -- For regular labels, determine text based on period type
    if labelData.upperBound == private.constants.config.futur then
        -- Future period: get previous period's upper bound
        local prevPeriodIndex = firstIndex + labelIndex - 2
        local prevPeriodData = Timeline.Periods[prevPeriodIndex]
        return prevPeriodData and tostring(prevPeriodData.upperBound) or ""
    elseif labelData.lowerBound == private.constants.config.mythos then
        -- Mythos period: use localized text
        return Locale["Mythos"]
    else
        -- Standard period: use lower bound
        return tostring(labelData.lowerBound)
    end
end

-- Distribute timeline label data via events
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

        if labelData then
            labelText = GenerateLabelText(labelData, isLastLabel, firstIndex, labelIndex)
        elseif isLastLabel then
            -- Special case: no data for last label, check if previous period is future
            local prevPeriodIndex = firstIndex + labelIndex - 2
            local prevPeriodData = Timeline.Periods[prevPeriodIndex]
            if prevPeriodData and prevPeriodData.upperBound == private.constants.config.futur then
                labelText = Locale["Futur"]
            end
        end

        SafeTriggerEvent(eventName, labelText, "Timeline:DistributeTimelineLabels")
    end
end

-- Distribute timeline period data via events
local function DistributeTimelinePeriods(paginationData)
    local firstIndex = paginationData.firstIndex
    local pageSize = paginationData.pageSize

    for periodIndex = 1, pageSize, 1 do
        local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(periodIndex)
        local periodData = Timeline.Periods[firstIndex + periodIndex - 1]

        SafeTriggerEvent(eventName, periodData, "Timeline:DistributeTimelinePeriods")
    end
end

-- Main function to display the timeline window - now orchestrates the separated responsibilities
function private.Core.Timeline.DisplayTimelineWindow()
    -- Calculate pagination parameters
    local paginationData = CalculateTimelinePagination()

    -- Update the current page state
    setCurrentPage(paginationData.currentPage, "Timeline page updated during display")

    -- Update UI state
    UpdateNavigationButtons(paginationData)

    -- Distribute data to UI components
    DistributeTimelineLabels(paginationData)
    DistributeTimelinePeriods(paginationData)
end

function private.Core.Timeline.ChangeCurrentStepValue(direction)
    -- TODO investigate performance issue with step 1 and 10
    local currentStepValue = getCurrentStepValue()
    local curentStepIndex = GetStepValueIndex(currentStepValue)
    local nextStepValue = private.constants.config.stepValues[1]

    -- handle selected year

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

    private.Core.Logger.trace(
        "Timeline",
        "Changing timeline step from " .. tostring(currentStepValue) .. " to " .. tostring(nextStepValue)
    )

    -- Update state instead of triggering event - provides single source of truth
    setCurrentStepValue(nextStepValue, "Timeline step changed via zoom")

    private.Core.Timeline.ComputeTimelinePeriods()
    local selectedYear = getSelectedYear()
    local newPage = GetYearPageIndex(selectedYear)
    setCurrentPage(newPage, "Timeline page updated after step change")
    private.Core.Timeline.DisplayTimelineWindow()
end

-----------------------------------------------------------------------------------------
-- Initialization -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.Timeline.Init()
    private.Core.Logger.trace("Timeline", "Initializing Timeline module")

    -- Initialize default values if not already set
    local currentStep = getCurrentStepValue()
    if not currentStep then
        local defaultStep = private.constants.config.stepValues[1]
        setCurrentStepValue(defaultStep, "Timeline step initialized to default")
    end

    local currentPage = getCurrentPage()
    if not currentPage then
        setCurrentPage(1, "Timeline page initialized to default")
    end

    -- Ensure timeline periods are computed during initialization
    private.Core.Timeline.ComputeTimelinePeriods()

    -- Explicitly trigger TimelineInit event to ensure UI components update
    SafeTriggerEvent(private.constants.events.TimelineInit, {}, "Timeline:Init")

    private.Core.Logger.trace("Timeline", "Timeline module initialization complete")
end
