local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyEvents = {}
Chronicles.UI.MyEvents.CurrentPage = 1
Chronicles.UI.MyEvents.SelectedEvent = nil
Chronicles.UI.MyEvents.SelectedEvent_Factions = nil
Chronicles.UI.MyEvents.CurrentFactionsPage = 1
Chronicles.UI.MyEvents.SelectedEvent_Characters = nil
Chronicles.UI.MyEvents.CurrentCharactersPage = 1

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

    Chronicles.UI.MyEvents:InitFactionSearch()
    Chronicles.UI.MyEvents:InitCharacterSearch()

    Chronicles.UI.MyEvents:HideFields()
    Chronicles.UI.MyEvents:InitLocales()
end

function Chronicles.UI.MyEvents:InitLocales()
    MyEvents.Title:SetText(Locale[":My Events"])
    MyEventsDetailsYearStartError:SetText(Locale["ErrorYearAsNumber"])
    MyEventsDetailsYearEndError:SetText(Locale["ErrorYearAsNumber"])
    MyEventsDetailsYearOrderError:SetText(Locale["ErrorYearOrder"])

    MyEventsDetailsAddDescriptionPage:SetText(Locale["AddPage"])
    MyEventsDetailsRemoveDescriptionPage:SetText(Locale["RemovePage"])
    MyEventsDetailsSaveButton:SetText(Locale["Save"])
    MyEvents.List.AddButton:SetText(Locale["Add"])
    MyEventsDetailsRemoveEvent:SetText(Locale["Delete"])
    MyEventsDetailsFactionsCharactersToggle:SetText(Locale["FactionsCharacters"])

    MyEventsFactions_Label:SetText(Locale["Factions_List"])

    MyEvents.Details.IdContainer.Label:SetText(Locale["Id_Field"] .. " :")
    MyEvents.Details.TitleLabelContainer.TitleLabel:SetText(Locale["Title_Field"] .. " :")

    MyEventsDetailsYearStartLabel:SetText(Locale["YearStart_Field"] .. " :")
    MyEventsDetailsYearEndLabel:SetText(Locale["YearEnd_Field"] .. " :")
    MyEventsDetailsDescriptionsLabel:SetText(Locale["Description_Field"] .. " :")
    MyEventsDetailsEventTypeLabel:SetText(Locale["EventType_Field"] .. " :")
    MyEventsDetailsTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")
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

    MyEvents.List.ScrollBar.ScrollUpButton:Disable()
    MyEvents.List.ScrollBar.ScrollDownButton:Disable()
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
    MyEvents.Details.IdContainer.Id:Hide()
    MyEvents.Details.IdContainer.Label:Hide()

    MyEvents.Details.TitleLabelContainer.TitleLabel:Hide()
    MyEvents.Details.Title:Hide()

    MyEvents.Details.Fields:Hide()

    MyEventsDetailsYearStartErrorContainer:Hide()
    MyEventsDetailsYearEndErrorContainer:Hide()
    MyEventsDetailsYearOrderErrorContainer:Hide()
    MyEventsDetailsFactionsCharactersToggle:Hide()

    MyEventsDetailsSaveButton:Hide()
    MyEventsDetailsRemoveEvent:Hide()

    MyEvents.Details.FactionsCharacters:Hide()
    MyEventsDetailsFactionsCharactersToggle.displayed = false

    Chronicles.UI.MyEvents.SelectedEvent = nil
    Chronicles.UI.MyEvents.SelectedEvent_Factions = nil
    Chronicles.UI.MyEvents.SelectedEvent_Characters = nil
end

