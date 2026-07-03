--[[
    Chronicles Data Module
      Main data management module for Chronicles addon.
    Handles database registration and integration with StateManager.
--]]
local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

Chronicles.Data = {}
Chronicles.Data.Events = {}
Chronicles.Data.Factions = {}
Chronicles.Data.Characters = {}
Chronicles.Data.RP = {}

local RPEventsDB = {}

function Chronicles.Data:Load()
    self:RegisterEventDB("RP", RPEventsDB)

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

function Chronicles.Data:RefreshPeriods()
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
end

-- -------------------------
-- Events Tools
-- -------------------------

function Chronicles.Data:AddRPEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(RPEventsDB) + 1
    end
    table.insert(RPEventsDB, event.id, self:CleanEventObject(event, "RP"))

    -- Invalidate caches since we added new event data
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MIN_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MAX_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)
end

-- function to retrieve the list of dates for all eventsGroup
function Chronicles.Data:GetPeriodsFillingBySteps()
    local periods = {
        mod1000 = {},
        mod500 = {},
        mod250 = {},
        mod100 = {},
        mod50 = {},
        mod10 = {}
        --mod1 = {}
    }
    for collectionName, eventsGroup in pairs(Chronicles.Data.Events) do
        if Chronicles.Data:GetCollectionStatus(collectionName) then
            if eventsGroup and eventsGroup.data then
                for _, event in pairs(eventsGroup.data) do
                    if (event ~= nil) then
                        local isActive = Chronicles.Data:GetEventTypeStatus(event.eventType)

                        if (isActive) then
                            for date = event.yearStart, event.yearEnd, 1 do
                                periods = Chronicles.Data:SetPeriodsForEvent(periods, date, event.id)
                            end
                        end
                    end
                end
            end
        end
    end

    return periods
end

function Chronicles.Data:SetPeriodsForEvent(periods, date, eventId)
    local profile = Chronicles.Data:ComputeEventDateProfile(date)

    periods.mod1000[profile.mod1000] = Chronicles.Data:DefinePeriodsForEvent(periods.mod1000[profile.mod1000], eventId)
    periods.mod500[profile.mod500] = Chronicles.Data:DefinePeriodsForEvent(periods.mod500[profile.mod500], eventId)
    periods.mod250[profile.mod250] = Chronicles.Data:DefinePeriodsForEvent(periods.mod250[profile.mod250], eventId)
    periods.mod100[profile.mod100] = Chronicles.Data:DefinePeriodsForEvent(periods.mod100[profile.mod100], eventId)
    periods.mod50[profile.mod50] = Chronicles.Data:DefinePeriodsForEvent(periods.mod50[profile.mod50], eventId)
    periods.mod10[profile.mod10] = Chronicles.Data:DefinePeriodsForEvent(periods.mod10[profile.mod10], eventId)
    --periods.mod1[profile.mod1] = Chronicles.Data:DefinePeriodsForEvent(periods.mod1[profile.mod1], eventId)

    return periods
end

function Chronicles.Data:DefinePeriodsForEvent(period, eventId)
    -- Use hash-set (table with eventId as key) for O(1) insertion and dedup
    -- instead of array + Set() conversion which is O(n) every time
    period = period or {}
    if not period[eventId] then
        period[eventId] = true
    end
    return period
end

function Chronicles.Data:ComputeEventDateProfile(date)
    return {
        mod1000 = math.floor(date / 1000),
        mod500 = math.floor(date / 500),
        mod250 = math.floor(date / 250),
        mod100 = math.floor(date / 100),
        mod50 = math.floor(date / 50),
        mod10 = math.floor(date / 10)
        --mod1 = date
    }
end

function Chronicles.Data:HasEvents(yearStart, yearEnd)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return false
    end
    return private.Core.Data.SearchEngine.hasEvents(yearStart, yearEnd)
end

function Chronicles.Data:HasEventsInDB(yearStart, yearEnd, db)
    return private.Core.Data.SearchEngine.hasEventsInDB(yearStart, yearEnd, db)
end

