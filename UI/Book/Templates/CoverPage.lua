local FOLDER_NAME, private = ...

-- =============================================================================================
-- COVER PAGE MIXIN
-- =============================================================================================

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
    else
        -- Hide portrait and frame if no image
        if self.Portrait then
            self.Portrait:Hide()
        end
        if self.PortraitFrame then
            self.PortraitFrame:Hide()
        end
    end

    -- Set description using unified content system
    local scrollContent = self.ContentArea and self.ContentArea.DescriptionScrollFrame and 
                         self.ContentArea.DescriptionScrollFrame.HTML
    local desc = elementData.text

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
        
        -- Use HTMLBuilder directly for better portrait integration
        local finalContent = desc
        if private.Core.Utils.HTMLBuilder then
            if isHTML then
                finalContent = private.Core.Utils.HTMLBuilder.CreateContentWithPortrait("", elementData.image) .. desc
            else
                finalContent = private.Core.Utils.HTMLBuilder.CreateContentWithPortrait(desc, elementData.image)
            end
        else
            -- Fallback logic
            if isHTML then
                local cleanText = desc
                if
                    private and private.Core and private.Core.Utils and private.Core.Utils.StringUtils and
                        private.Core.Utils.StringUtils.CleanHTML
                 then
                    cleanText = private.Core.Utils.StringUtils.CleanHTML(desc)
                end
                finalContent = cleanText
            else
                finalContent = "<html><body><p>" .. desc .. "</p></body></html>"
            end
        end
        
        scrollContent:SetText(finalContent)
        
        -- Reset scroll position to top when new content is loaded
        if self.ContentArea and self.ContentArea.DescriptionScrollFrame and self.ContentArea.DescriptionScrollFrame.SetVerticalScroll then
            self.ContentArea.DescriptionScrollFrame:SetVerticalScroll(0)
        end
        
        scrollContent:Show()
    else
        if scrollContent then
            scrollContent:Hide()
        end
    end
end
