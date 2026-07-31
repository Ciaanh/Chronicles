local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
=================================================================================
Module: Settings UI
Purpose: User preferences and configuration interface management
Dependencies: AceLocale-3.0, StateManager
Author: Chronicles Team
=================================================================================

This module manages the complex Settings interface with dynamic tab generation:
- Hierarchical settings categories and subcategories
- Dynamic UI generation based on configuration
- Real-time settings validation and application
- Collection and event type management

Complex UI Event Flow Patterns:

1. Settings Interface Initialization:
   OnLoad → Category Configuration → Dynamic Button Creation → Tab Setup
   
2. Category Navigation Flow:
   Button Click → Category Validation → Tab Switch → Content Loading → State Update
   
3. Setting Change Pattern:
   User Input → Validation → State Update → UI Refresh → Event Trigger → Persistence
   
4. Collection Management Flow:
   Collection Toggle → Status Validation → Data Registry Update → UI Refresh → Filter Update

UI Architecture Patterns:
- ConfiguredCategories: Hierarchical menu structure
- Dynamic button generation for categories and subcategories
- Tab-based content switching with lazy loading
- Event-driven state synchronization

Key Settings Categories:
- Event Types: Toggle event categories (war, death, birth, etc.)
- Collections: Enable/disable data collections (expansions, custom content)
- Logs: Debug and diagnostic information

Event Integration:
- Settings changes trigger events.SettingsEventTypeChecked
- Collection toggles trigger events.SettingsCollectionChecked
- State changes propagate to the Cache and Data modules

Dependencies:
- AceLocale-3.0: UI text localization
- StateManager: Settings persistence
=================================================================================
]]
-- Event types
-- Collections
SettingsMixin = {}

--[[
    Initialize the Settings interface with dynamic category generation
    
    This complex initialization function sets up the hierarchical settings structure:
    1. Configures category hierarchy with nested submenus
    2. Generates dynamic UI buttons for each category
    3. Sets up tab system integration
    4. Initializes event handling for settings changes
    
    UI Generation Flow:
    ConfiguredCategories → GetVisibleCategories → AddCategory → Button Creation
    
    @example
        -- Called automatically when Settings frame loads
        -- Creates buttons for: Settings (EventTypes, Collections), Logs
]]
function SettingsMixin:OnLoad()
    self.prefix = "Entry"

    -- Flat, two entries. "Settings" used to be a third category button with these two nested under it
    -- at an indent, which meant a rail sized for three rows where the top one only ever selected a
    -- landing page of static prose. It is the panel's header now, not a destination, so the first
    -- category with a TabName -- and therefore the tab that opens by default -- is Event types.
    self.ConfiguredCategories = {
        {
            text = Locale["Event types"],
            TabName = "EventTypes",
            TabFrame = self.TabUI.EventTypes,
            Load = self.LoadEventTypes
        },
        {
            text = Locale["Collections"],
            TabName = "Collections",
            TabFrame = self.TabUI.Collections,
            Load = self.LoadCollections
        }
    }

    self.categories = self:GetVisibleCategories(self.ConfiguredCategories)
    self.Buttons = {}

    for index, category in ipairs(self.categories) do
        self:AddCategory(index, category)
    end

    self.TabUI.Tabs = {}

    for _, category in ipairs(self.categories) do
        if (category.TabName ~= nil and category.TabFrame ~= nil) then
            local tabKey = category.TabName

            local currentTab = self.TabUI.currentTab
            if not currentTab then
                self.TabUI.currentTab = tabKey
            end

            self.TabUI.Tabs[tabKey] = category
        end
    end
    private.Core.registerCallback(
        private.constants.events.SettingsEventTypeChecked,
        self.OnSettingsEventTypeChecked,
        self
    )
    private.Core.registerCallback(
        private.constants.events.SettingsCollectionChecked,
        self.OnSettingsCollectionChecked,
        self
    )

    if private.Core.StateManager then
        local categoryKey = private.Core.StateManager.buildUIStateKey("settingsCategory")
        private.Core.StateManager.subscribe(
            categoryKey,
            function(newTab, oldTab)
                if newTab then
                    self:OnSettingsTabSelected(newTab)
                end
            end,
            "SettingsMixin"
        )
    end

    self:UpdateTabs()
    if self.TabUI.currentTab then
        local currentTab = self.TabUI.Tabs[self.TabUI.currentTab]
        if currentTab and currentTab.Load and currentTab.TabFrame then
            currentTab.Load(self, currentTab.TabFrame)
            currentTab.IsLoaded = true

            currentTab.TabFrame:Show()
            self:UpdateCategoryButtonSelection()
        end
    end

    self:InitializeLocalizedText()
    self:AnchorStatusToContentColumn()
