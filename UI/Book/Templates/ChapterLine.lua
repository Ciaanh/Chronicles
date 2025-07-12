local FOLDER_NAME, private = ...

-- =============================================================================================
-- CHAPTER LINE MIXIN (Old Format Compatibility)
-- =============================================================================================

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