function Chronicles.UI.MyEvents:ShowFields()
    MyEvents.Details.IdContainer.Id:Show()
    MyEvents.Details.IdContainer.Label:Show()

    MyEvents.Details.TitleLabelContainer.TitleLabel:Show()
    MyEvents.Details.Title:Show()

    MyEvents.Details.Fields:Show()

    MyEventsDetailsFactionsCharactersToggle:Show()

    MyEventsDetailsSaveButton:Show()
    MyEventsDetailsRemoveEvent:Show()

    MyEvents.Details.FactionsCharacters:Hide()
    MyEventsDetailsFactionsCharactersToggle.displayed = false
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
            MyEvents.List.ScrollBar:SetMinMaxValues(1, maxPageValue)

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
                    MyEvents.List.ScrollBar.ScrollUpButton:Enable()
                    MyEvents.List.ScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyEvents.List.ScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyEvents.CurrentPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfEvents) then
                    lastIndex = numberOfEvents
                    MyEvents.List.ScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyEvents.CurrentPage = page
                MyEvents.List.ScrollBar:SetValue(Chronicles.UI.MyEvents.CurrentPage)

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
    MyEventsDetailsYearOrderErrorContainer:Hide()

    MyEvents.Details.FactionsCharacters.factionSearchBox:SetText("")
    MyEvents.Details.FactionsCharacters.characterSearchBox:SetText("")

    if (Chronicles.UI.MyEvents.SelectedEvent ~= nil and Chronicles.UI.MyEvents.SelectedEvent.id ~= nil) then
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

    Chronicles.UI.MyEvents.SelectedEvent = {}
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

    MyEvents.Details.IdContainer.Id:SetText(event.id)
    MyEvents.Details.Title:SetText(event.label)

    MyEventsDetailsYearStart:SetNumber(event.yearStart)
    MyEventsDetailsYearEnd:SetNumber(event.yearEnd)

    UIDropDownMenu_SetSelectedID(MyEventsDetailsTypeDropDown, event.eventType)
    UIDropDownMenu_SetText(MyEventsDetailsTypeDropDown, Chronicles.constants.eventType[event.eventType])

    UIDropDownMenu_SetSelectedID(MyEventsDetailsTimelineDropDown, event.timeline)
    UIDropDownMenu_SetText(MyEventsDetailsTimelineDropDown, Chronicles.constants.timelines[event.timeline])

    Chronicles.UI.MyEvents.SelectedEvent_Factions = copyTable(event.factions)
    Chronicles.UI.MyEvents:ChangeFactionsPage(1)
    Chronicles.UI.MyEvents.SelectedEvent_Characters = copyTable(event.characters)
    Chronicles.UI.MyEvents:ChangeCharactersPage(1)
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
    Chronicles.UI.MyEvents:SaveDescriptionPage()

    local yearStartNumber = tonumber(MyEventsDetailsYearStart:GetText())
    local yearEndNumber = tonumber(MyEventsDetailsYearEnd:GetText())

    MyEventsDetailsYearStartErrorContainer:Hide()
    MyEventsDetailsYearEndErrorContainer:Hide()
    MyEventsDetailsYearOrderErrorContainer:Hide()

    if (yearStartNumber == nil) then
        MyEventsDetailsYearStartErrorContainer:Show()
    end

    if (yearEndNumber == nil) then
        MyEventsDetailsYearEndErrorContainer:Show()
    end

    if (yearStartNumber == nil or yearEndNumber == nil) then
        return
    end

    if (yearStartNumber > yearEndNumber) then
        MyEventsDetailsYearOrderErrorContainer:Show()
        return
    end

    local event = {
        id = tonumber(MyEvents.Details.IdContainer.Id:GetText()),
        label = MyEvents.Details.Title:GetText(),
        description = copyTable(Chronicles.UI.MyEvents.SelectedEvent.description),
        yearStart = MyEventsDetailsYearStart:GetNumber(),
        yearEnd = MyEventsDetailsYearEnd:GetNumber(),
        eventType = MyEventsDetailsTypeDropDown.selectedID,
        timeline = MyEventsDetailsTimelineDropDown.selectedID,
        factions = copyTable(Chronicles.UI.MyEvents.SelectedEvent_Factions),
        characters = copyTable(Chronicles.UI.MyEvents.SelectedEvent_Characters),
        order = 0
    }

    Chronicles.DB:SetMyJournalEvents(event)
    Chronicles.UI.MyEvents:DisplayEventList(Chronicles.UI.MyEvents.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Dropdowns -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Init_EventType_Dropdown()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Init_EventType_Dropdown " .. tostring(Chronicles.constants.eventType))

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

        -- DEFAULT_CHAT_FRAME:AddMessage("-- event type " .. info.text .. " " .. info.value)

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
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Set_DropdownValue " .. index .. " " .. data[index])
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
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-- Factions and Characters View ----------------------------------------------------------
------------------------------------------------------------------------------------------

function MyEventsDetailsFactionsCharactersToggle_Click(self)
    if (self.displayed == true) then
        MyEvents.Details.FactionsCharacters:Hide()
        MyEvents.Details.Fields:Show()
        self.displayed = false
    else
        MyEvents.Details.FactionsCharacters:Show()
        MyEvents.Details.Fields:Hide()
        self.displayed = true
    end
end

local NUM_SEARCH_PREVIEWS = 5
local SHOW_ALL_RESULTS_INDEX = NUM_SEARCH_PREVIEWS + 1

------------------------------------------------------------------------------------------
-- Factions ------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function MyEventsFactions_Previous_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentFactionsPage == nil) then
        Chronicles.UI.MyEvents:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyEvents:ChangeFactionsPage(Chronicles.UI.MyEvents.CurrentFactionsPage - 1)
    end
end

function MyEventsFactions_Next_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentFactionsPage == nil) then
        Chronicles.UI.MyEvents:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyEvents:ChangeFactionsPage(Chronicles.UI.MyEvents.CurrentFactionsPage + 1)
    end
end

function MyEventsFactions_ScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyEventsFactions_Previous_OnClick(self)
    else
        MyEventsFactions_Next_OnClick(self)
    end
end

function MyEventsFactions_ChangePage(page)
    Chronicles.UI.MyEvents:ChangeFactionsPage(page)
end

