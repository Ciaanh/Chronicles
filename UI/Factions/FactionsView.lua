local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.FactionsView = {}

function Chronicles.UI.FactionsView:Init()
    FactionsView.Title:SetText(Locale["Factions"])
    FactionList.Title:SetText(Locale["List"])
    FactionDetails.Title:SetText(Locale["Details"])
end
