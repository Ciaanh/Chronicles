local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}
Chronicles.UI.MyEvents.CurrentPage = 1

function Chronicles.UI.MyEvents:Init(isVisible)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- init My Events")
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

    Chronicles.UI.MyEvents:DisplayEventList(1, true)

    if (isVisible) then
        MyEvents:Show()
    else
        MyEvents:Hide()
    end
end

function Chronicles.UI.MyEvents:DisplayEventList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.myJournal.eventListPageSize
        local eventList = Chronicles.DB:GetMyJournalEvents() 
        local numberOfEvents = tablelength(eventList)

        if (numberOfEvents > 0) then
            local maxPageValue = math.ceil(numberOfEvents / pageSize)
            MyEventListScrollBar:SetMinMaxValues(1, maxPageValue)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (Chronicles.UI.MyEvents.CurrentPage ~= page or force) then
                Chronicles.UI.MyEvents:HideAll()
                Chronicles.UI.MyEvents:WipeAll()

                if (numberOfEvents > pageSize) then
                    MyEventListScrollBar.ScrollUpButton:Enable()
                    MyEventListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 8

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyEventListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyEvents.CurrentPage = 1
                end

                if ((firstIndex + 5) >= numberOfEvents) then
                    lastIndex = numberOfEvents
                    MyEventListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyEvents.CurrentPage = page
                MyEventListScrollBar:SetValue(Chronicles.UI.MyEvents.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex], MyEventListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 1], MyEventListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 2], MyEventListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 3], MyEventListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 4], MyEventListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 5], MyEventListBlock6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 6], MyEventListBlock7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 7], MyEventListBlock8)
                end

                if (((firstIndex + 8) > 0) and ((firstIndex + 8) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetTextToFrame(eventList[firstIndex + 8], MyEventListBlock9)
                end
            end
        else
            Chronicles.UI.MyEvents:HideAll()
        end
    end
end

function Chronicles.UI.MyEvents:SetTextToFrame(event, frame)
    if (frame.event ~= nil) then
        frame.event = nil
    end
    frame:Hide()
    if (event ~= nil) then
        frame.Text:SetText(event.label)

        frame.event = event
        frame:SetScript(
            "OnMouseDown",
            function()
                --Chronicles.UI.EventDescription:DrawEventDescription(frame.event)
                DEFAULT_CHAT_FRAME:AddMessage("-- clicked my event " .. event.label)
            end
        )
        frame:Show()
    --DEFAULT_CHAT_FRAME:AddMessage("-- set text " .. event.label)
    end
end

function Chronicles.UI.MyEvents:HideAll()
    MyEventListBlock1:Hide()
    MyEventListBlock2:Hide()
    MyEventListBlock3:Hide()
    MyEventListBlock4:Hide()
    MyEventListBlock5:Hide()
    MyEventListBlock6:Hide()
    MyEventListBlock7:Hide()
    MyEventListBlock8:Hide()
    MyEventListBlock9:Hide()

    MyEventListScrollBar.ScrollUpButton:Disable()
    MyEventListScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.MyEvents:WipeAll()
    if (MyEventListBlock1.event ~= nil) then
        MyEventListBlock1.event = nil
    end

    if (MyEventListBlock2.event ~= nil) then
        MyEventListBlock2.event = nil
    end

    if (MyEventListBlock3.event ~= nil) then
        MyEventListBlock3.event = nil
    end

    if (MyEventListBlock4.event ~= nil) then
        MyEventListBlock4.event = nil
    end

    if (MyEventListBlock5.event ~= nil) then
        MyEventListBlock5.event = nil
    end

    if (MyEventListBlock6.event ~= nil) then
        MyEventListBlock6.event = nil
    end

    if (MyEventListBlock7.event ~= nil) then
        MyEventListBlock7.event = nil
    end

    if (MyEventListBlock8.event ~= nil) then
        MyEventListBlock8.event = nil
    end

    if (MyEventListBlock9.event ~= nil) then
        MyEventListBlock9.event = nil
    end

    -- if (self.Data ~= nil) then
    --     self.Data = nil
    -- end
    -- self.Data = nil
    self.CurrentPage = nil
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