function Chronicles.UI.MyEvents:ChangeFactionsPage(page)
    if
        (Chronicles.UI.MyEvents.SelectedEvent ~= nil and Chronicles.UI.MyEvents.SelectedEvent_Factions ~= nil and
            tablelength(Chronicles.UI.MyEvents.SelectedEvent_Factions) > 0)
     then
        local factionsList = Chronicles.DB:FindFactions(Chronicles.UI.MyEvents.SelectedEvent_Factions)
        local numberOfFactions = tablelength(factionsList)

        if (page ~= nil and numberOfFactions > 0) then
            local pageSize = Chronicles.constants.config.myJournal.eventFactionsPageSize

            Chronicles.UI.MyEvents:HideAllFactions()

            if (numberOfFactions > 0) then
                local maxPageValue = math.ceil(numberOfFactions / pageSize)
                MyEventsFactions_ScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                if (numberOfFactions > pageSize) then
                    MyEventsFactions_ScrollBar.ScrollUpButton:Enable()
                    MyEventsFactions_ScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyEventsFactions_ScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyEvents.CurrentFactionsPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    MyEventsFactions_ScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyEvents.CurrentFactionsPage = page
                MyEventsFactions_ScrollBar:SetValue(Chronicles.UI.MyEvents.CurrentFactionsPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex], MyEventsFactions_Block1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 1], MyEventsFactions_Block2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 2], MyEventsFactions_Block3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 3], MyEventsFactions_Block4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 4], MyEventsFactions_Block5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 5], MyEventsFactions_Block6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 6], MyEventsFactions_Block7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetFactionTextToFrame(factionsList[firstIndex + 7], MyEventsFactions_Block8)
                end
            end
        else
            Chronicles.UI.MyEvents:HideAllFactions()
        end
    else
        Chronicles.UI.MyEvents:HideAllFactions()
    end
end

function Chronicles.UI.MyEvents:SetFactionTextToFrame(faction, frame)
    if (frame.faction ~= nil) then
        frame.faction = nil
    end
    frame:Hide()
    if (faction ~= nil) then
        frame.Text:SetText(adjustTextLength(faction.name, 13, frame))
        frame.faction = faction
        frame.remove:Show()
        frame.remove:SetScript(
            "OnClick",
            function()
                Chronicles.UI.MyEvents:RemoveFaction(faction)
            end
        )

        frame:Show()
    else
        frame.remove:SetScript("OnClick", nil)
        frame.remove:Hide()
    end
end

function Chronicles.UI.MyEvents:RemoveFaction(faction)
    local indexToRemove = nil
    for index, id in ipairs(Chronicles.UI.MyEvents.SelectedEvent_Factions[faction.source]) do
        if (faction.id == id) then
            indexToRemove = index
            break
        end
    end

    if indexToRemove ~= nil then
        table.remove(Chronicles.UI.MyEvents.SelectedEvent_Factions[faction.source], indexToRemove)
    end

    Chronicles.UI.MyEvents:ChangeFactionsPage(1)
    Chronicles.UI.FactionsView:Refresh()
end

function Chronicles.UI.MyEvents:HideAllFactions()
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block1)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block2)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block3)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block4)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block5)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block6)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block7)
    Chronicles.UI.MyEvents:HideFaction(MyEventsFactions_Block8)

    MyEventsFactions_ScrollBar.ScrollUpButton:Disable()
    MyEventsFactions_ScrollBar.ScrollDownButton:Disable()

    Chronicles.UI.MyEvents.CurrentFactionsPage = nil
end

function Chronicles.UI.MyEvents:HideFaction(frame)
    frame:Hide()
    frame.faction = nil
    frame.remove:SetScript("OnClick", nil)
end

------------------------------------------------------------------------------------------
-- Factions Autocomplete -----------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyEvents:InitFactionSearch()
    local scrollFrame = MyEvents.Details.FactionsCharacters.factionSearchResults.scrollFrame
    scrollFrame.update = MyEventsFactions_UpdateFullSearchResults
    scrollFrame.scrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "MyEventsFactions_FullSearchResultsButton", 5, 0)

    SearchBoxTemplate_OnLoad(MyEvents.Details.FactionsCharacters.factionSearchBox)
    MyEvents.Details.FactionsCharacters.factionSearchBox.HasStickyFocus = function()
        return DoesAncestryInclude(MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer, GetMouseFocus())
    end
end

function MyEventsFactions_SearchBox_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 7)
    MyEventsFactions_SetSearchPreviewSelection(1)
end

function MyEventsFactions_SearchBox_Refresh(self)
    SearchBoxTemplate_OnTextChanged(self)

    if (strlen(self:GetText()) >= MIN_CHARACTER_SEARCH) then
        MyEventsFactions_ShowSearchPreviewResults()
    else
        MyEventsFactions_HideSearchPreview()
    end
end

