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
        -- Content area left-aligned if portrait present
        if self.ContentArea then
            self.ContentArea:ClearAllPoints()
            self.ContentArea:SetPoint("TOP", self.Divider, "BOTTOM", -60, -15)
            if self.ContentArea.DescriptionScrollFrame then
                self.ContentArea.DescriptionScrollFrame:SetWidth(300)
                if self.ContentArea.DescriptionScrollFrame.ScrollContent then
                    if self.ContentArea.DescriptionScrollFrame.ScrollContent.Description then
                        self.ContentArea.DescriptionScrollFrame.ScrollContent.Description:SetWidth(280)
                    end
                    if self.ContentArea.DescriptionScrollFrame.ScrollContent.HTML then
                        self.ContentArea.DescriptionScrollFrame.ScrollContent.HTML:SetWidth(280)
                    end
                end
            end
        end
    else
        if self.Portrait then
            self.Portrait:Hide()
        end
        if self.PortraitFrame then
            self.PortraitFrame:Hide()
        end
        -- Content area centered and wider if no portrait
        if self.ContentArea then
            self.ContentArea:ClearAllPoints()
            self.ContentArea:SetPoint("TOP", self.Divider, "BOTTOM", 0, -15)
            if self.ContentArea.DescriptionScrollFrame then
                self.ContentArea.DescriptionScrollFrame:SetWidth(400)
                if self.ContentArea.DescriptionScrollFrame.ScrollContent then
                    if self.ContentArea.DescriptionScrollFrame.ScrollContent.Description then
                        self.ContentArea.DescriptionScrollFrame.ScrollContent.Description:SetWidth(380)
                    end
                    if self.ContentArea.DescriptionScrollFrame.ScrollContent.HTML then
                        self.ContentArea.DescriptionScrollFrame.ScrollContent.HTML:SetWidth(380)
                    end
                end
            end
        end
    end

    -- Handle description (HTML or plain text)
    if self.ContentArea and self.ContentArea.DescriptionScrollFrame then
        local scrollFrame = self.ContentArea.DescriptionScrollFrame
        -- local scrollContent = scrollFrame.ScrollContent
        local scrollContent = scrollFrame.HTML

        local desc = elementData.text or elementData.description or ""

        -- Debug: Check structure
        -- print("CoverPageMixin:Init - ScrollFrame exists:", scrollFrame and "yes" or "no")
        -- print("CoverPageMixin:Init - ScrollContent exists:", scrollContent and "yes" or "no")
        -- print("CoverPageMixin:Init - Description exists:", scrollContent and scrollContent.Description and "yes" or "no")
        -- print("CoverPageMixin:Init - HTML exists:", scrollContent and scrollContent.HTML and "yes" or "no")
        -- print("CoverPageMixin:Init - Description content:", desc and string.len(desc) or "nil")

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

            print("CoverPageMixin:Init - Is HTML:", isHTML)
            if isHTML then
                local cleanText = desc
                if
                    private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                        private.Core.Utils.StringUtils.CleanHTML
                 then
                    cleanText = private.Core.Utils.StringUtils.CleanHTML(desc)
                end
                scrollContent:SetText(cleanText)
            else
                local formatedContent = "<html><body><p>" .. desc .. "</p></body></html>"
                scrollContent:SetText(formatedContent)
            end
            scrollContent:Show()

            -- if isHTML then
            --     if scrollContent.Description then
            --         scrollContent.Description:Hide()
            --     end
            --     if scrollContent.HTML then
            --         scrollContent.HTML:Show()
            --         local cleanText = desc
            --         if
            --             private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
            --                 private.Core.Utils.StringUtils.CleanHTML
            --          then
            --             cleanText = private.Core.Utils.StringUtils.CleanHTML(desc)
            --         end
            --         scrollContent.HTML:SetText(cleanText)
            --         print("CoverPageMixin:Init - Set HTML content")
            --     end
            -- else
            --     if scrollContent.HTML then
            --         scrollContent.HTML:Hide()
            --     end
            --     if scrollContent.Description then
            --         scrollContent.Description:Show()
            --         scrollContent.Description:SetText(desc)

            --         -- Force update the scroll frame
            --         C_Timer.After(0.1, function()
            --             if scrollContent.Description then
            --                 local stringWidth = scrollContent.Description:GetWidth()
            --                 local stringHeight = scrollContent.Description:GetStringHeight()

            --                 print("CoverPageMixin:Init - After timer - width:", stringWidth, "height:", stringHeight)

            --                 if stringHeight > 0 then
            --                     scrollContent.Description:SetHeight(stringHeight)
            --                     scrollContent:SetHeight(math.max(stringHeight + 10, 200))
            --                 end

            --                 -- Force scroll frame update
            --                 scrollFrame:UpdateScrollChildRect()
            --             end
            --         end)

            --         print("CoverPageMixin:Init - Set Description content:", desc)
            --         print("CoverPageMixin:Init - Description shown:", scrollContent.Description:IsShown())
            --         print("CoverPageMixin:Init - Description text:", scrollContent.Description:GetText())
            --     end
            -- end

            -- Show the scroll frame
            scrollFrame:Show()
        else
            -- Hide everything if no description
            if scrollContent then
                -- if scrollContent.HTML then
                --     scrollContent.HTML:Hide()
                -- end
                -- if scrollContent.Description then
                --     scrollContent.Description:Hide()
                -- end
                scrollContent:Hide()
            end
            print("CoverPageMixin:Init - No description content, hiding elements")
        end
    else
        print("CoverPageMixin:Init - ContentArea or DescriptionScrollFrame missing!")
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
