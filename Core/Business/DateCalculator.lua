local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: DateCalculator
Purpose: Business logic for date and time calculations in Chronicles timeline
Dependencies: Core.Utils.ValidationUtils (via private namespace)
Author: Chronicles Team
=================================================================================

This module provides comprehensive date and timeline calculation functionality:
- Event duration calculations
- Year-based event filtering and validation
- Timeline period calculations
- Date range operations for historical events

Key Features:
- Event active year checking for timeline display
- Duration calculations for event spans
- Timeline period boundary calculations
- Year validation and normalization

Usage Example:
    local duration = DateCalculator.GetEventDuration(eventData)
    local isActive = DateCalculator.IsEventActiveInYear(eventData, -10000)
    local periods = DateCalculator.CalculateTimelinePeriods(startYear, endYear)

Event Integration:
- Used by Timeline module for period calculations
- Integrates with FilterEngine for year-based filtering
- Supports both positive and negative years (BC/AD system)

Dependencies:
- ValidationUtils (via private.Core.Utils.ValidationUtils)
- Constants for timeline configuration
=================================================================================
]]

private.Core.Business = private.Core.Business or {}
private.Core.Business.DateCalculator = {}

local DateCalculator = private.Core.Business.DateCalculator

-- Dependencies
local ValidationUtils = private.Core.Utils.ValidationUtils

-- Note: Utilities are accessed as globals since they're loaded before this module

--[[
    Calculate the duration of an event in years
    @param event [table] Event object with yearStart and yearEnd
    @return [number] Duration in years, 0 if invalid
]]
function DateCalculator.GetEventDuration(event)
    if not ValidationUtils.IsValidEvent(event) then
        return 0
    end

    return math.max(0, event.yearEnd - event.yearStart + 1)
end

--[[
    Check if an event is active during a specific year
    @param event [table] Event object
    @param year [number] Year to check
    @return [boolean] True if event is active during the year
]]
function DateCalculator.IsEventActiveInYear(event, year)
    if not ValidationUtils.IsValidEvent(event) or not ValidationUtils.IsValidYear(year) then
        return false
    end

    return year >= event.yearStart and year <= event.yearEnd
end

--[[
    Check if two events overlap in time
    @param event1 [table] First event
    @param event2 [table] Second event
    @return [boolean] True if events overlap
    @return [number] Start year of overlap (if any)
    @return [number] End year of overlap (if any)
]]
function DateCalculator.DoEventsOverlap(event1, event2)
    if not ValidationUtils.IsValidEvent(event1) or not ValidationUtils.IsValidEvent(event2) then
        return false, nil, nil
    end

    local overlapStart = math.max(event1.yearStart, event2.yearStart)
    local overlapEnd = math.min(event1.yearEnd, event2.yearEnd)

    if overlapStart <= overlapEnd then
        return true, overlapStart, overlapEnd
    else
        return false, nil, nil
    end
end

--[[
    Get events that overlap with a given time period
    @param events [table] List of events
    @param startYear [number] Start year of period
    @param endYear [number] End year of period
    @return [table] Events that overlap with the period
]]
function DateCalculator.GetEventsInPeriod(events, startYear, endYear)
    if
        not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidYear(startYear) or
            not ValidationUtils.IsValidYear(endYear)
     then
        return {}
    end

    local eventsInPeriod = {}

    for _, event in pairs(events) do
        if ValidationUtils.IsValidEvent(event) then
            local overlaps, _, _ =
                DateCalculator.DoEventsOverlap(
                event,
                {yearStart = startYear, yearEnd = endYear, id = -1, label = "period"}
            )

            if overlaps then
                table.insert(eventsInPeriod, event)
            end
        end
    end

    return eventsInPeriod
end

--[[
    Calculate the time gap between two events
    @param event1 [table] First event (should end first)
    @param event2 [table] Second event (should start later)
    @return [number] Years between events, negative if they overlap
]]
function DateCalculator.GetTimeBetweenEvents(event1, event2)
    if not ValidationUtils.IsValidEvent(event1) or not ValidationUtils.IsValidEvent(event2) then
        return 0
    end

    return event2.yearStart - event1.yearEnd - 1
end

--[[
    Find the earliest and latest years across a set of events
    @param events [table] List of events
    @return [number] Earliest year (or nil if no valid events)
    @return [number] Latest year (or nil if no valid events)
]]
function DateCalculator.GetTimeSpan(events)
    if not ValidationUtils.IsValidTable(events) then
        return nil, nil
    end

    local earliestYear = nil
    local latestYear = nil

    for _, event in pairs(events) do
        if ValidationUtils.IsValidEvent(event) then
            if not earliestYear or event.yearStart < earliestYear then
                earliestYear = event.yearStart
            end
            if not latestYear or event.yearEnd > latestYear then
                latestYear = event.yearEnd
            end
        end
    end

    return earliestYear, latestYear
