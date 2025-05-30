local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

-- Centralized Cache Management System
-- Responsible for all caching operations throughout the Chronicles addon
private.Core.Cache = {}

-----------------------------------------------------------------------------------------
-- Cache Structure & Configuration -----------------------------------------------------
-----------------------------------------------------------------------------------------

local Cache = {
    _data = {
        periodsFillingBySteps = nil,
        minEventYear = nil,
        maxEventYear = nil,
        librariesNames = nil,
        searchCache = {} -- Cache for search results with yearStart_yearEnd keys
    },
    _dirty = {
        periodsFillingBySteps = true,
        minEventYear = true,
        maxEventYear = true,
        librariesNames = true,
        searchCache = true
    }
}

-----------------------------------------------------------------------------------------
-- Core Cache Management Functions -----------------------------------------------------
-----------------------------------------------------------------------------------------

-- Invalidate specific cache type or all caches
function private.Core.Cache.invalidate(cacheType)
    if cacheType then
        Cache._dirty[cacheType] = true
        if cacheType == "searchCache" then
            Cache._data.searchCache = {}
        else
            Cache._data[cacheType] = nil
        end
        private.Core.Logger.trace("Cache", "Invalidated cache: " .. cacheType)
    else
        -- Invalidate all caches
        for key in pairs(Cache._dirty) do
            Cache._dirty[key] = true
        end
        Cache._data = {
            periodsFillingBySteps = nil,
            minEventYear = nil,
            maxEventYear = nil,
            librariesNames = nil,
            searchCache = {}
        }
        private.Core.Logger.trace("Cache", "Invalidated all caches")
    end
end

-- Check if cache entry is valid
function private.Core.Cache.isValid(cacheType, cacheKey)
    if cacheType == "searchCache" then
        return not Cache._dirty.searchCache and Cache._data.searchCache[cacheKey] ~= nil
    else
        return not Cache._dirty[cacheType] and Cache._data[cacheType] ~= nil
    end
end

-- Get cached value with automatic validation
function private.Core.Cache.get(cacheType, cacheKey)
    local isValid = private.Core.Cache.isValid(cacheType, cacheKey)

    if isValid then
        if cacheType == "searchCache" then
            return Cache._data.searchCache[cacheKey]
        else
            return Cache._data[cacheType]
        end
    else
        return nil
    end
end

-- Set cached value
function private.Core.Cache.set(cacheType, value, cacheKey)
    if cacheType == "searchCache" then
        Cache._data.searchCache[cacheKey] = value
        Cache._dirty.searchCache = false
    else
        Cache._data[cacheType] = value
        Cache._dirty[cacheType] = false
    end

    private.Core.Logger.trace("Cache", "Cached " .. cacheType .. (cacheKey and (" key: " .. cacheKey) or ""))
end

-----------------------------------------------------------------------------------------
-- High-Level Cache Interface Functions ------------------------------------------------
-----------------------------------------------------------------------------------------

-- Get cached periods with automatic rebuilding
function private.Core.Cache.getPeriodsFillingBySteps()
    local cached = private.Core.Cache.get("periodsFillingBySteps")
    if cached then
        return cached
    end

    private.Core.Logger.trace("Cache", "Rebuilding periods cache")
    local result = Chronicles.Data:GetPeriodsFillingBySteps()
    private.Core.Cache.set("periodsFillingBySteps", result)
    return result
end

-- Get cached min event year
function private.Core.Cache.getMinEventYear()
    local cached = private.Core.Cache.get("minEventYear")
    if cached then
        return cached
    end

    private.Core.Logger.trace("Cache", "Rebuilding min event year cache")
    local result = Chronicles.Data:MinEventYear()
    private.Core.Cache.set("minEventYear", result)
    return result
end

-- Get cached max event year
function private.Core.Cache.getMaxEventYear()
    local cached = private.Core.Cache.get("maxEventYear")
    if cached then
        return cached
    end

    private.Core.Logger.trace("Cache", "Rebuilding max event year cache")
    local result = Chronicles.Data:MaxEventYear()
    private.Core.Cache.set("maxEventYear", result)
    return result
end

-- Get cached libraries names
function private.Core.Cache.getLibrariesNames()
    local cached = private.Core.Cache.get("librariesNames")
    if cached then
        return cached
    end

    private.Core.Logger.trace("Cache", "Rebuilding libraries names cache")
    local result = Chronicles.Data:GetLibrariesNames()
    private.Core.Cache.set("librariesNames", result)
    return result
end

