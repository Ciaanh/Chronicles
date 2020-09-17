local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyJournalView = {}

function Chronicles.UI.MyJournalView:Init()
    MyJournalView.Title:SetText(Locale["MyJournalView"])
    MyJournalViewList.Title:SetText(Locale["List"])
    MyJournalViewDetails.Title:SetText(Locale["Details"])
end
