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

    print(self.scrollOnMouse)
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
