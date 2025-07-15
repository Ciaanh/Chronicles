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
    -- print("BookContainerMixin:OnLoad called")
    if not private.constants.templates then
        -- print("BookContainerMixin: ERROR - private.constants.templates is nil!")
        return
    end

    if not self.PagedDetails then
        -- print("BookContainerMixin: ERROR - self.PagedDetails is nil!")
        return
    end

    -- Debug template data being set
    -- print("BookContainerMixin: Setting element template data...")
    -- print("BookContainerMixin: Available templates:")
    -- for key, data in pairs(private.constants.templates) do
    --     print("  - " .. tostring(key) .. " -> " .. tostring(data.template))
    -- end
    
    local htmlTemplate = private.constants.templates[private.constants.bookTemplateKeys.HTML_CONTENT]
    -- if htmlTemplate then
    --     print("BookContainerMixin: HTML_CONTENT template found: " .. tostring(htmlTemplate.template))
    -- else
    --     print("BookContainerMixin: ERROR - HTML_CONTENT template not found!")
    -- end

    -- Set up template system
    self.PagedDetails:SetElementTemplateData(private.constants.templates)
    -- print("BookContainerMixin: Template data set successfully")

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
    -- print("BookContainerMixin:OnContentReceived called with content length: " .. tostring(#bookContent))
    
    if bookContent and #bookContent > 0 then
        -- Debug the content structure
        -- print("BookContainerMixin: Content structure:")
        -- for i, section in ipairs(bookContent) do
        --     print("  Section " .. i .. ":")
        --     if section.elements then
        --         print("    Elements count: " .. #section.elements)
        --         for j, element in ipairs(section.elements) do
        --             print("    Element " .. j .. ":")
        --             print("      templateKey: " .. tostring(element.templateKey))
        --             if element.templateKey == private.constants.bookTemplateKeys.HTML_CONTENT then
        --                 print("      htmlContent length: " .. tostring(element.htmlContent and string.len(element.htmlContent) or "nil"))
        --                 print("      title: " .. tostring(element.title))
        --                 print("      HTML_CONTENT constant: " .. tostring(private.constants.bookTemplateKeys.HTML_CONTENT))
        --             end
        --         end
        --     else
        --         print("    No elements found!")
        --     end
        -- end
        
        local dataProvider = CreateDataProvider(bookContent)
        local retainScrollPosition = false
        self.PagedDetails:SetDataProvider(dataProvider, retainScrollPosition)
        self.currentlyDisplayedContent = bookContent
        -- print("BookContainerMixin: Data provider set successfully")
    else
        -- print("BookContainerMixin: No content provided, showing empty book")
        self:ShowEmptyBook()
    end
end

--[[
    Display empty book state
]]
function BookContainerMixin:ShowEmptyBook()
    local emptyContent = {
        {
            elements = {
                {
                    templateKey = private.constants.bookTemplateKeys.EMPTY,
                    text = "No content available"
                }
            }
        }
    }

    local dataProvider = CreateDataProvider(emptyContent)
    self.PagedDetails:SetDataProvider(dataProvider, false)
    self.currentlyDisplayedContent = nil
end

--[[
    Handle UI refresh events
]]
function BookContainerMixin:OnUIRefresh()
    self:ShowEmptyBook()
end
