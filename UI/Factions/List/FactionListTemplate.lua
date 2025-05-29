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
	-- Set element template data first
	self.PagedFactionList:SetElementTemplateData(private.constants.templates)

	-- Register for timeline clean events to refresh faction data
	private.Core.registerCallback(private.constants.events.TimelineClean, self.OnTimelineClean, self)

	-- Wait a frame to ensure the ViewFrames are properly initialized
	C_Timer.After(
		0,
		function()
			self:LoadFactions()
		end
	)
end

function FactionListMixin:LoadFactions()
	if not self.PagedFactionList then
		private.Core.Logger.error("FactionList", "PagedFactionList frame not found")
		return
	end

	-- Safety check: Ensure ViewFrames is initialized before proceeding
	if not self.PagedFactionList.ViewFrames then
		private.Core.Logger.warn("FactionList", "ViewFrames not initialized for PagedFactionList, attempting retry...")
		-- Retry after a short delay to allow for proper initialization
		C_Timer.After(
			0.1,
			function()
				if self.PagedFactionList.ViewFrames then
					self:LoadFactions()
				else
					private.Core.Logger.error("FactionList", "ViewFrames still not initialized after retry")
				end
			end
		)
		return
	end

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
		local factionSummary = {
			templateKey = private.constants.templateKeys.FACTION_LIST_ITEM,
			name = faction.name,
			faction = faction
		}
		table.insert(content.elements, factionSummary)
	end

	-- Protected call to SetDataProvider to catch any remaining errors
	local success, errorMsg =
		pcall(
		function()
			local dataProvider = CreateDataProvider(content.elements)
			local retainScrollPosition = false
			self.PagedFactionList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)
	if not success then
		private.Core.Logger.error("FactionList", "Error setting data provider - " .. tostring(errorMsg))
	else
		private.Core.Logger.info("FactionList", "Successfully loaded " .. #content.elements .. " factions")
	end
end

function FactionListMixin:OnTimelineClean()
	-- Clear the faction list data when timeline is cleaned
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	-- Protected call to SetDataProvider to ensure safety
	local success, errorMsg =
		pcall(
		function()
			if self.PagedFactionList and self.PagedFactionList.ViewFrames then
				self.PagedFactionList:SetDataProvider(dataProvider, retainScrollPosition)
			end
		end
	)
	if not success then
		private.Core.Logger.error("FactionList", "Error clearing faction list data - " .. tostring(errorMsg))
	else
		private.Core.Logger.info("FactionList", "Faction list data cleared for timeline clean")
	end
end