end

--[[
    Put the feedback line under the content column.

    Done here rather than in XML because Status is a Layer FontString and layers are created before
    frames: it cannot reference the TabUI column it belongs under from the markup.
]]
function SettingsMixin:AnchorStatusToContentColumn()
    if not self.Status or not self.TabUI then
        return
    end

    self.Status:ClearAllPoints()
    self.Status:SetPoint("BOTTOMLEFT", self.TabUI, "BOTTOMLEFT", 0, -26)
    self.Status:SetPoint("BOTTOMRIGHT", self.TabUI, "BOTTOMRIGHT", 0, -26)
    self.Status:SetText("")
end

--[[
    Say something in the panel's feedback line, and start it fading.

    @param message [string] Already-localised text; an empty message clears the line
]]
function SettingsMixin:ShowStatus(message)
    if not self.Status then
        return
    end

    if self.StatusFadeOut then
        self.StatusFadeOut:Stop()
    end

    self.Status:SetText(message or "")
    self.Status:SetAlpha(1)

    if message and message ~= "" and self.StatusFadeOut then
        self.StatusFadeOut:Play()
    end
end

function SettingsMixin:InitializeLocalizedText()
    if self.CategoriesList and self.CategoriesList.Header then
        -- The panel's own name, now that "Settings" is a header rather than a category button
        self.CategoriesList.Header:SetText(Locale["Settings"])
    end

    if self.TabUI and self.TabUI.EventTypes then
        local eventTypes = self.TabUI.EventTypes
        if eventTypes.Title then
            eventTypes.Title:SetText(Locale["Event Types"])
        end
        if eventTypes.Description then
            eventTypes.Description:SetText(Locale["EventTypesDescription"])
        end
    end

    if self.TabUI and self.TabUI.Collections then
        local collections = self.TabUI.Collections
        if collections.Title then
            collections.Title:SetText(Locale["Event Collections"])
        end
        if collections.Description then
            collections.Description:SetText(Locale["CollectionsDescription"])
        end
    end
end

function SettingsMixin:UpdateTabs()
    local currentTab = self.TabUI.currentTab
    if not currentTab then
        for key, _ in pairs(self.TabUI.Tabs) do
            self:OnSettingsTabSelected(key)
            break
        end
    end
end

function SettingsMixin:UpdateCategoryButtonSelection()
    local currentTab = self.TabUI.currentTab
    if not currentTab then
        return
    end

    for _, button in pairs(self.Buttons) do
        if button.category and button.category.TabName == currentTab then
            button:SetSelected(true)
        else
            button:SetSelected(false)
        end
    end
end

