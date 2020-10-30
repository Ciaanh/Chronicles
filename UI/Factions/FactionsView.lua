local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.FactionsView = {}
Chronicles.UI.FactionsView.CurrentPage = 1

function Chronicles.UI.FactionsView:Init()
    FactionsView.List:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    Chronicles.UI.FactionsView:DisplayFactionList(1, true)

    Chronicles.UI.FactionsView:CleanSelectedFaction()

    Chronicles.UI.FactionsView:InitLocales()
end

function Chronicles.UI.FactionsView:InitLocales()
    FactionsView.Title:SetText(Locale["Factions"])

    FactionTimelineLabel:SetText(Locale["Timeline_Field"] .. " :")
end

function Chronicles.UI.FactionsView:Refresh()
    Chronicles.UI.FactionsView.CurrentPage = 1
    Chronicles.UI.FactionsView:DisplayFactionList(1, true)

    Chronicles.UI.FactionsView:CleanSelectedFaction()
end

------------------------------------------------------------------------------------------
-- List ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.FactionsView:HideAll()
    FactionsListBlock1:Hide()
    FactionsListBlock2:Hide()
    FactionsListBlock3:Hide()
    FactionsListBlock4:Hide()
    FactionsListBlock5:Hide()
    FactionsListBlock6:Hide()
    FactionsListBlock7:Hide()
    FactionsListBlock8:Hide()
    FactionsListBlock9:Hide()

    FactionsListScrollBar.ScrollUpButton:Disable()
    FactionsListScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.FactionsView:WipeAll()
    if (FactionsListBlock1.faction ~= nil) then
        FactionsListBlock1.faction = nil
    end

    if (FactionsListBlock2.faction ~= nil) then
        FactionsListBlock2.faction = nil
    end

    if (FactionsListBlock3.faction ~= nil) then
        FactionsListBlock3.faction = nil
    end

    if (FactionsListBlock4.faction ~= nil) then
        FactionsListBlock4.faction = nil
    end

    if (FactionsListBlock5.faction ~= nil) then
        FactionsListBlock5.faction = nil
    end

    if (FactionsListBlock6.faction ~= nil) then
        FactionsListBlock6.faction = nil
    end

    if (FactionsListBlock7.faction ~= nil) then
        FactionsListBlock7.faction = nil
    end

    if (FactionsListBlock8.faction ~= nil) then
        FactionsListBlock8.faction = nil
    end

    if (FactionsListBlock9.faction ~= nil) then
        FactionsListBlock9.faction = nil
    end

    Chronicles.UI.FactionsView.CurrentPage = nil
end

function DisplayFactionsList(page)
    Chronicles.UI.FactionsView:DisplayFactionList(page)
end

function Chronicles.UI.FactionsView:DisplayFactionList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.myJournal.factionListPageSize
        local factionList = Chronicles.DB:SearchFactions()

        local numberOfFactions = tablelength(factionList)

        if (numberOfFactions > 0) then
            local maxPageValue = math.ceil(numberOfFactions / pageSize)
            FactionsListScrollBar:SetMinMaxValues(1, maxPageValue)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (Chronicles.UI.FactionsView.CurrentPage ~= page or force) then
                Chronicles.UI.FactionsView:HideAll()
                Chronicles.UI.FactionsView:WipeAll()

                if (numberOfFactions > pageSize) then
                    FactionsListScrollBar.ScrollUpButton:Enable()
                    FactionsListScrollBar.ScrollDownButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + pageSize - 1

                if (firstIndex <= 1) then
                    firstIndex = 1
                    FactionsListScrollBar.ScrollUpButton:Disable()
                    Chronicles.UI.FactionsView.CurrentPage = 1
                end

                if ((firstIndex + pageSize - 1) >= numberOfFactions) then
                    lastIndex = numberOfFactions
                    FactionsListScrollBar.ScrollDownButton:Disable()
                end

                Chronicles.UI.FactionsView.CurrentPage = page
                FactionsListScrollBar:SetValue(Chronicles.UI.FactionsView.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex], FactionsListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 1], FactionsListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 2], FactionsListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 3], FactionsListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 4], FactionsListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 5], FactionsListBlock6)
                end

                if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 6], FactionsListBlock7)
                end

                if (((firstIndex + 7) > 0) and ((firstIndex + 7) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 7], FactionsListBlock8)
                end

                if (((firstIndex + 8) > 0) and ((firstIndex + 8) <= lastIndex)) then
                    Chronicles.UI.FactionsView:SetTextToFrame(factionList[firstIndex + 8], FactionsListBlock9)
                end
            end
        else
            Chronicles.UI.FactionsView:HideAll()
        end
    end
end

function Chronicles.UI.FactionsView:SetTextToFrame(faction, frame)
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
                Chronicles.UI.FactionsView:SetFactionDetails(faction)
            end
        )
        frame:Show()
    end
end

------------------------------------------------------------------------------------------
-- Scroll List ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function FactionsListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        FactionsListPreviousButton_OnClick(self)
    else
        FactionsListNextButton_OnClick(self)
    end
end

function FactionsListPreviousButton_OnClick(self)
    if (Chronicles.UI.FactionsView.CurrentPage == nil) then
        Chronicles.UI.FactionsView:DisplayFactionList(1)
    else
        Chronicles.UI.FactionsView:DisplayFactionList(Chronicles.UI.FactionsView.CurrentPage - 1)
    end
end

function FactionsListNextButton_OnClick(self)
    if (Chronicles.UI.FactionsView.CurrentPage == nil) then
        Chronicles.UI.FactionsView:DisplayFactionList(1)
    else
        Chronicles.UI.FactionsView:DisplayFactionList(Chronicles.UI.FactionsView.CurrentPage + 1)
    end
end

------------------------------------------------------------------------------------------
-- Details -------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.FactionsView:CleanSelectedFaction()
    FactionTimelineLabel:Hide()
    FactionTitle:SetText("")
    FactionDescriptionHTML:SetText("")
    FactionTimeline:SetText("")
end

function Chronicles.UI.FactionsView:SetFactionDetails(faction)
    if (faction == nil) then
        Chronicles.UI.FactionsView:CleanSelectedFaction()
        return
    end

    -- id=[integer],				-- Id of the faction
    -- name=[string], 				-- name of the faction
    -- description=[string],		-- description
    -- timeline=[integer],    		-- id of the timeline

    FactionTimelineLabel:Show()
    FactionTitle:SetText(faction.name)
    FactionDescriptionHTML:SetText(cleanHTML(faction.description))
    FactionTimeline:SetText(Chronicles.constants.timelines[faction.timeline])
end
