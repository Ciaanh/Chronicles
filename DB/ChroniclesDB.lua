local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}
Chronicles.DB.Events = {}
Chronicles.DB.Factions = {}
Chronicles.DB.Characters = {}
Chronicles.DB.RP = {}

RPEventsDB = {}

function Chronicles.DB:Init()
    self:RegisterEventDB("RP", RPEventsDB)

    -- load data for my journal
    self:RegisterEventDB("myjournal", Chronicles.DB:GetMyJournalEvents())
    self:RegisterFactionDB("myjournal", Chronicles.DB:GetMyJournalFactions())
    self:RegisterCharacterDB("myjournal", Chronicles.DB:GetMyJournalCharacters())

    if (Chronicles.Custom ~= nil and Chronicles.Custom.DB ~= nil) then
        Chronicles.Custom.DB:Init()
    end

    Chronicles.DB.EventsDates = Chronicles.DB:GetEventsDates()
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AvailableDbId(db)
end

function Chronicles.DB:AddRPEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(RPEventsDB) + 1
    end
    table.insert(RPEventsDB, event.id, self:CleanEventObject(event, "RP"))
end

-- function to retrieve the list of dates for all eventsGroup
function Chronicles.DB:GetEventsDates()
    local dates = {
        mod1000 = {},
        mod500 = {},
        mod250 = {},
        mod100 = {},
        mod50 = {},
        mod10 = {},
        mod1 = {}
    }

    for groupName, eventsGroup in pairs(Chronicles.DB.Events) do
        local isActive = Chronicles.DB.GetGroupStatus(self, groupName)
        local computeDateProfile = Chronicles.DB.ComputeDateProfile

        if (isActive) then
            for _, event in pairs(eventsGroup.data) do
                if (event ~= nil) then
                    for i = event.yearStart, event.yearEnd, 1 do
                        local dateProfile = computeDateProfile(self, i)

                        dates.mod1000[dateProfile.mod1000] = true
                        dates.mod500[dateProfile.mod500] = true
                        dates.mod250[dateProfile.mod250] = true
                        dates.mod100[dateProfile.mod100] = true
                        dates.mod50[dateProfile.mod50] = true
                        dates.mod10[dateProfile.mod10] = true
                        dates.mod1[dateProfile.mod1] = true
                    end
                end
            end
        end
    end

    return dates
end

function Chronicles.DB:ComputeDateProfile(date)
    local mod1000 = math.floor(date / 1000)
    local mod500 = math.floor(date / 500)
    local mod250 = math.floor(date / 250)
    local mod100 = math.floor(date / 100)
    local mod50 = math.floor(date / 50)
    local mod10 = math.floor(date / 10)

    return {
        mod1000 = mod1000,
        mod500 = mod500,
        mod250 = mod250,
        mod100 = mod100,
        mod50 = mod50,
        mod10 = mod10,
        mod1 = date
    }
end

function Chronicles.DB:HasEvents(yearStart, yearEnd)
    if (yearStart <= yearEnd) then
        local getGroupStatus = Chronicles.DB.GetGroupStatus
        local hasEventsInDB = Chronicles.DB.HasEventsInDB
        for groupName, eventsGroup in pairs(Chronicles.DB.Events) do
            local isActive = getGroupStatus(self, groupName)
            if (isActive and hasEventsInDB(self, yearStart, yearEnd, eventsGroup.data)) then
                return true
            end
        end
    end
    return false
end

function Chronicles.DB:HasEventsInDB(yearStart, yearEnd, db)
    local getEventTypeStatus = Chronicles.DB.GetEventTypeStatus
    local isInRange = Chronicles.DB.IsInRange
    for eventIndex, event in pairs(db) do
        local isEventTypeActive = getEventTypeStatus(self, event.eventType)

        if isEventTypeActive and isInRange(self, db[eventIndex], yearStart, yearEnd) then
            return true
        end
    end
    return false
end

