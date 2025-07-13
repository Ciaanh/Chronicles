local FOLDER_NAME, private = ...

-- Import dependencies directly
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- =============================================================================================
-- HTML CONTENT MIXIN
-- =============================================================================================

--[[
    Mixin for HTML content display components - the single HTML container
]]
HTMLContentMixin = {}

--[[
    Initialize HTML content display
    @param elementData [table] Element data with content and formatting options
]]
function HTMLContentMixin:Init(elementData)
    if not elementData then
        return
    end

    local htmlContent = ""

    if elementData.htmlContent then
        htmlContent = elementData.htmlContent
    elseif elementData.text then
        htmlContent = HTMLBuilder.ConvertTextToHTML(elementData.text, elementData.portraitPath)
        if elementData.portraitPath and elementData.portraitPath ~= "" then
            htmlContent = HTMLBuilder.CreateContentWithPortrait(elementData.text, elementData.portraitPath)
        end
    end

    if htmlContent ~= "" and self.ScrollFrame and self.ScrollFrame.HTML then
        local parentWidth = self:GetParent() and self:GetParent():GetWidth() or 400
        local contentWidth = math.max(parentWidth - 40, 300) -- Account for padding and scrollbar

        self.ScrollFrame.HTML:SetSize(contentWidth, 1)
        self.ScrollFrame.HTML:SetText(htmlContent)

        -- Reset scroll position to top when new content is loaded
        if self.ScrollFrame.SetVerticalScroll then
            self.ScrollFrame:SetVerticalScroll(0)
        end

        local estimatedHeight = elementData.estimatedHeight or 400
        self:SetHeight(estimatedHeight)
    end
end
