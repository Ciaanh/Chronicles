local FOLDER_NAME, private = ...

EventBookMixin = {}

function EventBookMixin:OnLoad()
	self.PagedEventDetails:SetElementTemplateData(private.constants.templates)

	-- Register only for events that don't have a state equivalent
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)	-- Use state-based subscription for event selection
	-- This provides a single source of truth for the selected event
	if private.Core.StateManager then		private.Core.StateManager.subscribe(
			"ui.selectedEvent",
			function(newEventSelection)
				if newEventSelection and newEventSelection.eventId then
					-- Fetch the full event object using both ID and library name
					self:OnEventSelected(newEventSelection.eventId, newEventSelection.libraryName)
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

function EventBookMixin:GetEventById(eventId, libraryName)
	-- FIRST: If library name is provided, try direct lookup in that specific library
	if libraryName and Chronicles and Chronicles.Data and Chronicles.Data.Events then
		local libraryData = Chronicles.Data.Events[libraryName]
		if libraryData and libraryData.data and libraryData.data[eventId] then
			return libraryData.data[eventId]
		end
	end
	-- SECOND: Try direct access to OriginsEventsDB (fastest fallback method)
	if OriginsEventsDB and OriginsEventsDB[eventId] then
		local eventData = OriginsEventsDB[eventId]
		return eventData
	end	-- THIRD: Try Chronicles.Data API (comprehensive search across all libraries)
	if Chronicles and Chronicles.Data then
		-- Check active libraries
		local libraries = Chronicles.Data:GetLibrariesNames()
		local originsStatus = Chronicles.Data:GetLibraryStatus("Origins")

		-- Try accessing through registered databases
		if Chronicles.Data.Events then
			for libraryName, libraryData in pairs(Chronicles.Data.Events) do
				if libraryData and libraryData.data then
					local event = libraryData.data[eventId]
					if event then
						return event
					end
				end
			end
		end
	end	-- FOURTH: Try MyJournal events (user-created events)
	if Chronicles and Chronicles.Data and Chronicles.Data.GetMyJournalEvents then
		local myJournalEvents = Chronicles.Data:GetMyJournalEvents()
		for _, event in ipairs(myJournalEvents) do
			if event.id == eventId then
				return event
			end
		end
	end

	return nil
end

function EventBookMixin:OnEventSelected(eventId, libraryName)
	local data = self:GetEventById(eventId, libraryName)
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
