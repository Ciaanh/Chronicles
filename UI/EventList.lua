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

    if (Chronicles.SelectedValues.eventListData ~= nil) then
        local eventList = Chronicles.SelectedValues.eventListData.events

        local numberOfEvents = tablelength(eventList)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- numberOfEvents " .. numberOfEvents)

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
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    Chronicles.UI.EventList:SetTextToFrame(eventList[firstIndex], EventListBlock6)
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
    EventListBlock2:Hide()
    EventListBlock3:Hide()
    EventListBlock4:Hide()
    EventListBlock5:Hide()
    EventListBlock6:Hide()

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

        frame:SetScript(
            "OnMouseDown",
            function()
                Chronicles.SelectedValues.selectedEvent = event.id
                Chronicles.UI.EventDescription:DrawEventDescription(event)
            end
        )
    end
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
    if (Chronicles.SelectedValues.currentEventListPage == nil) then
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.SelectedValues.currentEventListPage - 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventListNextButton_OnClick(self)
    if (Chronicles.SelectedValues.currentEventListPage == nil) then
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.SelectedValues.currentEventListPage + 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
