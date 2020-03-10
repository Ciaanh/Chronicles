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

    if (self.CurrentPage ~= pageIndex or force) then
        TimelineScrollBar:SetMinMaxValues(1, maxPageValue)
        self.CurrentPage = pageIndex

        if (numberOfCells <= pageSize) then
            TimelinePreviousButton:Disable()
            TimelineNextButton:Disable()
        else
            TimelinePreviousButton:Enable()
            TimelineNextButton:Enable()
        end

        TimelineScrollBar:SetValue(self.CurrentPage)

        Chronicles.UI.Timeline:BuildTimelineBlocks(pageIndex, pageSize, numberOfCells, maxPageValue)
    end
end

function Chronicles.UI.Timeline:GetNumberOfTimelineBlock()
    local length = math.abs(Chronicles.constants.timeline.yearStart - Chronicles.constants.timeline.yearEnd)
    return math.ceil(length / self.CurrentStep)
end

function Chronicles.UI.Timeline:GetLowerBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + ((blockIndex - 1) * self.CurrentStep)

    if (value < Chronicles.constants.timeline.yearStart) then
        return Chronicles.constants.timeline.yearStart
    end
    return value
end

function Chronicles.UI.Timeline:GetUpperBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + (blockIndex * self.CurrentStep) - 1
    if (value > Chronicles.constants.timeline.yearEnd) then
        return Chronicles.constants.timeline.yearEnd
    end
    return value
end

function Chronicles.UI.Timeline:BuildTimelineBlocks(page, pageSize, numberOfCells, maxPageValue)
    local firstIndex = 1 + ((page - 1) * pageSize)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex)

    if (firstIndex <= 1) then
        firstIndex = 1
        TimelinePreviousButton:Disable()
        self.CurrentPage = 1
    end

    if ((firstIndex + 7) >= numberOfCells) then
        firstIndex = numberOfCells - 7
        TimelineNextButton:Disable()
        self.CurrentPage = maxPageValue
    end

    -- TimelineBlock1
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex], 1)

    -- TimelineBlock2
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 1], 2)

    -- TimelineBlock3
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 2], 3)

    -- TimelineBlock4
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 3], 4)

    -- TimelineBlock5
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 4], 5)

    -- TimelineBlock6
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 5], 6)

    -- TimelineBlock7
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 6], 7)

    -- TimelineBlock8
    Chronicles.UI.Timeline:SetTextToFrameFromDate(Chronicles.UI.Timeline.StepDates[firstIndex + 7], 8)
end

function Chronicles.UI.Timeline:SetTextToFrameFromDate(dateBlock, position)
    local frameEvent = nil
    local frameNoEvent = nil

    if (position == 1) then
        frameEvent = TimelineBlock1
        frameNoEvent = TimelineBlockNoEvent1
    end
    if (position == 2) then
        frameEvent = TimelineBlock2
        frameNoEvent = TimelineBlockNoEvent2
    end
    if (position == 3) then
        frameEvent = TimelineBlock3
        frameNoEvent = TimelineBlockNoEvent3
    end
    if (position == 4) then
        frameEvent = TimelineBlock4
        frameNoEvent = TimelineBlockNoEvent4
    end
    if (position == 5) then
        frameEvent = TimelineBlock5
        frameNoEvent = TimelineBlockNoEvent5
    end
    if (position == 6) then
        frameEvent = TimelineBlock6
        frameNoEvent = TimelineBlockNoEvent6
    end
    if (position == 7) then
        frameEvent = TimelineBlock7
        frameNoEvent = TimelineBlockNoEvent7
    end
    if (position == 8) then
        frameEvent = TimelineBlock8
        frameNoEvent = TimelineBlockNoEvent8
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
                self.SelectedYear = math.floor((frameEvent.lowerBound + frameEvent.upperBound) / 2)
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
end

------------------------------------------------------------------------------------------
-- Zoom ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.Timeline:LoadSetDates()
    Chronicles.UI.Timeline.StepDates = {}

    local numberOfCells = self:GetNumberOfTimelineBlock()
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Number of cells " .. numberOfCells)

    local dateArray = {}
    for i = 1, numberOfCells do
        local lowerBoundValue = self:GetLowerBound(i)
        local upperBoundValue = self:GetUpperBound(i)
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

function Chronicles.UI.Timeline:GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(self.StepValues) do
        index[v] = k
    end
    return index[stepValue]
end

function Chronicles.UI.Timeline:FindYearIndexOnTimeline(year)
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Chronicles.UI.Timeline.CurrentPage
        local pageSize = Chronicles.constants.timeline.pageSize
        local numberOfCells = self:GetNumberOfTimelineBlock()

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

        local lowerBoundYear = self:GetLowerBound(firstIndex)
        local upperBoundYear = self:GetUpperBound(firstIndex + 7)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- lowerBoundYear " .. lowerBoundYear)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- upperBoundYear " .. upperBoundYear)

        selectedYear = (lowerBoundYear + upperBoundYear) / 2
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear " .. selectedYear)

    local length = math.abs(Chronicles.constants.timeline.yearStart - selectedYear)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- length " .. length)

    local yearIndex = math.floor(length / self.CurrentStep)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- yearIndex " .. yearIndex)

    local result = yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- result " .. result)

    return result
end

function Timeline_ZoomIn()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep
    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(currentStepValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomIn ")

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex + 1]

    Chronicles.UI.Timeline:DisplayTimeline(
        Chronicles.UI.Timeline:FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear),
        true
    )
end

function Timeline_ZoomOut()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep
    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(currentStepValue)

    if (curentStepIndex == 1) then
        return
    end

    --DEFAULT_CHAT_FRAME:AddMessage("-- ZoomOut ")

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex - 1]

    Chronicles.UI.Timeline:DisplayTimeline(
        Chronicles.UI.Timeline:FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear),
        true
    )
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
