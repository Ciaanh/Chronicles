local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

local Chronicles = private.Chronicles

-----------------------------------------------------------------------------------------
-- Timeline -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
local Timeline = {}
Timeline.MaxStepIndex = #private.constants.config.stepValues
Timeline.CurrentStepValue = nil
Timeline.CurrentPage = nil
Timeline.SelectedYear = nil
Timeline.Periods = {}

local function GetDateCurrentStepIndex(date)
    local dateProfile = Chronicles.Data:ComputeEventDateProfile(date)

    -- Safety check: if dateProfile is nil, return default value
    if dateProfile == nil then
        return 0
    end

    if (Timeline.CurrentStepValue == 1000) then
        return dateProfile.mod1000 or 0
    elseif (Timeline.CurrentStepValue == 500) then
        return dateProfile.mod500 or 0
    elseif (Timeline.CurrentStepValue == 250) then
        return dateProfile.mod250 or 0
    elseif (Timeline.CurrentStepValue == 100) then
        return dateProfile.mod100 or 0
    elseif (Timeline.CurrentStepValue == 50) then
        return dateProfile.mod50 or 0
    elseif (Timeline.CurrentStepValue == 10) then
        return dateProfile.mod10 or 0
    elseif (Timeline.CurrentStepValue == 1) then
        --     return dateProfile.mod1
        return 0 -- Return default value for step 1 (not implemented)
    else
        -- Return default value for unsupported step values
        return 0
    end
end

local function GetCurrentStepPeriodsFilling()
    local eventDates = Chronicles.Data.PeriodsFillingBySteps

    -- Safety check: if eventDates is nil, return empty table
    if eventDates == nil then
        return {}
    end

    if (Timeline.CurrentStepValue == 1000) then
        return eventDates.mod1000 or {}
    elseif (Timeline.CurrentStepValue == 500) then
        return eventDates.mod500 or {}
    elseif (Timeline.CurrentStepValue == 250) then
        return eventDates.mod250 or {}
    elseif (Timeline.CurrentStepValue == 100) then
        return eventDates.mod100 or {}
    elseif (Timeline.CurrentStepValue == 50) then
        return eventDates.mod50 or {}
    elseif (Timeline.CurrentStepValue == 10) then
        return eventDates.mod10 or {}
    elseif (Timeline.CurrentStepValue == 1) then
        --     return eventDates.mod1
        return {} -- Return empty table for step 1 (not implemented)
    else
        -- Return empty table for unsupported step values to prevent errors
        return {}
    end
end

local function CountEvents(block)
    local eventCount = 0

    local originalLowerBound = block.lowerBound
    local originalUpperBound = block.upperBound

    -- Handle special periods differently
    local isMytosPeriod = (originalLowerBound == private.constants.config.mythos)
    local isFuturePeriod = (originalUpperBound == private.constants.config.futur)
    if isMytosPeriod then
        -- For mythos period: manually search for events before historyStartYear
        -- since the date index system might not properly handle extreme negative values
        local mythosYearEnd = private.constants.config.historyStartYear - 1
        local foundEvents = Chronicles.Data:SearchEvents(private.constants.config.mythos, mythosYearEnd)

        if foundEvents ~= nil then
            eventCount = #foundEvents
        end
    elseif isFuturePeriod then
        -- For future period: manually search for events beyond currentYear
        -- since the date index system doesn't cover future dates
        local futureYearStart = private.constants.config.currentYear + 1
        local foundEvents = Chronicles.Data:SearchEvents(futureYearStart, private.constants.config.futur)

        if foundEvents ~= nil then
            eventCount = #foundEvents
        end
    else
        -- Regular period processing - use original logic with bounds clamping for index calculation
        local lowerBound = originalLowerBound
        local upperBound = originalUpperBound

        -- Clamp bounds to valid date range for date index calculation only
        if (lowerBound < private.constants.config.historyStartYear) then
            lowerBound = private.constants.config.historyStartYear
        end

        if (upperBound > private.constants.config.currentYear) then
            upperBound = private.constants.config.currentYear
        end

        local lowerDateIndex = GetDateCurrentStepIndex(lowerBound)
        local upperDateIndex = GetDateCurrentStepIndex(upperBound)

        if upperDateIndex == nil or lowerDateIndex == nil then
            return eventCount
        end

        local periodsFilling = GetCurrentStepPeriodsFilling()
        if periodsFilling == nil then
            return eventCount
        end

        if (lowerDateIndex < upperDateIndex) then
            for i = lowerDateIndex, upperDateIndex - 1, 1 do
                local periodEvents = periodsFilling[i]

                if (periodEvents ~= nil) then
                    local periodsCount = #periodEvents
                    eventCount = eventCount + periodsCount
                end
            end
        elseif lowerDateIndex == upperDateIndex then
            local periodEvents = periodsFilling[lowerDateIndex]
            if (periodEvents ~= nil) then
                eventCount = #periodEvents
            end
        end
    end

    return eventCount
end

