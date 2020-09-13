local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventFilter = {}
Chronicles.UI.EventFilter.Displayed = false

Chronicles.UI.EventFilter.LibrariesData = nil
Chronicles.UI.EventFilter.CurrentLibrariesPage = nil

function Chronicles.UI.EventFilter:Init()
    EventTypeBlockEra:SetChecked(get_EventType_Checked(get_constants().eventType.era))
    EventTypeBlockWar:SetChecked(get_EventType_Checked(get_constants().eventType.war))
    EventTypeBlockBattle:SetChecked(get_EventType_Checked(get_constants().eventType.battle))
    EventTypeBlockDeath:SetChecked(get_EventType_Checked(get_constants().eventType.death))
    EventTypeBlockBirth:SetChecked(get_EventType_Checked(get_constants().eventType.birth))
    EventTypeBlockOther:SetChecked(get_EventType_Checked(get_constants().eventType.other))
end

function EventFilter_InitToggle(self)
    self:SetText("<")
end

function EventFilter_Toggle()
    if (Chronicles.UI.EventFilter.Displayed) then
        EventFilter:Hide()
        Chronicles.UI.EventFilter.Displayed = false
        EventFilterToggle:SetText("<")
    else
        Chronicles.UI.EventFilter:SetLibrariesFilterData()
        EventFilter:Show()
        Chronicles.UI.EventFilter.Displayed = true
        EventFilterToggle:SetText(">")
    end
end

------------------------------------------------------------------------------------------
-- Event type Filter ---------------------------------------------------------------------
------------------------------------------------------------------------------------------
function change_EventType(eventType, checked)
    Chronicles.DB:SetEventTypeStatus(eventType, checked)

    Chronicles.UI.EventList:Refresh()
    Chronicles.UI.Timeline:Refresh()
    Chronicles.UI.EventDescription:Refresh()
end

function get_EventType_Checked(eventType)
    return Chronicles.DB:GetEventTypeStatus(eventType)
end

------------------------------------------------------------------------------------------
-- Libraries Filter ----------------------------------------------------------------------
------------------------------------------------------------------------------------------
function Chronicles.UI.EventFilter:DisplayLibrariesFilter(page)
    DisplayLibrariesFilter(page)
end
function DisplayLibrariesFilter(page)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.eventFilter.pageSize

        if (Chronicles.UI.EventFilter.LibrariesData ~= nil) then
            local eventGroups = Chronicles.UI.EventFilter.LibrariesData

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

                if (Chronicles.UI.EventFilter.CurrentLibrariesPage ~= page) then
                    Chronicles.UI.EventFilter:HideAllLibrariesContent()

                    if (numberOfGroups > pageSize) then
                        LibrariesFilterScrollBar.ScrollUpButton:Enable()
                        LibrariesFilterScrollBar.ScrollDownButton:Enable()
                    end

                    local firstIndex = 1 + ((page - 1) * pageSize)
                    local lastIndex = firstIndex + pageSize - 1

                    if (firstIndex <= 1) then
                        firstIndex = 1
                        LibrariesFilterScrollBar.ScrollUpButton:Disable()
                        Chronicles.UI.EventFilter.CurrentLibrariesPage = 1
                    end

                    if ((firstIndex + pageSize - 1) >= numberOfGroups) then
                        lastIndex = numberOfGroups
                        LibrariesFilterScrollBar.ScrollDownButton:Disable()
                    end

                    Chronicles.UI.EventFilter.CurrentLibrariesPage = page
                    LibrariesFilterScrollBar:SetValue(Chronicles.UI.EventFilter.CurrentLibrariesPage)

                    if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex], LibrariesFilterBlock1)
                    end

                    if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 1], LibrariesFilterBlock2)
                    end

                    if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 2], LibrariesFilterBlock3)
                    end

                    if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 3], LibrariesFilterBlock4)
                    end

                    if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 4], LibrariesFilterBlock5)
                    end

                    if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 5], LibrariesFilterBlock6)
                    end

                    if (((firstIndex + 6) > 0) and ((firstIndex + 6) <= lastIndex)) then
                        Chronicles.UI.EventFilter:SetTextToFrame(eventGroups[firstIndex + 6], LibrariesFilterBlock7)
                    end
                end
            else
                Chronicles.UI.EventFilter:HideAllLibrariesContent()
            end
        else
            Chronicles.UI.EventFilter:HideAllLibrariesContent()
        end
    end
end

function Chronicles.UI.EventFilter:HideAllLibrariesContent()
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

function Chronicles.UI.EventFilter:WipeAllLibrariesContent()
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

function Chronicles.UI.EventFilter:SetLibrariesFilterData()
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

function Chronicles.UI.EventFilter:SetTextToFrame(group, checkBox)
    if (checkBox.group ~= nil) then
        checkBox.group = nil
    end
    checkBox:Hide()

    if (group ~= nil) then
        local text = group.name
        if (text:len() > 6) then
            text = text:sub(0, 6)

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

        local label = _G[checkBox:GetName() .. "Text"]
        label:SetText(text)

        checkBox:SetChecked(group.isActive)

        checkBox.group = group
        checkBox:SetScript(
            "OnClick",
            function(selfCheckBox)
                group.isActive = not group.isActive

                Chronicles.DB:SetGroupStatus(group.name, group.isActive)

                Chronicles.UI.EventList:Refresh()
                Chronicles.UI.Timeline:Refresh()
                Chronicles.UI.EventDescription:Refresh()
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
    if (Chronicles.UI.EventFilter.CurrentLibrariesPage == nil) then
        Chronicles.UI.EventFilter:DisplayLibrariesFilter(1)
    else
        Chronicles.UI.EventFilter:DisplayLibrariesFilter(Chronicles.UI.EventFilter.CurrentLibrariesPage - 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function LibrariesFilterNextButton_OnClick(self)
    if (Chronicles.UI.EventFilter.CurrentLibrariesPage == nil) then
        Chronicles.UI.EventFilter:DisplayLibrariesFilter(1)
    else
        Chronicles.UI.EventFilter:DisplayLibrariesFilter(Chronicles.UI.EventFilter.CurrentLibrariesPage + 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
