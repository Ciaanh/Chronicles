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
    local dateProfile = Chronicles.DB:ComputeEventDateProfile(date)
    if (Timeline.CurrentStepValue == 1000) then
        return dateProfile.mod1000
    elseif (Timeline.CurrentStepValue == 500) then
        return dateProfile.mod500
    elseif (Timeline.CurrentStepValue == 250) then
        return dateProfile.mod250
    elseif (Timeline.CurrentStepValue == 100) then
        return dateProfile.mod100
    elseif (Timeline.CurrentStepValue == 50) then
        return dateProfile.mod50
    elseif (Timeline.CurrentStepValue == 10) then
        return dateProfile.mod10
    -- elseif (Timeline.CurrentStepValue == 1) then
    --     return dateProfile.mod1
    end
end

local function GetCurrentStepPeriodsFilling()
    local eventDates = Chronicles.DB.PeriodsFillingBySteps
    if (Timeline.CurrentStepValue == 1000) then
        return eventDates.mod1000
    elseif (Timeline.CurrentStepValue == 500) then
        return eventDates.mod500
    elseif (Timeline.CurrentStepValue == 250) then
        return eventDates.mod250
    elseif (Timeline.CurrentStepValue == 100) then
        return eventDates.mod100
    elseif (Timeline.CurrentStepValue == 50) then
        return eventDates.mod50
    elseif (Timeline.CurrentStepValue == 10) then
        return eventDates.mod10
    -- elseif (Timeline.CurrentStepValue == 1) then
    --     return eventDates.mod1
    end
end

local function CountEvents(block)
    local upperBound = block.upperBound
    local lowerBound = block.lowerBound

    local upperDateIndex = GetDateCurrentStepIndex(upperBound)
    local lowerDateIndex = GetDateCurrentStepIndex(lowerBound)

    local periodsFilling = GetCurrentStepPeriodsFilling()

    if (lowerDateIndex < upperDateIndex) then
        local eventCount = 0
        for i = lowerDateIndex, upperDateIndex, 1 do
            local periodEvents = periodsFilling[i]

            if (periodEvents ~= nil) then
                eventCount = eventCount + #periodEvents
            end
        end
        return eventCount
    elseif lowerDateIndex == upperDateIndex then
        local periodEvents = periodsFilling[lowerDateIndex]
        if (periodEvents ~= nil) then
            return #periodEvents
        end
    end

    return 0
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

    local minYear = Chronicles.DB:MinEventYear()
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

    local minYear = Chronicles.DB:MinEventYear()
    local maxYear = Chronicles.DB:MaxEventYear()
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
            elseif (timelineConfig.futurEvents == true and blockIndex == numberOfCells) then
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

function private.Core.Timeline:DisplayTimelineWindow()
    local pageIndex = Timeline.CurrentPage
    local pageSize = private.constants.config.timeline.pageSize
    local numberOfCells = #Timeline.Periods

    local maxPageValue = math.ceil(numberOfCells / pageSize)
    if (pageIndex == nil) then
        pageIndex = maxPageValue
    elseif (pageIndex < 1) then
        pageIndex = 1
    elseif (pageIndex > maxPageValue) then
        pageIndex = maxPageValue
    end

    local firstIndex = 1 + ((pageIndex - 1) * pageSize)

    if (firstIndex <= 1) then
        firstIndex = 1
        pageIndex = 1

        EventRegistry:TriggerEvent(private.constants.events.TimelinePreviousButtonVisible, false)
    else
        EventRegistry:TriggerEvent(private.constants.events.TimelinePreviousButtonVisible, true)
    end

    if ((firstIndex + pageSize - 1) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        pageIndex = maxPageValue

        EventRegistry:TriggerEvent(private.constants.events.TimelineNextButtonVisible, false)
    else
        EventRegistry:TriggerEvent(private.constants.events.TimelineNextButtonVisible, true)
    end

    Timeline.CurrentPage = pageIndex

    for labelIndex = 1, pageSize + 1, 1 do
        local labelData = Timeline.Periods[firstIndex + labelIndex - 1]
        local eventName = private.constants.events.DisplayTimelineLabel .. tostring(labelIndex)
        if (labelData ~= nil) then
            if labelIndex == pageSize + 1 then
                labelData = Timeline.Periods[firstIndex + labelIndex - 2]
                EventRegistry:TriggerEvent(eventName, tostring(labelData.upperBound))
            else
                if (labelData.text ~= nil) then
                    EventRegistry:TriggerEvent(eventName, labelData.text)
                else
                    EventRegistry:TriggerEvent(eventName, tostring(labelData.lowerBound))
                end
            end
        else
            EventRegistry:TriggerEvent(eventName, nil)
        end
    end

    for periodIndex = 1, pageSize, 1 do
        local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(periodIndex)
        local periodData = Timeline.Periods[firstIndex + periodIndex - 1]

        EventRegistry:TriggerEvent(eventName, periodData)
    end
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

    private.Core.Timeline:ComputeTimelinePeriods()
    Timeline.CurrentPage = GetYearPageIndex(Timeline.SelectedYear)
    private.Core.Timeline:DisplayTimelineWindow()
end