function MyEventsFactions_SearchBox_OnFocusLost(self)
    SearchBoxTemplate_OnEditFocusLost(self)
    MyEventsFactions_HideSearchPreview()
end

function MyEventsFactions_SearchBox_OnFocusGained(self)
    SearchBoxTemplate_OnEditFocusGained(self)
    MyEvents.Details.FactionsCharacters.factionSearchResults:Hide()

    MyEventsFactions_SearchBox_Refresh(self)
end

function MyEventsFactions_SearchBox_OnKeyDown(self, key)
    if (key == "UP") then
        MyEventsFactions_SetSearchPreviewSelection(
            MyEvents.Details.FactionsCharacters.factionSearchBox.selectedIndex - 1
        )
    elseif (key == "DOWN") then
        MyEventsFactions_SetSearchPreviewSelection(
            MyEvents.Details.FactionsCharacters.factionSearchBox.selectedIndex + 1
        )
    end
end

function MyEventsFactions_HideSearchPreview()
    local factionSearchPreviewContainer = MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer
    local searchPreviews = factionSearchPreviewContainer.searchPreviews
    factionSearchPreviewContainer:Hide()

    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    factionSearchPreviewContainer.showAllSearchResults:Hide()
end

function MyEventsFactions_SetSearchPreviewSelection(selectedIndex)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_SetSearchPreviewSelection " .. tostring(selectedIndex))

    local factionSearchPreviewContainer = MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer
    local searchPreviews = factionSearchPreviewContainer.searchPreviews
    local numShown = 0
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        searchPreview.selectedTexture:Hide()

        if (searchPreview:IsShown()) then
            numShown = numShown + 1
        end
    end

    if (factionSearchPreviewContainer.showAllSearchResults:IsShown()) then
        numShown = numShown + 1
    end

    factionSearchPreviewContainer.showAllSearchResults.selectedTexture:Hide()

    if (numShown <= 0) then
        -- Default to the first entry.
        selectedIndex = 1
    else
        selectedIndex = (selectedIndex - 1) % numShown + 1
    end

    MyEvents.Details.FactionsCharacters.factionSearchBox.selectedIndex = selectedIndex

    if (selectedIndex == SHOW_ALL_RESULTS_INDEX) then
        factionSearchPreviewContainer.showAllSearchResults.selectedTexture:Show()
    else
        factionSearchPreviewContainer.searchPreviews[selectedIndex].selectedTexture:Show()
    end
end

function MyEventsFactions_ShowSearchPreviewResults()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_ShowSearchPreviewResults ")

    local searchtext = MyEvents.Details.FactionsCharacters.factionSearchBox:GetText()
    local factionSearchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(factionSearchResults)

    -- DEFAULT_CHAT_FRAME:AddMessage("---- numResults " .. numResults)
    if (numResults > 0) then
        MyEventsFactions_SetSearchPreviewSelection(1)
    end

    local factionSearchPreviewContainer = MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer
    local searchPreviews = factionSearchPreviewContainer.searchPreviews
    local lastButton

    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_ShowSearchPreviewResults " .. tablelength(searchPreviews))
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        if (index <= numResults) then
            local faction = factionSearchResults[index]

            searchPreview.name:SetText(faction.name)
            --searchPreview.icon:SetTexture(icon)
            searchPreview.factionID = {id = faction.id, group = faction.source}
            searchPreview:Show()
            lastButton = searchPreview
        else
            searchPreview.factionID = nil
            searchPreview:Hide()
        end
    end

    if (numResults > 5) then
        factionSearchPreviewContainer.showAllSearchResults:Show()
        lastButton = factionSearchPreviewContainer.showAllSearchResults
        factionSearchPreviewContainer.showAllSearchResults.text:SetText(
            string.format(ENCOUNTER_JOURNAL_SHOW_SEARCH_RESULTS, numResults)
        )
    else
        factionSearchPreviewContainer.showAllSearchResults:Hide()
    end

    if (lastButton) then
        factionSearchPreviewContainer.borderAnchor:SetPoint("BOTTOM", lastButton, "BOTTOM", 0, -5)
        factionSearchPreviewContainer.background:Hide()
        factionSearchPreviewContainer:Show()
    else
        factionSearchPreviewContainer:Hide()
    end
end

function MyEventsFactions_ShowAllSearchResults_OnEnter()
    MyEventsFactions_SetSearchPreviewSelection(SHOW_ALL_RESULTS_INDEX)
end

function MyEventsFactions_FullSearchResultsButton_OnClick(self)
    if (self.factionID) then
        MyEventsFactions_SelectSearchItem(self.factionID)
        MyEvents.Details.FactionsCharacters.factionSearchResults:Hide()
    end
end

