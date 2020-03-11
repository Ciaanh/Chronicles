local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.MaxStepIndex = 3
Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 5, 1}
Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[1]
Chronicles.UI.Timeline.StepDates = {}
Chronicles.UI.Timeline.CurrentPage = nil
Chronicles.UI.Timeline.SelectedYear = nil

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

-- pageIndex goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(pageIndex, force)
    Chronicles.UI.Timeline:LoadSetDates()

    local numberOfCells = tablelength(Chronicles.UI.Timeline.StepDates)

    local pageSize = Chronicles.constants.timeline.pageSize
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    if (pageIndex < 1) then
        pageIndex = 1
    end
    if (pageIndex > maxPageValue) then
        pageIndex = maxPageValue
    end

    if (Chronicles.UI.Timeline.CurrentPage ~= pageIndex or force) then
        TimelineScrollBar:SetMinMaxValues(1, maxPageValue)
        Chronicles.UI.Timeline.CurrentPage = pageIndex

        if (numberOfCells <= pageSize) then
            TimelinePreviousButton:Disable()
            TimelineNextButton:Disable()
        else
            TimelinePreviousButton:Enable()
            TimelineNextButton:Enable()
        end

        TimelineScrollBar:SetValue(Chronicles.UI.Timeline.CurrentPage)

        BuildTimelineBlocks(pageIndex, pageSize, numberOfCells, maxPageValue)
    end
end

function GetNumberOfTimelineBlock()
    local length = math.abs(Chronicles.constants.timeline.yearStart - Chronicles.constants.timeline.yearEnd)
    return math.ceil(length / Chronicles.UI.Timeline.CurrentStep)
end

function GetLowerBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + ((blockIndex - 1) * Chronicles.UI.Timeline.CurrentStep)

    if (value < Chronicles.constants.timeline.yearStart) then
        return Chronicles.constants.timeline.yearStart
    end
    return value
end

function GetUpperBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + (blockIndex * Chronicles.UI.Timeline.CurrentStep) - 1
    if (value > Chronicles.constants.timeline.yearEnd) then
        return Chronicles.constants.timeline.yearEnd
    end
    return value
end

