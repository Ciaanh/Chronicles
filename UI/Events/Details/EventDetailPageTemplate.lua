local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

EventDetailPageMixin = {}

function EventDetailPageMixin:OnLoad()
	self.PagedEventDetails:SetElementTemplateData(private.constants.templates)

	EventRegistry:RegisterCallback(private.constants.events.EventDetailPageEventSelected, self.OnEventSelected, self)

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedEventDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function EventDetailPageMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function EventDetailPageMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

function EventDetailPageMixin:OnEventSelected(data)
	local content = private.Core.Events.TransformEventToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
