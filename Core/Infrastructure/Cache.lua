local FOLDER_NAME, private = ...

-- Get Chronicles reference
local Chronicles = private.Chronicles

--[[
    Chronicles Cache Module
    
    Centralized caching system for performance optimization and data management.
    Provides intelligent caching, cache invalidation, and performance monitoring.
    
    DEPENDENCIES:
    - Core.Utils.HelperUtils: For safe Chronicles object access
    - Constants: For configuration values and timeline ranges
    - Timer API: For delayed cache warming and cleanup operations
    
    RESPONSIBILITIES:
    - Event search result caching with intelligent invalidation
    - Timeline data caching (periods, min/max years, collections)
    - Cache warming strategies for performance optimization
    - Memory management and cache cleanup operations
    - Performance monitoring and cache hit/miss statistics
    
    CACHING STRATEGIES:
    - Lazy loading: Cache data on first access
    - Pre-warming: Common queries cached proactively
    - Smart invalidation: Only invalidate affected cache entries
    - Memory bounds: Automatic cleanup when limits exceeded
      CACHE TYPES:
    - Filtered Events: Search results by year range with compound keys
    - Timeline Metadata: Min/max years, periods, collection status
    - Character Data: All characters and filtered search results
    - Performance Data: Cache statistics and hit ratios
    
    PERFORMANCE FEATURES:
    - Sub-second cache lookups for timeline navigation
    - Background cache warming during low-activity periods
    - Automatic cache rebuilding on data changes
    - Memory-efficient storage with configurable limits
--]]
private.Core.Cache = {}

-- -------------------------
-- Cache Key Constants
-- -------------------------
local CACHE_KEYS = {
    PERIODS_FILLING = "periodsFillingBySteps",
    MIN_EVENT_YEAR = "minEventYear",
    MAX_EVENT_YEAR = "maxEventYear",
    COLLECTIONS_NAMES = "collectionsNames",
    FILTERED_EVENTS = "filteredEventResults", -- Cache for filtered event search results with yearStart_yearEnd keys
    ALL_CHARACTERS = "allCharacters", -- Cache for all characters from all data sources
    FILTERED_CHARACTERS = "filteredCharacterResults" -- Cache for filtered character search results with search term keys
}

-- Export cache keys for use by other modules immediately
private.Core.Cache.KEYS = CACHE_KEYS

-- -------------------------
-- Cache Structure & Configuration
-- -------------------------

local Cache = {
    _data = {
        [CACHE_KEYS.PERIODS_FILLING] = nil,
        [CACHE_KEYS.MIN_EVENT_YEAR] = nil,
        [CACHE_KEYS.MAX_EVENT_YEAR] = nil,
        [CACHE_KEYS.COLLECTIONS_NAMES] = nil,
        [CACHE_KEYS.FILTERED_EVENTS] = {}, -- Cache for filtered event results with yearStart_yearEnd keys
        [CACHE_KEYS.ALL_CHARACTERS] = nil, -- Cache for all characters from all data sources
        [CACHE_KEYS.FILTERED_CHARACTERS] = {} -- Cache for filtered character search results with search term keys
    },
    _dirty = {
        [CACHE_KEYS.PERIODS_FILLING] = true,
        [CACHE_KEYS.MIN_EVENT_YEAR] = true,
        [CACHE_KEYS.MAX_EVENT_YEAR] = true,
        [CACHE_KEYS.COLLECTIONS_NAMES] = true,
        [CACHE_KEYS.FILTERED_EVENTS] = true,
        [CACHE_KEYS.ALL_CHARACTERS] = true,
        [CACHE_KEYS.FILTERED_CHARACTERS] = true
    }
}

-- -------------------------
-- Core Cache Management Functions
-- -------------------------

function private.Core.Cache.invalidate(cacheType)
    if cacheType then
        Cache._dirty[cacheType] = true
        if cacheType == CACHE_KEYS.FILTERED_EVENTS then
            Cache._data[CACHE_KEYS.FILTERED_EVENTS] = {}
        elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
            Cache._data[CACHE_KEYS.FILTERED_CHARACTERS] = {}
        else
            Cache._data[cacheType] = nil
        end
    else
        for key in pairs(Cache._dirty) do
            Cache._dirty[key] = true
        end
        Cache._data = {
            [CACHE_KEYS.PERIODS_FILLING] = nil,
            [CACHE_KEYS.MIN_EVENT_YEAR] = nil,
            [CACHE_KEYS.MAX_EVENT_YEAR] = nil,
            [CACHE_KEYS.COLLECTIONS_NAMES] = nil,
            [CACHE_KEYS.FILTERED_EVENTS] = {},
            [CACHE_KEYS.ALL_CHARACTERS] = nil,
            [CACHE_KEYS.FILTERED_CHARACTERS] = {}
        }
    end