function Chronicles.DB:MinEventYear()
    local MinEventYear = 0
    local getGroupStatus = Chronicles.DB.GetGroupStatus
    local getEventTypeStatus = Chronicles.DB.GetEventTypeStatus

    for groupName, eventsGroup in pairs(Chronicles.DB.Events) do
        local isActive = getGroupStatus(self, groupName)
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

function Chronicles.DB:MaxEventYear()
    local MaxEventYear = 0
    local getGroupStatus = Chronicles.DB.GetGroupStatus
    local getEventTypeStatus = Chronicles.DB.GetEventTypeStatus

    for groupName, eventsGroup in pairs(Chronicles.DB.Events) do
        local isActive = getGroupStatus(self, groupName)
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

function Chronicles.DB:SearchEvents(yearStart, yearEnd)
    local foundEvents = {}
    local insert = table.insert
    local searchEventsInDB = Chronicles.DB.SearchEventsInDB
    local cleanEventObject = Chronicles.DB.CleanEventObject

    --print("-- Chronicles.DB:SearchEvents start " .. GetTime())
    if (yearStart <= yearEnd) then
        for groupName, eventsGroup in pairs(Chronicles.DB.Events) do
            local pluginEvents = searchEventsInDB(self, yearStart, yearEnd, eventsGroup.data)

            for eventIndex, event in pairs(pluginEvents) do
                insert(foundEvents, cleanEventObject(self, event, groupName))
            end
        end
    end
    --print("-- Chronicles.DB:SearchEvents finish " .. GetTime())
    return foundEvents
end

function Chronicles.DB:SearchEventsInDB(yearStart, yearEnd, db)
    local foundEvents = {}
    local insert = table.insert
    local getEventTypeStatus = Chronicles.DB.GetEventTypeStatus
    local isInRange = Chronicles.DB.IsInRange

    for eventIndex, event in pairs(db) do
        local isEventTypeActive = getEventTypeStatus(self, event.eventType)

        if isEventTypeActive and isInRange(self, db[eventIndex], yearStart, yearEnd) then
            insert(foundEvents, db[eventIndex])
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

    if (yearStart == yearEnd) then
        if (event.yearStart <= yearStart and yearStart <= event.yearEnd) then
            return true
        end
    end

    return false
end

function Chronicles.DB:CleanEventObject(event, groupName)
    if event then
        local description = event.description or UNKNOWN

        local start = event.yearStart
        local finish = event.yearEnd

        -- if (start < Chronicles.constants.config.historyStartYear) then
        --     start = Chronicles.constants.config.historyStartYear - 1
        -- end
        -- if (finish < Chronicles.constants.config.historyEndYear) then
        --     finish = Chronicles.constants.config.historyEndYear - 1
        -- end

        local formatedEvent = {
            id = event.id,
            label = event.label,
            yearStart = start,
            yearEnd = finish,
            description = description,
            eventType = event.eventType,
            factions = event.factions,
            characters = event.characters,
            source = groupName,
            order = event.order
        }
        if (event.order == nil) then
            formatedEvent.order = 0
        -- print("-- event " .. tostring(event.id) .. " --")
        -- print("order: " .. tostring(event.order))
        -- print("label: " .. tostring(event.label))
        end

        return formatedEvent
    end
end

-- Search factions ----------------------------------------------------------------------

function Chronicles.DB:SearchFactions(name)
    local foundFactions = {}
    local lower = string.lower
    local insert = table.insert
    local getGroupStatus = Chronicles.DB.GetGroupStatus
    local cleanFactionObject = Chronicles.DB.CleanFactionObject

    for groupName, factionsGroup in pairs(Chronicles.DB.Factions) do
        local factionGroupStatus = getGroupStatus(self, groupName)
        if (factionGroupStatus) then
            for factionIndex, faction in pairs(factionsGroup.data) do
                if (name ~= nil and strlen(name) >= MIN_CHARACTER_SEARCH) then
                    if (lower(faction.name):find(lower(name)) ~= nil) then
                        insert(foundFactions, cleanFactionObject(self, faction, groupName))
                    end
                else
                    insert(foundFactions, cleanFactionObject(self, faction, groupName))
                end
            end
        end
    end
    return foundFactions
