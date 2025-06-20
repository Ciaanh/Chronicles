local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

-- Dependency injection container to eliminate circular dependencies
local function getDependency(name)
    if private.Core.DependencyContainer then
        return private.Core.DependencyContainer.resolve(name)
    end
    return nil
end

-- Safe dependency accessor with fallbacks
local function getTimelineBusiness()
    local timelineBusiness = getDependency("TimelineBusiness")
    if timelineBusiness then
        return timelineBusiness
    end
    -- Fallback to direct access if container not available
    return private.Core.Data and private.Core.Data.TimelineBusiness
end

local function getStateManager()
    local stateManager = getDependency("StateManager")
    if stateManager then
        return stateManager
    end
    -- Fallback to direct access if container not available
    return private.Core.StateManager
end

local function getChronicles()
    local chronicles = getDependency("Chronicles")
    if chronicles then
        return chronicles
    end
    -- Fallback to direct access if container not available
    return private.Chronicles
end

-- -------------------------
-- Year-Specific Mode Management
-- -------------------------

local function clearYearSpecificMode(description)
    local stateManager = getStateManager()
    if not stateManager then
        return
    end

    stateManager.setState(
        stateManager.buildTimelineKey("yearSpecificMode"),
        false,
        description or "Year-specific mode cleared"
    )

    stateManager.setState(stateManager.buildTimelineKey("yearSpecificTarget"), nil, "Year-specific target cleared")

    stateManager.setState(stateManager.buildTimelineKey("yearSpecificEvents"), nil, "Year-specific events cleared")
end

-- -------------------------
-- Timeline
-- -------------------------
local Timeline = {}
Timeline.MaxStepIndex = #private.constants.config.stepValues
Timeline.Periods = {}

local function getCurrentStepValue()
    local stateManager = getStateManager()
    if not stateManager then
        return private.constants.config.stepValues[1] -- fallback default
    end
    return stateManager.getState(stateManager.buildTimelineKey("currentStep"))
end

local function getCurrentPage()
    local stateManager = getStateManager()
    if not stateManager then
        return 1 -- fallback default
    end
    return stateManager.getState(stateManager.buildTimelineKey("currentPage"))
end

local function getSelectedYear()
    local stateManager = getStateManager()
    if not stateManager then
        return nil
    end
    return stateManager.getState(stateManager.buildTimelineKey("selectedYear"))
end

local function setCurrentStepValue(value, description)
    local stateManager = getStateManager()
    if not stateManager then
        return
    end
    stateManager.setState(stateManager.buildTimelineKey("currentStep"), value, description or "Timeline step changed")
end

local function setCurrentPage(value, description)
    local stateManager = getStateManager()
    if not stateManager then
        return
    end
    stateManager.setState(stateManager.buildTimelineKey("currentPage"), value, description or "Timeline page changed")
end

local function setSelectedYear(value, description)
    local stateManager = getStateManager()
    if not stateManager then
        return
    end
    stateManager.setState(stateManager.buildTimelineKey("selectedYear"), value, description or "Timeline year changed")
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

    -- Clear year-specific mode when navigating via timeline pages
    clearYearSpecificMode("Year-specific mode cleared due to page navigation")

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

--[[
    Navigate to a specific year and display associated events
    This function finds the appropriate timeline period for the given year,
    navigates to the correct page, and triggers event display.
    
    @param year [number] Target year to navigate to
]]
function private.Core.Timeline.NavigateToYear(year)
    if not year or type(year) ~= "number" then
        return false, "Invalid year provided"
    end

    local timelineBusiness = getTimelineBusiness()
    if not timelineBusiness then
        return false, "Timeline business logic not available"
    end

    local stateManager = getStateManager()
    if not stateManager then
        return false, "State manager not available"
    end

    -- Set the selected year in state
    setSelectedYear(year, "Navigation to specific year: " .. year)

    -- Find the appropriate page for this year
    local pageIndex = timelineBusiness.getYearPageIndex(year)
    if pageIndex then
        setCurrentPage(pageIndex, "Page updated for year navigation")
    end

    -- Recompute timeline periods to ensure current data
    private.Core.Timeline.ComputeTimelinePeriods()

    -- Find and select the period containing this year
    local selectedPeriod = nil

    for i, period in ipairs(Timeline.Periods) do
        local containsYear = false

        if period.lower == private.constants.config.mythos then
            containsYear = (year < private.constants.config.historyStartYear)
        elseif period.upper == private.constants.config.futur then
            containsYear = (year > private.constants.config.currentYear)
        else
            containsYear = (year >= period.lower and year <= period.upper)
        end

        if containsYear then
            selectedPeriod = period
            break
        end
    end

    -- Update selected period in state using dependency container
    if selectedPeriod then
        local selectedPeriodKey = stateManager.buildUIStateKey("selectedPeriod")
        stateManager.setState(selectedPeriodKey, selectedPeriod, "Timeline period selected via year navigation") -- Set a flag to indicate we're displaying year-specific events
        stateManager.setState(
            stateManager.buildTimelineKey("yearSpecificMode"),
            true,
            "Year-specific event display mode enabled"
        )

        stateManager.setState(
            stateManager.buildTimelineKey("yearSpecificTarget"),
            year,
            "Target year for year-specific display"
        )

        -- Search for events specifically for this year, not the entire period
        local searchEngine = getDependency("SearchEngine")
        if searchEngine and searchEngine.searchEvents then
            -- Search for events only for the specific year (yearStart == yearEnd)
            local events = searchEngine.searchEvents(year, year)
            -- Store the year-specific events in state
            stateManager.setState(
                stateManager.buildTimelineKey("yearSpecificEvents"),
                events,
                "Events for year-specific display"
            )
        end
    else
        return false, "Period not found for year"
    end
    -- Refresh the timeline display first
    private.Core.Timeline.DisplayTimelineWindow()

    -- After timeline refresh, trigger year-specific event display if in year-specific mode
    local yearSpecificMode = stateManager.getState(stateManager.buildTimelineKey("yearSpecificMode"))
    if yearSpecificMode then
        local yearSpecificEvents = stateManager.getState(stateManager.buildTimelineKey("yearSpecificEvents"))
        local yearSpecificTarget = stateManager.getState(stateManager.buildTimelineKey("yearSpecificTarget"))

        if yearSpecificTarget and yearSpecificEvents then
            -- Trigger event to display the filtered events for this specific year
            SafeTriggerEvent(
                private.constants.events.DisplayEventsForYear,
                {year = yearSpecificTarget, events = yearSpecificEvents},
                "Timeline:NavigateToYear"
            )
        end
    end    local successMsg =
        string.format(Locale["Successfully navigated to year %d"] or "Successfully navigated to year %d", year)
    return true, successMsg
end
