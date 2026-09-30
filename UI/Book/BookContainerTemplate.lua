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

    -- The footer links sit over the left page's HTML and must take the clicks, and they follow the
    -- page: OnUpdate fires after every spread is displayed (PagedContentFrameBaseMixin).
    if self.FooterLinks then
        self.FooterLinks:SetFrameLevel(self.PagedDetails:GetFrameLevel() + 50)
        self.PagedDetails:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.UpdateFooterVisibility, self)
    end
end

-- =============================================================================================
-- FOOTER LINKS (previous and next event)
-- =============================================================================================

--[[
    Set the links at the foot of the left page

    @param previous [table|nil] {title, subtitle, onClick}, nil for none
    @param nextLink [table|nil] same shape
]]
function BookContainerMixin:SetFooterLinks(previous, nextLink)
    self.footerLinks = {previous = previous, next = nextLink}

    if self.FooterLinks then
        self.FooterLinks.Previous:SetLink(previous, "LEFT")
        self.FooterLinks.Next:SetLink(nextLink, "RIGHT")
    end

    self:UpdateFooterVisibility()
end

function BookContainerMixin:UpdateFooterVisibility()
    local footer = self.FooterLinks
    if not footer then
        return
    end

    local links = self.footerLinks
    local hasLinks = links ~= nil and (links.previous ~= nil or links.next ~= nil)
    local controls = self.PagedDetails and self.PagedDetails.PagingControls
    local page = (controls and controls.GetCurrentPage and controls:GetCurrentPage()) or 1

    footer:SetShown(hasLinks and page == 1)
end

BookFooterLinkMixin = {}

-- Rust at rest, darker under the pointer: the same ink as the links in the text (HTMLBuilder.LINK_COLOR)
local FOOTER_LINK_COLOR = {0.541, 0.204, 0.078}
local FOOTER_LINK_HOVER_COLOR = {0.37, 0.13, 0.05}

function BookFooterLinkMixin:SetLink(link, justify)
    self.link = link
    if not link then
        self:Hide()
        return
    end

    self.Title:SetJustifyH(justify)
    self.Subtitle:SetJustifyH(justify)
    self.Title:SetText(link.title or "")
    self.Subtitle:SetText(link.subtitle or "")
    self.Title:SetTextColor(unpack(FOOTER_LINK_COLOR))
    self:Show()
end

function BookFooterLinkMixin:OnClick()
    if self.link and self.link.onClick then
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
        self.link.onClick()
    end
end

function BookFooterLinkMixin:OnEnter()
    self.Title:SetTextColor(unpack(FOOTER_LINK_HOVER_COLOR))
    -- A long name is cut to the button's width; the tooltip gives it whole
    if self.Title:IsTruncated() then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.link and self.link.title or "", 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

function BookFooterLinkMixin:OnLeave()
    self.Title:SetTextColor(unpack(FOOTER_LINK_COLOR))
    GameTooltip:Hide()
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

    Two elements, not one, so the empty book is a balanced spread like every other: element 1 lands on
    View1 where front matter normally goes, element 2 on View2 where the prose goes. A single centred
    line left the left page blank and made the book look broken rather than waiting.

    The counts are the caller's job. This frame is a sibling of the rail and is handed content, not a
    selection; MainFrameUI already owns the selection-to-book mapping and can reach the collection and
    entity counts, so it formats both strings. Walking the frame tree from here to find the rail would
    couple the book to a layout it does not own.

    @param promptText [string] Optional invitation to select something. The caller knows which kind
                              of entity this book shows; without it we fall back to a neutral line.
    @param frontMatterText [string] Optional line for the left page, normally what this tab holds.
                                    Absent, the left page stays empty and behaviour matches the old
                                    single-prompt form.
]]
function BookContainerMixin:ShowEmptyBook(promptText, frontMatterText)
    local message = promptText or Locale["NoContentAvailable"]

    local elements = {}

    if frontMatterText and frontMatterText ~= "" then
        table.insert(
            elements,
            {
                templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                htmlContent = string.format('<html><body><p align="center">%s</p></body></html>', frontMatterText)
            }
        )
    end

    table.insert(
        elements,
        {
            templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
            htmlContent = string.format('<html><body><p align="center">%s</p></body></html>', message)
        }
    )

    local emptyContent = {
        {
            elements = elements
        }
    }

    local dataProvider = CreateDataProvider(emptyContent)
    self.PagedDetails:SetDataProvider(dataProvider, false)
    self.currentlyDisplayedContent = emptyContent

    self:SetFooterLinks(nil, nil)
end
