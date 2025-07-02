local FOLDER_NAME, private = ...

EmptyMixin = {}
function EmptyMixin:Init(elementData)
    -- Empty mixin - no initialization needed
end

AuthorMixin = {}
function AuthorMixin:Init(elementData)
    if elementData.text then
        self.Text:SetText(elementData.text)
    end
end

ChapterHeaderMixin = {}
function ChapterHeaderMixin:Init(elementData)
    if elementData.text then
        self.Text:SetText(elementData.text)
    end
end

ChapterLineMixin = {}
function ChapterLineMixin:Init(elementData)
    if elementData.text then
        self.Text:SetText(elementData.text)
    end
end

HtmlPageMixin = {}
function HtmlPageMixin:Init(elementData)
    if elementData.text then
        self.ScrollFrame.HTML:SetText(elementData.text)
    end
end

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

-- Simple Title Mixin - Unified mixin for characters and factions
SimpleTitleMixin = {}
function SimpleTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
    end

    -- Set author (hide if not present)
    if elementData.author and elementData.author ~= "" then
        self.Author:SetText(elementData.author)
        self.Author:Show()
    else
        self.Author:SetText("")
        self.Author:Hide()
    end
end

CoverPageMixin = {}
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

    -- Set portrait/image
    if elementData.image and elementData.image ~= "" then
        self.Portrait:SetTexture(elementData.image)
        self.Portrait:Show()
    else
        self.Portrait:Hide()
    end

    -- Handle description
    if elementData.text and elementData.text ~= "" then
        -- Calculate available height for description
        local totalHeight = 550
        local portraitHeight = 128 + 20 + 10 -- portrait + top margin + bottom spacing
        local nameHeight = 60 + 10 -- name height + bottom spacing
        local authorHeight = 25 -- author height
        local availableHeight = totalHeight - portraitHeight - nameHeight - authorHeight - 20 -- extra padding

        -- Check if content is HTML using the StringUtils helper if available
        local isHTML = false
        if
            private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                private.Core.Utils.StringUtils.ContainsHTML
         then
            isHTML = private.Core.Utils.StringUtils.ContainsHTML(elementData.text)
        else
            -- Fallback: simple HTML detection
            isHTML = string.find(elementData.text, "<[^>]+>") ~= nil
        end

        if isHTML then
            -- Use HTML ScrollFrame for HTML content
            self.Description:Hide()
            self.DescriptionScrollFrame:Show()
            self.DescriptionScrollFrame:SetHeight(availableHeight)

            -- Clean HTML if utility is available
            local cleanText = elementData.text
            if
                private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                    private.Core.Utils.StringUtils.CleanHTML
             then
                cleanText = private.Core.Utils.StringUtils.CleanHTML(elementData.text)
            end

            self.DescriptionScrollFrame.HTML:SetText(cleanText)
        else
            -- Use simple FontString for text content
            self.DescriptionScrollFrame:Hide()
            self.Description:Show()
            self.Description:SetHeight(availableHeight)
            self.Description:SetText(elementData.text)
        end
    else
        -- Hide both description elements if no text
        self.Description:Hide()
        self.DescriptionScrollFrame:Hide()
    end
end

CoverDescriptionMixin = {}
function CoverDescriptionMixin:Init(elementData)
    if elementData.text then
        self.Description:SetText(elementData.text)
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
