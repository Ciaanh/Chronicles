local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyFactions = {}
Chronicles.UI.MyFactions.CurrentPage = 1
Chronicles.UI.MyFactions.SelectedFaction = {}

function Chronicles.UI.MyFactions:Init(isVisible)
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

    Chronicles.UI.MyFactions:DisplayFactionList(1, true)

    if (isVisible) then
        MyFactions:Show()
    else
        MyFactions:Hide()
    end

    UIDropDownMenu_SetWidth(MyFactionsDetailsTimelineDropDown, 95)
    UIDropDownMenu_JustifyText(MyFactionsDetailsTimelineDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyFactionsDetailsTimelineDropDown, Init_MyFactions_Timeline_Dropdown)

    Chronicles.UI.MyFactions:HideFields()

    Chronicles.UI.MyFactions:InitLocales()
end

function Chronicles.UI.MyFactions:InitLocales()
    MyFactions.Name:SetText(Locale[":My Factions"])

    MyFactionsDetailsSaveButton:SetText(Locale["Save"])
    MyFactionsListAddFaction:SetText(Locale["AddFaction"])
    MyFactionsDetailsRemoveFaction:SetText(Locale["Delete"])
    
    MyFactionsDetailsIdLabel:SetText(Locale["Id_Field"] .. " :")
    MyFactionsDetailsNameLabel:SetText(Locale["Name_Field"] .. " :")
    MyFactionsDetailsDescriptionsLabel:SetText(Locale["Description_Field"] .. " :")
    MyFactionsDetailsTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")
end

function Chronicles.UI.MyFactions:HideAll()
    MyFactionsListBlock1:Hide()
    MyFactionsListBlock2:Hide()
    MyFactionsListBlock3:Hide()
    MyFactionsListBlock4:Hide()
    MyFactionsListBlock5:Hide()
    MyFactionsListBlock6:Hide()
    MyFactionsListBlock7:Hide()
    MyFactionsListBlock8:Hide()
    MyFactionsListBlock9:Hide()

    MyFactionsListScrollBar.ScrollUpButton:Disable()
    MyFactionsListScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.MyFactions:WipeAll()
    if (MyFactionsListBlock1.faction ~= nil) then
        MyFactionsListBlock1.faction = nil
    end

    if (MyFactionsListBlock2.faction ~= nil) then
        MyFactionsListBlock2.faction = nil
    end

    if (MyFactionsListBlock3.faction ~= nil) then
        MyFactionsListBlock3.faction = nil
    end

    if (MyFactionsListBlock4.faction ~= nil) then
        MyFactionsListBlock4.faction = nil
    end

    if (MyFactionsListBlock5.faction ~= nil) then
        MyFactionsListBlock5.faction = nil
    end

    if (MyFactionsListBlock6.faction ~= nil) then
        MyFactionsListBlock6.faction = nil
    end

    if (MyFactionsListBlock7.faction ~= nil) then
        MyFactionsListBlock7.faction = nil
    end

    if (MyFactionsListBlock8.faction ~= nil) then
        MyFactionsListBlock8.faction = nil
    end

    if (MyFactionsListBlock9.faction ~= nil) then
        MyFactionsListBlock9.faction = nil
    end

    Chronicles.UI.MyFactions.CurrentPage = nil
end

function Chronicles.UI.MyFactions:HideFields()
    MyFactionsDetailsIdLabel:Hide()
    MyFactionsDetailsId:Hide()
    MyFactionsDetailsNameLabel:Hide()
    MyFactionsDetailsDescriptionsLabel:Hide()
    MyFactionsDetailsTimelineLabel:Hide()
    MyFactionsDetailsTimelineDropDown:Hide()
    MyFactionsDetailsName:Hide()
    MyFactionsDetailsDescriptionContainer:Hide()
    MyFactionsDetailsSaveButton:Hide()
    MyFactionsDetailsRemoveFaction:Hide()
end

function Chronicles.UI.MyFactions:ShowFields()
    MyFactionsDetailsIdLabel:Show()
    MyFactionsDetailsId:Show()
    MyFactionsDetailsNameLabel:Show()
    MyFactionsDetailsDescriptionsLabel:Show()
    MyFactionsDetailsTimelineLabel:Show()
    MyFactionsDetailsTimelineDropDown:Show()
    MyFactionsDetailsName:Show()
    MyFactionsDetailsDescriptionContainer:Show()
    MyFactionsDetailsSaveButton:Show()
    MyFactionsDetailsRemoveFaction:Show()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function DisplayMyFactionsList(page)
    Chronicles.UI.MyFactions:DisplayFactionList(page)
end

