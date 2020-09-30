local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyFactions = {}

function Chronicles.UI.MyFactions:Init(isVisible)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- init My Factions")

    MyFactions.Title:SetText(Locale[":My Factions"])

    MyFactions.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    MyFactions.Details:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    if (isVisible) then
        MyFactions:Show()
    else
        MyFactions:Hide()
    end
end
