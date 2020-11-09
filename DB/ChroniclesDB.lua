local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}
Chronicles.DB.Events = {}
Chronicles.DB.Factions = {}
Chronicles.DB.Characters = {}
Chronicles.DB.RP = {}

RPEventsDB = {}

function Chronicles.DB:Init()
    self:RegisterEventDB("RP", RPEventsDB)

    self:RegisterEventDB("Demo", DemoEventsDB)
    self:RegisterFactionDB("Demo", DemoFactionsDB)
    self:RegisterCharacterDB("Demo", DemoCharactersDB)

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

function Chronicles.DB:AddRPEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(RPEventsDB) + 1
    end
    table.insert(RPEventsDB, event.id, self:CleanEventObject(event, "RP"))
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

function Chronicles.DB:MinEventYear()
    local MinEventYear = 0
    for groupName, eventsGroup in pairs(self.Events) do
        local isActive = Chronicles.DB:GetGroupStatus(groupName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = Chronicles.DB:GetEventTypeStatus(event.eventType)

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
    for groupName, eventsGroup in pairs(self.Events) do
        local isActive = Chronicles.DB:GetGroupStatus(groupName)
        if (isActive) then
            for eventIndex, event in pairs(eventsGroup.data) do
                local isEventTypeActive = Chronicles.DB:GetEventTypeStatus(event.eventType)

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

-- Search factions ----------------------------------------------------------------------

function Chronicles.DB:SearchFactions(name)
    local foundFactions = {}

    for groupName, factionsGroup in pairs(self.Factions) do
        local factionGroupStatus = Chronicles.DB:GetGroupStatus(groupName)
        if (factionGroupStatus) then
            for factionIndex, faction in pairs(factionsGroup.data) do
                if (name ~= nil and strlen(name) >= MIN_CHARACTER_SEARCH) then
                    if (string.lower(faction.name):find(string.lower(name)) ~= nil) then
                        table.insert(foundFactions, self:CleanFactionObject(faction, groupName))
                    end
                else
                    table.insert(foundFactions, self:CleanFactionObject(faction, groupName))
                end
            end
        end
    end
    return foundFactions
end

function Chronicles.DB:FindFactions(ids)
    local foundFactions = {}

    -- DEFAULT_CHAT_FRAME:AddMessage("-- FindFactions " .. tostring(ids))

    for group, factionIds in pairs(ids) do
        -- DEFAULT_CHAT_FRAME:AddMessage("---- group " .. group)
        local factionGroupStatus = Chronicles.DB:GetGroupStatus(group)
        if (factionGroupStatus) then
            local factionsGroup = self.Factions[group]
            -- DEFAULT_CHAT_FRAME:AddMessage("------ factionsGroup " .. tablelength(factionsGroup.data))
            if (factionsGroup ~= nil and factionsGroup.data ~= nil and tablelength(factionsGroup.data) > 0) then
                for factionIndex, faction in pairs(factionsGroup.data) do
                    for index, id in ipairs(factionIds) do
                        -- DEFAULT_CHAT_FRAME:AddMessage("-------- faction.id " .. faction.id .. " id " .. id)
                        if (faction.id == id) then
                            table.insert(foundFactions, Chronicles.DB:CleanFactionObject(faction, group))
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
                        table.insert(foundCharacters, self:CleanCharacterObject(character, groupName))
                    end
                else
                    table.insert(foundCharacters, self:CleanCharacterObject(character, groupName))
                end
            end
        end
    end
    return foundCharacters
end

function Chronicles.DB:FindCharacters(ids)
    local foundCharacters = {}

    -- DEFAULT_CHAT_FRAME:AddMessage("-- FindFactions " .. tostring(ids))

    for group, characterIds in pairs(ids) do
        -- DEFAULT_CHAT_FRAME:AddMessage("---- group " .. group)
        local characterGroupStatus = Chronicles.DB:GetGroupStatus(group)
        if (characterGroupStatus) then
            local charactersGroup = self.Characters[group]
            -- DEFAULT_CHAT_FRAME:AddMessage("------ factionsGroup " .. tablelength(factionsGroup.data))
            if (charactersGroup ~= nil and charactersGroup.data ~= nil and tablelength(charactersGroup.data) > 0) then
                for characterIndex, character in pairs(charactersGroup.data) do
                    for index, id in ipairs(characterIds) do
                        -- DEFAULT_CHAT_FRAME:AddMessage("-------- faction.id " .. faction.id .. " id " .. id)
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
    -- DEFAULT_CHAT_FRAME:AddMessage("-- AvailableDbId ")
    local ids = {}

    for key, value in pairs(db) do
        if (value ~= nil) then
            table.insert(ids, value.id)
        end
    end

    table.sort(ids)

    local maxId = 1

    for key, value in ipairs(ids) do
        -- DEFAULT_CHAT_FRAME:AddMessage("-- key " .. key .. " , value " .. value .. " , maxid " .. maxId)
        if (value > maxId + 1) then
            return maxId + 1
        end
        maxId = maxId + 1
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- AvailableDbId maxId " .. maxId)
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
    local birth = Chronicles.constants.config.currentYear - age
    local event = {
        id = 0,
        label = "Birth of " .. name,
        description = {"Birth of " .. name .. " \n\nImported from " .. addon},
        yearStart = birth,
        yearEnd = birth,
        eventType = 5
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
