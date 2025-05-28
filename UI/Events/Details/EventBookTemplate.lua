local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

EventBookMixin = {}

function EventBookMixin:OnLoad()
	self.PagedEventDetails:SetElementTemplateData(private.constants.templates)

	-- Use safe event registration
	private.Core.registerCallback(private.constants.events.EventSelected, self.OnEventSelected, self)
	private.Core.registerCallback(private.constants.events.TimelineClean, self.OnTimelineClean, self)
	
	-- Subscribe to state changes for the selected event
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedEvent",
			function(newEvent, oldEvent)
				if newEvent then
					self:OnEventSelected(newEvent)
				end
			end,
			"EventBookMixin"
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedEventDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function EventBookMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function EventBookMixin:OnPagingButtonLeave()
	local reverse = true

	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

function EventBookMixin:OnEventSelected(data)
	local content = private.Core.Events.TransformEventToBook(data)
	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end

function EventBookMixin:OnTimelineClean()
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
