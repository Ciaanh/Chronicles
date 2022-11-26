local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.MaxStepIndex = 7

Chronicles.UI.Timeline.StepValues = {1000, 500, 250, 100, 50, 10, 1}
Chronicles.UI.Timeline.CurrentStepValue = nil
Chronicles.UI.Timeline.CurrentPage = nil
Chronicles.UI.Timeline.SelectedYear = nil

Chronicles.UI.Timeline.Periods = {}

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

    TimelineScrollBar:SetBackdropColor(0.8, 0.65, 0.39)
    Chronicles.UI.Timeline:ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[1])

    Chronicles.UI.Timeline:Refresh()
end

function Chronicles.UI.Timeline:Refresh()
    Chronicles.UI.Timeline.Periods =
        Chronicles.UI.Timeline:ComputeTimelinePeriods(Chronicles.UI.Timeline.CurrentStepValue)
    Chronicles.UI.Timeline:DisplayTimeline()
end

-- pageIndex goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimeline(debounceIndex)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Chronicles.UI.Timeline:DisplayTimeline " .. GetTime())

    local stepValue = Chronicles.UI.Timeline.CurrentStepValue
    local pageIndex = Chronicles.UI.Timeline.CurrentPage
    local pageSize = Chronicles.constants.config.timeline.pageSize

    if (debounceIndex ~= nil) then
        if (debounceIndex ~= pageIndex) then
            pageIndex = debounceIndex
        else
            return
        end
    end

    local numberOfCells = #Chronicles.UI.Timeline.Periods
    if (numberOfCells == 0) then
        TimelineScrollBar:SetMinMaxValues(1, 1)
        Chronicles.UI.Timeline.CurrentPage = 1
        TimelinePreviousButton:Disable()
        TimelineNextButton:Disable()
        Chronicles.UI.Timeline:HideAllTimelineBlocks()
        return
    end

    local maxPageValue = math.ceil(numberOfCells / pageSize)
    if (pageIndex == nil) then
        pageIndex = maxPageValue
    elseif (pageIndex < 1) then
        pageIndex = 1
    elseif (pageIndex > maxPageValue) then
        pageIndex = maxPageValue
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- pageIndex " .. pageIndex)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- maxPageValue " .. maxPageValue)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- numberOfCells " .. numberOfCells)

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

    -- DEFAULT_CHAT_FRAME:AddMessage("-- size of TimeFrames " .. #Chronicles.UI.Timeline.Periods)

    Chronicles.UI.Timeline:BuildTimelineBlocks(pageIndex, pageSize, numberOfCells, maxPageValue)
end

function Chronicles.UI.Timeline:ChangeCurrentStepValue(stepValue)
    if (stepValue == nil) then
        stepValue = Chronicles.UI.Timeline.StepValues[1]
    end

    local stepText = Locale["currentstep"] .. stepValue .. Locale["years"]
    if (stepValue == 1) then
        stepText = Locale["currentstep"] .. stepValue .. Locale["year"]
    end

    TimelineStep:SetText(stepText)

    Chronicles.UI.Timeline.CurrentStepValue = stepValue

    Chronicles.UI.Timeline.Periods = Chronicles.UI.Timeline:ComputeTimelinePeriods(stepValue)
end

function Chronicles.UI.Timeline:GetTimelineConfig(minYear, maxYear, stepValue)
    local timelineConfig = {
        isOverlapping = false,
        pastEvents = false,
        futurEvents = false,
        before = 0,
        after = 0,
        minYear = minYear,
        maxYear = maxYear,
        numberOfTimelineBlock = 0
    }

    -- Define the boundaries of the timeline
    if (minYear < Chronicles.constants.config.historyStartYear) then -- there is event before the history start year
        timelineConfig.minYear = Chronicles.constants.config.historyStartYear
        timelineConfig.pastEvents = true
    end

    if (maxYear > Chronicles.constants.config.currentYear) then -- there is event after the current year
        timelineConfig.maxYear = Chronicles.constants.config.currentYear
        timelineConfig.futurEvents = true
    end

    if (timelineConfig.minYear < 0 and timelineConfig.maxYear > 0) then -- there is event before and after the 0 year
        timelineConfig.isOverlapping = true
    end

    if (timelineConfig.minYear < 0) then
        local beforeLength = math.abs(timelineConfig.minYear)

        timelineConfig.before = math.ceil((beforeLength) / stepValue)
    end
    if (timelineConfig.maxYear > 0) then
        local afterLength = math.abs(timelineConfig.maxYear)

        timelineConfig.after = math.ceil((afterLength) / stepValue)
    end

    -- Define the total number of timeline blocks
    if (timelineConfig.isOverlapping) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.before + timelineConfig.after
    else
        local length = math.abs(timelineConfig.minYear - timelineConfig.maxYear)
        timelineConfig.numberOfTimelineBlock = math.ceil(length / stepValue)
    end

    if (timelineConfig.pastEvents == true) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.numberOfTimelineBlock + 1
        if (timelineConfig.isOverlapping) then
            timelineConfig.before = timelineConfig.before + 1
        end
    end
    if (timelineConfig.futurEvents == true) then
        timelineConfig.numberOfTimelineBlock = timelineConfig.numberOfTimelineBlock + 1

        if (timelineConfig.isOverlapping) then
            timelineConfig.after = timelineConfig.after + 1
        end
    end

    return timelineConfig
end

function Chronicles.UI.Timeline:ComputeTimelinePeriods(stepValue)
    local minYear = Chronicles.DB:MinEventYear()
    local maxYear = Chronicles.DB:MaxEventYear()

    -- DEFAULT_CHAT_FRAME:AddMessage("-- minYear " .. minYear)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- maxYear " .. maxYear)

    local timelineConfig = Chronicles.UI.Timeline:GetTimelineConfig(minYear, maxYear, stepValue)

    local insert = table.insert
    local timelineBlocks = {}

    DEFAULT_CHAT_FRAME:AddMessage("-- numberOfTimelineBlock " .. timelineConfig.numberOfTimelineBlock)

    for blockIndex = 1, timelineConfig.numberOfTimelineBlock do
        local minValue = 0
        local maxValue = 0

        if (timelineConfig.isOverlapping) then
            if (blockIndex <= timelineConfig.before) then
                minValue = -((timelineConfig.before - blockIndex + 1) * stepValue)
                maxValue = -((timelineConfig.before - blockIndex) * stepValue) - 1
            else
                minValue = ((blockIndex - timelineConfig.before - 1) * stepValue)
                maxValue = ((blockIndex - timelineConfig.before) * stepValue) - 1
            end
        else
            if (timelineConfig.pastEvents == true and blockIndex == 1) then
                minValue = timelineConfig.minYear - 2
                maxValue = timelineConfig.minYear - 1
            elseif (timelineConfig.futurEvents == true and blockIndex == numberOfCells) then
                minValue = timelineConfig.maxYear + 1
                maxValue = timelineConfig.maxYear + 2
            else
                minValue = timelineConfig.minYear + ((blockIndex - 1) * stepValue) + 1
                maxValue = timelineConfig.minYear + (blockIndex * stepValue)
            end
        end

        local block = {
            lowerBound = minValue,
            upperBound = maxValue,
            text = nil,
            hasEvents = nil
        }

        if (maxValue > Chronicles.constants.config.currentYear) then
            if (minValue > Chronicles.constants.config.currentYear) then
                block.lowerBound = Chronicles.constants.config.currentYear + 1
                block.upperBound = 999999
                block.text = Locale["Futur"]
            else
                block.upperBound = Chronicles.constants.config.currentYear
            end
        elseif (maxValue < Chronicles.constants.config.historyStartYear) then
            if (minValue < Chronicles.constants.config.historyStartYear) then
                block.lowerBound = -999999
                block.upperBound = Chronicles.constants.config.historyStartYear - 1
                block.text = Locale["Mythos"]
            else
                block.upperBound = Chronicles.constants.config.historyStartYear
            end
        end

        if (blockIndex == timelineConfig.numberOfTimelineBlock) then
            DEFAULT_CHAT_FRAME:AddMessage(
                "-- blockIndex " .. blockIndex .. "-- minValue " .. minValue .. "-- maxValue " .. maxValue
            )
            DEFAULT_CHAT_FRAME:AddMessage("-- lower " .. block.lowerBound .. "-- upper " .. block.upperBound)
        end

        block.hasEvents = Chronicles.UI.Timeline:HasEvents(block)

        insert(timelineBlocks, block)
    end

    local displayableTimeFrames = {}
    for j, value in ipairs(timelineBlocks) do
        local nextValue = timelineBlocks[j + 1]

        if (value.lowerBound == 40) then
            DEFAULT_CHAT_FRAME:AddMessage("-- value.lowerBound " .. value.lowerBound)
        end

        if (nextValue ~= nil) then
            if (value.hasEvents == true or (value.hasEvents == false and nextValue.hasEvents == true)) then
                table.insert(
                    displayableTimeFrames,
                    {
                        lowerBound = value.lowerBound,
                        upperBound = value.upperBound,
                        text = value.text,
                        hasEvents = value.hasEvents
                    }
                )
            end

            if (value.hasEvents == false and nextValue.hasEvents == false) then
                nextValue.lowerBound = value.lowerBound
            end
        else
            table.insert(
                displayableTimeFrames,
                {
                    lowerBound = value.lowerBound,
                    upperBound = value.upperBound,
                    text = value.text,
                    hasEvents = value.hasEvents
                }
            )
        end
    end

    -- for i, v in ipairs(displayableTimeFrames) do
    --     DEFAULT_CHAT_FRAME:AddMessage(
    --         "-- block " ..
    --             i .. --" " .. #displayableTimeFrames ..
    --                 " " .. tostring(v) .. " " .. tostring(v.lowerBound) .. " " .. tostring(v.upperBound)
    --     )
    -- end

    -- for k = 1, #displayableTimeFrames do

    -- end

    -- DEFAULT_CHAT_FRAME:AddMessage(
    --     "-- block " .. #timelineBlocks ..
    --     " " .. #displayableTimeFrames ..
    --     " " .. tostring(displayableTimeFrames[24]) ..
    --     " " .. tostring(displayableTimeFrames[24].text)
    -- )

    return displayableTimeFrames
end

function Chronicles.UI.Timeline:HasEvents(block)
    local upperBound = block.upperBound
    local lowerBound = block.lowerBound

    local upperDateIndex = Chronicles.UI.Timeline:GetDateCurrentStepIndex(upperBound)
    local lowerDateIndex = Chronicles.UI.Timeline:GetDateCurrentStepIndex(lowerBound)

    local eventDates = Chronicles.UI.Timeline:GetCurrentStepEventDates()
    local currentstep = Chronicles.UI.Timeline.CurrentStepValue

    local gap = math.abs(upperDateIndex - lowerDateIndex)

    -- if (block.lowerBound == 0) then
    --     DEFAULT_CHAT_FRAME:AddMessage(
    --         "-- upperDateIndex " .. upperDateIndex .. " " .. tostring(eventDates[upperDateIndex])
    --     )
    --     DEFAULT_CHAT_FRAME:AddMessage(
    --         "-- lowerDateIndex " .. lowerDateIndex .. " " .. tostring(eventDates[lowerDateIndex])
    --     )
    -- end

    -- DEFAULT_CHAT_FRAME:AddMessage("-- lowerBound " .. lowerBound .. " step " .. Chronicles.UI.Timeline.CurrentStepValue)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- lowerDateIndex " .. lowerDateIndex)

    if (gap > 1) then
        for i = lowerDateIndex, upperDateIndex, 1 do
            local eventsDate = eventDates[i]
            if (eventsDate ~= nil and eventsDate) then
                return true
            end
        end
    else
        local lowerEventsDate = eventDates[lowerDateIndex]
        local upperEventsDate = eventDates[upperDateIndex]

        -- DEFAULT_CHAT_FRAME:AddMessage("-- size of TimeFrames " .. #Chronicles.UI.Timeline.Periods)

        -- if (block.lowerBound == 0) then
        --     DEFAULT_CHAT_FRAME:AddMessage(
        --         "-- upperDateIndex " .. upperDateIndex .. " " .. tostring(eventDates[upperDateIndex])
        --     )
        --     DEFAULT_CHAT_FRAME:AddMessage(
        --         "-- lowerDateIndex " .. lowerDateIndex .. " " .. tostring(eventDates[lowerDateIndex])
        --     )
        -- end

        if (lowerEventsDate ~= nil and lowerEventsDate) then
            -- if (block.lowerBound == 0) then
            --     DEFAULT_CHAT_FRAME:AddMessage(
            --         "-- lowerDateIndex " .. lowerDateIndex .. " " .. tostring(eventDates[lowerDateIndex])
            --     )
            -- end
            return true
        end
        if (upperEventsDate ~= nil and upperEventsDate) then
            -- if (block.lowerBound == 0) then
            --     DEFAULT_CHAT_FRAME:AddMessage(
            --         "-- upperDateIndex " .. upperDateIndex .. " " .. tostring(eventDates[upperDateIndex])
            --     )
            -- end
            return true
        end
    end
    return false
end

function Chronicles.UI.Timeline:GetDateCurrentStepIndex(date)
    local dateProfile = Chronicles.DB:ComputeDateProfile(date)
    if (Chronicles.UI.Timeline.CurrentStepValue == 1000) then
        return dateProfile.mod1000
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 500) then
        return dateProfile.mod500
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 250) then
        return dateProfile.mod250
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 100) then
        return dateProfile.mod100
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 50) then
        return dateProfile.mod50
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 10) then
        return dateProfile.mod10
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 1) then
        return dateProfile.mod1
    end