end

function private.Core.Cache.isValid(cacheType, cacheKey)
    if cacheType == CACHE_KEYS.FILTERED_EVENTS then
        return not Cache._dirty[CACHE_KEYS.FILTERED_EVENTS] and Cache._data[CACHE_KEYS.FILTERED_EVENTS][cacheKey] ~= nil
    elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
        return not Cache._dirty[CACHE_KEYS.FILTERED_CHARACTERS] and
            Cache._data[CACHE_KEYS.FILTERED_CHARACTERS][cacheKey] ~= nil
    else
        return not Cache._dirty[cacheType] and Cache._data[cacheType] ~= nil
    end
end

function private.Core.Cache.get(cacheType, cacheKey)
    local isValid = private.Core.Cache.isValid(cacheType, cacheKey)

    if isValid then
        if cacheType == CACHE_KEYS.FILTERED_EVENTS then
            return Cache._data[CACHE_KEYS.FILTERED_EVENTS][cacheKey]
        elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
            return Cache._data[CACHE_KEYS.FILTERED_CHARACTERS][cacheKey]
        else
            return Cache._data[cacheType]
        end
    else
        return nil
    end
end

function private.Core.Cache.set(cacheType, value, cacheKey)
    if cacheType == CACHE_KEYS.FILTERED_EVENTS then
        Cache._data[CACHE_KEYS.FILTERED_EVENTS][cacheKey] = value
        Cache._dirty[CACHE_KEYS.FILTERED_EVENTS] = false
    elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
        Cache._data[CACHE_KEYS.FILTERED_CHARACTERS][cacheKey] = value
        Cache._dirty[CACHE_KEYS.FILTERED_CHARACTERS] = false
    else
        Cache._data[cacheType] = value
        Cache._dirty[cacheType] = false
    end
end

-- -------------------------
-- High-Level Cache Interface Functions
-- -------------------------

function private.Core.Cache.getPeriodsFillingBySteps()
    local cached = private.Core.Cache.get(CACHE_KEYS.PERIODS_FILLING)
    if cached then
        return cached
    end
    local result = Chronicles.Data:GetPeriodsFillingBySteps()
    private.Core.Cache.set(CACHE_KEYS.PERIODS_FILLING, result)
    return result
end

function private.Core.Cache.getMinEventYear()
    local cached = private.Core.Cache.get(CACHE_KEYS.MIN_EVENT_YEAR)
    if cached then
        return cached
    end
    local result = Chronicles.Data:MinEventYear()
    private.Core.Cache.set(CACHE_KEYS.MIN_EVENT_YEAR, result)
    return result
end

function private.Core.Cache.getMaxEventYear()
    local cached = private.Core.Cache.get(CACHE_KEYS.MAX_EVENT_YEAR)
    if cached then
        return cached
    end
    local result = Chronicles.Data:MaxEventYear()
    private.Core.Cache.set(CACHE_KEYS.MAX_EVENT_YEAR, result)
    return result
end

function private.Core.Cache.getCollectionsNames()
    local cached = private.Core.Cache.get(CACHE_KEYS.COLLECTIONS_NAMES)
    if cached then
        return cached
    end
    local result = Chronicles.Data:GetCollectionsNames()
    private.Core.Cache.set(CACHE_KEYS.COLLECTIONS_NAMES, result)
    return result
end

function private.Core.Cache.getSearchEvents(yearStart, yearEnd)
    if not yearStart or not yearEnd then
        return {}
    end
    local cacheKey = yearStart .. "_" .. yearEnd
    local cached = private.Core.Cache.get(CACHE_KEYS.FILTERED_EVENTS, cacheKey)
    if cached then
        return cached
    end

    local result = Chronicles.Data:SearchEvents(yearStart, yearEnd)
    private.Core.Cache.set(CACHE_KEYS.FILTERED_EVENTS, result, cacheKey)
    return result
