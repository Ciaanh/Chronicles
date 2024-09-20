local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.CharactersView = {}
Chronicles.UI.CharactersView.CurrentPage = 1
Chronicles.UI.CharactersView.CurrentFactionsPage = 1
Chronicles.UI.CharactersView.SelectedCharacterFactions = {}

function Chronicles.UI.CharactersView:Init()
    CharactersView.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    CharacterFactionsScrollFrame:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    Chronicles.UI.CharactersView:DisplayCharacterList(1, true)

    Chronicles.UI.CharactersView:CleanSelectedCharacter()

    CharactersView.Title:SetText(Locale["Characters"])
    CharacterTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")
    CharacterFactionsLabel:SetText(Locale["Factions_List"] .. " :")
end

function Chronicles.UI.CharactersView:Refresh()
    -- print("-- Chronicles.UI.CharactersView:Refresh ")

    Chronicles.UI.CharactersView.CurrentPage = 1
    Chronicles.UI.CharactersView:DisplayCharacterList(1, true)

    Chronicles.UI.CharactersView:CleanSelectedCharacter()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.CharactersView:HideAll()
    CharactersListBlock1:Hide()
    CharactersListBlock2:Hide()
    CharactersListBlock3:Hide()
    CharactersListBlock4:Hide()
    CharactersListBlock5:Hide()
    CharactersListBlock6:Hide()
    CharactersListBlock7:Hide()
    CharactersListBlock8:Hide()
    CharactersListBlock9:Hide()

    CharactersListScrollBar.ScrollUpButton:Disable()
    CharactersListScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.CharactersView:WipeAll()
    if (CharactersListBlock1.character ~= nil) then
        CharactersListBlock1.character = nil
    end

    if (CharactersListBlock2.character ~= nil) then
        CharactersListBlock2.character = nil
    end

    if (CharactersListBlock3.character ~= nil) then
        CharactersListBlock3.character = nil
    end

    if (CharactersListBlock4.character ~= nil) then
        CharactersListBlock4.character = nil
    end

    if (CharactersListBlock5.character ~= nil) then
        CharactersListBlock5.character = nil
    end

    if (CharactersListBlock6.character ~= nil) then
        CharactersListBlock6.character = nil
    end

    if (CharactersListBlock7.character ~= nil) then
        CharactersListBlock7.character = nil
    end

    if (CharactersListBlock8.character ~= nil) then
        CharactersListBlock8.character = nil
    end

    if (CharactersListBlock9.character ~= nil) then
        CharactersListBlock9.character = nil
    end

    Chronicles.UI.CharactersView.CurrentPage = nil
end

function DisplayCharactersList(page)
    Chronicles.UI.CharactersView:DisplayCharacterList(page)
end