function MyEventsFactions_SelectSearchItem(factionID)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_SelectSearchItem " .. factionID.id .. " " .. factionID.group)

    local results =
        Chronicles.DB:FindFactions(
        {
            [factionID.group] = {factionID.id}
        }
    )

    -- DEFAULT_CHAT_FRAME:AddMessage("---- results " .. tablelength(results))

    if (results ~= nil and tablelength(results) > 0) then
        if (Chronicles.UI.MyEvents.SelectedEvent_Factions[factionID.group] ~= nil) then
            for index, id in ipairs(Chronicles.UI.MyEvents.SelectedEvent_Factions[factionID.group]) do
                if (factionID.id == id) then
                    Chronicles.UI.MyEvents:ChangeFactionsPage(1)
                    return
                end
            end
            table.insert(Chronicles.UI.MyEvents.SelectedEvent_Factions[factionID.group], factionID.id)
        else
            Chronicles.UI.MyEvents.SelectedEvent_Factions[factionID.group] = {factionID.id}
        end
    end
    Chronicles.UI.MyEvents:ChangeFactionsPage(1)
    Chronicles.UI.FactionsView:Refresh()
end

function MyEventsFactions_SearchBox_OnUpdate(self)
    local factionSearchPreviewContainer = MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer
    local searchPreviews = factionSearchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    factionSearchPreviewContainer.showAllSearchResults:Hide()

    factionSearchPreviewContainer.borderAnchor:SetPoint("BOTTOM", 0, -5)
    factionSearchPreviewContainer.background:Show()
    factionSearchPreviewContainer:Show()
end

function MyEventsFactions_SearchPreviewButton_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10)
end

function MyEventsFactions_SearchPreviewButton_OnLoad(self)
    local factionSearchPreviewContainer = MyEvents.Details.FactionsCharacters.factionSearchPreviewContainer
    local searchPreviews = factionSearchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        if (searchPreviews[index] == self) then
            self.previewIndex = index
            break
        end
    end
end

function MyEventsFactions_SearchPreviewButton_OnEnter(self)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_SearchPreviewButton_OnEnter ")
    MyEventsFactions_SetSearchPreviewSelection(self.previewIndex)
end

function MyEventsFactions_SearchPreviewButton_OnClick(self)
    if (self.factionID) then
        MyEventsFactions_SelectSearchItem(self.factionID)
        MyEvents.Details.FactionsCharacters.factionSearchResults:Hide()
        MyEventsFactions_HideSearchPreview()
        MyEvents.Details.FactionsCharacters.factionSearchBox:ClearFocus()
    end
end

function MyEventsFactions_ShowFullSearch()
    MyEventsFactions_UpdateFullSearchResults()

    local searchtext = MyEvents.Details.FactionsCharacters.factionSearchBox:GetText()
    local factionSearchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(factionSearchResults)
    if (numResults == 0) then
        MyEvents.Details.FactionsCharacters.factionSearchResults:Hide()
        return
    end

    MyEventsFactions_HideSearchPreview()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsFactions_ShowFullSearch ")
    MyEvents.Details.FactionsCharacters.factionSearchBox:ClearFocus()
    MyEvents.Details.FactionsCharacters.factionSearchResults:Show()
end

function MyEventsFactions_UpdateFullSearchResults()
    local searchtext = MyEvents.Details.FactionsCharacters.factionSearchBox:GetText()
    local factionSearchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(factionSearchResults)

    local scrollFrame = MyEvents.Details.FactionsCharacters.factionSearchResults.scrollFrame
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local results = scrollFrame.buttons
    local result, index

    for i = 1, #results do
        result = results[i]
        index = offset + i
        if (index <= numResults) then
            local faction = factionSearchResults[index]

            result.name:SetText(faction.name)
            -- result.icon:SetTexture(icon)

            result.factionID = {id = faction.id, group = faction.source}

            local size = 75
            if (containsHTML(faction.description)) then
                result.description:SetText("")
            else
                result.description:SetText(faction.description:sub(0, size))
            end

            result:Show()
        else
            result:Hide()
        end
    end

    local totalHeight = numResults * 49
    HybridScrollFrame_Update(scrollFrame, totalHeight, 270)

    MyEvents.Details.FactionsCharacters.factionSearchResults.titleText:SetText(
        string.format(ENCOUNTER_JOURNAL_SEARCH_RESULTS, searchtext, numResults)
    )
end

------------------------------------------------------------------------------------------
-- Characters ------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function MyEventsCharacters_Previous_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentCharactersPage == nil) then
        Chronicles.UI.MyEvents:ChangeCharactersPage(1)
    else
        Chronicles.UI.MyEvents:ChangeCharactersPage(Chronicles.UI.MyEvents.CurrentCharactersPage - 1)
    end
end

function MyEventsCharacters_Next_OnClick(self)
    if (Chronicles.UI.MyEvents.CurrentCharactersPage == nil) then
        Chronicles.UI.MyEvents:ChangeCharactersPage(1)
    else
        Chronicles.UI.MyEvents:ChangeCharactersPage(Chronicles.UI.MyEvents.CurrentCharactersPage + 1)
    end
end

function MyEventsCharacters_ScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyEventsCharacters_Previous_OnClick(self)
    else
        MyEventsCharacters_Next_OnClick(self)
    end
