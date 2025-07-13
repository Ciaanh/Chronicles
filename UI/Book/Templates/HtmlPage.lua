local FOLDER_NAME, private = ...

-- =============================================================================================
-- HTML PAGE MIXIN (Old Format Compatibility)
-- =============================================================================================

HtmlPageMixin = {}
function HtmlPageMixin:Init(elementData)
    if not elementData then 
        return 
    end
    
    -- Handle both 'content' and 'text' properties
    local htmlContent = elementData.content or elementData.text
    if htmlContent and self.ScrollFrame and self.ScrollFrame.HTML then
        self.ScrollFrame.HTML:SetText(htmlContent)
        
        -- Reset scroll position to top when new content is loaded
        if self.ScrollFrame.SetVerticalScroll then
            self.ScrollFrame:SetVerticalScroll(0)
        end
    end
end