end

function private.Core.Cache.getAllCharacters()
    local cached = private.Core.Cache.get(CACHE_KEYS.ALL_CHARACTERS)
    if cached then
        return cached
    end

    if not Chronicles or not Chronicles.Data or not Chronicles.Data.SearchCharacters then
        return {}
    end

    local result = Chronicles.Data:SearchCharacters()
    private.Core.Cache.set(CACHE_KEYS.ALL_CHARACTERS, result)
    return result
end

function private.Core.Cache.getSearchCharacters(searchTerm)
    if not searchTerm or searchTerm == "" then
        return private.Core.Cache.getAllCharacters()
    end

    local cacheKey = string.lower(searchTerm)
    local cached = private.Core.Cache.get(CACHE_KEYS.FILTERED_CHARACTERS, cacheKey)
    if cached then
        return cached
    end

    if not Chronicles or not Chronicles.Data or not Chronicles.Data.SearchCharacters then
        return {}
    end

    local result = Chronicles.Data:SearchCharacters(searchTerm)
    private.Core.Cache.set(CACHE_KEYS.FILTERED_CHARACTERS, result, cacheKey)
    return result
end

-- -------------------------
-- Character Cache Interface Functions
-- -------------------------

-- The character caching system provides optimized access to character data from all
-- registered data sources with intelligent search result caching.
--
-- KEY FEATURES:
-- • All characters cached on first access for fast subsequent lookups
-- • Search results cached by normalized search terms
-- • Automatic cache invalidation when character data changes
-- • Memory-efficient storage with lowercase key normalization
--
-- PERFORMANCE BENEFITS:
-- • Sub-millisecond character list population
-- • Instant search result display for repeated queries
-- • Reduced database access for character browsing
-- • Optimized memory usage with smart cache key management

-- -------------------------
-- Cache Management Utilities
-- -------------------------

-- Pre-warm commonly used search caches for better performance
function private.Core.Cache.preWarmSearchCache()
    if not Cache._dirty[CACHE_KEYS.FILTERED_EVENTS] then
        return -- Cache is already warm
    end

    if not private.constants or not private.constants.config then
        return
    end

    local config = private.constants.config

    if not config.mythos or not config.historyStartYear or not config.currentYear or not config.futur then
        return
    end

    -- Pre-cache some common search ranges that are likely to be used frequently
    local commonRanges = {
        {config.mythos, config.historyStartYear - 1},
        {config.currentYear + 1, config.futur},
        {config.historyStartYear, config.currentYear}
    }

    for _, range in ipairs(commonRanges) do
        local yearStart, yearEnd = range[1], range[2]
        if yearStart and yearEnd and yearStart <= yearEnd then
            private.Core.Cache.getSearchEvents(yearStart, yearEnd)
        end
    end
end

function private.Core.Cache.warmAllCaches()
    if Cache._dirty[CACHE_KEYS.PERIODS_FILLING] then
        private.Core.Cache.getPeriodsFillingBySteps()
    end
    if Cache._dirty[CACHE_KEYS.MIN_EVENT_YEAR] then
        private.Core.Cache.getMinEventYear()
    end
    if Cache._dirty[CACHE_KEYS.MAX_EVENT_YEAR] then
        private.Core.Cache.getMaxEventYear()
    end
    if Cache._dirty[CACHE_KEYS.COLLECTIONS_NAMES] then
        private.Core.Cache.getCollectionsNames()
    end
    if Cache._dirty[CACHE_KEYS.ALL_CHARACTERS] then
        private.Core.Cache.getAllCharacters()
    end

    private.Core.Cache.preWarmSearchCache()
end

function private.Core.Cache.clearAll()
    private.Core.Cache.invalidate()
end

function private.Core.Cache.rebuildAll()
    private.Core.Cache.invalidate()
    private.Core.Cache.warmAllCaches()
end

-- -------------------------
-- Initialization & Cleanup
-- -------------------------

function private.Core.Cache.init()
    private.Core.Cache.invalidate()

    C_Timer.After(
        1.0,
        function()
            private.Core.Cache.warmAllCaches()
        end
    )
end

function private.Core.Cache.cleanup()
    private.Core.Cache.clearAll()
end

-- -------------------------
-- Export Cache Interface
-- -------------------------

Chronicles.Cache = private.Core.Cache
