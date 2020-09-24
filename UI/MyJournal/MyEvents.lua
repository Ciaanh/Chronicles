local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}
Chronicles.UI.MyEvents.CurrentPage = 1

function Chronicles.UI.MyEvents:Init(isVisible)
    DEFAULT_CHAT_FRAME:AddMessage("-- init My Events")
    MyEvents.Title:SetText(Locale[":My Events"])

    MyEvents.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    MyEvents.Details:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    if (isVisible) then
        MyEvents:Show()
    else
        MyEvents:Hide()
    end

    Chronicles.UI.MyEvents:DisplayEventList(1)
end

function Chronicles.UI.MyEvents:DisplayEventList(page)
    DEFAULT_CHAT_FRAME:AddMessage("-- asked page My Events" .. page)

    local fakeEvent = {
        yearStart = "42",
        label = "toto"
    }

    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock1)
    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock2)
    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock3)
    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock4)
    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock5)
    Chronicles.UI.MyEvents:SetTextToFrame(fakeEvent, MyEventListBlock6)
end

function Chronicles.UI.MyEvents:SetTextToFrame(event, frame)
    if (frame.event ~= nil) then
        frame.event = nil
    end
    --frame:Hide()
    if (event ~= nil) then
        -- local label = _G[frame:GetName() .. "Text"]
        -- label:SetText(event.label)

        frame.Text:SetText(event.label)

        frame.event = event
        frame:SetScript(
            "OnMouseDown",
            function()
                --Chronicles.UI.EventDescription:DrawEventDescription(frame.event)
                DEFAULT_CHAT_FRAME:AddMessage("-- clicked event " .. event.label)
            end
        )
        frame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("-- set text " .. event.label)
    end
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function MyEventListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyEventListPreviousButton_OnClick(self)
    else
        MyEventListNextButton_OnClick(self)
    end
end

function MyEventListPreviousButton_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentPage == nil) then
        Chronicles.UI.MyEvents:DisplayEventList(1)
    else
        Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage - 1)
    end
end

function MyEventListNextButton_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentPage == nil) then
        Chronicles.UI.MyEvents:DisplayEventList(1)
    else
        Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage + 1)
    end
end
