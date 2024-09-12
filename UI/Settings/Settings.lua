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

            self.TabUI.Tabs[tabKey] = element
        end
    end

    EventRegistry:RegisterCallback(private.constants.events.SettingsTabSelected, self.SetTab, self)
    EventRegistry:RegisterCallback(private.constants.events.SettingsEventTypeChecked, self.Change_EventType, self)

    self:UpdateTabs()
end

function SettingsMixin:UpdateTabs()
    local currentTab = self.TabUI.currentTab
    if not currentTab then
        for key, tab in pairs(self.TabUI.Tabs) do
            self:SetTab(key)
            break
        end
    end
end

function SettingsMixin:SetTab(tabName)
    print("SettingsMixin:SetTab " .. tabName)

    self.TabUI.currentTab = tabKey
    for key, tabbedElement in pairs(self.TabUI.Tabs) do
        tabbedElement:SetShown(key == tabName)
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

    if (category.Load and category.TabFrame) then
        category.Load(self, category.TabFrame)
    end
end

function SettingsMixin:Change_EventType(eventType, checked)
    Chronicles.DB:SetEventTypeStatus(eventType, checked)
    --Chronicles.UI:Refresh()

    print("SettingsMixin:Change_EventType")
end

-- function SettingsMixin:Get_EventType_Checked(eventType)
--     return Chronicles.DB:GetEventTypeStatus(eventType)
-- end

function SettingsMixin:LoadEventTypes(frame)
    local previousCheckbox = nil
    for index, value in ipairs(get_constants().eventType) do
        local text = get_locale(value)

        local newCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        newCheckbox.Text:SetText(text)
        newCheckbox.eventId = index

        newCheckbox:SetChecked(Chronicles.DB:GetEventTypeStatus(index))
        newCheckbox:SetScript(
            "OnClick",
            function(self)
                local data = {
                    eventId = self.eventId,
                    isActive = self:GetChecked()
                }
                EventRegistry:TriggerEvent(private.constants.events.SettingsEventTypeChecked, data)
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
end

function SettingsMixin:LoadMyJournal(frame)
    print("SettingsMixin:LoadMyJournal")
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
    --print("CategoryButtonMixin:Button_OnClick " .. tostring(self.CategoryId))

    local data = self.data
    -- for k, v in pairs(data) do
    --     print(k .. " - " .. tostring(v))
    -- end
    if button ~= "LeftButton" or not data or data.subMenu then
        --print("returned " .. tostring(self.CategoryId))
        return
    end

    for _, menuButton in pairs(self:GetParent().Buttons) do
        menuButton.SelectedTexture:SetShown(false)
    end

    if data.TabName and data.TabFrame then
        --print("Should call set tab " .. tostring(self.CategoryId))

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