end

function Chronicles.DB:FindFactions(ids)
    local foundFactions = {}
    local insert = table.insert
    local getGroupStatus = Chronicles.DB.GetGroupStatus
    local cleanFactionObject = Chronicles.DB.CleanFactionObject

    for group, factionIds in pairs(ids) do
        local factionGroupStatus = getGroupStatus(self, group)
        if (factionGroupStatus) then
            local factionsGroup = Chronicles.DB.Factions[group]
            if (factionsGroup ~= nil and factionsGroup.data ~= nil and tablelength(factionsGroup.data) > 0) then
                for factionIndex, faction in pairs(factionsGroup.data) do
                    for index, id in ipairs(factionIds) do
                        if (faction.id == id) then
                            insert(foundFactions, cleanFactionObject(self, faction, group))
                        end
                    end
                end
            end
        end
    end
    return foundFactions
end

function Chronicles.DB:CleanFactionObject(faction, groupName)
    if faction ~= nil then
        return {
            id = faction.id,
            name = faction.name,
            description = faction.description,
            timeline = faction.timeline,
            source = groupName
        }
    end
    return nil
end

-- Search characters --------------------------------------------------------------------

function Chronicles.DB:SearchCharacters(name)
    local foundCharacters = {}

    for groupName, charactersGroup in pairs(self.Characters) do
        local characterGroupStatus = Chronicles.DB:GetGroupStatus(groupName)
        if (characterGroupStatus) then
            for characterIndex, character in pairs(charactersGroup.data) do
                if (name ~= nil and strlen(name) >= MIN_CHARACTER_SEARCH) then
                    if (string.lower(character.name):find(string.lower(name)) ~= nil) then
                        table.insert(foundCharacters, Chronicles.DB:CleanCharacterObject(character, groupName))
                    end
                else
                    table.insert(foundCharacters, Chronicles.DB:CleanCharacterObject(character, groupName))
                end
            end
        end
    end
    return foundCharacters
end

function Chronicles.DB:FindCharacters(ids)
    local foundCharacters = {}

    -- print("-- FindFactions " .. tostring(ids))

    for group, characterIds in pairs(ids) do
        -- print("---- group " .. group)
        local characterGroupStatus = Chronicles.DB:GetGroupStatus(group)
        if (characterGroupStatus) then
            local charactersGroup = Chronicles.DB.Characters[group]
            -- print("------ factionsGroup " .. tablelength(factionsGroup.data))
            if (charactersGroup ~= nil and charactersGroup.data ~= nil and tablelength(charactersGroup.data) > 0) then
                for characterIndex, character in pairs(charactersGroup.data) do
                    for index, id in ipairs(characterIds) do
                        -- print("-------- faction.id " .. faction.id .. " id " .. id)
                        if (character.id == id) then
                            table.insert(foundCharacters, Chronicles.DB:CleanCharacterObject(character, group))
                        end
                    end
                end
            end
        end
    end
    return foundCharacters
end

