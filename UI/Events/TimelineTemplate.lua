local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

local Spacing = private.Core.Utils.Spacing

-- -------------------------
-- Timeline
-- -------------------------
TimelineMixin = {}

function TimelineMixin:SetupEventCallbacks()
    if self._eventCallbacksActive then
        return
    end

    if not self._eventCallbackDefinitions then
        self._eventCallbackDefinitions = {
            {event = private.constants.events.TimelineInit, handler = self.OnTimelineInit},
            {event = private.constants.events.TimelinePreviousButtonVisible, handler = self.OnTimelinePreviousButtonVisible},
            {event = private.constants.events.TimelineNextButtonVisible, handler = self.OnTimelineNextButtonVisible},
            {event = private.constants.events.DisplayEventsForYear, handler = self.OnDisplayEventsForYear}
        }
    end

    for _, definition in ipairs(self._eventCallbackDefinitions) do
        private.Core.registerCallback(definition.event, definition.handler, self)
    end

    self._eventCallbacksActive = true
end

function TimelineMixin:ShutdownEventCallbacks()
    if not self._eventCallbacksActive or not self._eventCallbackDefinitions then
        return
    end

    if private.Core.unregisterCallback then
        for _, definition in ipairs(self._eventCallbackDefinitions) do
            private.Core.unregisterCallback(definition.event, self)
        end
    end

    self._eventCallbacksActive = false
end

function TimelineMixin:InitializeStateSubscriptions()
    if not private.Core.StateManager then
        return
    end

    if not self._stateSubscriptionDefs then
        local timelineKey = private.Core.StateManager.buildTimelineKey("currentStep")
        local subscriptionId = (self:GetName() or "TimelineMixin") .. "_CurrentStep"
        self._stateSubscriptionDefs = {
            {
                key = timelineKey,
                id = subscriptionId,
                callback = function(newStep)
                    self:UpdateZoomLevelIndicator(newStep)
                end
            }
        }
    end
end

function TimelineMixin:EnableStateSubscriptions()
    if self._stateSubscriptionsActive or not self._stateSubscriptionDefs then
        return
    end

    for _, definition in ipairs(self._stateSubscriptionDefs) do
        private.Core.StateManager.subscribe(definition.key, definition.callback, definition.id)
    end

    self._stateSubscriptionsActive = true
end

function TimelineMixin:DisableStateSubscriptions()
    if not self._stateSubscriptionsActive or not self._stateSubscriptionDefs then
        return
    end

    for _, definition in ipairs(self._stateSubscriptionDefs) do
        private.Core.StateManager.unsubscribe(definition.key, definition.id)
    end

    self._stateSubscriptionsActive = false
end

--[[
    Build (or reuse) the label and period frames for a page size

    The count used to be frozen in XML as nine hand-chained Label frames and eight Period frames,
    which both restated config.timeline.pageSize and leaked seventeen frame globals. Sizing the
    pools from the same constant the pagination uses means a different page size renders a
    different grid with no XML change.

    Periods sit above the labels, each straddling the boundary between its label and the next, so
    there is always one more label than there are periods.

    @param pageSize [number] Periods on a page; labels are the boundaries, so pageSize + 1 of them
]]
function TimelineMixin:RefreshTimelinePools(pageSize)
    local UIUtils = private.Core.Utils.UIUtils
    if not UIUtils or not pageSize or pageSize < 1 then
        return
    end

    local labelCount = pageSize + 1

    self.labelPool = self.labelPool or {}
    self.periodPool = self.periodPool or {}

    for index = 1, labelCount do
        local label = UIUtils.AcquirePooledFrame(self.labelPool, "TimelineLabelTemplate", self, index, "Frame")

        label:ClearAllPoints()
        if index == 1 then
            label:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", Spacing.md, Spacing.md)
        else
            label:SetPoint("LEFT", self.labelPool[index - 1], "RIGHT", 0, 0)
        end

        label:Initialize(index)
    end
    UIUtils.ReleaseFramesAbove(self.labelPool, labelCount)

    for index = 1, pageSize do
        local period = UIUtils.AcquirePooledFrame(self.periodPool, "TimelinePeriodTemplate", self, index, "Button")

        -- Anchoring the period's left edge to its label's TOP puts it at that label's centre line,
        -- so the period spans from one year mark to the next. The offset is the label art's own
        -- inset, previously a bare 5.
        period:ClearAllPoints()
        period:SetPoint("BOTTOMLEFT", self.labelPool[index], "TOP", Spacing.xs, 0)

        period:Initialize(index)
    end
    UIUtils.ReleaseFramesAbove(self.periodPool, pageSize)

    self.visibleLabelCount = labelCount
    self.visiblePeriodCount = pageSize
