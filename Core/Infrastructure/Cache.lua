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
    FILTERED_CHARACTERS = "filteredCharacterResults", -- Cache for filtered character search results with search term keys
    BOOK_CONTENT = "bookContent" -- Cache for generated HTML book payloads keyed by entity signatures
}

-- Export cache keys for use by other modules immediately
private.Core.Cache.KEYS = CACHE_KEYS

-- -------------------------
-- Cache Structure & Configuration
-- -------------------------

local MAX_CACHE_ENTRIES = 100 -- Prevent unbounded cache growth

local Cache = {
    _data = {
        [CACHE_KEYS.PERIODS_FILLING] = nil,
        [CACHE_KEYS.MIN_EVENT_YEAR] = nil,
        [CACHE_KEYS.MAX_EVENT_YEAR] = nil,
        [CACHE_KEYS.COLLECTIONS_NAMES] = nil,
        [CACHE_KEYS.FILTERED_EVENTS] = {}, -- Cache for filtered event results with yearStart_yearEnd keys
        [CACHE_KEYS.ALL_CHARACTERS] = nil, -- Cache for all characters from all data sources
        [CACHE_KEYS.FILTERED_CHARACTERS] = {}, -- Cache for filtered character search results with search term keys
        [CACHE_KEYS.BOOK_CONTENT] = {} -- Cache for generated HTML book payloads keyed by entity signatures
    },
    _dirty = {
        [CACHE_KEYS.PERIODS_FILLING] = true,
        [CACHE_KEYS.MIN_EVENT_YEAR] = true,
        [CACHE_KEYS.MAX_EVENT_YEAR] = true,
        [CACHE_KEYS.COLLECTIONS_NAMES] = true,
        [CACHE_KEYS.FILTERED_EVENTS] = true,
        [CACHE_KEYS.ALL_CHARACTERS] = true,
        [CACHE_KEYS.FILTERED_CHARACTERS] = true,
        [CACHE_KEYS.BOOK_CONTENT] = true
    }
}

Cache._lastWarmError = nil

local WARM_TASK_INTERVAL_DEFAULT = 0.05
local warmQueue = {}
local warmTaskInterval = WARM_TASK_INTERVAL_DEFAULT
local isWarmQueueActive = false

local function processWarmQueue()
    if #warmQueue == 0 then
        isWarmQueueActive = false
        return
    end

    local task = table.remove(warmQueue, 1)
    local ok, err = pcall(task)
    if not ok then
        Cache._lastWarmError = err
        geterrorhandler()(err)
    end

    if #warmQueue > 0 then
        C_Timer.After(warmTaskInterval, processWarmQueue)
    else
        isWarmQueueActive = false
    end
end

local function enqueueWarmTasks(tasks, interval)
    if not tasks or #tasks == 0 then
        return
    end

    if not isWarmQueueActive then
        warmTaskInterval = interval or WARM_TASK_INTERVAL_DEFAULT
    end

    for _, task in ipairs(tasks) do
        warmQueue[#warmQueue + 1] = task
    end

    if not isWarmQueueActive then
        isWarmQueueActive = true
        processWarmQueue()
    end
end

local function buildWarmTaskList()
    local tasks = {}

    if Cache._dirty[CACHE_KEYS.PERIODS_FILLING] then
        table.insert(
            tasks,
            function()
                private.Core.Cache.getPeriodsFillingBySteps()
            end
        )
    end
    if Cache._dirty[CACHE_KEYS.MIN_EVENT_YEAR] then
        table.insert(
            tasks,
            function()
                private.Core.Cache.getMinEventYear()
            end
        )
    end
    if Cache._dirty[CACHE_KEYS.MAX_EVENT_YEAR] then
        table.insert(
            tasks,
            function()
                private.Core.Cache.getMaxEventYear()
            end
        )
    end
    if Cache._dirty[CACHE_KEYS.COLLECTIONS_NAMES] then
        table.insert(
            tasks,
            function()
                private.Core.Cache.getCollectionsNames()
            end
        )
    end
    if Cache._dirty[CACHE_KEYS.ALL_CHARACTERS] then
        table.insert(
            tasks,
            function()
                private.Core.Cache.getAllCharacters()
            end
        )
    end
    if Cache._dirty[CACHE_KEYS.BOOK_CONTENT] then
        table.insert(
            tasks,
            function()
                Cache._data[CACHE_KEYS.BOOK_CONTENT] = {}
                Cache._dirty[CACHE_KEYS.BOOK_CONTENT] = false
            end
        )
    end

    table.insert(
        tasks,
        function()
            private.Core.Cache.preWarmSearchCache()
        end
    )

    return tasks
end

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
        elseif cacheType == CACHE_KEYS.BOOK_CONTENT then
            Cache._data[CACHE_KEYS.BOOK_CONTENT] = {}
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
            [CACHE_KEYS.FILTERED_CHARACTERS] = {},
            [CACHE_KEYS.BOOK_CONTENT] = {}
        }
    end
