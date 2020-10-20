local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyCharacters = {}
Chronicles.UI.MyCharacters.CurrentPage = 1
Chronicles.UI.MyCharacters.SelectedCharacter = {}

function Chronicles.UI.MyCharacters:Init(isVisible)
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

    Chronicles.UI.MyCharacters:DisplayCharacterList(1, true)

    if (isVisible) then
        MyCharacters:Show()
    else
        MyCharacters:Hide()
    end

    UIDropDownMenu_SetWidth(MyCharactersDetailsTimelineDropDown, 95)
    UIDropDownMenu_JustifyText(MyCharactersDetailsTimelineDropDown, "LEFT")
    UIDropDownMenu_Initialize(MyCharactersDetailsTimelineDropDown, Init_MyCharacters_Timeline_Dropdown)

    Chronicles.UI.MyCharacters:HideFields()

    Chronicles.UI.MyCharacters:InitLocales()
end

function Chronicles.UI.MyCharacters:InitLocales()
    MyCharacters.Name:SetText(Locale[":My Characters"])

    MyCharactersDetailsSaveButton:SetText(Locale["Save"])
    MyCharactersListAddCharacter:SetText(Locale["AddCharacter"])
    MyCharactersDetailsRemoveCharacter:SetText(Locale["Delete"])

    MyCharactersDetailsIdLabel:SetText(Locale["Id_Field"] .. " :")
    MyCharactersDetailsNameLabel:SetText(Locale["Name_Field"] .. " :")
    MyCharactersDetailsBiographyLabel:SetText(Locale["Biography_Field"] .. " :")
    MyCharactersDetailsTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")
end

function Chronicles.UI.MyCharacters:HideAll()
    MyCharactersListBlock1:Hide()
    MyCharactersListBlock2:Hide()
    MyCharactersListBlock3:Hide()
    MyCharactersListBlock4:Hide()
    MyCharactersListBlock5:Hide()
    MyCharactersListBlock6:Hide()
    MyCharactersListBlock7:Hide()
    MyCharactersListBlock8:Hide()
    MyCharactersListBlock9:Hide()

    MyCharactersListScrollBar.ScrollUpButton:Disable()
    MyCharactersListScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.MyCharacters:WipeAll()
    if (MyCharactersListBlock1.character ~= nil) then
        MyCharactersListBlock1.character = nil
    end

    if (MyCharactersListBlock2.character ~= nil) then
        MyCharactersListBlock2.character = nil
    end

    if (MyCharactersListBlock3.character ~= nil) then
        MyCharactersListBlock3.character = nil
    end

    if (MyCharactersListBlock4.character ~= nil) then
        MyCharactersListBlock4.character = nil
    end

    if (MyCharactersListBlock5.character ~= nil) then
        MyCharactersListBlock5.character = nil
    end

    if (MyCharactersListBlock6.character ~= nil) then
        MyCharactersListBlock6.character = nil
    end

    if (MyCharactersListBlock7.character ~= nil) then
        MyCharactersListBlock7.character = nil
    end

    if (MyCharactersListBlock8.character ~= nil) then
        MyCharactersListBlock8.character = nil
    end

    if (MyCharactersListBlock9.character ~= nil) then
        MyCharactersListBlock9.character = nil
    end

    Chronicles.UI.MyCharacters.CurrentPage = nil
end

function Chronicles.UI.MyCharacters:HideFields()
    MyCharactersDetailsIdLabel:Hide()
    MyCharactersDetailsId:Hide()
    MyCharactersDetailsNameLabel:Hide()
    MyCharactersDetailsBiographyLabel:Hide()
    MyCharactersDetailsTimelineLabel:Hide()
    MyCharactersDetailsTimelineDropDown:Hide()
    MyCharactersDetailsName:Hide()
    MyCharactersDetailsBiographyContainer:Hide()
    MyCharactersDetailsSaveButton:Hide()
    MyCharactersDetailsRemoveCharacter:Hide()
end

function Chronicles.UI.MyCharacters:ShowFields()
    MyCharactersDetailsIdLabel:Show()
    MyCharactersDetailsId:Show()
    MyCharactersDetailsNameLabel:Show()
    MyCharactersDetailsBiographyLabel:Show()
    MyCharactersDetailsTimelineLabel:Show()
    MyCharactersDetailsTimelineDropDown:Show()
    MyCharactersDetailsName:Show()
    MyCharactersDetailsBiographyContainer:Show()
    MyCharactersDetailsSaveButton:Show()
    MyCharactersDetailsRemoveCharacter:Show()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function DisplayMyCharactersList(page)
    Chronicles.UI.MyCharacters:DisplayCharacterList(page)
end

