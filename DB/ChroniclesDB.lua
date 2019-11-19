local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}

Chronicles.DB.Events = {}

GlobalEventsDB = {
    --[[ structure:
		[eventId] = {
            id=[integer],				-- Id of the event
			label=[string], 			-- label: text that'll be the label
			description=table[string], 	-- description: text that give informations about the event
			icon=[string], 				-- the pre-define icon type which can be found in Constant.lua
			yearStart=[integer],		-- 
			yearEnd=[integer],			-- 
			eventType=[string],			-- type of event defined in constants

		},
	--]]
    [1] = {
        id = 1,
        label = Locale["Dark Portal label"],
        description = {Locale["Dark Portal page 1"], Locale["Dark Portal page 2"]},
        icon = "research",
        yearStart = 0,
        yearEnd = 0,
        eventType = Chronicles.constants.eventType.other
    }
}

function tablelength(T)
    local count = 0
    if (T ~= nil) then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end

function Chronicles.DB:InitDB()
    -- Get infos from TRP or MRP
    -- if (TRP) then
    --     local age = GetAge()
    --     local name = GetName()
    --     -- compare date with current year
    --     local birth = Chronicles.constants.timeline.yearEnd - age
    --     local event = {
    --         label = "Birth of " .. name,
    --         description = {"Birth of ".. name .. " imported from TRP"},
    --         icon = "research",
    --         yearStart = birth,
    --         yearEnd = birth,
    --         eventType = Chronicles.constants.eventType.birth
    --     }
    --     self:AddGlobalEvent(event)
    -- end

    -- if (MRP) then
    --     local age = GetAge()
    --     local name = GetName()
    --     -- compare date with current year
    --     local birth = Chronicles.constants.timeline.yearEnd - age
    --     local event = {
    --         label = "Birth of " .. name,
    --         description = {"Birth of ".. name .. " imported from MRP"},
    --         icon = "research",
    --         yearStart = birth,
    --         yearEnd = birth,
    --         eventType = Chronicles.constants.eventType.birth
    --     }
    --     self:AddGlobalEvent(event)
    -- end

    self:RegisterEventDB("Global", GlobalEventsDB)
end

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AddGlobalEvent(event)
    -- check max index and set it to event
    event.id = table.maxn(GlobalEventsDB) + 1
    table.insert(GlobalEventsDB, Chronicles.DB:CleanEventObject(event, "Global"))
end

-- Should return a list of objects :
-- { label, yearStart, yearEnd, description, eventType, icon, source }
function Chronicles.DB:SearchEvents(yearStart, yearEnd)
    local nbFoundEvents = 0
    local foundEvents = {}

    if (yearStart <= yearEnd) then
        for groupName in pairs(self.Events) do
            local pluginEvents = Chronicles.DB:SearchEventsInDB(yearStart, yearEnd, self.Events[groupName])

            for eventIndex in pairs(pluginEvents) do
                local event = pluginEvents[eventIndex]
                table.insert(foundEvents, Chronicles.DB:CleanEventObject(event, groupName))
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
        if Chronicles.DB:IsInRange(db[eventIndex], yearStart, yearEnd) then
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

-- if _G["TRP3_API"] then state.trp3  = true table.insert(rpClients,  "trp3" ) state.trp3_Version  = GetAddOnMetadata("totalRP3",   "Version") or "Unknown" end;

--     function GetCharacteristics()
--         return TRP3_API.profile.getPlayerCurrentProfile();
--     end

--     function GetName()
--         local name, realm = UnitName("player");
--         return name;
--     end

--     function GetFirstName()
--         local characteristics = GetCharacteristics();
--         if characteristics  then
--             return characteristics.FN;
--         end
--     end

--     function GetLastName()
--         local characteristics = GetCharacteristics();
--         if characteristics then
--             return characteristics.LN
--         end
--     end

--     function GetRoleplayingName()
--         local name = GetFirstName() or GetName();
--         if GetLastName() then
--             name = name .. " " .. GetLastName();
--         end
--         return name
--     end

--     function GetAge()
--         local characteristics = GetCharacteristics();
--         if characteristics  then
--             return characteristics.AG;
--         end
--     end

-- if _G["mrp"]      then state.mrp   = true table.insert(rpClients,  "mrp"  ) state.mrp_Version   = GetAddOnMetadata("MyRolePlay", "Version") or "Unknown" end;
--         if state.mrp
--         then
--         end

--     function GetRoleplayingName()
--         return msp.my["NA"];
--     end

--     function GetAge()
--         return msp.my["AG"];
--     end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
