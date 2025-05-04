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
            local element = category.TabFrame

            local currentTab = self.TabUI.currentTab
            if not currentTab then
                self.TabUI.currentTab = tabKey
            end

            self.TabUI.Tabs[tabKey] = category
        end
    end

    EventRegistry:RegisterCallback(private.constants.events.SettingsTabSelected, self.SetTab, self)
    EventRegistry:RegisterCallback(private.constants.events.SettingsEventTypeChecked, self.Change_EventType, self)
    EventRegistry:RegisterCallback(private.constants.events.SettingsLibraryChecked, self.Change_Library, self)

    self:UpdateTabs()
end

function SettingsMixin:UpdateTabs()
    local currentTab = self.TabUI.currentTab
    if not currentTab then
        for key, _ in pairs(self.TabUI.Tabs) do
            self:SetTab(key)
            break
        end
    end
end

function SettingsMixin:SetTab(tabName)
    self.TabUI.currentTab = tabKey
    for key, tab in pairs(self.TabUI.Tabs) do
        if (tab.Load and tab.TabFrame and not tab.IsLoaded) then
            tab.Load(self, tab.TabFrame)
            tab.IsLoaded = true
        end

        tab.TabFrame:SetShown(key == tabName)
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
    local initialXoffset = 8
    local initialYoffset = -10
    local xOffset = 6

    local button = CreateFrame("Button", nil, self.CategoriesList, "CategoryButtonTemplate")

    if index == 1 then
        button:SetPoint("TOPLEFT", initialXoffset, initialYoffset)
    else
        button:SetPoint("TOP", self.Buttons[self.prefix .. (index - 1)], "BOTTOM", 0, -2)
        button:SetPoint("LEFT", initialXoffset + xOffset * category.level, 0)
    end

    button:SetData(category, index)
    self.Buttons[self.prefix .. index] = button
end

function SettingsMixin:Change_EventType(eventTypeId, checked)
    Chronicles.Data:SetEventTypeStatus(eventTypeId, checked)
    Chronicles.Data:RefreshPeriods()

    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()

    -- TODO clean select period and event

    -- print("SettingsMixin:Change_EventType " .. tostring(eventTypeId) .. " " .. tostring(checked))

    EventRegistry:TriggerEvent(private.constants.events.TimelineClean)
end

function SettingsMixin:Change_Library(libraryId, checked)
    Chronicles.Data:SetLibraryStatus(libraryId, checked)
    Chronicles.Data:RefreshPeriods()

    private.Core.Timeline:ComputeTimelinePeriods()
    private.Core.Timeline:DisplayTimelineWindow()

    EventRegistry:TriggerEvent(private.constants.events.TimelineClean)
end

function SettingsMixin:LoadEventTypes(frame)
    local previousCheckbox = nil
    for eventTypeId, eventTypeName in ipairs(get_constants().eventType) do
        local text = get_locale(eventTypeName)

        local newCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        newCheckbox.Text:SetText(text)
        newCheckbox.eventTypeId = eventTypeId
        newCheckbox.eventTypeName = eventTypeName
        newCheckbox:SetChecked(Chronicles.Data:GetEventTypeStatus(eventTypeId))
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local data = {
                    eventTypeId = self.eventTypeId,
                    isActive = self:GetChecked()
                }
                EventRegistry:TriggerEvent(
                    private.constants.events.SettingsEventTypeChecked,
                    data.eventTypeId,
                    data.isActive
                )
            end
        )

        if (previousCheckbox) then
            newCheckbox:SetPoint("TOP", previousCheckbox, "BOTTOM", 0, -1)
        else
            newCheckbox:SetPoint("TOP", frame, "TOP", 0, -1)
        end
        newCheckbox:Show()
        previousCheckbox = newCheckbox
    end
end

function SettingsMixin:LoadLibraries(frame)
    print("SettingsMixin:LoadLibraries")

    local libraries = Chronicles.Data:GetLibrariesNames()
    for _, library in ipairs(libraries) do
        local libraryName = library.name
        local text = get_locale(libraryName) or ""

        local newCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        newCheckbox.Text:SetText(text)
        newCheckbox.libraryName = libraryName

        newCheckbox:SetChecked(Chronicles.Data:GetLibraryStatus(libraryName))
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local data = {
                    libraryName = self.libraryName,
                    isActive = self:GetChecked()
                }
                EventRegistry:TriggerEvent(
                    private.constants.events.SettingsLibraryChecked,
                    data.libraryName,
                    data.isActive
                )
            end
        )

        if (previousCheckbox) then
            newCheckbox:SetPoint("TOP", previousCheckbox, "BOTTOM", 0, -1)
        else
            newCheckbox:SetPoint("TOP", frame, "TOP", 0, -1)
        end
        newCheckbox:Show()
        previousCheckbox = newCheckbox
    end
end

function SettingsMixin:LoadMyJournal(frame)
    print("SettingsMixin:LoadMyJournal")

    frame.IsActive:SetChecked(Chronicles.db.global.options.myjournal)
end

