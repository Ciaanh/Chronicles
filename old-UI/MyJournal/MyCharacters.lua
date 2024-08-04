local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyCharacters = {}
Chronicles.UI.MyCharacters.CurrentPage = 1
Chronicles.UI.MyCharacters.SelectedCharacterId = nil
Chronicles.UI.MyCharacters.SelectedCharacterFactions = {}

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

    Chronicles.UI.MyCharacters:InitFactionSearch()

    Chronicles.UI.MyCharacters:InitLocales()
    Chronicles.UI.MyCharacters:HideFields()
end

function Chronicles.UI.MyCharacters:InitLocales()
    MyCharacters.Name:SetText(Locale[":My Characters"])

    MyCharactersDetailsSaveButton:SetText(Locale["Save"])
    MyCharactersListAddCharacter:SetText(Locale["Add"])
    MyCharactersDetailsRemoveCharacter:SetText(Locale["Delete"])

    MyCharactersDetailsIdLabel:SetText(Locale["Id_Field"] .. " :")
    MyCharactersDetailsNameLabel:SetText(Locale["Name_Field"] .. " :")
    MyCharactersDetailsBiographyLabel:SetText(Locale["Biography_Field"] .. " :")
    MyCharactersDetailsTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")

    MyCharacterFactions_Label:SetText(Locale["Factions_List"] .. " :")
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
    MyCharacterFactions_Label:Hide()
    MyCharacterFactions_ScrollBar:Hide()

    MyCharactersDetails.searchBox:Hide()
    MyCharactersDetails.searchBox:SetText("")

    Chronicles.UI.MyCharacters.SelectedCharacterId = nil
    Chronicles.UI.MyCharacters.SelectedCharacterFactions = nil

    Chronicles.UI.MyCharacters:HideAllFactions()
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
    MyCharacterFactions_Label:Show()
    MyCharacterFactions_ScrollBar:Show()

    MyCharactersDetails.searchBox:Show()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function DisplayMyCharactersList(page)
    Chronicles.UI.MyCharacters:DisplayCharacterList(page)
end

function Chronicles.UI.MyCharacters:DisplayCharacterList(page, force)
    if (page ~= nil) then
        local pageSize = private.constants.config.myJournal.characterListPageSize
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
    Chronicles.UI.CharactersView:Refresh()
end

function MyCharactersDetailsRemoveCharacter_OnClick()
    Chronicles.DB:RemoveMyJournalCharacter(Chronicles.UI.MyCharacters.SelectedCharacterId)
    Chronicles.UI.MyCharacters:HideFields()
    Chronicles.UI.MyCharacters.SelectedCharacterId = nil
    Chronicles.UI.MyCharacters.SelectedCharacterFactions = nil
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

        Chronicles.UI.MyCharacters.SelectedCharacterId = character.id

        -- id=[integer],				-- Id of the character
        -- name=[string], 				-- name of the character
        -- biography=[string],			-- small biography
        -- timeline=[integer],    		-- id of the timeline
        -- factions=table[integer], 	-- concerned factions

        MyCharactersDetailsId:SetText(character.id)
        MyCharactersDetailsName:SetText(character.name)
        MyCharactersDetailsBiography:SetText(character.biography)
        MyCharactersDetails.searchBox:SetText("")

        UIDropDownMenu_SetSelectedID(MyCharactersDetailsTimelineDropDown, character.timeline)
        UIDropDownMenu_SetText(MyCharactersDetailsTimelineDropDown, private.constants.timelines[character.timeline])

        Chronicles.UI.MyCharacters.SelectedCharacterFactions = copyTable(character.factions)
        Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    end
end

function MyCharactersDetailsSave_Click()
    -- print(
    --     "-- MyCharactersDetailsSave_Click " .. tablelength(Chronicles.UI.MyCharacters.SelectedCharacterFactions)
    -- )
    local character = {
        id = tonumber(MyCharactersDetailsId:GetText()),
        name = MyCharactersDetailsName:GetText(),
        biography = MyCharactersDetailsBiography:GetText(),
        timeline = MyCharactersDetailsTimelineDropDown.selectedID,
        factions = copyTable(Chronicles.UI.MyCharacters.SelectedCharacterFactions)
    }

    Chronicles.DB:SetMyJournalCharacters(character)
    Chronicles.UI.MyCharacters:DisplayCharacterList(Chronicles.UI.MyCharacters.CurrentPage, true)
    Chronicles.UI.CharactersView:Refresh()
end

------------------------------------------------------------------------------------------
-- Dropdowns -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Init_MyCharacters_Timeline_Dropdown()
    for key, value in ipairs(private.constants.timelines) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = value
        info.value = key

        info.arg1 = MyCharactersDetailsTimelineDropDown
        info.arg2 = private.constants.timelines
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