function SettingsMixin:OnSettingsTabSelected(tabNameOrData)
    local tabName = tabNameOrData
    if type(tabNameOrData) == "table" then
        if tabNameOrData.tabName then
            tabName = tabNameOrData.tabName
        else
            return
        end
    elseif type(tabNameOrData) ~= "string" then
        return
    end

    if not self.TabUI then
        return
    end

    self.TabUI.currentTab = tabName
    for key, tab in pairs(self.TabUI.Tabs or {}) do
        if tab.TabFrame then
            if type(tab.Load) == "function" and not tab.IsLoaded then
                local success, errorMsg = pcall(tab.Load, self, tab.TabFrame)
                if success then
                    tab.IsLoaded = true
                else
                    geterrorhandler()(errorMsg)
                end
            end

            local isSelected = (key == tabName)
            if type(tab.TabFrame.SetShown) == "function" then
                pcall(tab.TabFrame.SetShown, tab.TabFrame, isSelected)
            end

            if isSelected then
                local scrollFrame = tab.TabFrame.ScrollFrame
                local content = scrollFrame and scrollFrame.Content
                if content and content.checkboxes and #content.checkboxes > 0 then
                    local totalHeight = SettingsMixin.ComputeCheckboxContentHeight(#content.checkboxes)
                    if type(content.SetSize) == "function" and type(scrollFrame.GetWidth) == "function" then
                        pcall(content.SetSize, content, scrollFrame:GetWidth() - 20, totalHeight)
                    end
                end
            end
        end
    end
end

function SettingsMixin:GetVisibleCategories(categories)
    local visibleCategories = {}

    for index, category in ipairs(categories) do
        category.index = index
        category.level = 1
        table.insert(visibleCategories, category)

        if category.subMenu then
            for j, subCategory in ipairs(category.subMenu) do
                subCategory.level = 2
                table.insert(visibleCategories, subCategory)
            end
        end
    end

    return visibleCategories
end

function SettingsMixin:AddCategory(index, category)
    local categoryButton = CreateFrame("Button", nil, self.CategoriesList, "CategoryButtonTemplate")

    -- Flat: no per-level indent, because there are no levels any more. The rows stack under the rail's
    -- header separator, spanning the rail's full width like the bookmark rows on the content tabs.
    if index == 1 then
        categoryButton:SetPoint("TOPLEFT", self.CategoriesList.HeaderSeparator, "BOTTOMLEFT", 0, -8)
        categoryButton:SetPoint("TOPRIGHT", self.CategoriesList.HeaderSeparator, "BOTTOMRIGHT", 0, -8)
    else
        local previous = self.Buttons[self.prefix .. (index - 1)]
        categoryButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4) -- Spacing.xs
        categoryButton:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -4)
    end

    categoryButton:SetData(category, index)
    self.Buttons[self.prefix .. index] = categoryButton
end

-- =============================================================================================
-- CHECKBOX COLUMN LAYOUT
-- =============================================================================================

--[[
    Two columns, because one column of 15 collections scrolled a page that had room for all of them
    twice over. Seven event types become 4 + 3; fifteen collections become 8 + 7 and stop scrolling.

    The pitch numbers live here, once. The scroll range is derived from the same constants by
    ComputeCheckboxContentHeight: three separate places used to compute a one-column height, and a
    height that disagrees with the content hides the scroll bar while the content is still clipped.
]]
local CHECKBOX_COLUMNS = 2
local CHECKBOX_ROW_PITCH = 33
local CHECKBOX_COLUMN_PITCH = 380
local CHECKBOX_TOP_OFFSET = -15
local CHECKBOX_CONTENT_PADDING = 30
local CHECKBOX_MIN_HEIGHT = 200

--[[
    Place one checkbox container in the grid.

    @param content [table] The scroll child every container is parented to
    @param container [table] The container frame to place
    @param index [number] 1-based position in the list, filling left to right then down
]]
local function placeCheckboxContainer(content, container, index)
    local column = (index - 1) % CHECKBOX_COLUMNS
    local row = math.floor((index - 1) / CHECKBOX_COLUMNS)

    container:ClearAllPoints()
    container:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        column * CHECKBOX_COLUMN_PITCH,
        CHECKBOX_TOP_OFFSET - row * CHECKBOX_ROW_PITCH
    )
end

--[[
    Scroll-child height for a given number of checkboxes.

    @param count [number] Checkboxes on the page
    @return [number] Height in pixels
]]
function SettingsMixin.ComputeCheckboxContentHeight(count)
    local rows = math.ceil((count or 0) / CHECKBOX_COLUMNS)
    return math.max(CHECKBOX_MIN_HEIGHT, rows * CHECKBOX_ROW_PITCH + CHECKBOX_CONTENT_PADDING)
end