end

function MyEventsCharacters_ChangePage(page)
    Chronicles.UI.MyEvents:ChangeCharactersPage(page)
end

function Chronicles.UI.MyEvents:ChangeCharactersPage(page)
    if
        (Chronicles.UI.MyEvents.SelectedEvent ~= nil and Chronicles.UI.MyEvents.SelectedEvent_Characters ~= nil and
            tablelength(Chronicles.UI.MyEvents.SelectedEvent_Characters) > 0)
     then
        local charactersList = Chronicles.DB:FindCharacters(Chronicles.UI.MyEvents.SelectedEvent_Characters)
        local numberOfCharacters = tablelength(charactersList)

        if (page ~= nil and numberOfCharacters > 0) then
            local pageSize = Chronicles.constants.config.myJournal.eventCharactersPageSize

            Chronicles.UI.MyEvents:HideAllCharacters()

            if (numberOfCharacters > 0) then
                local maxPageValue = math.ceil(numberOfCharacters / pageSize)
                MyEventsCharacters_ScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                if (numberOfCharacters > pageSize) then
                    MyEventsCharacters_ScrollBar.ScrollUpButton:Enable()
                    MyEventsCharacters_ScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyEventsCharacters_ScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyEvents.CurrentCharactersPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfCharacters) then
                    lastIndex = numberOfCharacters
                    MyEventsCharacters_ScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyEvents.CurrentCharactersPage = page
                MyEventsCharacters_ScrollBar:SetValue(Chronicles.UI.MyEvents.CurrentCharactersPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex],
                        MyEventsCharacters_Block1
                    )
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 1],
                        MyEventsCharacters_Block2
                    )
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 2],
                        MyEventsCharacters_Block3
                    )
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 3],
                        MyEventsCharacters_Block4
                    )
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 4],
                        MyEventsCharacters_Block5
                    )
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 5],
                        MyEventsCharacters_Block6
                    )
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 6],
                        MyEventsCharacters_Block7
                    )
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyEvents:SetCharacterTextToFrame(
                        charactersList[firstIndex + 7],
                        MyEventsCharacters_Block8
                    )
                end
            end
        else
            Chronicles.UI.MyEvents:HideAllCharacters()
        end
    else
        Chronicles.UI.MyEvents:HideAllCharacters()
    end
end

function Chronicles.UI.MyEvents:SetCharacterTextToFrame(character, frame)
    if (frame.character ~= nil) then
        frame.character = nil
    end
    frame:Hide()
    if (character ~= nil) then
        frame.Text:SetText(adjustTextLength(character.name, 13, frame))
        frame.character = character
        frame.remove:Show()
        frame.remove:SetScript(
            "OnClick",
            function()
                Chronicles.UI.MyEvents:RemoveCharacter(character)
            end
        )

        frame:Show()
    else
        frame.remove:SetScript("OnClick", nil)
        frame.remove:Hide()
    end
end

function Chronicles.UI.MyEvents:RemoveCharacter(character)
    local indexToRemove = nil
    for index, id in ipairs(Chronicles.UI.MyEvents.SelectedEvent_Characters[character.source]) do
        if (character.id == id) then
            indexToRemove = index
            break
        end
    end

    if indexToRemove ~= nil then
        table.remove(Chronicles.UI.MyEvents.SelectedEvent_Characters[character.source], indexToRemove)
    end

    Chronicles.UI.MyEvents:ChangeCharactersPage(1)
    Chronicles.UI.CharactersView:Refresh()
end

function Chronicles.UI.MyEvents:HideAllCharacters()
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block1)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block2)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block3)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block4)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block5)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block6)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block7)
    Chronicles.UI.MyEvents:HideCharacter(MyEventsCharacters_Block8)

    MyEventsCharacters_ScrollBar.ScrollUpButton:Disable()
    MyEventsCharacters_ScrollBar.ScrollDownButton:Disable()

    Chronicles.UI.MyEvents.CurrentCharactersPage = nil
end

function Chronicles.UI.MyEvents:HideCharacter(frame)
    frame:Hide()
    frame.character = nil
    frame.remove:SetScript("OnClick", nil)
end

------------------------------------------------------------------------------------------
-- Characters Autocomplete -----------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyEvents:InitCharacterSearch()
    local scrollFrame = MyEvents.Details.FactionsCharacters.characterSearchResults.scrollFrame
    scrollFrame.update = MyEventsCharacters_UpdateFullSearchResults
    scrollFrame.scrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "MyEventsCharacters_FullSearchResultsButton", 5, 0)

    SearchBoxTemplate_OnLoad(MyEvents.Details.FactionsCharacters.characterSearchBox)
    MyEvents.Details.FactionsCharacters.characterSearchBox.HasStickyFocus = function()
        return DoesAncestryInclude(MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer, GetMouseFocus())
    end
end