-- Get cached search results
function private.Core.Cache.getSearchEvents(yearStart, yearEnd)
    local cacheKey = yearStart .. "_" .. yearEnd
    local cached = private.Core.Cache.get("searchCache", cacheKey)
    if cached then
        return cached
    end

    private.Core.Logger.trace("Cache", "Caching search results for " .. cacheKey)
    local result = Chronicles.Data:SearchEvents(yearStart, yearEnd)
    private.Core.Cache.set("searchCache", result, cacheKey)
    return result
end

-----------------------------------------------------------------------------------------
-- Cache Management Utilities ----------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Pre-warm commonly used search caches for better performance
function private.Core.Cache.preWarmSearchCache()
    if not Cache._dirty.searchCache then
        return -- Cache is already warm
    end

    private.Core.Logger.trace("Cache", "Pre-warming search cache with common ranges")

    -- Pre-cache some common search ranges that are likely to be used frequently
    local commonRanges = {
        {private.constants.config.mythos, private.constants.config.historyStartYear - 1}, -- Mythos period
        {private.constants.config.currentYear + 1, private.constants.config.futur}, -- Future period
        {private.constants.config.historyStartYear, private.constants.config.currentYear}, -- Main history
        {-10000, 0}, -- Common ancient period
        {0, 50} -- Common modern period
    }

    for _, range in ipairs(commonRanges) do
        local yearStart, yearEnd = range[1], range[2]
        if yearStart <= yearEnd then
            private.Core.Cache.getSearchEvents(yearStart, yearEnd)
        end
    end
end

-- Warm all caches during low-activity periods
function private.Core.Cache.warmAllCaches()
    private.Core.Logger.trace("Cache", "Warming all caches")

    if Cache._dirty.periodsFillingBySteps then
        private.Core.Cache.getPeriodsFillingBySteps()
    end
    if Cache._dirty.minEventYear then
        private.Core.Cache.getMinEventYear()
    end
    if Cache._dirty.maxEventYear then
        private.Core.Cache.getMaxEventYear()
    end
    if Cache._dirty.librariesNames then
        private.Core.Cache.getLibrariesNames()
    end

    private.Core.Cache.preWarmSearchCache()
end

-- Clear all caches to free memory
function private.Core.Cache.clearAll()
    private.Core.Logger.trace("Cache", "Clearing all caches")
    private.Core.Cache.invalidate()
end

-- Force cache rebuild (useful for debugging or major data changes)
function private.Core.Cache.rebuildAll()
    private.Core.Logger.trace("Cache", "Force rebuilding all caches")
    private.Core.Cache.invalidate()
    private.Core.Cache.warmAllCaches()
end

-----------------------------------------------------------------------------------------
-- Initialization & Cleanup ------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Initialize cache system
function private.Core.Cache.init()
    private.Core.Logger.trace("Cache", "Initializing cache system")

    -- Initialize all caches as dirty
    private.Core.Cache.invalidate()

    -- Pre-warm after a short delay to avoid initialization conflicts
    C_Timer.After(
        1.0,
        function()
            private.Core.Cache.warmAllCaches()
        end
    )

    private.Core.Logger.trace("Cache", "Cache system initialized")
end

-- Cleanup cache system on shutdown
function private.Core.Cache.cleanup()
    private.Core.Logger.trace("Cache", "Cleaning up cache system")
    private.Core.Cache.clearAll()
end

-----------------------------------------------------------------------------------------
-- Backward Compatibility Bridge (for Chronicles.Data methods) -------------------------
-----------------------------------------------------------------------------------------

-- These functions provide backward compatibility for existing Data.lua cache methods
-- They will be removed once all references are updated to use private.Core.Cache directly

function private.Core.Cache.bridgeInvalidateCache(cacheType)
    return private.Core.Cache.invalidate(cacheType)
end

function private.Core.Cache.bridgeGetCachedPeriodsFillingBySteps()
    return private.Core.Cache.getPeriodsFillingBySteps()
end

function private.Core.Cache.bridgeGetCachedMinEventYear()
    return private.Core.Cache.getMinEventYear()
end

function private.Core.Cache.bridgeGetCachedMaxEventYear()
    return private.Core.Cache.getMaxEventYear()
end

function private.Core.Cache.bridgeGetCachedLibrariesNames()
    return private.Core.Cache.getLibrariesNames()
end

function private.Core.Cache.bridgeGetCachedSearchEvents(yearStart, yearEnd)
    return private.Core.Cache.getSearchEvents(yearStart, yearEnd)
end

function private.Core.Cache.bridgeWarmCache()
    return private.Core.Cache.warmAllCaches()
end

function private.Core.Cache.bridgeClearCache()
    return private.Core.Cache.clearAll()
end

function private.Core.Cache.bridgeRebuildCache()
    return private.Core.Cache.rebuildAll()
end

-----------------------------------------------------------------------------------------
-- Export Cache Interface ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Export the main cache interface
Chronicles.Cache = private.Core.Cache
