local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

FactionDetailPageMixin = {}

function FactionDetailPageMixin:OnLoad()
	self.PagedFactionDetails:SetElementTemplateData(private.constants.templates)

	EventRegistry:RegisterCallback(private.constants.events.FactionSelected, self.OnFactionSelected, self)

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

