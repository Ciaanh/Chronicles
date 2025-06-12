--[[
    Chronicles Data Module
    
    Main data management module for Chronicles addon.
    Handles database registration, MyJournal operations, and integration with StateManager.
--]]
local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- Constants
local MIN_CHARACTER_SEARCH = 3

Chronicles.Data = {}
Chronicles.Data.Events = {}
Chronicles.Data.Factions = {}
Chronicles.Data.Characters = {}
Chronicles.Data.RP = {}

RPEventsDB = {}

function Chronicles.Data:Load()
    self:RegisterEventDB("RP", RPEventsDB)

    -- load data for my journal
    self:RegisterEventDB("myjournal", Chronicles.Data:GetMyJournalEvents())
    self:RegisterFactionDB("myjournal", Chronicles.Data:GetMyJournalFactions())
    self:RegisterCharacterDB("myjournal", Chronicles.Data:GetMyJournalCharacters())
    if (Chronicles.DB ~= nil) then
        Chronicles.DB:Init()
    end

    -- Initialize the cache system
    private.Core.Cache.init()
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
    if period ~= nil then
        local items = Set(period)
        if items[eventId] ~= nil then
        else
            table.insert(period, eventId)
        end

        return period
    else
        local data = {}
        table.insert(data, eventId)

        return data
    end
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
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to check for events")
        return false
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.hasEvents(yearStart, yearEnd)
end

function Chronicles.Data:HasEventsInDB(yearStart, yearEnd, db)
    -- Delegate to SearchEngine
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

-- Search events ------------------------------------------------------------------------

function Chronicles.Data:SearchEvents(yearStart, yearEnd)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to search events")
        return {}
    end

    -- If no parameters provided, search entire range
    if not yearStart or not yearEnd then
        if private.constants and private.constants.config then
            yearStart = private.constants.config.mythos
            yearEnd = private.constants.config.futur
        else
            private.Core.Logger.warn("Data", "SearchEvents called without parameters and constants not available")
            return {}
        end
    end

    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.searchEvents(yearStart, yearEnd)
end

function Chronicles.Data:SearchEventsInDB(yearStart, yearEnd, db)
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.searchEventsInDB(yearStart, yearEnd, db)
end

function Chronicles.Data:IsInRange(event, yearStart, yearEnd)
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.isEventInRange(event, yearStart, yearEnd)
end

