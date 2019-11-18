local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventList = {}

function tablelength(T)
    local count = 0
    if (T ~= nil) then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end

function Chronicles.UI.EventList:DisplayEventList(page)
    local pageSize = Chronicles.constants.eventList.pageSize
    DEFAULT_CHAT_FRAME:AddMessage("-- asked page " .. page)

    if (Chronicles.SelectedValues.eventListData ~= nil) then
        local eventList = Chronicles.SelectedValues.eventListData.events

        local numberOfEvents = tablelength(eventList)
        DEFAULT_CHAT_FRAME:AddMessage("-- numberOfEvents " .. numberOfEvents)

        if (numberOfEvents > 0) then
            local maxPageValue = math.ceil(numberOfEvents / pageSize)
            EventListScrollBar:SetMinMaxValues(1, maxPageValue)
            -- DEFAULT_CHAT_FRAME:AddMessage("-- maxPageValue " .. maxPageValue .. " asked page " .. page)

            if (page > maxPageValue) then
                page = maxPageValue
            end
            if (page < 1) then
                page = 1
            end
            if (Chronicles.SelectedValues.currentEventListPage ~= nil) then
                DEFAULT_CHAT_FRAME:AddMessage(
                    "-- current " .. Chronicles.SelectedValues.currentEventListPage .. " asked page " .. page
                )
            end
            if (Chronicles.SelectedValues.currentEventListPage ~= page) then
                Chronicles.SelectedValues.currentEventListPage = page
                EventListScrollBar:SetValue(Chronicles.SelectedValues.currentEventListPage)

                if (numberOfEvents <= pageSize) then
                    EventListPreviousButton:Disable()
                    EventListNextButton:Disable()
                else
                    EventListPreviousButton:Enable()
                    EventListNextButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 5
                -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex .. " LastIndex " .. lastIndex)

                if (firstIndex <= 1) then
                    firstIndex = 1
                    EventListPreviousButton:Disable()
                    Chronicles.SelectedValues.currentEventListPage = 1
                end

                if ((firstIndex + 5) >= numberOfEvents) then
                    lastIndex = numberOfEvents
                    EventListNextButton:Disable()
                    
                end

                -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex .. " LastIndex " .. lastIndex)

                Chronicles.UI.EventList:HideAll()

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex + 1], EventListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex + 2], EventListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex + 3], EventListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex + 4], EventListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex + 5], EventListBlock6)
                end
            end
        else
            Chronicles.UI.EventList:HideAll()
        end
    else
        Chronicles.UI.EventList:HideAll()
    end
end

function Chronicles.UI.EventList:HideAll()
    EventListBlock1:Hide()
    if (EventListBlock1.event ~= nil) then
        wipe(EventListBlock1.event)
    end

    EventListBlock2:Hide()
    if (EventListBlock2.event ~= nil) then
        wipe(EventListBlock2.event)
    end

    EventListBlock3:Hide()
    if (EventListBlock3.event ~= nil) then
        wipe(EventListBlock3.event)
    end

    EventListBlock4:Hide()
    if (EventListBlock4.event ~= nil) then
        wipe(EventListBlock4.event)
    end

    EventListBlock5:Hide()
    if (EventListBlock5.event ~= nil) then
        wipe(EventListBlock5.event)
    end

    EventListBlock6:Hide()
    if (EventListBlock6.event ~= nil) then
        wipe(EventListBlock6.event)
    end

    EventListPreviousButton:Disable()
    EventListNextButton:Disable()

    Chronicles.SelectedValues.currentEventListPage = nil
end

function Chronicles.UI.EventList:SetEventListData(lowerBound, upperBound, eventList)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Call to SetEventListData " .. lowerBound .. " " .. upperBound)

    Chronicles.SelectedValues.selectedEvent = nil

    if (eventList == nil) then
        Chronicles.UI.EventList:HideAll()
    else
        -- DEFAULT_CHAT_FRAME:AddMessage("-- SetEventListData numberOfEvents " .. numberOfEvents)
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
        if (numberOfEvents == 0) then
            Chronicles.UI.EventList:HideAll()
        else
            Chronicles.UI.EventList:DisplayEventList(1)
        end
    end
end

--[[ structure:
    [eventId] = {
        id=[integer],				-- Id of the event
        label=[string], 			-- label: text that'll be the label
        description=table[string], 	-- description: text that give informations about the event
        icon=[string], 				-- the pre-define icon type which can be found in Constant.lua
        yearStart=[integer],		-- 
        yearEnd=[integer],			-- 
        eventType=[string],			-- type of event defined in constants
    },
--]]
function Chronicles.UI.EventList:SetTextToFrame(event, frame)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Render frame")
    if (event ~= nil) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- event not nil " .. event.label)

        frame:Show()

        local label = _G[frame:GetName() .. "Text"]
        label:SetText(event.label)
        frame.event = event

        frame:SetScript(
            "OnMouseDown",
            function()
                Chronicles.SelectedValues.selectedEvent = frame.event.id
                Chronicles.UI.EventDescription:DrawEventDescription(frame.event)
            end
        )
    end
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventListScrollFrame_OnMouseWheel(self, value)
    DEFAULT_CHAT_FRAME:AddMessage("-- scroll " .. value)
    if (value > 0) then
        EventListPreviousButton_OnClick(self)
    else
        EventListNextButton_OnClick(self)
    end
end

function EventListPreviousButton_OnClick(self)
    if (Chronicles.SelectedValues.currentEventListPage == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("-- previous null ")
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.SelectedValues.currentEventListPage - 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventListNextButton_OnClick(self)
    if (Chronicles.SelectedValues.currentEventListPage == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("-- next null ")
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.SelectedValues.currentEventListPage + 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
