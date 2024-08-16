local FOLDER_NAME, private = ...

EventTitleMixin = {}
function EventTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
    end

    if (private.constants.config.currentYear < elementData.yearStart) then
        self.Dates:SetText("")
        return
    end

    if (elementData.yearEnd < private.constants.config.historyStartYear) then
        self.Dates:SetText("")
        return
    end

    if elementData.yearStart == elementData.yearEnd then
        self.Dates:SetText(elementData.yearStart)
    else
        self.Dates:SetText(tostring(elementData.yearStart) .. " - " .. tostring(elementData.yearEnd))
    end
end