--[[
    Show the rule between the two columns, sized to the rows that are actually there.

    Hidden for a page with a single column's worth of entries: a divider with nothing on its right is
    a line for its own sake.

    @param frame [table] The settings page
    @param count [number] Checkboxes on the page
]]
local function updateColumnDivider(frame, count)
    local divider = frame and frame.ColumnDivider
    if not divider then
        return
    end

    if (count or 0) <= CHECKBOX_COLUMNS - 1 then
        divider:Hide()
        return
    end

    local rows = math.ceil(count / CHECKBOX_COLUMNS)
    divider:SetHeight(math.max(CHECKBOX_ROW_PITCH, rows * CHECKBOX_ROW_PITCH))
    divider:ClearAllPoints()
    divider:SetPoint("TOP", frame.Description, "BOTTOM", CHECKBOX_COLUMN_PITCH / 2, -10)
    divider:Show()
end

--[[
    How many events each event type would add or remove.

    Answers "what does this checkbox do" where the checkbox is, rather than leaving the reader to
    toggle it and go looking. Computed once per LoadEventTypes rather than per toggle: it walks every
    registered collection, and the number does not change while the panel is open.

    Counts across *all* collections regardless of whether a collection is currently enabled, because the
    number describes the event type, not the current filter state. Returns an empty table when the data
    layer is not reachable, so the labels simply carry no count rather than a zero that looks like a fact.

    @return [table] eventTypeId to count
]]
function SettingsMixin:CountEventsByType()
    local counts = {}
    local data = Chronicles and Chronicles.Data

    if not data or type(data.Events) ~= "table" then
        return counts
    end

    for _, eventsGroup in pairs(data.Events) do
        if eventsGroup and eventsGroup.data then
            for _, event in pairs(eventsGroup.data) do
                if event and event.eventType then
                    counts[event.eventType] = (counts[event.eventType] or 0) + 1
                end
            end
        end
    end

    return counts
end

function SettingsMixin:OnSettingsEventTypeChecked(eventData)
    if not eventData or not eventData.eventTypeId then
        return
    end

    local eventTypeId = eventData.eventTypeId
    local isActive = eventData.isActive
    local settingsKey = private.Core.StateManager.buildSettingsKey("eventType", eventTypeId)

    private.Core.StateManager.setState(settingsKey, isActive, "Event type setting changed")

    private.Core.Cache.invalidateForDataChange("events")

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsEventTypeChecked")

    self:ReportTimelineEmptiness()
end

--[[
    Say something if the toggle just emptied the timeline.

    The handlers above recompute the timeline behind the settings panel, where the reader cannot see it.
    Without this, the only evidence that a toggle emptied the current page is a blank rail on the Events
    tab minutes later.
]]
function SettingsMixin:ReportTimelineEmptiness()
    local business = private.Core.Data and private.Core.Data.TimelineBusiness
    if not business or not business.computeTimelinePeriods then
        return
    end

    local ok, periods = pcall(business.computeTimelinePeriods)
    if not ok then
        return
    end

    local hasAnyEvents = false
    for _, period in ipairs(periods or {}) do
        if period and period.hasEvents then
            hasAnyEvents = true
            break
        end
    end

    if not hasAnyEvents then
        self:ShowStatus(Locale["SettingsTimelineNowEmpty"])
    else
        self:ShowStatus("")
    end
end

function SettingsMixin:OnSettingsCollectionChecked(eventData)
    if not eventData or not eventData.collectionName then
        return
    end

    local collectionName = eventData.collectionName
    local isActive = eventData.isActive

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    private.Core.StateManager.setState(collectionKey, isActive, "Collection setting changed")

    -- Enabling or disabling a collection moves events, characters, factions,
    -- the collection list and the timeline bounds all at once.
    private.Core.Cache.invalidateForDataChange("all")

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsCollectionChecked")

    self:ReportTimelineEmptiness()
end

