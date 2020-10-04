local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}
Chronicles.UI.MyEvents.CurrentPage = 1
Chronicles.UI.MyEvents.SelectedEvent = {}

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

    UIDropDownMenu_SetWidth(MyEventsDetailsTypeDropDown, 95)
    UIDropDownMenu_JustifyText(MyEventsDetailsTypeDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyEventsDetailsTypeDropDown, Init_EventType_Dropdown)

    UIDropDownMenu_SetWidth(MyEventsDetailsTimelineDropDown, 95)
    UIDropDownMenu_JustifyText(MyEventsDetailsTimelineDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyEventsDetailsTimelineDropDown, Init_Timeline_Dropdown)

    Chronicles.UI.MyEvents:HideFields()
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

function Chronicles.UI.MyEvents:HideFields()
    MyEventsDetailsIdLabel:Hide()
    MyEventsDetailsId:Hide()
    MyEventsDetailsTitleLabel:Hide()
    MyEventsDetailsYearStartLabel:Hide()
    MyEventsDetailsYearEndLabel:Hide()
    MyEventsDetailsDescriptionsLabel:Hide()
    MyEventsDetailsDescriptionPager:Hide()
    MyEventsDetailsEventTypeLabel:Hide()
    MyEventsDetailsTimelineLabel:Hide()
    MyEventsDetailsTypeDropDown:Hide()
    MyEventsDetailsTimelineDropDown:Hide()
    MyEventsDetailsTitle:Hide()
    MyEventsDetailsYearStart:Hide()
    MyEventsDetailsYearEnd:Hide()
    MyEventsDetailsDescriptionContainer:Hide()
    MyEventsDetailsDescriptionPrevious:Hide()
    MyEventsDetailsDescriptionNext:Hide()
    MyEventsDetailsSaveButton:Hide()
    MyEventsDetailsAddDescriptionPage:Hide()
    MyEventsDetailsRemoveDescriptionPage:Hide()
end

function Chronicles.UI.MyEvents:ShowFields()
    MyEventsDetailsIdLabel:Show()
    MyEventsDetailsId:Show()
    MyEventsDetailsTitleLabel:Show()
    MyEventsDetailsYearStartLabel:Show()
    MyEventsDetailsYearEndLabel:Show()
    MyEventsDetailsDescriptionsLabel:Show()
    MyEventsDetailsDescriptionPager:Show()
    MyEventsDetailsEventTypeLabel:Show()
    MyEventsDetailsTimelineLabel:Show()
    MyEventsDetailsTypeDropDown:Show()
    MyEventsDetailsTimelineDropDown:Show()
    MyEventsDetailsTitle:Show()
    MyEventsDetailsYearStart:Show()
    MyEventsDetailsYearEnd:Show()
    MyEventsDetailsDescriptionContainer:Show()
    MyEventsDetailsDescriptionPrevious:Show()
    MyEventsDetailsDescriptionNext:Show()
    MyEventsDetailsSaveButton:Show()
    MyEventsDetailsAddDescriptionPage:Show()
    MyEventsDetailsRemoveDescriptionPage:Show()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

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
                Chronicles.UI.MyEvents:SetMyEventDetails(event)
            end
        )
        frame:Show()
    end
end

function MyEventsDetailsAddEvent_OnClick()
    DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsDetailsAddEvent_OnClick ")
    local event = {
        id = nil,
        label = "Title",
        description = {""},
        yearStart = 0,
        yearEnd = 0,
        eventType = 1,
        timeline = 1
    }
    Chronicles.DB:SetMyJournalEvents(event)
end

