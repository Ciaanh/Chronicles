local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.MaxStepIndex = 3
Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 5, 1}
Chronicles.UI.Timeline.CurrentStep = Chronicles.constants.timeline.defaultStep
Chronicles.UI.Timeline.CurrentPage = nil
Chronicles.UI.Timeline.SelectedYear = Chronicles.constants.timeline.yearStart

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- page goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(page)
    local pageSize = Chronicles.constants.timeline.pageSize
    local numberOfCells = self:GetNumberOfTimelineBlock(self.CurrentStep)
    local maxPageValue = math.ceil(numberOfCells / pageSize)

    if (page < 1) then
        page = 1
    end
    if (page > maxPageValue) then
        page = maxPageValue
    end

    if (self.CurrentPage ~= page) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Asked page " .. page)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- SetMinMaxValues " .. numberOfCells .. "  " .. pageSize .. "  " .. maxPageValue)

        TimelineScrollBar:SetMinMaxValues(1, maxPageValue)
        self.CurrentPage = page

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
            self.CurrentPage = 1
        end

        if ((firstIndex + 7) >= numberOfCells) then
            firstIndex = numberOfCells - 7
            TimelineNextButton:Disable()
            self.CurrentPage = maxPageValue
        end

        TimelineScrollBar:SetValue(self.CurrentPage)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndexAfterChecked " .. firstIndex)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Page and Index " .. self.CurrentPage .. "  " .. firstIndex)

        -- TimelineBlock1
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex, TimelineBlock1, 1)

        -- TimelineBlock2
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 1, TimelineBlock2, 2)

        -- TimelineBlock3
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 2, TimelineBlock3, 3)

        -- TimelineBlock4
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 3, TimelineBlock4, 4)

        -- TimelineBlock5
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 4, TimelineBlock5, 5)

        -- TimelineBlock6
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 5, TimelineBlock6, 6)

        -- TimelineBlock7
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 6, TimelineBlock7, 7)

        -- TimelineBlock8
        Chronicles.UI.Timeline:SetTextToFrame(firstIndex + 7, TimelineBlock8, 8)
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

function Chronicles.UI.Timeline:SetTextToFrame(blockIndex, frame, position)
    local lowerBoundBlock = self:GetLowerBound(blockIndex)
    local upperBoundBlock = self:GetUpperBound(blockIndex)

    local text = "" .. lowerBoundBlock
    frame.lowerBound = lowerBoundBlock
    frame.upperBound = upperBoundBlock

    -- local label = _G[frame:GetName() .. "Text"]
    local label = frame.Label
    label:SetText(text)

    frame:SetScript(
        "OnMouseDown",
        function()
            local eventList = Chronicles.DB:SearchEvents(frame.lowerBound, frame.upperBound)
            self.SelectedYear = math.floor((frame.lowerBound + frame.upperBound) / 2)
            Chronicles.UI.EventList:SetEventListData(frame.lowerBound, frame.upperBound, eventList)
        end
    )
end

------------------------------------------------------------------------------------------
-- Zoom ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.Timeline:GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(self.StepValues) do
        index[v] = k
    end
    return index[stepValue]
end

function Chronicles.UI.Timeline:FindYearIndexOnTimeline(year)
    -- if (year ~= nil) then
        local length = math.abs(Chronicles.constants.timeline.yearStart - year)
        local yearIndex = math.floor(length / self.CurrentStep)

        return yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
    -- else
    --     local numberOfCells = self:GetNumberOfTimelineBlock(self.CurrentStep)

    --     local firstIndex = 1 + ((page - 1) * pageSize)
    --     if (firstIndex <= 1) then
    --         firstIndex = 1
    --     end
    --     if ((firstIndex + 7) >= numberOfCells) then
    --         firstIndex = numberOfCells - 7
    --     end

    --     local lowerBoundYear = self:GetLowerBound(firstIndex)
    --     local upperBoundYear = self:GetUpperBound(firstIndex + 7)

    --     year = (lowerBoundYear + upperBoundYear) / 2

    --     local length = math.abs(Chronicles.constants.timeline.yearStart - year)
    --     local yearIndex = math.floor(length / self.CurrentStep)

    --     return yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
    -- end
end

function Timeline_ZoomIn()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep

    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(currentStepValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex + 1]

    Chronicles.UI.Timeline:DisplayTimeline(
        Chronicles.UI.Timeline:FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear)
    )
end

function Timeline_ZoomOut()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep

    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(currentStepValue)

    if (curentStepIndex == 1) then
        return
    end

    Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[curentStepIndex - 1]

    Chronicles.UI.Timeline:DisplayTimeline(
        Chronicles.UI.Timeline:FindYearIndexOnTimeline(Chronicles.UI.Timeline.SelectedYear)
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
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage - 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function TimelineScrollNextButton_OnClick(self)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage + 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
