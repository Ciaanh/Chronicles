local FOLDER_NAME, private = ...

CharacterTitleMixin = {}
function CharacterTitleMixin:Init(elementData)
    if elementData.text then
        self.Title:SetText(elementData.text)
    end
end