end

function Chronicles.UI.Timeline:GetCurrentStepEventDates()
    local eventDates = Chronicles.DB.EventsDates
    if (Chronicles.UI.Timeline.CurrentStepValue == 1000) then
        return eventDates.mod1000
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 500) then
        return eventDates.mod500
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 250) then
        return eventDates.mod250
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 100) then
        return eventDates.mod100
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 50) then
        return eventDates.mod50
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 10) then
        return eventDates.mod10
    elseif (Chronicles.UI.Timeline.CurrentStepValue == 1) then
        return eventDates.mod1
    end
end

function Chronicles.UI.Timeline:GetIndex(year)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- GetIndex " .. GetTime())
    local selectedYear = year

    if (selectedYear == nil) then
        local page = Chronicles.UI.Timeline.CurrentPage
        local pageSize = Chronicles.constants.config.timeline.pageSize
        -- local numberOfCells = Chronicles.UI.Timeline:GetNumberOfTimelineBlock(Chronicles.UI.Timeline.CurrentStepValue)
        local numberOfCells = #Chronicles.UI.Timeline.Periods

        -- DEFAULT_CHAT_FRAME:AddMessage("-- GetIndex " .. numberOfCells)

        if (page == nil) then
            page = 1
        end

        local firstIndex = 1 + ((page - 1) * pageSize)
        local lastIndex = page * pageSize

        if (firstIndex <= 1) then
            firstIndex = 1
        end
        if (lastIndex > numberOfCells) then
            firstIndex = numberOfCells - (pageSize)
            lastIndex = numberOfCells - 1
        end

        -- DEFAULT_CHAT_FRAME:AddMessage("-- firstIndex " .. firstIndex)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- lastIndex " .. lastIndex)
        -- DEFAULT_CHAT_FRAME:AddMessage("-- Size " .. #Chronicles.UI.Timeline.Periods)

        local firstIndexBounds = Chronicles.UI.Timeline.Periods[firstIndex]
        local lastIndexBounds = Chronicles.UI.Timeline.Periods[lastIndex]

        if (firstIndexBounds ~= nil and upperBoundYear ~= nil) then
            local lowerBoundYear = firstIndexBounds.lowerBound
            local upperBoundYear = lastIndexBounds.upperBound

            selectedYear = (lowerBoundYear + upperBoundYear) / 2
        else
            selectedYear = 0
        end
    end

    local minYear = Chronicles.DB:MinEventYear()
    local length = math.abs(minYear - selectedYear)
    local yearIndex = math.floor(length / Chronicles.UI.Timeline.CurrentStepValue)
    local result = yearIndex - (yearIndex % Chronicles.constants.config.timeline.pageSize)

    -- DEFAULT_CHAT_FRAME:AddMessage("-- GetIndex " .. length .. " " .. yearIndex .. " " .. result)

    return result
end

function Chronicles.UI.Timeline:BuildTimelineBlocks(page, pageSize, numberOfCells, maxPageValue)
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

    Chronicles.UI.Timeline:LoadTimelineDatesToBlock(firstIndex)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- LoadTimelineDatesToBlock end " .. GetTime())
end

function Chronicles.UI.Timeline:LoadTimelineDatesToBlock(firstIndex)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 0, TimelineBlock1, TimelineBlockNoEvent1)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 1, TimelineBlock2, TimelineBlockNoEvent2)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 2, TimelineBlock3, TimelineBlockNoEvent3)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 3, TimelineBlock4, TimelineBlockNoEvent4)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 4, TimelineBlock5, TimelineBlockNoEvent5)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 5, TimelineBlock6, TimelineBlockNoEvent6)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 6, TimelineBlock7, TimelineBlockNoEvent7)
    Chronicles.UI.Timeline:SetDateToBlock(firstIndex + 7, TimelineBlock8, TimelineBlockNoEvent8)
