local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventList = {}
Chronicles.UI.EventList.Data = nil
Chronicles.UI.EventList.CurrentPage = nil

function Chronicles.UI.EventList:Init()
    EventListFrame:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )

    Chronicles.UI.EventList:DisplayEventList(1, true)
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

        local eventGroupStatus = Chronicles.DB:GetGroupStatus(event.source)
        local eventTypeStatus = Chronicles.DB:GetEventTypeStatus(event.eventType)

        if eventGroupStatus and eventTypeStatus then
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
    DisplayEventList(page, force)
end

function DisplayEventList(page, force)
    if (page ~= nil) then
        local pageSize = Chronicles.constants.config.eventList.pageSize
        --DEFAULT_CHAT_FRAME:AddMessage("-- asked page " .. page)

        if (Chronicles.UI.EventList.Data ~= nil and Chronicles.UI.EventList.Data.events ~= nil) then
            local eventList = Chronicles.UI.EventList:FilterEvents(Chronicles.UI.EventList.Data.events)

            local numberOfEvents = tablelength(eventList)
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

                if (Chronicles.UI.EventList.CurrentPage ~= page or force) then
                    Chronicles.UI.EventList:HideAll()

                    if (numberOfEvents > pageSize) then
                        EventListScrollBar.ScrollUpButton:Enable()
                        EventListScrollBar.ScrollDownButton:Enable()
                    end

                    local firstIndex = 1 + ((page - 1) * pageSize)
                    local lastIndex = firstIndex + 5

                    if (firstIndex <= 1) then
                        firstIndex = 1
                        EventListScrollBar.ScrollUpButton:Disable()
                        Chronicles.UI.EventList.CurrentPage = 1
                    end

                    if ((firstIndex + 5) >= numberOfEvents) then
                        lastIndex = numberOfEvents
                        EventListScrollBar.ScrollDownButton:Disable()
                    end

                    Chronicles.UI.EventList.CurrentPage = page
                    EventListScrollBar:SetValue(Chronicles.UI.EventList.CurrentPage)

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
end

function Chronicles.UI.EventList:HideAll()
    EventListBlock1:Hide()
    EventListBlock2:Hide()
    EventListBlock3:Hide()
    EventListBlock4:Hide()
    EventListBlock5:Hide()
    EventListBlock6:Hide()

    EventListScrollBar.ScrollUpButton:Disable()
    EventListScrollBar.ScrollDownButton:Disable()
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
        local numberOfEvents = tablelength(eventList)

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
end

function EventListNextButton_OnClick(self)
    if (Chronicles.UI.EventList.CurrentPage == nil) then
        Chronicles.UI.EventList:DisplayEventList(1)
    else
        Chronicles.UI.EventList:DisplayEventList(Chronicles.UI.EventList.CurrentPage + 1)
    end
end