function SettingsMixin:LoadEventTypes(frame)
    local scrollFrame = frame.ScrollFrame
    if not scrollFrame then
        return
    end

    local content = scrollFrame.Content
    if not content then
        return
    end
    content.checkboxes = content.checkboxes or {}

    -- Use UIUtils for cleanup
    local UIUtils = private.Core.Utils.UIUtils
    if UIUtils then
        UIUtils.CleanupElementArray(content.checkboxes)
    else
        -- Fallback cleanup
        for i = #content.checkboxes, 1, -1 do
            if content.checkboxes[i] then
                content.checkboxes[i]:Hide()
                content.checkboxes[i]:SetParent(nil)
            end
        end
        content.checkboxes = {}
    end
    if not private.constants or not private.constants.eventType then
        return
    end

    -- Counted once per load, not per toggle: the same data the toggle handler goes on to invalidate
    local eventCounts = self:CountEventsByType()

    for eventTypeId, eventTypeName in ipairs(private.constants.eventType) do
        local text = Locale[eventTypeName]
        local affected = eventCounts[eventTypeId]
        if affected then
            text = string.format(Locale["SettingsEventTypeCount"], text, affected)
        end

        local checkboxContainer = CreateFrame("Frame", nil, content)
        checkboxContainer:SetSize(CHECKBOX_COLUMN_PITCH - 20, 28)

        local newCheckbox = CreateFrame("CheckButton", nil, checkboxContainer, "ChroniclesSettingsCheckboxTemplate")
        newCheckbox:SetPoint("LEFT", 10, 0)
        newCheckbox.Text:SetText(text)
        newCheckbox.eventTypeId = eventTypeId
        newCheckbox.eventTypeName = eventTypeName

        local currentStatus = Chronicles.Data:GetEventTypeStatus(eventTypeId)

        newCheckbox:SetChecked(currentStatus)

        checkboxContainer:SetScript(
            "OnEnter",
            function(self)
                newCheckbox:LockHighlight()
            end
        )
        checkboxContainer:SetScript(
            "OnLeave",
            function(self)
                newCheckbox:UnlockHighlight()
            end
        )
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local eventData = {
                    eventTypeId = self.eventTypeId,
                    isActive = self:GetChecked()
                }
                private.Core.triggerEvent(
                    private.constants.events.SettingsEventTypeChecked,
                    eventData,
                    "Settings:EventTypeCheckbox"
                )
            end
        )

        table.insert(content.checkboxes, checkboxContainer)
        placeCheckboxContainer(content, checkboxContainer, #content.checkboxes)
        checkboxContainer:Show()
    end

    local totalHeight = SettingsMixin.ComputeCheckboxContentHeight(#content.checkboxes)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)
    updateColumnDivider(frame, #content.checkboxes)

    if type(self.UpdateScrollIndicators) == "function" then
        pcall(function()
            self:UpdateScrollIndicators(scrollFrame)
        end)
    end

    -- Reset the view to the top. The bar here is the modern ScrollBox-style scroll bar created by
    -- ScrollFrameMixin (driven by SetScrollPercentage and the OnScrollRangeChanged callback), not an
    -- old Slider, so it has no SetMinMaxValues/SetValue. Resizing the content above already made the
    -- ScrollFrame recompute the bar's range, and SetHideIfUnscrollable (set in the mixin's OnLoad)
    -- hides it when there is nothing to scroll; the only thing left to do is scroll back to the top.
    if type(scrollFrame.SetVerticalScroll) == "function" then
        scrollFrame:SetVerticalScroll(0)
    end

    content:Show()
    scrollFrame:Show()
end

function SettingsMixin:LoadCollections(frame)
    local scrollFrame = frame.ScrollFrame
    if not scrollFrame then
        return
    end

    local content = scrollFrame.Content
    if not content then
        return
    end
    content.checkboxes = content.checkboxes or {}

    -- Use UIUtils for cleanup
    local UIUtils = private.Core.Utils.UIUtils
    if UIUtils then
        UIUtils.CleanupElementArray(content.checkboxes)
    else
        -- Fallback cleanup
        for i = #content.checkboxes, 1, -1 do
            if content.checkboxes[i] then
                content.checkboxes[i]:Hide()
                content.checkboxes[i]:SetParent(nil)
            end
        end
        content.checkboxes = {}
    end

    local collections = private.Core.Cache.getCollectionsNames()
    for _, collection in ipairs(collections) do
        local collectionName = collection.name
        local text = Locale[collectionName] or collectionName
        local checkboxContainer = CreateFrame("Frame", nil, content)
        checkboxContainer:SetSize(CHECKBOX_COLUMN_PITCH - 20, 28)

        local newCheckbox = CreateFrame("CheckButton", nil, checkboxContainer, "ChroniclesSettingsCheckboxTemplate")
        newCheckbox:SetPoint("LEFT", 10, 0)
        newCheckbox.Text:SetText(text)
        newCheckbox.collectionName = collectionName

        newCheckbox:SetChecked(Chronicles.Data:GetCollectionStatus(collectionName))
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local eventData = {
                    collectionName = self.collectionName,
                    isActive = self:GetChecked()
                }

                private.Core.triggerEvent(
                    private.constants.events.SettingsCollectionChecked,
                    eventData,
                    "Settings:CollectionCheckbox"
                )
            end
        )

        table.insert(content.checkboxes, checkboxContainer)
        placeCheckboxContainer(content, checkboxContainer, #content.checkboxes)
        checkboxContainer:Show()
    end

    local totalHeight = SettingsMixin.ComputeCheckboxContentHeight(#content.checkboxes)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)
    updateColumnDivider(frame, #content.checkboxes)

    content:Show()
    scrollFrame:Show()
end

CategoryButtonMixin = {}

function CategoryButtonMixin:OnLoad()
    -- Initialize the button with default properties
    self.isSelected = false

    -- Set up default text properties if text exists
    if self.Text then
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    -- Initialize selection state textures. SelectedGlow, not SelectedTexture: the button draws the
    -- same bookmark art and the same additive selected pass as every rail row in the window, rather
    -- than the auction house's nav-button atlases it used to borrow.
    if self.SelectedGlow then
        self.SelectedGlow:Hide()
    end
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end
end

function CategoryButtonMixin:OnEnter()
    if self.HighlightTexture then
        self.HighlightTexture:Show()
    end

    -- Enhanced text coloring on hover. The literal here was (1.0, 1.0, 0.8), a faint warm white with
    -- no global equivalent; HIGHLIGHT_FONT_COLOR is the nearest one and the shift is not perceptible
    -- against the gold selected state it sits between.
    if self.Text then
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
end

function CategoryButtonMixin:OnLeave()
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end

    -- Reset text color based on selection state
    if self.Text then
        if self.isSelected then
            self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        else
            self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        end
    end
end

function CategoryButtonMixin:OnClick()
    -- Handle tab selection if this category has a TabName
    if self.category and self.category.TabName then -- Update state instead of calling method directly - provides single source of truth
        if private.Core.StateManager then
            private.Core.StateManager.setState(
                private.Core.StateManager.buildUIStateKey("settingsCategory"),
                self.category.TabName,
                "Settings tab selected from category button"
            )
        end

        -- Update visual selection state for all category buttons
        self:UpdateCategorySelection()
    end
end

function CategoryButtonMixin:UpdateCategorySelection()
    local settingsFrame = self:GetParent():GetParent()
    if not settingsFrame or not settingsFrame.Buttons then
        return
    end

    -- Clear selection from all buttons
    for _, button in pairs(settingsFrame.Buttons) do
        if button.SetSelected then
            button:SetSelected(false)
        end
    end

    -- Set this button as selected
    self:SetSelected(true)
end

function CategoryButtonMixin:SetData(category, index)
    self.category = category
    self.index = index

    -- Set the button text
    if self.Text then
        self.Text:SetText(category.text)
    end

    -- Store any additional category properties
    self.eventTypeId = category.eventTypeId
end

function CategoryButtonMixin:SetSelected(selected)
    self.isSelected = selected

    if self.SelectedGlow then
        self.SelectedGlow:SetShown(selected)
    end

    if self.Text then
        if selected then
            self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        else
            self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        end
    end
end
