local FOLDER_NAME, private = ...

local Chronicles = private.Chronicles

-- =============================================================================================
-- SHARED BOOK TEMPLATE MIXIN
-- =============================================================================================
--
-- Base mixin that provides common book functionality for Events, Characters, and Factions.
-- This shared component handles state management, UI interactions, paging controls,
-- period filtering, and other common book behaviors.
--
-- USAGE:
-- Concrete implementations should inherit from this mixin and implement the required
-- abstract methods to provide type-specific behavior.
--
-- DESIGN PATTERN:
-- Uses template method pattern where the base class defines the algorithm structure
-- and derived classes provide specific implementations for data transformation,
-- source lookup, and date range validation.
-- =============================================================================================

SharedBookMixin = {}

-- =============================================================================================
-- INITIALIZATION AND SETUP
-- =============================================================================================

function SharedBookMixin:OnLoad()
	-- Set up paged content display
	self.PagedDetails:SetElementTemplateData(private.constants.templates)

	-- Register for UI refresh events that don't have state equivalents
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	-- Initialize state subscriptions based on book type
	self:InitializeStateSubscriptions()

	-- Set up paging controls with hover animations
	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	-- Initialize book corner animation
	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()

	-- Track currently displayed item
	self.currentlyDisplayedItem = nil

	private.Core.Logger.trace(self:GetMixinName(), "OnLoad completed - initialized shared book template")
end

function SharedBookMixin:InitializeStateSubscriptions()
	if not private.Core.StateManager then
		private.Core.Logger.warn(self:GetMixinName(), "StateManager not available for state subscriptions")
		return
	end

	local bookType = self:GetBookType()
	local selectionKey = private.Core.StateManager.buildSelectionKey(bookType)

	-- Subscribe to item selection changes
	private.Core.StateManager.subscribe(
		selectionKey,
		function(newSelection)
			if newSelection and newSelection.id then
				-- Support both new format {id, collectionName} and legacy formats
				local itemId = newSelection.id or newSelection.eventId or newSelection.characterId or newSelection.factionId
				local collectionName = newSelection.collectionName

				if itemId then
					self:OnItemSelected(itemId, collectionName)
				else
					self:OnUIRefresh()
				end
			else
				self:OnUIRefresh()
			end
		end,
		self:GetMixinName()
	)

	-- Subscribe to period selection changes for filtering
	local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
	private.Core.StateManager.subscribe(
		selectedPeriodKey,
		function(newPeriod, oldPeriod)
			if newPeriod then
				self:OnPeriodSelectionChanged(newPeriod)
			end
		end,
		self:GetMixinName()
	)

	private.Core.Logger.trace(self:GetMixinName(), "State subscriptions initialized for", bookType, "book")
end

-- =============================================================================================
-- ANIMATION AND UI INTERACTIONS
-- =============================================================================================

function SharedBookMixin:OnPagingButtonEnter()
	-- Play book corner animation on paging button hover
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function SharedBookMixin:OnPagingButtonLeave()
	-- Reverse book corner animation when hover ends
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

-- =============================================================================================
-- DATA MANAGEMENT
-- =============================================================================================

function SharedBookMixin:GetItemById(itemId, collectionName)
	local bookType = self:GetBookType()
	local dataSource = self:GetDataSource()

	if collectionName and Chronicles and Chronicles.Data and Chronicles.Data[dataSource] then
		local collectionData = Chronicles.Data[dataSource][collectionName]

		if collectionData and collectionData.data then
			local item = collectionData.data[itemId]
			if item then
				return item
			end
		end
	end

	private.Core.Logger.warn(
		self:GetMixinName(),
		"No",
		bookType,
		"found with ID:",
		itemId,
		"in collection:",
		collectionName
	)
	return nil
end

function SharedBookMixin:OnItemSelected(itemId, collectionName)
	local data = self:GetItemById(itemId, collectionName)

	if data then
		-- Transform data to book format using type-specific transformer
		local content = self:TransformItemToBook(data)
		local dataProvider = CreateDataProvider(content)
		local retainScrollPosition = false

		-- Display the content in the paged view
		self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)

		-- Track currently displayed item for period filtering
		self.currentlyDisplayedItem = {
			id = itemId,
			collectionName = collectionName,
			bookType = self:GetBookType()
		}

		private.Core.Logger.trace(
			self:GetMixinName(),
			"Item selected and displayed:",
			itemId,
			"from collection:",
			collectionName
		)
	else
		-- Show empty book if item not found
		local emptyData = self:GetEmptyBook()
		local dataProvider = CreateDataProvider(emptyData)
		self.PagedDetails:SetDataProvider(dataProvider, false)
		self.currentlyDisplayedItem = nil

		private.Core.Logger.warn(self:GetMixinName(), "Failed to load item, showing empty book:", itemId)
	end
