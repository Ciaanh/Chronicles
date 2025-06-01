--[[
    Chronicles Timeline Business Logic Module
    
    Phase 3 of Clean Code Reorganization - Timeline Business Logic Extraction
    
    This module extracts pure timeline business logic from Timeline.lua, separating:
    - Timeline calculation algorithms from UI display logic
    - Period generation and management from UI event distribution
    - Event counting and filtering from display coordination
    
    EXTRACTED RESPONSIBILITIES:
    - Timeline period calculation and generation
    - Event counting and aggregation within periods
    - Timeline configuration computation (overlapping, boundaries, etc.)
    - Period filtering and consolidation logic
    - Timeline pagination calculations
    
    DEPENDENCIES:
    - Chronicles.Data (for event data access)
    - private.Core.StateManager (for timeline state)
    - private.Core.Logger (for logging)
    - private.constants.config (for configuration values)
    
    USAGE:
    - Used by Timeline.lua for pure business logic
    - Used by UI components for timeline data
    - Maintains separation from presentation logic
--]]
local FOLDER_NAME, private = ...

-- Initialize TimelineBusiness module
if not private.Core then
    private.Core = {}
end
private.Core.TimelineBusiness = {}
local TimelineBusiness = private.Core.TimelineBusiness

-- Helper function to safely access Chronicles
local function getChronicles()
    return private.Chronicles
end

-----------------------------------------------------------------------------------------
-- Timeline Configuration Logic ---------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Calculate timeline configuration based on data boundaries
    @param minYear [number] Minimum event year
    @param maxYear [number] Maximum event year  
    @param stepValue [number] Current timeline step value
    @return [table] Timeline configuration object
]]
function TimelineBusiness.calculateTimelineConfig(minYear, maxYear, stepValue)
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "TimelineBusiness",
            "Chronicles.Data not initialized when calculating timeline config"
        )
        return {
            isOverlapping = false,
            pastEvents = false,
            futurEvents = false,
            before = 0,
            after = 0,
            minYear = 0,
            maxYear = 0,
            numberOfTimelineBlock = 0
        }
    end

    -- Safety check: ensure constants are available
    if not private.constants or not private.constants.config then
        private.Core.Logger.warn("TimelineBusiness", "Constants not available when calculating timeline config")
        return {
            isOverlapping = false,
            pastEvents = false,
            futurEvents = false,
            before = 0,
            after = 0,
            minYear = 0,
            maxYear = 0,
            numberOfTimelineBlock = 0
        }
    end

    local config = private.constants.config
    if not config.historyStartYear or not config.currentYear then
        private.Core.Logger.warn("TimelineBusiness", "Required config values are nil for timeline config")
        return {
            isOverlapping = false,
            pastEvents = false,
            futurEvents = false,
            before = 0,
            after = 0,
            minYear = 0,
            maxYear = 0,
            numberOfTimelineBlock = 0
        }
    end

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
    if (minYear < config.historyStartYear) then
        timelineConfig.minYear = config.historyStartYear
        timelineConfig.pastEvents = true
    end

    if (maxYear > config.currentYear) then
        timelineConfig.maxYear = config.currentYear
        timelineConfig.futurEvents = true
    end

    if (timelineConfig.minYear < 0 and timelineConfig.maxYear > 0) then
        timelineConfig.isOverlapping = true
    end

    if (timelineConfig.minYear < 0) then
        local beforeLength = math.abs(timelineConfig.minYear)
        timelineConfig.before = math.ceil(beforeLength / stepValue)
    end

    if (timelineConfig.maxYear > 0) then
        local afterLength = math.abs(timelineConfig.maxYear)
        timelineConfig.after = math.ceil(afterLength / stepValue)
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

-----------------------------------------------------------------------------------------
-- Event Counting and Analysis ----------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Get date profile index for current step value
    @param date [number] The date to get index for
    @return [number] Date index for current step
]]
function TimelineBusiness.getDateCurrentStepIndex(date)
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error("TimelineBusiness", "Chronicles.Data not initialized when getting date index")
        return 0
    end

    local dateProfile = Chronicles.Data:ComputeEventDateProfile(date)
    local currentStepValue = private.Core.StateManager.getState("timeline.currentStep")

    if (currentStepValue == 1000) then
        return dateProfile.mod1000 or 0
    elseif (currentStepValue == 500) then
        return dateProfile.mod500 or 0
    elseif (currentStepValue == 250) then
        return dateProfile.mod250 or 0
    elseif (currentStepValue == 100) then
        return dateProfile.mod100 or 0
    elseif (currentStepValue == 50) then
        return dateProfile.mod50 or 0
    elseif (currentStepValue == 10) then
        return dateProfile.mod10 or 0
    elseif (currentStepValue == 1) then
        return 0 -- Return default value for step 1 (not implemented)
    else
        return 0 -- Return default value for unsupported step values
    end