function Chronicles.UI.CharactersView:DisplayCharacterList(page, force)
    if (page ~= nil) then
        local pageSize = private.constants.config.myJournal.characterListPageSize
        local characterList = Chronicles.Data:SearchCharacters()

        local numberOfCharacters = tablelength(characterList)

        if (numberOfCharacters > 0) then
            local maxPageValue = math.ceil(numberOfCharacters / pageSize)
            CharactersListScrollBar:SetMinMaxValues(1, maxPageValue)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (Chronicles.UI.CharactersView.CurrentPage ~= page or force) then
                Chronicles.UI.CharactersView:HideAll()
                Chronicles.UI.CharactersView:WipeAll()

                if (numberOfCharacters > pageSize) then
                    CharactersListScrollBar.ScrollUpButton:Enable()
                    CharactersListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    CharactersListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.CharactersView.CurrentPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfCharacters) then
                    lastIndex = numberOfCharacters
                    CharactersListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.CharactersView.CurrentPage = page
                CharactersListScrollBar:SetValue(Chronicles.UI.CharactersView.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex], CharactersListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 1], CharactersListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 2], CharactersListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 3], CharactersListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 4], CharactersListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 5], CharactersListBlock6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 6], CharactersListBlock7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 7], CharactersListBlock8)
                end

                if (((firstIndex + 8) > 0) and ((firstIndex + 8) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetTextToFrame(characterList[firstIndex + 8], CharactersListBlock9)
                end
            end
        else
            Chronicles.UI.CharactersView:HideAll()
        end
    end
end

function Chronicles.UI.CharactersView:SetTextToFrame(character, frame)
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
                Chronicles.UI.CharactersView:SetCharacterDetails(character)
            end
        )
        frame:Show()
    end
end

------------------------------------------------------------------------------------------
-- Scroll List ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function CharactersListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        CharactersListPreviousButton_OnClick(self)
    else
        CharactersListNextButton_OnClick(self)
    end
end

function CharactersListPreviousButton_OnClick(self)
    if (Chronicles.UI.CharactersView.CurrentPage == nil) then
        Chronicles.UI.CharactersView:DisplayCharacterList(1)
    else
        Chronicles.UI.CharactersView:DisplayCharacterList(Chronicles.UI.CharactersView.CurrentPage - 1)
    end
end

function CharactersListNextButton_OnClick(self)
    if (Chronicles.UI.CharactersView.CurrentPage == nil) then
        Chronicles.UI.CharactersView:DisplayCharacterList(1)
    else
        Chronicles.UI.CharactersView:DisplayCharacterList(Chronicles.UI.CharactersView.CurrentPage + 1)
    end
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.CharactersView:CleanSelectedCharacter()
    -- print("-- CleanSelectedCharacter ")

    CharacterTimelineLabel:Hide()
    CharacterTitle:SetText("")
    CharacterBiographyHTML:SetText("")
    CharacterTimeline:SetText("")

    Chronicles.UI.CharactersView.SelectedCharacterFactions = {}

    Chronicles.UI.CharactersView:HideAllFactions()
end

function Chronicles.UI.CharactersView:SetCharacterDetails(character)
    if (character == nil) then
        Chronicles.UI.CharactersView:CleanSelectedCharacter()
        return
    end

    -- id=[integer],				-- Id of the character
    -- name=[string], 				-- name of the character
    -- biography=[string],			-- small biography
    -- timeline=[integer],    		-- id of the timeline
    -- factions=table[integer], 	-- concerned factions

    CharacterTimelineLabel:Show()
    CharacterTitle:SetText(character.name)
    CharacterBiographyHTML:SetText(cleanHTML(character.biography))
    CharacterTimeline:SetText(private.constants.timelines[character.timeline])

    -- print("-- SetCharacterDetails " .. tablelength(character.factions))

    Chronicles.UI.CharactersView.SelectedCharacterFactions = copyTable(character.factions)
    Chronicles.UI.CharactersView:ChangeFactionsPage(1)
end

function CharacterFactionsPrevious_OnClick(self)
    if (Chronicles.UI.CharactersView.CurrentFactionsPage == nil) then
        Chronicles.UI.CharactersView:ChangeFactionsPage(1)
    else
        Chronicles.UI.CharactersView:ChangeFactionsPage(Chronicles.UI.CharactersView.CurrentFactionsPage - 1)
    end
end

function CharacterFactionsNext_OnClick(self)
    if (Chronicles.UI.CharactersView.CurrentFactionsPage == nil) then
        Chronicles.UI.CharactersView:ChangeFactionsPage(1)
    else
        Chronicles.UI.CharactersView:ChangeFactionsPage(Chronicles.UI.CharactersView.CurrentFactionsPage + 1)
    end
end

function CharacterFactionsScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        CharacterFactionsPrevious_OnClick(self)
    else
        CharacterFactionsNext_OnClick(self)
    end
end

function ChangeFactionsPage(page)
    Chronicles.UI.CharactersView:ChangeFactionsPage(page)
end

function Chronicles.UI.CharactersView:ChangeFactionsPage(page)
    -- print(
    --     "-- ChangeFactionsPage " .. tablelength(Chronicles.UI.CharactersView.SelectedCharacterFactions)
    -- )

    if
        (Chronicles.UI.CharactersView.SelectedCharacterFactions ~= nil and
            tablelength(Chronicles.UI.CharactersView.SelectedCharacterFactions) > 0)
     then
        local factionsList = Chronicles.Data:FindFactions(Chronicles.UI.CharactersView.SelectedCharacterFactions)
        local numberOfFactions = tablelength(factionsList)

        if (page ~= nil and numberOfFactions > 0) then
            local pageSize = private.constants.config.myJournal.characterFactionsPageSize

            -- print("-- numberOfFactions " .. numberOfFactions)

            if (numberOfFactions > 0) then
                local maxPageValue = math.ceil(numberOfFactions / pageSize)
                CharacterFactionsScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                Chronicles.UI.CharactersView:HideAllFactions()

                if (numberOfFactions > pageSize) then
                    CharacterFactionsScrollBar.ScrollUpButton:Enable()
                    CharacterFactionsScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    CharacterFactionsScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.CharactersView.CurrentFactionsPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    CharacterFactionsScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.CharactersView.CurrentFactionsPage = page
                CharacterFactionsScrollBar:SetValue(Chronicles.UI.CharactersView.CurrentFactionsPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex],
                        CharacterFactionsBlock1
                    )
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 1],
                        CharacterFactionsBlock2
                    )
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 2],
                        CharacterFactionsBlock3
                    )
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 3],
                        CharacterFactionsBlock4
                    )
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 4],
                        CharacterFactionsBlock5
                    )
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 5],
                        CharacterFactionsBlock6
                    )
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 6],
                        CharacterFactionsBlock7
                    )
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.CharactersView:SetFactionTextToFrame(
                        factionsList[firstIndex + 7],
                        CharacterFactionsBlock8
                    )
                end
            end
        else
            Chronicles.UI.CharactersView:HideAllFactions()
        end
    else
        Chronicles.UI.CharactersView:HideAllFactions()
    end
end

function Chronicles.UI.CharactersView:SetFactionTextToFrame(faction, frame)
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
        --         Chronicles.UI.CharactersView:SetCharacterDetails(character)
        --     end
        -- )
        frame:Show()
    end
end

function Chronicles.UI.CharactersView:HideAllFactions()
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock1)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock2)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock3)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock4)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock5)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock6)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock7)
    Chronicles.UI.CharactersView:HideFaction(CharacterFactionsBlock8)

    CharacterFactionsScrollBar.ScrollUpButton:Disable()
    CharacterFactionsScrollBar.ScrollDownButton:Disable()
    Chronicles.UI.CharactersView.CurrentFactionsPage = nil
end

function Chronicles.UI.CharactersView:HideFaction(frame)
    frame.faction = nil
    frame:Hide()
end
