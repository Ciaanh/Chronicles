local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.Data = {}
Chronicles.Data.Events = {}
Chronicles.Data.Factions = {}
Chronicles.Data.Characters = {}
Chronicles.Data.RP = {}

RPEventsDB = {}

function Chronicles.Data:Init()
    self:RegisterEventDB("RP", RPEventsDB)

    -- load data for my journal
    self:RegisterEventDB("myjournal", Chronicles.Data:GetMyJournalEvents())
    self:RegisterFactionDB("myjournal", Chronicles.Data:GetMyJournalFactions())
    self:RegisterCharacterDB("myjournal", Chronicles.Data:GetMyJournalCharacters())

    if (Chronicles.Custom ~= nil and Chronicles.Custom.DB ~= nil) then
        Chronicles.Custom.DB:Init()
    end

    Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
end

function Chronicles.Data:RefreshPeriods()
    Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.Data:AvailableDbId(db)
end

function Chronicles.Data:AddRPEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(RPEventsDB) + 1
    end
    table.insert(RPEventsDB, event.id, self:CleanEventObject(event, "RP"))
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
    if (yearStart <= yearEnd) then
        local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
        local hasEventsInDB = Chronicles.Data.HasEventsInDB

        for libraryName, eventsGroup in pairs(Chronicles.Data.Events) do
            local isActive = GetLibraryStatus(self, libraryName)
            if (isActive and hasEventsInDB(self, yearStart, yearEnd, eventsGroup.data)) then
                return true
            end
        end
    end
    return false
end

function Chronicles.Data:HasEventsInDB(yearStart, yearEnd, db)
    local getEventTypeStatus = Chronicles.Data.GetEventTypeStatus
    local isInRange = Chronicles.Data.IsInRange
    for eventIndex, event in pairs(db) do
        local isEventTypeActive = getEventTypeStatus(self, event.eventType)

        if isEventTypeActive and isInRange(self, db[eventIndex], yearStart, yearEnd) then
            return true
        end
    end
    return false
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
    local foundEvents = {}
    local searchEventsInDB = Chronicles.Data.SearchEventsInDB
    local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
    local cleanEventObject = Chronicles.Data.CleanEventObject

    if (yearStart <= yearEnd) then
        -- filter groupname ?
        for libraryName, eventsGroup in pairs(Chronicles.Data.Events) do
            -- local isActive = GetLibraryStatus(self, libraryName)

            -- if (isActive) then
                local pluginEvents = searchEventsInDB(self, yearStart, yearEnd, eventsGroup.data)

                for eventIndex, event in pairs(pluginEvents) do
                    table.insert(foundEvents, cleanEventObject(self, event, libraryName))
                end
            --end
        end
    end
    return foundEvents
end

function Chronicles.Data:SearchEventsInDB(yearStart, yearEnd, db)
    local foundEvents = {}
    local getEventTypeStatus = Chronicles.Data.GetEventTypeStatus
    local isInRange = Chronicles.Data.IsInRange

    for eventIndex, event in pairs(db) do
        local isEventTypeActive = getEventTypeStatus(self, event.eventType)

        if isEventTypeActive and isInRange(self, db[eventIndex], yearStart, yearEnd) then
            table.insert(foundEvents, db[eventIndex])
        end
    end
    return foundEvents
end

function Chronicles.Data:IsInRange(event, yearStart, yearEnd)
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

function Chronicles.Data:CleanEventObject(event, libraryName)
    if event then
        local description = event.description or UNKNOWN

        local start = event.yearStart
        local finish = event.yearEnd

        local formatedEvent = {
            id = event.id,
            label = event.label,
            yearStart = start,
            yearEnd = finish,
            description = description,
            chapters = event.chapters,
            eventType = event.eventType,
            factions = event.factions,
            characters = event.characters,
            source = libraryName,
            order = event.order,
            author = event.author
        }
        if (event.order == nil) then
            formatedEvent.order = 0
        end

        return formatedEvent
    end
end

-- Search factions ----------------------------------------------------------------------

