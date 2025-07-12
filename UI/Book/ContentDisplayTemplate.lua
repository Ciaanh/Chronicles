--[[
    ContentDisplayTemplate.lua
    
    Modern UI mixins for the Chronicles addon book template system.
    See BOOK_TEMPLATES.md for comprehensive documentation of all templates and data structures.
    
    Note: Content utilities have been moved to Core/Utils/ContentUtils.lua
]]

local FOLDER_NAME, private = ...

-- Import dependencies
local ContentUtils = private.Core.Utils.ContentUtils

-- =============================================================================================
-- UI MIXINS
-- =============================================================================================

--[[
    Mixin for unified content display components
]]
UnifiedContentMixin = {}

--[[
    Initialize unified content display
    @param elementData [table] Element data with content and formatting options
]]
function UnifiedContentMixin:Init(elementData)
    if not elementData then
        return
    end

    local htmlContent = ""

    if elementData.htmlContent then
        htmlContent = elementData.htmlContent
    elseif elementData.text then
        htmlContent = ContentUtils.ConvertTextToHTML(elementData.text, elementData.portraitPath)
    end

    if htmlContent ~= "" and self.ScrollFrame and self.ScrollFrame.HTML then
        local parentWidth = self:GetParent() and self:GetParent():GetWidth() or 400
        local contentWidth = math.max(parentWidth - 40, 300) -- Account for padding and scrollbar

        self.ScrollFrame.HTML:SetSize(contentWidth, 1)
        self.ScrollFrame.HTML:SetText(htmlContent)

        local estimatedHeight = elementData.estimatedHeight or 400
        self:SetHeight(estimatedHeight)
    end
end

--[[
    Mixin for content scroll frame components
]]
ContentScrollFrameMixin = {}

--[[
    Initialize scroll frame with scrollbar support
]]
function ContentScrollFrameMixin:OnLoad()
    if not self.noScrollBar then
        local scrollBarTemplate = self.scrollBarTemplate or "MinimalScrollBar"

        local left = self.scrollBarX or 14
        local top = self.scrollBarTopY or -5
        local bottom = self.scrollBarBottomY or 5

        local scrollBar = CreateFrame("EventFrame", nil, self, scrollBarTemplate)
        scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", left, top)
        scrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", left, bottom)

        self.ScrollBar = scrollBar

        local function updateScrollBar()
            local scrollRange = self:GetVerticalScrollRange()
            local scrollOffset = self:GetVerticalScroll()

            if scrollRange > 0 then
                local scrollPercentage = scrollOffset / scrollRange
                scrollBar:SetScrollPercentage(scrollPercentage, ScrollBoxConstants.NoScrollInterpolation)

                local visibleExtent = self:GetHeight() / (scrollRange + self:GetHeight())
                scrollBar:SetVisibleExtentPercentage(visibleExtent)
            end
        end

        self:SetScript("OnVerticalScroll", updateScrollBar)
        self:SetScript("OnScrollRangeChanged", updateScrollBar)

        if self.scrollOnMouse then
            self:SetScript(
                "OnMouseWheel",
                function(_, delta)
                    scrollBar:ScrollStepInDirection(-delta)
                end
            )
        end

        scrollBar:RegisterCallback(
            BaseScrollBoxEvents.OnScroll,
            function(_, scrollPercentage)
                local scroll = scrollPercentage * self:GetVerticalScrollRange()
                self:SetVerticalScroll(scroll)
            end
        )
    end
end

--[[
    Mixin for cover with content display
]]
CoverWithContentMixin = {}

--[[
    Initialize cover display with entity information
    @param elementData [table] Element data containing entity information
]]
function CoverWithContentMixin:Init(elementData)
    if not elementData or not elementData.entity then
        return
    end

    local entity = elementData.entity

    if entity.name or entity.label then
        if self.Name then
            self.Name:SetText(entity.name or entity.label)
        end
    end

    if entity.author and entity.author ~= "" then
        if self.Author then
            self.Author:SetText("Author: " .. entity.author)
            self.Author:Show()
        end
    else
        if self.Author then
            self.Author:Hide()
        end
    end

    local htmlContent = ""
    if entity.description then
        htmlContent = ContentUtils.ConvertTextToHTML(entity.description, elementData.portraitPath)
    end

    if self.ContentFrame and htmlContent ~= "" then
        self.ContentFrame:Init(
            {
                htmlContent = htmlContent,
                portraitPath = elementData.portraitPath,
                estimatedHeight = 300
            }
        )
    end
end

--[[
    Mixin for page break elements
]]
PageBreakMixin = {}

--[[
    Initialize page break element
    @param elementData [table] Element data for page break configuration
]]
function PageBreakMixin:Init(elementData)
    -- Simple page break - could be enhanced with page numbers
end
