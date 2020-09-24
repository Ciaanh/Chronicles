local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyCharacters = {}

function Chronicles.UI.MyCharacters:Init(isVisible)
    DEFAULT_CHAT_FRAME:AddMessage("-- init My Characters")
    MyCharacters.Title:SetText(Locale[":My Characters"])

    MyCharacters.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    MyCharacters.Details:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    if (isVisible) then
        MyCharacters:Show()
    else
        MyCharacters:Hide()
    end
end
