local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.OptionsView = {}

Chronicles.UI.OptionsView.LibrariesData = nil
Chronicles.UI.OptionsView.CurrentLibrariesPage = nil

function Chronicles.UI.OptionsView:Init()
    Chronicles.UI.OptionsView:SetLibrariesFilterData()
    OptionsView.Title:SetText(Locale["Options"])

    LibrariesFilter.Title:SetText(Locale["Libraries"])
    LibrariesFilter:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    ConfigurationList.Title:SetText(Locale["Configuration"])
    ConfigurationList:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    MyJournalCheckBox.Text:SetText(Locale["My journal"])
    MyJournalCheckBox:SetChecked(Chronicles.storage.global.options.myjournal)
end

------------------------------------------------------------------------------------------
-- My Journal ----------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function MyJournalCheckBox_OnClick()
    Chronicles.storage.global.options.myjournal = not Chronicles.storage.global.options.myjournal
    
    if (Chronicles.storage.global.options.myjournal) then
        MyJournalViewShow:Show()
        Chronicles.DB:SetGroupStatus("myjournal", true)
    else
        MyJournalViewShow:Hide()
        Chronicles.DB:SetGroupStatus("myjournal", false)
    end

    Chronicles.UI:Refresh()
end

------------------------------------------------------------------------------------------
-- Libraries Filter ----------------------------------------------------------------------
------------------------------------------------------------------------------------------
function Chronicles.UI.OptionsView:DisplayLibrariesFilter(page)
    DisplayLibrariesFilter(page)
end

function DisplayLibrariesFilter(page)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.librariesFilter.pageSize

        if (Chronicles.UI.OptionsView.LibrariesData ~= nil) then
            local eventGroups = Chronicles.UI.OptionsView.LibrariesData

            local numberOfGroups = tablelength(eventGroups)

            if (numberOfGroups > 0) then
                local maxPageValue = math.ceil(numberOfGroups / pageSize)
                LibrariesFilterScrollBar:SetMinMaxValues(1, maxPageValue)

                if (page > maxPageValue) then
                    page = maxPageValue
                end
                if (page < 1) then
                    page = 1
                end

                if (Chronicles.UI.OptionsView.CurrentLibrariesPage ~= page) then
                    Chronicles.UI.OptionsView:HideAllLibrariesContent()

                    if (numberOfGroups > pageSize) then
                        LibrariesFilterScrollBar.ScrollUpButton:Enable()
                        LibrariesFilterScrollBar.ScrollDownButton:Enable()
                    end

                    local firstIndex = 1 + ((page - 1) * pageSize)
                    local lastIndex = firstIndex + pageSize - 1

                    if (firstIndex <= 1) then
                        firstIndex = 1
                        LibrariesFilterScrollBar.ScrollUpButton:Disable()
                        Chronicles.UI.OptionsView.CurrentLibrariesPage = 1
                    end

                    if ((firstIndex + pageSize - 1) >= numberOfGroups) then
                        lastIndex = numberOfGroups
                        LibrariesFilterScrollBar.ScrollDownButton:Disable()
                    end

                    Chronicles.UI.OptionsView.CurrentLibrariesPage = page
                    LibrariesFilterScrollBar:SetValue(Chronicles.UI.OptionsView.CurrentLibrariesPage)

                    if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex], LibrariesFilterBlock1)
                    end

                    if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 1], LibrariesFilterBlock2)
                    end

                    if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 2], LibrariesFilterBlock3)
                    end

                    if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 3], LibrariesFilterBlock4)
                    end

                    if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 4], LibrariesFilterBlock5)
                    end

                    if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 5], LibrariesFilterBlock6)
                    end

                    if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                        Chronicles.UI.OptionsView:SetTextToFrame(eventGroups[firstIndex + 6], LibrariesFilterBlock7)
                    end
                end
            else
                Chronicles.UI.OptionsView:HideAllLibrariesContent()
            end
        else
            Chronicles.UI.OptionsView:HideAllLibrariesContent()
        end
    end
end

