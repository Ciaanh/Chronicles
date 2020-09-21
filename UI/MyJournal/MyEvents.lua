local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}

function Chronicles.UI.MyEvents:Init(isVisible)
    MyEvents.Title:SetText(Locale["My Events"])

    MyEvents.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    MyEvents.Details:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    
    if (isVisible) then
        MyEvents:Show()
    else
        MyEvents:Hide()
    end
end