function MyEventsCharacters_SearchBox_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 7)
    MyEventsCharacters_SetSearchPreviewSelection(1)
end

function MyEventsCharacters_SearchBox_Refresh(self)
    SearchBoxTemplate_OnTextChanged(self)

    if (strlen(self:GetText()) >= MIN_CHARACTER_SEARCH) then
        MyEventsCharacters_ShowSearchPreviewResults()
    else
        MyEventsCharacters_HideSearchPreview()
    end
end

function MyEventsCharacters_SearchBox_OnFocusLost(self)
    SearchBoxTemplate_OnEditFocusLost(self)
    MyEventsCharacters_HideSearchPreview()
end

function MyEventsCharacters_SearchBox_OnFocusGained(self)
    SearchBoxTemplate_OnEditFocusGained(self)
    MyEvents.Details.FactionsCharacters.characterSearchResults:Hide()

    MyEventsCharacters_SearchBox_Refresh(self)
end

function MyEventsCharacters_SearchBox_OnKeyDown(self, key)
    if (key == "UP") then
        MyEventsCharacters_SetSearchPreviewSelection(
            MyEvents.Details.FactionsCharacters.characterSearchBox.selectedIndex - 1
        )
    elseif (key == "DOWN") then
        MyEventsCharacters_SetSearchPreviewSelection(
            MyEvents.Details.FactionsCharacters.characterSearchBox.selectedIndex + 1
        )
    end
end

function MyEventsCharacters_HideSearchPreview()
    local characterSearchPreviewContainer = MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer
    local searchPreviews = characterSearchPreviewContainer.searchPreviews
    characterSearchPreviewContainer:Hide()

    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    characterSearchPreviewContainer.showAllSearchResults:Hide()
end

function MyEventsCharacters_SetSearchPreviewSelection(selectedIndex)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_SetSearchPreviewSelection " .. tostring(selectedIndex))

    local characterSearchPreviewContainer = MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer
    local searchPreviews = characterSearchPreviewContainer.searchPreviews
    local numShown = 0
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        searchPreview.selectedTexture:Hide()

        if (searchPreview:IsShown()) then
            numShown = numShown + 1
        end
    end

    if (characterSearchPreviewContainer.showAllSearchResults:IsShown()) then
        numShown = numShown + 1
    end

    characterSearchPreviewContainer.showAllSearchResults.selectedTexture:Hide()

    if (numShown <= 0) then
        -- Default to the first entry.
        selectedIndex = 1
    else
        selectedIndex = (selectedIndex - 1) % numShown + 1
    end

    MyEvents.Details.FactionsCharacters.characterSearchBox.selectedIndex = selectedIndex

    if (selectedIndex == SHOW_ALL_RESULTS_INDEX) then
        characterSearchPreviewContainer.showAllSearchResults.selectedTexture:Show()
    else
        characterSearchPreviewContainer.searchPreviews[selectedIndex].selectedTexture:Show()
    end
end

function MyEventsCharacters_ShowSearchPreviewResults()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_ShowSearchPreviewResults ")

    local searchtext = MyEvents.Details.FactionsCharacters.characterSearchBox:GetText()
    local characterSearchResults = Chronicles.DB:SearchCharacters(searchtext)

    local numResults = tablelength(characterSearchResults)

    -- DEFAULT_CHAT_FRAME:AddMessage("---- numResults " .. numResults)
    if (numResults > 0) then
        MyEventsCharacters_SetSearchPreviewSelection(1)
    end

    local characterSearchPreviewContainer = MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer
    local searchPreviews = characterSearchPreviewContainer.searchPreviews
    local lastButton

    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_ShowSearchPreviewResults " .. tablelength(searchPreviews))
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        if (index <= numResults) then
            local character = characterSearchResults[index]

            searchPreview.name:SetText(character.name)
            --searchPreview.icon:SetTexture(icon)
            searchPreview.characterID = {id = character.id, group = character.source}
            searchPreview:Show()
            lastButton = searchPreview
        else
            searchPreview.characterID = nil
            searchPreview:Hide()
        end
    end

    if (numResults > 5) then
        characterSearchPreviewContainer.showAllSearchResults:Show()
        lastButton = characterSearchPreviewContainer.showAllSearchResults
        characterSearchPreviewContainer.showAllSearchResults.text:SetText(
            string.format(ENCOUNTER_JOURNAL_SHOW_SEARCH_RESULTS, numResults)
        )
    else
        characterSearchPreviewContainer.showAllSearchResults:Hide()
    end

    if (lastButton) then
        characterSearchPreviewContainer.borderAnchor:SetPoint("BOTTOM", lastButton, "BOTTOM", 0, -5)
        characterSearchPreviewContainer.background:Hide()
        characterSearchPreviewContainer:Show()
    else
        characterSearchPreviewContainer:Hide()
    end
end

function MyEventsCharacters_ShowAllSearchResults_OnEnter()
    MyEventsCharacters_SetSearchPreviewSelection(SHOW_ALL_RESULTS_INDEX)
