local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

SinglePageFrameMixin = {}
local Templates = {
	["TITLE"] = {template = "BookTitleTemplate", initFunc = BookTitleMixin.Init},
	["HEADER"] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	["TEXTCONTENT"] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init},
	["HTMLCONTENT"] = {template = "HtmlPageTemplate", initFunc = HtmlPageMixin.Init}
}

function SinglePageFrameMixin:OnLoad()
	self.PagedSinglePageFrame:SetElementTemplateData(Templates)

	EventRegistry:RegisterCallback(private.events.SinglePageFrameEventSelected, self.OnEventSelected, self)

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedSinglePageFrame.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function SinglePageFrameMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function SinglePageFrameMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

function SinglePageFrameMixin:OnEventSelected(eventData)
	self:ShowEvent(eventData)
end

function SinglePageFrameMixin:ShowEvent(data)
	local content = TransformEventToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedSinglePageFrame:SetDataProvider(dataProvider, retainScrollPosition)
end
