local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventFilter = {}
Chronicles.UI.EventFilter.Displayed = false
Chronicles.UI.EventFilter.Data = nil
Chronicles.UI.EventFilter.CurrentPage = nil

function EventFilter_InitToggle(self)
    self:SetText("<")
end

function EventFilter_Toggle()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Toggle EventFilter " .. tostring(Chronicles.UI.EventFilter.Displayed))

    if (Chronicles.UI.EventFilter.Displayed) then
        FilterContent:Hide()
        Chronicles.UI.EventFilter.Displayed = false
    else
        Chronicles.UI.EventFilter:SetEventFilterData()
        FilterContent:Show()
        Chronicles.UI.EventFilter.Displayed = true
    end
end

function Chronicles.UI.EventFilter:DisplayEventFilter(page)
    local pageSize = Chronicles.constants.config.eventFilter.pageSize

    --DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:DisplayEventFilter call")

    if (self.Data ~= nil) then
        local eventGroups = self.Data

        local numberOfGroups = Chronicles:GetTableLength(eventGroups)

        if (numberOfGroups > 0) then
            local maxPageValue = math.ceil(numberOfGroups / pageSize)
            EventFilterScrollBar:SetMinMaxValues(1, maxPageValue)
            -- DEFAULT_CHAT_FRAME:AddMessage("-- maxPageValue " .. maxPageValue .. " asked page " .. page)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end

            if (self.CurrentPage ~= page) then
                self:HideAll()

                if (numberOfGroups > pageSize) then
                    EventFilterPreviousButton:Enable()
                    EventFilterNextButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 5

                if (firstIndex <= 1) then
                    firstIndex = 1
                    EventFilterPreviousButton:Disable()
                    self.CurrentPage = 1
                end

                if ((firstIndex + 5) >= numberOfGroups) then
                    lastIndex = numberOfGroups
                    EventFilterNextButton:Disable()
                end

                self.CurrentPage = page
                EventFilterScrollBar:SetValue(self.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex], EventFilterBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex + 1], EventFilterBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex + 2], EventFilterBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex + 3], EventFilterBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex + 4], EventFilterBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    self:SetTextToFrame(eventGroups[firstIndex + 5], EventFilterBlock6)
                end
            end
        else
            self:HideAll()
        end
    else
        self:HideAll()
    end
end

function Chronicles.UI.EventFilter:HideAll()
    EventFilterBlock1:Hide()
    EventFilterBlock2:Hide()
    EventFilterBlock3:Hide()
    EventFilterBlock4:Hide()
    EventFilterBlock5:Hide()
    EventFilterBlock6:Hide()

    EventFilterPreviousButton:Disable()
    EventFilterNextButton:Disable()
end

function Chronicles.UI.EventFilter:WipeAll()
    if (EventFilterBlock1.event ~= nil) then
        EventFilterBlock1.event = nil
    end

    if (EventFilterBlock2.event ~= nil) then
        EventFilterBlock2.event = nil
    end

    if (EventFilterBlock3.event ~= nil) then
        EventFilterBlock3.event = nil
    end

    if (EventFilterBlock4.event ~= nil) then
        EventFilterBlock4.event = nil
    end

    if (EventFilterBlock5.event ~= nil) then
        EventFilterBlock5.event = nil
    end

    if (EventFilterBlock6.event ~= nil) then
        EventFilterBlock6.event = nil
    end

    if (self.Data ~= nil) then
        self.Data = nil
    end
    self.Data = nil
    self.CurrentPage = nil
end

function Chronicles.UI.EventFilter:SetEventFilterData()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:SetEventFilterData call")

    local groupList = Chronicles.DB:GetEventGroupNames()

    if (groupList == nil) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:SetEventFilterData nil")

        self:HideAll()
        self:WipeAll()
    else
        local numberOfGroups = Chronicles:GetTableLength(groupList)

        --DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:SetEventFilterData numberOfGroups " .. numberOfGroups)

        if (numberOfGroups == 0) then
            self:HideAll()
            self:WipeAll()
        else
            self:WipeAll()

            self.Data = groupList
            self:DisplayEventFilter(1)
        end
    end
end

function Chronicles.UI.EventFilter:SetTextToFrame(group, checkBox)
    --DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:SetTextToFrame call")

    if (checkBox.group ~= nil) then
        checkBox.group = nil
    end
    checkBox:Hide()

    if (group ~= nil) then
        --DEFAULT_CHAT_FRAME:AddMessage("-- EventFilter:SetTextToFrame " .. group.name .. " "..tostring(group.isActive))
        local label = _G[checkBox:GetName() .. "Text"]
        label:SetText(group.name)

        checkBox:SetChecked(group.isActive);

        checkBox.group = group
        checkBox:SetScript(
            "OnClick",
            function(selfCheckBox)
                local checked = selfCheckBox:GetChecked()
                Chronicles.DB:SetGroupStatus(group.name, not group.isActive)

                Chronicles.UI.EventList:Refresh()
                DEFAULT_CHAT_FRAME:AddMessage("-- blob ")
                Chronicles.UI.Timeline:Refresh()
                DEFAULT_CHAT_FRAME:AddMessage("-- blob 2")
            end
        )
        checkBox:Show()
    end
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventFilterScrollFrame_OnMouseWheel(self, value)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- scroll " .. value)
    if (value > 0) then
        EventFilterPreviousButton_OnClick(self)
    else
        EventFilterNextButton_OnClick(self)
    end
end

function EventFilterPreviousButton_OnClick(self)
    if (Chronicles.UI.EventFilter.CurrentPage == nil) then
        Chronicles.UI.EventFilter:DisplayEventFilter(1)
    else
        Chronicles.UI.EventFilter:DisplayEventFilter(Chronicles.UI.EventFilter.CurrentPage - 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventFilterNextButton_OnClick(self)
    if (Chronicles.UI.EventFilter.CurrentPage == nil) then
        Chronicles.UI.EventFilter:DisplayEventFilter(1)
    else
        Chronicles.UI.EventFilter:DisplayEventFilter(Chronicles.UI.EventFilter.CurrentPage + 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
