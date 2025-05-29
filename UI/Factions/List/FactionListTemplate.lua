local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-----------------------------------------------------------------------------------------
-- Templates ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

FactionListItemMixin = {}
function FactionListItemMixin:Init(factionData)
	self.Text:SetText(factionData.faction.name)
	self.Faction = factionData.faction
end

function FactionListItemMixin:OnClick()
	-- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		private.Core.StateManager.setState("ui.selectedFaction", self.Faction, "Faction selected from list")
	end
end

-----------------------------------------------------------------------------------------
-- FactionList --------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
FactionListMixin = {}
function FactionListMixin:OnLoad()
	self.PagedFactionList:SetElementTemplateData(private.constants.templates)

	-- Register for timeline clean events to refresh faction data
	private.Core.registerCallback(private.constants.events.TimelineClean, self.OnTimelineClean, self)

	-- Load initial data
	self:LoadFactions()
end

function FactionListMixin:LoadFactions()
	-- Get all factions using the data search function
	local factions = Chronicles.Data:SearchFactions()
	if not factions then
		private.Core.Logger.warn("FactionList", "No faction data available")
		return
	end

	local content = {
		elements = {}
	}
	-- Create list items for each faction
	for key, faction in pairs(factions) do
		if faction and type(faction) == "table" and faction.name then
			local factionSummary = {
				templateKey = private.constants.templateKeys.FACTION_LIST_ITEM,
				name = faction.name,
				faction = faction
			}
			table.insert(content.elements, factionSummary)
		else
			private.Core.Logger.warn("FactionList", "Invalid faction data at key: " .. tostring(key))
		end
	end

	local data = {}
	table.insert(data, content)
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	-- Protected call to SetDataProvider to ensure safety
	local success, errorMsg =
		pcall(
		function()
			self.PagedFactionList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)

	if not success then
		private.Core.Logger.error("FactionList", "Error setting faction list data - " .. tostring(errorMsg))
	else
		private.Core.Logger.info("FactionList", "Faction list loaded successfully with " .. #content.elements .. " factions")
	end
end

function FactionListMixin:OnTimelineClean()
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedFactionList:SetDataProvider(dataProvider, retainScrollPosition)
end
