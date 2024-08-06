local FOLDER_NAME, private = ...

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Timeline = {}

local Chronicles = private.Chronicles

-----------------------------------------------------------------------------------------
-- Timeline -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
local Timeline = private.Core.Timeline
Timeline.MaxStepIndex = 7
Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 1}
Timeline.CurrentStepValue = nil
Timeline.CurrentPage = nil
Timeline.SelectedYear = nil
Timeline.Periods = {}

function private.Core.Timeline:ChangePage(value)
    self.DefineDisplayedTimelinePage(Timeline.CurrentPage + value)
    self.DisplayTimelineWindow()
end

function private.Core.Timeline:SetYear(year)
    Timeline.SelectedYear = year
end

function private.Core.Timeline.ComputeTimelinePeriods()
    local stepValue = Timeline.CurrentStepValue
    if (stepValue == nil) then
        Timeline.CurrentStepValue = Timeline.StepValues[1]
        stepValue = Timeline.CurrentStepValue
    end

    local minYear = Chronicles.DB:MinEventYear()
    local maxYear = Chronicles.DB:MaxEventYear()
    local timelineConfig = GetTimelineConfig(minYear, maxYear, stepValue)

    -- for k, v in pairs(timelineConfig) do
    --     print("-- " .. k .. " " .. tostring(v))
    -- end

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
                period.upperBound = 999999
                period.text = Locale["Futur"]
            else
                period.upperBound = private.constants.config.currentYear
            end
        elseif (maxValue < private.constants.config.historyStartYear) then
            if (minValue < private.constants.config.historyStartYear) then
                period.lowerBound = -999999
                period.upperBound = private.constants.config.historyStartYear - 1
                period.text = Locale["Mythos"]
            else
                period.upperBound = private.constants.config.historyStartYear
            end
        end

        local nbEvents = CountEvents(period)
        period.hasEvents = nbEvents > 0
        period.nbEvents = nbEvents

        -- if period.hasEvents then
        --     print("-- blockIndex " .. tostring(i))
        -- end
        -- print("-- blockIndex " .. tostring(period))

        table.insert(timelineBlocks, period)
    end

    local displayableTimeFrames = {}
    for j, value in ipairs(timelineBlocks) do
        local nextValue = timelineBlocks[j + 1]

        -- if (value.lowerBound == 40) then
        --     print("-- value.lowerBound " .. value.lowerBound)
        -- end

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

    -- for i, v in ipairs(displayableTimeFrames) do
    --     print(
    --         "-- block " ..
    --             i .. --" " .. #displayableTimeFrames ..
    --                 " " .. tostring(v) .. " " .. tostring(v.lowerBound) .. " " .. tostring(v.upperBound)
    --     )
    -- end

    -- print(#displayableTimeFrames)

    Timeline.Periods = displayableTimeFrames

    -- for index, value in ipairs(displayableTimeFrames) do
    --     print(index)
    --     print(value)
    -- end

    return displayableTimeFrames
end

function CountEvents(block)
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

function GetDateCurrentStepIndex(date)
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
    elseif (Timeline.CurrentStepValue == 1) then
        return dateProfile.mod1
    end
end

function GetCurrentStepPeriodsFilling()
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
    elseif (Timeline.CurrentStepValue == 1) then
        return eventDates.mod1
    end
end

function GetTimelineConfig(minYear, maxYear, stepValue)
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

        timelineConfig.after = math.ceil((afterLength) / stepValue)

        if (maxYear == private.constants.config.currentYear and stepValue < private.constants.config.currentYear) then
            timelineConfig.after = timelineConfig.after + 1
        end
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

-- pageIndex goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function private.Core.Timeline.DefineDisplayedTimelinePage(debounceIndex)
    local pageIndex = Timeline.CurrentPage
    local pageSize = private.constants.config.timeline.pageSize

    if (debounceIndex ~= nil) then
        if (debounceIndex ~= pageIndex) then
            pageIndex = debounceIndex
        else
            return
        end
    end

    local timelineNextButtonEnable = false
    local timelinePreviousButtonEnable = false

    local maxPageValue = 1
    local minPageValue = 1

    local numberOfCells = #Timeline.Periods
    if (numberOfCells == 0) then
        -- print("Set current page" .. tostring(1))
        Timeline.CurrentPage = 1

        timelineNextButtonEnable = false
        timelinePreviousButtonEnable = false

        return {
            TimelineMin = minPageValue,
            TimelineMax = maxPageValue,
            TimelineNextButtonEnable = timelineNextButtonEnable,
            TimelinePreviousButtonEnable = timelinePreviousButtonEnable,
            HideAllTimelineBlocks = true,
            PageIndex = Timeline.CurrentPage,
            PageSize = pageSize,
            NumberOfCells = numberOfCells
        }
    end

    maxPageValue = math.ceil(numberOfCells / pageSize)
    if (pageIndex == nil) then
        pageIndex = maxPageValue
    elseif (pageIndex < 1) then
        pageIndex = 1
    elseif (pageIndex > maxPageValue) then
        pageIndex = maxPageValue
    end

    -- print("Set current page" .. tostring(pageIndex))
    Timeline.CurrentPage = pageIndex

    if (numberOfCells <= pageSize) then
        timelineNextButtonEnable = false
        timelinePreviousButtonEnable = false
    else
        timelineNextButtonEnable = true
        timelinePreviousButtonEnable = true
    end

    --Chronicles.UI.Timeline:BuildTimelineBlocks(pageIndex, pageSize, numberOfCells, maxPageValue)

    return {
        TimelineMin = minPageValue,
        TimelineMax = maxPageValue,
        TimelineNextButtonEnable = timelineNextButtonEnable,
        TimelinePreviousButtonEnable = timelinePreviousButtonEnable,
        HideAllTimelineBlocks = false,
        PageIndex = Timeline.CurrentPage,
        PageSize = pageSize,
        NumberOfCells = numberOfCells
    }
end

function private.Core.Timeline.DisplayTimelineWindow()
    -- print("DisplayTimelineWindow")
    local pageIndex = Timeline.CurrentPage
    local pageSize = private.constants.config.timeline.pageSize
    local numberOfCells = #Timeline.Periods
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    local firstIndex = 1 + ((pageIndex - 1) * pageSize)

    -- print("Current page" .. tostring(pageIndex))

    if (firstIndex <= 1) then
        firstIndex = 1
        -- TimelinePreviousButton:Disable()
        -- print("Set current page" .. tostring(1))
        Timeline.CurrentPage = 1

        EventRegistry:TriggerEvent(private.constants.events.TimelinePreviousButtonVisible, false)
    else
        EventRegistry:TriggerEvent(private.constants.events.TimelinePreviousButtonVisible, true)
    end

    if ((firstIndex + pageSize - 1) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        -- TimelineNextButton:Disable()
        -- print("Set current page" .. tostring(maxPageValue))
        Timeline.CurrentPage = maxPageValue

        EventRegistry:TriggerEvent(private.constants.events.TimelineNextButtonVisible, false)
    else
        EventRegistry:TriggerEvent(private.constants.events.TimelineNextButtonVisible, true)
    end

    -- print("First index " .. tostring(firstIndex))
    -- print("Current page " .. tostring(Timeline.CurrentPage))

    for labelIndex = 1, pageSize + 1, 1 do
        -- print(tostring(labelIndex)) -- crash on index 1

        local labelData = Timeline.Periods[firstIndex + labelIndex - 1]
        local eventName = private.constants.events.DisplayTimelineLabel .. tostring(labelIndex)

        -- if labelData == nil then
        --     print("data nil " .. tostring(#Timeline.Periods))
        -- end

        if labelIndex == pageSize + 1 then
            labelData = Timeline.Periods[firstIndex + labelIndex - 2]

            -- print(tostring(labelIndex) .. "-- data.upperBound " .. tostring(labelData.upperBound))
            EventRegistry:TriggerEvent(eventName, tostring(labelData.upperBound))
        else
            if (labelData.text ~= nil) then
                -- print(tostring(labelIndex) .. "-- use data.text " .. labelData.text)
                EventRegistry:TriggerEvent(eventName, labelData.text)
            else
                -- end
                -- if (labelData.lowerBound == labelData.upperBound) then
                --     print(tostring(labelIndex) .. "-- data.text lowerBound " .. tostring(labelData.lowerBound))
                --     EventRegistry:TriggerEvent(eventName, tostring(labelData.lowerBound))
                -- else
                -- print(tostring(labelIndex) .. "-- data lowerBound " .. tostring(labelData.lowerBound))
                EventRegistry:TriggerEvent(eventName, tostring(labelData.lowerBound))
            end
        end

        -- print("Trigger " .. eventName .. " "..labelData)
        -- EventRegistry:TriggerEvent(eventName, labelData)
    end

    for periodIndex = 1, pageSize, 1 do
        local periodData = Timeline.Periods[firstIndex + periodIndex - 1]

        local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(periodIndex)
        -- print("Trigger " .. eventName)
        EventRegistry:TriggerEvent(eventName, periodData)
    end
end


function private.Core.Timeline.GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(Timeline.StepValues) do
        index[v] = k
    end
    return index[stepValue]
end

function private.Core.Timeline.ChangeCurrentStepValue(stepValue)
	if (stepValue == nil) then
		stepValue = Timeline.StepValues[1]
	end

	Timeline.CurrentStepValue = stepValue

	private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DefineDisplayedTimelinePage()
    private.Core.Timeline.DisplayTimelineWindow()
end
