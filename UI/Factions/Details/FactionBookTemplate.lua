local FOLDER_NAME, private = ...

local Chronicles = private.Chronicles

FactionDetailPageMixin = {}

function FactionDetailPageMixin:OnLoad()
	self.PagedFactionDetails:SetElementTemplateData(private.constants.templates)
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			private.Core.StateManager.buildSelectionKey("faction"),
			function(newFactionSelection, oldFactionSelection)
				if newFactionSelection then
					local factionData = nil

					if type(newFactionSelection) == "table" and newFactionSelection.factionId and newFactionSelection.collectionName then
						local factionId = newFactionSelection.factionId
						local collectionName = newFactionSelection.collectionName
						factionData = self:GetFactionById(factionId, collectionName)
					else
						local factionId = type(newFactionSelection) == "table" and newFactionSelection.factionId or newFactionSelection
						if factionId then
							factionData = self:GetFactionById(factionId)
						end
					end

					if factionData then
						self:OnFactionSelected(factionData)
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
	if Chronicles and Chronicles.Data then
		local factions = Chronicles.Data:SearchFactions()
		if factions then
			if collectionName then
				for _, faction in pairs(factions) do
					if faction.id == factionId and faction.source == collectionName then
						return faction
					end
				end
			end

			for _, faction in pairs(factions) do
				if faction.id == factionId then
					return faction
				end
			end
		end
	end

	return nil
end

function FactionDetailPageMixin:OnFactionSelected(data)
	local content = private.Core.Factions.TransformFactionToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedFactionDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
