local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI = {}

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.UI:Init()
    Chronicles.UI.Timeline:Init()
    Chronicles.UI.EventList:Init()
end

function Chronicles.UI:DisplayWindow()
    Chronicles.DB:LoadRolePlayProfile()
    MainFrame:Show()
end

function Chronicles.UI:HideWindow()
    MainFrame:Hide()
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
