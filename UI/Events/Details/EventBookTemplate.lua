local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

EventBookMixin = {}

function EventBookMixin:OnLoad()
	self.PagedEventDetails:SetElementTemplateData(private.constants.templates)

	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
	-- Use state-based subscription for event selection
	-- This provides a single source of truth for the selected event
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedEvent",
			function(newEventId, oldEventId)
				if newEventId then
					-- Fetch the full event object from the ID
					local eventData = self:GetEventById(newEventId)
					if eventData then
						self:OnEventSelected(eventData)
					end
				else
					self:OnUIRefresh()
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

function EventBookMixin:GetEventById(eventId)
	-- Use the Chronicles Data API to find the event by ID
	if Chronicles and Chronicles.Data then
		-- Search all events across the entire timeline
		local events = Chronicles.Data:SearchEvents()
		if events then
			for _, event in pairs(events) do
				if event.id == eventId then
					return event
				end
			end
		end
	end
	return nil
end

function EventBookMixin:OnEventSelected(data)
	local content = private.Core.Events.TransformEventToBook(data)
	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end

function EventBookMixin:OnUIRefresh()
	local data = private.Core.Events.EmptyBook()
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
