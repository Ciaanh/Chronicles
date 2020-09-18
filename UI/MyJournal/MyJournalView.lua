local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyJournalView = {}

function Chronicles.UI.MyJournalView:Init()
    MyJournalView.Title:SetText(Locale["My Journal"])

    MyEvents.Title:SetText(Locale["My Events"])
    MyCharacters.Title:SetText(Locale["My Characters"])
    MyFactions.Title:SetText(Locale["My Factions"])
end