end

--[[
    Restate the span the visible page covers, read off the outermost year marks

    Derived from the labels rather than from the pagination data so it cannot disagree with what is
    on screen, and so it needs no event of its own. Only shown labels count: a label with no year to
    show hides itself, and quoting one of those would name a boundary the page does not have.
]]
function TimelineMixin:UpdateRangeIndicator()
    if not self.RangeIndicator or not self.RangeIndicator.Text or not self.labelPool then
        return
    end

    local lower, upper
    for index = 1, self.visibleLabelCount or #self.labelPool do
        local label = self.labelPool[index]
        local text = label and label:IsShown() and label.Text and label.Text:GetText()

        if text and text ~= "" then
            lower = lower or text
            upper = text
        end
    end

    if not lower then
        self.RangeIndicator.Text:SetText("")
        return
    end

    self.RangeIndicator.Text:SetText(lower .. Locale["RangeSeparator"] .. upper)
end

function TimelineMixin:OnLoad()
    -- Set localized button text
    self.ZoomOut:SetText(Locale["Zoom Out"])
    self.ZoomIn:SetText(Locale["Zoom In"])
    self.Previous:SetText(Locale["Previous Page"])
    self.Next:SetText(Locale["Next Page"])
    self.ZoomOut:SetScript(
        "OnClick",
        function()
            private.Core.Timeline.ChangeCurrentStepValue(-1)
        end
    )
    self.ZoomIn:SetScript(
        "OnClick",
        function()
            private.Core.Timeline.ChangeCurrentStepValue(1)
        end
    )
    self.Previous:SetScript("OnClick", self.TimelinePrevious)
    self.Next:SetScript("OnClick", self.TimelineNext)

    -- Before any Display* event fires: the pooled frames are what register for those events.
    self:RefreshTimelinePools(private.constants.config.timeline.pageSize)

    self:InitializeStateSubscriptions()

    -- Immediately initialize the timeline when UI is loaded
    -- This ensures timeline is populated even if TimelineInit event hasn't been triggered
    C_Timer.After(
        0.1,
        function()
            self:OnTimelineInit()
        end
    )

    -- Initialize zoom level indicator
    local initialStepValue
    if private.Core.StateManager then
        initialStepValue =
            private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("currentStep"))
    end
    self:UpdateZoomLevelIndicator(initialStepValue or private.constants.config.stepValues[1])

    -- Initialize date search
    self:InitializeDateSearch()
end

function TimelineMixin:OnShow()
    self:SetupEventCallbacks()
    self:InitializeStateSubscriptions()
    self:EnableStateSubscriptions()

    if private.Core.StateManager then
        local currentStep = private.Core.StateManager.getState(private.Core.StateManager.buildTimelineKey("currentStep"))
        if currentStep then
            self:UpdateZoomLevelIndicator(currentStep)
        end
    end
end

function TimelineMixin:OnHide()
    self:DisableStateSubscriptions()
    self:ShutdownEventCallbacks()
end

-- -------------------------
-- Year-Specific Event Display
-- -------------------------

function TimelineMixin:OnDisplayEventsForYear(eventData)
    if not eventData or not eventData.year or not eventData.events then
        return
    end

    local year = eventData.year
    local events = eventData.events

    -- Update the selected period to show year-specific information
    if private.Core.StateManager then
        -- Create a special period data for year-specific display
        local yearSpecificPeriod = {
            lower = year,
            upper = year,
            text = "Year " .. year,
            nbEvents = #events,
            hasEvents = #events > 0,
            isYearSpecific = true
        }

        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        private.Core.StateManager.setState(selectedPeriodKey, yearSpecificPeriod, "Year-specific period selected")
    end
end

-- -------------------------
-- Date Search Functionality
-- -------------------------

