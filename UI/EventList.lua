local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventList = {}
Chronicles.UI.EventList.Data = nil
Chronicles.UI.EventList.CurrentPage = nil

function Chronicles.UI.EventList:Init()
    Chronicles.UI.EventList:DisplayEventList(1)
end

function Chronicles.UI.EventList:Refresh()
    --DEFAULT_CHAT_FRAME:AddMessage("-- Refresh event list " .. Chronicles.UI.Timeline.CurrentPage)
    Chronicles.UI.EventList.CurrentPage = 1
    Chronicles.UI.EventList:DisplayEventList(1, true)
end

function Chronicles.UI.EventList:FilterEvents(events)
    local foundEvents = {}
    for eventIndex in pairs(events) do
        local event = events[eventIndex]

        if Chronicles.DB:GetGroupStatus(event.source) then
            table.insert(foundEvents, event)
        end
    end

    table.sort(
        foundEvents,
        function(a, b)
            return a.yearStart < b.yearStart
        end
    )
    return foundEvents
end

function Chronicles.UI.EventList:DisplayEventList(page, force)
    local pageSize = Chronicles.constants.config.eventList.pageSize
    --DEFAULT_CHAT_FRAME:AddMessage("-- asked page " .. page)

    if (self.Data ~= nil and self.Data.events ~= nil) then
        local eventList = Chronicles.UI.EventList:FilterEvents(self.Data.events)

        local numberOfEvents = Chronicles:GetTableLength(eventList)
        --DEFAULT_CHAT_FRAME:AddMessage("-- numberOfEvents " .. numberOfEvents)

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

            if (self.CurrentPage ~= page or force) then
                self:HideAll()

                if (numberOfEvents > pageSize) then
                    EventListPreviousButton:Enable()
                    EventListNextButton:Enable()
                end

                local firstIndex = 1 + ((page - 1) * pageSize)
                local lastIndex = firstIndex + 5

                if (firstIndex <= 1) then
                    firstIndex = 1
                    EventListPreviousButton:Disable()
                    self.CurrentPage = 1
                end

                if ((firstIndex + 5) >= numberOfEvents) then
                    lastIndex = numberOfEvents
                    EventListNextButton:Disable()
                end

                self.CurrentPage = page
                EventListScrollBar:SetValue(self.CurrentPage)

                if ((firstIndex > 0) and (firstIndex <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex], EventListBlock1)
                end

                if (((firstIndex + 1) > 0) and ((firstIndex + 1) <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex + 1], EventListBlock2)
                end

                if (((firstIndex + 2) > 0) and ((firstIndex + 2) <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex + 2], EventListBlock3)
                end

                if (((firstIndex + 3) > 0) and ((firstIndex + 3) <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex + 3], EventListBlock4)
                end

                if (((firstIndex + 4) > 0) and ((firstIndex + 4) <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex + 4], EventListBlock5)
                end

                if (((firstIndex + 5) > 0) and ((firstIndex + 5) <= lastIndex)) then
                    self:SetTextToFrame(eventList[firstIndex + 5], EventListBlock6)
                end
            end
        else
            self:HideAll()
        end
    else
        self:HideAll()
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
end

function Chronicles.UI.EventList:WipeAll()
    if (EventListBlock1.event ~= nil) then
        EventListBlock1.event = nil
    end

    if (EventListBlock2.event ~= nil) then
        EventListBlock2.event = nil
    end

    if (EventListBlock3.event ~= nil) then
        EventListBlock3.event = nil
    end

    if (EventListBlock4.event ~= nil) then
        EventListBlock4.event = nil
    end

    if (EventListBlock5.event ~= nil) then
        EventListBlock5.event = nil
    end

    if (EventListBlock6.event ~= nil) then
        EventListBlock6.event = nil
    end

    if (self.Data ~= nil) then
        self.Data = nil
    end
    self.Data = nil
    self.CurrentPage = nil
end

function Chronicles.UI.EventList:SetEventListData(lowerBound, upperBound, eventList)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Call to SetEventListData " .. lowerBound .. " " .. upperBound)

    if (eventList == nil) then
        self:HideAll()
        self:WipeAll()
    else
        -- DEFAULT_CHAT_FRAME:AddMessage("-- SetEventListData numberOfEvents " .. numberOfEvents)
        local numberOfEvents = Chronicles:GetTableLength(eventList)

        if (numberOfEvents == 0) then
            self:HideAll()
            self:WipeAll()
        else
            self:WipeAll()

            self.Data = {
                events = eventList,
                startDate = lowerBound,
                endDate = upperBound
            }
            self:DisplayEventList(1)
        end
    end
end

--[[ structure:
    [eventId] = {
        id=[integer],				-- Id of the event
        label=[string], 			-- label: text that'll be the label
        description=table[string], 	-- description: text that give informations about the event
        yearStart=[integer],		-- 
        yearEnd=[integer],			-- 
        eventType=[string],			-- type of event defined in constants
    },
--]]
function Chronicles.UI.EventList:SetTextToFrame(event, frame)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Render frame")
    if (frame.event ~= nil) then
        frame.event = nil
    end
    frame:Hide()
    if (event ~= nil) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- event not nil " .. event.label)
        local label = _G[frame:GetName() .. "Text"]
        label:SetText(event.label)

        frame.event = event
        frame:SetScript(
            "OnMouseDown",
            function()
                Chronicles.UI.EventDescription:DrawEventDescription(frame.event)
            end
        )
        frame:Show()
    end
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventListScrollFrame_OnMouseWheel(self, value)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- scroll " .. value)
    if (value > 0) then
        EventListPreviousButton_OnClick(self)
    else
        EventListNextButton_OnClick(self)
    end
end

function EventListPreviousButton_OnClick(self)
    if (Chronicles.UI.EventList.CurrentPage == nil) then
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.UI.EventList.CurrentPage - 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventListNextButton_OnClick(self)
    if (Chronicles.UI.EventList.CurrentPage == nil) then
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.UI.EventList.CurrentPage + 1)
    end
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
