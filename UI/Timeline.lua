local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.MaxStepIndex = 3

Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 5, 1}
Chronicles.UI.Timeline.CurrentStepValue = nil
Chronicles.UI.Timeline.TimeFrames = {}
Chronicles.UI.Timeline.CurrentPage = nil
Chronicles.UI.Timeline.SelectedYear = nil

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.Timeline:Init()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Init timeline ")
    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[1])
    Chronicles.UI.Timeline:DisplayTimeline(1, true)
end

function Chronicles.UI.Timeline:Refresh()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Refresh timeline " .. Chronicles.UI.Timeline.CurrentPage)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage, true)
end

-- pageIndex goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(pageIndex, force)
    DisplayTimeline(pageIndex, force)
end

function DisplayTimeline(pageIndex, force)
    --DEFAULT_CHAT_FRAME:AddMessage("-- DisplayTimeline " .. pageIndex)

    if (pageIndex ~= nil) then
        --DEFAULT_CHAT_FRAME:AddMessage("-- DisplayTimeline " .. pageIndex)
        Chronicles.UI.Timeline.TimeFrames = GetDisplayableTimeFrames()

        local numberOfCells = tablelength(Chronicles.UI.Timeline.TimeFrames)

        if (numberOfCells == 0) then
            TimelineScrollBar:SetMinMaxValues(1, 1)
            ChangeCurrentPage(1)
            TimelinePreviousButton:Disable()
            TimelineNextButton:Disable()
            HideAllTimelineBlocks()
            return
        end

        local pageSize = Chronicles.constants.config.timeline.pageSize
        local maxPageValue = math.ceil(numberOfCells / pageSize)

        if (pageIndex < 1) then
            pageIndex = 1
        end
        if (pageIndex > maxPageValue) then
            pageIndex = maxPageValue
        end

        if (Chronicles.UI.Timeline.CurrentPage ~= pageIndex or force) then
            TimelineScrollBar:SetMinMaxValues(1, maxPageValue)
            ChangeCurrentPage(pageIndex)

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
end

function GetDisplayableTimeFrames()
    local displayableTimeFrames = {}
    local stepValue = Chronicles.UI.Timeline.CurrentStepValue

    local numberOfCells = GetNumberOfTimelineBlock(stepValue)
    --DEFAULT_CHAT_FRAME:AddMessage("-- Number of cells " .. numberOfCells)

    local dateSteps = {}
    for i = 1, numberOfCells do
        local lowerBoundValue = GetLowerBound(i, stepValue)
        local upperBoundValue = GetUpperBound(i, stepValue)

        dateSteps[i] = {
            lowerBound = lowerBoundValue,
            upperBound = upperBoundValue
        }
    end

    for j = 1, numberOfCells - 1 do
        local block = dateSteps[j]
        local nextBlock = dateSteps[j + 1]

        local hasEvents = Chronicles.DB:HasEvents(block.lowerBound, block.upperBound)
        local nextHasEvents = Chronicles.DB:HasEvents(nextBlock.lowerBound, nextBlock.upperBound)

        if (hasEvents == true or (hasEvents == false and nextHasEvents == true)) then
            table.insert(
                displayableTimeFrames,
                {
                    lowerBound = block.lowerBound,
                    upperBound = block.upperBound,
                    hasEvents = hasEvents
                }
            )
        end

        if (hasEvents == false and nextHasEvents == false) then
            nextBlock.lowerBound = block.lowerBound
        end
    end

    local last = dateSteps[numberOfCells]
    local lastHasEvents = Chronicles.DB:HasEvents(last.lowerBound, last.upperBound)
    if (lastHasEvents == true) then
        table.insert(
            displayableTimeFrames,
            {
                lowerBound = last.lowerBound,
                upperBound = last.upperBound,
                hasEvents = true
            }
        )
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- displayable timeframes " .. tostring(tablelength(displayableTimeFrames)))

    if (tablelength(displayableTimeFrames) > 0) then
        local first = displayableTimeFrames[1]
        local firstHasEvents = Chronicles.DB:HasEvents(first.lowerBound, first.upperBound)
        if (firstHasEvents == false) then
            table.remove(displayableTimeFrames, 1)
        end
    else
        return
    end

    return displayableTimeFrames
end

function ChangeCurrentStepValue(stepValue)
    Chronicles.UI.Timeline.CurrentStepValue = stepValue
end

function ChangeCurrentPage(currentPageIndex)
    Chronicles.UI.Timeline.CurrentPage = currentPageIndex
end

function GetNumberOfTimelineBlock(stepValue)
    local length =
        math.abs(Chronicles.constants.config.timeline.yearStart - Chronicles.constants.config.timeline.yearEnd)
    return math.ceil(length / stepValue)
end

function GetLowerBound(blockIndex, stepValue)
    local value = Chronicles.constants.config.timeline.yearStart + ((blockIndex - 1) * stepValue)

    if (value < Chronicles.constants.config.timeline.yearStart) then
        return Chronicles.constants.config.timeline.yearStart
    end
    return value
end

function GetUpperBound(blockIndex, stepValue)
    local value = Chronicles.constants.config.timeline.yearStart + (blockIndex * stepValue) - 1
    if (value > Chronicles.constants.config.timeline.yearEnd) then
        return Chronicles.constants.config.timeline.yearEnd
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

function HideAllTimelineBlocks()
    TimelineBlock1:Hide()
    TimelineBlockNoEvent1:Hide()
    TimelineBlock2:Hide()
    TimelineBlockNoEvent2:Hide()
    TimelineBlock3:Hide()
    TimelineBlockNoEvent3:Hide()
    TimelineBlock4:Hide()
    TimelineBlockNoEvent4:Hide()
    TimelineBlock5:Hide()
    TimelineBlockNoEvent5:Hide()
    TimelineBlock6:Hide()
    TimelineBlockNoEvent6:Hide()
    TimelineBlock7:Hide()
    TimelineBlockNoEvent7:Hide()
    TimelineBlock8:Hide()
    TimelineBlockNoEvent8:Hide()
end

function SetDateToBlock(index, frameEvent, frameNoEvent)
    local isUp = true
    if ((index % 2) == 0) then
        isUp = false
    end
    local dateBlock = Chronicles.UI.Timeline.TimeFrames[index]

    if (dateBlock == nil) then
        frameNoEvent:Hide()
        frameEvent:Hide()

        return
    end

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
        local pageSize = Chronicles.constants.config.timeline.pageSize
        local numberOfCells = GetNumberOfTimelineBlock(Chronicles.UI.Timeline.CurrentStepValue)

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

        local lowerBoundYear = GetLowerBound(firstIndex, Chronicles.UI.Timeline.CurrentStepValue)
        local upperBoundYear = GetUpperBound(firstIndex + 7, Chronicles.UI.Timeline.CurrentStepValue)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- lowerBoundYear " .. lowerBoundYear)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- upperBoundYear " .. upperBoundYear)

        selectedYear = (lowerBoundYear + upperBoundYear) / 2
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear " .. selectedYear)

    local length = math.abs(Chronicles.constants.config.timeline.yearStart - selectedYear)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- length " .. length)

    local yearIndex = math.floor(length / Chronicles.UI.Timeline.CurrentStepValue)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- yearIndex " .. yearIndex)

    local result = yearIndex - (yearIndex % Chronicles.constants.config.timeline.pageSize)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- result " .. result)

    return result
end

function Timeline_ZoomIn()
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomIn ")
    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex + 1])

    Chronicles.UI.Timeline:DisplayTimeline(FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear), true)
end

function Timeline_ZoomOut()
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == 1) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomOut ")

    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex - 1])

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