function TimelineMixin:InitializeDateSearch()
    -- Set initial state
    if self.DateSearchInput then
        self.DateSearchInput:SetText("")
        -- Set localized placeholder text
        if self.DateSearchInput.PlaceholderText then
            self.DateSearchInput.PlaceholderText:SetText(Locale["Enter year..."] or "Enter year...")
        end
        self:UpdateDateSearchPlaceholder()

        self.DateSearchInput:SetScript(
            "OnEditFocusGained",
            function()
                self:OnDateSearchFocusGained()
            end
        )
        self.DateSearchInput:SetScript(
            "OnEditFocusLost",
            function()
                self:OnDateSearchFocusLost()
            end
        )
        self.DateSearchInput:SetScript(
            "OnEnterPressed",
            function()
                self:OnDateSearchEnterPressed()
            end
        )
        self.DateSearchInput:SetScript(
            "OnEscapePressed",
            function()
                self:OnDateSearchEscapePressed()
            end
        )
        self.DateSearchInput:SetScript(
            "OnTextChanged",
            function()
                self:OnDateSearchTextChanged()
            end
        )
    end

    -- Set localized button text
    if self.DateSearchButton then
        self.DateSearchButton:SetText(Locale["Go"] or "Go")
        self.DateSearchButton:SetScript(
            "OnClick",
            function()
                self:OnDateSearchButtonClick()
            end
        )
    end
end

function TimelineMixin:OnDateSearchFocusGained()
    if self.DateSearchInput.PlaceholderText then
        self.DateSearchInput.PlaceholderText:Hide()
    end
end

function TimelineMixin:OnDateSearchFocusLost()
    self:UpdateDateSearchPlaceholder()
end

function TimelineMixin:OnDateSearchTextChanged()
    self:UpdateDateSearchPlaceholder()
end

function TimelineMixin:UpdateDateSearchPlaceholder()
    if not self.DateSearchInput or not self.DateSearchInput.PlaceholderText then
        return
    end

    local text = self.DateSearchInput:GetText()
    if text and text ~= "" then
        self.DateSearchInput.PlaceholderText:Hide()
    else
        self.DateSearchInput.PlaceholderText:Show()
    end
end

function TimelineMixin:OnDateSearchEnterPressed()
    self:PerformDateSearch()
end

function TimelineMixin:OnDateSearchEscapePressed()
    if self.DateSearchInput then
        self.DateSearchInput:SetText("")
        self.DateSearchInput:ClearFocus()
        self:UpdateDateSearchPlaceholder()
    end
end

function TimelineMixin:OnDateSearchButtonClick()
    self:PerformDateSearch()
end

function TimelineMixin:PerformDateSearch()
    if not self.DateSearchInput then
        return
    end

    local searchText = self.DateSearchInput:GetText()
    if not searchText or searchText == "" then
        return
    end
    -- Rejections are reported to chat, the same channel the data layer uses for user-facing errors.
    -- Silently returning leaves the box looking broken: the text stays, nothing moves.
    local function reportRejection(message)
        print(private.constants.colors.red .. message .. "|r")
    end

    local year = tonumber(searchText)
    if not year then
        reportRejection(Locale["Invalid year format. Please enter a number (e.g., -10000, 25, 2024)"])
        return
    end

    local minYear = private.constants.config.historyStartYear
    local maxYear = private.constants.config.futur

    if year < minYear or year > maxYear then
        reportRejection(string.format(Locale["Year must be between %d and %d"], minYear, maxYear))
        return
    end

    self:NavigateToYear(year)
    self:DisplayEventsForYear(year)
    self.DateSearchInput:ClearFocus()
end

function TimelineMixin:NavigateToYear(year)
    -- Find the period containing this year and display events
    if not year then
        return
    end

    -- Use Timeline business logic to find the correct page for this year
    if private.Core.Timeline and private.Core.Timeline.NavigateToYear then
        private.Core.Timeline.NavigateToYear(year)
    else
        -- Fallback implementation
        self:FallbackNavigateToYear(year)
    end
end