function Chronicles.Data:MinEventYear()
    local MinEventYear = 0

    for collectionName, eventsGroup in pairs(Chronicles.Data.Events) do
        local isActive = self:GetCollectionStatus(collectionName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = self:GetEventTypeStatus(event.eventType)

                if (isEventTypeActive and event.yearStart < MinEventYear) then
                    MinEventYear = event.yearStart
                end
            end
        end
    end
    return MinEventYear
end

function Chronicles.Data:MaxEventYear()
    local MaxEventYear = 0

    for collectionName, eventsGroup in pairs(Chronicles.Data.Events) do
        local isActive = self:GetCollectionStatus(collectionName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = self:GetEventTypeStatus(event.eventType)

                if (isEventTypeActive and event.yearEnd > MaxEventYear) then
                    MaxEventYear = event.yearEnd
                end
            end
        end
    end
    return MaxEventYear
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

Chronicles.Data.SearchEventsInDB               = createSearchEngineProxy("searchEventsInDB", {})
Chronicles.Data.IsInRange                      = createSearchEngineProxy("isEventInRange", false)
Chronicles.Data.CleanEventObject               = createSearchEngineProxy("cleanEventObject", nil)
Chronicles.Data.FindEventByIdAndCollection     = createSearchEngineProxy("findEventByIdAndCollection", nil)

Chronicles.Data.SearchFactions                 = createSearchEngineProxy("searchFactions", {})
Chronicles.Data.FindFactions                   = createSearchEngineProxy("findFactions", {})
Chronicles.Data.CleanFactionObject             = createSearchEngineProxy("cleanFactionObject", nil)
Chronicles.Data.FindFactionByIdAndCollection   = createSearchEngineProxy("findFactionByIdAndCollection", nil)

Chronicles.Data.SearchCharacters               = createSearchEngineProxy("searchCharacters", {})
Chronicles.Data.FindCharacters                 = createSearchEngineProxy("findCharacters", {})
Chronicles.Data.CleanCharacterObject           = createSearchEngineProxy("cleanCharacterObject", nil)
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

    if status == nil then
        private.Core.StateManager.setState(
            eventTypeKey,
            true,
            "Default status for new event type " .. tostring(eventTypeId)
        )
        return true
    end
    return status
end

function Chronicles.Data:AvailableDbId(db)
    local ids = {}

    for key, value in pairs(db) do
        if (value ~= nil) then
            table.insert(ids, value.id)
        end
    end

    table.sort(ids)

    local maxId = 1

    for key, value in ipairs(ids) do
        if (value > maxId + 1) then
            return maxId + 1
        end
        maxId = maxId + 1
    end

    return maxId
end

-- -------------------------
-- RP addons tools
-- -------------------------
function Chronicles.Data:LoadRolePlayProfile()
    if (RPEventsDB[0] ~= nil) then
        return
    end

    if (_G["TRP3_API"]) then
        local age = tonumber(Chronicles.Data.RP:TRP_GetAge())
        local name = Chronicles.Data.RP:TRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            Chronicles.Data.RP:RegisterBirth(age, name, "TotalRP")
        end
    end

    if (_G["mrp"]) then
        local age = tonumber(Chronicles.Data.RP:MRP_GetAge())
        local name = Chronicles.Data.RP:MRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            Chronicles.Data.RP:RegisterBirth(age, name, "MyRolePlay")
        end
    end
end

function Chronicles.Data.RP:RegisterBirth(age, name, addon)
    -- compare date with current year
    local birth = private.constants.config.currentYear - age
    local event = {
        id = 0,
        label = "Birth of " .. name,
        chapters = {
            {
                header = "Birth of " .. name,
                pages = {"Birth of " .. name .. "\n\nImported from " .. addon}
            }
        },
        yearStart = birth,
        yearEnd = birth,
        eventType = 5,
        order = 0
    }
    Chronicles.Data:AddRPEvent(event)
end

function Chronicles.Data.RP:MRP_GetRoleplayingName()
    return msp.my["NA"]
end

function Chronicles.Data.RP:MRP_GetAge()
    return msp.my["AG"]
end

function Chronicles.Data.RP:GetName()
    local name, realm = UnitName("player")
    return name
end

function Chronicles.Data.RP:TRP_GetCharacteristics()
    if not _G["TRP3_API"] or not TRP3_API.profile then
        return nil
    end
    local profileID = TRP3_API.profile.getPlayerCurrentProfileID()
    local profile = TRP3_API.profile.getProfileByID(profileID)
    if profile and profile.player and profile.player.characteristics then
        return profile.player.characteristics
    end
    return nil
end

function Chronicles.Data.RP:TRP_GetFirstName()
    local characteristics = Chronicles.Data.RP:TRP_GetCharacteristics()
    if characteristics ~= nil then
        return characteristics.FN
    end
end

function Chronicles.Data.RP:TRP_GetLastName()
    local characteristics = Chronicles.Data.RP:TRP_GetCharacteristics()
    if characteristics ~= nil then
        return characteristics.LN
    end
end

function Chronicles.Data.RP:TRP_GetRoleplayingName()
    local name = Chronicles.Data.RP:TRP_GetFirstName() or Chronicles.Data.RP:GetName()
    if Chronicles.Data.RP:TRP_GetLastName() then
        name = name .. " " .. Chronicles.Data.RP:TRP_GetLastName()
    end
    return name
end

function Chronicles.Data.RP:TRP_GetAge()
    local characteristics = Chronicles.Data.RP:TRP_GetCharacteristics()

    if characteristics ~= nil then
        return characteristics.AG
    end
end

-- -------------------------
