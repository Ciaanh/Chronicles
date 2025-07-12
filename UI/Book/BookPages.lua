local FOLDER_NAME, private = ...

-- =============================================================================================
-- CORE MIXINS FOR BOOK TEMPLATES
-- =============================================================================================

EmptyMixin = {}
function EmptyMixin:Init(elementData)
    -- Empty mixin - no initialization needed
end

-- Simple Title Mixin - Unified mixin for characters and factions
SimpleTitleMixin = {}
function SimpleTitleMixin:Init(elementData)
    if not elementData then 
        return 
    end
    
    if elementData.text then
        if self.Title then
            self.Title:SetText(elementData.text)
        end
    end

    -- Set author (hide if not present)
    if elementData.author and elementData.author ~= "" then
        if self.Author then
            self.Author:SetText(elementData.author)
            self.Author:Show()
        end
    else
        if self.Author then
            self.Author:SetText("")
            self.Author:Hide()
        end
    end
end

EventTitleMixin = {}
function EventTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
        self.Title:Show()
    else
        self.Title:SetText("")
        self.Title:Hide()
    end

    -- Set author (hide if not present)
    if elementData.author and elementData.author ~= "" then
        self.Author:SetText(elementData.author)
        self.Author:Show()
    else
        self.Author:SetText("")
        self.Author:Hide()
    end

    -- Set dates
    if elementData.yearStart and private.constants.config.currentYear < elementData.yearStart then
        self.Dates:SetText("")
        self.Dates:Hide()
        return
    end

    if elementData.yearEnd and elementData.yearEnd < private.constants.config.historyStartYear then
        self.Dates:SetText("")
        self.Dates:Hide()
        return
    end

    if elementData.yearStart and elementData.yearEnd then
        local dateText
        if elementData.yearStart == elementData.yearEnd then
            dateText = tostring(elementData.yearStart)
        else
            dateText = tostring(elementData.yearStart) .. " - " .. tostring(elementData.yearEnd)
        end
        self.Dates:SetText(dateText)
        self.Dates:Show()
    else
        self.Dates:SetText("")
        self.Dates:Hide()
    end
end

CoverPageMixin = {}
function CoverPageMixin:OnLoad()
    -- Initialize the cover page
end

function CoverPageMixin:Init(elementData)
    -- Set entity name
    if elementData.name then
        self.Name:SetText(elementData.name)
    end

    -- Set author
    if elementData.author and elementData.author ~= "" then
        self.Author:SetText(elementData.author)
        self.Author:Show()
    else
        self.Author:Hide()
    end

    -- Set portrait/image and frame
    if elementData.image and elementData.image ~= "" then
        if self.Portrait then
            self.Portrait:SetTexture(elementData.image)
            self.Portrait:Show()
            self.Portrait:SetAlpha(1)
        end
        if self.PortraitFrame then
            self.PortraitFrame:Show()
        end
    else
        -- Hide portrait and frame if no image
        if self.Portrait then
            self.Portrait:Hide()
        end
        if self.PortraitFrame then
            self.PortraitFrame:Hide()
        end
    end

    -- Set description using unified content system
    local scrollContent = self.ContentArea and self.ContentArea.DescriptionScrollFrame and 
                         self.ContentArea.DescriptionScrollFrame.HTML
    local desc = elementData.text

    if desc and desc ~= "" and scrollContent then
        local isHTML = false
        if
            private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                private.Core.Utils.StringUtils.ContainsHTML
         then
            isHTML = private.Core.Utils.StringUtils.ContainsHTML(desc)
        else
            isHTML = string.find(desc, "<[^>]+>") ~= nil
        end
        
        -- Use ContentUtils if available for better portrait integration
        local finalContent = desc
        if private.Core.Utils.ContentUtils then
            if isHTML then
                finalContent = private.Core.Utils.ContentUtils.InjectPortraitIntoHTML(desc, elementData.image)
            else
                finalContent = private.Core.Utils.ContentUtils.ConvertTextToHTML(desc, elementData.image)
            end
        else
            -- Fallback logic
            if isHTML then
                local cleanText = desc
                if
                    private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                        private.Core.Utils.StringUtils.CleanHTML
                 then
                    cleanText = private.Core.Utils.StringUtils.CleanHTML(desc)
                end
                finalContent = cleanText
            else
                finalContent = "<html><body><p>" .. desc .. "</p></body></html>"
            end
        end
        
        scrollContent:SetText(finalContent)
        scrollContent:Show()
    else
        if scrollContent then
            scrollContent:Hide()
        end
    end
