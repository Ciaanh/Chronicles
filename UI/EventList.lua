local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventList = {}

function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function Chronicles.UI.EventList:SetEventListData(lowerBound, upperBound, eventList)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to SetEventListData " .. lowerBound .. " " .. upperBound)

    if (Chronicles.SelectedValues.eventListData ~= nil) then
        wipe(Chronicles.SelectedValues.eventListData)
    end
    Chronicles.SelectedValues.eventListData = {
        events = eventList,
        startDate = lowerBound,
        endDate = upperBound
    }

    local pageSize = Chronicles.constants.eventList.pageSize

    local numberOfEvents = tablelength(eventList)
    if (numberOfEvents > 0) then
        local maxPageValue = math.ceil(numberOfEvents / pageSize)
        EventListScrollBar:SetMinMaxValues(1, maxPageValue)

        Chronicles.SelectedValues.currentTimelinePage = 1
        EventListScrollBar:SetValue(Chronicles.SelectedValues.currentTimelinePage)

        if (numberOfEvents == 0) then
            EventListBlock1:Hide()
            EventListBlock2:Hide()
            EventListBlock3:Hide()
            EventListBlock4:Hide()
            EventListBlock5:Hide()
            EventListBlock6:Hide()
        else
            EventListBlock1:Show()
            EventListBlock2:Show()
            EventListBlock3:Show()
            EventListBlock4:Show()
            EventListBlock5:Show()
            EventListBlock6:Show()
        end
    end
end

function Chronicles.UI.EventList:DisplayEventList()
    Chronicles.UI.Timeline:DisplayTimelinePage(Chronicles.SelectedValues.currentTimelinePage)
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventListScrollFrame_OnMouseWheel(self, value)
    if (value > 0) then
        EventListPreviousButton_OnClick(self)
    else
        EventListNextButton_OnClick(self)
    end
end

function EventListPreviousButton_OnClick(self)
    Chronicles.SelectedValues.currentEventListPage = Chronicles.SelectedValues.currentEventListPage - 1

    Chronicles.UI.EventList:DisplayEventList()
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventListNextButton_OnClick(self)
    Chronicles.SelectedValues.currentEventListPage = Chronicles.SelectedValues.currentEventListPage + 1

    Chronicles.UI.EventList:DisplayEventList()
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
