local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}
Chronicles.DB.Events = {}
Chronicles.DB.RP = {}

function Chronicles.DB:InitDB()
    --self:LoadRolePlayProfile()
    self:RegisterEventDB("Global", GlobalEventsDB)
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AddGlobalEvent(event)
    -- check max index and set it to event
    if (event.id == nil) then
        event.id = table.maxn(GlobalEventsDB) + 1
    end
    table.insert(GlobalEventsDB, event.id, self:CleanEventObject(event, "Global"))
end

function Chronicles.DB:HasEvents(yearStart, yearEnd)
    if (yearStart <= yearEnd) then
        for groupName in pairs(self.Events) do
            local eventsGroup = self.Events[groupName]

            if (eventsGroup.isActive and self:HasEventsInDB(yearStart, yearEnd, eventsGroup.data)) then
                return true
            end
        end
    end
    return false
end

function Chronicles.DB:HasEventsInDB(yearStart, yearEnd, db)
    for eventIndex in pairs(db) do
        if self:IsInRange(db[eventIndex], yearStart, yearEnd) then
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
        for groupName in pairs(self.Events) do
            local eventsGroup = self.Events[groupName]

            local pluginEvents = self:SearchEventsInDB(yearStart, yearEnd, eventsGroup.data)

            for eventIndex in pairs(pluginEvents) do
                local event = pluginEvents[eventIndex]
                table.insert(foundEvents, self:CleanEventObject(event, groupName))
                nbFoundEvents = nbFoundEvents + 1
            end
        end
    end
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Found events " .. nbFoundEvents)
    return foundEvents
end

function Chronicles.DB:SearchEventsInDB(yearStart, yearEnd, db)
    local foundEvents = {}
    for eventIndex in pairs(db) do
        if self:IsInRange(db[eventIndex], yearStart, yearEnd) then
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
        error(groupName .. " is already registered by another plugin.")
    else
        self.Events[groupName] = {
            data = db,
            name = groupName,
            isActive = true
        }
    end

    Chronicles.UI:Init()
end

function Chronicles.DB:GetEventGroupNames()
    local dataGroups = {}
    for groupName in pairs(self.Events) do
        local group = self.Events[groupName]

        local groupProjection = {
            name = group.name,
            isActive = group.isActive
        }
        table.insert(dataGroups, groupProjection)
        --DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register group " .. groupProjection.name)
    end


    
    table.insert(dataGroups, { name = "dummy 1", isActive = false })
    table.insert(dataGroups, { name = "dummy 2", isActive = false })
    table.insert(dataGroups, { name = "dummy 3", isActive = false })
    table.insert(dataGroups, { name = "dummy 4", isActive = false })
    table.insert(dataGroups, { name = "dummy 56789101112131415", isActive = false })

    return dataGroups
end

function Chronicles.DB:SetGroupStatus(groupName, status)

    --DEFAULT_CHAT_FRAME:AddMessage("-- SetGroupStatus " .. groupName .. " " .. tostring(status))

    if self.Events[groupName] ~= nil then
        self.Events[groupName].isActive = status
    else
        error(groupName .. " does not exist as a data group.")
    end
end

function Chronicles.DB:GetGroupStatus(groupName)
    if self.Events[groupName] ~= nil then
        --DEFAULT_CHAT_FRAME:AddMessage("-- GetGroupStatus " .. groupName .. " " .. tostring(self.Events[groupName].isActive))

        return self.Events[groupName].isActive
    else
        error(groupName .. " does not exist as a data group.")
    end
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

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
        eventType = Chronicles.constants.eventType.birth
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