end

-- =============================================================================================
-- SCROLL FRAME MIXIN
-- =============================================================================================

ScrollFrameMixin = {}
function ScrollFrameMixin:OnLoad()
    if not self.noScrollBar then
        local scrollBarTemplate = self.scrollBarTemplate or SCROLL_FRAME_SCROLL_BAR_TEMPLATE

        local left = self.scrollBarX or SCROLL_FRAME_SCROLL_BAR_OFFSET_LEFT
        local top = self.scrollBarTopY or SCROLL_FRAME_SCROLL_BAR_OFFSET_TOP
        local bottom = self.scrollBarBottomY or SCROLL_FRAME_SCROLL_BAR_OFFSET_BOTTOM

        self.ScrollBar = CreateFrame("EventFrame", nil, self, scrollBarTemplate)
        self.ScrollBar:SetHideIfUnscrollable(self.scrollBarHideIfUnscrollable)
        self.ScrollBar:SetHideTrackIfThumbExceedsTrack(self.scrollBarHideTrackIfThumbExceedsTrack)
        self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", left, top)
        self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", left, bottom)
        self.ScrollBar:Show()

        self:InitScrollFrameWithScrollBar()
        self.ScrollBar:Update()
    end
end

function ScrollFrameMixin:InitScrollFrameWithScrollBar()
    local scrollFrame = self
    local scrollBar = self.ScrollBar

    local onVerticalScroll = function(scrollFrame, offset)
        local verticalScrollRange = scrollFrame:GetVerticalScrollRange()
        local scrollPercentage = 0
        if verticalScrollRange > 0 then
            scrollPercentage = offset / verticalScrollRange
        end
        scrollBar:SetScrollPercentage(scrollPercentage, ScrollBoxConstants.NoScrollInterpolation)
    end

    scrollFrame:SetScript("OnVerticalScroll", onVerticalScroll)

    scrollFrame.GetPanExtent = function(self)
        return self.panExtent
    end

    scrollFrame.SetPanExtent = function(self, panExtent)
        self.panExtent = panExtent
    end

    scrollFrame:SetPanExtent(30)

    local onScrollRangeChanged = function(scrollFrame, hScrollRange, vScrollRange)
        onVerticalScroll(scrollFrame, scrollFrame:GetVerticalScroll())

        local visibleExtentPercentage = 0
        local height = scrollFrame:GetHeight()
        if height > 0 then
            visibleExtentPercentage = height / (vScrollRange + height)
        end

        scrollBar:SetVisibleExtentPercentage(visibleExtentPercentage)

        local panExtentPercentage = 0
        local verticalScrollRange = scrollFrame:GetVerticalScrollRange()
        if verticalScrollRange > 0 then
            panExtentPercentage = Saturate(scrollFrame:GetPanExtent() / verticalScrollRange)
        end
        scrollBar:SetPanExtentPercentage(panExtentPercentage)
    end

    scrollFrame:SetScript("OnScrollRangeChanged", onScrollRangeChanged)

    if self.scrollOnMouse then
        local onMouseWheel = function(scrollFrame, value)
            scrollBar:ScrollStepInDirection(-value)
        end

        scrollFrame:SetScript("OnMouseWheel", onMouseWheel)
    end

    local onScrollBarScroll = function(o, scrollPercentage)
        local scroll = scrollPercentage * scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll(scroll)
    end
    scrollBar:RegisterCallback(BaseScrollBoxEvents.OnScroll, onScrollBarScroll, scrollFrame)
end

-- =============================================================================================
-- OLD TEMPLATE COMPATIBILITY MIXINS
-- =============================================================================================

-- Chapter Header Mixin - Old format compatibility
ChapterHeaderMixin = {}
function ChapterHeaderMixin:Init(elementData)
    if not elementData then 
        return 
    end
    
    if elementData.text then
        if self.Title then
            self.Title:SetText(elementData.text)
        end
    end
end

-- Chapter Line Mixin - Old format compatibility
ChapterLineMixin = {}
function ChapterLineMixin:Init(elementData)
    if not elementData then 
        return 
    end
    
    if elementData.text then
        if self.Text then
            self.Text:SetText(elementData.text)
        end
    end
end

-- HTML Page Mixin - Old format compatibility
HtmlPageMixin = {}
function HtmlPageMixin:Init(elementData)
    if not elementData then 
        return 
    end
    
    if elementData.content then
        if self.ScrollFrame and self.ScrollFrame.HTML then
            self.ScrollFrame.HTML:SetText(elementData.content)
        end
    end
end