end

-- The complete set of derived caches that each kind of data change makes stale.
-- COLLECTIONS_NAMES and BOOK_CONTENT are listed under all three kinds because
-- registering any collection adds a name, and any record can appear in a book.
local DATA_CHANGE_KEYS = {
    events = {
        CACHE_KEYS.PERIODS_FILLING,
        CACHE_KEYS.MIN_EVENT_YEAR,
        CACHE_KEYS.MAX_EVENT_YEAR,
        CACHE_KEYS.FILTERED_EVENTS,
        CACHE_KEYS.COLLECTIONS_NAMES,
        CACHE_KEYS.BOOK_CONTENT
    },
    characters = {
        CACHE_KEYS.ALL_CHARACTERS,
        CACHE_KEYS.FILTERED_CHARACTERS,
        CACHE_KEYS.COLLECTIONS_NAMES,
        CACHE_KEYS.BOOK_CONTENT
    },
    factions = {
        CACHE_KEYS.COLLECTIONS_NAMES,
        CACHE_KEYS.BOOK_CONTENT
    }
}

--[[
    Invalidate every cache derived from one kind of data change.

    This is the only supported way to invalidate after a mutation or a toggle:
    the character caches embed the active collection set at build time, so a
    call site that hand-picks keys leaves rails rendering disabled collections.

    @param kind [string] "events", "characters", "factions", or "all" for a
                         change that crosses all three (collection enable
                         /disable)
]]
function private.Core.Cache.invalidateForDataChange(kind)
    if kind == "all" then
        private.Core.Cache.invalidate()
        return
    end

    local keys = DATA_CHANGE_KEYS[kind]
    if not keys then
        error("Cache.invalidateForDataChange: unknown data change kind: " .. tostring(kind))
    end

    for _, cacheType in ipairs(keys) do
        private.Core.Cache.invalidate(cacheType)
    end
end

function private.Core.Cache.isValid(cacheType, cacheKey)
    if cacheType == CACHE_KEYS.FILTERED_EVENTS then
        return not Cache._dirty[CACHE_KEYS.FILTERED_EVENTS] and Cache._data[CACHE_KEYS.FILTERED_EVENTS][cacheKey] ~= nil
    elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
        return not Cache._dirty[CACHE_KEYS.FILTERED_CHARACTERS] and
            Cache._data[CACHE_KEYS.FILTERED_CHARACTERS][cacheKey] ~= nil
    elseif cacheType == CACHE_KEYS.BOOK_CONTENT then
        return not Cache._dirty[CACHE_KEYS.BOOK_CONTENT] and Cache._data[CACHE_KEYS.BOOK_CONTENT][cacheKey] ~= nil
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
        elseif cacheType == CACHE_KEYS.BOOK_CONTENT then
            return Cache._data[CACHE_KEYS.BOOK_CONTENT][cacheKey]
        else
            return Cache._data[cacheType]
        end
    else
        return nil
    end
end

