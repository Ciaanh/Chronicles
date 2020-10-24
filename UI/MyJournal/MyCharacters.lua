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
    
    Chronicles.UI.MyCharacters:InitLocales()

    InitFactionSearch()

    Chronicles.UI.MyCharacters:HideFields()
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

    MyCharacterFactionsLabel:SetText(Locale["Factions_List"] .. " :")
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
    MyCharacterFactionsLabel:Hide()
    MyCharacterFactionsScrollBar:Hide()

    MyCharactersDetails.searchBox:Hide()
    MyCharactersDetails.searchProgressBar:Hide()

    Chronicles.UI.MyCharacters.SelectedCharacter = {}

    Chronicles.UI.MyCharacters:HideAllFactions()
    Chronicles.UI.MyCharacters:WipeAllFactions()
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
    MyCharacterFactionsLabel:Show()
    MyCharacterFactionsScrollBar:Show()

    MyCharactersDetails.searchBox:Show()
    MyCharactersDetails.searchProgressBar:Show()
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

-- function Chronicles.UI.MyCharacters:CleanSelectedCharacter()
--     MyCharactersDetailsId:SetText("")
--     MyCharactersDetailsName:SetText("")
--     MyCharactersDetailsBiography:SetText("")

--     Chronicles.UI.MyCharacters.SelectedCharacter = {}

--     Chronicles.UI.MyCharacters:HideAllFactions()
--     Chronicles.UI.MyCharacters:WipeAllFactions()
-- end

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

    Chronicles.UI.MyCharacters.SelectedCharacter.Factions = character.factions
    Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
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

------------------------------------------------------------------------------------------
-- Factions ------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function MyCharacterFactionsPrevious_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentFactionsPage == nil) then
        Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyCharacters:ChangeFactionsPage(Chronicles.UI.MyCharacters.CurrentFactionsPage - 1)
    end
end

function MyCharacterFactionsNext_OnClick(self)
    if (Chronicles.UI.MyCharacters.CurrentFactionsPage == nil) then
        Chronicles.UI.MyCharacters:ChangeFactionsPage(1)
    else
        Chronicles.UI.MyCharacters:ChangeFactionsPage(Chronicles.UI.MyCharacters.CurrentFactionsPage + 1)
    end
end

function MyCharacterFactionsScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        MyCharacterFactionsPrevious_OnClick(self)
    else
        MyCharacterFactionsNext_OnClick(self)
    end
end

function MyCharacterChangeFactionsPage(page)
    Chronicles.UI.MyCharacters:ChangeFactionsPage(page)
end