------------------------------------------------------------------------------------------
-- Factions ------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function MyCharacterFactions_Previous_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentFactionsPage == nil) then
        Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyCharacters:ChangeFactionsPage(Chronicles.UI.MyCharacters.CurrentFactionsPage - 1)
    end
end

function MyCharacterFactions_Next_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentFactionsPage == nil) then
        Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyCharacters:ChangeFactionsPage(Chronicles.UI.MyCharacters.CurrentFactionsPage + 1)
    end
end

function MyCharacterFactions_ScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyCharacterFactions_Previous_OnClick(self)
    else
        MyCharacterFactions_Next_OnClick(self)
    end
end

function MyCharacterChangeFactionsPage(page)
    Chronicles.UI.MyCharacters:ChangeFactionsPage(page)
end

function Chronicles.UI.MyCharacters:ChangeFactionsPage(page)
    -- print("-- ChangeFactionsPage " .. page)

    if
        (Chronicles.UI.MyCharacters.SelectedCharacterId ~= nil and
            Chronicles.UI.MyCharacters.SelectedCharacterFactions ~= nil and
            tablelength(Chronicles.UI.MyCharacters.SelectedCharacterFactions) > 0)
     then
        -- print(
        --     "-- ChangeFactionsPage " .. tablelength(Chronicles.UI.MyCharacters.SelectedCharacterFactions)
        -- )

        local factionsList = Chronicles.DB:FindFactions(Chronicles.UI.MyCharacters.SelectedCharacterFactions)
        local numberOfFactions = tablelength(factionsList)

        if (page ~= nil and numberOfFactions > 0) then
            local pageSize = private.constants.config.myJournal.characterFactionsPageSize

            -- print("-- numberOfFactions " .. numberOfFactions)

            Chronicles.UI.MyCharacters:HideAllFactions()

            if (numberOfFactions > 0) then
                local maxPageValue = math.ceil(numberOfFactions / pageSize)
                MyCharacterFactions_ScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                if (numberOfFactions > pageSize) then
                    MyCharacterFactions_ScrollBar.ScrollUpButton:Enable()
                    MyCharacterFactions_ScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyCharacterFactions_ScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyCharacters.CurrentFactionsPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    MyCharacterFactions_ScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyCharacters.CurrentFactionsPage = page
                MyCharacterFactions_ScrollBar:SetValue(Chronicles.UI.MyCharacters.CurrentFactionsPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex],
                        MyCharacterFactions_Block1
                    )
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 1],
                        MyCharacterFactions_Block2
                    )
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 2],
                        MyCharacterFactions_Block3
                    )
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 3],
                        MyCharacterFactions_Block4
                    )
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 4],
                        MyCharacterFactions_Block5
                    )
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 5],
                        MyCharacterFactions_Block6
                    )
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 6],
                        MyCharacterFactions_Block7
                    )
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 7],
                        MyCharacterFactions_Block8
                    )
                end
            end
        else
            Chronicles.UI.MyCharacters:HideAllFactions()
        end
    else
        Chronicles.UI.MyCharacters:HideAllFactions()
    end
end

function Chronicles.UI.MyCharacters:SetFactionTextToFrame(faction, frame)
    if (frame.faction ~= nil) then
        frame.faction = nil
    end
    frame:Hide()
    if (faction ~= nil) then
        -- print("-- SetFactionTextToFrame " .. faction.name)
        frame.Text:SetText(adjustTextLength(faction.name, 13, frame))
        frame.faction = faction
        -- frame:SetScript(
        --     "OnMouseDown",
        --     function()
        --         Chronicles.UI.MyCharacters:SetCharacterDetails(character)
        --     end
        -- )
        frame.remove:Show()
        frame.remove:SetScript(
            "OnClick",
            function()
                Chronicles.UI.MyCharacters:RemoveFaction(faction)
            end
        )

        frame:Show()
    else
        frame.remove:SetScript("OnClick", nil)
        frame.remove:Hide()
    end
end

function Chronicles.UI.MyCharacters:RemoveFaction(faction)
    -- print("-- RemoveFaction " .. faction.name)
    local indexToRemove = nil
    for index, id in ipairs(Chronicles.UI.MyCharacters.SelectedCharacterFactions[faction.source]) do
        if (faction.id == id) then
            indexToRemove = index
            break
        end
    end

    if indexToRemove ~= nil then
        -- print("-- RemoveFaction index " .. indexToRemove)
        table.remove(Chronicles.UI.MyCharacters.SelectedCharacterFactions[faction.source], indexToRemove)
    end

    -- print("-- RemoveFaction MyCharacters " .. tablelength(Chronicles.UI.MyCharacters.SelectedCharacterFactions))
    -- print("-- RemoveFaction CharactersView " .. tablelength(Chronicles.UI.CharactersView.SelectedCharacterFactions))

    Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    Chronicles.UI.CharactersView:Refresh()
