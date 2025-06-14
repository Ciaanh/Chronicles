--[[
    Chronicles Data Module
      Main data management module for Chronicles addon.
    Handles database registration and integration with StateManager.
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

-- Search events ------------------------------------------------------------------------

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

function Chronicles.Data:SearchEventsInDB(yearStart, yearEnd, db)
    return private.Core.Data.SearchEngine.searchEventsInDB(yearStart, yearEnd, db)
end

function Chronicles.Data:IsInRange(event, yearStart, yearEnd)
    return private.Core.Data.SearchEngine.isEventInRange(event, yearStart, yearEnd)
end

function Chronicles.Data:CleanEventObject(event, collectionName)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return nil
    --return event
    end

    return private.Core.Data.SearchEngine.cleanEventObject(event, collectionName)
end

-- Search factions ----------------------------------------------------------------------

function Chronicles.Data:SearchFactions(name)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return {}
    end
    return private.Core.Data.SearchEngine.searchFactions(name)
end

function Chronicles.Data:FindFactions(ids)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return {}
    end
    return private.Core.Data.SearchEngine.findFactions(ids)
end

function Chronicles.Data:CleanFactionObject(faction, collectionName)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return nil
    --return faction
    end
    return private.Core.Data.SearchEngine.cleanFactionObject(faction, collectionName)
end

-- Search characters --------------------------------------------------------------------

function Chronicles.Data:SearchCharacters(name)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return {}
    end
    return private.Core.Data.SearchEngine.searchCharacters(name)
end

function Chronicles.Data:FindCharacters(ids)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return {}
    end
    return private.Core.Data.SearchEngine.findCharacters(ids)
end

function Chronicles.Data:CleanCharacterObject(character, collectionName)
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        return nil
    --return character
    end
    return private.Core.Data.SearchEngine.cleanCharacterObject(character, collectionName)
end

-- -------------------------
-- External DB tools
-- -------------------------
function Chronicles.Data:RegisterEventDB(collectionName, db)
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        return false
    end
    return private.Core.Data.DataRegistry.registerEventDB(collectionName, db)
end

function Chronicles.Data:RegisterCharacterDB(collectionName, db)
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        return false
    end
    return private.Core.Data.DataRegistry.registerCharacterDB(collectionName, db)
end

function Chronicles.Data:RegisterFactionDB(collectionName, db)
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        return false
    end
    return private.Core.Data.DataRegistry.registerFactionDB(collectionName, db)
end

function Chronicles.Data:GetCollectionsNames()
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        return {}
    end
    return private.Core.Data.DataRegistry.getCollectionsNames()
end

function Chronicles.Data:GetCollectionStatus(collectionName)
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        return false
    end
    return private.Core.Data.DataRegistry.getCollectionStatus(collectionName)
end

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