end

function MyEventsCharacters_FullSearchResultsButton_OnClick(self)
    if (self.characterID) then
        MyEventsCharacters_SelectSearchItem(self.characterID)
        MyEvents.Details.FactionsCharacters.characterSearchResults:Hide()
    end
end

function MyEventsCharacters_SelectSearchItem(characterID)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_SelectSearchItem " .. characterID.id .. " " .. characterID.group)

    local results =
        Chronicles.DB:FindCharacters(
        {
            [characterID.group] = {characterID.id}
        }
    )

    -- DEFAULT_CHAT_FRAME:AddMessage("---- results " .. tablelength(results))

    if (results ~= nil and tablelength(results) > 0) then
        if (Chronicles.UI.MyEvents.SelectedEvent_Characters[characterID.group] ~= nil) then
            for index, id in ipairs(Chronicles.UI.MyEvents.SelectedEvent_Characters[characterID.group]) do
                if (characterID.id == id) then
                    Chronicles.UI.MyEvents:ChangeCharactersPage(1)
                    return
                end
            end
            table.insert(Chronicles.UI.MyEvents.SelectedEvent_Characters[characterID.group], characterID.id)
        else
            Chronicles.UI.MyEvents.SelectedEvent_Characters[characterID.group] = {characterID.id}
        end
    end
    Chronicles.UI.MyEvents:ChangeCharactersPage(1)
    Chronicles.UI.CharactersView:Refresh()
end

function MyEventsCharacters_SearchBox_OnUpdate(self)
    local characterSearchPreviewContainer = MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer
    local searchPreviews = characterSearchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    characterSearchPreviewContainer.showAllSearchResults:Hide()

    characterSearchPreviewContainer.borderAnchor:SetPoint("BOTTOM", 0, -5)
    characterSearchPreviewContainer.background:Show()
    characterSearchPreviewContainer:Show()
end

function MyEventsCharacters_SearchPreviewButton_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10)
end

function MyEventsCharacters_SearchPreviewButton_OnLoad(self)
    local characterSearchPreviewContainer = MyEvents.Details.FactionsCharacters.characterSearchPreviewContainer
    local searchPreviews = characterSearchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        if (searchPreviews[index] == self) then
            self.previewIndex = index
            break
        end
    end
end

function MyEventsCharacters_SearchPreviewButton_OnEnter(self)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_SearchPreviewButton_OnEnter ")
    MyEventsCharacters_SetSearchPreviewSelection(self.previewIndex)
end

function MyEventsCharacters_SearchPreviewButton_OnClick(self)
    if (self.characterID) then
        MyEventsCharacters_SelectSearchItem(self.characterID)
        MyEvents.Details.FactionsCharacters.characterSearchResults:Hide()
        MyEventsCharacters_HideSearchPreview()
        MyEvents.Details.FactionsCharacters.characterSearchBox:ClearFocus()
    end
end

function MyEventsCharacters_ShowFullSearch()
    MyEventsCharacters_UpdateFullSearchResults()

    local searchtext = MyEvents.Details.FactionsCharacters.characterSearchBox:GetText()
    local characterSearchResults = Chronicles.DB:SearchCharacters(searchtext)

    local numResults = tablelength(characterSearchResults)
    if (numResults == 0) then
        MyEvents.Details.FactionsCharacters.characterSearchResults:Hide()
        return
    end

    MyEventsCharacters_HideSearchPreview()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- MyEventsCharacters_ShowFullSearch ")
    MyEvents.Details.FactionsCharacters.characterSearchBox:ClearFocus()
    MyEvents.Details.FactionsCharacters.characterSearchResults:Show()
end

function MyEventsCharacters_UpdateFullSearchResults()
    local searchtext = MyEvents.Details.FactionsCharacters.characterSearchBox:GetText()
    local characterSearchResults = Chronicles.DB:SearchCharacters(searchtext)

    local numResults = tablelength(characterSearchResults)

    local scrollFrame = MyEvents.Details.FactionsCharacters.characterSearchResults.scrollFrame
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local results = scrollFrame.buttons
    local result, index

    for i = 1, #results do
        result = results[i]
        index = offset + i
        if (index <= numResults) then
            local character = characterSearchResults[index]

            result.name:SetText(character.name)
            -- result.icon:SetTexture(icon)

            result.characterID = {id = character.id, group = character.source}

            local size = 75
            if (containsHTML(character.description)) then
                result.description:SetText("")
            else
                result.description:SetText(character.description:sub(0, size))
            end

            result:Show()
        else
            result:Hide()
        end
    end

    local totalHeight = numResults * 49
    HybridScrollFrame_Update(scrollFrame, totalHeight, 270)

    MyEvents.Details.FactionsCharacters.characterSearchResults.titleText:SetText(
        string.format(ENCOUNTER_JOURNAL_SEARCH_RESULTS, searchtext, numResults)
    )
end