function Chronicles.Data:SearchFactions(name)
    local foundFactions = {}
    local lower = string.lower
    local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
    local cleanFactionObject = Chronicles.Data.CleanFactionObject

    for libraryName, factionsGroup in pairs(Chronicles.Data.Factions) do
        local factionGroupStatus = GetLibraryStatus(self, libraryName)
        if (factionGroupStatus) then
            for factionIndex, faction in pairs(factionsGroup.data) do
                if (name ~= nil and strlen(name) >= MIN_CHARACTER_SEARCH) then
                    if (lower(faction.name):find(lower(name)) ~= nil) then
                        table.insert(foundFactions, cleanFactionObject(self, faction, libraryName))
                    end
                else
                    table.insert(foundFactions, cleanFactionObject(self, faction, libraryName))
                end
            end
        end
    end
    return foundFactions
end

function Chronicles.Data:FindFactions(ids)
    local foundFactions = {}
    local GetLibraryStatus = Chronicles.Data.GetLibraryStatus
    local cleanFactionObject = Chronicles.Data.CleanFactionObject

    for group, factionIds in pairs(ids) do
        local factionGroupStatus = GetLibraryStatus(self, group)
        if (factionGroupStatus) then
            local factionsGroup = Chronicles.Data.Factions[group]
            if (factionsGroup ~= nil and factionsGroup.data ~= nil and tablelength(factionsGroup.data) > 0) then
                for factionIndex, faction in pairs(factionsGroup.data) do
                    for index, id in ipairs(factionIds) do
                        if (faction.id == id) then
                            table.insert(foundFactions, cleanFactionObject(self, faction, group))
                        end
                    end
                end
            end
        end
    end
    return foundFactions
end

function Chronicles.Data:CleanFactionObject(faction, libraryName)
    if faction ~= nil then
        return {
            id = faction.id,
            name = faction.name,
            description = faction.description,
            timeline = faction.timeline,
            source = libraryName
        }
    end
    return nil
end

-- Search characters --------------------------------------------------------------------

function Chronicles.Data:SearchCharacters(name)
    local foundCharacters = {}

    for libraryName, charactersGroup in pairs(self.Characters) do
        local characterGroupStatus = Chronicles.Data:GetLibraryStatus(libraryName)
        if (characterGroupStatus) then
            for characterIndex, character in pairs(charactersGroup.data) do
                if (name ~= nil and strlen(name) >= MIN_CHARACTER_SEARCH) then
                    if (string.lower(character.name):find(string.lower(name)) ~= nil) then
                        table.insert(foundCharacters, Chronicles.Data:CleanCharacterObject(character, libraryName))
                    end
                else
                    table.insert(foundCharacters, Chronicles.Data:CleanCharacterObject(character, libraryName))
                end
            end
        end
    end
    return foundCharacters
end

function Chronicles.Data:FindCharacters(ids)
    local foundCharacters = {}

    for group, characterIds in pairs(ids) do
        local characterGroupStatus = Chronicles.Data:GetLibraryStatus(group)
        if (characterGroupStatus) then
            local charactersGroup = Chronicles.Data.Characters[group]
            if (charactersGroup ~= nil and charactersGroup.data ~= nil and tablelength(charactersGroup.data) > 0) then
                for characterIndex, character in pairs(charactersGroup.data) do
                    for index, id in ipairs(characterIds) do
                        if (character.id == id) then
                            table.insert(foundCharacters, Chronicles.Data:CleanCharacterObject(character, group))
                        end
                    end
                end
            end
        end
    end
    return foundCharacters
end

function Chronicles.Data:CleanCharacterObject(character, libraryName)
    if character ~= nil then
        return {
            id = character.id,
            name = character.name,
            biography = character.biography,
            timeline = character.timeline,
            factions = character.factions,
            source = libraryName
        }
    end
    return nil
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- External DB tools --------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.Data:RegisterEventDB(libraryName, db)
    if Chronicles.Data.Events[libraryName] ~= nil then
        error(libraryName .. " is already registered by another plugin in Events.")
    else
        local isActive = Chronicles.db.global.EventDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.EventDBStatuses[libraryName] = isActive
        end

        Chronicles.Data.Events[libraryName] = {
            data = db,
            name = libraryName
        }
    end
end