function private.Core.Cache.set(cacheType, value, cacheKey)
    if cacheType == CACHE_KEYS.FILTERED_EVENTS then
        -- Enforce cache size limit to prevent unbounded growth
        local count = 0
        for _ in pairs(Cache._data[CACHE_KEYS.FILTERED_EVENTS]) do
            count = count + 1
        end
        if count >= MAX_CACHE_ENTRIES then
            -- Clear cache when limit exceeded (simple LRU alternative)
            Cache._data[CACHE_KEYS.FILTERED_EVENTS] = {}
        end
        Cache._data[CACHE_KEYS.FILTERED_EVENTS][cacheKey] = value
        Cache._dirty[CACHE_KEYS.FILTERED_EVENTS] = false
    elseif cacheType == CACHE_KEYS.FILTERED_CHARACTERS then
        -- Enforce cache size limit to prevent unbounded growth
        local count = 0
        for _ in pairs(Cache._data[CACHE_KEYS.FILTERED_CHARACTERS]) do
            count = count + 1
        end
        if count >= MAX_CACHE_ENTRIES then
            -- Clear cache when limit exceeded (simple LRU alternative)
            Cache._data[CACHE_KEYS.FILTERED_CHARACTERS] = {}
        end
        Cache._data[CACHE_KEYS.FILTERED_CHARACTERS][cacheKey] = value
        Cache._dirty[CACHE_KEYS.FILTERED_CHARACTERS] = false
    elseif cacheType == CACHE_KEYS.BOOK_CONTENT then
        Cache._data[CACHE_KEYS.BOOK_CONTENT][cacheKey] = value
        Cache._dirty[CACHE_KEYS.BOOK_CONTENT] = false
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
    if cached ~= nil then
        return cached
    end
    local result = Chronicles.Data:GetPeriodsFillingBySteps()
    private.Core.Cache.set(CACHE_KEYS.PERIODS_FILLING, result)
    return result
end

function private.Core.Cache.getMinEventYear()
    local cached = private.Core.Cache.get(CACHE_KEYS.MIN_EVENT_YEAR)
    if cached ~= nil then
        return cached
    end

    if not Chronicles or not Chronicles.Data or not Chronicles.Data.MinEventYear then
        return nil
    end

    local result = Chronicles.Data:MinEventYear()
    private.Core.Cache.set(CACHE_KEYS.MIN_EVENT_YEAR, result)
    return result
end

function private.Core.Cache.getMaxEventYear()
    local cached = private.Core.Cache.get(CACHE_KEYS.MAX_EVENT_YEAR)
    if cached ~= nil then
        return cached
    end

    if not Chronicles or not Chronicles.Data or not Chronicles.Data.MaxEventYear then
        return nil
    end

    local result = Chronicles.Data:MaxEventYear()
    private.Core.Cache.set(CACHE_KEYS.MAX_EVENT_YEAR, result)
    return result
end

function private.Core.Cache.getCollectionsNames()
    local cached = private.Core.Cache.get(CACHE_KEYS.COLLECTIONS_NAMES)
    if cached ~= nil then
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
    if cached ~= nil then
        return cached
    end

    local result = Chronicles.Data:SearchEvents(yearStart, yearEnd)
    private.Core.Cache.set(CACHE_KEYS.FILTERED_EVENTS, result, cacheKey)
    return result
end

function private.Core.Cache.getAllCharacters()
    local cached = private.Core.Cache.get(CACHE_KEYS.ALL_CHARACTERS)
    if cached ~= nil then
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
    if cached ~= nil then
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

function private.Core.Cache.warmAllCaches(options)
    options = options or {}
    local tasks = buildWarmTaskList()

    if #tasks == 0 then
        return
    end

    if options.async then
        Cache._lastWarmError = nil
        enqueueWarmTasks(tasks, options.interval)
    else
        for _, task in ipairs(tasks) do
            task()
        end
    end
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
            private.Core.Cache.warmAllCaches({async = true})
        end
    )
end

function private.Core.Cache.cleanup()
    private.Core.Cache.clearAll()
end

function private.Core.Cache.getBookContent(cacheKey)
    return private.Core.Cache.get(CACHE_KEYS.BOOK_CONTENT, cacheKey)
end

function private.Core.Cache.setBookContent(cacheKey, value)
    private.Core.Cache.set(CACHE_KEYS.BOOK_CONTENT, value, cacheKey)
end

-- -------------------------
-- Export Cache Interface
-- -------------------------

-- This publishes the *whole* module on the public facade, so every function above is reachable by
-- external addons even when nothing in Chronicles calls it. `cleanup`, `rebuildAll` and
-- `getSearchCharacters` currently have no internal callers for exactly that reason -- they are API,
-- not dead code. Removing one is a breaking change; check consumers before pruning here.
Chronicles.Cache = private.Core.Cache
