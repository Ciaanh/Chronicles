local FOLDER_NAME, private = ...
-- -------------------------
-- Templates
-- -------------------------

FactionListItemMixin = {}
function FactionListItemMixin:Init(factionData)
	self.Text:SetText(factionData.faction.name)
	self.Faction = factionData.faction
end

function FactionListItemMixin:OnClick()
	if private.Core.StateManager then
		local factionId = self.Faction and self.Faction.id or nil
		local collectionName = self.Faction and self.Faction.source or nil
		if factionId and collectionName then
			private.Core.StateManager.setState(
				private.Core.StateManager.buildSelectionKey("faction"),
				{factionId = factionId, collectionName = collectionName},
				"Faction selected from list"
			)
		end
	end
end

-- -------------------------
-- FactionList
-- -------------------------
FactionListMixin = {}
function FactionListMixin:OnLoad()
	self.PagedFactionList:SetElementTemplateData(private.constants.templates)
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	self:LoadFactions()
end

function FactionListMixin:LoadFactions()
	local factions = private.Chronicles.Data:SearchFactions()
	if not factions then
		return
	end

	local content = {
		elements = {}
	}

	for key, faction in pairs(factions) do
		if faction and type(faction) == "table" and faction.name then
			local factionSummary = {
				templateKey = private.constants.templateKeys.FACTION_LIST_ITEM,
				name = faction.name,
				faction = faction
			}
			table.insert(content.elements, factionSummary)
		end
	end

	local data = {}
	table.insert(data, content)
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	local success, errorMsg =
		pcall(
		function()
			self.PagedFactionList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)
end

function FactionListMixin:OnUIRefresh()
	self:LoadFactions()
end
