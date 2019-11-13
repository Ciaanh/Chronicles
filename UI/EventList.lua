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

-- Accept a list of events
function Chronicles.UI.EventList:DrawEventList(lowerBound, upperBound, eventList)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to DrawEventList " .. lowerBound .. " " .. upperBound)

    -- if (eventList ~= nil) then
    --     -- local child = CreateFrame("Frame", "EventListScrollChild", EventListScrollFrame)
    --     -- child:SetSize(85, 600)
    --     -- EventListScrollFrame.ScrollBar:SetMinMaxValues(0, 600)
    --     -- EventListScrollFrame.ScrollBar:SetValueStep(1)
    --     -- EventListScrollFrame:SetScrollChild(child)

    --     --EventList.scroll.child:SetSize(85, 600)
    --     EventListScrollBar:SetMinMaxValues(1, tablelength(eventList))
    --     EventListScrollBar:SetValueStep(1)

    --     local previousBlock = nil

    --     for eventIndex in pairs(eventList) do
    --         local event = eventList[eventIndex]
    --         -- Chronicles.UI:AddEvent(event.label, event.yearStart, event.yearEnd, container)

    --         -- EventListBlockTemplate
    --         -- EventList.scroll.child

    --         local text = "" .. event.label .. "\n" .. event.yearStart .. "   " .. event.yearEnd

    --         DEFAULT_CHAT_FRAME:AddMessage("-- Cell " .. "  " .. text)

    --         local frame = CreateFrame("Frame", nil, EventListScrollChild, "EventListBlockTemplate")
    --         frame.event = event

    --         local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    --         highlight:SetTexture(nil)
    --         highlight:SetAllPoints()
    --         highlight:SetBlendMode("ADD")

    --         local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    --         label:SetText(text)
    --         label.highlight = highlight
    --         label:SetPoint("CENTER")

    --         -- local image = frame:CreateTexture(nil, "BACKGROUND")
    --         -- image:SetTexture(path)
    --         -- image:SetTexCoord(0, 1, 0, 1)

    --         frame:EnableMouse(true)
    --         frame:SetScript(
    --             "OnMouseDown",
    --             function()
    --                 Chronicles.UI.EventDescription:DrawEventDescription(frame.event)
    --             end
    --         )

    --         if (previousBlock == nil) then
    --             frame:SetPoint("LEFT", child, "LEFT", 0, 0)
    --         else
    --             frame:SetPoint("LEFT", previousBlock, "RIGHT", 5, 0)
    --         end

    --         previousBlock = frame
    --     end
    -- end
end

function Chronicles.UI.EventList:CreateEventListContainer()
    -- local eventListContainer = AceGUI:Create("InlineGroup")
    -- eventListContainer:SetRelativeWidth(0.25)
    -- eventListContainer:SetAutoAdjustHeight(false)
    -- eventListContainer:SetHeight(425)
    -- eventListContainer:SetLayout("Flow")
    -- eventListContainer:SetTitle("Event List")
    -- local scrollFrame = AceGUI:Create("ScrollFrame")
    -- scrollFrame:SetLayout("Flow")
    -- scrollFrame:SetFullWidth(true)
    -- scrollFrame:SetFullHeight(true)
    -- self.eventListContainer = scrollFrame
    -- eventListContainer:AddChild(scrollFrame)
    -- return eventListContainer
end

function Chronicles.UI.EventList:CreateEventDetailsContainer()
    -- local eventDetailsContainer = AceGUI:Create("InlineGroup")
    -- self.eventDetailsContainer = eventDetailsContainer
    -- eventDetailsContainer:SetRelativeWidth(0.75)
    -- eventDetailsContainer:SetAutoAdjustHeight(false)
    -- eventDetailsContainer:SetHeight(425)
    -- eventDetailsContainer:SetLayout("Flow")
    -- eventDetailsContainer:SetTitle("Event Details")
    -- local scrollFrame = AceGUI:Create("ScrollFrame")
    -- scrollFrame:SetLayout("Flow")
    -- scrollFrame:SetFullWidth(true)
    -- scrollFrame:SetFullHeight(true)
    -- self.eventDetailsContainer = scrollFrame
    -- eventDetailsContainer:AddChild(scrollFrame)
    -- return eventDetailsContainer
end

function Chronicles.UI.EventList:AddEvent(label, yearStart, yearEnd, container)
    -- local InlineGroup = AceGUI:Create("InlineGroup")
    -- InlineGroup:SetLayout("Flow")
    -- local InteractiveLabel = AceGUI:Create("InteractiveLabel")
    -- InteractiveLabel:SetText(label)
    -- InteractiveLabel:SetWidth(200)
    -- InlineGroup:AddChild(InteractiveLabel)
    -- local LabelStart = AceGUI:Create("Label")
    -- LabelStart:SetText(yearStart)
    -- LabelStart:SetWidth(200)
    -- InlineGroup:AddChild(LabelStart)
    -- local LabelEnd = AceGUI:Create("Label")
    -- LabelEnd:SetText(yearEnd)
    -- LabelEnd:SetWidth(200)
    -- InlineGroup:AddChild(LabelEnd)
    -- container:AddChild(InlineGroup)
end

-- Chronicles.SelectedValues.yearStart,
-- Chronicles.SelectedValues.yearEnd,
-- Chronicles.SelectedValues.timelineStep









------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------