function Chronicles.UI.MyCharacters:DisplayCharacterList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.myJournal.characterListPageSize
        local characterList = Chronicles.DB:GetMyJournalCharacters()

        local numberOfCharacters = tablelength(characterList)

        if (numberOfCharacters > 0) then
            local maxPageValue = math.ceil(numberOfCharacters / pageSize)
            MyCharactersListScrollBar:SetMinMaxValues(1, maxPageValue)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (Chronicles.UI.MyCharacters.CurrentPage ~= page or force) then
                Chronicles.UI.MyCharacters:HideAll()
                Chronicles.UI.MyCharacters:WipeAll()

                if (numberOfCharacters > pageSize) then
                    MyCharactersListScrollBar.ScrollUpButton:Enable()
                    MyCharactersListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyCharactersListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyCharacters.CurrentPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfCharacters) then
                    lastIndex = numberOfCharacters
                    MyCharactersListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyCharacters.CurrentPage = page
                MyCharactersListScrollBar:SetValue(Chronicles.UI.MyCharacters.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex], MyCharactersListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 1], MyCharactersListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 2], MyCharactersListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 3], MyCharactersListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 4], MyCharactersListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 5], MyCharactersListBlock6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 6], MyCharactersListBlock7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 7], MyCharactersListBlock8)
                end

                if (((firstIndex + 8) > 0) and ((firstIndex + 8) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetTextToFrame(characterList[firstIndex + 8], MyCharactersListBlock9)
                end
            end
        else
            Chronicles.UI.MyCharacters:HideAll()
        end
    end
end

function Chronicles.UI.MyCharacters:SetTextToFrame(character, frame)
    if (frame.character ~= nil) then
        frame.character = nil
    end
    frame:Hide()
    if (character ~= nil) then
        frame.Text:SetText(adjustTextLength(character.name, 15, frame))
        frame.character = character
        frame:SetScript(
            "OnMouseDown",
            function()
                Chronicles.UI.MyCharacters:SetMyCharacterDetails(character)
            end
        )
        frame:Show()
    end
end

function MyCharactersListAddCharacter_OnClick()
    local character = {
        id = nil,
        name = "New character",
        biography = "",
        timeline = 1,
        factions = {}

        -- id=[integer],				-- Id of the character
        -- name=[string], 				-- name of the character
        -- biography=[string],			-- small biography
        -- timeline=[integer],    		-- id of the timeline
        -- factions=table[integer], 	-- concerned factions
    }
    Chronicles.DB:SetMyJournalCharacters(character)
    Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage, true)
    Chronicles.UI:Refresh()
end

function MyCharactersDetailsRemoveCharacter_OnClick()
    Chronicles.DB:RemoveMyJournalCharacter(Chronicles.UI.MyCharacters.SelectedCharacter.id)
    Chronicles.UI.MyCharacters:HideFields()
    Chronicles.UI.MyCharacters.SelectedCharacter = {}
    Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.MyCharacters:SetMyCharacterDetails(character)
    if (character == nil) then
        Chronicles.UI.MyCharacters:HideFields()
    else
        Chronicles.UI.MyCharacters:ShowFields()
    end

    Chronicles.UI.MyCharacters.SelectedCharacter.id = character.id

    -- id=[integer],				-- Id of the character
    -- name=[string], 				-- name of the character
    -- biography=[string],			-- small biography
    -- timeline=[integer],    		-- id of the timeline
    -- factions=table[integer], 	-- concerned factions

    MyCharactersDetailsId:SetText(character.id)
    MyCharactersDetailsName:SetText(character.name)
    MyCharactersDetailsBiography:SetText(character.biography)

    UIDropDownMenu_SetSelectedID(MyCharactersDetailsTimelineDropDown, character.timeline)
    UIDropDownMenu_SetText(MyCharactersDetailsTimelineDropDown, Chronicles.constants.timelines[character.timeline])
end

function MyCharactersDetailsSave_Click()
    local character = {
        id = tonumber(MyCharactersDetailsId:GetText()),
        name = MyCharactersDetailsName:GetText(),
        biography = MyCharactersDetailsBiography:GetText(),
        timeline = MyCharactersDetailsTimelineDropDown.selectedID
    }

    Chronicles.DB:SetMyJournalCharacters(character)
    Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage, true)
    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Dropdowns -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Init_MyCharacters_Timeline_Dropdown()
    for key, value in ipairs(Chronicles.constants.timelines) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyCharactersDetailsTimelineDropDown
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
function MyCharactersListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyCharactersListPreviousButton_OnClick(self)
    else
        MyCharactersListNextButton_OnClick(self)
    end
end

function MyCharactersListPreviousButton_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentPage == nil) then
        Chronicles.UI.MyCharacters:DisplayCharacterList(1)
    else
        Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage - 1)
    end
end

function MyCharactersListNextButton_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentPage == nil) then
        Chronicles.UI.MyCharacters:DisplayCharacterList(1)
    else
        Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage + 1)
    end
end