end

function Chronicles.UI.Timeline:HideAllTimelineBlocks()
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

function Chronicles.UI.Timeline:SetDateToBlock(index, frameEvent, frameNoEvent)
    local isUp = true
    if ((index % 2) == 0) then
        isUp = false
    end
    local dateBlock = Chronicles.UI.Timeline.Periods[index]

    if (dateBlock == nil) then
        frameNoEvent:Hide()
        frameEvent:Hide()
        return
    end

    -- if (dateBlock.lowerBound == 0) then
    --     DEFAULT_CHAT_FRAME:AddMessage(
    --         "-- SetDateToBlock " .. dateBlock.lowerBound .. " " .. tostring(dateBlock.hasEvents) .. " " .. index
    --     )
    -- end

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
            if (dateBlock.lowerBound == dateBlock.upperBound) then
                frameEvent.LabelText:SetText(dateBlock.lowerBound)
                frameEvent.LabelStart:SetText("")
                frameEvent.LabelEnd:SetText("")
            else
                frameEvent.LabelText:SetText("")
                frameEvent.LabelStart:SetText(dateBlock.lowerBound)
                frameEvent.LabelEnd:SetText(dateBlock.upperBound)
            end

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

            if (dateBlock.lowerBound == dateBlock.upperBound) then
                frameNoEvent.LabelText:SetText(dateBlock.lowerBound)
                frameNoEvent.LabelStart:SetText("")
                frameNoEvent.LabelEnd:SetText("")
            else
                frameNoEvent.LabelText:SetText("")
                frameNoEvent.LabelStart:SetText(dateBlock.lowerBound)
                frameNoEvent.LabelEnd:SetText(dateBlock.upperBound)
            end
        end
        frameEvent:SetScript(
            "OnMouseDown",
            function()
                Chronicles.UI.EventList:SetEventListData(0, 0, {})
            end
        )
    end

    if (isUp) then
        Chronicles.UI.Timeline:SetTimelineBlockUp(frameEvent)
        Chronicles.UI.Timeline:SetTimelineBlockUp(frameNoEvent)
    else
        Chronicles.UI.Timeline:SetTimelineBlockDown(frameEvent)
        Chronicles.UI.Timeline:SetTimelineBlockDown(frameNoEvent)
    end