function Chronicles.UI.MyCharacters:ChangeFactionsPage(page)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- ChangeFactionsPage " .. page)

    -- MyCharacterFactionsPrevious:Hide()
    -- MyCharacterFactionsNext:Hide()

    if
        (Chronicles.UI.MyCharacters.SelectedCharacter ~= nil and
            Chronicles.UI.MyCharacters.SelectedCharacter.Factions ~= nil and
            tablelength(Chronicles.UI.MyCharacters.SelectedCharacter.Factions) > 0)
     then
        if (page ~= nil) then
            local pageSize = Chronicles.constants.config.myJournal.characterFactionsPageSize
            local factionsList = Chronicles.DB:FindFactions(Chronicles.UI.MyCharacters.SelectedCharacter.Factions)

            local numberOfFactions = tablelength(factionsList)
            -- DEFAULT_CHAT_FRAME:AddMessage("-- numberOfFactions " .. numberOfFactions)

            if (numberOfFactions > 0) then
                local maxPageValue = math.ceil(numberOfFactions / pageSize)
                MyCharacterFactionsScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                Chronicles.UI.MyCharacters:HideAllFactions()
                Chronicles.UI.MyCharacters:WipeAllFactions()

                if (numberOfFactions > pageSize) then
                    MyCharacterFactionsScrollBar.ScrollUpButton:Enable()
                    MyCharacterFactionsScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    MyCharacterFactionsScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.MyCharacters.CurrentFactionsPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    MyCharacterFactionsScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.MyCharacters.CurrentFactionsPage = page
                MyCharacterFactionsScrollBar:SetValue(Chronicles.UI.MyCharacters.CurrentFactionsPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex],
                        MyCharacterFactionsBlock1
                    )
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 1],
                        MyCharacterFactionsBlock2
                    )
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 2],
                        MyCharacterFactionsBlock3
                    )
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 3],
                        MyCharacterFactionsBlock4
                    )
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 4],
                        MyCharacterFactionsBlock5
                    )
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 5],
                        MyCharacterFactionsBlock6
                    )
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 6],
                        MyCharacterFactionsBlock7
                    )
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.MyCharacters:SetFactionTextToFrame(
                        factionsList[firstIndex + 7],
                        MyCharacterFactionsBlock8
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
        --DEFAULT_CHAT_FRAME:AddMessage("-- SetFactionTextToFrame " .. faction.name)
        frame.Text:SetText(adjustTextLength(faction.name, 13, frame))
        frame.faction = faction
        -- frame:SetScript(
        --     "OnMouseDown",
        --     function()
        --         Chronicles.UI.MyCharacters:SetCharacterDetails(character)
        --     end
        -- )
        frame:Show()
    end
end

function Chronicles.UI.MyCharacters:HideAllFactions()
    MyCharacterFactionsBlock1:Hide()
    MyCharacterFactionsBlock2:Hide()
    MyCharacterFactionsBlock3:Hide()
    MyCharacterFactionsBlock4:Hide()
    MyCharacterFactionsBlock5:Hide()
    MyCharacterFactionsBlock6:Hide()
    MyCharacterFactionsBlock7:Hide()
    MyCharacterFactionsBlock8:Hide()

    MyCharacterFactionsScrollBar.ScrollUpButton:Disable()
    MyCharacterFactionsScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.MyCharacters:WipeAllFactions()
    if (CharactersListBlock1.faction ~= nil) then
        CharactersListBlock1.faction = nil
    end

    if (MyCharacterFactionsBlock2.faction ~= nil) then
        MyCharacterFactionsBlock2.faction = nil
    end

    if (MyCharacterFactionsBlock3.faction ~= nil) then
        MyCharacterFactionsBlock3.faction = nil
    end

    if (MyCharacterFactionsBlock4.faction ~= nil) then
        MyCharacterFactionsBlock4.faction = nil
    end

    if (MyCharacterFactionsBlock5.faction ~= nil) then
        MyCharacterFactionsBlock5.faction = nil
    end

    if (MyCharacterFactionsBlock6.faction ~= nil) then
        MyCharacterFactionsBlock6.faction = nil
    end

    if (MyCharacterFactionsBlock7.faction ~= nil) then
        MyCharacterFactionsBlock7.faction = nil
    end

    if (MyCharacterFactionsBlock8.faction ~= nil) then
        MyCharacterFactionsBlock8.faction = nil
    end

    Chronicles.UI.MyCharacters.CurrentFactionsPage = nil
end






































------------------------------------------------------------------------------------------
-- Factions Autocomplete -----------------------------------------------------------------
------------------------------------------------------------------------------------------

local NUM_SEARCH_PREVIEWS = 5;
local SHOW_ALL_RESULTS_INDEX = NUM_SEARCH_PREVIEWS + 1;

function InitFactionSearch()
    MyCharactersDetails.searchResults.scrollFrame.update = MyCharacterFactions_UpdateFullSearchResults;
	MyCharactersDetails.searchResults.scrollFrame.scrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(MyCharactersDetails.searchResults.scrollFrame, "MyCharacterFactionsFullSearchResultsButton", 0, 0);
end

function MyCharacterFactionsSearchBox_OnLoad(self)
    SearchBoxTemplate_OnLoad(self)
    
    -- useful to display all results
    self.HasStickyFocus = function()
        local ancestry = self:GetParent().searchPreviewContainer
        return DoesAncestryInclude(ancestry, GetMouseFocus())
    end
end

function MyCharacterFactionsSearchBox_OnShow(self)
    self:SetFrameLevel(self:GetParent():GetFrameLevel() + 7)
    MyCharacterFactions_SetSearchPreviewSelection(1)
    self.fullSearchFinished = false
    self.searchPreviewUpdateDelay = 0
end

function MyCharacterFactionsSearchBox_OnEnterPressed(self)
    -- If the search is not finished yet we have to wait to show the full search results.
    if (not self.fullSearchFinished or strlen(self:GetText()) < MIN_CHARACTER_SEARCH) then
        return
    end

    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    if (self.selectedIndex == SHOW_ALL_RESULTS_INDEX) then
        if (searchPreviewContainer.showAllSearchResults:IsShown()) then
            searchPreviewContainer.showAllSearchResults:Click()
        end
    else
        local preview = searchPreviewContainer.searchPreviews[self.selectedIndex]
        if (preview:IsShown()) then
            preview:Click()
        end
    end
end

function MyCharacterFactionsSearchBox_OnTextChanged(self)
    SearchBoxTemplate_OnTextChanged(self)

    if (strlen(self:GetText()) >= MIN_CHARACTER_SEARCH) then
        MyCharactersDetails.searchBox.fullSearchFinished = SetAchievementSearchString(self:GetText())
        if (not MyCharactersDetails.searchBox.fullSearchFinished) then
            MyCharacterFactions_UpdateSearchPreview()
        else
            MyCharacterFactions_ShowSearchPreviewResults()
        end
    else
        MyCharacterFactions_HideSearchPreview()
    end
end

function MyCharacterFactionsSearchBox_OnFocusLost(self)
    SearchBoxTemplate_OnEditFocusLost(self)
    MyCharacterFactions_HideSearchPreview()
end

function MyCharacterFactionsSearchBox_OnFocusGained(self)
    SearchBoxTemplate_OnEditFocusGained(self)
    MyCharactersDetails.searchResults:Hide()
    MyCharacterFactions_UpdateSearchPreview()
end

function MyCharacterFactionsSearchBox_OnKeyDown(self, key)
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
    MyCharactersDetails.searchProgressBar:Hide()
end

function MyCharacterFactions_UpdateSearchPreview()
    if
        (not MyCharactersDetails.searchBox:HasFocus() or
            strlen(MyCharactersDetails.searchBox:GetText()) < MIN_CHARACTER_SEARCH)
     then
        MyCharacterFactions_HideSearchPreview()
        return
    end

    MyCharactersDetails.searchBox.searchPreviewUpdateDelay = 0

    if (MyCharactersDetails.searchBox:GetScript("OnUpdate") == nil) then
        MyCharactersDetails.searchBox:SetScript("OnUpdate", MyCharacterFactionsSearchBox_OnUpdate)
    end
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

    DEFAULT_CHAT_FRAME:AddMessage("-- selectedIndex " .. tostring(selectedIndex))

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
    MyCharactersDetails.searchProgressBar:Hide()

    local numResults = GetNumFilteredAchievements()

    if (numResults > 0) then
        MyCharacterFactions_SetSearchPreviewSelection(1)
    end

    local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
    local searchPreviews = searchPreviewContainer.searchPreviews
    local lastButton
    for index = 1, NUM_SEARCH_PREVIEWS do
        local searchPreview = searchPreviews[index]
        if (index <= numResults) then
            local achievementID = GetFilteredAchievementID(index)
            local _, name, _, _, _, _, _, description, _, icon, _, _, _, _ = GetAchievementInfo(achievementID)
            searchPreview.name:SetText(name)
            searchPreview.icon:SetTexture(icon)
            searchPreview.achievementID = achievementID
            searchPreview:Show()
            lastButton = searchPreview
        else
            searchPreview.achievementID = nil
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

function MyCharacterFactionsShowAllSearchResults_OnEnter()
    MyCharacterFactions_SetSearchPreviewSelection(SHOW_ALL_RESULTS_INDEX)
end

function MyCharacterFactionsFullSearchResultsButton_OnClick(self)
    if (self.achievementID) then
        MyCharacterFactions_SelectSearchItem(self.achievementID)
        MyCharactersDetails.searchResults:Hide()
    end
end

function MyCharacterFactions_SelectSearchItem(id)
    DEFAULT_CHAT_FRAME:AddMessage("-- MyCharacterFactions_SelectSearchItem " .. tostring(id))

    -- local isStatistic = select(15, GetAchievementInfo(id));
    -- if ( isStatistic ) then
    -- 	AchievementFrame_SelectStatisticByAchievementID(id, AchievementFrameComparison:IsShown());
    -- else
    -- 	AchievementFrame_SelectAchievement(id, true, AchievementFrameComparison:IsShown());
    -- end
end

-- There is a delay before the search is updated to avoid a search progress bar if the search
-- completes within the grace period.
local ACHIEVEMENT_SEARCH_PREVIEW_UPDATE_DELAY = 0.3
function MyCharacterFactionsSearchBox_OnUpdate(self, elapsed)
    if (self.fullSearchFinished) then
        MyCharacterFactions_ShowSearchPreviewResults()
        self.searchPreviewUpdateDelay = 0
        self:SetScript("OnUpdate", nil)
        return
    end

    self.searchPreviewUpdateDelay = self.searchPreviewUpdateDelay + elapsed

    if (self.searchPreviewUpdateDelay > ACHIEVEMENT_SEARCH_PREVIEW_UPDATE_DELAY) then
        self.searchPreviewUpdateDelay = 0
        self:SetScript("OnUpdate", nil)

        -- display search preview
        if (MyCharactersDetails.searchProgressBar:GetScript("OnUpdate") == nil) then
            MyCharactersDetails.searchProgressBar:SetScript("OnUpdate", MyCharacterFactionsSearchProgressBar_OnUpdate)

            local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer
            local searchPreviews = searchPreviewContainer.searchPreviews
            for index = 1, NUM_SEARCH_PREVIEWS do
                searchPreviews[index]:Hide()
            end

            searchPreviewContainer.showAllSearchResults:Hide()

            searchPreviewContainer.borderAnchor:SetPoint("BOTTOM", 0, -5)
            searchPreviewContainer.background:Show()
            searchPreviewContainer:Show()

            MyCharactersDetails.searchProgressBar:Show()
            return
        end
    end
end

-- If the searcher does not finish within the update delay then a search progress bar is displayed that
-- will fill until the search is finished and then display the search preview results.
function MyCharacterFactionsSearchProgressBar_OnUpdate(self, elapsed)
    local _, maxValue = self:GetMinMaxValues()
    local actualProgress = GetAchievementSearchProgress() / GetAchievementSearchSize() * maxValue
    local displayedProgress = self:GetValue()

    self:SetValue(actualProgress)

    if (self:GetValue() >= maxValue) then
        self:SetScript("OnUpdate", nil)
        self:SetValue(0)
        MyCharacterFactions_ShowSearchPreviewResults()
    end
end


function MyCharacterFactionsSearchPreviewButton_OnShow(self)
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 10);
end


