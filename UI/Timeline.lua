local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.Timeline = {}

Chronicles.UI.Timeline.StepValues = {
	1000,
	500,
	250,
	100,
	50,
	10,
	5,
	1
}

Chronicles.UI.Timeline.MaxStepIndex = 3

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

function Chronicles.UI.Timeline:DsiplayTimeline()
	Chronicles.UI.Timeline:DisplayTimelinePage(Chronicles.SelectedValues.currentTimelinePage)
end

function GetLowerBound(index)
	local value = Chronicles.constants.timeline.yearStart + ((index - 1) * Chronicles.SelectedValues.timelineStep)

	if (value < Chronicles.constants.timeline.yearStart) then
		return Chronicles.constants.timeline.yearStart
	end
	return value
end

function GetUpperBound(index)
	local value = Chronicles.constants.timeline.yearStart + (index * Chronicles.SelectedValues.timelineStep) - 1
	if (value > Chronicles.constants.timeline.yearEnd) then
		return Chronicles.constants.timeline.yearEnd
	end
	return value
end

-- page goes from 1 to math.floor(numberOfCells / pageSize)
-- index should go from 1 to GetNumberOfTimelineBlock
function Chronicles.UI.Timeline:DisplayTimelinePage(page)
	local pageSize = Chronicles.constants.timeline.pageSize
	local numberOfCells = GetNumberOfTimelineBlock(Chronicles.SelectedValues.timelineStep)
	local maxPageValue = math.ceil(numberOfCells / pageSize)

	if (page < 1) then
		page = 1
	end
	if (page > maxPageValue) then
		page = maxPageValue
	end

	--DEFAULT_CHAT_FRAME:AddMessage("-- Asked page " .. page)
	--DEFAULT_CHAT_FRAME:AddMessage("-- SetMinMaxValues " .. numberOfCells .. "  " .. pageSize .. "  " .. maxPageValue)

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
	--DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndex " .. firstIndex)

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

	--DEFAULT_CHAT_FRAME:AddMessage("-- FirstIndexAfterChecked " .. firstIndex)
	--DEFAULT_CHAT_FRAME:AddMessage("-- Page and Index " .. Chronicles.SelectedValues.currentTimelinePage .. "  " .. firstIndex)

	-- TimelineBlock1
	local lowerBoundBlock1 = GetLowerBound(firstIndex)
	local upperBoundBlock1 = GetUpperBound(firstIndex)
	SetTextToFrame(lowerBoundBlock1, upperBoundBlock1, TimelineBlock1)

	-- TimelineBlock2
	local lowerBoundBlock2 = GetLowerBound(firstIndex + 1)
	local upperBoundBlock2 = GetUpperBound(firstIndex + 1)
	SetTextToFrame(lowerBoundBlock2, upperBoundBlock2, TimelineBlock2)

	-- TimelineBlock3
	local lowerBoundBlock3 = GetLowerBound(firstIndex + 2)
	local upperBoundBlock3 = GetUpperBound(firstIndex + 2)
	SetTextToFrame(lowerBoundBlock3, upperBoundBlock3, TimelineBlock3)

	-- TimelineBlock4
	local lowerBoundBlock4 = GetLowerBound(firstIndex + 3)
	local upperBoundBlock4 = GetUpperBound(firstIndex + 3)
	SetTextToFrame(lowerBoundBlock4, upperBoundBlock4, TimelineBlock4)

	-- TimelineBlock5
	local lowerBoundBlock5 = GetLowerBound(firstIndex + 4)
	local upperBoundBlock5 = GetUpperBound(firstIndex + 4)
	SetTextToFrame(lowerBoundBlock5, upperBoundBlock5, TimelineBlock5)

	-- TimelineBlock6
	local lowerBoundBlock6 = GetLowerBound(firstIndex + 5)
	local upperBoundBlock6 = GetUpperBound(firstIndex + 5)
	SetTextToFrame(lowerBoundBlock6, upperBoundBlock6, TimelineBlock6)

	-- TimelineBlock7
	local lowerBoundBlock7 = GetLowerBound(firstIndex + 6)
	local upperBoundBlock7 = GetUpperBound(firstIndex + 6)
	SetTextToFrame(lowerBoundBlock7, upperBoundBlock7, TimelineBlock7)

	-- TimelineBlock8
	local lowerBoundBlock8 = GetLowerBound(firstIndex + 7)
	local upperBoundBlock8 = GetUpperBound(firstIndex + 7)
	SetTextToFrame(lowerBoundBlock8, upperBoundBlock8, TimelineBlock8)
end

function GetNumberOfTimelineBlock()
	local length = math.abs(Chronicles.constants.timeline.yearStart - Chronicles.constants.timeline.yearEnd)
	return math.ceil(length / Chronicles.SelectedValues.timelineStep)
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

	Chronicles.SelectedValues.currentTimelinePage =
		FindYearIndexOnTimeline(Chronicles.SelectedValues.currentTimelineYear, Chronicles.SelectedValues.timelineStep)

	Chronicles.UI.Timeline:DsiplayTimeline()
end

function Timeline_ZoomOut()
	local currentStepValue = Chronicles.SelectedValues.timelineStep

	local curentStepIndex = GetStepValueIndex(currentStepValue)

	if (curentStepIndex == 1) then
		return
	end

	Chronicles.SelectedValues.timelineStep = Chronicles.UI.Timeline.StepValues[curentStepIndex - 1]

	Chronicles.SelectedValues.currentTimelinePage =
		FindYearIndexOnTimeline(Chronicles.SelectedValues.currentTimelineYear, Chronicles.SelectedValues.timelineStep)

	Chronicles.UI.Timeline:DsiplayTimeline()
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
	--DEFAULT_CHAT_FRAME:AddMessage("-- TimelineScrollFrame_OnMouseWheel " .. value)
	if (value > 0) then
		TimelineScrollPreviousButton_OnClick(self)
	else
		TimelineScrollNextButton_OnClick(self)
	end
end

function TimelineScrollPreviousButton_OnClick(self)
	Chronicles.SelectedValues.currentTimelinePage = Chronicles.SelectedValues.currentTimelinePage - 1

	Chronicles.UI.Timeline:DsiplayTimeline()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function TimelineScrollNextButton_OnClick(self)
	Chronicles.SelectedValues.currentTimelinePage = Chronicles.SelectedValues.currentTimelinePage + 1

	Chronicles.UI.Timeline:DsiplayTimeline()
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function SetTextToFrame(lowerBound, upperBound, frame)
	local text = "" .. lowerBound .. "\n" .. upperBound
	frame.lowerBound = lowerBound
	frame.upperBound = upperBound

	local label = _G[frame:GetName() .. "Text"]
	label:SetText(text)

	frame:SetScript(
		"OnMouseDown",
		function()
			local eventList = Chronicles:SearchEvents(lowerBound, upperBound)
			Chronicles.SelectedValues.currentTimelineYear = math.floor((lowerBound + upperBound) / 2)
			Chronicles.UI.EventList:DrawEventList(frame.lowerBound, frame.upperBound, eventList)
		end
	)
end
