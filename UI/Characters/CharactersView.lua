local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.CharactersView = {}

function Chronicles.UI.CharactersView:Init()
    --CharactersView.Title:SetText(Locale["Characters"])

    -- CharacterList.Title:SetText(Locale["List"])
    CharacterDetails.Title:SetText(Locale["Details"])
end