function TimelineMixin:DisplayEventsForYear(year)
    if not year or not private.Core then
        return
    end

    local triggerEvent = private.Core.triggerEvent
    if not triggerEvent or not private.constants or not private.constants.events then
        return
    end

    local eventsProvider = private.Core.Cache and private.Core.Cache.getSearchEvents and private.Core.Cache.getSearchEvents(year, year) or {}

    local filteredEvents = eventsProvider
    if private.Core.Events and private.Core.Events.FilterEvents then
        filteredEvents = private.Core.Events.FilterEvents(eventsProvider)
    end

    -- A valid year that simply holds nothing would otherwise look identical to a failed search.
    if #filteredEvents > 0 then
        print(string.format(Locale["Found %d events for year %d"], #filteredEvents, year))
    else
        print(string.format(Locale["No events found for year %d"], year))
    end

    local stateManager = private.Core.StateManager
    if stateManager then
        stateManager.setState(
            stateManager.buildTimelineKey("yearSpecificMode"),
            true,
            "Year-specific search activated"
        )
        stateManager.setState(
            stateManager.buildTimelineKey("yearSpecificTarget"),
            year,
            "Year-specific search target"
        )
    end

    -- The event payload below carries the events themselves. They are deliberately not written to
    -- state: timeline.* persists to SavedVariables, so storing whole event records (labels, HTML
    -- chapters) would write the content of every year searched to disk for nobody to read back.

    triggerEvent(
        private.constants.events.DisplayEventsForYear,
        {
            year = year,
            events = filteredEvents
        },
        "TimelineMixin:DisplayEventsForYear"
    )
end

function TimelineMixin:FallbackNavigateToYear(year)
    -- Simple fallback that sets the selected year and refreshes timeline
    if private.Core.StateManager then
        private.Core.StateManager.setState(
            private.Core.StateManager.buildTimelineKey("selectedYear"),
            year,
            "Date search navigation"
        )
    end

    -- Trigger timeline refresh
    if private.Core.Timeline and private.Core.Timeline.ComputeTimelinePeriods then
        private.Core.Timeline.ComputeTimelinePeriods()
        private.Core.Timeline.DisplayTimelineWindow()
    end
end

function TimelineMixin:OnTimelineInit(eventData)
    -- Ahead of the compute, so a changed page size has its frames before the Display* events fire
    self:RefreshTimelinePools(private.constants.config.timeline.pageSize)

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()
end

function TimelineMixin:TimelinePrevious()
    private.Core.Timeline.ChangePage(-1)
end

function TimelineMixin:OnTimelinePreviousButtonVisible(eventData)
    if eventData and eventData.visible then
        self.Previous:Enable()
    else
        self.Previous:Disable()
    end
end

function TimelineMixin:TimelineNext()
    private.Core.Timeline.ChangePage(1)
end

function TimelineMixin:OnTimelineNextButtonVisible(eventData)
    if eventData and eventData.visible then
        self.Next:Enable()
    else
        self.Next:Disable()
    end
end

function TimelineMixin:OnMouseWheel(value)
    if (value > 0) then
        private.Core.Timeline.ChangePage(-1)
    else
        private.Core.Timeline.ChangePage(1)
    end
end

function TimelineMixin:UpdateZoomLevelIndicator(stepValue)
    if not self.ZoomLevelIndicator or not self.ZoomLevelIndicator.Text then
        return
    end

    local displayText = ""
    if stepValue then
        displayText = tostring(stepValue) .. Locale["years"]
    else
        displayText = "?" .. Locale["years"]
    end

    self.ZoomLevelIndicator.Text:SetText(displayText)
end

-- -------------------------
-- TimelineLabel
-- -------------------------
TimelineLabelMixin = {}

--[[
    Claim a position in the timeline and subscribe to the event that fills it

    Replaces an OnLoad that read an "index" KeyValue. Pooled frames are created without one, so the
    position arrives here instead; the DisplayTimelineLabel<index> naming that Timeline.lua fires
    against is unchanged. Calling this again on an already-initialized frame is a no-op, so
    re-laying-out the pool does not stack duplicate subscriptions.

    @param index [number] Position in the label row, 1-based from the left
]]
function TimelineLabelMixin:Initialize(index)
    if self.index then
        return
    end

    self.index = index

    local eventName = private.constants.events.DisplayTimelineLabel .. tostring(index)
    private.Core.registerCallback(eventName, self.OnDisplayTimelineLabel, self)
end

function TimelineLabelMixin:OnDisplayTimelineLabel(data)
    if (data ~= nil and data ~= "") then
        self:Show()
        self.Text:SetText(tostring(data))
    else
        self:Hide()
    end

    local timeline = self:GetParent()
    if timeline and timeline.UpdateRangeIndicator then
        timeline:UpdateRangeIndicator()
    end
end

-- -------------------------
-- TimelinePeriod
-- -------------------------
TimelinePeriodMixin = {}

local ART_PATH = "Interface\\AddOns\\Chronicles\\Art\\"
local NO_EVENTS_TEXTURE = "no-events"

-- Ordered low to high; the first tier whose ceiling the count is under wins, and anything above
-- them all is dense. The same ladder used to be written out three times over.
local EVENT_DENSITY_TIERS = {
    {below = 10, texture = "low-events"},
    {below = 25, texture = "medium-events"}
}
local DENSE_TEXTURE = "high-events"

--[[
    Claim a position in the timeline and subscribe to the event that fills it

    @param index [number] Position in the period row, 1-based from the left
]]
function TimelinePeriodMixin:Initialize(index)
    if self.index then
        return
    end

    self.index = index

    local eventName = private.constants.events.DisplayTimelinePeriod .. tostring(index)
    private.Core.registerCallback(eventName, self.OnDisplayTimelinePeriod, self)
end

--[[
    Paint the period's background for how many events it holds

    @param selected [boolean] Use the "-selected" variant of whichever density texture applies
]]
function TimelinePeriodMixin:ApplyEventDensityTexture(selected)
    local data = self.data

    if not data or not data.hasEvents then
        self.Background:SetTexture(ART_PATH .. NO_EVENTS_TEXTURE)
        return
    end

    local textureName = DENSE_TEXTURE
    for _, tier in ipairs(EVENT_DENSITY_TIERS) do
        if data.nbEvents < tier.below then
            textureName = tier.texture
            break
        end
    end

    self.Background:SetTexture(ART_PATH .. textureName .. (selected and "-selected" or ""))
end

function TimelinePeriodMixin:OnDisplayTimelinePeriod(periodData)
    self.data = periodData

    local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
    local selectedPeriod = private.Core.StateManager.getState(selectedPeriodKey)
    local isSelected =
        selectedPeriod and periodData and selectedPeriod.lower == periodData.lower and
        selectedPeriod.upper == periodData.upper

    if (periodData ~= nil and periodData.hasEvents) then
        self.Text:SetText(periodData.nbEvents)
    else
        self.Text:SetText("")
    end

    self:ApplyEventDensityTexture(isSelected)

    self.Background:SetVertexColor(1, 1, 1)

    -- White count everywhere. The font family's dark shadow carries the contrast over both the
    -- dark unselected crystals and the lighter "-selected" ones. The old black-for-selected branch
    -- assumed every "-selected" texture was light, but a low-density selected period keeps a dark
    -- teal crystal, and black-on-teal was unreadable.
    if self.Text and self.Text.SetTextColor then
        self.Text:SetTextColor(1, 1, 1)
    end
end

--[[
    Return every period on the page to its unselected texture

    Walks the parent's pool. This used to read a literal eight-element list of Period1..Period8
    globals, which both hardcoded the page size and depended on frames being named.
]]
function TimelinePeriodMixin:ResetAllPeriodTextures()
    local timeline = self:GetParent()
    local pool = timeline and timeline.periodPool
    if not pool then
        return
    end

    for index = 1, (timeline.visiblePeriodCount or #pool) do
        local period = pool[index]
        if period then
            period:ApplyEventDensityTexture(false)
        end
    end
end

function TimelinePeriodMixin:OnClick()
    -- Clear year-specific mode when clicking on timeline periods (normal navigation)
    if private.Core.StateManager then
        private.Core.StateManager.setState(
            private.Core.StateManager.buildTimelineKey("yearSpecificMode"),
            false,
            "Year-specific mode cleared due to period selection"
        )
    end

    -- Create a period data structure for state storage
    -- Only store essential data, not calculated values
    local periodData = {
        lower = self.data.lower,
        upper = self.data.upper,
        text = self.data.text,
        nbEvents = self.data.nbEvents,
        hasEvents = self.data.hasEvents
    }

    -- Update state instead of triggering event - provides single source of truth
    if private.Core.StateManager then
        local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
        local currentSelection = private.Core.StateManager.getState(selectedPeriodKey)

        if currentSelection and currentSelection.lower == periodData.lower and currentSelection.upper == periodData.upper then
            return
        end

        private.Core.StateManager.setState(
            selectedPeriodKey,
            periodData,
            "Timeline period selected"
        )
    end

    self:ResetAllPeriodTextures()

    -- Set the selected texture for this period
    self:ApplyEventDensityTexture(true)
end
