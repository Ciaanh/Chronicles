local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

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
    TimelineScrollBar:SetBackdrop(
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            tile = true,
            tileSize = 16,
            insets = {left = 6, right = 6, top = 0, bottom = 17}
        }
    )

    TimelineScrollBar:SetBackdropColor(CreateColor(0.8, 0.65, 0.39))
    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[1])
    Chronicles.UI.Timeline:Refresh()
end

function Chronicles.UI.Timeline:Refresh()
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage, true)
end

function DisplayTimeline(pageIndex, force)
    Chronicles.UI.Timeline:DisplayTimeline(pageIndex, force)
end

-- pageIndex goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(pageIndex, force)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- DisplayTimeline " .. pageIndex)
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

    if (pageIndex == nil) then
        pageIndex = maxPageValue
    end

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

function GetDisplayableTimeFrames()
    local displayableTimeFrames = {}
    local stepValue = Chronicles.UI.Timeline.CurrentStepValue

    local numberOfCells = GetNumberOfTimelineBlock(stepValue)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Number of cells " .. numberOfCells)

    local dateSteps = {}

    for i = 1, numberOfCells do
        local bounds = GetBounds(i, stepValue, numberOfCells)
        dateSteps[i] = {
            lowerBound = bounds.lower,
            upperBound = bounds.upper,
            text = bounds.text
        }
    end

    for j = 1, numberOfCells do
        local block = dateSteps[j]
        local nextBlock = dateSteps[j + 1]

        local hasEvents = Chronicles.DB:HasEvents(block.lowerBound, block.upperBound)
        if (nextBlock ~= nil) then
            local nextHasEvents = Chronicles.DB:HasEvents(nextBlock.lowerBound, nextBlock.upperBound)

            if (hasEvents == true or (hasEvents == false and nextHasEvents == true)) then
                table.insert(
                    displayableTimeFrames,
                    {
                        lowerBound = block.lowerBound,
                        upperBound = block.upperBound,
                        text = block.text,
                        hasEvents = hasEvents
                    }
                )
            end

            if (hasEvents == false and nextHasEvents == false) then
                nextBlock.lowerBound = block.lowerBound
            end
        else
            table.insert(
                displayableTimeFrames,
                {
                    lowerBound = block.lowerBound,
                    upperBound = block.upperBound,
                    text = block.text,
                    hasEvents = hasEvents
                }
            )
        end
    end
    return displayableTimeFrames
end

function ChangeCurrentStepValue(stepValue)
    Chronicles.UI.Timeline.CurrentStepValue = stepValue
end

function ChangeCurrentPage(currentPageIndex)
    Chronicles.UI.Timeline.CurrentPage = currentPageIndex
end

function GetTimelineDetails(stepValue)
    local minYear = Chronicles.DB:MinEventYear()
    local maxYear = Chronicles.DB:MaxEventYear()

    local isOverlapping = false
    local pastEvents = false
    local futurEvents = false
    local before = nil
    local after = nil

    if (minYear < Chronicles.constants.config.historyStartYear) then
        minYear = Chronicles.constants.config.historyStartYear
        pastEvents = true
    end
    if (maxYear > Chronicles.constants.config.currentYear) then
        maxYear = Chronicles.constants.config.currentYear
        futurEvents = true
    end

    if (minYear < 0 and maxYear > 0) then
        isOverlapping = true

        local beforeLength = math.abs(minYear)
        local afterLength = math.abs(maxYear)

        before = math.ceil((beforeLength) / stepValue)
        after = math.ceil((afterLength) / stepValue)
    end

    return {
        isOverlapping = isOverlapping,
        pastEvents = pastEvents,
        futurEvents = futurEvents,
        before = before,
        after = after,
        minYear = minYear,
        maxYear = maxYear
    }
end

function GetNumberOfTimelineBlock(stepValue)
    local details = GetTimelineDetails(stepValue)

    if (details.isOverlapping) then
        local result = details.before + details.after
        if (details.pastEvents == true) then
            result = result + 1
        end
        if (details.futurEvents == true) then
            result = result + 1
        end
        return result
    else
        local length = math.abs(details.minYear - details.maxYear)
        return math.ceil(length / stepValue)
    end
end

function GetBounds(blockIndex, stepValue, numberOfCells)
    local details = GetTimelineDetails(stepValue)

    local minValue = 0
    local maxValue = 0

    if (details.isOverlapping) then
        -- DEFAULT_CHAT_FRAME:AddMessage("-- is overlaping ")
        local before = details.before
        local after = details.after

        if (details.pastEvents == true) then
            -- DEFAULT_CHAT_FRAME:AddMessage("-- past events ")
            before = before + 1
        end

        if (details.futurEvents == true) then
            after = after + 1
        end

        if (blockIndex <= before) then
            minValue = -((before - blockIndex + 1) * stepValue)
            maxValue = -((before - blockIndex) * stepValue) - 1
        else
            minValue = ((blockIndex - before - 1) * stepValue)
            maxValue = ((blockIndex - before) * stepValue) - 1
        end
    else
        if (details.pastEvents == true and blockIndex == 1) then
            minValue = details.minYear - 2
            maxValue = details.minYear - 1

            -- DEFAULT_CHAT_FRAME:AddMessage("-- pastEvents " .. blockIndex .. " " .. maxValue .. " " .. minValue)
        elseif (details.futurEvents == true and blockIndex == numberOfCells) then
            minValue = details.maxYear + 1
            maxValue = details.maxYear + 2

            -- DEFAULT_CHAT_FRAME:AddMessage("-- futurEvents " .. blockIndex .. " " .. maxValue .. " " .. minValue)
        else
            minValue = details.minYear + ((blockIndex - 1) * stepValue) + 1
            maxValue = details.minYear + (blockIndex * stepValue)
        end
    end

    if (maxValue > Chronicles.constants.config.currentYear) then
        if (minValue > Chronicles.constants.config.currentYear) then
            return {
                lower = Chronicles.constants.config.currentYear + 1,
                upper = 999999,
                text = Locale["Futur"]
            }
        else
            maxValue = Chronicles.constants.config.currentYear
        end
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- past events " .. maxValue .. " " .. minValue)
    if (maxValue < Chronicles.constants.config.historyStartYear) then
        if (minValue < Chronicles.constants.config.historyStartYear) then
            return {
                lower = -999999,
                upper = Chronicles.constants.config.historyStartYear - 1,
                text = Locale["Mythos"]
            }
        else
            maxValue = Chronicles.constants.config.historyStartYear
        end
    end

    return {
        lower = minValue,
        upper = maxValue,
        text = nil
    }
