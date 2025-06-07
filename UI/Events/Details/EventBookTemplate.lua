local FOLDER_NAME, private = ...

local Chronicles = private.Chronicles

EventBookMixin = {}

function EventBookMixin:OnLoad()
	self.PagedEventDetails:SetElementTemplateData(private.constants.templates)

	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self) -- Use state-based subscription for event selection
	-- This provides a single source of truth for the selected event
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedEvent",
			function(newEventSelection)
				if newEventSelection and newEventSelection.eventId then
					-- Fetch the full event object using both ID and collection name
					self:OnEventSelected(newEventSelection.eventId, newEventSelection.collectionName)
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

function EventBookMixin:GetEventById(eventId, collectionName)
	if collectionName and Chronicles and Chronicles.Data and Chronicles.Data.Events then
		local collectionData = Chronicles.Data.Events[collectionName]

		if collectionData and collectionData.data then
			local event = collectionData.data[eventId]
			if event then
				return event
			end
		end
	end

	private.Core.Logger.warn("EventBookMixin", "No event found with ID:", eventId, "in collection:", collectionName)

	return nil
end

function EventBookMixin:OnEventSelected(eventId, collectionName)
	local data = self:GetEventById(eventId, collectionName)

	if data then
		local content = private.Core.Events.TransformEventToBook(data)
		local dataProvider = CreateDataProvider(content)
		local retainScrollPosition = false

		self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
	else
		local emptyData = private.Core.Events.EmptyBook()
		local dataProvider = CreateDataProvider(emptyData)
		self.PagedEventDetails:SetDataProvider(dataProvider, false)
	end
end

function EventBookMixin:OnUIRefresh()
	local data = private.Core.Events.EmptyBook()
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
