local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

FactionDetailPageMixin = {}

function FactionDetailPageMixin:OnLoad()
	self.PagedFactionDetails:SetElementTemplateData(private.constants.templates) -- Use state-based subscription for faction selection
	-- This provides a single source of truth for the selected faction
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedFaction",
			function(newFactionSelection, oldFactionSelection)
				if newFactionSelection then
					local factionData = nil

					-- Handle both new format {factionId, collectionName} and legacy format (just ID)
					if type(newFactionSelection) == "table" and newFactionSelection.factionId and newFactionSelection.collectionName then
						-- New format with collection-specific lookup
						local factionId = newFactionSelection.factionId
						local collectionName = newFactionSelection.collectionName
						private.Core.Logger.trace(
							"FactionBook",
							"Faction selection received - ID: " .. factionId .. ", Collection: " .. collectionName
						)
						factionData = self:GetFactionById(factionId, collectionName)
					else
						-- Legacy format or fallback - treat as just faction ID
						local factionId = type(newFactionSelection) == "table" and newFactionSelection.factionId or newFactionSelection
						if factionId then
							private.Core.Logger.trace("FactionBook", "Faction selection received (legacy format) - ID: " .. factionId)
							factionData = self:GetFactionById(factionId)
						end
					end

					if factionData then
						self:OnFactionSelected(factionData)
					else
						private.Core.Logger.warn("FactionBook", "Could not find faction data for selection")
					end
				end
			end
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedFactionDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function FactionDetailPageMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function FactionDetailPageMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

function FactionDetailPageMixin:GetFactionById(factionId, collectionName)
	-- Use the Chronicles Data API to find the faction by ID
	if Chronicles and Chronicles.Data then
		local factions = Chronicles.Data:SearchFactions()
		if factions then
			-- If collection name is provided, try direct lookup first for performance
			if collectionName then
				private.Core.Logger.trace(
					"FactionBook",
					"Attempting direct collection lookup for faction ID: " .. factionId .. " in collection: " .. collectionName
				)

				for _, faction in pairs(factions) do
					if faction.id == factionId and faction.source == collectionName then
						private.Core.Logger.trace("FactionBook", "Found faction via direct collection lookup")
						return faction
					end
				end

				private.Core.Logger.warn("FactionBook", "Faction not found in specified collection, falling back to general search")
			end

			-- Fallback: search through all factions (maintains backward compatibility)
			for _, faction in pairs(factions) do
				if faction.id == factionId then
					if collectionName then
						private.Core.Logger.trace("FactionBook", "Found faction via fallback search (different collection than expected)")
					end
					return faction
				end
			end
		end
	end

	if collectionName then
		private.Core.Logger.error(
			"FactionBook",
			"Faction not found - ID: " .. factionId .. ", Collection: " .. collectionName
		)
	else
		private.Core.Logger.error("FactionBook", "Faction not found - ID: " .. factionId)
	end
	return nil
end

function FactionDetailPageMixin:OnFactionSelected(data)
	local content = private.Core.Factions.TransformFactionToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedFactionDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