end

function SharedBookMixin:OnUIRefresh()
	-- Clear the book view and show empty state
	local data = self:GetEmptyBook()
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)
	self.currentlyDisplayedItem = nil

	private.Core.Logger.trace(self:GetMixinName(), "UI refreshed - book view cleared")
end

-- =============================================================================================
-- PERIOD FILTERING
-- =============================================================================================

function SharedBookMixin:OnPeriodSelectionChanged(newPeriod)
	-- Check if we have a currently displayed item
	if not self.currentlyDisplayedItem then
		private.Core.Logger.trace(
			self:GetMixinName(),
			"Period selection changed but no item is currently displayed - no action needed"
		)
		return
	end

	-- Check if the current item falls within the new period
	local currentItem = self.currentlyDisplayedItem
	local itemInNewPeriod = self:IsItemInPeriod(currentItem, newPeriod)

	if itemInNewPeriod then
		private.Core.Logger.trace(
			self:GetMixinName(),
			"Period selection changed but current item (ID:",
			tostring(currentItem.id),
			") is within new period (",
			tostring(newPeriod.lower),
			"-",
			tostring(newPeriod.upper),
			") - keeping item displayed"
		)
	else
		private.Core.Logger.trace(
			self:GetMixinName(),
			"Period selection changed and current item (ID:",
			tostring(currentItem.id),
			") is NOT within new period (",
			tostring(newPeriod.lower),
			"-",
			tostring(newPeriod.upper),
			") - resetting book view"
		)
		self:OnUIRefresh()
	end
end

function SharedBookMixin:IsItemInPeriod(itemSelection, period)
	-- Validate inputs
	if not itemSelection or not itemSelection.id or not itemSelection.collectionName then
		return false
	end

	if not period or not period.lower or not period.upper then
		return false
	end

	-- Get the full item data to check its date range
	local itemData = self:GetItemById(itemSelection.id, itemSelection.collectionName)
	if not itemData then
		return false
	end

	-- Use type-specific date range checking
	return self:CheckItemDateRange(itemData, period)
end

-- =============================================================================================
-- LEGACY COMPATIBILITY METHODS
-- =============================================================================================
--
-- These methods provide backward compatibility with existing code that expects
-- specific method names for events, characters, and factions.
-- =============================================================================================

-- Legacy compatibility for EventBookMixin
function SharedBookMixin:GetEventById(eventId, collectionName)
	if self:GetBookType() == "event" then
		return self:GetItemById(eventId, collectionName)
	else
		error("GetEventById called on non-event book template")
	end
end

function SharedBookMixin:OnEventSelected(eventId, collectionName)
	if self:GetBookType() == "event" then
		return self:OnItemSelected(eventId, collectionName)
	else
		error("OnEventSelected called on non-event book template")
	end
end

-- Legacy compatibility for CharacterBookMixin
function SharedBookMixin:GetCharacterById(characterId, collectionName)
	if self:GetBookType() == "character" then
		return self:GetItemById(characterId, collectionName)
	else
		error("GetCharacterById called on non-character book template")
	end
end

function SharedBookMixin:OnCharacterSelected(characterId, collectionName)
	if self:GetBookType() == "character" then
		return self:OnItemSelected(characterId, collectionName)
	else
		error("OnCharacterSelected called on non-character book template")
	end
end

-- Legacy compatibility for FactionBookMixin
function SharedBookMixin:GetFactionById(factionId, collectionName)
	if self:GetBookType() == "faction" then
		return self:GetItemById(factionId, collectionName)
	else
		error("GetFactionById called on non-faction book template")
	end
end

function SharedBookMixin:OnFactionSelected(factionId, collectionName)
	if self:GetBookType() == "faction" then
		return self:OnItemSelected(factionId, collectionName)
	else
		error("OnFactionSelected called on non-faction book template")
	end
end

-- =============================================================================================
-- ABSTRACT METHODS - MUST BE IMPLEMENTED BY CONCRETE MIXINS
-- =============================================================================================
--
-- These methods define the interface that concrete book implementations must provide.
-- They handle type-specific behavior while the base class manages common functionality.
--
-- Required Methods:
-- - GetBookType() : string - Return book type identifier ('event', 'character', 'faction')
-- - GetDataSource() : string - Return data source accessor ('Events', 'Characters', 'Factions')
-- - GetMixinName() : string - Return mixin name for logging ('EventBookMixin', etc.)
-- - TransformItemToBook(data) : table - Transform raw data into book format
-- - GetEmptyBook() : table - Return empty book content for placeholder state
-- - CheckItemDateRange(itemData, period) : boolean - Check if item falls within date range
-- =============================================================================================

-- Abstract methods are implemented by concrete mixins in SharedBookImplementations.lua
-- No default implementations are provided here to avoid conflicts with concrete implementations