end

--[[
    Get periods filling data for current step
    @return [table] Periods filling data organized by step value
]]
function TimelineBusiness.getCurrentStepPeriodsFilling()
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error("TimelineBusiness", "Chronicles.Data not initialized when getting periods filling")
        return {}
    end

    local eventDates = private.Core.Cache.getPeriodsFillingBySteps()
    if eventDates == nil then
        return {}
    end

    local currentStepValue = private.Core.StateManager.getState("timeline.currentStep")

    if (currentStepValue == 1000) then
        return eventDates.mod1000 or {}
    elseif (currentStepValue == 500) then
        return eventDates.mod500 or {}
    elseif (currentStepValue == 250) then
        return eventDates.mod250 or {}
    elseif (currentStepValue == 100) then
        return eventDates.mod100 or {}
    elseif (currentStepValue == 50) then
        return eventDates.mod50 or {}
    elseif (currentStepValue == 10) then
        return eventDates.mod10 or {}
    elseif (currentStepValue == 1) then
        return {} -- Return empty table for step 1 (not implemented)
    else
        return {} -- Return empty table for unsupported step values
    end
end

--[[
    Count events within a timeline period block
    @param block [table] Timeline period block with lowerBound and upperBound
    @return [number] Number of events in the period
]]
function TimelineBusiness.countEventsInPeriod(block)
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error("TimelineBusiness", "Chronicles.Data not initialized when counting events")
        return 0
    end

    -- Safety check: ensure constants are available
    if not private.constants or not private.constants.config then
        private.Core.Logger.warn("TimelineBusiness", "Constants not available when counting events, returning 0")
        return 0
    end

    local config = private.constants.config
    if not config.mythos or not config.futur or not config.historyStartYear or not config.currentYear then
        private.Core.Logger.warn("TimelineBusiness", "Required config values are nil, returning 0")
        return 0
    end

    local eventCount = 0
    local originalLowerBound = block.lowerBound
    local originalUpperBound = block.upperBound

    -- Handle special periods differently
    local isMytosPeriod = (originalLowerBound == config.mythos)
    local isFuturePeriod = (originalUpperBound == config.futur)
    if isMytosPeriod then
        -- For mythos period: manually search for events before historyStartYear
        local mythosYearEnd = config.historyStartYear - 1
        local foundEvents = private.Core.Cache.getSearchEvents(config.mythos, mythosYearEnd)
        if foundEvents ~= nil then
            eventCount = #foundEvents
        end
    elseif isFuturePeriod then
        -- For future period: manually search for events beyond currentYear
        local futureYearStart = config.currentYear + 1
        local foundEvents = private.Core.Cache.getSearchEvents(futureYearStart, config.futur)
        if foundEvents ~= nil then
            eventCount = #foundEvents
        end
    else
        -- Regular period processing
        local lowerBound = originalLowerBound
        local upperBound = originalUpperBound -- Clamp bounds to valid date range for date index calculation only
        if (lowerBound < config.historyStartYear) then
            lowerBound = config.historyStartYear
        end
        if (upperBound > config.currentYear) then
            upperBound = config.currentYear
        end

        local lowerDateIndex = TimelineBusiness.getDateCurrentStepIndex(lowerBound)
        local upperDateIndex = TimelineBusiness.getDateCurrentStepIndex(upperBound)

        if upperDateIndex == nil or lowerDateIndex == nil then
            return eventCount
        end

        local periodsFilling = TimelineBusiness.getCurrentStepPeriodsFilling()
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

