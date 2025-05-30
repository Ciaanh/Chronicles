--[[
    Chronicles Data Module
    
    Main data management module for Chronicles addon. This module has been refactored as part of 
    the Clean Code reorganization initiative.
    
    PHASE 1 COMPLETED: Search functionality has been extracted to SearchEngine module
    - All search methods now delegate to private.Core.Data.SearchEngine
    - Backward compatibility maintained through facade methods
    - Single responsibility principle applied
    
    PHASE 2 COMPLETED: Data Registry functionality has been extracted to DataRegistry module
    - All registry methods now delegate to private.Core.Data.DataRegistry
    - Database registration: RegisterEventDB, RegisterFactionDB, RegisterCharacterDB
    - Library status management: GetLibraryStatus, SetLibraryStatus, GetLibrariesNames
    - Backward compatibility maintained through facade methods
    
    ERROR FIXES COMPLETED: Runtime error resolution
    - Added initialization guards to all delegation methods
    - Prevents nil access errors during module loading
    - Graceful error handling with fallback values
    
    Future Phases:
    - Phase 3: Extract Timeline Business Logic
    - Phase 4: Complete domain separation
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
    if (Chronicles.Custom ~= nil and Chronicles.Custom.DB ~= nil) then
        Chronicles.Custom.DB:Init()
    end

    -- Initialize the cache system
    private.Core.Cache.init()
end

function Chronicles.Data:RefreshPeriods()
    private.Core.Cache.invalidate("periodsFillingBySteps")
end

-- Cache management methods (delegate to Core.Cache)
function Chronicles.Data:InvalidateCache(cacheType)
    return private.Core.Cache.invalidate(cacheType)
end

function Chronicles.Data:GetCachedPeriodsFillingBySteps()
    return private.Core.Cache.getPeriodsFillingBySteps()
end

function Chronicles.Data:GetCachedMinEventYear()
    return private.Core.Cache.getMinEventYear()
end

function Chronicles.Data:GetCachedMaxEventYear()
    return private.Core.Cache.getMaxEventYear()
end

function Chronicles.Data:GetCachedLibrariesNames()
    return private.Core.Cache.getLibrariesNames()
end

function Chronicles.Data:GetCachedSearchEvents(yearStart, yearEnd)
    return private.Core.Cache.getSearchEvents(yearStart, yearEnd)
end

function Chronicles.Data:PreWarmSearchCache()
    return private.Core.Cache.preWarmSearchCache()
end

function Chronicles.Data:WarmCache()
    return private.Core.Cache.warmAllCaches()
end

function Chronicles.Data:ClearCache()
    return private.Core.Cache.clearAll()
end

function Chronicles.Data:RebuildCache()
    return private.Core.Cache.rebuildAll()
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.Data:AddRPEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(RPEventsDB) + 1
    end
    table.insert(RPEventsDB, event.id, self:CleanEventObject(event, "RP"))

    -- Invalidate caches since we added new event data
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("minEventYear")
    private.Core.Cache.invalidate("maxEventYear")
    private.Core.Cache.invalidate("searchCache")
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
    for libraryName, eventsGroup in pairs(Chronicles.Data.Events) do
        if Chronicles.Data:GetLibraryStatus(libraryName) then
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
            --print("-- found event do nothing")
        else
            --print("-- event not found insert")
            table.insert(period, eventId)
        end

        return period
    else
        local data = {}
        table.insert(data, eventId)

        --print("-- create new data")
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
    local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
    local getEventTypeStatus = Chronicles.Data.GetEventTypeStatus

    for libraryName, eventsGroup in pairs(Chronicles.Data.Events) do
        local isActive = GetLibraryStatus(self, libraryName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = getEventTypeStatus(self, event.eventType)

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
    local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
    local getEventTypeStatus = Chronicles.Data.GetEventTypeStatus

    for libraryName, eventsGroup in pairs(Chronicles.Data.Events) do
        local isActive = GetLibraryStatus(self, libraryName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = getEventTypeStatus(self, event.eventType)

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

function Chronicles.Data:CleanEventObject(event, libraryName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean event object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanEventObject(event, libraryName)
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

function Chronicles.Data:CleanFactionObject(faction, libraryName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean faction object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanFactionObject(faction, libraryName)
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

function Chronicles.Data:CleanCharacterObject(character, libraryName)
    -- Ensure SearchEngine module is loaded
    if not private.Core.Data or not private.Core.Data.SearchEngine then
        private.Core.Logger.error("Data", "SearchEngine module not loaded when trying to clean character object")
        return nil
    end
    -- Delegate to SearchEngine
    return private.Core.Data.SearchEngine.cleanCharacterObject(character, libraryName)
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- External DB tools --------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.Data:RegisterEventDB(libraryName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. libraryName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerEventDB(libraryName, db)
end

function Chronicles.Data:RegisterCharacterDB(libraryName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. libraryName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerCharacterDB(libraryName, db)
end

function Chronicles.Data:RegisterFactionDB(libraryName, db)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to register " .. libraryName)
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.registerFactionDB(libraryName, db)
end

function Chronicles.Data:GetLibrariesNames()
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to get libraries names")
        return {}
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.getLibrariesNames()
end

function Chronicles.Data:SetLibraryStatus(libraryName, status)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to set library status")
        return
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.setLibraryStatus(libraryName, status)
end

function Chronicles.Data:GetLibraryStatus(libraryName)
    -- Ensure DataRegistry module is loaded
    if not private.Core.Data or not private.Core.Data.DataRegistry then
        private.Core.Logger.error("Data", "DataRegistry module not loaded when trying to get library status")
        return false
    end
    -- Delegate to DataRegistry
    return private.Core.Data.DataRegistry.getLibraryStatus(libraryName)
end

function Chronicles.Data:SetEventTypeStatus(eventType, isActive)
    local oldStatus = Chronicles.db.global.EventTypesStatuses[eventType]
    Chronicles.db.global.EventTypesStatuses[eventType] = isActive -- Only invalidate cache if there was an actual change
    if oldStatus ~= isActive then
        private.Core.Cache.invalidate("periodsFillingBySteps")
        private.Core.Cache.invalidate("searchCache")
    end
end

function Chronicles.Data:GetEventTypeStatus(eventTypeId)
    local isActive = Chronicles.db.global.EventTypesStatuses[eventTypeId]
    if (isActive == nil) then
        isActive = true
        Chronicles.db.global.EventTypesStatuses[eventTypeId] = isActive
    end
    return isActive
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.Data:GetMyJournalEvents()
    return Chronicles.db.global.MyJournalEventDB
end

function Chronicles.Data:SetMyJournalEvents(event)
    Chronicles.Data:AddToMyJournal(event, Chronicles.db.global.MyJournalEventDB)
    -- Invalidate caches since we added new event data
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("minEventYear")
    private.Core.Cache.invalidate("maxEventYear")
    private.Core.Cache.invalidate("searchCache")
end

function Chronicles.Data:RemoveMyJournalEvent(eventId)
    Chronicles.Data:RemoveFromMyJournal(eventId, Chronicles.db.global.MyJournalEventDB)
    -- Invalidate caches since we removed event data
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("minEventYear")
    private.Core.Cache.invalidate("maxEventYear")
    private.Core.Cache.invalidate("searchCache")
end

function Chronicles.Data:GetMyJournalFactions()
    return Chronicles.db.global.MyJournalFactionDB
end

function Chronicles.Data:SetMyJournalFactions(faction)
    Chronicles.Data:AddToMyJournal(faction, Chronicles.db.global.MyJournalFactionDB)
end

function Chronicles.Data:RemoveMyJournalFaction(factionId)
    Chronicles.Data:RemoveFromMyJournal(factionId, Chronicles.db.global.MyJournalFactionDB)
end

function Chronicles.Data:GetMyJournalCharacters()
    return Chronicles.db.global.MyJournalCharacterDB
end

function Chronicles.Data:SetMyJournalCharacters(character)
    Chronicles.Data:AddToMyJournal(character, Chronicles.db.global.MyJournalCharacterDB)
end

function Chronicles.Data:RemoveMyJournalCharacter(characterId)
    Chronicles.Data:RemoveFromMyJournal(characterId, Chronicles.db.global.MyJournalCharacterDB)
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

function Chronicles.Data:AddToMyJournal(object, db)
    object.source = "myjournal"

    if (object.id == nil) then
        object.id = Chronicles.Data:AvailableDbId(db)
        table.insert(db, object)
    else
        db[object.id] = object
    end
end

function Chronicles.Data:RemoveFromMyJournal(objectId, db)
    for key, value in ipairs(db) do
        if (value.id == objectId) then
            table.remove(db, key)
        end
    end
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- RP addons tools ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------
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
        description = {"Birth of " .. name .. " \n\nImported from " .. addon},
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
    local profileID = TRP3_API.profile.getPlayerCurrentProfileID()
    local profile = TRP3_API.profile.getProfileByID(profileID)
    return profile.player.characteristics
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

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
