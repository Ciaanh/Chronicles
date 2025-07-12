local FOLDER_NAME, private = ...

-- =============================================================================================
-- CHAPTER HEADER MIXIN (Old Format Compatibility)
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