end

--[[
    Calculate which timeline period a year falls into
    @param year [number] Year to check
    @param periods [table] List of timeline periods
    @return [table] Timeline period object or nil if not found
]]
function DateCalculator.GetPeriodForYear(year, periods)
    if not ValidationUtils.IsValidYear(year) or not ValidationUtils.IsValidTable(periods) then
        return nil
    end

    for _, period in pairs(periods) do
        if ValidationUtils.IsValidPeriod(period) then
            if year >= period.yearStart and year <= period.yearEnd then
                return period
            end
        end
    end

    return nil
end

--[[
    Sort events chronologically
    @param events [table] List of events to sort
    @return [table] Sorted events (copy)
]]
function DateCalculator.SortEventsByDate(events)
    if not ValidationUtils.IsValidTable(events) then
        return {}
    end

    local sortedEvents = {}
    for _, event in pairs(events) do
        if ValidationUtils.IsValidEvent(event) then
            table.insert(sortedEvents, event)
        end
    end

    table.sort(
        sortedEvents,
        function(a, b)
            if a.yearStart == b.yearStart then
                if a.yearEnd == b.yearEnd then
                    return (a.order or 0) < (b.order or 0)
                end
                return a.yearEnd < b.yearEnd
            end
            return a.yearStart < b.yearStart
        end
    )

    return sortedEvents
end

--[[
    Group events by time periods
    @param events [table] List of events
    @param periods [table] List of timeline periods
    @return [table] Events grouped by period {periodId = {events}}
]]
function DateCalculator.GroupEventsByPeriod(events, periods)
    if not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidTable(periods) then
        return {}
    end

    local groupedEvents = {}

    for _, period in pairs(periods) do
        if ValidationUtils.IsValidPeriod(period) then
            groupedEvents[period.id] = DateCalculator.GetEventsInPeriod(events, period.yearStart, period.yearEnd)
        end
    end

    return groupedEvents
end

--[[
    Calculate event density for a time period (events per year)
    @param events [table] List of events
    @param startYear [number] Start year of period
    @param endYear [number] End year of period
    @return [number] Events per year (density)
]]
function DateCalculator.GetEventDensity(events, startYear, endYear)
    if
        not ValidationUtils.IsValidTable(events) or not ValidationUtils.IsValidYear(startYear) or
            not ValidationUtils.IsValidYear(endYear) or
            endYear < startYear
     then
        return 0
    end

    local eventsInPeriod = DateCalculator.GetEventsInPeriod(events, startYear, endYear)
    local periodLength = endYear - startYear + 1

    return #eventsInPeriod / periodLength
end

--[[
    Find events that are contemporaneous (overlapping) with a given event
    @param targetEvent [table] Event to find contemporaries for
    @param allEvents [table] List of all events to search
    @return [table] Events that overlap with the target event
]]
function DateCalculator.GetContemporaneousEvents(targetEvent, allEvents)
    if not ValidationUtils.IsValidEvent(targetEvent) or not ValidationUtils.IsValidTable(allEvents) then
        return {}
    end

    local contemporaries = {}

    for _, event in pairs(allEvents) do
        if ValidationUtils.IsValidEvent(event) and event.id ~= targetEvent.id then
            local overlaps, _, _ = DateCalculator.DoEventsOverlap(targetEvent, event)
            if overlaps then
                table.insert(contemporaries, event)
            end
        end
    end

    return contemporaries
end

--[[
    Calculate relative time description
    @param fromYear [number] Reference year
    @param toYear [number] Target year
    @return [string] Human-readable time description
]]
function DateCalculator.GetRelativeTimeDescription(fromYear, toYear)
    if not ValidationUtils.IsValidYear(fromYear) or not ValidationUtils.IsValidYear(toYear) then
        return "Unknown time"
    end

    local difference = toYear - fromYear

    if difference == 0 then
        return "Same year"
    elseif difference > 0 then
        if difference == 1 then
            return "1 year later"
        else
            return difference .. " years later"
        end
    else
        local absDiff = math.abs(difference)
        if absDiff == 1 then
            return "1 year earlier"
        else
            return absDiff .. " years earlier"
        end
    end
end

-- Module export
return DateCalculator
