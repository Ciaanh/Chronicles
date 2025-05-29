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
			function(newFaction, oldFaction)
				if newFaction then
					self:OnFactionSelected(newFaction)
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

function FactionDetailPageMixin:OnFactionSelected(data)
	local content = private.Core.Factions.TransformFactionToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedFactionDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