function Chronicles.UI.MyFactions:DisplayFactionList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.myJournal.factionListPageSize
        local factionList = Chronicles.DB:GetMyJournalFactions()

        local numberOfFactions = tablelength(factionList)

        if (numberOfFactions > 0) then
            local maxPageValue = math.ceil(numberOfFactions / pageSize)
            MyFactionsListScrollBar:SetMinMaxValues(1, maxPageValue)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (Chronicles.UI.MyFactions.CurrentPage ~= page or force) then
                Chronicles.UI.MyFactions:HideAll()
                Chronicles.UI.MyFactions:WipeAll()

                if (numberOfFactions > pageSize) then
                    MyFactionsListScrollBar.ScrollUpButton:Enable()
                    MyFactionsListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 8

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyFactionsListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyFactions.CurrentPage = 1
                end

                if ((firstIndex + 5) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    MyFactionsListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyFactions.CurrentPage = page
                MyFactionsListScrollBar:SetValue(Chronicles.UI.MyFactions.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex], MyFactionsListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 1], MyFactionsListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 2], MyFactionsListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 3], MyFactionsListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 4], MyFactionsListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 5], MyFactionsListBlock6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 6], MyFactionsListBlock7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 7], MyFactionsListBlock8)
                end

                if (((firstIndex + 8) > 0) and ((firstIndex + 8) <= lastIndex)) then
                    Chronicles.UI.MyFactions:SetTextToFrame(factionList[firstIndex + 8], MyFactionsListBlock9)
                end
            end
        else
            Chronicles.UI.MyFactions:HideAll()
        end
    end
end

function Chronicles.UI.MyFactions:SetTextToFrame(faction, frame)
    if (frame.faction ~= nil) then
        frame.faction = nil
    end
    frame:Hide()
    if (faction ~= nil) then
        frame.Text:SetText(adjustTextLength(faction.name, 15, frame))
        frame.faction = faction
        frame:SetScript(
            "OnMouseDown",
            function()
                Chronicles.UI.MyFactions:SetMyFactionDetails(faction)
            end
        )
        frame:Show()
    end
end

function MyFactionsListAddFaction_OnClick()
    local faction = {
        id = nil,
        name = "New faction",
        description = "",
        timeline = 1
    }
    Chronicles.DB:SetMyJournalFactions(faction)
    Chronicles.UI.MyFactions:DisplayFactionList(Chronicles.UI.MyFactions.CurrentPage, true)
    Chronicles.UI:Refresh()
end

function MyFactionsDetailsRemoveFaction_OnClick()
    Chronicles.DB:RemoveMyJournalFaction(Chronicles.UI.MyFactions.SelectedFaction.id)
    Chronicles.UI.MyFactions:HideFields()
    Chronicles.UI.MyFactions.SelectedFaction = {}
    Chronicles.UI.MyFactions:DisplayFactionList(Chronicles.UI.MyFactions.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyFactions:SetMyFactionDetails(faction)
    if (faction == nil) then
        Chronicles.UI.MyFactions:HideFields()
    else
        Chronicles.UI.MyFactions:ShowFields()
    end

    Chronicles.UI.MyFactions.SelectedFaction.id = faction.id

    -- id=[integer],				-- Id of the faction
    -- name=[string], 				-- name of the faction
    -- description=[string],		-- description
    -- timeline=[integer],    		-- id of the timeline

    MyFactionsDetailsId:SetText(faction.id)
    MyFactionsDetailsName:SetText(faction.name)
    MyFactionsDetailsDescription:SetText(faction.description)

    UIDropDownMenu_SetSelectedID(MyFactionsDetailsTimelineDropDown, faction.timeline)
    UIDropDownMenu_SetText(MyFactionsDetailsTimelineDropDown, Chronicles.constants.timelines[faction.timeline])
end

function MyFactionsDetailsSave_Click()
    local faction = {
        id = tonumber(MyFactionsDetailsId:GetText()),
        name = MyFactionsDetailsName:GetText(),
        description = MyFactionsDetailsDescription:GetText(),
        timeline = MyFactionsDetailsTimelineDropDown.selectedID
    }

    Chronicles.DB:SetMyJournalFactions(faction)
    Chronicles.UI.MyFactions:DisplayFactionList(Chronicles.UI.MyFactions.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Dropdowns -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Init_MyFactions_Timeline_Dropdown()
    for key, value in ipairs(Chronicles.constants.timelines) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyFactionsDetailsTimelineDropDown
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
    UIDropDownMenu_SetSelectedID(frame, index)
    UIDropDownMenu_SetText(frame, data[index])
end

------------------------------------------------------------------------------------------
-- Scroll List ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function MyFactionsListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyFactionsListPreviousButton_OnClick(self)
    else
        MyFactionsListNextButton_OnClick(self)
    end
end

function MyFactionsListPreviousButton_OnClick(self)
    if (Chronicles.UI.MyFactions.CurrentPage == nil) then
        Chronicles.UI.MyFactions:DisplayFactionList(1)
    else
        Chronicles.UI.MyFactions:DisplayFactionList(Chronicles.UI.MyFactions.CurrentPage - 1)
    end
end

function MyFactionsListNextButton_OnClick(self)
    if (Chronicles.UI.MyFactions.CurrentPage == nil) then
        Chronicles.UI.MyFactions:DisplayFactionList(1)
    else
        Chronicles.UI.MyFactions:DisplayFactionList(Chronicles.UI.MyFactions.CurrentPage + 1)
    end
end
