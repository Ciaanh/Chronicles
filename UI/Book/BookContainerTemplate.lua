--[[
    BookContainerTemplate.lua
    
    Main book container for the Chronicles book system.
    Provides a complete book experience with paging, navigation, and template support.
    
    Based on SharedBookMixin but integrated into the Book system architecture.
    Supports all template types including HTML_CONTENT for the new unified system.
]]
local FOLDER_NAME, private = ...

-- =============================================================================================
-- BOOK CONTAINER MIXIN
-- =============================================================================================

--[[
    Main book container mixin with full template support
    Handles all template types and provides proper book UI experience
]]
BookContainerMixin = {}

-- =============================================================================================
-- INITIALIZATION AND SETUP
-- =============================================================================================

function BookContainerMixin:OnLoad()
    if not private.constants.templates then
        return
    end

    if not self.PagedDetails then
        return
    end

    local htmlTemplate = private.constants.templates[private.constants.bookTemplateKeys.HTML_CONTENT]

    -- Set up template system
    self.PagedDetails:SetElementTemplateData(private.constants.templates)

    -- Register for UI refresh events
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

function BookContainerMixin:OnPagingButtonEnter()
    if self.SinglePageBookCornerFlipbook and self.SinglePageBookCornerFlipbook.Anim then
        self.SinglePageBookCornerFlipbook.Anim:Play()
    end
end

function BookContainerMixin:OnPagingButtonLeave()
    if self.SinglePageBookCornerFlipbook and self.SinglePageBookCornerFlipbook.Anim then
        local reverse = true
        self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
    end
end

-- =============================================================================================
-- CONTENT MANAGEMENT
-- =============================================================================================

--[[
    Main method to display content in the book
    @param bookContent [table] Already-transformed book content with proper template keys
]]
function BookContainerMixin:OnContentReceived(bookContent)
    if bookContent and #bookContent > 0 then
        -- Store navigation data if available (from HTMLBuilder result)
        if bookContent.navigationData then
            self.navigationData = bookContent.navigationData
        end

        -- Keep the reader's place when this is a re-render of the content already on screen, and
        -- reset it when a different entity is opened. A UI refresh should not throw away the page
        -- you were reading; selecting something new should start at its beginning.
        --
        -- Table identity is a sound test here: ContentUtils.TransformEntityToBook caches its result
        -- per entity and returns the cached table, so the same entity yields the same table and a
        -- different entity yields a different one.
        local retainScrollPosition = self.currentlyDisplayedContent == bookContent

        local dataProvider = CreateDataProvider(bookContent)
        self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)
        self.currentlyDisplayedContent = bookContent
    else
        self:ShowEmptyBook()
    end
end

--[[
    Display empty book state
]]
function BookContainerMixin:ShowEmptyBook()
    -- Test with HTML content first
    local testContent = {
        {
            elements = {
                {
                    templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                    htmlContent = "<html><body><h1>Test HTML Content</h1><p>This is a test to verify the HTML content template is working.</p></body></html>",
                    title = "Test"
                }
            }
        }
    }

    local dataProvider = CreateDataProvider(testContent)
    self.PagedDetails:SetDataProvider(dataProvider, false)
    self.currentlyDisplayedContent = testContent
end

--[[
    Handle UI refresh events
]]
function BookContainerMixin:OnUIRefresh()
    self:ShowEmptyBook()
end
