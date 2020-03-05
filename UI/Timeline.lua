local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.MaxStepIndex = 3
Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 5, 1}
Chronicles.UI.Timeline.CurrentStep = Chronicles.UI.Timeline.StepValues[1]
Chronicles.UI.Timeline.CurrentPage = nil
Chronicles.UI.Timeline.SelectedYear = nil

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

-- page goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(page, force)
    -- create table with all date steps and check if events exist for it
    local numberOfCells = self:GetNumberOfTimelineBlock()
    local dates = {}
    for i = 1, numberOfCells do
        lowerBoundValue = self:GetLowerBound(i)
        upperBoundValue = self:GetUpperBound(i)

        dates[i] = {
            lowerBound = lowerBoundValue,
            upperBound = upperBoundValue,
            hasEvents = Chronicles.DB:HasEvents(lowerBoundValue, upperBoundValue)
        }
    end

    local pageSize = Chronicles.constants.timeline.pageSize

    local maxPageValue = math.ceil(numberOfCells / pageSize)

    if (page < 1) then
        page = 1
    end
    if (page > maxPageValue) then
        page = maxPageValue
    end

    if (self.CurrentPage ~= page or force) then
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

        local firstIndex = Chronicles.UI.Timeline:ComputeFirstIndex(page, pageSize, numberOfCells, maxPageValue)

        TimelineScrollBar:SetValue(self.CurrentPage)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndexAfterChecked " .. firstIndex)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Page and Index " .. self.CurrentPage .. "  " .. firstIndex)

        Chronicles.UI.Timeline:Build(firstIndex, dates)
    end
end

function Chronicles.UI.Timeline:ComputeFirstIndex(page, pageSize, numberOfCells, maxPageValue)
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
    return firstIndex
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

function Chronicles.UI.Timeline:SetThemeGold(frame)
    frame.BoxLeft:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Gold")
    frame.BoxCenter:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Gold")
    frame.BoxRight:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Gold")
    frame.BoxAnchor:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Anchor-Gold")
    frame.Label:SetTextColor(1, 0.82, 0, 1)
end

function Chronicles.UI.Timeline:SetThemeGrey(frame)
    frame.BoxLeft:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Grey")
    frame.BoxCenter:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Grey")
    frame.BoxRight:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Label-Grey")
    frame.BoxAnchor:SetTexture("Interface\\AddOns\\Chronicles\\Images\\Timeline-Anchor-Grey")
    frame.Label:SetTextColor(0.18, 0.18, 0.18, 1)
end

function Chronicles.UI.Timeline:Build(firstIndex, dates)
    -- TimelineBlock1
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex], TimelineBlock1, 1)

    -- TimelineBlock2
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 1], TimelineBlock2, 2)

    -- TimelineBlock3
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 2], TimelineBlock3, 3)

    -- TimelineBlock4
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 3], TimelineBlock4, 4)

    -- TimelineBlock5
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 4], TimelineBlock5, 5)

    -- TimelineBlock6
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 5], TimelineBlock6, 6)

    -- TimelineBlock7
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 6], TimelineBlock7, 7)

    -- TimelineBlock8
    Chronicles.UI.Timeline:SetTextToFrameFromDate(dates[firstIndex + 7], TimelineBlock8, 8)
end

function Chronicles.UI.Timeline:SetTextToFrameFromDate(dateBlock, frame, position)
    frame.lowerBound = dateBlock.lowerBound
    frame.upperBound = dateBlock.upperBound

    if dateBlock.hasEvents then
        Chronicles.UI.Timeline:SetThemeGold(frame)
    else
        Chronicles.UI.Timeline:SetThemeGrey(frame)
    end

    local label = frame.Label
    label:SetText("" .. dateBlock.lowerBound)

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
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Chronicles.UI.Timeline.CurrentPage
        local pageSize = Chronicles.constants.timeline.pageSize
        local numberOfCells = self:GetNumberOfTimelineBlock()

        if (page == nil) then
            page = 1
        end

        DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear nil " .. page)

        local firstIndex = 1 + ((page - 1) * pageSize)

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if ((firstIndex + 7) >= numberOfCells) then
            firstIndex = numberOfCells - 7
        end

        local lowerBoundYear = self:GetLowerBound(firstIndex)
        local upperBoundYear = self:GetUpperBound(firstIndex + 7)

        DEFAULT_CHAT_FRAME:AddMessage("-- lowerBoundYear " .. lowerBoundYear)
        DEFAULT_CHAT_FRAME:AddMessage("-- upperBoundYear " .. upperBoundYear)

        selectedYear = (lowerBoundYear + upperBoundYear) / 2
    end

    DEFAULT_CHAT_FRAME:AddMessage("-- selectedYear " .. selectedYear)

    local length = math.abs(Chronicles.constants.timeline.yearStart - selectedYear)
    DEFAULT_CHAT_FRAME:AddMessage("-- length " .. length)

    local yearIndex = math.floor(length / self.CurrentStep)
    DEFAULT_CHAT_FRAME:AddMessage("-- yearIndex " .. yearIndex)

    local result = yearIndex - (yearIndex % Chronicles.constants.timeline.pageSize)
    DEFAULT_CHAT_FRAME:AddMessage("-- result " .. result)

    return result
end

function Timeline_ZoomIn()
    local currentStepValue = Chronicles.UI.Timeline.CurrentStep
    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(currentStepValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("-- ZoomIn ")

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

    DEFAULT_CHAT_FRAME:AddMessage("-- ZoomOut ")

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
