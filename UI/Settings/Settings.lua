local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- Event types
-- Collections
-- My journal
SettingsMixin = {}

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
        },
        {
            text = Locale["My Journal"],
            TabName = "MyJournal",
            TabFrame = self.TabUI.MyJournal,
            Load = self.LoadMyJournal
        },
        {
            text = Locale["Logs"] or "Logs",
            TabName = "Logs",
            TabFrame = self.TabUI.Logs,
            Load = self.LoadLogs
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
    private.Core.registerCallback(private.constants.events.SettingsCollectionChecked, self.OnSettingsCollectionChecked, self)

    -- Use state-based subscription for tab selection
    -- This provides a single source of truth for the active tab
    if private.Core.StateManager then
        private.Core.StateManager.subscribe(
            "ui.activeTab",
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

    -- Initialize localized text
    self:InitializeLocalizedText()
end

function SettingsMixin:InitializeLocalizedText()
    -- Initialize category list header
    if self.CategoriesList and self.CategoriesList.Header then
        self.CategoriesList.Header:SetText(Locale["Configuration"])
    end

    -- Initialize Settings Home tab
    if self.TabUI and self.TabUI.SettingsHome then
        local settingsHome = self.TabUI.SettingsHome

        if settingsHome.Title then
            settingsHome.Title:SetText(Locale["Settings"])
        end
        if settingsHome.Description then
            settingsHome.Description:SetText(Locale["SettingsHomeDescription"])
        end

        -- Overview Section
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
            if overview.MyJournalInfo then
                overview.MyJournalInfo:SetText(Locale["SettingsHomeOverviewMyJournalInfo"])
            end
        end

        -- Getting Started Section
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

        -- About Section
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

    -- Initialize Event Types tab
    if self.TabUI and self.TabUI.EventTypes then
        local eventTypes = self.TabUI.EventTypes
        if eventTypes.Title then
            eventTypes.Title:SetText(Locale["Event Types"])
        end
        if eventTypes.Description then
            eventTypes.Description:SetText(Locale["EventTypesDescription"])
        end
    end

    -- Initialize Collections tab
    if self.TabUI and self.TabUI.Collections then
        local collections = self.TabUI.Collections
        if collections.Title then
            collections.Title:SetText(Locale["Event Collections"])
        end
        if collections.Description then
            collections.Description:SetText(Locale["CollectionsDescription"])
        end
    end

    -- Initialize My Journal tab
    if self.TabUI and self.TabUI.MyJournal then
        local myJournal = self.TabUI.MyJournal
        if myJournal.Title then
            myJournal.Title:SetText(Locale["My Journal"])
        end
        if myJournal.Description then
            myJournal.Description:SetText(Locale["MyJournalDescription"])
        end

        -- Initialize My Journal checkbox and description
        if myJournal.SettingsContainer and myJournal.SettingsContainer.IsActive then
            local checkbox = myJournal.SettingsContainer.IsActive
            if checkbox.Text then
                checkbox.Text:SetText(Locale["MyJournalCheckboxText"])
            end
            -- Set button text using SetText on the CheckButton
            if checkbox.SetText then
                checkbox:SetText(Locale["MyJournalCheckboxText"])
            end
        end

        if myJournal.SettingsContainer and myJournal.SettingsContainer.FeatureDescription then
            myJournal.SettingsContainer.FeatureDescription:SetText(Locale["SettingsContainerFeatureDescription"])
        end
    end

    -- Initialize Logs tab
    if self.TabUI and self.TabUI.Logs then
        local logs = self.TabUI.Logs
        if logs.Title then
            logs.Title:SetText(Locale["Logs"])
        end
        if logs.Description then
            logs.Description:SetText(Locale["LogsDescription"])
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

    -- Find and select the appropriate category button
    for _, button in pairs(self.Buttons) do
        if button.category and button.category.TabName == currentTab then
            button:SetSelected(true)
        else
            button:SetSelected(false)
        end
    end
end

function SettingsMixin:OnSettingsTabSelected(tabNameOrData)
    -- Handle both string and table format for backward compatibility
    local tabName = tabNameOrData
    if type(tabNameOrData) == "table" then
        if tabNameOrData.tabName then
            tabName = tabNameOrData.tabName
        else
            private.Core.Logger.warn("Settings", "OnSettingsTabSelected - Table format missing 'tabName' property")
            return
        end
    elseif type(tabNameOrData) ~= "string" then
        private.Core.Logger.warn(
            "Settings",
            "OnSettingsTabSelected - Invalid tabNameOrData format: " .. type(tabNameOrData)
        )
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

            -- If we're showing this tab, make sure it's fully initialized
            if isSelected and tab.TabFrame.ScrollFrame and tab.TabFrame.ScrollFrame.Content then
                local scrollFrame = tab.TabFrame.ScrollFrame
                local content = scrollFrame.Content
                -- Ensure content is sized properly
                if content.checkboxes and #content.checkboxes > 0 then
                    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
                    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)
                    self:UpdateScrollIndicators(scrollFrame)
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
    -- Validate event data
    if not eventData or not eventData.eventTypeId then
        private.Core.Logger.warn("Settings", "OnSettingsEventTypeChecked called with invalid eventData")
        return
    end

    -- Extract the event type ID and checked status from the event data
    local eventTypeId = eventData.eventTypeId
    local isActive = eventData.isActive -- Update StateManager for event type status
    local path = "eventTypes." .. tostring(eventTypeId)
    private.Core.StateManager.setState(path, isActive, "Event type setting changed")

    --private.Core.Utils.HelperUtils.getChronicles().Data:SetEventTypeStatus(eventTypeId, isActive)
    private.Core.Utils.HelperUtils.getChronicles().Data:RefreshPeriods()

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsEventTypeChecked")
end

function SettingsMixin:OnSettingsCollectionChecked(eventData)
    -- Validate event data
    if not eventData or not eventData.collectionName then
        private.Core.Logger.warn("Settings", "OnSettingsCollectionChecked called with invalid eventData")
        return
    end

    -- Extract the collection name and checked status from the event data
    local collectionName = eventData.collectionName
    local isActive = eventData.isActive -- Update StateManager for collection status
    local path = "collections." .. collectionName
    private.Core.StateManager.setState(path, isActive, "Collection setting changed")

    private.Core.Utils.HelperUtils.getChronicles().Data:RefreshPeriods()

    -- Invalidate caches when collection status changes
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("searchCache")

    private.Core.Timeline.ComputeTimelinePeriods()
    private.Core.Timeline.DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.UIRefresh, nil, "Settings:OnSettingsCollectionChecked")
