local FOLDER_NAME, private = ...

private.Core.EventPerformance = {}

-----------------------------------------------------------------------------------------
-- Performance Monitoring ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

local PerformanceMonitor = {
    enabled = false,
    metrics = {},
    slowEventThreshold = 0.016, -- 16ms (1 frame at 60fps)
    maxMetricsHistory = 1000,
    totalEventsTriggered = 0,
    totalEventTime = 0
}

-----------------------------------------------------------------------------------------
-- Metrics Collection -------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.EventPerformance.startMonitoring()
    PerformanceMonitor.enabled = true
    print("|cFF00FF00[Chronicles EventPerformance]|r Performance monitoring enabled")
end

function private.Core.EventPerformance.stopMonitoring()
    PerformanceMonitor.enabled = false
    print("|cFF00FF00[Chronicles EventPerformance]|r Performance monitoring disabled")
end

function private.Core.EventPerformance.recordEventMetric(eventName, duration, isError, callbackCount)
    if not PerformanceMonitor.enabled then
        return
    end

    local metric = {
        eventName = eventName,
        duration = duration,
        timestamp = GetServerTime(),
        isError = isError or false,
        callbackCount = callbackCount or 1,
        isSlow = duration > PerformanceMonitor.slowEventThreshold
    }

    table.insert(PerformanceMonitor.metrics, metric)

    -- Update totals
    PerformanceMonitor.totalEventsTriggered = PerformanceMonitor.totalEventsTriggered + 1
    PerformanceMonitor.totalEventTime = PerformanceMonitor.totalEventTime + duration

    -- Maintain history size
    if #PerformanceMonitor.metrics > PerformanceMonitor.maxMetricsHistory then
        table.remove(PerformanceMonitor.metrics, 1)
    end

    -- Log slow events immediately
    if metric.isSlow then
        print(
            string.format(
                "|cFFFF7F00[Chronicles EventPerformance]|r Slow event detected: %s took %.3fms",
                eventName,
                duration * 1000
            )
        )
    end

    -- Log errors immediately
    if isError then
        print(
            string.format(
                "|cFFFF0000[Chronicles EventPerformance]|r Error in event: %s (%.3fms)",
                eventName,
                duration * 1000
            )
        )
    end
end

-----------------------------------------------------------------------------------------
-- Performance Analysis -----------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.EventPerformance.getEventStats(eventName)
    local stats = {
        count = 0,
        totalDuration = 0,
        avgDuration = 0,
        maxDuration = 0,
        minDuration = math.huge,
        errorCount = 0,
        slowCount = 0
    }

    for _, metric in ipairs(PerformanceMonitor.metrics) do
        if not eventName or metric.eventName == eventName then
            stats.count = stats.count + 1
            stats.totalDuration = stats.totalDuration + metric.duration
            stats.maxDuration = math.max(stats.maxDuration, metric.duration)
            stats.minDuration = math.min(stats.minDuration, metric.duration)

            if metric.isError then
                stats.errorCount = stats.errorCount + 1
            end

            if metric.isSlow then
                stats.slowCount = stats.slowCount + 1
            end
        end
    end

    if stats.count > 0 then
        stats.avgDuration = stats.totalDuration / stats.count
    else
        stats.minDuration = 0
    end

    return stats
end