end

function Chronicles.UI.Timeline:SetTimelineBlockUp(frame)
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

function Chronicles.UI.Timeline:SetTimelineBlockDown(frame)
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

function Chronicles.UI.Timeline:GetStepValueIndex(stepValue)
    local index = {}
    for k, v in pairs(Chronicles.UI.Timeline.StepValues) do
        index[v] = k
    end
    return index[stepValue]
end

function Timeline_ZoomIn()
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == Chronicles.UI.Timeline.MaxStepIndex) then
        return
    end
    Chronicles.UI.Timeline:ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex + 1])

    Chronicles.UI.Timeline.CurrentPage = Chronicles.UI.Timeline:GetIndex(Chronicles.UI.Timeline.SelectedYear)

    -- DEFAULT_CHAT_FRAME:AddMessage("-- Timeline_ZoomIn " .. GetTime())
    Chronicles.UI.Timeline:DisplayTimeline()
end

function Timeline_ZoomOut()
    local CurrentStepValueValue = Chronicles.UI.Timeline.CurrentStepValue
    local curentStepIndex = Chronicles.UI.Timeline:GetStepValueIndex(CurrentStepValueValue)

    if (curentStepIndex == 1) then
        return
    end
    Chronicles.UI.Timeline:ChangeCurrentStepValue(Chronicles.UI.Timeline.StepValues[curentStepIndex - 1])

    Chronicles.UI.Timeline.CurrentPage = Chronicles.UI.Timeline:GetIndex(Chronicles.UI.Timeline.SelectedYear)

    -- DEFAULT_CHAT_FRAME:AddMessage("-- Timeline_ZoomOut " .. GetTime())
    Chronicles.UI.Timeline:DisplayTimeline()
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
    -- DEFAULT_CHAT_FRAME:AddMessage("-- TimelineScrollPreviousButton_OnClick " .. GetTime())
    Chronicles.UI.Timeline.CurrentPage = Chronicles.UI.Timeline.CurrentPage - 1
    Chronicles.UI.Timeline:DisplayTimeline()
end

function TimelineScrollNextButton_OnClick(self)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- TimelineScrollNextButton_OnClick " .. GetTime())
    Chronicles.UI.Timeline.CurrentPage = Chronicles.UI.Timeline.CurrentPage + 1
    Chronicles.UI.Timeline:DisplayTimeline()
end

function TimelineScrollBar_OnValueChanged(value, step)
    local index = adjust_value(value, step)
    Chronicles.UI.Timeline:DisplayTimeline(index)
end