function Chronicles.Data:CleanEventObject(event, collectionName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean event object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanEventObject(event, collectionName)
end

-- Search factions ----------------------------------------------------------------------

function Chronicles.Data:SearchFactions(name)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to search factions")
        return {}
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.searchFactions(name)
end

function Chronicles.Data:FindFactions(ids)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to find factions")
        return {}
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.findFactions(ids)
end

function Chronicles.Data:CleanFactionObject(faction, collectionName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean faction object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanFactionObject(faction, collectionName)
end

-- Search characters --------------------------------------------------------------------

function Chronicles.Data:SearchCharacters(name)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to search characters")
        return {}
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.searchCharacters(name)
end

function Chronicles.Data:FindCharacters(ids)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to find characters")
        return {}
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.findCharacters(ids)
end

function Chronicles.Data:CleanCharacterObject(character, collectionName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean character object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanCharacterObject(character, collectionName)
end

-- -------------------------
-- External DB tools
-- -------------------------
function Chronicles.Data:RegisterEventDB(collectionName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. collectionName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerEventDB(collectionName, db)
end

function Chronicles.Data:RegisterCharacterDB(collectionName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. collectionName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerCharacterDB(collectionName, db)
end

function Chronicles.Data:RegisterFactionDB(collectionName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. collectionName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerFactionDB(collectionName, db)
end

function Chronicles.Data:GetCollectionsNames()
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to get collections names")
        return {}
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.getCollectionsNames()
end

function Chronicles.Data:GetCollectionStatus(collectionName)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to get collection status")
        return false
    end

    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.getCollectionStatus(collectionName)
end

function Chronicles.Data:GetEventTypeStatus(eventTypeId)
    -- Ensure StateManager is available
    if not private.Core.StateManager then
        private.Core.Logger.error("Data", "StateManager not available when trying to get event type status")
        return true -- Default to active
    end

    -- Validate eventTypeId before using it
    if not eventTypeId then
        private.Core.Logger.warn("Data", "GetEventTypeStatus called with nil eventTypeId")
        return true -- Default to active
    end

    -- Use the proper key builder instead of direct concatenation
    local eventTypeKey = private.Core.StateManager.buildSettingsKey("eventType", eventTypeId)
    local status = private.Core.StateManager.getState(eventTypeKey)

    -- If status is nil after state is loaded, it means this is a new event type
    -- Set default to true for new event types only
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

-- -------------------------

function Chronicles.Data:GetMyJournalEvents()
    -- Ensure StateManager is available
    if not private.Core.StateManager then
        private.Core.Logger.error("Data", "StateManager not available when trying to get MyJournal events")
        return {}
    end -- Delegate to StateManager
    local userContentDataKey = private.Core.StateManager.buildUserContentDataKey("events", "byId")
    local newData = private.Core.StateManager.getState(userContentDataKey)
    if newData and next(newData) then
        local result = {}
        for id, event in pairs(newData) do
            table.insert(result, event)
        end
        return result
    end
    return {}
end

function Chronicles.Data:SetMyJournalEvents(event)
    -- Ensure StateManager is available
    if not private.Core.StateManager then
        private.Core.Logger.error("Data", "StateManager not available when trying to set MyJournal event")
        return
    end -- Set source and ensure ID is assigned
    event.source = "myjournal"
    if (event.id == nil) then
        local userContentDataKey = private.Core.StateManager.buildUserContentDataKey("events", "byId")
        local newData = private.Core.StateManager.getState(userContentDataKey)
        local currentEvents = {}
        if newData and next(newData) then
            for id, evt in pairs(newData) do
                table.insert(currentEvents, evt)
            end
        end
        event.id = Chronicles.Data:AvailableDbId(currentEvents)
    end

    -- Add through StateManager
    local userContentKey = private.Core.StateManager.buildUserContentKey("events")
    local currentData = private.Core.StateManager.getState(userContentKey)
    if currentData and currentData.byId and event and event.id then
        currentData.byId[event.id] = event
        currentData.metadata.count = currentData.metadata.count + 1
        currentData.metadata.lastModified = GetServerTime()

        local startYear = event.yearStart or 0
        local eventType = event.eventType or 1

        if not currentData.index.byYear[startYear] then
            currentData.index.byYear[startYear] = {}
        end
        if not private.Core.Utils.TableUtils.containsValue(currentData.index.byYear[startYear], event.id) then
            table.insert(currentData.index.byYear[startYear], event.id)
        end

        if not currentData.index.byType[eventType] then
            currentData.index.byType[eventType] = {}
        end
        if not private.Core.Utils.TableUtils.containsValue(currentData.index.byType[eventType], event.id) then
            table.insert(currentData.index.byType[eventType], event.id)
        end

        private.Core.StateManager.setState(
            userContentKey,
            currentData,
            "Added MyJournal event: " .. (event.label or event.id)
        )
    end -- Invalidate caches since we added new event data
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MIN_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MAX_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)
end

function Chronicles.Data:RemoveMyJournalEvent(eventId)
    -- Remove through StateManager
    local userContentKey = private.Core.StateManager.buildUserContentKey("events")
    local currentData = private.Core.StateManager.getState(userContentKey)
    if currentData and currentData.byId and eventId then
        currentData.byId[eventId] = nil
        currentData.metadata.count = math.max(0, currentData.metadata.count - 1)
        currentData.metadata.lastModified = GetServerTime()

        -- Remove from indexes
        for year, eventIds in pairs(currentData.index.byYear or {}) do
            for i, id in ipairs(eventIds) do
                if id == eventId then
                    table.remove(eventIds, i)
                    break
                end
            end
        end

        for eventType, eventIds in pairs(currentData.index.byType or {}) do
            for i, id in ipairs(eventIds) do
                if id == eventId then
                    table.remove(eventIds, i)
                    break
                end
            end
        end
        private.Core.StateManager.setState(
            userContentKey,
            currentData,
            "Removed MyJournal event: " .. eventId
        ) -- Invalidate caches
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.MIN_EVENT_YEAR)
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.MAX_EVENT_YEAR)
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)
    end
end

function Chronicles.Data:GetMyJournalFactions()
    -- Use StateManager directly for clean implementation
    local newData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentDataKey("factions", "byId"))
    if newData and next(newData) then
        local result = {}
        for id, faction in pairs(newData) do
            table.insert(result, faction)
        end
        return result
    end
    return {}
end

function Chronicles.Data:SetMyJournalFactions(faction)
    -- Set source and ensure ID is assigned
    faction.source = "myjournal"
    if (faction.id == nil) then
        local currentFactions = Chronicles.Data:GetMyJournalFactions()
        faction.id = Chronicles.Data:AvailableDbId(currentFactions)
    end    -- Add through StateManager
    local currentData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentKey("factions"))
    if currentData and currentData.byId and faction and faction.id then
        currentData.byId[faction.id] = faction
        currentData.metadata.count = currentData.metadata.count + 1
        currentData.metadata.lastModified = GetServerTime()

        local startYear = faction.yearStart or 0

        if not currentData.index.byYear[startYear] then
            currentData.index.byYear[startYear] = {}
        end
        if not private.Core.Utils.TableUtils.containsValue(currentData.index.byYear[startYear], faction.id) then
            table.insert(currentData.index.byYear[startYear], faction.id)
        end        private.Core.StateManager.setState(
            private.Core.StateManager.buildUserContentKey("factions"),
            currentData,
            "Added MyJournal faction: " .. (faction.label or faction.id)
        )
    end