local function GetTimelineConfig(minYear, maxYear, stepValue)
    local timelineConfig = {
        isOverlapping = false,
        pastEvents = false,
        futurEvents = false,
        before = 0,
        after = 0,
        minYear = minYear,
        maxYear = maxYear,
        numberOfTimelineBlock = 0
    }

    -- Define the boundaries of the timeline
    if (minYear < private.constants.config.historyStartYear) then -- there is event before the history start year
        timelineConfig.minYear = private.constants.config.historyStartYear
        timelineConfig.pastEvents = true
    end

    if (maxYear > private.constants.config.currentYear) then -- there is event after the current year
        timelineConfig.maxYear = private.constants.config.currentYear
        timelineConfig.futurEvents = true
    end

    if (timelineConfig.minYear < 0 and timelineConfig.maxYear > 0) then -- there is event before and after the 0 year
        timelineConfig.isOverlapping = true
    end

    if (timelineConfig.minYear < 0) then
        local beforeLength = math.abs(timelineConfig.minYear)

        timelineConfig.before = math.ceil((beforeLength) / stepValue)
    end

    if (timelineConfig.maxYear > 0) then
        local afterLength = math.abs(timelineConfig.maxYear)
        local ceil = math.ceil(afterLength / stepValue)

        timelineConfig.after = ceil
    end

    -- Define the total number of timeline blocks
    if (timelineConfig.isOverlapping) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.before + timelineConfig.after
    else
        local length = math.abs(timelineConfig.minYear - timelineConfig.maxYear)
        timelineConfig.numberOfTimelineBlock = math.ceil(length / stepValue)
    end

    if (timelineConfig.pastEvents == true) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.numberOfTimelineBlock + 1
        if (timelineConfig.isOverlapping) then
            timelineConfig.before = timelineConfig.before + 1
        end
    end
    if (timelineConfig.futurEvents == true) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.numberOfTimelineBlock + 1

        if (timelineConfig.isOverlapping) then
            timelineConfig.after = timelineConfig.after + 1
        end
    end

    return timelineConfig
end

local function GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(private.constants.config.stepValues) do
        index[v] = k
    end
    return index[stepValue]
end

local function GetYearPageIndex(year)
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Timeline.CurrentPage
        local pageSize = private.constants.config.timeline.pageSize
        local numberOfCells = #Timeline.Periods

        if (page == nil) then
            page = 1
        end

        local firstIndex = 1 + ((page - 1) * pageSize)
        local lastIndex = page * pageSize

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if (lastIndex > numberOfCells) then
            firstIndex = numberOfCells - (pageSize)
            lastIndex = numberOfCells - 1
        end

        local firstIndexBounds = Timeline.Periods[firstIndex]
        local lastIndexBounds = Timeline.Periods[lastIndex]

        if (firstIndexBounds ~= nil and upperBoundYear ~= nil) then
            local lowerBoundYear = firstIndexBounds.lowerBound
            local upperBoundYear = lastIndexBounds.upperBound

            selectedYear = (lowerBoundYear + upperBoundYear) / 2
        else
            selectedYear = 0
        end
    end

    local minYear = Chronicles.Data:MinEventYear()
    local length = math.abs(minYear - selectedYear)
    local yearIndex = math.floor(length / Timeline.CurrentStepValue)
    local result = yearIndex - (yearIndex % private.constants.config.timeline.pageSize)

    return result
end

function private.Core.Timeline:ChangePage(value)
    Timeline.CurrentPage = Timeline.CurrentPage + value
    self:DisplayTimelineWindow()
end

function private.Core.Timeline:SetYear(year)
    Timeline.SelectedYear = year
end

