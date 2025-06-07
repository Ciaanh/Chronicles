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
			private.Core.StateManager.buildSelectionKey("event"),
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
		-- Subscribe to period selection changes to reset event book view
		-- Only reset if the newly selected period does not contain the currently displayed event
		local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
		private.Core.StateManager.subscribe(
			selectedPeriodKey,
			function(newPeriod, oldPeriod)
				if newPeriod then
					self:OnPeriodSelectionChanged(newPeriod)
				end
			end,
			"EventBookMixin"
		)

		private.Core.Logger.trace(
			"EventBookMixin",
			"OnLoad completed - subscribed to state changes, state restoration will happen during AddonStartup"
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedEventDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()

	self.currentlyDisplayedEvent = nil -- Track the currently displayed event
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
		self.currentlyDisplayedEvent = {eventId = eventId, collectionName = collectionName}
	else
		local emptyData = private.Core.Events.EmptyBook()
		local dataProvider = CreateDataProvider(emptyData)
		self.PagedEventDetails:SetDataProvider(dataProvider, false)
		self.currentlyDisplayedEvent = nil
	end
end

function EventBookMixin:OnUIRefresh()
	local data = private.Core.Events.EmptyBook()
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedEventDetails:SetDataProvider(dataProvider, retainScrollPosition)
	-- Clear tracking when UI is refreshed (book view is empty)
	self.currentlyDisplayedEvent = nil
end

function EventBookMixin:OnPeriodSelectionChanged(newPeriod)
	-- Check if we have a currently displayed event
	if not self.currentlyDisplayedEvent then
		private.Core.Logger.trace(
			"EventBookMixin",
			"Period selection changed but no event is currently displayed - no action needed"
		)
		return
	end

	-- Check if the current event falls within the new period
	local currentEvent = self.currentlyDisplayedEvent
	local eventInNewPeriod = self:IsEventInPeriod(currentEvent, newPeriod)

	if eventInNewPeriod then
		private.Core.Logger.trace(
			"EventBookMixin",
			"Period selection changed but current event (ID: " ..
				tostring(currentEvent.eventId) ..
					") is within new period (" ..
						tostring(newPeriod.lower) .. "-" .. tostring(newPeriod.upper) .. ") - keeping event displayed"
		)
	else
		private.Core.Logger.trace(
			"EventBookMixin",
			"Period selection changed and current event (ID: " ..
				tostring(currentEvent.eventId) ..
					") is NOT within new period (" ..
						tostring(newPeriod.lower) .. "-" .. tostring(newPeriod.upper) .. ") - resetting event book view"
		)
		self:OnUIRefresh()
	end
end

function EventBookMixin:IsEventInPeriod(eventSelection, period)
	if not eventSelection or not eventSelection.eventId or not eventSelection.collectionName then
		return false
	end

	if not period or not period.lower or not period.upper then
		return false
	end

	-- Get the full event data to check its date range
	local eventData = self:GetEventById(eventSelection.eventId, eventSelection.collectionName)
	if not eventData or not eventData.yearStart or not eventData.yearEnd then
		return false
	end

	-- Check if the event's date range overlaps with the period
	-- Event is in period if: event.yearStart <= period.upper AND event.yearEnd >= period.lower
	return eventData.yearStart <= period.upper and eventData.yearEnd >= period.lower
end
