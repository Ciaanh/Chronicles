local FOLDER_NAME, private = ...

-- =============================================================================================
-- EVENT TITLE MIXIN
-- =============================================================================================

EventTitleMixin = {}
function EventTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
        self.Title:Show()
    else
        self.Title:SetText("")
        self.Title:Hide()
    end

    -- Set author (hide if not present)
    if elementData.author and elementData.author ~= "" then
        self.Author:SetText(elementData.author)
        self.Author:Show()
    else
        self.Author:SetText("")
        self.Author:Hide()
    end

    -- Set dates
    if elementData.yearStart and private.constants.config.currentYear < elementData.yearStart then
        self.Dates:SetText("")
        self.Dates:Hide()
        return
    end

    if elementData.yearEnd and elementData.yearEnd < private.constants.config.historyStartYear then
        self.Dates:SetText("")
        self.Dates:Hide()
        return
    end

    if elementData.yearStart and elementData.yearEnd then
        local dateText
        if elementData.yearStart == elementData.yearEnd then
            dateText = tostring(elementData.yearStart)
        else
            dateText = tostring(elementData.yearStart) .. " - " .. tostring(elementData.yearEnd)
        end
        self.Dates:SetText(dateText)
        self.Dates:Show()
    else
        self.Dates:SetText("")
        self.Dates:Hide()
    end
end