function MyCharacterFactionsSearchPreviewButton_OnLoad(self)
	local searchPreviewContainer = MyCharactersDetails.searchPreviewContainer;
	local searchPreviews = searchPreviewContainer.searchPreviews;
	for index = 1, NUM_SEARCH_PREVIEWS do
		if ( searchPreviews[index] == self ) then
			self.previewIndex = index;
			break;
		end
	end
end

function MyCharacterFactionsSearchPreviewButton_OnEnter(self)
	MyCharacterFactions_SetSearchPreviewSelection(self.previewIndex);
end

function MyCharacterFactionsSearchPreviewButton_OnClick(self)
	if ( self.achievementID ) then
		MyCharacterFactions_SelectSearchItem(self.achievementID);
		MyCharactersDetails.searchResults:Hide();
		MyCharacterFactions_HideSearchPreview();
		MyCharactersDetails.searchBox:ClearFocus();
	end
end

function MyCharacterFactions_ShowFullSearch()
    -- MyCharacterFactions
    -- MyCharactersDetails
    -- AchievementFrame
	MyCharacterFactions_UpdateFullSearchResults();

	if ( GetNumFilteredAchievements() == 0 ) then
		MyCharactersDetails.searchResults:Hide();
		return;
	end

	MyCharacterFactions_HideSearchPreview();
	MyCharactersDetails.searchBox:ClearFocus();
	MyCharactersDetails.searchResults:Show();