function Chronicles.DB:CleanCharacterObject(character, groupName)
    if character ~= nil then
        return {
            id = character.id,
            name = character.name,
            biography = character.biography,
            timeline = character.timeline,
            factions = character.factions,
            source = groupName
        }
    end
    return nil
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- External DB tools --------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.DB:RegisterEventDB(groupName, db)
    -- print("-- Asked to register group " .. groupName)
    if Chronicles.DB.Events[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Events.")
    else
        local isActive = Chronicles.storage.global.EventDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.EventDBStatuses[groupName] = isActive
        end

        Chronicles.DB.Events[groupName] = {
            data = db,
            name = groupName
        }
    end
end

function Chronicles.DB:RegisterCharacterDB(groupName, db)
    -- print("-- Asked to register group " .. groupName)
    if Chronicles.DB.Characters[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Characters.")
    else
        local isActive = Chronicles.storage.global.CharacterDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.CharacterDBStatuses[groupName] = isActive
        end

        Chronicles.DB.Characters[groupName] = {
            data = db,
            name = groupName
        }
    end
end

function Chronicles.DB:RegisterFactionDB(groupName, db)
    -- print("-- Asked to register group " .. groupName)
    if Chronicles.DB.Factions[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin in Factions.")
    else
        local isActive = Chronicles.storage.global.FactionDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.FactionDBStatuses[groupName] = isActive
        end

        Chronicles.DB.Factions[groupName] = {
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

    for eventGroupName, group in pairs(Chronicles.DB.Events) do
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

    for factionGroupName, group in pairs(Chronicles.DB.Factions) do
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

    for characterGroupName, group in pairs(Chronicles.DB.Characters) do
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
    if Chronicles.DB.Events[groupName] ~= nil then
        Chronicles.storage.global.EventDBStatuses[groupName] = status
        Chronicles.DB.EventsDates = Chronicles.DB:GetEventsDates()
    end

    if Chronicles.DB.Factions[groupName] ~= nil then
        Chronicles.storage.global.FactionDBStatuses[groupName] = status
    end

    if Chronicles.DB.Characters[groupName] ~= nil then
        Chronicles.storage.global.CharacterDBStatuses[groupName] = status
    end
end

function Chronicles.DB:GetGroupStatus(groupName)
    local isEventActive = nil
    local isFactionActive = nil
    local isCharacterActive = nil

    if Chronicles.DB.Events[groupName] ~= nil then
        local isActive = Chronicles.storage.global.EventDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.EventDBStatuses[groupName] = isActive
            Chronicles.DB.EventsDates = Chronicles.DB:GetEventsDates()
        end
        isEventActive = isActive
    end

    if Chronicles.DB.Factions[groupName] ~= nil then
        local isActive = Chronicles.storage.global.FactionDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.FactionDBStatuses[groupName] = isActive
        end
        isFactionActive = isActive
    end

    if Chronicles.DB.Characters[groupName] ~= nil then
        local isActive = Chronicles.storage.global.CharacterDBStatuses[groupName]
        if (isActive == nil) then
            isActive = true
            Chronicles.storage.global.CharacterDBStatuses[groupName] = isActive
        end
        isCharacterActive = isActive
    end
    --------------------------------------------------
    if (isEventActive) then
        if Chronicles.DB.Factions[groupName] ~= nil then
            Chronicles.storage.global.FactionDBStatuses[groupName] = true
        end
        if Chronicles.DB.Characters[groupName] ~= nil then
            Chronicles.storage.global.CharacterDBStatuses[groupName] = true
        end
        return true
    end

    if (isFactionActive) then
        if Chronicles.DB.Events[groupName] ~= nil then
            Chronicles.storage.global.EventDBStatuses[groupName] = true
            Chronicles.DB.EventsDates = Chronicles.DB:GetEventsDates()
        end
        if Chronicles.DB.Characters[groupName] ~= nil then
            Chronicles.storage.global.CharacterDBStatuses[groupName] = true
        end
        return true
    end

    if (isCharacterActive) then
        if Chronicles.DB.Events[groupName] ~= nil then
            Chronicles.storage.global.EventDBStatuses[groupName] = true
            Chronicles.DB.EventsDates = Chronicles.DB:GetEventsDates()
        end
        if Chronicles.DB.Factions[groupName] ~= nil then
            Chronicles.storage.global.FactionDBStatuses[groupName] = true
        end
        return true
    end

    return false
end

function Chronicles.DB:SetEventTypeStatus(eventType, status)
    -- print("-- SetGroupStatus " .. groupName .. " " .. tostring(status))
    Chronicles.storage.global.EventTypesStatuses[eventType] = status
end

function Chronicles.DB:GetEventTypeStatus(eventType)
    -- print("-- GetEventTypeStatus " .. tostring(eventType))
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
    return Chronicles.storage.global.MyJournalEventDB
end

function Chronicles.DB:SetMyJournalEvents(event)
    Chronicles.DB:AddToMyJournal(event, Chronicles.storage.global.MyJournalEventDB)
end

function Chronicles.DB:RemoveMyJournalEvent(eventId)
    Chronicles.DB:RemoveFromMyJournal(eventId, Chronicles.storage.global.MyJournalEventDB)
end

function Chronicles.DB:GetMyJournalFactions()
    return Chronicles.storage.global.MyJournalFactionDB
end

function Chronicles.DB:SetMyJournalFactions(faction)
    Chronicles.DB:AddToMyJournal(faction, Chronicles.storage.global.MyJournalFactionDB)
end

function Chronicles.DB:RemoveMyJournalFaction(factionId)
    Chronicles.DB:RemoveFromMyJournal(factionId, Chronicles.storage.global.MyJournalFactionDB)
end

function Chronicles.DB:GetMyJournalCharacters()
    return Chronicles.storage.global.MyJournalCharacterDB
end

function Chronicles.DB:SetMyJournalCharacters(character)
    Chronicles.DB:AddToMyJournal(character, Chronicles.storage.global.MyJournalCharacterDB)
end

function Chronicles.DB:RemoveMyJournalCharacter(characterId)
    Chronicles.DB:RemoveFromMyJournal(characterId, Chronicles.storage.global.MyJournalCharacterDB)
end

function Chronicles.DB:AvailableDbId(db)
    -- print("-- AvailableDbId ")
    local ids = {}

    for key, value in pairs(db) do
        if (value ~= nil) then
            table.insert(ids, value.id)
        end
    end

    table.sort(ids)

    local maxId = 1

    for key, value in ipairs(ids) do
        -- print("-- key " .. key .. " , value " .. value .. " , maxid " .. maxId)
        if (value > maxId + 1) then
            return maxId + 1
        end
        maxId = maxId + 1
    end

    -- print("-- AvailableDbId maxId " .. maxId)
    return maxId -- table.maxn(db) + 1
end

function Chronicles.DB:AddToMyJournal(object, db)
    object.source = "myjournal"

    if (object.id == nil) then
        object.id = Chronicles.DB:AvailableDbId(db)
        table.insert(db, object)
    else
        db[object.id] = object
    end
end

function Chronicles.DB:RemoveFromMyJournal(objectId, db)
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
function Chronicles.DB:LoadRolePlayProfile()
    if (RPEventsDB[0] ~= nil) then
        return
    end

    if (_G["TRP3_API"]) then
        local age = tonumber(Chronicles.DB.RP:TRP_GetAge())
        local name = Chronicles.DB.RP:TRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            --print("-- trp " .. age .. " " .. name)
            Chronicles.DB.RP:RegisterBirth(age, name, "TotalRP")
        end
    end

    if (_G["mrp"]) then
        local age = tonumber(Chronicles.DB.RP:MRP_GetAge())
        local name = Chronicles.DB.RP:MRP_GetRoleplayingName()

        if (age ~= nil and name ~= nil) then
            -- print("-- mrp " .. age .. " " .. name)
            Chronicles.DB.RP:RegisterBirth(age, name, "MyRolePlay")
        end
    end
end

function Chronicles.DB.RP:RegisterBirth(age, name, addon)
    -- compare date with current year
    local birth = Chronicles.constants.config.currentYear - age
    local event = {
        id = 0,
        label = "Birth of " .. name,
        description = {"Birth of " .. name .. " \n\nImported from " .. addon},
        yearStart = birth,
        yearEnd = birth,
        eventType = 5,
        order = 0
    }
    Chronicles.DB:AddRPEvent(event)
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