function SettingsMixin:MyJournalIsActive_OnClick(chkBox)
    print("SettingsMixin:MyJournalIsActive_OnClick")

    Chronicles.db.global.options.myjournal = chkBox:GetChecked()
    Chronicles.Data:SetLibraryStatus(
        private.constants.configurationName.myjournal,
        Chronicles.db.global.options.myjournal
    )

    -- EventRegistry:TriggerEvent(
    --                 private.constants.events.SettingsLibraryChecked,
    --                 data.libraryName,
    --                 data.isActive
    --             )

    if (Chronicles.db.global.options.myjournal) then
        MyJournalViewShow:Show()
    else
        MyJournalViewShow:Hide()
    end

    Chronicles.UI:Refresh()
end

CategoryButtonMixin = {}
function CategoryButtonMixin:OnLoad()
    self:SetPushedTextOffset(0, 0)

    self:SetScript(
        "OnEnter",
        function(self)
            TruncatedTooltipScript_OnEnter(self)
            self.HighlightTexture:Show()
        end
    )

    self:SetScript(
        "OnLeave",
        function(self)
            TruncatedTooltipScript_OnLeave(self)
            self.HighlightTexture:Hide()
        end
    )

    self:SetScript(
        "OnMouseDown",
        function(self)
            self.Text:AdjustPointsOffset(1, -1)
        end
    )

    self:SetScript(
        "OnMouseUp",
        function(self)
            self.Text:AdjustPointsOffset(-1, 1)
        end
    )
end

function CategoryButtonMixin:SetData(category, categoryId)
    self.data = category
    self.CategoryId = categoryId

    self.Text:SetText(category.text)
end

function CategoryButtonMixin:Button_OnClick(button)
    local data = self.data

    if button ~= "LeftButton" or not data or data.subMenu then
        return
    end

    for _, menuButton in pairs(self:GetParent().Buttons) do
        menuButton.SelectedTexture:SetShown(false)
    end

    if data.TabName and data.TabFrame then
        EventRegistry:TriggerEvent(private.constants.events.SettingsTabSelected, data.TabName)

        self.SelectedTexture:SetShown(true)
    end
end

-- function CategoryButtonMixin:SetCategory(text)
--     self:SetText(text)
--     self.Text:SetPoint("LEFT", self, "LEFT", 8, 0)
--     self.Lines:Hide()
--     self:SetNormalFontObject(GameFontNormalSmall)

--     local texture = self.NormalTexture
--     texture:SetAtlas("auctionhouse-nav-button", false)
--     texture:SetSize(156, 32)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPLEFT", -2, 0)
--     texture:SetAlpha(1.0)

--     texture = self.SelectedTexture
--     texture:SetAtlas("auctionhouse-nav-button-select", false)
--     texture:SetSize(152, 21)
--     texture:ClearAllPoints()
--     texture:SetPoint("CENTER")

--     texture = self.HighlightTexture
--     texture:SetAtlas("auctionhouse-nav-button-highlight", false)
--     texture:SetSize(152, 21)
--     texture:ClearAllPoints()
--     texture:SetPoint("CENTER")
--     texture:SetBlendMode("BLEND")

--     self:Show()
-- end

-- function CategoryButtonMixin:SetSubCategory(text)
--     self:SetText(text)
--     self.Text:SetPoint("LEFT", self, "LEFT", 18, 0)
--     self.Lines:Hide()
--     self:SetNormalFontObject(GameFontHighlightSmall)

--     local texture = self.NormalTexture
--     texture:SetAtlas("auctionhouse-nav-button-secondary", false)
--     texture:SetSize(153, 32)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPLEFT", 1, 0)
--     texture:SetAlpha(1.0)

--     texture = self.SelectedTexture
--     texture:SetAtlas("auctionhouse-nav-button-secondary-select", false)
--     texture:SetSize(142, 21)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPLEFT", 10, 0)

--     texture = self.HighlightTexture
--     texture:SetAtlas("auctionhouse-nav-button-secondary-highlight", false)
--     texture:SetSize(142, 21)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPLEFT", 10, 0)
--     texture:SetBlendMode("BLEND")

--     self:Show()
-- end

-- function CategoryButtonMixin:SetSubSubCategory(text)
--     self:SetText(text)
--     self.Text:SetPoint("LEFT", self, "LEFT", 26, 0)
--     self.Lines:Show()
--     self:SetNormalFontObject(GameFontHighlightSmall)

--     local texture = self.NormalTexture
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPLEFT", 10, 0)
--     texture:SetAlpha(0.0)

--     texture = self.SelectedTexture
--     texture:SetAtlas("auctionhouse-ui-row-select", false)
--     texture:SetSize(136, 18)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPRIGHT", 0, -2)

--     texture = self.HighlightTexture
--     texture:SetAtlas("auctionhouse-ui-row-highlight", false)
--     texture:SetSize(136, 18)
--     texture:ClearAllPoints()
--     texture:SetPoint("TOPRIGHT", 0, -2)
--     texture:SetBlendMode("ADD")

--     self:Show()
-- end