function Chronicles.Data:RegisterCharacterDB(libraryName, db)
    if Chronicles.Data.Characters[libraryName] ~= nil then
        error(libraryName .. " is already registered by another plugin in Characters.")
    else
        local isActive = Chronicles.db.global.CharacterDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.CharacterDBStatuses[libraryName] = isActive
        end

        Chronicles.Data.Characters[libraryName] = {
            data = db,
            name = libraryName
        }
    end
end

function Chronicles.Data:RegisterFactionDB(libraryName, db)
    if Chronicles.Data.Factions[libraryName] ~= nil then
        error(libraryName .. " is already registered by another plugin in Factions.")
    else
        local isActive = Chronicles.db.global.FactionDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.FactionDBStatuses[libraryName] = isActive
        end

        Chronicles.Data.Factions[libraryName] = {
            data = db,
            name = libraryName
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

function Chronicles.Data:GetLibrariesNames()
    local dataGroups = {}

    for eventLibraryName, group in pairs(Chronicles.Data.Events) do
        if (eventLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.EventDBStatuses[eventLibraryName]
            }

            Chronicles.Data:SetLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(eventLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    for factionLibraryName, group in pairs(Chronicles.Data.Factions) do
        if (factionLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.FactionDBStatuses[factionLibraryName]
            }

            Chronicles.Data:SetLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(factionLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    for characterLibraryName, group in pairs(Chronicles.Data.Characters) do
        if (characterLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.CharacterDBStatuses[characterLibraryName]
            }

            Chronicles.Data:SetLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not exist_in_table(characterLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    return dataGroups
end

function Chronicles.Data:SetLibraryStatus(libraryName, status)
    if Chronicles.Data.Events[libraryName] ~= nil then
        Chronicles.db.global.EventDBStatuses[libraryName] = status
        Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
    end

    if Chronicles.Data.Factions[libraryName] ~= nil then
        Chronicles.db.global.FactionDBStatuses[libraryName] = status
    end

    if Chronicles.Data.Characters[libraryName] ~= nil then
        Chronicles.db.global.CharacterDBStatuses[libraryName] = status
    end
end

function Chronicles.Data:GetLibraryStatus(libraryName)
    local isEventActive = nil
    local isFactionActive = nil
    local isCharacterActive = nil

    if Chronicles.Data.Events[libraryName] ~= nil then
        local isActive = Chronicles.db.global.EventDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.EventDBStatuses[libraryName] = isActive
            Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
        end
        isEventActive = isActive
    end

    if Chronicles.Data.Factions[libraryName] ~= nil then
        local isActive = Chronicles.db.global.FactionDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.FactionDBStatuses[libraryName] = isActive
        end
        isFactionActive = isActive
    end

    if Chronicles.Data.Characters[libraryName] ~= nil then
        local isActive = Chronicles.db.global.CharacterDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.CharacterDBStatuses[libraryName] = isActive
        end
        isCharacterActive = isActive
    end
    --------------------------------------------------
    if (isEventActive) then
        if Chronicles.Data.Factions[libraryName] ~= nil then
            Chronicles.db.global.FactionDBStatuses[libraryName] = true
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            Chronicles.db.global.CharacterDBStatuses[libraryName] = true
        end
        return true
    end

    if (isFactionActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            Chronicles.db.global.EventDBStatuses[libraryName] = true
            Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            Chronicles.db.global.CharacterDBStatuses[libraryName] = true
        end
        return true
    end

    if (isCharacterActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            Chronicles.db.global.EventDBStatuses[libraryName] = true
            Chronicles.Data.PeriodsFillingBySteps = Chronicles.Data:GetPeriodsFillingBySteps()
        end
        if Chronicles.Data.Factions[libraryName] ~= nil then
            Chronicles.db.global.FactionDBStatuses[libraryName] = true
        end
        return true
    end

    return false
end

function Chronicles.Data:SetEventTypeStatus(eventType, isActive)
    Chronicles.db.global.EventTypesStatuses[eventType] = isActive
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
end

function Chronicles.Data:RemoveMyJournalEvent(eventId)
    Chronicles.Data:RemoveFromMyJournal(eventId, Chronicles.db.global.MyJournalEventDB)
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
