local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
=================================================================================
Module: Settings UI
Purpose: User preferences and configuration interface management
Dependencies: AceLocale-3.0, StateManager, Core.Settings
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
- State changes propagate to FilterEngine and Data modules

Dependencies:
- AceLocale-3.0: UI text localization
- StateManager: Settings persistence
- Core.Settings: Configuration data management
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
    self.ConfiguredCategories = {
        {
            text = Locale["Settings"],
            TabName = "SettingsHome",
            TabFrame = self.TabUI.SettingsHome,
            Load = self.LoadSettingsHome,
            subMenu = {
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
        local activeTabKey = private.Core.StateManager.buildUIStateKey("activeTab")
        private.Core.StateManager.subscribe(
            activeTabKey,
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
end

function SettingsMixin:InitializeLocalizedText()
    if self.CategoriesList and self.CategoriesList.Header then
        self.CategoriesList.Header:SetText(Locale["Configuration"])
    end

    if self.TabUI and self.TabUI.SettingsHome then
        local settingsHome = self.TabUI.SettingsHome

        if settingsHome.Title then
            settingsHome.Title:SetText(Locale["Settings"])
        end
        if settingsHome.Description then
            settingsHome.Description:SetText(Locale["SettingsHomeDescription"])
        end

        if settingsHome.OverviewSection then
            local overview = settingsHome.OverviewSection
            if overview.SectionTitle then
                overview.SectionTitle:SetText(Locale["SettingsHomeOverviewSectionTitle"])
            end
            if overview.EventTypesInfo then
                overview.EventTypesInfo:SetText(Locale["SettingsHomeOverviewEventTypesInfo"])
            end
            if overview.CollectionsInfo then
                overview.CollectionsInfo:SetText(Locale["SettingsHomeOverviewCollectionsInfo"])
            end
        end

        if settingsHome.QuickActionsSection then
            local quickActions = settingsHome.QuickActionsSection
            if quickActions.SectionTitle then
                quickActions.SectionTitle:SetText(Locale["SettingsHomeQuickActionsSectionTitle"])
            end
            if quickActions.Tip1 then
                quickActions.Tip1:SetText(Locale["SettingsHomeQuickActionsTip1"])
            end
            if quickActions.Tip2 then
                quickActions.Tip2:SetText(Locale["SettingsHomeQuickActionsTip2"])
            end
            if quickActions.Tip3 then
                quickActions.Tip3:SetText(Locale["SettingsHomeQuickActionsTip3"])
            end
        end

        if settingsHome.VersionSection then
            local version = settingsHome.VersionSection
            if version.SectionTitle then
                version.SectionTitle:SetText(Locale["SettingsHomeVersionSectionTitle"])
            end
            if version.VersionInfo then
                version.VersionInfo:SetText(Locale["SettingsHomeVersionVersionInfo"])
            end
            if version.ConfigNote then
                version.ConfigNote:SetText(Locale["SettingsHomeVersionConfigNote"])
            end
        end
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

    self.TabUI.currentTab = tabName
    for key, tab in pairs(self.TabUI.Tabs) do
        if (tab.Load and tab.TabFrame) then
            if tab.Load and not tab.IsLoaded then
                local success, errorMsg =
                    pcall(
                    function()
                        tab.Load(self, tab.TabFrame)
                    end
                )

                if success then
                    tab.IsLoaded = true
                end
            end
            local isSelected = (key == tabName)
            tab.TabFrame:SetShown(isSelected)

            if isSelected and tab.TabFrame.ScrollFrame and tab.TabFrame.ScrollFrame.Content then
                local scrollFrame = tab.TabFrame.ScrollFrame
                local content = scrollFrame.Content
                if content.checkboxes and #content.checkboxes > 0 then
                    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
                    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)
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
    local initialXoffset = 12
    local initialYoffset = -50
    local xOffset = 8

    local categoryButton = CreateFrame("Button", nil, self.CategoriesList, "CategoryButtonTemplate")

    if index == 1 then
        categoryButton:SetPoint("TOPLEFT", initialXoffset, initialYoffset)
    else
        categoryButton:SetPoint("TOP", self.Buttons[self.prefix .. (index - 1)], "BOTTOM", 0, -3)
        categoryButton:SetPoint("LEFT", initialXoffset + xOffset * category.level, 0)
    end

    categoryButton:SetData(category, index)
    self.Buttons[self.prefix .. index] = categoryButton
end

function SettingsMixin:OnSettingsEventTypeChecked(eventData)
    if not eventData or not eventData.eventTypeId then
        return
    end

    local eventTypeId = eventData.eventTypeId
    local isActive = eventData.isActive
    local settingsKey = private.Core.StateManager.buildSettingsKey("eventType", eventTypeId)

    private.Core.StateManager.setState(settingsKey, isActive, "Event type setting changed")

    Chronicles.Data:RefreshPeriods()
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsEventTypeChecked")
end

function SettingsMixin:OnSettingsCollectionChecked(eventData)
    if not eventData or not eventData.collectionName then
        return
    end

    local collectionName = eventData.collectionName
    local isActive = eventData.isActive

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    private.Core.StateManager.setState(collectionKey, isActive, "Collection setting changed")

    Chronicles.Data:RefreshPeriods()
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsCollectionChecked")
end

function SettingsMixin:LoadSettingsHome(frame)
    if frame then
        frame:Show()
    end
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

    local previousCheckbox = nil
    local yOffset = -15

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
    for eventTypeId, eventTypeName in ipairs(private.constants.eventType) do
        local text = Locale[eventTypeName]

        local checkboxContainer = CreateFrame("Frame", nil, content)
        checkboxContainer:SetSize(400, 28)

        local newCheckbox = CreateFrame("CheckButton", nil, checkboxContainer, "ChroniclesSettingsCheckboxTemplate")
        newCheckbox:SetPoint("LEFT", 10, 0)
        newCheckbox.Text:SetText(text)
        newCheckbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
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

        if previousCheckbox then
            checkboxContainer:SetPoint("TOP", previousCheckbox, "BOTTOM", 0, -5)
        else
            checkboxContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        end
        checkboxContainer:Show()
        table.insert(content.checkboxes, checkboxContainer)
        previousCheckbox = checkboxContainer
    end
    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)

    self:UpdateScrollIndicators(scrollFrame)

    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:SetMinMaxValues(0, math.max(scrollFrame:GetVerticalScrollRange(), 1))
        scrollFrame.ScrollBar:SetValue(0)
        if scrollFrame.scrollBarHideIfUnscrollable then
            scrollFrame.ScrollBar:SetShown(scrollFrame:GetVerticalScrollRange() > 0)
        else
            scrollFrame.ScrollBar:Show()
        end
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

    local previousCheckbox = nil
    local yOffset = -15

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
        checkboxContainer:SetSize(400, 28)

        local newCheckbox = CreateFrame("CheckButton", nil, checkboxContainer, "ChroniclesSettingsCheckboxTemplate")
        newCheckbox:SetPoint("LEFT", 10, 0)
        newCheckbox.Text:SetText(text)
        newCheckbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
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

        if previousCheckbox then
            checkboxContainer:SetPoint("TOP", previousCheckbox, "BOTTOM", 0, -5)
        else
            checkboxContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        end
        checkboxContainer:Show()
        table.insert(content.checkboxes, checkboxContainer)
        previousCheckbox = checkboxContainer
    end

    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)
end

CategoryButtonMixin = {}

function CategoryButtonMixin:OnLoad()
    -- Initialize the button with default properties
    self.isSelected = false

    -- Set up default text properties if text exists
    if self.Text then
        self.Text:SetTextColor(0.9, 0.9, 0.9) -- Default white text
    end

    -- Initialize selection state textures
    if self.SelectedTexture then
        self.SelectedTexture:Hide()
    end
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end
end

function CategoryButtonMixin:OnEnter()
    if self.HighlightTexture then
        self.HighlightTexture:Show()
    end

    -- Enhanced text coloring on hover
    if self.Text then
        self.Text:SetTextColor(1.0, 1.0, 0.8) -- Slight golden tint
    end
end

function CategoryButtonMixin:OnLeave()
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end

    -- Reset text color based on selection state
    if self.Text then
        if self.isSelected then
            self.Text:SetTextColor(1.0, 0.82, 0.0) -- Gold for selected
        else
            self.Text:SetTextColor(0.9, 0.9, 0.9) -- Default white
        end
    end
end

function CategoryButtonMixin:OnClick()
    -- Handle tab selection if this category has a TabName
    if self.category and self.category.TabName then -- Update state instead of calling method directly - provides single source of truth
        if private.Core.StateManager then
            private.Core.StateManager.setState(
                private.Core.StateManager.buildUIStateKey("activeTab"),
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

    if selected then
        if self.SelectedTexture then
            self.SelectedTexture:Show()
        end
        if self.Text then
            self.Text:SetTextColor(1.0, 0.82, 0.0) -- Gold for selected
        end
    else
        if self.SelectedTexture then
            self.SelectedTexture:Hide()
        end
        if self.Text then
            self.Text:SetTextColor(0.9, 0.9, 0.9) -- Default white
        end
    end
end
