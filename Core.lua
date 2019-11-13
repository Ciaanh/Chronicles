local FOLDER_NAME, private = ...

-- Init libs ---------------------------------------------------------------------------
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local I = LibStub("LibDBIcon-1.0")

local Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
private.Core = Chronicles

Chronicles.constants = private.constants
Chronicles.descName = L["Chronicles"]
Chronicles.description = L["Display Azeroth history as a timeline"]

Chronicles.SelectedValues = {
	currentTimelinePage = 1,
	currentTimelineYear = Chronicles.constants.timeline.yearStart,
	timelineStep = Chronicles.constants.timeline.defaultStep,
	eventId = nil
}

local _db
local _options
local _defaults = {
	global = {
		options = {
			version = "",
			minimap = {
				hide = false
			}
		}
	}
}

function tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

----------------------------------------------------------------------------------------

Chronicles.UI = {}
Chronicles.pluginsDB = {}

function Chronicles.UI:Init()
	Chronicles.UI.Timeline:DsiplayTimeline()
end

function Chronicles.UI:DisplayWindow()
	Chronicles_UI:Show()
end

function Chronicles.UI:HideWindow()
	Chronicles_UI:Hide()
end

function Chronicles:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ChroniclesDB", _defaults, true)

	self.mapIcon =
		LibStub("LibDataBroker-1.1"):NewDataObject(
		FOLDER_NAME,
		{
			type = "launcher",
			text = "Chronicles",
			icon = "Interface\\ICONS\\Inv_scroll_04",
			OnClick = function(self, button, down)
				if (Chronicles_UI:IsVisible()) then
					Chronicles.UI:HideWindow()
				else
					Chronicles.UI:DisplayWindow()
				end
			end,
			OnTooltipShow = function(tt)
				tt:AddLine("Chronicles", 1, 1, 1)
				tt:AddLine("Click to show the timeline.")
			end
		}
	)
	I:Register(FOLDER_NAME, self.mapIcon, self.db.global.options.minimap)

	Chronicles.UI:Init()

	self:RegisterChatCommand(
		"chronicles",
		function()
			self.UI:DisplayWindow()
		end
	)
end

-- External DB tools -------------------------------------------------------------------
function Chronicles:RegisterPluginDB(pluginName, db)
	--DEFAULT_CHAT_FRAME:AddMessage("-- Asked to register plugin " .. pluginName)
	if self.pluginsDB[pluginName] ~= nil then
		error(pluginName .. " is already registered by another plugin.")
	else
		self.pluginsDB[pluginName] = db
	end
end
-----------------------------------------------------------------------------------------

-- Should return a list of objects :
-- { label, yearStart, yearEnd, description, eventType, icon, source }
function Chronicles:SearchEvents(yearStart, yearEnd)
	local foundEvents = {}
	if (yearStart <= yearEnd) then
		for pluginName in pairs(self.pluginsDB) do
			local pluginEvents = Chronicles:SearchEventsInDB(yearStart, yearEnd, self.pluginsDB[pluginName])

			for eventIndex in pairs(pluginEvents) do
				local event = pluginEvents[eventIndex]
				table.insert(foundEvents, Chronicles:CleanEventObject(event, pluginName))
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("-- Found events " .. tablelength(foundEvents))
	return foundEvents
end

function Chronicles:SearchEventsInDB(yearStart, yearEnd, db)
	local selectedEvents = {}
	for eventIndex in pairs(db) do
		if Chronicles:IsInRange(db[eventIndex], yearStart, yearEnd) then
			table.insert(selectedEvents, db[eventIndex])
		end
	end
	return selectedEvents
end

function Chronicles:IsInRange(event, yearStart, yearEnd)
	if (yearStart <= event.yearStart and event.yearStart <= yearEnd) then
		return true
	end
	if (yearStart <= event.yearEnd and event.yearEnd <= yearEnd) then
		return true
	end
	return false
end

function Chronicles:CleanEventObject(event, pluginName)
	if event then
		local description = event.description or UNKNOWN
		local icon = event.icon or private.constants.defaultIcon

		return {
			label = event.label,
			yearStart = event.yearStart,
			yearEnd = event.yearEnd,
			description = description,
			eventType = event.eventType,
			icon = icon,
			source = pluginName
		}
	end
end
