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

    MyEventsDetailsDescription:SetBackdropColor(CreateColor(0.8, 0.65, 0.39))

    Chronicles.UI.MyEvents:DisplayEventList(1, true)

    if (isVisible) then
        MyEvents:Show()
    else
        MyEvents:Hide()
    end

    UIDropDownMenu_SetWidth(MyEventTypeDropDown, 95)
    UIDropDownMenu_JustifyText(MyEventTypeDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyEventTypeDropDown, Init_EventType_Dropdown)

    UIDropDownMenu_SetWidth(MyEventTimelineDropDown, 95)
    UIDropDownMenu_JustifyText(MyEventTimelineDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyEventTimelineDropDown, Init_Timeline_Dropdown)
end

function DisplayMyEventList(page)
    Chronicles.UI.MyEvents:DisplayEventList(page)
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
                Chronicles.UI.MyEvents:SetMyEventDetails(event)
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

function Chronicles.UI.MyEvents:SetMyEventDetails(event)
    -- id = 9,
    -- label = "My event 9",
    -- description = {"My event 9 label"},
    -- yearStart = -2800,
    -- yearEnd = -2800,
    -- eventType = 2,
    -- timeline = 2

    MyEventsDetails.Id:SetText(event.id)
    MyEventsDetails.Label:SetText(event.label)
    MyEventsDetails.Description:SetText(event.description[1])

    UIDropDownMenu_SetSelectedID(MyEventTypeDropDown, event.eventType)
    UIDropDownMenu_SetText(MyEventTypeDropDown, Chronicles.constants.eventType[event.eventType])

    UIDropDownMenu_SetSelectedID(MyEventTimelineDropDown, event.timeline)
    UIDropDownMenu_SetText(MyEventTimelineDropDown, Chronicles.constants.timelines[event.timeline])
end

function Init_EventType_Dropdown()
    --DEFAULT_CHAT_FRAME:AddMessage("-- Init_EventType_Dropdown " .. tostring(Chronicles.constants.eventType))

    for key, value in ipairs(Chronicles.constants.eventType) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyEventTypeDropDown
        info.arg2 = Chronicles.constants.eventType
        info.func = Set_DropdownValue

        info.notCheckable = true
        info.checked = false
        info.disabled = false

        --DEFAULT_CHAT_FRAME:AddMessage("-- event type " .. info.text .. " " .. info.value)

        UIDropDownMenu_AddButton(info)
    end
end

function Set_DropdownValue(self, frame, data)
    local index = self:GetID()
    DEFAULT_CHAT_FRAME:AddMessage("-- Set_DropdownValue " .. index .. " " .. data[index])
    UIDropDownMenu_SetSelectedID(frame, index)
    UIDropDownMenu_SetText(frame, data[index])
end

function Init_Timeline_Dropdown()
    for key, value in ipairs(Chronicles.constants.timelines) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyEventTimelineDropDown
        info.arg2 = Chronicles.constants.timelines
        info.func = Set_DropdownValue

        info.notCheckable = true
        info.checked = false
        info.disabled = false

        UIDropDownMenu_AddButton(info)
    end
end

function MyEventSave_Click()
    DEFAULT_CHAT_FRAME:AddMessage("-- saving my event ")

    --local index = MyEventTimelineDropDown.selectedID
    DEFAULT_CHAT_FRAME:AddMessage("-- eventtype selectedID " .. tostring(MyEventTypeDropDown.selectedID))

    DEFAULT_CHAT_FRAME:AddMessage("-- timeline selectedID " .. tostring(MyEventTimelineDropDown.selectedID))


    -- DEFAULT_CHAT_FRAME:AddMessage(
    --     "--MyEventTypeDropDown_GetSelectedID " .. tostring(UIDropDownMenu_GetSelectedID(MyEventTypeDropDown))
    -- )
    -- DEFAULT_CHAT_FRAME:AddMessage(
    --     "--MyEventTimelineDropDown_GetSelectedID " .. tostring(UIDropDownMenu_GetSelectedID(MyEventTimelineDropDown))
    -- )
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
