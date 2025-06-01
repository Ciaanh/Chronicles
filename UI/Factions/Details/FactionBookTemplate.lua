local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

FactionDetailPageMixin = {}

function FactionDetailPageMixin:OnLoad()
	self.PagedFactionDetails:SetElementTemplateData(private.constants.templates)
	-- Use state-based subscription for faction selection
	-- This provides a single source of truth for the selected faction
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedFaction",
			function(newFactionId, oldFactionId)
				if newFactionId then
					-- Fetch the full faction object from the ID
					local factionData = self:GetFactionById(newFactionId)
					if factionData then
						self:OnFactionSelected(factionData)
					end
				end
			end,
			"FactionDetailPageMixin"
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

function FactionDetailPageMixin:GetFactionById(factionId)
	-- Use the Chronicles Data API to find the faction by ID
	if Chronicles and Chronicles.Data then
		local factions = Chronicles.Data:SearchFactions()
		if factions then
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