function BuildTimelineBlocks(page, pageSize, numberOfCells, maxPageValue)
    local firstIndex = 1 + ((page - 1) * pageSize)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex)

    if (firstIndex <= 1) then
        firstIndex = 1
        TimelinePreviousButton:Disable()
        Chronicles.UI.Timeline.CurrentPage = 1
    end

    if ((firstIndex + 7) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        TimelineNextButton:Disable()
        Chronicles.UI.Timeline.CurrentPage = maxPageValue
    end

    LoadTimelineDatesToBlock(firstIndex)
end

function LoadTimelineDatesToBlock(firstIndex)
    SetDateToBlock(firstIndex, TimelineBlock1, TimelineBlockNoEvent1)
    SetDateToBlock(firstIndex + 1, TimelineBlock2, TimelineBlockNoEvent2)
    SetDateToBlock(firstIndex + 2, TimelineBlock3, TimelineBlockNoEvent3)
    SetDateToBlock(firstIndex + 3, TimelineBlock4, TimelineBlockNoEvent4)
    SetDateToBlock(firstIndex + 4, TimelineBlock5, TimelineBlockNoEvent5)
    SetDateToBlock(firstIndex + 5, TimelineBlock6, TimelineBlockNoEvent6)
    SetDateToBlock(firstIndex + 6, TimelineBlock7, TimelineBlockNoEvent7)
    SetDateToBlock(firstIndex + 7, TimelineBlock8, TimelineBlockNoEvent8)
end

function SetDateToBlock(index, frameEvent, frameNoEvent)
    local isUp = true
    if ((index % 2) == 0) then
        isUp = false
    end
    local dateBlock = Chronicles.UI.Timeline.StepDates[index]

    if (dateBlock.hasEvents) then
        frameNoEvent:Hide()
        frameEvent:Show()

        frameEvent.lowerBound = dateBlock.lowerBound
        frameEvent.upperBound = dateBlock.upperBound
        frameEvent.LabelStart:SetText("" .. dateBlock.lowerBound)
        frameEvent.LabelEnd:SetText("" .. dateBlock.upperBound)
        frameNoEvent.LabelStart:SetText("")
        frameNoEvent.LabelEnd:SetText("")

        frameEvent:SetScript(
            "OnMouseDown",
            function()
                local eventList = Chronicles.DB:SearchEvents(frameEvent.lowerBound, frameEvent.upperBound)
                Chronicles.UI.Timeline.SelectedYear = math.floor((frameEvent.lowerBound + frameEvent.upperBound) / 2)
                Chronicles.UI.EventList:SetEventListData(frameEvent.lowerBound, frameEvent.upperBound, eventList)
            end
        )
    else
        frameNoEvent:Show()
        frameEvent:Hide()

        frameEvent.lowerBound = nil
        frameEvent.upperBound = nil
        frameEvent.LabelStart:SetText("")
        frameEvent.LabelEnd:SetText("")
        frameNoEvent.LabelStart:SetText("" .. dateBlock.lowerBound)
        frameNoEvent.LabelEnd:SetText("" .. dateBlock.upperBound)

        frameEvent:SetScript(
            "OnMouseDown",
            function()
                Chronicles.UI.EventList:SetEventListData(0, 0, {})
            end
        )
    end

    if (isUp) then
        SetTimelineBlockUp(frameEvent)
        SetTimelineBlockUp(frameNoEvent)
    else
        SetTimelineBlockDown(frameEvent)
        SetTimelineBlockDown(frameNoEvent)
    end
end

function SetTimelineBlockUp(frame)
    -- frame.BoxAnchor
    frame.BoxAnchor:ClearAllPoints()
    frame.BoxAnchor:SetPoint("CENTER", -20, 1)
    frame.BoxAnchor:SetTexCoord(0, 1, 1, 0)

    -- frame.BoxLeft
    frame.BoxLeft:ClearAllPoints()
    frame.BoxLeft:SetPoint("LEFT", -5, 28)

    -- frame.BoxCenter
    frame.BoxCenter:ClearAllPoints()
    frame.BoxCenter:SetPoint("CENTER", 0, 28)

    -- frame.BoxRight
    frame.BoxRight:ClearAllPoints()
    frame.BoxRight:SetPoint("RIGHT", 5, 28)

    -- frame.LabelStart
    frame.LabelStart:ClearAllPoints()
    frame.LabelStart:SetPoint("LEFT", 8, 24)

    -- frame.LabelEnd
    frame.LabelEnd:ClearAllPoints()
    frame.LabelEnd:SetPoint("RIGHT", -8, 32)
end

function SetTimelineBlockDown(frame)
    -- frame.BoxAnchor
    frame.BoxAnchor:ClearAllPoints()
    frame.BoxAnchor:SetPoint("CENTER", -20, -1)
    frame.BoxAnchor:SetTexCoord(0, 1, 0, 1)

    -- frame.BoxLeft
    frame.BoxLeft:ClearAllPoints()
    frame.BoxLeft:SetPoint("LEFT", -5, -28)

    -- frame.BoxCenter
    frame.BoxCenter:ClearAllPoints()
    frame.BoxCenter:SetPoint("CENTER", 0, -28)

    -- frame.BoxRight
    frame.BoxRight:ClearAllPoints()
    frame.BoxRight:SetPoint("RIGHT", 5, -28)

    -- frame.LabelStart
    frame.LabelStart:ClearAllPoints()
    frame.LabelStart:SetPoint("LEFT", 8, -24)

    -- frame.LabelEnd
    frame.LabelEnd:ClearAllPoints()
    frame.LabelEnd:SetPoint("RIGHT", -8, -32)
end

------------------------------------------------------------------------------------------
-- Zoom ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.Timeline:LoadSetDates()
    Chronicles.UI.Timeline.StepDates = {}

    local numberOfCells = GetNumberOfTimelineBlock()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Number of cells " .. numberOfCells)

    local dateArray = {}
    for i = 1, numberOfCells do
        local lowerBoundValue = GetLowerBound(i)
        local upperBoundValue = GetUpperBound(i)
        local hasEvents = Chronicles.DB:HasEvents(lowerBoundValue, upperBoundValue)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- index " .. i .. " bounds " .. lowerBoundValue .. " " .. upperBoundValue)
        dateArray[i] = {
            lowerBound = lowerBoundValue,
            upperBound = upperBoundValue,
            hasEvents = hasEvents
        }
    end

    Chronicles.UI.Timeline.StepDates = {}
    for j = 1, numberOfCells - 1 do
        if (dateArray[j].hasEvents == true or (dateArray[j].hasEvents == false and dateArray[j + 1].hasEvents == true)) then
            table.insert(Chronicles.UI.Timeline.StepDates, dateArray[j])
        end
        if (dateArray[j].hasEvents == false and dateArray[j + 1].hasEvents == false) then
            dateArray[j + 1].lowerBound = dateArray[j].lowerBound
        end
    end
    if (dateArray[numberOfCells].hasEvents == true) then
        table.insert(Chronicles.UI.Timeline.StepDates, dateArray[j])
    end

    if (Chronicles.UI.Timeline.StepDates[1].hasEvents == false) then
        table.remove(Chronicles.UI.Timeline.StepDates, 1)
    end
end

function GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(Chronicles.UI.Timeline.StepValues) do
        index[v] = k
    end
    return index[stepValue]
end

function FindYearIndexOnTimeline(year)
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Chronicles.UI.Timeline.CurrentPage
        local pageSize = Chronicles.constants.timeline.pageSize
        local numberOfCells = GetNumberOfTimelineBlock()

        if (page == nil) then
            page = 1
        end

        -- DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear nil " .. page)

        local firstIndex = 1 + ((page - 1) * pageSize)

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if ((firstIndex + 7) >= numberOfCells) then
            firstIndex = numberOfCells - 7
        end

        local lowerBoundYear = GetLowerBound(firstIndex)
        local upperBoundYear = GetUpperBound(firstIndex + 7)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- lowerBoundYear " .. lowerBoundYear)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- upperBoundYear " .. upperBoundYear)

        selectedYear = (lowerBoundYear + upperBoundYear) / 2
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear " .. selectedYear)

    local length = math.abs(Chronicles.constants.timeline.yearStart - selectedYear)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- length " .. length)

    local yearIndex = math.floor(length / Chronicles.UI.Timeline.CurrentStep)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- yearIndex " .. yearIndex)

    local result = yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- result " .. result)

    return result
end

function Timeline_ZoomIn()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep
    local curentStepIndex = GetStepValueIndex(currentStepValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomIn ")

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex + 1]

    Chronicles.UI.Timeline:DisplayTimeline(FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear), true)
end

function Timeline_ZoomOut()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep
    local curentStepIndex = GetStepValueIndex(currentStepValue)

    if (curentStepIndex == 1) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomOut ")

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex - 1]

    Chronicles.UI.Timeline:DisplayTimeline(FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear), true)
end

------------------------------------------------------------------------------------------
-- Scroll Page ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------
function TimelineScrollFrame_OnMouseWheel(self, value)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- TimelineScrollFrame_OnMouseWheel " .. value)
    if (value > 0) then
        TimelineScrollPreviousButton_OnClick(self)
    else
        TimelineScrollNextButton_OnClick(self)
    end
end

function TimelineScrollPreviousButton_OnClick(self)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage - 1, false)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function TimelineScrollNextButton_OnClick(self)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage + 1, false)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