end

function GetIndex(year)
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Chronicles.UI.Timeline.CurrentPage
        local pageSize = Chronicles.constants.config.timeline.pageSize
        local numberOfCells = GetNumberOfTimelineBlock(Chronicles.UI.Timeline.CurrentStepValue)

        -- DEFAULT_CHAT_FRAME:AddMessage("-- GetIndex " .. numberOfCells)

        if (page == nil) then
            page = 1
        end

        local firstIndex = 1 + ((page - 1) * pageSize)

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if ((firstIndex + pageSize - 1) >= numberOfCells) then
            firstIndex = numberOfCells - (pageSize - 1)
        end

        local firstIndexBounds = GetBounds(firstIndex, Chronicles.UI.Timeline.CurrentStepValue)
        local lastIndexBounds = GetBounds(firstIndex + (pageSize - 1), Chronicles.UI.Timeline.CurrentStepValue)

        local lowerBoundYear = firstIndexBounds.lower
        local upperBoundYear = lastIndexBounds.upper

        selectedYear = (lowerBoundYear + upperBoundYear) / 2
    end

    local minYear = Chronicles.DB:MinEventYear()
    local length = math.abs(minYear - selectedYear)
    local yearIndex = math.floor(length / Chronicles.UI.Timeline.CurrentStepValue)
    local result = yearIndex - (yearIndex % Chronicles.constants.config.timeline.pageSize)

    -- DEFAULT_CHAT_FRAME:AddMessage("-- GetIndex " .. length .. " " .. yearIndex .. " " .. result)

    return result
end

function BuildTimelineBlocks(page, pageSize, numberOfCells, maxPageValue)
    local firstIndex = 1 + ((page - 1) * pageSize)

    if (firstIndex <= 1) then
        firstIndex = 1
        TimelinePreviousButton:Disable()
        Chronicles.UI.Timeline.CurrentPage = 1
    end

    if ((firstIndex + pageSize - 1) >= numberOfCells) then
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

        if (dateBlock.text ~= nil) then
            -- DEFAULT_CHAT_FRAME:AddMessage("-- dateBlock.text Event " .. dateBlock.text)
            frameEvent.LabelText:SetText(dateBlock.text)
            frameEvent.LabelStart:SetText("")
            frameEvent.LabelEnd:SetText("")

            frameNoEvent.LabelText:SetText("")
            frameNoEvent.LabelStart:SetText("")
            frameNoEvent.LabelEnd:SetText("")
        else
            frameEvent.LabelText:SetText("")
            frameEvent.LabelStart:SetText("" .. dateBlock.lowerBound)
            frameEvent.LabelEnd:SetText("" .. dateBlock.upperBound)

            frameNoEvent.LabelStart:SetText("")
            frameNoEvent.LabelEnd:SetText("")
            frameNoEvent.LabelText:SetText("")
        end
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

        if (dateBlock.text ~= nil) then
            frameEvent.LabelText:SetText("")
            frameEvent.LabelStart:SetText("")
            frameEvent.LabelEnd:SetText("")

            frameNoEvent.LabelText:SetText(dateBlock.text)
            frameNoEvent.LabelStart:SetText("")
            frameNoEvent.LabelEnd:SetText("")
        else
            frameEvent.LabelText:SetText("")
            frameEvent.LabelStart:SetText("")
            frameEvent.LabelEnd:SetText("")

            frameNoEvent.LabelText:SetText("")
            frameNoEvent.LabelStart:SetText("" .. dateBlock.lowerBound)
            frameNoEvent.LabelEnd:SetText("" .. dateBlock.upperBound)
        end
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

    -- frame.LabelText
    frame.LabelText:ClearAllPoints()
    frame.LabelText:SetPoint("CENTER", 0, 28)
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

    -- frame.LabelText
    frame.LabelText:ClearAllPoints()
    frame.LabelText:SetPoint("CENTER", 0, -28)
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
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end
    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex + 1])
    Chronicles.UI.Timeline:DisplayTimeline(GetIndex(Chronicles.UI.Timeline.SelectedYear), true)
end

function Timeline_ZoomOut()
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == 1) then
        return
    end
    ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex - 1])
    Chronicles.UI.Timeline:DisplayTimeline(GetIndex(Chronicles.UI.Timeline.SelectedYear), true)
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
end

function TimelineScrollNextButton_OnClick(self)
    Chronicles.UI.Timeline:DisplayTimeline(Chronicles.UI.Timeline.CurrentPage + 1, false)
end