-----------------------------------------------------------------------------------------
-- Timeline Period Generation -----------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Generate timeline periods based on configuration
    @param stepValue [number] Current timeline step value
    @return [table] Array of timeline periods with bounds and event data
]]
function TimelineBusiness.generateTimelinePeriods(stepValue)
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error("TimelineBusiness", "Chronicles.Data not initialized when generating periods")
        -- Return default empty periods instead of empty table
        -- This ensures timeline UI has something to display
        return TimelineBusiness.generateDefaultPeriods(stepValue)
    end

    local minYear = Chronicles.Data:MinEventYear()
    local maxYear = Chronicles.Data:MaxEventYear()

    -- If no events are loaded or found, use default range
    if not minYear or not maxYear or minYear > maxYear then
        private.Core.Logger.warn("TimelineBusiness", "No valid event range found, using defaults")
        return TimelineBusiness.generateDefaultPeriods(stepValue)
    end

    local timelineConfig = TimelineBusiness.calculateTimelineConfig(minYear, maxYear, stepValue)
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

        -- Handle special period types
        if (maxValue > private.constants.config.currentYear) then
            if (minValue > private.constants.config.currentYear) then
                period.lowerBound = private.constants.config.currentYear + 1
                period.upperBound = private.constants.config.futur
                period.text = nil -- Let the UI layer handle localization
            else
                period.upperBound = private.constants.config.currentYear
            end
        elseif (maxValue < private.constants.config.historyStartYear) then
            if (minValue < private.constants.config.historyStartYear) then
                period.lowerBound = private.constants.config.mythos
                period.upperBound = private.constants.config.historyStartYear - 1
                period.text = nil -- Let the UI layer handle localization
            else
                period.upperBound = private.constants.config.historyStartYear
            end
        end

        -- Calculate event data for this period
        local nbEvents = TimelineBusiness.countEventsInPeriod(period)
        period.hasEvents = nbEvents > 0
        period.nbEvents = nbEvents

        table.insert(timelineBlocks, period)
    end

    return timelineBlocks
end

--[[
    Generate default timeline periods when no events are loaded
    @param stepValue [number] Current timeline step value
    @return [table] Array of default timeline periods
]]
function TimelineBusiness.generateDefaultPeriods(stepValue)
    private.Core.Logger.trace("TimelineBusiness", "Generating default timeline periods")

    local defaultMinYear = -10000 -- Example default minimum year
    local defaultMaxYear = private.constants.config.currentYear
    local timelineConfig = TimelineBusiness.calculateTimelineConfig(defaultMinYear, defaultMaxYear, stepValue)
    local timelineBlocks = {}

    -- Generate a reasonable number of default periods
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
            hasEvents = false,
            nbEvents = 0
        }

        -- Handle special period types
        if (maxValue > private.constants.config.currentYear) then
            if (minValue > private.constants.config.currentYear) then
                period.lowerBound = private.constants.config.currentYear + 1
                period.upperBound = private.constants.config.futur
                period.text = nil -- Let the UI layer handle localization
            else
                period.upperBound = private.constants.config.currentYear
            end
        elseif (maxValue < private.constants.config.historyStartYear) then
            if (minValue < private.constants.config.historyStartYear) then
                period.lowerBound = private.constants.config.mythos
                period.upperBound = private.constants.config.historyStartYear - 1
                period.text = nil -- Let the UI layer handle localization
            else
                period.upperBound = private.constants.config.historyStartYear
            end
        end

        table.insert(timelineBlocks, period)
    end

    return timelineBlocks
end

--[[
    Consolidate timeline periods by merging adjacent empty periods
    @param timelineBlocks [table] Array of raw timeline periods
    @return [table] Array of consolidated timeline periods
]]
function TimelineBusiness.consolidateTimelinePeriods(timelineBlocks)
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

    return displayableTimeFrames
end

