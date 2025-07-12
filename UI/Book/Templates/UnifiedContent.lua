local FOLDER_NAME, private = ...

-- Import dependencies
local ContentUtils = private.Core.Utils.ContentUtils

-- =============================================================================================
-- UNIFIED CONTENT MIXIN
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
