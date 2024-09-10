local FOLDER_NAME, private = ...
--local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

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
                    isTab = true,
                    TabName = "EventTypes",
                    TabFrame = self.Events
                },
                {
                    text = "Libraries",
                    isTab = true,
                    TabName = "Libraries",
                    TabFrame = self.Libraries
                }
            }
        },
        {
            text = "My Journal",
            isTab = true,
            TabName = "MyJournal",
            TabFrame = self.MyJournal
        },
        {
            text = "Test 1",
            subMenu = {
                {
                    text = "Test 2",
                    isTab = true,
                    TabName = "Test2",
                    TabFrame = self.Test2
                },
                {
                    text = "Test 3",
                    isTab = true,
                    TabName = "Test3",
                    TabFrame = self.Test3
                }
            }
        }
    }

    self.categories = self:GetVisibleCategories(self.ConfiguredCategories)
    self.Buttons = {}

    for index, category in ipairs(self.categories) do
        self:AddCategory(index, category)
    end

    self.TabUI.FrameTabs = {}
    for _, category in ipairs(self.categories) do
        if category.isTab then
            self.TabUI.FrameTabs[category.TabName] = category.TabFrame
        end
    end

    EventRegistry:RegisterCallback(private.constants.events.SettingsTabSelected, self.SetTab, self)

    self:UpdateTabs()
end

function SettingsMixin:GetTab()
    local currentTab = self.TabUI.currentTab
    return currentTab
end

function SettingsMixin:UpdateTabs()
    local currentTab = self:GetTab()
    if not currentTab then
        for key, tab in pairs(self.TabUI.FrameTabs) do
            self:SetTab(tab.TabName)
            break
        end
    end
end

function SettingsMixin:SetTab(tabName)
    for key, tab in pairs(self.TabUI.FrameTabs) do
        if tabName == key then
            tab:Show()
            self.TabUI.currentTab = key
        else
            tab:Hide()
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
    --button:SetID(index)
    self.Buttons[self.prefix .. index] = button
end

function SettingsMixin:OnUnselectAll()
    print("SettingsMixin:UnselectAll")
end

-- function SettingsMixin:EventTypes_Tab()
--     print("SettingsMixin:EventTypes_Tab")
-- end

-- function SettingsMixin:Libraries_Tab()
--     print("SettingsMixin:Libraries_Tab")
-- end

-- function SettingsMixin:MyJournal_Tab()
--     print("SettingsMixin:MyJournal_Tab")
-- end

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
    print("CategoryButtonMixin:Button_OnClick " .. tostring(self.CategoryId))

    local data = self.data
    for k, v in pairs(data) do
        print(k .. " - " .. tostring(v))
    end
    if button ~= "LeftButton" or not data or data.subMenu then
        print("returned " .. tostring(self.CategoryId))
        return
    end

    for _, menuButton in pairs(self:GetParent().Buttons) do
        menuButton.SelectedTexture:SetShown(false)
    end

    if data.isTab then
        print("Should call set tab " .. tostring(self.CategoryId))

        EventRegistry:TriggerEvent(private.constants.events.SettingsTabSelected, data.TabName)
        
        -- self:SetTab(data.TabName)
        self.SelectedTexture:SetShown(true)
    end
end

function CategoryButtonMixin:SetCategory(text)
    self:SetText(text)
    self.Text:SetPoint("LEFT", self, "LEFT", 8, 0)
    self.Lines:Hide()
    self:SetNormalFontObject(GameFontNormalSmall)

    local texture = self.NormalTexture
    texture:SetAtlas("auctionhouse-nav-button", false)
    texture:SetSize(156, 32)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", -2, 0)
    texture:SetAlpha(1.0)

    texture = self.SelectedTexture
    texture:SetAtlas("auctionhouse-nav-button-select", false)
    texture:SetSize(152, 21)
    texture:ClearAllPoints()
    texture:SetPoint("CENTER")

    texture = self.HighlightTexture
    texture:SetAtlas("auctionhouse-nav-button-highlight", false)
    texture:SetSize(152, 21)
    texture:ClearAllPoints()
    texture:SetPoint("CENTER")
    texture:SetBlendMode("BLEND")

    self:Show()
end

function CategoryButtonMixin:SetSubCategory(text)
    self:SetText(text)
    self.Text:SetPoint("LEFT", self, "LEFT", 18, 0)
    self.Lines:Hide()
    self:SetNormalFontObject(GameFontHighlightSmall)

    local texture = self.NormalTexture
    texture:SetAtlas("auctionhouse-nav-button-secondary", false)
    texture:SetSize(153, 32)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", 1, 0)
    texture:SetAlpha(1.0)

    texture = self.SelectedTexture
    texture:SetAtlas("auctionhouse-nav-button-secondary-select", false)
    texture:SetSize(142, 21)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", 10, 0)

    texture = self.HighlightTexture
    texture:SetAtlas("auctionhouse-nav-button-secondary-highlight", false)
    texture:SetSize(142, 21)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", 10, 0)
    texture:SetBlendMode("BLEND")

    self:Show()
end

function CategoryButtonMixin:SetSubSubCategory(text)
    self:SetText(text)
    self.Text:SetPoint("LEFT", self, "LEFT", 26, 0)
    self.Lines:Show()
    self:SetNormalFontObject(GameFontHighlightSmall)

    local texture = self.NormalTexture
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", 10, 0)
    texture:SetAlpha(0.0)

    texture = self.SelectedTexture
    texture:SetAtlas("auctionhouse-ui-row-select", false)
    texture:SetSize(136, 18)
    texture:ClearAllPoints()
    texture:SetPoint("TOPRIGHT", 0, -2)

    texture = self.HighlightTexture
    texture:SetAtlas("auctionhouse-ui-row-highlight", false)
    texture:SetSize(136, 18)
    texture:ClearAllPoints()
    texture:SetPoint("TOPRIGHT", 0, -2)
    texture:SetBlendMode("ADD")

    self:Show()
end
