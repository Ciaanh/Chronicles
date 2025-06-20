local FOLDER_NAME, private = ...

FactionTitleMixin = {}
function FactionTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
    end
end