function MyEventsDetailsRemoveEvent_OnClick()
    DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsDetailsRemoveEvent_OnClick ")
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyEvents:SetMyEventDetails(event)
    if (Chronicles.UI.MyEvents.SelectedEvent.id ~= nil) then
        if (event.id == Chronicles.UI.MyEvents.SelectedEvent.id) then
            return
        end
        Chronicles.UI.MyEvents:SaveDescriptionPage()
    end

    if (event == nil) then
        Chronicles.UI.MyEvents:HideFields()
    else
        Chronicles.UI.MyEvents:ShowFields()
    end

    Chronicles.UI.MyEvents.SelectedEvent.id = event.id
    Chronicles.UI.MyEvents.SelectedEvent.description = copyTable(event.description)

    if (Chronicles.UI.MyEvents.SelectedEvent.description ~= nil) then
        local nbDescriptionPage = tablelength(Chronicles.UI.MyEvents.SelectedEvent.description)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- Pages " .. nbDescriptionPage)

        Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages = nbDescriptionPage
        if (nbDescriptionPage > 0) then
            Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage = 1
            Chronicles.UI.MyEvents:ChangeEventDescriptionPage(1)
        else
            Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages = 1
            Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage = 1
            Chronicles.UI.MyEvents.SelectedEvent.description[1] = ""
            MyEventsDetailsDescription:SetText("")

            MyEventsDetailsDescriptionPrevious:Hide()
            MyEventsDetailsDescriptionNext:Hide()
            MyEventsDetailsDescriptionPager:Hide()
        end
    end

    -- id = 9,
    -- label = "My event 9",
    -- description = {"My event 9 label"},
    -- yearStart = -2800,
    -- yearEnd = -2800,
    -- eventType = 2,
    -- timeline = 2

    MyEventsDetails.Id:SetText(event.id)
    MyEventsDetails.Title:SetText(event.label)

    MyEventsDetails.YearStart:SetText(event.yearStart)
    MyEventsDetails.YearEnd:SetText(event.yearEnd)

    UIDropDownMenu_SetSelectedID(MyEventsDetailsTypeDropDown, event.eventType)
    UIDropDownMenu_SetText(MyEventsDetailsTypeDropDown, Chronicles.constants.eventType[event.eventType])

    UIDropDownMenu_SetSelectedID(MyEventsDetailsTimelineDropDown, event.timeline)
    UIDropDownMenu_SetText(MyEventsDetailsTimelineDropDown, Chronicles.constants.timelines[event.timeline])
end

function Chronicles.UI.MyEvents:ChangeEventDescriptionPage(page)
    MyEventsDetailsDescriptionPrevious:Hide()
    MyEventsDetailsDescriptionNext:Hide()
    MyEventsDetailsDescriptionPager:Hide()

    if (Chronicles.UI.MyEvents.SelectedEvent.id ~= nil and Chronicles.UI.MyEvents.SelectedEvent.description ~= nil) then
        if (page < 1) then
            page = 1
        end
        if (page > Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages) then
            page = Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages
        end

        if (Chronicles.UI.MyEvents.SelectedEvent.description[page] ~= nil) then
            Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage = page

            -- DEFAULT_CHAT_FRAME:AddMessage("-- Set description " .. page)

            MyEventsDetailsDescription:SetText(Chronicles.UI.MyEvents.SelectedEvent.description[page])

            if (Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages > 1) then
                local text = "" .. page .. " / " .. Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages
                MyEventsDetailsDescriptionPager:SetText(text)

                if (page <= 1) then
                    MyEventsDetailsDescriptionPrevious:Disable()
                else
                    MyEventsDetailsDescriptionPrevious:Enable()
                end

                if (page >= Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages) then
                    MyEventsDetailsDescriptionNext:Disable()
                else
                    MyEventsDetailsDescriptionNext:Enable()
                end

                MyEventsDetailsDescriptionPager:Show()
                MyEventsDetailsDescriptionPrevious:Show()
                MyEventsDetailsDescriptionNext:Show()
            end
        end
    end
end

function MyEventsDetailsSave_Click()
    DEFAULT_CHAT_FRAME:AddMessage("-- saving my event ")

    DEFAULT_CHAT_FRAME:AddMessage("-- eventtype selectedID " .. tostring(MyEventsDetailsTypeDropDown.selectedID))
    DEFAULT_CHAT_FRAME:AddMessage("-- timeline selectedID " .. tostring(MyEventsDetailsTimelineDropDown.selectedID))

    DEFAULT_CHAT_FRAME:AddMessage("-- timeline Id " .. tostring(MyEventsDetails.Id:GetText()))
    DEFAULT_CHAT_FRAME:AddMessage("-- timeline Title " .. tostring(MyEventsDetails.Title:GetText()))

    -- DEFAULT_CHAT_FRAME:AddMessage("-- timeline YearStart " .. tostring(MyEventsDetails.YearStart:GetNumber()))
    -- DEFAULT_CHAT_FRAME:AddMessage("-- timeline YearEnd " .. tostring(MyEventsDetails.YearEnd:GetNumber()))

    DEFAULT_CHAT_FRAME:AddMessage("-- timeline YearStart " .. tostring(MyEventsDetails.YearStart:GetText()))
    DEFAULT_CHAT_FRAME:AddMessage("-- timeline YearEnd " .. tostring(MyEventsDetails.YearEnd:GetText()))

    local yearStart = tonumber(MyEventsDetails.YearStart:GetText())
    local yearEnd = tonumber(MyEventsDetails.YearEnd:GetText())

    -- DEFAULT_CHAT_FRAME:AddMessage(
    --     "--MyEventsDetailsTypeDropDown_GetSelectedID " .. tostring(UIDropDownMenu_GetSelectedID(MyEventsDetailsTypeDropDown))
    -- )
    -- DEFAULT_CHAT_FRAME:AddMessage(
    --     "--MyEventsDetailsTimelineDropDown_GetSelectedID " .. tostring(UIDropDownMenu_GetSelectedID(MyEventsDetailsTimelineDropDown))
    -- )