end

function Chronicles.UI.MyCharacters:HideAllFactions()
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block1)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block2)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block3)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block4)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block5)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block6)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block7)
    Chronicles.UI.MyCharacters:HideFaction(MyCharacterFactions_Block8)

    MyCharacterFactions_ScrollBar.ScrollUpButton:Disable()
    MyCharacterFactions_ScrollBar.ScrollDownButton:Disable()

    Chronicles.UI.MyCharacters.CurrentFactionsPage = nil
end

function Chronicles.UI.MyCharacters:HideFaction(frame)
    frame:Hide()
    frame.faction = nil
    frame.remove:SetScript("OnClick", nil)
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
-- Factions Autocomplete -----------------------------------------------------------------
------------------------------------------------------------------------------------------

local NUM_SEARCH_PREVIEWS = 5
local SHOW_ALL_RESULTS_INDEX = NUM_SEARCH_PREVIEWS + 1

function Chronicles.UI.MyCharacters:InitFactionSearch()
    local scrollFrame = MyCharactersDetails.searchResults.scrollFrame
    scrollFrame.update = MyCharacterFactions_UpdateFullSearchResults
    scrollFrame.scrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "MyCharacterFactions_FullSearchResultsButton", 5, 0)

    SearchBoxTemplate_OnLoad(MyCharactersDetails.searchBox)
    MyCharactersDetails.searchBox.HasStickyFocus = function()
        return DoesAncestryInclude(MyCharactersDetails.searchPreviewContainer, GetMouseFocus())
    end
end

function MyCharacterFactions_SearchBox_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 7)
    MyCharacterFactions_SetSearchPreviewSelection(1)
end

function MyCharacterFactions_SearchBox_Refresh(self)
    SearchBoxTemplate_OnTextChanged(self)

    if (strlen(self:GetText()) >= MIN_CHARACTER_SEARCH) then
        MyCharacterFactions_ShowSearchPreviewResults()
    else
        MyCharacterFactions_HideSearchPreview()
    end
end

function MyCharacterFactions_SearchBox_OnFocusLost(self)
    SearchBoxTemplate_OnEditFocusLost(self)
    MyCharacterFactions_HideSearchPreview()
    -- print("-- MyCharacterFactions_SearchBox_OnFocusLost ")
end

function MyCharacterFactions_SearchBox_OnFocusGained(self)
    SearchBoxTemplate_OnEditFocusGained(self)
    MyCharactersDetails.searchResults:Hide()

    MyCharacterFactions_SearchBox_Refresh(self)
end

function MyCharacterFactions_SearchBox_OnKeyDown(self, key)
    if (key == "UP") then
        MyCharacterFactions_SetSearchPreviewSelection(MyCharactersDetails.searchBox.selectedIndex - 1)
    elseif (key == "DOWN") then
        MyCharacterFactions_SetSearchPreviewSelection(MyCharactersDetails.searchBox.selectedIndex + 1)
    end
end

function MyCharacterFactions_HideSearchPreview()
    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    searchPreviewContainer:Hide()

    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    searchPreviewContainer.showAllSearchResults:Hide()
end

function MyCharacterFactions_SetSearchPreviewSelection(selectedIndex)
    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    local numShown = 0
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        searchPreview.selectedTexture:Hide()

        if (searchPreview:IsShown()) then
            numShown = numShown + 1
        end
    end

    if (searchPreviewContainer.showAllSearchResults:IsShown()) then
        numShown = numShown + 1
    end

    searchPreviewContainer.showAllSearchResults.selectedTexture:Hide()

    if (numShown <= 0) then
        -- Default to the first entry.
        selectedIndex = 1
    else
        selectedIndex = (selectedIndex - 1) % numShown + 1
    end

    MyCharactersDetails.searchBox.selectedIndex = selectedIndex

    if (selectedIndex == SHOW_ALL_RESULTS_INDEX) then
        searchPreviewContainer.showAllSearchResults.selectedTexture:Show()
    else
        searchPreviewContainer.searchPreviews[selectedIndex].selectedTexture:Show()
    end
end

