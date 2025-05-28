local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- Event types
-- Libraries
-- My journal
SettingsMixin = {}

function SettingsMixin:OnLoad()
    self.prefix = "Entry"
    self.ConfiguredCategories = {
        {
            text = "Settings",
            TabName = "SettingsHome",
            TabFrame = self.TabUI.SettingsHome,
            Load = self.LoadSettingsHome,
            subMenu = {
                {
                    text = "Event types",
                    TabName = "EventTypes",
                    TabFrame = self.TabUI.EventTypes,
                    Load = self.LoadEventTypes
                },
                {
                    text = "Libraries",
                    TabName = "Libraries",
                    TabFrame = self.TabUI.Libraries,
                    Load = self.LoadLibraries
                }
            }
        },
        {
            text = "My Journal",
            TabName = "MyJournal",
            TabFrame = self.TabUI.MyJournal,
            Load = self.LoadMyJournal
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

    private.Core.registerCallback(private.constants.events.SettingsTabSelected, self.OnSettingsTabSelected, self)
    private.Core.registerCallback(
        private.constants.events.SettingsEventTypeChecked,
        self.OnSettingsEventTypeChecked,
        self
    )
    private.Core.registerCallback(private.constants.events.SettingsLibraryChecked, self.OnSettingsLibraryChecked, self)

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
    if type(tabNameOrData) == "table" and tabNameOrData.tabName then
        tabName = tabNameOrData.tabName
    else
        print("SettingsMixin:OnSettingsTabSelected - Invalid tabNameOrData format")
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

function SettingsMixin:OnSettingsEventTypeChecked(eventTypeId, checked)
    Chronicles.Data:SetEventTypeStatus(eventTypeId, checked)
    Chronicles.Data:RefreshPeriods()

    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.TimelineClean, nil, "Settings:OnSettingsEventTypeChecked")
end

function SettingsMixin:OnSettingsLibraryChecked(libraryId, checked)
    Chronicles.Data:SetLibraryStatus(libraryId, checked)
    Chronicles.Data:RefreshPeriods()

    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()

    private.Core.triggerEvent(private.constants.events.TimelineClean, nil, "Settings:OnSettingsLibraryChecked")
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
        newCheckbox:SetChecked(Chronicles.Data:GetEventTypeStatus(eventTypeId))

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

function SettingsMixin:LoadLibraries(frame)
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

    local libraries = Chronicles.Data:GetLibrariesNames()
    for _, library in ipairs(libraries) do
        local libraryName = library.name
        local text = Locale[libraryName] or libraryName
        local checkboxContainer = CreateFrame("Frame", nil, content)
        checkboxContainer:SetSize(400, 28)

        local newCheckbox = CreateFrame("CheckButton", nil, checkboxContainer, "ChroniclesSettingsCheckboxTemplate")
        newCheckbox:SetPoint("LEFT", 10, 0)
        newCheckbox.Text:SetText(text)
        newCheckbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
        newCheckbox.libraryName = libraryName

        newCheckbox:SetChecked(Chronicles.Data:GetLibraryStatus(libraryName))
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local eventData = {
                    libraryName = self.libraryName,
                    isActive = self:GetChecked()
                }

                private.Core.triggerEvent(
                    private.constants.events.SettingsLibraryChecked,
                    eventData,
                    "Settings:LibraryCheckbox"
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
    if not private.Chronicles.db or not private.Chronicles.db.global or not private.Chronicles.db.global.options then
        private.Chronicles.db = private.Chronicles.db or {}
        private.Chronicles.db.global = private.Chronicles.db.global or {}
        private.Chronicles.db.global.options = private.Chronicles.db.global.options or {}
        private.Chronicles.db.global.options.myjournal = false
    end

    isActive:SetChecked(private.Chronicles.db.global.options.myjournal)

    -- Apply enhanced styling to the checkbox
    isActive.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    isActive.Text:SetTextColor(0.9, 0.9, 0.9)

    isActive:SetScript(
        "OnClick",
        function(self)
            local isChecked = self:GetChecked()

            if not private.Chronicles.db or not private.Chronicles.db.global or not private.Chronicles.db.global.options then
                private.Chronicles.db = private.Chronicles.db or {}
                private.Chronicles.db.global = private.Chronicles.db.global or {}
                private.Chronicles.db.global.options = private.Chronicles.db.global.options or {}
            end
            private.Chronicles.db.global.options.myjournal = isChecked
            Chronicles.Data:SetLibraryStatus(private.constants.configurationName.myjournal, isChecked)

            -- Update UI
            if MyJournalViewShow then
                if (isChecked) then
                    MyJournalViewShow:Show()
                else
                    MyJournalViewShow:Hide()
                end
            end

            -- Refresh UI if method exists
            if Chronicles.UI and Chronicles.UI.Refresh then
                Chronicles.UI:Refresh()
            end
        end
    )
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
        local settingsFrame = self:GetParent():GetParent() -- Get the main settings frame
        if settingsFrame and settingsFrame.OnSettingsTabSelected then
            settingsFrame:OnSettingsTabSelected(self.category.TabName)

            -- Update visual selection state for all category buttons
            self:UpdateCategorySelection()
        end
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