function private.Core.EventPerformance.getTopSlowEvents(count)
    count = count or 10

    -- Group by event name
    local eventGroups = {}
    for _, metric in ipairs(PerformanceMonitor.metrics) do
        if not eventGroups[metric.eventName] then
            eventGroups[metric.eventName] = {}
        end
        table.insert(eventGroups[metric.eventName], metric)
    end

    -- Calculate average duration for each event
    local eventAvgs = {}
    for eventName, metrics in pairs(eventGroups) do
        local totalDuration = 0
        local slowCount = 0

        for _, metric in ipairs(metrics) do
            totalDuration = totalDuration + metric.duration
            if metric.isSlow then
                slowCount = slowCount + 1
            end
        end

        table.insert(
            eventAvgs,
            {
                eventName = eventName,
                avgDuration = totalDuration / #metrics,
                count = #metrics,
                slowCount = slowCount,
                slowPercentage = (slowCount / #metrics) * 100
            }
        )
    end

    -- Sort by average duration
    table.sort(
        eventAvgs,
        function(a, b)
            return a.avgDuration > b.avgDuration
        end
    )

    -- Return top N
    local result = {}
    for i = 1, math.min(count, #eventAvgs) do
        table.insert(result, eventAvgs[i])
    end

    return result
end

function private.Core.EventPerformance.getRecentSlowEvents(minutes)
    minutes = minutes or 5
    local cutoffTime = GetServerTime() - (minutes * 60)
    local slowEvents = {}

    for _, metric in ipairs(PerformanceMonitor.metrics) do
        if metric.timestamp >= cutoffTime and metric.isSlow then
            table.insert(slowEvents, metric)
        end
    end

    -- Sort by duration descending
    table.sort(
        slowEvents,
        function(a, b)
            return a.duration > b.duration
        end
    )

    return slowEvents
end

-----------------------------------------------------------------------------------------
-- Performance Wrapper -----------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.EventPerformance.wrapEventTrigger(originalTriggerFunc)
    return function(eventName, data, source)
        local startTime = debugprofilestop()
        local success, result = pcall(originalTriggerFunc, eventName, data, source)
        local endTime = debugprofilestop()
        local duration = (endTime - startTime) / 1000 -- Convert to seconds

        private.Core.EventPerformance.recordEventMetric(eventName, duration, not success, 1)

        if success then
            return result
        else
            error(result)
        end
    end
end

function private.Core.EventPerformance.wrapEventCallback(originalCallback, eventName, owner)
    return function(...)
        local startTime = debugprofilestop()
        local success, result = pcall(originalCallback, ...)
        local endTime = debugprofilestop()
        local duration = (endTime - startTime) / 1000 -- Convert to seconds

        local metricName = eventName .. " -> " .. tostring(owner)
        private.Core.EventPerformance.recordEventMetric(metricName, duration, not success, 1)

        if success then
            return result
        else
            error(result)
        end
    end
end

-----------------------------------------------------------------------------------------
-- Performance Reporting ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.EventPerformance.printSummary()
    if PerformanceMonitor.totalEventsTriggered == 0 then
        print("|cFF00FF00[Chronicles EventPerformance]|r No events recorded yet")
        return
    end

    local avgEventTime = PerformanceMonitor.totalEventTime / PerformanceMonitor.totalEventsTriggered
    local stats = private.Core.EventPerformance.getEventStats()

    print("|cFF00FF00[Chronicles EventPerformance]|r Performance Summary:")
    print(string.format("  Total Events: %d", PerformanceMonitor.totalEventsTriggered))
    print(string.format("  Total Time: %.3fms", PerformanceMonitor.totalEventTime * 1000))
    print(string.format("  Average Time: %.3fms", avgEventTime * 1000))
    print(string.format("  Slow Events: %d (%.1f%%)", stats.slowCount, (stats.slowCount / stats.count) * 100))
    print(string.format("  Errors: %d (%.1f%%)", stats.errorCount, (stats.errorCount / stats.count) * 100))
end

function private.Core.EventPerformance.printTopSlowEvents(count)
    count = count or 5
    local topSlow = private.Core.EventPerformance.getTopSlowEvents(count)

    print("|cFF00FF00[Chronicles EventPerformance]|r Top Slow Events:")
    for i, event in ipairs(topSlow) do
        print(
            string.format(
                "  %d. %s: %.3fms avg (%d calls, %d slow)",
                i,
                event.eventName,
                event.avgDuration * 1000,
                event.count,
                event.slowCount
            )
        )
    end
end

function private.Core.EventPerformance.printRecentSlowEvents(minutes)
    minutes = minutes or 5
    local recentSlow = private.Core.EventPerformance.getRecentSlowEvents(minutes)

    print(string.format("|cFF00FF00[Chronicles EventPerformance]|r Recent Slow Events (last %d minutes):", minutes))
    for i, event in ipairs(recentSlow) do
        local timeAgo = GetServerTime() - event.timestamp
        print(string.format("  %s: %.3fms (%ds ago)", event.eventName, event.duration * 1000, timeAgo))
    end
end

-----------------------------------------------------------------------------------------
-- Auto-Performance Monitoring ---------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.EventPerformance.enableAutoMonitoring()
    if not private.Core.EventManager then
        print("|cFFFF0000[Chronicles EventPerformance]|r EventManager not available")
        return
    end

    -- Wrap the safe trigger function
    local originalSafeTrigger = private.Core.EventManager.safeTrigger
    private.Core.EventManager.safeTrigger = private.Core.EventPerformance.wrapEventTrigger(originalSafeTrigger)

    -- Wrap the safe register callback function
    local originalSafeRegister = private.Core.EventManager.safeRegisterCallback
    private.Core.EventManager.safeRegisterCallback = function(eventName, callback, owner)
        local wrappedCallback = private.Core.EventPerformance.wrapEventCallback(callback, eventName, owner)
        return originalSafeRegister(eventName, wrappedCallback, owner)
    end

    private.Core.EventPerformance.startMonitoring()
    print("|cFF00FF00[Chronicles EventPerformance]|r Auto-monitoring enabled")
end

-----------------------------------------------------------------------------------------
-- Console Commands ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

SLASH_CHRONICLESEVENTPERF1 = "/ceventperf"
SlashCmdList["CHRONICLESEVENTPERF"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1]

    if command == "start" then
        private.Core.EventPerformance.startMonitoring()
    elseif command == "stop" then
        private.Core.EventPerformance.stopMonitoring()
    elseif command == "auto" then
        private.Core.EventPerformance.enableAutoMonitoring()
    elseif command == "summary" then
        private.Core.EventPerformance.printSummary()
    elseif command == "slow" then
        local count = tonumber(args[2]) or 5
        private.Core.EventPerformance.printTopSlowEvents(count)
    elseif command == "recent" then
        local minutes = tonumber(args[2]) or 5
        private.Core.EventPerformance.printRecentSlowEvents(minutes)
    elseif command == "threshold" then
        local newThreshold = tonumber(args[2])
        if newThreshold then
            PerformanceMonitor.slowEventThreshold = newThreshold / 1000 -- Convert ms to seconds
            print(
                string.format(
                    "|cFF00FF00[Chronicles EventPerformance]|r Slow event threshold set to %.1fms",
                    newThreshold
                )
            )
        else
            print(
                string.format(
                    "|cFF00FF00[Chronicles EventPerformance]|r Current slow event threshold: %.1fms",
                    PerformanceMonitor.slowEventThreshold * 1000
                )
            )
        end
    elseif command == "clear" then
        PerformanceMonitor.metrics = {}
        PerformanceMonitor.totalEventsTriggered = 0
        PerformanceMonitor.totalEventTime = 0
        print("|cFF00FF00[Chronicles EventPerformance]|r Performance metrics cleared")
    else
        print("|cFF00FF00[Chronicles EventPerformance]|r Commands:")
        print("  /ceventperf start - Start performance monitoring")
        print("  /ceventperf stop - Stop performance monitoring")
        print("  /ceventperf auto - Enable automatic monitoring with wrapping")
        print("  /ceventperf summary - Show performance summary")
        print("  /ceventperf slow [count] - Show top slow events")
        print("  /ceventperf recent [minutes] - Show recent slow events")
        print("  /ceventperf threshold [ms] - Set/show slow event threshold")
        print("  /ceventperf clear - Clear all metrics")
    end
end