end

function MyCharacterFactions_UpdateFullSearchResults()
	local numResults = GetNumFilteredAchievements();

	local scrollFrame = MyCharactersDetails.searchResults.scrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local results = scrollFrame.buttons;
    local result, index;
    


	for i = 1,#results do
		result = results[i];
		index = offset + i;
		if ( index <= numResults ) then
			local achievementID = GetFilteredAchievementID(index);
			local _, name, _, completed, _, _, _, description, _, icon, _, _, _, _ = GetAchievementInfo(achievementID);

			result.name:SetText(name);
			result.icon:SetTexture(icon);
			result.achievementID = achievementID;

			if ( completed ) then
				result.resultType:SetText(ACHIEVEMENTFRAME_FILTER_COMPLETED);
			else
				result.resultType:SetText(ACHIEVEMENTFRAME_FILTER_INCOMPLETE);
			end

			local categoryID = GetAchievementCategory(achievementID);
			local categoryName, parentCategoryID = GetCategoryInfo(categoryID);
			path = categoryName;
			while ( not (parentCategoryID == -1) ) do
				categoryName, parentCategoryID = GetCategoryInfo(parentCategoryID);
				path = categoryName.." > "..path;
			end

            DEFAULT_CHAT_FRAME:AddMessage("-- path " .. path)

			result.path:SetText(path);

			result:Show();
		else
			result:Hide();
		end
	end

	local totalHeight = numResults * 49;
	HybridScrollFrame_Update(scrollFrame, totalHeight, 270);

	MyCharactersDetails.searchResults.titleText:SetText(string.format(ENCOUNTER_JOURNAL_SEARCH_RESULTS, MyCharactersDetails.searchBox:GetText(), numResults));
end