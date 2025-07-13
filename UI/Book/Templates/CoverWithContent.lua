local FOLDER_NAME, private = ...

-- Import dependencies directly
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- =============================================================================================
-- COVER WITH CONTENT MIXIN
-- =============================================================================================

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
        if elementData.portraitPath and elementData.portraitPath ~= "" then
            htmlContent = HTMLBuilder.CreateContentWithPortrait(entity.description, elementData.portraitPath)
        else
            htmlContent = HTMLBuilder.ConvertTextToHTML(entity.description)
        end
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
