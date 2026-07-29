--[[
    BookContainerTemplate.lua
    
    Main book container for the Chronicles book system.
    Provides a complete book experience with paging, navigation, and template support.
    
    Based on SharedBookMixin but integrated into the Book system architecture.
    Supports all template types including HTML_CONTENT for the new unified system.
]]
local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

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

    -- Deliberately no UIRefresh handler here. A refresh must not blank the page you are reading, and
    -- this frame does not know what is selected. MainFrameUI owns the selection-to-book mapping and
    -- re-renders each book from current state on UIRefresh instead.

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
    Display the empty book state — what the reader sees before they pick anything.

    @param promptText [string] Optional invitation to select something. The caller knows which kind
                              of entity this book shows; without it we fall back to a neutral line.
]]
function BookContainerMixin:ShowEmptyBook(promptText)
    local message = promptText or Locale["NoContentAvailable"]

    local emptyContent = {
        {
            elements = {
                {
                    templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                    htmlContent = string.format('<html><body><p align="center">%s</p></body></html>', message)
                }
            }
        }
    }

    local dataProvider = CreateDataProvider(emptyContent)
    self.PagedDetails:SetDataProvider(dataProvider, false)
    self.currentlyDisplayedContent = emptyContent
end
