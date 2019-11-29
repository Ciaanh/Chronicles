local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI = {}

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.UI:DisplayWindow() MainFrame:Show() end

function Chronicles.UI:HideWindow() MainFrame:Hide() end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
