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
	self.PagedDetails:SetElementTemplateData(private.constants.templates)
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	self:InitializeStateSubscriptions()

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()

	self.currentlyDisplayedItem = nil
end

function SharedBookMixin:InitializeStateSubscriptions()
	if not private.Core.StateManager then
		return
	end

	local bookType = self:GetBookType()
	local selectionKey = private.Core.StateManager.buildSelectionKey(bookType)

	private.Core.StateManager.subscribe(
		selectionKey,
		function(newSelection)
			if newSelection and newSelection.id then
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
end

-- =============================================================================================
-- ANIMATION AND UI INTERACTIONS
-- =============================================================================================

function SharedBookMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function SharedBookMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

-- =============================================================================================
-- DATA MANAGEMENT
-- =============================================================================================

function SharedBookMixin:GetItemById(itemId, collectionName)
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
	return nil
end

function SharedBookMixin:OnItemSelected(itemId, collectionName)
	local data = self:GetItemById(itemId, collectionName)

	if data then
		local content = self:TransformItemToBook(data)
		local dataProvider = CreateDataProvider(content)
		local retainScrollPosition = false

		self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)

		self.currentlyDisplayedItem = {
			id = itemId,
			collectionName = collectionName,
			bookType = self:GetBookType()
		}
	else
		local emptyData = self:GetEmptyBook()
		local dataProvider = CreateDataProvider(emptyData)
		self.PagedDetails:SetDataProvider(dataProvider, false)
		self.currentlyDisplayedItem = nil
	end
end

function SharedBookMixin:OnUIRefresh()
	local data = self:GetEmptyBook()
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)
	self.currentlyDisplayedItem = nil
end

-- =============================================================================================
-- PERIOD FILTERING
-- =============================================================================================

function SharedBookMixin:OnPeriodSelectionChanged(newPeriod)
	if not self.currentlyDisplayedItem then
		return
	end

	-- Check if the current item falls within the new period
	local currentItem = self.currentlyDisplayedItem
	local itemInNewPeriod = self:IsItemInPeriod(currentItem, newPeriod)

	if not itemInNewPeriod then
		self:OnUIRefresh()
	end
end

function SharedBookMixin:IsItemInPeriod(itemSelection, period)
	if not itemSelection or not itemSelection.id or not itemSelection.collectionName then
		return false
	end

	if not period or not period.lower or not period.upper then
		return false
	end

	local itemData = self:GetItemById(itemSelection.id, itemSelection.collectionName)
	if not itemData then
		return false
	end

	return self:CheckItemDateRange(itemData, period)
end

-- =============================================================================================
-- LEGACY COMPATIBILITY METHODS
-- =============================================================================================
--
-- These methods provide backward compatibility with existing code that expects
-- specific method names for events, characters, and factions.
-- =============================================================================================

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
