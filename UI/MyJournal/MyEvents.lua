local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}
Chronicles.UI.MyEvents.CurrentPage = 1
Chronicles.UI.MyEvents.SelectedEvent = {}

function Chronicles.UI.MyEvents:Init(isVisible)
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

    Chronicles.UI.MyEvents:InitLocales()
end

function Chronicles.UI.MyEvents:InitLocales()
    MyEvents.Title:SetText(Locale[":My Events"])
    MyEventsDetailsYearStartError:SetText(Locale["ErrorYearAsNumber"])
    MyEventsDetailsYearEndError:SetText(Locale["ErrorYearAsNumber"])

    MyEventsDetailsAddDescriptionPage:SetText(Locale["AddPage"])
    MyEventsDetailsRemoveDescriptionPage:SetText(Locale["RemovePage"])
    MyEventsDetailsSaveButton:SetText(Locale["Save"])

    MyEventsListAddEvent:SetText(Locale["AddEvent"])
    MyEventsDetailsRemoveEvent:SetText(Locale["RemoveEvent"])

    MyEventsDetailsIdLabel:SetText(Locale["Id"] .. " :")
    MyEventsDetailsTitleLabel:SetText(Locale["Title"] .. " :")
    MyEventsDetailsYearStartLabel:SetText(Locale["YearStart"] .. " :")
    MyEventsDetailsYearEndLabel:SetText(Locale["YearEnd"] .. " :")
    MyEventsDetailsDescriptionsLabel:SetText(Locale["Description"] .. " :")
    MyEventsDetailsEventTypeLabel:SetText(Locale["EventType"] .. " :")
    MyEventsDetailsTimelineLabel:SetText(Locale["Timeline"] .. " :")
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

    MyEventsListScrollBar.ScrollUpButton:Disable()
    MyEventsListScrollBar.ScrollDownButton:Disable()
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
    MyEventsDetailsRemoveEvent:Hide()
    MyEventsDetailsYearStartErrorContainer:Hide()
    MyEventsDetailsYearEndErrorContainer:Hide()
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
    MyEventsDetailsRemoveEvent:Show()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function DisplayMyEventsList(page)
    Chronicles.UI.MyEvents:DisplayEventList(page)
end

function Chronicles.UI.MyEvents:FilterEvents(events)
    local foundEvents = {}
    for eventIndex, event in pairs(events) do
        if event ~= nil then
            table.insert(foundEvents, event)
        end
    end

    table.sort(
        foundEvents,
        function(a, b)
            return a.yearStart < b.yearStart
        end
    )
    return foundEvents
end

function Chronicles.UI.MyEvents:DisplayEventList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.myJournal.eventListPageSize
        local eventList = Chronicles.UI.MyEvents:FilterEvents(Chronicles.DB:GetMyJournalEvents())

        local numberOfEvents = tablelength(eventList)

        if (numberOfEvents > 0) then
            local maxPageValue = math.ceil(numberOfEvents / pageSize)
            MyEventsListScrollBar:SetMinMaxValues(1, maxPageValue)

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
                    MyEventsListScrollBar.ScrollUpButton:Enable()
                    MyEventsListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 8

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyEventsListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyEvents.CurrentPage = 1
                end

                if ((firstIndex + 5) >= numberOfEvents) then
                    lastIndex = numberOfEvents
                    MyEventsListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyEvents.CurrentPage = page
                MyEventsListScrollBar:SetValue(Chronicles.UI.MyEvents.CurrentPage)

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

function MyEventsListAddEvent_OnClick()
    local event = {
        id = nil,
        label = "New event",
        description = {""},
        yearStart = 0,
        yearEnd = 0,
        eventType = 1,
        timeline = 1
    }
    Chronicles.DB:SetMyJournalEvents(event)
    Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage, true)
    Chronicles.UI:Refresh()
end

function MyEventsDetailsRemoveEvent_OnClick()
    Chronicles.DB:RemoveMyJournalEvent(Chronicles.UI.MyEvents.SelectedEvent.id)
    Chronicles.UI.MyEvents:HideFields()
    Chronicles.UI.MyEvents.SelectedEvent = {}
    Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyEvents:SetMyEventDetails(event)
    MyEventsDetailsYearStartErrorContainer:Hide()
    MyEventsDetailsYearEndErrorContainer:Hide()
    
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

    -- MyEventsDetails.YearStart:SetText(event.yearStart)
    -- MyEventsDetails.YearEnd:SetText(event.yearEnd)

    MyEventsDetails.YearStart:SetNumber(event.yearStart)
    MyEventsDetails.YearEnd:SetNumber(event.yearEnd)

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
    local yearStartNumber = tonumber(MyEventsDetails.YearStart:GetText())
    local yearEndNumber = tonumber(MyEventsDetails.YearEnd:GetText())

    if (yearStartNumber == nil) then
        MyEventsDetailsYearStartErrorContainer:Show()
    end

    if (yearEndNumber == nil) then
        MyEventsDetailsYearEndErrorContainer:Show()
    end

    if (yearStartNumber == nil or yearEndNumber == nil) then
        return
    end

    MyEventsDetailsYearStartErrorContainer:Hide()
    MyEventsDetailsYearEndErrorContainer:Hide()

    local event = {
        id = tonumber(MyEventsDetails.Id:GetText()),
        label = MyEventsDetails.Title:GetText(),
        description = copyTable(Chronicles.UI.MyEvents.SelectedEvent.description),
        yearStart = MyEventsDetails.YearStart:GetNumber(),
        yearEnd = MyEventsDetails.YearEnd:GetNumber(),
        eventType = MyEventsDetailsTypeDropDown.selectedID,
        timeline = MyEventsDetailsTimelineDropDown.selectedID
    }

    Chronicles.DB:SetMyJournalEvents(event)
    Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage, true)
    Chronicles.UI:Refresh()
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
function MyEventsListScrollFrame_OnMouseWheel(self, value)
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