function private.Core.Timeline:ComputeTimelinePeriods()
    local stepValue = Timeline.CurrentStepValue
    if (stepValue == nil) then
        Timeline.CurrentStepValue = private.constants.config.stepValues[1]
        stepValue = Timeline.CurrentStepValue
    end

    local minYear = Chronicles.Data:MinEventYear()
    local maxYear = Chronicles.Data:MaxEventYear()
    local timelineConfig = GetTimelineConfig(minYear, maxYear, stepValue)
    local timelineBlocks = {}

    for blockIndex = 1, timelineConfig.numberOfTimelineBlock do
        local minValue = 0
        local maxValue = 0

        if (timelineConfig.isOverlapping) then
            if (blockIndex <= timelineConfig.before) then
                minValue = -((timelineConfig.before - blockIndex + 1) * stepValue)
                maxValue = -((timelineConfig.before - blockIndex) * stepValue) - 1
            else
                minValue = ((blockIndex - timelineConfig.before - 1) * stepValue)
                maxValue = ((blockIndex - timelineConfig.before) * stepValue) - 1
            end
        else
            if (timelineConfig.pastEvents == true and blockIndex == 1) then
                minValue = timelineConfig.minYear - 2
                maxValue = timelineConfig.minYear - 1
            elseif (timelineConfig.futurEvents == true and blockIndex == timelineConfig.numberOfTimelineBlock) then
                minValue = timelineConfig.maxYear + 1
                maxValue = timelineConfig.maxYear + 2
            else
                minValue = timelineConfig.minYear + ((blockIndex - 1) * stepValue) + 1
                maxValue = timelineConfig.minYear + (blockIndex * stepValue)
            end
        end

        local period = {
            lowerBound = minValue,
            upperBound = maxValue,
            text = nil,
            hasEvents = nil
        }

        if (maxValue > private.constants.config.currentYear) then
            if (minValue > private.constants.config.currentYear) then
                period.lowerBound = private.constants.config.currentYear + 1
                period.upperBound = private.constants.config.futur
                period.text = Locale["Futur"]
            else
                period.upperBound = private.constants.config.currentYear
            end
        elseif (maxValue < private.constants.config.historyStartYear) then
            if (minValue < private.constants.config.historyStartYear) then
                period.lowerBound = private.constants.config.mythos
                period.upperBound = private.constants.config.historyStartYear - 1
                period.text = Locale["Mythos"]
            else
                period.upperBound = private.constants.config.historyStartYear
            end
        end

        local nbEvents = CountEvents(period)
        period.hasEvents = nbEvents > 0
        period.nbEvents = nbEvents

        table.insert(timelineBlocks, period)
    end

    local displayableTimeFrames = {}
    for j, value in ipairs(timelineBlocks) do
        local nextValue = timelineBlocks[j + 1]

        if (nextValue ~= nil) then
            if (value.hasEvents == true or (value.hasEvents == false and nextValue.hasEvents == true)) then
                table.insert(
                    displayableTimeFrames,
                    {
                        lowerBound = value.lowerBound,
                        upperBound = value.upperBound,
                        text = value.text,
                        hasEvents = value.hasEvents,
                        nbEvents = value.nbEvents
                    }
                )
            end

            if (value.hasEvents == false and nextValue.hasEvents == false) then
                nextValue.lowerBound = value.lowerBound
            end
        else
            table.insert(
                displayableTimeFrames,
                {
                    lowerBound = value.lowerBound,
                    upperBound = value.upperBound,
                    text = value.text,
                    hasEvents = value.hasEvents,
                    nbEvents = value.nbEvents
                }
            )
        end
    end

    Timeline.Periods = displayableTimeFrames
    return displayableTimeFrames
end

-- Helper function to safely trigger events
local function SafeTriggerEvent(eventName, eventData, source)
    private.Core.triggerEvent(eventName, eventData, source)
end

-- Calculate pagination parameters for the timeline window
local function CalculateTimelinePagination()
    local pageIndex = Timeline.CurrentPage
    local pageSize = private.constants.config.timeline.pageSize
    local numberOfCells = #Timeline.Periods
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    -- Validate and normalize page index
    if (pageIndex == nil) then
        pageIndex = maxPageValue
    elseif (pageIndex < 1) then
        pageIndex = 1
    elseif (pageIndex > maxPageValue) then
        pageIndex = maxPageValue
    end

    local firstIndex = 1 + ((pageIndex - 1) * pageSize)

    -- Adjust for boundary conditions
    if (firstIndex <= 1) then
        firstIndex = 1
        pageIndex = 1
    end

    if ((firstIndex + pageSize - 1) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        pageIndex = maxPageValue
    end

    return {
        pageIndex = pageIndex,
        firstIndex = firstIndex,
        pageSize = pageSize,
        numberOfCells = numberOfCells,
        maxPageValue = maxPageValue
    }
end

-- Update navigation button visibility based on pagination state
local function UpdateNavigationButtons(paginationData)
    local showPrevious = paginationData.firstIndex > 1
    local showNext = (paginationData.firstIndex + paginationData.pageSize - 1) < paginationData.numberOfCells

    SafeTriggerEvent(
        private.constants.events.TimelinePreviousButtonVisible,
        showPrevious and {visible = true} or {visible = false},
        "Timeline:UpdateNavigationButtons"
    )

    SafeTriggerEvent(
        private.constants.events.TimelineNextButtonVisible,
        showNext and {visible = true} or {visible = false},
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
function private.Core.Timeline:DisplayTimelineWindow()
    -- Calculate pagination parameters
    local paginationData = CalculateTimelinePagination()

    -- Update the current page state
    Timeline.CurrentPage = paginationData.pageIndex

    -- Update UI state
    UpdateNavigationButtons(paginationData)

    -- Distribute data to UI components
    DistributeTimelineLabels(paginationData)
    DistributeTimelinePeriods(paginationData)
end

function private.Core.Timeline:ChangeCurrentStepValue(direction)
    -- TODO investigate performance issue with step 1 and 10
    local currentStepValue = Timeline.CurrentStepValue
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

    Timeline.CurrentStepValue = nextStepValue

    -- Update state instead of triggering event - provides single source of truth
    if private.Core.StateManager then
        private.Core.StateManager.setState("timeline.currentStep", nextStepValue, "Timeline step changed via zoom")
    end

    private.Core.Timeline:ComputeTimelinePeriods()
    Timeline.CurrentPage = GetYearPageIndex(Timeline.SelectedYear)
    private.Core.Timeline:DisplayTimelineWindow()
end
