local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}
Chronicles.DB.Events = {}
Chronicles.DB.Factions = {}
Chronicles.DB.Characters = {}
Chronicles.DB.RP = {}

function Chronicles.DB:Init()
    self:RegisterEventDB("Global", GlobalEventsDB)
    self:RegisterFactionDB("Global", GlobalFactionsDB)
    self:RegisterCharacterDB("Global", GlobalCharactersDB)

    -- load data for my journal
    self:RegisterEventDB("myjournal", Chronicles.DB:GetMyJournalEvents())
    self:RegisterFactionDB("myjournal", Chronicles.DB:GetMyJournalFactions())
    self:RegisterCharacterDB("myjournal", Chronicles.DB:GetMyJournalCharacters())
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AvailableDbId(db)
end

function Chronicles.DB:AddGlobalEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(GlobalEventsDB) + 1
    end
    table.insert(GlobalEventsDB, event.id, self:CleanEventObject(event, "Global"))
end

function Chronicles.DB:HasEvents(yearStart, yearEnd)
    if (yearStart <= yearEnd) then
        for groupName, eventsGroup in pairs(self.Events) do
            local isActive = Chronicles.DB:GetGroupStatus(groupName)
            if (isActive and self:HasEventsInDB(yearStart, yearEnd, eventsGroup.data)) then
                return true
            end
        end
    end
    return false
end

function Chronicles.DB:HasEventsInDB(yearStart, yearEnd, db)
    for eventIndex, event in pairs(db) do
        local isEventTypeActive = Chronicles.DB:GetEventTypeStatus(event.eventType)

        if isEventTypeActive and self:IsInRange(db[eventIndex], yearStart, yearEnd) then
            return true
        end
    end
    return false
end

-- Should return a list of objects :
-- { label, yearStart, yearEnd, description, eventType, source }
function Chronicles.DB:SearchEvents(yearStart, yearEnd)
    local nbFoundEvents = 0
    local foundEvents = {}

    if (yearStart <= yearEnd) then
        for groupName, eventsGroup in pairs(self.Events) do
            local pluginEvents = self:SearchEventsInDB(yearStart, yearEnd, eventsGroup.data)

            for eventIndex, event in pairs(pluginEvents) do
                table.insert(foundEvents, self:CleanEventObject(event, groupName))
                nbFoundEvents = nbFoundEvents + 1
            end
        end
    end
    return foundEvents
end

function Chronicles.DB:SearchEventsInDB(yearStart, yearEnd, db)
    local foundEvents = {}
    for eventIndex, event in pairs(db) do
        local isEventTypeActive = Chronicles.DB:GetEventTypeStatus(event.eventType)

        if isEventTypeActive and self:IsInRange(db[eventIndex], yearStart, yearEnd) then
            table.insert(foundEvents, db[eventIndex])
        end
    end
    return foundEvents
end

function Chronicles.DB:IsInRange(event, yearStart, yearEnd)
    if (yearStart <= event.yearStart and event.yearStart <= yearEnd) then
        return true
    end
    if (yearStart <= event.yearEnd and event.yearEnd <= yearEnd) then
        return true
    end
    return false
end

