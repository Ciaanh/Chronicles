local FOLDER_NAME, private = ...

local Chronicles = private.Chronicles

-- =============================================================================================
-- SHARED BOOK TEMPLATE MIXIN
-- =============================================================================================
--
-- Completely agnostic book component that displays already-transformed content.
-- Handles UI interactions, paging controls, and state management.
-- Used directly without type-specific implementations.
--
-- USAGE:
-- Simply inherit from this mixin and provide content via OnContentReceived().
-- Content should be pre-transformed into book format with proper template keys.
-- The OnContentReceived method receives already-transformed content, not item IDs.
-- =============================================================================================

SharedBookMixin = {}

-- =============================================================================================
-- INITIALIZATION AND SETUP
-- =============================================================================================

function SharedBookMixin:OnLoad()
	if not private.constants.templates then
		return
	end

	if not self.PagedDetails then
		return
	end

	self.PagedDetails:SetElementTemplateData(private.constants.templates)

	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()

	self.currentlyDisplayedContent = nil
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
-- CONTENT MANAGEMENT
-- =============================================================================================

-- Main method to display content in the book
-- @param bookContent [table] Already-transformed book content with proper template keys
function SharedBookMixin:OnContentReceived(bookContent)
	if bookContent and #bookContent > 0 then
		local dataProvider = CreateDataProvider(bookContent)
		local retainScrollPosition = false
		self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)
		self.currentlyDisplayedContent = bookContent
	else
		self:ShowEmptyBook()
	end
end

-- Internal method to display empty book state
function SharedBookMixin:ShowEmptyBook()
	local emptyContent = {
		{
			templateKey = private.constants.bookTemplateKeys.EMPTY,
			text = "No content available"
		}
	}

	local dataProvider = CreateDataProvider(emptyContent)
	self.PagedDetails:SetDataProvider(dataProvider, false)
	self.currentlyDisplayedContent = nil
end

function SharedBookMixin:OnUIRefresh()
	self:ShowEmptyBook()
end