end

function SettingsMixin:LoadSettingsHome(frame)
    -- The SettingsHome frame is primarily static content
    -- Just ensure it's visible and properly configured
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

    -- Initialize checkboxes array if it doesn't exist
    content.checkboxes = content.checkboxes or {}

    local previousCheckbox = nil
    local yOffset = -15

    -- Clear any existing content
    for i = #content.checkboxes, 1, -1 do
        if content.checkboxes[i] then
            content.checkboxes[i]:Hide()
            content.checkboxes[i]:SetParent(nil)
        end
    end
    content.checkboxes = {}
    -- Make sure eventType is available
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
        newCheckbox:SetChecked(private.Core.Utils.HelperUtils.getChronicles().Data:GetEventTypeStatus(eventTypeId))

        -- Add hover effect to container
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
    -- Update content size for scrolling
    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)

    -- Update scroll indicators
    self:UpdateScrollIndicators(scrollFrame)

    -- Make sure ScrollFrame is working properly
    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:SetMinMaxValues(0, math.max(scrollFrame:GetVerticalScrollRange(), 1))
        scrollFrame.ScrollBar:SetValue(0) -- Reset to top position
        -- Show scrollbar if needed
        if scrollFrame.scrollBarHideIfUnscrollable then
            scrollFrame.ScrollBar:SetShown(scrollFrame:GetVerticalScrollRange() > 0)
        else
            scrollFrame.ScrollBar:Show()
        end
    end

    -- Force show the content
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

    -- Initialize checkboxes array if it doesn't exist
    content.checkboxes = content.checkboxes or {}

    local previousCheckbox = nil
    local yOffset = -15

    -- Clear any existing content
    for i = #content.checkboxes, 1, -1 do
        if content.checkboxes[i] then
            content.checkboxes[i]:Hide()
            content.checkboxes[i]:SetParent(nil)
        end
    end
    content.checkboxes = {}

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

        newCheckbox:SetChecked(private.Core.Utils.HelperUtils.getChronicles().Data:GetCollectionStatus(collectionName))
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

    -- Update content size for scrolling
    local totalHeight = math.max(200, (#content.checkboxes * 33) + 30)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)

    -- Update scroll indicators
    self:UpdateScrollIndicators(scrollFrame)
end

function SettingsMixin:LoadMyJournal(frame)
    local isActive = frame.SettingsContainer.IsActive

    -- Check if the setting exists in the database
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles.db or not chronicles.db.global or not chronicles.db.global.options then
        chronicles.db = chronicles.db or {}
        chronicles.db.global = chronicles.db.global or {}
        chronicles.db.global.options = chronicles.db.global.options or {}
        chronicles.db.global.options.myjournal = false
    end

    isActive:SetChecked(chronicles.db.global.options.myjournal)

    -- Apply enhanced styling to the checkbox
    isActive.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    isActive.Text:SetTextColor(0.9, 0.9, 0.9)
    isActive:SetScript(
        "OnClick",
        function(self)
            local isChecked = self:GetChecked()
            local chronicles = private.Core.Utils.HelperUtils.getChronicles()

            if not chronicles.db or not chronicles.db.global or not chronicles.db.global.options then
                chronicles.db = chronicles.db or {}
                chronicles.db.global = chronicles.db.global or {}
                chronicles.db.global.options = chronicles.db.global.options or {}
            end
            chronicles.db.global.options.myjournal = isChecked
            private.Core.StateManager.setState(
                "collections." .. private.constants.configurationName.myjournal,
                isChecked,
                "MyJournal setting changed"
            )

            -- Update UI
            if MyJournalViewShow then
                if (isChecked) then
                    MyJournalViewShow:Show()
                else
                    MyJournalViewShow:Hide()
                end
            end
        end
    )
end

function SettingsMixin:LoadLogs(frame)
    private.Core.Logger.trace("Settings", "Loading Logs tab")

    if not frame.LogsContainer then
        private.Core.Logger.warn("Settings", "LogsContainer not found in frame")
        return
    end

    local container = frame.LogsContainer

    -- Initialize log level controls
    if container.LogLevelContainer then
        self:InitializeLogLevelControls(container.LogLevelContainer)
    end

    -- Initialize log display
    if container.LogDisplayContainer then
        self:InitializeLogDisplay(container.LogDisplayContainer)
    end

    -- Initialize control buttons
    if container.ControlsContainer then
        self:InitializeLogControls(container.ControlsContainer)
    end

    -- Load initial log data
    self:RefreshLogDisplay(frame)
end

function SettingsMixin:InitializeLogLevelControls(container)
    if not container.LogLevelDropdown then
        return
    end
    local dropdown = container.LogLevelDropdown
    local levels = {"TRACE", "WARN", "ERROR"}
    local currentLevel = "WARN" -- Default fallback

    -- Safely get current log level
    if private.Core.Logger.getLogLevel then
        local success, level = pcall(private.Core.Logger.getLogLevel)
        if success and level then
            currentLevel = level
        end
    end

    -- Initialize the dropdown menu
    local function InitializeDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for i, logLevel in ipairs(levels) do
            info.text = logLevel
            info.value = logLevel
            info.func = function()
                if private.Core.Logger.setLogLevel then
                    private.Core.Logger.setLogLevel(logLevel)
                    UIDropDownMenu_SetText(dropdown, logLevel)
                    private.Core.Logger.trace("Settings", "Log level changed to: " .. logLevel)
                    -- Refresh the log display to apply new filter
                    local settingsFrame = dropdown:GetParent():GetParent():GetParent():GetParent()
                    if settingsFrame and settingsFrame.RefreshLogDisplay then
                        settingsFrame:RefreshLogDisplay(settingsFrame.TabUI.Logs)
                    end
                end
            end
            info.checked = (logLevel == currentLevel)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    -- Initialize the dropdown
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    UIDropDownMenu_SetText(dropdown, currentLevel)
    UIDropDownMenu_SetWidth(dropdown, 100)

    -- Set up enable/disable checkbox
    if container.EnabledCheckbox then
        local checkbox = container.EnabledCheckbox
        local isEnabled = private.Core.Logger.isEnabled and private.Core.Logger.isEnabled() or true
        checkbox:SetChecked(isEnabled)
        checkbox:SetScript(
            "OnClick",
            function(self)
                local isChecked = self:GetChecked()
                if private.Core.Logger.setEnabled then
                    private.Core.Logger.setEnabled(isChecked)
                    private.Core.Logger.trace("Settings", "Logger " .. (isChecked and "enabled" or "disabled"))
                end
            end
        )
    end
end

function SettingsMixin:InitializeLogDisplay(container)
    if not container.ScrollFrame then
        return
    end

    local scrollFrame = container.ScrollFrame
    local content = scrollFrame.Content

    if not content then
        return
    end

    -- Initialize log entries array
    content.logEntries = content.logEntries or {}

    -- Clear existing entries
    for i = #content.logEntries, 1, -1 do
        if content.logEntries[i] then
            content.logEntries[i]:Hide()
            content.logEntries[i]:SetParent(nil)
        end
    end
    content.logEntries = {}
end

function SettingsMixin:InitializeLogControls(container)
    -- Store reference to the settings frame for callbacks
    local settingsFrame = self

    -- Refresh button
    if container.RefreshButton then
        container.RefreshButton:SetScript(
            "OnClick",
            function()
                settingsFrame:RefreshLogDisplay(settingsFrame.TabUI.Logs)
            end
        )
    end

    -- Clear logs button
    if container.ClearButton then
        container.ClearButton:SetScript(
            "OnClick",
            function()
                if private.Core.Logger.clearLogHistory then
                    private.Core.Logger.clearLogHistory()
                    settingsFrame:RefreshLogDisplay(settingsFrame.TabUI.Logs)
                    private.Core.Logger.trace("Settings", "Log history cleared from UI")
                end
            end
        )
    end
end

function SettingsMixin:RefreshLogDisplay(frame)
    if not frame.LogsContainer or not frame.LogsContainer.LogDisplayContainer then
        return
    end

    local container = frame.LogsContainer.LogDisplayContainer
    local scrollFrame = container.ScrollFrame
    local content = scrollFrame.Content

    if not content then
        return
    end
    -- Get recent log history (last 100 entries)
    local logHistory = {}
    if private.Core.Logger.getLogHistory then
        logHistory = private.Core.Logger.getLogHistory(100)
    else
        -- Fallback: create sample entries if Logger doesn't have getLogHistory
        logHistory = {
            {level = "TRACE", module = "Settings", message = "Logs tab initialized", timestamp = time()},
            {level = "TRACE", module = "Core", message = "Logger system ready", timestamp = time()},
            {
                level = "WARN",
                module = "Settings",
                message = "No log history available - using sample data",
                timestamp = time()
            }
        }
    end

    -- Get current log level filter from dropdown
    local currentLogLevel = private.Core.Logger.getLogLevel and private.Core.Logger.getLogLevel() or "WARN"
    local logLevels = {TRACE = 1, WARN = 2, ERROR = 3}
    local minLevel = logLevels[currentLogLevel] or 3

    -- Filter log history based on current log level
    local filteredHistory = {}
    for _, logEntry in ipairs(logHistory) do
        local entryLevel = logLevels[logEntry.level] or 3
        if entryLevel >= minLevel then
            table.insert(filteredHistory, logEntry)
        end
    end

    -- Clear existing entries
    for i = #content.logEntries, 1, -1 do
        if content.logEntries[i] then
            content.logEntries[i]:Hide()
            content.logEntries[i]:SetParent(nil)
        end
    end
    content.logEntries = {}

    -- Create status header
    local statusFrame = CreateFrame("Frame", nil, content)
    statusFrame:SetSize(content:GetWidth() - 40, 25)
    statusFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -5)

    local statusText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", statusFrame, "LEFT", 0, 0)
    statusText:SetText(string.format("Showing %d entries (Level: %s and above)", #filteredHistory, currentLogLevel))
    statusText:SetTextColor(0.7, 0.7, 0.9)

    table.insert(content.logEntries, statusFrame)

    local previousEntry = statusFrame
    local yOffset = -10 -- Create log entry frames
    if #filteredHistory > 0 then
        for i, logEntry in ipairs(filteredHistory) do
            local entryFrame = self:CreateLogEntryFrame(content, logEntry)

            if previousEntry then
                entryFrame:SetPoint("TOP", previousEntry, "BOTTOM", 0, -2)
            else
                entryFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
            end

            entryFrame:Show()
            table.insert(content.logEntries, entryFrame)
            previousEntry = entryFrame
        end
    else
        -- Show "no logs" message
        local noLogsFrame = CreateFrame("Frame", nil, content)
        noLogsFrame:SetSize(content:GetWidth() - 40, 30)
        noLogsFrame:SetPoint("TOP", previousEntry, "BOTTOM", 0, -20)

        local noLogsText = noLogsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noLogsText:SetPoint("CENTER", noLogsFrame, "CENTER", 0, 0)
        noLogsText:SetText("No log entries match the current filter level.")
        noLogsText:SetTextColor(0.6, 0.6, 0.6)

        table.insert(content.logEntries, noLogsFrame)
        previousEntry = noLogsFrame
    end

    -- Update content size for scrolling
    local totalHeight = math.max(200, (#content.logEntries * 25) + 40)
    content:SetSize(scrollFrame:GetWidth() - 20, totalHeight)

    -- Update scroll indicators
    self:UpdateScrollIndicators(scrollFrame)
    private.Core.Logger.trace(
        "Settings",
        "Refreshed log display with " .. #filteredHistory .. " entries (filtered from " .. #logHistory .. " total)"
    )
end

function SettingsMixin:CreateLogEntryFrame(parent, logEntry)
    local entryFrame = CreateFrame("Frame", nil, parent)
    entryFrame:SetSize(parent:GetWidth() - 40, 20)

    -- Level indicator
    local levelText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("LEFT", entryFrame, "LEFT", 5, 0)
    levelText:SetWidth(50)
    levelText:SetJustifyH("LEFT")
    levelText:SetText(logEntry.level or "INFO")

    -- Color level text based on log level
    local colors = {
        TRACE = {0.0, 1.0, 1.0},
        WARN = {1.0, 1.0, 0.0},
        ERROR = {1.0, 0.0, 0.0}
    }

    local color = colors[logEntry.level] or {1.0, 1.0, 1.0}
    levelText:SetTextColor(color[1], color[2], color[3])

    -- Module text
    local moduleText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moduleText:SetPoint("LEFT", levelText, "RIGHT", 5, 0)
    moduleText:SetWidth(80)
    moduleText:SetJustifyH("LEFT")
    moduleText:SetText(logEntry.module or "Unknown")
    moduleText:SetTextColor(0.8, 0.8, 1.0)

    -- Message text
    local messageText = entryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    messageText:SetPoint("LEFT", moduleText, "RIGHT", 5, 0)
    messageText:SetPoint("RIGHT", entryFrame, "RIGHT", -5, 0)
    messageText:SetJustifyH("LEFT")
    messageText:SetText(logEntry.message or "")
    messageText:SetTextColor(0.9, 0.9, 0.9)

    -- Timestamp tooltip
    entryFrame:SetScript(
        "OnEnter",
        function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Log Entry Details", 1, 1, 1)
            GameTooltip:AddLine("Timestamp: " .. date("%Y-%m-%d %H:%M:%S", logEntry.timestamp or time()), 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Level: " .. (logEntry.level or "INFO"), color[1], color[2], color[3])
            GameTooltip:AddLine("Module: " .. (logEntry.module or "Unknown"), 0.8, 0.8, 1.0)
            GameTooltip:AddLine("Message: " .. (logEntry.message or ""), 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end
    )

    entryFrame:SetScript(
        "OnLeave",
        function(self)
            GameTooltip:Hide()
        end
    )

    return entryFrame
end

function SettingsMixin:UpdateScrollIndicators(scrollFrame)
    if not scrollFrame or not scrollFrame.ScrollBar then
        return
    end

    local scrollBar = scrollFrame.ScrollBar
    local content = scrollFrame.Content

    if content and scrollFrame then
        local contentHeight = content:GetHeight() or 0
        local frameHeight = scrollFrame:GetHeight() or 0

        -- Show/hide scroll bar based on content overflow
        if contentHeight > frameHeight then
            scrollBar:Show()
            scrollBar:SetAlpha(0.8)
        else
            scrollBar:Hide()
        end
    end
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
    if self.category and self.category.TabName then
        -- Update state instead of calling method directly - provides single source of truth
        if private.Core.StateManager then
            private.Core.StateManager.setState(
                "ui.activeTab",
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

-- function CategoryButtonMixin:GetData()
--     return self.category, self.index
-- end

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
