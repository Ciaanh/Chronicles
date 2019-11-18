local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.DB = {}

Chronicles.DB.Events = {}

GlobalEventsDB = {
    --[[ structure:
		[eventId] = {
			label=[string], 			-- label: text that'll be the label
			description=table[string], 	-- description: text that give informations about the event
			icon=[string], 				-- the pre-define icon type which can be found in Constant.lua
			yearStart=[integer],		-- 
			yearEnd=[integer],			-- 
			eventType=[string],			-- type of event defined in constants

		},
	--]]
    [1] = {
        label = L["Custom Event"],
        description = {L["Custom Event page 1"], L["Custom Event page 2"]},
        icon = "research",
        yearStart = -7,
        yearEnd = -15,
        eventType = Chronicles.constants.eventType.other
    }
}

function Chronicles.DB:InitDB()

    -- Get infos from TRP or MRP
    -- if (TRP) then
    --     local age = GetAge()
    --     local name = GetName()
    --     -- compare date with current year 
    --     local birth = Chronicles.constants.timeline.yearEnd - age

    --     local event = {
    --         label = "Birth of " .. name,
    --         description = {"Custom Event page 1"},
    --         icon = "research",
    --         yearStart = birth,
    --         yearEnd = birth,
    --         eventType = Chronicles.constants.eventType.birth
    --     }

    --     self:AddLocalEvent(event)
    -- end

    self:RegisterEventDB("Global", GlobalEventsDB)
end

-----------------------------------------------------------------------------------------
-- Events Tools -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function Chronicles.DB:AddLocalEvent(event)
    -- check max index and set it to event
    table.insert(GlobalEventsDB, Chronicles.DB:CleanEventObject(event, "Global"))
end

-- Should return a list of objects :
-- { label, yearStart, yearEnd, description, eventType, icon, source }
function Chronicles.DB:SearchEvents(yearStart, yearEnd)
    local nbFoundEvents = 0
    local foundEvents = {}

    if (yearStart <= yearEnd) then
        for groupName in pairs(self.DB.Events) do
            local pluginEvents = Chronicles.DB:SearchEventsInDB(yearStart,
                                                                yearEnd, self.DB
                                                                    .Events[groupName])

            for eventIndex in pairs(pluginEvents) do
                local event = pluginEvents[eventIndex]
                table.insert(foundEvents,
                             Chronicles.DB:CleanEventObject(event, groupName))
                nbFoundEvents = nbFoundEvents + 1
            end
        end
    end
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Found events " .. nbFoundEvents)
    return foundEvents
end

function Chronicles.DB:SearchEventsInDB(yearStart, yearEnd, db)
    local selectedEvents = {}
    for eventIndex in pairs(db) do
        if Chronicles.DB:IsInRange(db[eventIndex], yearStart, yearEnd) then
            table.insert(selectedEvents, db[eventIndex])
        end
    end
    return selectedEvents
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
    if self.DB.Events[groupName] ~= nil then
        error(groupName .. " is already registered by another plugin.")
    else
        self.DB.Events[groupName] = db
    end
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