end

function Chronicles.UI.MyEvents:ClearDetails()
    DEFAULT_CHAT_FRAME:AddMessage("-- ClearDetails ")
end

------------------------------------------------------------------------------------------
-- Dropdowns -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Init_EventType_Dropdown()
    --DEFAULT_CHAT_FRAME:AddMessage("-- Init_EventType_Dropdown " .. tostring(Chronicles.constants.eventType))

    for key, value in ipairs(Chronicles.constants.eventType) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyEventsDetailsTypeDropDown
        info.arg2 = Chronicles.constants.eventType
        info.func = Set_DropdownValue

        info.notCheckable = true
        info.checked = false
        info.disabled = false

        --DEFAULT_CHAT_FRAME:AddMessage("-- event type " .. info.text .. " " .. info.value)

        UIDropDownMenu_AddButton(info)
    end
end

function Init_Timeline_Dropdown()
    for key, value in ipairs(Chronicles.constants.timelines) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyEventsDetailsTimelineDropDown
        info.arg2 = Chronicles.constants.timelines
        info.func = Set_DropdownValue

        info.notCheckable = true
        info.checked = false
        info.disabled = false

        UIDropDownMenu_AddButton(info)
    end
end

function Set_DropdownValue(self, frame, data)
    local index = self:GetID()
    --DEFAULT_CHAT_FRAME:AddMessage("-- Set_DropdownValue " .. index .. " " .. data[index])
    UIDropDownMenu_SetSelectedID(frame, index)
    UIDropDownMenu_SetText(frame, data[index])
end

------------------------------------------------------------------------------------------
-- Descriptions --------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyEvents:SaveDescriptionPage()
    if
        (Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage ~= nil and
            Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage ~= 0)
     then
        local text = MyEventsDetailsDescription:GetText()

        -- DEFAULT_CHAT_FRAME:AddMessage("-- SaveDescriptionPage text " .. text)
        -- DEFAULT_CHAT_FRAME:AddMessage(
        --     "-- SaveDescriptionPage page " .. Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage
        -- )

        Chronicles.UI.MyEvents.SelectedEvent.description[Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage] =
            text
    end
end

function MyEventsDetailsAddDescriptionPage_OnClick()
    Chronicles.UI.MyEvents:SaveDescriptionPage()

    local maxIndex = Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages + 1

    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsDetailsAddDescriptionPage_OnClick " .. maxIndex)

    Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages = maxIndex
    Chronicles.UI.MyEvents.SelectedEvent.description[maxIndex] = ""

    Chronicles.UI.MyEvents:ChangeEventDescriptionPage(maxIndex)
end

function MyEventsDetailsRemoveDescriptionPage_OnClick()
    Chronicles.UI.MyEvents:SaveDescriptionPage()

    table.remove(
        Chronicles.UI.MyEvents.SelectedEvent.description,
        Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages
    )

    local nbDescriptionPage = tablelength(Chronicles.UI.MyEvents.SelectedEvent.description)
    Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages = nbDescriptionPage

    if (nbDescriptionPage > 0) then
        Chronicles.UI.MyEvents:ChangeEventDescriptionPage(nbDescriptionPage)
    else
        Chronicles.UI.MyEvents.SelectedEvent.description[1] = ""
        Chronicles.UI.MyEvents:ChangeEventDescriptionPage(1)

        MyEventsDetailsDescriptionPrevious:Hide()
        MyEventsDetailsDescriptionNext:Hide()
        MyEventsDetailsDescriptionPager:Hide()
    end
end

function MyEventsDetailsDescriptionNext_OnClick()
    if
        (Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage ==
            Chronicles.UI.MyEvents.SelectedEvent.MaxDescriptionPages)
     then
        return
    end
    Chronicles.UI.MyEvents:SaveDescriptionPage()
    Chronicles.UI.MyEvents:ChangeEventDescriptionPage(Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage + 1)
end

function MyEventsDetailsDescriptionPrevious_OnClick()
    if (Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage == 0) then
        return
    end
    Chronicles.UI.MyEvents:SaveDescriptionPage()
    Chronicles.UI.MyEvents:ChangeEventDescriptionPage(Chronicles.UI.MyEvents.SelectedEvent.CurrentDescriptionPage - 1)
end

------------------------------------------------------------------------------------------
-- Scroll List ---------------------------------------------------------------------------
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
