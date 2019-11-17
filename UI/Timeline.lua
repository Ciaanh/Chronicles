local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 5, 1}

Chronicles.UI.Timeline.MaxStepIndex = 3

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- page goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(page)
    local pageSize = Chronicles.constants.timeline.pageSize
    local numberOfCells = GetNumberOfTimelineBlock(Chronicles.SelectedValues.timelineStep)
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    if (page < 1) then
        page = 1
    end
    if (page > maxPageValue) then
        page = maxPageValue
    end

    if (Chronicles.SelectedValues.currentTimelinePage ~= page) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Asked page " .. page)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- SetMinMaxValues " .. numberOfCells .. "  " .. pageSize .. "  " .. maxPageValue)

        TimelineScrollBar:SetMinMaxValues(1, maxPageValue)
        Chronicles.SelectedValues.currentTimelinePage = page

        if (numberOfCells <= pageSize) then
            TimelinePreviousButton:Disable()
            TimelineNextButton:Disable()
        else
            TimelinePreviousButton:Enable()
            TimelineNextButton:Enable()
        end

        local firstIndex = 1 + ((page - 1) * pageSize)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex)

        if (firstIndex <= 1) then
            firstIndex = 1
            TimelinePreviousButton:Disable()
            Chronicles.SelectedValues.currentTimelinePage = 1
        end

        if ((firstIndex + 7) >= numberOfCells) then
            firstIndex = numberOfCells - 7
            TimelineNextButton:Disable()
            Chronicles.SelectedValues.currentTimelinePage = maxPageValue
        end

        TimelineScrollBar:SetValue(Chronicles.SelectedValues.currentTimelinePage)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndexAfterChecked " .. firstIndex)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Page and Index " .. Chronicles.SelectedValues.currentTimelinePage .. "  " .. firstIndex)

        -- TimelineBlock1
        SetTextToFrame(firstIndex, TimelineBlock1)

        -- TimelineBlock2
        SetTextToFrame(firstIndex + 1, TimelineBlock2)

        -- TimelineBlock3
        SetTextToFrame(firstIndex + 2, TimelineBlock3)

        -- TimelineBlock4
        SetTextToFrame(firstIndex + 3, TimelineBlock4)

        -- TimelineBlock5
        SetTextToFrame(firstIndex + 4, TimelineBlock5)

        -- TimelineBlock6
        SetTextToFrame(firstIndex + 5, TimelineBlock6)

        -- TimelineBlock7
        SetTextToFrame(firstIndex + 6, TimelineBlock7)

        -- TimelineBlock8
        SetTextToFrame(firstIndex + 7, TimelineBlock8)
    end
end

function GetNumberOfTimelineBlock()
    local length = math.abs(Chronicles.constants.timeline.yearStart - Chronicles.constants.timeline.yearEnd)
    return math.ceil(length / Chronicles.SelectedValues.timelineStep)
end

function GetLowerBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + ((blockIndex - 1) * Chronicles.SelectedValues.timelineStep)

    if (value < Chronicles.constants.timeline.yearStart) then
        return Chronicles.constants.timeline.yearStart
    end
    return value
end

function GetUpperBound(blockIndex)
    local value = Chronicles.constants.timeline.yearStart + (blockIndex * Chronicles.SelectedValues.timelineStep) - 1
    if (value > Chronicles.constants.timeline.yearEnd) then
        return Chronicles.constants.timeline.yearEnd
    end
    return value
end

function SetTextToFrame(blockIndex, frame)
    local lowerBoundBlock = GetLowerBound(blockIndex)
    local upperBoundBlock = GetUpperBound(blockIndex)

    local text = "" .. lowerBoundBlock .. "\n" .. upperBoundBlock
    frame.lowerBound = lowerBoundBlock
    frame.upperBound = upperBoundBlock

    local label = _G[frame:GetName() .. "Text"]
    label:SetText(text)

    frame:SetScript(
        "OnMouseDown",
        function()
            local eventList = Chronicles:SearchEvents(frame.lowerBound, frame.upperBound)
            Chronicles.SelectedValues.selectedTimelineYear = math.floor((frame.lowerBound + frame.upperBound) / 2)
            Chronicles.UI.EventList:SetEventListData(frame.lowerBound, frame.upperBound, eventList)
        end
    )
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

function Timeline_ZoomIn()
    local currentStepValue = Chronicles.SelectedValues.timelineStep

    local curentStepIndex = GetStepValueIndex(currentStepValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    Chronicles.SelectedValues.timelineStep = Chronicles.UI.Timeline.StepValues[curentStepIndex + 1]

    Chronicles.UI.Timeline:DisplayTimeline(FindYearIndexOnTimeline(Chronicles.SelectedValues.selectedTimelineYear, Chronicles.SelectedValues.timelineStep))
end

function Timeline_ZoomOut()
    local currentStepValue = Chronicles.SelectedValues.timelineStep

    local curentStepIndex = GetStepValueIndex(currentStepValue)

    if (curentStepIndex == 1) then
        return
    end

    Chronicles.SelectedValues.timelineStep = Chronicles.UI.Timeline.StepValues[curentStepIndex - 1]

    Chronicles.UI.Timeline:DisplayTimeline(FindYearIndexOnTimeline(Chronicles.SelectedValues.selectedTimelineYear, Chronicles.SelectedValues.timelineStep))
end

function FindYearIndexOnTimeline(year)
    local length = math.abs(Chronicles.constants.timeline.yearStart - year)
    local yearIndex = math.floor(length / Chronicles.SelectedValues.timelineStep)

    return yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
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
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.SelectedValues.currentTimelinePage - 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function TimelineScrollNextButton_OnClick(self)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.SelectedValues.currentTimelinePage + 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