-----------------------------------------------------------------------------------------
-- Timeline Pagination Logic ------------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Calculate pagination parameters for timeline display
    @param periods [table] Array of timeline periods
    @param currentPage [number] Current page number (optional)
    @return [table] Pagination data with bounds and navigation info
]]
function TimelineBusiness.calculateTimelinePagination(periods, currentPage)
    local pageSize = private.constants.config.timeline.pageSize
    local numberOfCells = #periods
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    -- Validate and normalize page index
    if (currentPage == nil) then
        currentPage = maxPageValue
        private.Core.StateManager.setState(
            "timeline.currentPage",
            currentPage,
            "Timeline page initialized to last page"
        )
    end

    if (currentPage < 1) then
        currentPage = 1
        private.Core.StateManager.setState("timeline.currentPage", currentPage, "Timeline page clamped to minimum")
    end

    if (currentPage > maxPageValue) then
        currentPage = maxPageValue
        private.Core.StateManager.setState("timeline.currentPage", currentPage, "Timeline page clamped to maximum")
    end

    -- Calculate page bounds
    local firstIndex = 1 + ((currentPage - 1) * pageSize)

    if (firstIndex <= 1) then
        firstIndex = 1
        currentPage = 1
    end

    if ((firstIndex + pageSize - 1) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        currentPage = maxPageValue
    end

    -- Calculate navigation button visibility
    local showPrevious = (currentPage > 1)
    local showNext = (currentPage < maxPageValue)

    return {
        currentPage = currentPage,
        maxPage = maxPageValue,
        firstIndex = firstIndex,
        pageSize = pageSize,
        totalPeriods = numberOfCells,
        showPrevious = showPrevious,
        showNext = showNext
    }
end

--[[
    Calculate page index for a specific year
    @param year [number] The year to find page for
    @param periods [table] Array of timeline periods
    @return [number] Page index containing the specified year
]]
function TimelineBusiness.getYearPageIndex(year, periods)
    local selectedYear = year
    local pageSize = private.constants.config.timeline.pageSize
    local numberOfCells = #periods

    if (selectedYear == nil) then
        local currentPage = private.Core.StateManager.getState("timeline.currentPage") or 1
        local firstIndex = 1 + ((currentPage - 1) * pageSize)
        local lastIndex = currentPage * pageSize

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if (lastIndex > numberOfCells) then
            firstIndex = numberOfCells - (pageSize)
            lastIndex = numberOfCells - 1
        end

        local firstIndexBounds = periods[firstIndex]
        local lastIndexBounds = periods[lastIndex]

        if (firstIndexBounds ~= nil and lastIndexBounds ~= nil) then
            local lowerBoundYear = firstIndexBounds.lowerBound
            local upperBoundYear = lastIndexBounds.upperBound
            selectedYear = (lowerBoundYear + upperBoundYear) / 2
        else
            selectedYear = 0
        end
    end

    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        return 1
    end

    local minYear = Chronicles.Data:MinEventYear()
    local length = math.abs(minYear - selectedYear)
    local currentStepValue = private.Core.StateManager.getState("timeline.currentStep")
    local yearIndex = math.floor(length / currentStepValue)
    local result = yearIndex - (yearIndex % pageSize)

    return result
end

--[[
    Get step value index from the configuration
    @param stepValue [number] The step value to find index for
    @return [number] Index of the step value in configuration
]]
function TimelineBusiness.getStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(private.constants.config.stepValues) do
        index[v] = k
    end
    return index[stepValue]
end

-----------------------------------------------------------------------------------------
-- Main Timeline Business Logic Interface -----------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Compute complete timeline periods for current state
    @return [table] Array of displayable timeline periods
]]
function TimelineBusiness.computeTimelinePeriods()
    local stepValue = private.Core.StateManager.getState("timeline.currentStep")
    if (stepValue == nil) then
        stepValue = private.constants.config.stepValues[1]
        private.Core.Logger.trace(
            "TimelineBusiness",
            "Initializing timeline step to default value: " .. tostring(stepValue)
        )
        private.Core.StateManager.setState("timeline.currentStep", stepValue, "Timeline step initialized")
    end

    private.Core.Logger.trace("TimelineBusiness", "Computing timeline periods with step value: " .. tostring(stepValue))

    -- Generate raw timeline periods
    local rawPeriods = TimelineBusiness.generateTimelinePeriods(stepValue)

    -- Consolidate periods by merging adjacent empty ones
    local consolidatedPeriods = TimelineBusiness.consolidateTimelinePeriods(rawPeriods)

    private.Core.Logger.trace("TimelineBusiness", "Generated " .. #consolidatedPeriods .. " timeline periods")

    -- -- Debug print of periods
    -- for i, period in ipairs(consolidatedPeriods) do
    --     print(
    --         string.format(
    --             "Period %d: lowerBound=%s, upperBound=%s, hasEvents=%s, nbEvents=%s",
    --             i,
    --             tostring(period.lowerBound),
    --             tostring(period.upperBound),
    --             tostring(period.hasEvents),
    --             tostring(period.nbEvents)
    --         )
    --     )
    -- end

    return consolidatedPeriods
end

return TimelineBusiness