function MyCharacterFactions_ShowSearchPreviewResults()
    local searchtext = MyCharactersDetails.searchBox:GetText()
    local searchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(searchResults)

    if (numResults > 0) then
        MyCharacterFactions_SetSearchPreviewSelection(1)
    end

    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    local lastButton
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        if (index <= numResults) then
            local faction = searchResults[index]

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
        searchPreviewContainer.showAllSearchResults:Show()
        lastButton = searchPreviewContainer.showAllSearchResults
        searchPreviewContainer.showAllSearchResults.text:SetText(
            string.format(ENCOUNTER_JOURNAL_SHOW_SEARCH_RESULTS, numResults)
        )
    else
        searchPreviewContainer.showAllSearchResults:Hide()
    end

    if (lastButton) then
        searchPreviewContainer.borderAnchor:SetPoint("BOTTOM", lastButton, "BOTTOM", 0, -5)
        searchPreviewContainer.background:Hide()
        searchPreviewContainer:Show()
    else
        searchPreviewContainer:Hide()
    end
end

function MyCharacterFactions_ShowAllSearchResults_OnEnter()
    MyCharacterFactions_SetSearchPreviewSelection(SHOW_ALL_RESULTS_INDEX)
end

function MyCharacterFactions_FullSearchResultsButton_OnClick(self)
    if (self.factionID) then
        MyCharacterFactions_SelectSearchItem(self.factionID)
        MyCharactersDetails.searchResults:Hide()
    end
end

function MyCharacterFactions_SelectSearchItem(factionID)
    -- print("-- MyCharacterFactions_SelectSearchItem " .. factionID.id .. " " .. factionID.group)

    local results =
        Chronicles.DB:FindFactions(
        {
            [factionID.group] = {factionID.id}
        }
    )

    if (results ~= nil and tablelength(results) > 0) then
        if (Chronicles.UI.MyCharacters.SelectedCharacterFactions[factionID.group] ~= nil) then
            for index, id in ipairs(Chronicles.UI.MyCharacters.SelectedCharacterFactions[factionID.group]) do
                if (factionID.id == id) then
                    Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
                    return
                end
            end
            table.insert(Chronicles.UI.MyCharacters.SelectedCharacterFactions[factionID.group], factionID.id)
        else
            Chronicles.UI.MyCharacters.SelectedCharacterFactions[factionID.group] = {factionID.id}
        end
    end
    Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    Chronicles.UI.CharactersView:Refresh()
end

function MyCharacterFactions_SearchBox_OnUpdate(self)
    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        searchPreviews[index]:Hide()
    end

    searchPreviewContainer.showAllSearchResults:Hide()

    searchPreviewContainer.borderAnchor:SetPoint("BOTTOM", 0, -5)
    searchPreviewContainer.background:Show()
    searchPreviewContainer:Show()

    -- print("-- MyCharacterFactions_SearchBox_OnUpdate ")
end

function MyCharacterFactions_SearchPreviewButton_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10)
end

function MyCharacterFactions_SearchPreviewButton_OnLoad(self)
    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    for index = 1, NUM_SEARCH_PREVIEWS do
        if (searchPreviews[index] == self) then
            self.previewIndex = index
            break
        end
    end
end

function MyCharacterFactions_SearchPreviewButton_OnEnter(self)
    MyCharacterFactions_SetSearchPreviewSelection(self.previewIndex)
end

function MyCharacterFactions_SearchPreviewButton_OnClick(self)
    -- print("-- MyCharacterFactions_SearchPreviewButton_OnClick ")

    if (self.factionID) then
        MyCharacterFactions_SelectSearchItem(self.factionID)
        MyCharactersDetails.searchResults:Hide()
        MyCharacterFactions_HideSearchPreview()
        MyCharactersDetails.searchBox:ClearFocus()
    end
end

function MyCharacterFactions_ShowFullSearch()
    -- print("-- MyCharacterFactions_ShowFullSearch ")

    MyCharacterFactions_UpdateFullSearchResults()

    local searchtext = MyCharactersDetails.searchBox:GetText()
    local searchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(searchResults)
    if (numResults == 0) then
        MyCharactersDetails.searchResults:Hide()
        return
    end

    MyCharacterFactions_HideSearchPreview()
    MyCharactersDetails.searchBox:ClearFocus()
    MyCharactersDetails.searchResults:Show()
end

function MyCharacterFactions_UpdateFullSearchResults()
    local searchtext = MyCharactersDetails.searchBox:GetText()
    local searchResults = Chronicles.DB:SearchFactions(searchtext)

    local numResults = tablelength(searchResults)

    local scrollFrame = MyCharactersDetails.searchResults.scrollFrame
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local results = scrollFrame.buttons
    local result, index

    for i = 1, #results do
        result = results[i]
        index = offset + i
        if (index <= numResults) then
            local faction = searchResults[index]

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

    MyCharactersDetails.searchResults.titleText:SetText(
        string.format(ENCOUNTER_JOURNAL_SEARCH_RESULTS, searchtext, numResults)
    )
end