end

function Chronicles.Data:RemoveMyJournalFaction(factionId)
    -- Remove through StateManager
    local currentData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentKey("factions"))
    if currentData and currentData.byId and factionId then
        currentData.byId[factionId] = nil
        currentData.metadata.count = math.max(0, currentData.metadata.count - 1)
        currentData.metadata.lastModified = GetServerTime()

        -- Remove from indexes
        for year, factionIds in pairs(currentData.index.byYear or {}) do
            for i, id in ipairs(factionIds) do
                if id == factionId then
                    table.remove(factionIds, i)
                    break
                end
            end
        end        private.Core.StateManager.setState(
            private.Core.StateManager.buildUserContentKey("factions"),
            currentData,
            "Removed MyJournal faction: " .. factionId
        )
    end
end

function Chronicles.Data:GetMyJournalCharacters()
    -- Use StateManager directly for clean implementation
    local newData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentDataKey("characters", "byId"))
    if newData and next(newData) then
        local result = {}
        for id, character in pairs(newData) do
            table.insert(result, character)
        end
        return result
    end
    return {}
end

function Chronicles.Data:SetMyJournalCharacters(character)
    -- Set source and ensure ID is assigned
    character.source = "myjournal"
    if (character.id == nil) then
        local currentCharacters = Chronicles.Data:GetMyJournalCharacters()
        character.id = Chronicles.Data:AvailableDbId(currentCharacters)
    end    -- Add through StateManager
    local currentData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentKey("characters"))
    if currentData and currentData.byId and character and character.id then
        currentData.byId[character.id] = character
        currentData.metadata.count = currentData.metadata.count + 1
        currentData.metadata.lastModified = GetServerTime()

        local startYear = character.yearStart or 0

        if not currentData.index.byYear[startYear] then
            currentData.index.byYear[startYear] = {}
        end
        if not private.Core.Utils.TableUtils.containsValue(currentData.index.byYear[startYear], character.id) then
            table.insert(currentData.index.byYear[startYear], character.id)
        end        private.Core.StateManager.setState(
            private.Core.StateManager.buildUserContentKey("characters"),
            currentData,
            "Added MyJournal character: " .. (character.label or character.id)
        )

        -- Invalidate character caches
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.ALL_CHARACTERS)
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_CHARACTERS)
    end
end

function Chronicles.Data:RemoveMyJournalCharacter(characterId)
    -- Remove through StateManager
    local currentData = private.Core.StateManager.getState(private.Core.StateManager.buildUserContentKey("characters"))
    if currentData and currentData.byId and characterId then
        currentData.byId[characterId] = nil
        currentData.metadata.count = math.max(0, currentData.metadata.count - 1)
        currentData.metadata.lastModified = GetServerTime()

        -- Remove from indexes
        for year, characterIds in pairs(currentData.index.byYear or {}) do
            for i, id in ipairs(characterIds) do
                if id == characterId then
                    table.remove(characterIds, i)
                    break
                end
            end
        end        private.Core.StateManager.setState(
            private.Core.StateManager.buildUserContentKey("characters"),
            currentData,
            "Removed MyJournal character: " .. characterId
        )

        -- Invalidate character caches
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.ALL_CHARACTERS)
        private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_CHARACTERS)
    end
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