function Chronicles.UI.OptionsView:HideAllLibrariesContent()
    LibrariesFilterBlock1:Hide()
    LibrariesFilterBlock2:Hide()
    LibrariesFilterBlock3:Hide()
    LibrariesFilterBlock4:Hide()
    LibrariesFilterBlock5:Hide()
    LibrariesFilterBlock6:Hide()
    LibrariesFilterBlock7:Hide()

    LibrariesFilterScrollBar.ScrollUpButton:Disable()
    LibrariesFilterScrollBar.ScrollDownButton:Disable()
end

function Chronicles.UI.OptionsView:WipeAllLibrariesContent()
    if (LibrariesFilterBlock1.event ~= nil) then
        LibrariesFilterBlock1.event = nil
    end

    if (LibrariesFilterBlock2.event ~= nil) then
        LibrariesFilterBlock2.event = nil
    end

    if (LibrariesFilterBlock3.event ~= nil) then
        LibrariesFilterBlock3.event = nil
    end

    if (LibrariesFilterBlock4.event ~= nil) then
        LibrariesFilterBlock4.event = nil
    end

    if (LibrariesFilterBlock5.event ~= nil) then
        LibrariesFilterBlock5.event = nil
    end

    if (LibrariesFilterBlock6.event ~= nil) then
        LibrariesFilterBlock6.event = nil
    end

    if (LibrariesFilterBlock7.event ~= nil) then
        LibrariesFilterBlock7.event = nil
    end

    if (self.LibrariesData ~= nil) then
        self.LibrariesData = nil
    end
    self.LibrariesData = nil
    self.CurrentLibrariesPage = nil
end

function Chronicles.UI.OptionsView:SetLibrariesFilterData()
    local groupList = Chronicles.DB:GetGroupNames()

    if (groupList == nil) then
        self:HideAllLibrariesContent()
        self:WipeAllLibrariesContent()
    else
        local numberOfGroups = tablelength(groupList)

        if (numberOfGroups == 0) then
            self:HideAllLibrariesContent()
            self:WipeAllLibrariesContent()
        else
            self:WipeAllLibrariesContent()

            self.LibrariesData = groupList
            self:DisplayLibrariesFilter(1)
        end
    end
end

function Chronicles.UI.OptionsView:SetTextToFrame(group, checkBox)
    if (checkBox.group ~= nil) then
        checkBox.group = nil
    end
    checkBox:Hide()

    if (group ~= nil) then
        local text = group.name
        if (text:len() > 15) then
            text = text:sub(0, 15)

            checkBox:SetScript(
                "OnEnter",
                function()
                    GameTooltip:SetOwner(checkBox, "ANCHOR_BOTTOMRIGHT", -5, 30)
                    GameTooltip:SetText(group.name, nil, nil, nil, nil, true)
                end
            )
            checkBox:SetScript(
                "OnLeave",
                function()
                    GameTooltip:Hide()
                end
            )
        else
            checkBox:SetScript(
                "OnEnter",
                function()
                end
            )
            checkBox:SetScript(
                "OnLeave",
                function()
                end
            )
        end

        -- local label = _G[checkBox:GetName() .. "Text"]
        -- label:SetText(text)
        checkBox.Text:SetText(text)

        checkBox:SetChecked(group.isActive)

        checkBox.group = group
        checkBox:SetScript(
            "OnClick",
            function(selfCheckBox)
                group.isActive = not group.isActive

                Chronicles.DB:SetGroupStatus(group.name, group.isActive)
                Chronicles.UI:Refresh()
            end
        )
        checkBox:Show()
    end
end

function LibrariesFilterScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        LibrariesFilterPreviousButton_OnClick(self)
    else
        LibrariesFilterNextButton_OnClick(self)
    end
end

function LibrariesFilterPreviousButton_OnClick(self)
    if (Chronicles.UI.OptionsView.CurrentLibrariesPage == nil) then
        Chronicles.UI.OptionsView:DisplayLibrariesFilter(1)
    else
        Chronicles.UI.OptionsView:DisplayLibrariesFilter(Chronicles.UI.OptionsView.CurrentLibrariesPage - 1)
    end
end

function LibrariesFilterNextButton_OnClick(self)
    if (Chronicles.UI.OptionsView.CurrentLibrariesPage == nil) then
        Chronicles.UI.OptionsView:DisplayLibrariesFilter(1)
    else
        Chronicles.UI.OptionsView:DisplayLibrariesFilter(Chronicles.UI.OptionsView.CurrentLibrariesPage + 1)
    end
end
