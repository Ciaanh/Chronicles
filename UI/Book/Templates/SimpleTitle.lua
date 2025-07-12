local FOLDER_NAME, private = ...

-- =============================================================================================
-- SIMPLE TITLE MIXIN
-- =============================================================================================

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