function Chronicles.DB:CleanEventObject(event, groupName)
    if event then
        local description = event.description or UNKNOWN

        return {
            id = event.id,
            label = event.label,
            yearStart = event.yearStart,
            yearEnd = event.yearEnd,
            description = description,
            eventType = event.eventType,
            source = groupName
        }
    end
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- External DB tools --------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.DB:RegisterEventDB(groupName, db)
    --DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register group " .. groupName)
    if self.Events[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Events.")
    else
        local isActive = Chronicles.storage.global.EventDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.EventDBStatuses[groupName] = isActive
        end

        self.Events[groupName] = {
            data = db,
            name = groupName
        }
    end
end

function Chronicles.DB:RegisterCharacterDB(groupName, db)
    --DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register group " .. groupName)
    if self.Characters[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Characters.")
    else
        local isActive = Chronicles.storage.global.CharacterDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.CharacterDBStatuses[groupName] = isActive
        end

        self.Characters[groupName] = {
            data = db,
            name = groupName
        }
    end
end

function Chronicles.DB:RegisterFactionDB(groupName, db)
    --DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register group " .. groupName)
    if self.Factions[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Factions.")
    else
        local isActive = Chronicles.storage.global.FactionDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.FactionDBStatuses[groupName] = isActive
        end

        self.Factions[groupName] = {
            data = db,
            name = groupName
        }
    end
end

function exist_in_table(value, lookUpTable)
    for key, item in pairs(lookUpTable) do
        if (item.name == value) then
            return true
        end
    end
    return false
end

function Chronicles.DB:GetGroupNames()
    local dataGroups = {}

    for eventGroupName, group in pairs(self.Events) do
        if (eventGroupName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.storage.global.EventDBStatuses[eventGroupName]
            }

            Chronicles.DB:SetGroupStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(eventGroupName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    for factionGroupName, group in pairs(self.Factions) do
        if (factionGroupName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.storage.global.FactionDBStatuses[factionGroupName]
            }

            Chronicles.DB:SetGroupStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(factionGroupName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    for characterGroupName, group in pairs(self.Characters) do
        if (characterGroupName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.storage.global.CharacterDBStatuses[characterGroupName]
            }

            Chronicles.DB:SetGroupStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(characterGroupName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    return dataGroups
end

function Chronicles.DB:SetGroupStatus(groupName, status)
    if self.Events[groupName] ~= nil then
        Chronicles.storage.global.EventDBStatuses[groupName] = status
    end

    if self.Factions[groupName] ~= nil then
        Chronicles.storage.global.FactionDBStatuses[groupName] = status
    end

    if self.Characters[groupName] ~= nil then
        Chronicles.storage.global.CharacterDBStatuses[groupName] = status
    end
end

function Chronicles.DB:GetGroupStatus(groupName)
    local isEventActive = nil
    local isFactionActive = nil
    local isCharacterActive = nil

    if self.Events[groupName] ~= nil then
        local isActive = Chronicles.storage.global.EventDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.EventDBStatuses[groupName] = isActive
        end
        isEventActive = isActive
    end

    if self.Factions[groupName] ~= nil then
        local isActive = Chronicles.storage.global.FactionDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.FactionDBStatuses[groupName] = isActive
        end
        isFactionActive = isActive
    end

    if self.Characters[groupName] ~= nil then
        local isActive = Chronicles.storage.global.CharacterDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.CharacterDBStatuses[groupName] = isActive
        end
        isCharacterActive = isActive
    end
    --------------------------------------------------
    if (isEventActive) then
        if self.Factions[groupName] ~= nil then
            Chronicles.storage.global.FactionDBStatuses[groupName] = true
        end
        if self.Characters[groupName] ~= nil then
            Chronicles.storage.global.CharacterDBStatuses[groupName] = true
        end
        return true
    end

    if (isFactionActive) then
        if self.Events[groupName] ~= nil then
            Chronicles.storage.global.EventDBStatuses[groupName] = true
        end
        if self.Characters[groupName] ~= nil then
            Chronicles.storage.global.CharacterDBStatuses[groupName] = true
        end
        return true
    end

    if (isCharacterActive) then
        if self.Events[groupName] ~= nil then
            Chronicles.storage.global.EventDBStatuses[groupName] = true
        end
        if self.Factions[groupName] ~= nil then
            Chronicles.storage.global.FactionDBStatuses[groupName] = true
        end
        return true
    end

    return false
end

function Chronicles.DB:SetEventTypeStatus(eventType, status)
    --DEFAULT_CHAT_FRAME:AddMessage("-- SetGroupStatus " .. groupName .. " " .. tostring(status))
    Chronicles.storage.global.EventTypesStatuses[eventType] = status
end

function Chronicles.DB:GetEventTypeStatus(eventType)
    --DEFAULT_CHAT_FRAME:AddMessage("-- GetEventTypeStatus " .. tostring(eventType))
    local isActive = Chronicles.storage.global.EventTypesStatuses[eventType]
    if (isActive == nil) then
        isActive = true
        Chronicles.storage.global.EventTypesStatuses[eventType] = isActive
    end
    return isActive
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:GetMyJournalEvents()
    local myEvent = {
        [1] = {
            id = 1,
            label = "My event 1",
            description = {"My event 1 label"},
            yearStart = -10000,
            yearEnd = -10000,
            eventType = 2,
            timeline = 2
        },
        [2] = {
            id = 2,
            label = "My event 2",
            description = {"My event 2 label\n\n\ndssdgfqgddd"},
            yearStart = -6800,
            yearEnd = -6800,
            eventType = 6,
            timeline = 2
        },
        [3] = {
            id = 3,
            label = "My event 3",
            description = {"My event 3 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [4] = {
            id = 4,
            label = "My event 4",
            description = {"My event 4 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [5] = {
            id = 5,
            label = "My event 5",
            description = {"My event 5 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [6] = {
            id = 6,
            label = "My event 6",
            description = {"My event 6 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [7] = {
            id = 7,
            label = "My event 7",
            description = {"My event 7 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [8] = {
            id = 8,
            label = "My event 8",
            description = {"My event 8 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [9] = {
            id = 9,
            label = "My event 9",
            description = {"My event 9 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        },
        [10] = {
            id = 10,
            label = "My event 10",
            description = {"My event 10 label"},
            yearStart = -2800,
            yearEnd = -2800,
            eventType = 2,
            timeline = 2
        }
    }
    return myEvent

    --return Chronicles.storage.global.MyJournalEventDB
end

function Chronicles.DB:GetMyJournalFactions()
    return Chronicles.storage.global.MyJournalFactionDB
end

function Chronicles.DB:GetMyJournalCharacters()
    return Chronicles.storage.global.MyJournalCharacterDB
end

-- function add - delete

function Chronicles.DB:AvailableDbId(db)
    for key, value in pairs(db) do
        if (value == nil) then
            return key
        end
    end

    return table.maxn(db) + 1
end

function Chronicles.DB:AddToMyJournal(object, db)
    if (object.id == nil) then
        object.id = Chronicles.DB:AvailableDbId(db)
    end
    object.source = "myjournal"
    table.insert(db, object.id, object)
end

function Chronicles.DB:RemoveFromMyJournal(object, db)
    table.remove(db, object.id)
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- RP addons tools ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.DB:LoadRolePlayProfile()
    if (GlobalEventsDB[0] ~= nil) then
        return
    end

    if (_G["TRP3_API"]) then
        local age = Chronicles.DB.RP:TRP_GetAge()
        local name = Chronicles.DB.RP:TRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            -- DEFAULT_CHAT_FRAME:AddMessage("-- trp " .. age .. " " .. name)
            self.RP:RegisterBirth(age, name, "TotalRP")
        end
    end

    if (_G["mrp"]) then
        local age = Chronicles.DB.RP:MRP_GetAge()
        local name = Chronicles.DB.RP:MRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            -- DEFAULT_CHAT_FRAME:AddMessage("-- mrp " .. age .. " " .. name)
            self.RP:RegisterBirth(age, name, "MyRolePlay")
        end
    end
end

function Chronicles.DB.RP:RegisterBirth(age, name, addon)
    -- compare date with current year
    local birth = Chronicles.constants.config.timeline.yearEnd - age
    local event = {
        id = 0,
        label = "Birth of " .. name,
        description = {"Birth of " .. name .. " \n\nImported from " .. addon},
        yearStart = birth,
        yearEnd = birth,
        eventType = 5
    }
    Chronicles.DB:AddGlobalEvent(event)
end

function Chronicles.DB.RP:MRP_GetRoleplayingName()
    return msp.my["NA"]
end

function Chronicles.DB.RP:MRP_GetAge()
    return msp.my["AG"]
end

function Chronicles.DB.RP:GetName()
    local name, realm = UnitName("player")
    return name
end

function Chronicles.DB.RP:TRP_GetCharacteristics()
    local profileID = TRP3_API.profile.getPlayerCurrentProfileID()
    local profile = TRP3_API.profile.getProfileByID(profileID)
    return profile.player.characteristics
end

function Chronicles.DB.RP:TRP_GetFirstName()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()
    if characteristics ~= nil then
        return characteristics.FN
    end
end

function Chronicles.DB.RP:TRP_GetLastName()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()
    if characteristics ~= nil then
        return characteristics.LN
    end
end

function Chronicles.DB.RP:TRP_GetRoleplayingName()
    local name = Chronicles.DB.RP:TRP_GetFirstName() or Chronicles.DB.RP:GetName()
    if Chronicles.DB.RP:TRP_GetLastName() then
        name = name .. " " .. Chronicles.DB.RP:TRP_GetLastName()
    end
    return name
end

function Chronicles.DB.RP:TRP_GetAge()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()

    if characteristics ~= nil then
        return characteristics.AG
    end
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
