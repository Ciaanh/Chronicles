--[[
    Chronicles Data Module
      Main data management module for Chronicles addon.
    Handles database registration and integration with StateManager.
--]]
local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

-- Initialize Core.Utils namespace if it doesn't exist
private.Core = private.Core or {}
private.Core.Utils = private.Core.Utils or {}

Chronicles.Data = {}
Chronicles.Data.Events = {}
Chronicles.Data.Factions = {}
Chronicles.Data.Characters = {}

-- One bucket family per entry of private.constants.config.stepValues; a family
-- with no matching step value would be built and held for nothing.
local PERIOD_BUCKETS = {
    {key = "mod1000", step = 1000},
    {key = "mod500", step = 500},
    {key = "mod100", step = 100},
    {key = "mod10", step = 10}
}

local function initializePeriodBuckets()
    local buckets = {}
    for _, bucket in ipairs(PERIOD_BUCKETS) do
        buckets[bucket.key] = {}
    end
    return buckets
end

local function addEventToBucketRange(bucketTable, startIndex, endIndex, eventId)
    for index = startIndex, endIndex do
        local bucket = bucketTable[index]
        if not bucket then
            bucket = {}
            bucketTable[index] = bucket
        end
        bucket[#bucket + 1] = eventId
    end
end

--[[
    Give every configured event type a persisted status on first run.

    Seeding up front is what lets GetEventTypeStatus stay a pure read: it runs
    once per event inside the timeline scans, which repeat on every rebuild.
]]
local function seedEventTypeDefaults()
    if not private.Core.StateManager or not private.constants or not private.constants.eventType then
        return
    end

    for eventTypeId in pairs(private.constants.eventType) do
        local eventTypeKey = private.Core.StateManager.buildSettingsKey("eventType", eventTypeId)
        if private.Core.StateManager.getState(eventTypeKey) == nil then
            private.Core.StateManager.setState(
                eventTypeKey,
                true,
                "Default status for event type " .. tostring(eventTypeId)
            )
        end
    end
end

function Chronicles.Data:Load()
    seedEventTypeDefaults()

    -- Load internal bundled databases (Sample DBs from DB/ folder)
    if private.registerInternalDBs then
        private.registerInternalDBs()
    end

    -- Process any external plugin manifests already populated before Chronicles loaded
    self:LoadPluginManifests()

    -- Listen for other addons loading after us — re-scan manifests for late arrivals
    -- ADDON_LOADED fires for every addon, but LoadPluginManifests skips already-processed plugins
    Chronicles:RegisterEvent("ADDON_LOADED", function()
        if Chronicles.Data:LoadPluginManifests() then
            private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:ADDON_LOADED manifest scan")
        end
    end)

    -- Once all addons are loaded, stop listening — LoD addons are unlikely to be Chronicles plugins
    Chronicles:RegisterEvent("PLAYER_LOGIN", function()
        Chronicles:UnregisterEvent("ADDON_LOADED")
        Chronicles:UnregisterEvent("PLAYER_LOGIN")
    end)

    -- Initialize the cache system
    private.Core.Cache.init()
end

--[[
    Process external plugin manifests from the ChroniclesPlugins global table.

    External plugins populate this table during their file load phase:
        ChroniclesPlugins = ChroniclesPlugins or {}
        ChroniclesPlugins["MyPlugin"] = {
            events     = myEventsDB,       -- optional
            characters = myCharactersDB,   -- optional
            factions   = myFactionsDB,     -- optional
        }

    This function is safe to call multiple times — already-processed plugin names
    are tracked and skipped on subsequent calls.

    @return [boolean] true if any new plugin data was registered
]]
local processedPlugins = {}

function Chronicles.Data:LoadPluginManifests()
    if not _G.ChroniclesPlugins then return false end

    local registered = false
    for pluginName, manifest in pairs(_G.ChroniclesPlugins) do
        if type(pluginName) == "string" and not processedPlugins[pluginName] and type(manifest) == "table" then
            local hasNameConflict = (self.Events[pluginName] ~= nil) or (self.Factions[pluginName] ~= nil) or
                (self.Characters[pluginName] ~= nil)
            if hasNameConflict then
                print(
                    "|cffff9900Warning:|r Chronicles plugin manifest skipped due to duplicate collection name: " ..
                    tostring(pluginName)
                )
                processedPlugins[pluginName] = true
            else
                processedPlugins[pluginName] = true
                if manifest.events and self:RegisterEventDB(pluginName, manifest.events) then
                    registered = true
                end
                if manifest.characters and self:RegisterCharacterDB(pluginName, manifest.characters) then
                    registered = true
                end
                if manifest.factions and self:RegisterFactionDB(pluginName, manifest.factions) then
                    registered = true
                end
            end
        end
    end
    return registered
end

-- -------------------------
-- Events Tools
-- -------------------------

-- function to retrieve the list of dates for all eventsGroup
function Chronicles.Data:GetPeriodsFillingBySteps()
    local periods = initializePeriodBuckets()
    for collectionName, eventsGroup in pairs(Chronicles.Data.Events) do
        if Chronicles.Data:GetCollectionStatus(collectionName) then
            if eventsGroup and eventsGroup.data then
                for _, event in pairs(eventsGroup.data) do
                    if (event ~= nil) then
                        local isActive = Chronicles.Data:GetEventTypeStatus(event.eventType)

                        if (isActive) then
                            local yearStart = tonumber(event.yearStart)
                            local yearEnd = tonumber(event.yearEnd)

                            if yearStart and yearEnd then
                                if yearStart > yearEnd then
                                    yearStart, yearEnd = yearEnd, yearStart
                                end

                                for _, bucket in ipairs(PERIOD_BUCKETS) do
                                    local bucketTable = periods[bucket.key]
                                    local startIndex = math.floor(yearStart / bucket.step)
                                    local endIndex = math.floor(yearEnd / bucket.step)

                                    if endIndex >= startIndex then
                                        addEventToBucketRange(bucketTable, startIndex, endIndex, event.id)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return periods
end

function Chronicles.Data:ComputeEventDateProfile(date)
    local profile = {}
    for _, bucket in ipairs(PERIOD_BUCKETS) do
        profile[bucket.key] = math.floor(date / bucket.step)
    end
    return profile
end

--[[
    Scan every enabled collection for the earliest and latest event year.

    Both bounds are seeded from the first matching event rather than from 0, so
    a dataset lying entirely on one side of year 0 is not padded back to it.

    @return [number|nil, number|nil] Earliest and latest year, both nil when no
                                     enabled event matched
]]
local function computeEventYearBounds()
    local minYear, maxYear

    for collectionName, eventsGroup in pairs(Chronicles.Data.Events) do
        if Chronicles.Data:GetCollectionStatus(collectionName) and eventsGroup and eventsGroup.data then
            for _, event in pairs(eventsGroup.data) do
                if event and Chronicles.Data:GetEventTypeStatus(event.eventType) then
                    local yearStart = tonumber(event.yearStart)
                    local yearEnd = tonumber(event.yearEnd)

                    if yearStart and (minYear == nil or yearStart < minYear) then
                        minYear = yearStart
                    end

                    if yearEnd and (maxYear == nil or yearEnd > maxYear) then
                        maxYear = yearEnd
                    end
                end
            end
        end
    end

    return minYear, maxYear
end

function Chronicles.Data:MinEventYear()
    local minYear = computeEventYearBounds()
    return minYear
end

function Chronicles.Data:MaxEventYear()
    local _, maxYear = computeEventYearBounds()
    return maxYear
end

-- -------------------------
-- Proxy Generator Pattern
-- -------------------------
-- Eliminates repetitive guard-and-delegate boilerplate

local function createSearchEngineProxy(method, default)
    return function(self, ...)
        if not private.Core.Data or not private.Core.Data.SearchEngine then
            return default
        end
        return private.Core.Data.SearchEngine[method](...)
    end
end

local function createDataRegistryProxy(method, default)
    return function(self, ...)
        if not private.Core.Data or not private.Core.Data.DataRegistry then
            return default
        end
        return private.Core.Data.DataRegistry[method](...)
    end
end

-- -------------------------
-- Search Events (with special handling for default year range)
-- -------------------------

function Chronicles.Data:SearchEvents(yearStart, yearEnd)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return {}
    end

    if not yearStart or not yearEnd then
        if private.constants and private.constants.config then
            yearStart = private.constants.config.mythos
            yearEnd = private.constants.config.futur
        else
            return {}
        end
    end

    return private.Core.Data.SearchEngine.searchEvents(yearStart, yearEnd)
end

-- -------------------------
-- Search Engine Proxies
-- -------------------------

Chronicles.Data.FindEventByIdAndCollection     = createSearchEngineProxy("findEventByIdAndCollection", nil)

Chronicles.Data.SearchFactions                 = createSearchEngineProxy("searchFactions", {})
Chronicles.Data.FindFactionByIdAndCollection   = createSearchEngineProxy("findFactionByIdAndCollection", nil)

Chronicles.Data.SearchCharacters               = createSearchEngineProxy("searchCharacters", {})
Chronicles.Data.FindCharacterByIdAndCollection = createSearchEngineProxy("findCharacterByIdAndCollection", nil)

-- -------------------------
-- Data Registry Proxies
-- -------------------------

Chronicles.Data.RegisterEventDB      = createDataRegistryProxy("registerEventDB", false)
Chronicles.Data.RegisterCharacterDB  = createDataRegistryProxy("registerCharacterDB", false)
Chronicles.Data.RegisterFactionDB    = createDataRegistryProxy("registerFactionDB", false)
Chronicles.Data.GetCollectionsNames  = createDataRegistryProxy("getCollectionsNames", {})
Chronicles.Data.GetCollectionStatus  = createDataRegistryProxy("getCollectionStatus", false)

function Chronicles.Data:GetEventTypeStatus(eventTypeId)
    if not private.Core.StateManager then
        return true
    end

    if not eventTypeId then
        return true
    end

    local eventTypeKey = private.Core.StateManager.buildSettingsKey("eventType", eventTypeId)
    local status = private.Core.StateManager.getState(eventTypeKey)

    -- An id outside constants.eventType has no setting and no checkbox to
    -- toggle it, so it is treated as enabled.
    if status == nil then
        return true
    end
    return status
end

