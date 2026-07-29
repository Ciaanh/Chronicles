local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

-- Direct access helpers
local function getTimelineBusiness()
    return private.Core.Data and private.Core.Data.TimelineBusiness
end

local function getStateManager()
    return private.Core.StateManager
end

local function getChronicles()
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
end

-- -------------------------
-- Timeline
-- -------------------------
local Timeline = {}
Timeline.MaxStepIndex = #private.constants.config.stepValues
Timeline.Periods = {}

local function isConfiguredStepValue(stepValue)
    for _, value in ipairs(private.constants.config.stepValues) do
        if value == stepValue then
            return true
        end
    end
    return false
end

local function setCurrentStepValue(value, description)
    local stateManager = getStateManager()
    if not stateManager then
        return
    end
    stateManager.setState(stateManager.buildTimelineKey("currentStep"), value, description or "Timeline step changed")
end

local function getCurrentStepValue()
    local defaultStep = private.constants.config.stepValues[1]
    local stateManager = getStateManager()
    if not stateManager then
        return defaultStep -- fallback default
    end

    local stepValue = stateManager.getState(stateManager.buildTimelineKey("currentStep"))

    -- A step saved before its value was retired from stepValues has no index,
    -- so every zoom computation on it would operate on nil.
    if not isConfiguredStepValue(stepValue) then
        setCurrentStepValue(defaultStep, "Timeline step reset to a configured value")
        return defaultStep
    end

    return stepValue
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

local function GetStepValueIndex(stepValue)
    return getTimelineBusiness().getStepValueIndex(stepValue)
end

-- Resolves against the periods already held here, so the page index and the
-- period selected from the same array cannot disagree.
local function GetYearPageIndex(year)
    return getTimelineBusiness().getYearPageIndexWithPeriods(year, Timeline.Periods)
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

-- There is deliberately no Timeline.Init(). Every piece of startup work it would do already has an
-- owner: TimelineTemplate's OnTimelineInit computes periods and renders, TimelineBusiness defaults a
-- missing page to 1 and sanitizes a retired step value, and TimelineInit is triggered by Core/Data
-- and by RegisterPluginDB. Its currentPage subscription would also have double-rendered, because
-- NavigatePage already calls DisplayTimelineWindow() itself right after setCurrentPage().

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

    if selectedPeriod then
        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        private.Core.StateManager.setState(
            selectedPeriodKey,
            selectedPeriod,
            "Timeline period selected after year navigation"
        )
    end

    return true
end
