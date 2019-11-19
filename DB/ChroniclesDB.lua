local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}
Chronicles.DB.Events = {}
Chronicles.DB.RP = {}

function Chronicles.DB:InitDB()
    self:LoadRolePlayProfile()
    self:RegisterEventDB("Global", GlobalEventsDB)
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AddGlobalEvent(event)
    -- check max index and set it to event
    event.id = table.maxn(GlobalEventsDB) + 1
    table.insert(GlobalEventsDB, self:CleanEventObject(event, "Global"))
end

-- Should return a list of objects :
-- { label, yearStart, yearEnd, description, eventType, icon, source }
function Chronicles.DB:SearchEvents(yearStart, yearEnd)
    local nbFoundEvents = 0
    local foundEvents = {}

    if (yearStart <= yearEnd) then
        for groupName in pairs(self.Events) do
            local pluginEvents = self:SearchEventsInDB(yearStart, yearEnd, self.Events[groupName])

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
        local icon = event.icon or private.constants.defaultIcon

        return {
            id = event.id,
            label = event.label,
            yearStart = event.yearStart,
            yearEnd = event.yearEnd,
            description = description,
            eventType = event.eventType,
            icon = icon,
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
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register group " .. groupName)
    if self.Events[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin.")
    else
        self.Events[groupName] = db
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

    -- if _G["TRP3_API"] then state.trp3 = true state.trp3_Version = GetAddOnMetadata("totalRP3", "Version") or "Unknown" end;
    if (_G["TRP3_API"]) then
        local age = Chronicles.DB.RP:TRP_GetAge()
        local name = Chronicles.DB.RP:TRP_GetRoleplayingName()

        if( age ~= nil and name ~= nil) then
            self.RP:RegisterBirth(age, name)
        end
    end

    -- if _G["mrp"] then state.mrp = true state.mrp_Version = GetAddOnMetadata("MyRolePlay", "Version") or "Unknown" end;
    if (_G["mrp"]) then
        local age = Chronicles.DB.RP:MRP_GetAge()
        local name = Chronicles.DB.RP:MRP_GetRoleplayingName()
        
        if( age ~= nil and name ~= nil) then
            self.RP:RegisterBirth(age, name)
        end
    end
end

function Chronicles.DB.RP:RegisterBirth(age, name) 
    -- compare date with current year
    local birth = Chronicles.constants.timeline.yearEnd - age
    local event = {
        label = "Birth of " .. name,
        description = {"Birth of " .. name .. " imported from MRP"},
        icon = "research",
        yearStart = birth,
        yearEnd = birth,
        eventType = Chronicles.constants.eventType.birth
    }
    Chronicles.DB:AddGlobalEvent(event)
end

function Chronicles.DB.RP:MRP_GetRoleplayingName() return msp.my["NA"] end

function Chronicles.DB.RP:MRP_GetAge() return msp.my["AG"] end

function Chronicles.DB.RP:GetName()
    local name, realm = UnitName("player")
    return name
end

function Chronicles.DB.RP:TRP_GetCharacteristics()
    return TRP3_API.profile.getPlayerCurrentProfile()
end

function Chronicles.DB.RP:TRP_GetFirstName()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()
    if characteristics then return characteristics.FN end
end

function Chronicles.DB.RP:TRP_GetLastName()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()
    if characteristics then return characteristics.LN end
end

function Chronicles.DB.RP:TRP_GetRoleplayingName()
    local name = Chronicles.DB.RP:TRP_GetFirstName() or
                     Chronicles.DB.RP:GetName()
    if Chronicles.DB.RP:TRP_GetLastName() then
        name = name .. " " .. Chronicles.DB.RP:TRP_GetLastName()
    end
    return name
end

function Chronicles.DB.RP:TRP_GetAge()
    local characteristics = Chronicles.DB.RP:TRP_GetCharacteristics()
    if characteristics then return characteristics.AG end
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
