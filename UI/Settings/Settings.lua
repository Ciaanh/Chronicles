local FOLDER_NAME, private = ...
--local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

SettingsMixin = {}
function SettingsMixin:OnLoad()
    local categories = {
        {
            text = "Settings",
            isExpanded = true,
            subMenu = {
                {
                    text = addonName,
                    isExpanded = true,
                    subMenu = {
                        {text = "GENERAL", panel = 1, callback = self.Settings_OnClick},
                        {text = "MAIL_LABEL", panel = 2, callback = self.Settings_OnClick},
                        {text = "Tooltip", panel = 3, callback = self.Settings_OnClick},
                        {text = "Calendar", panel = 4, callback = self.Settings_OnClick},
                        {text = " MISCELLANEOUS", panel = 5, callback = self.Settings_OnClick}
                    }
                },
                {
                    text = "DataStore",
                    subMenu = {
                        {text = "Auctions", panel = 10, callback = self.Settings_OnClick},
                        {text = "Characters", panel = 11, callback = self.Settings_OnClick},
                        {text = "Garrisons", panel = 12, callback = self.Settings_OnClick},
                        {text = "Inventory", panel = 13, callback = self.Settings_OnClick},
                        {text = "Mails", panel = 14, callback = self.Settings_OnClick},
                        {text = "Quests", panel = 15, callback = self.Settings_OnClick}
                    }
                }
            }
        },
        {
            text = "Account Sharing",
            subMenu = {
                {
                    text = format("%s1|r. %s", private.constants.colors.cyan, "How to"),
                    panel = helpPanelID,
                    helpID = 1,
                    callback = self.Help_OnClick
                },
                {
                    text = format("%s2|r. %s", private.constants.colors.cyan, "Authorizations"),
                    panel = 20,
                    callback = self.Settings_OnClick
                },
                {
                    text = format("%s3|r. %s", private.constants.colors.cyan, "Shared Content"),
                    panel = 21,
                    callback = self.Settings_OnClick
                },
                {
                    text = format(
                        "%s4|r. %s%s|r !",
                        private.constants.colors.cyan,
                        private.constants.colors.green,
                        "Share"
                    ),
                    panel = 22,
                    callback = self.Settings_OnClick
                }
            }
        }
    }

    self.CategoriesList:SetCategories(categories)
end

function SettingsMixin:RegisterPanel(key, panel)
    -- a simple list of all the child frames
    self.Panels = self.Panels or {}
    self.Panels[key] = panel
end

function SettingsMixin:HideAllPanels()
    for _, panel in pairs(self.Panels) do
        panel:Hide()
    end
end

function SettingsMixin:ShowPanel(panelKey)
    if not panelKey then
        return
    end

    self.currentPanelKey = panelKey

    self:HideAllPanels()

    local panel = self.Panels[currentPanelKey]

    panel:Show()
    if panel.PreUpdate then
        panel:PreUpdate()
    end
    panel:Update()
end

function SettingsMixin:SetStatus(text)
    self.Status:SetText(text)
end

function SettingsMixin:SetHelp(helpID)
    local panel = self.Panels[30] -- SetHelp is only for this panel
    panel:SetHelp(helpID)
end

function SettingsMixin:Update()
    self:ShowPanel(currentPanelKey)
end

function SettingsMixin:Settings_OnClick(categoryData)
    self.currentPanelKey = categoryData.panel
    self:Update()
end

function SettingsMixin:Help_OnClick(categoryData)
    self.currentPanelKey = categoryData.panel
    self:SetHelp(categoryData.helpID)
    self:Update()
end

CategoriesListMixin = {}
function CategoriesListMixin:OnLoad()
end

function CategoriesListMixin:ClickCategory(field, value)
    -- parse all categories, find the one that matches the field with the right value
    local soughtCategory

    self:IterateCategories(
        self.categories,
        function(category, parent, grandParent)
            if soughtCategory then
                return
            end -- already found ? stop searching

            if category[field] and category[field] == value then
                soughtCategory = category -- if the sought item exists, save it

                -- be sure it is visible by expanding both its parent and grand-parent
                if parent then
                    parent.isExpanded = true
                end
                if grandParent then
                    grandParent.isExpanded = true
                end
            end
        end
    )

    -- Update, to apply the expansion of categories
    if soughtCategory then
        self:UpdateCategories()
        if soughtCategory._parentButton then
            soughtCategory._parentButton:Button_OnClick("LeftButton")
        end
    end
end

function CategoriesListMixin:UnselectAll()
    -- unselect all categories
    self:IterateCategories(
        self.categories,
        function(category)
            category.isSelected = nil
        end
    )
end

function CategoriesListMixin:IterateCategories(categories, callback)
    -- Loop on all 3 levels
    for _, category in pairs(categories) do
        callback(category)

        if category.subMenu then
            for _, subCategory in pairs(category.subMenu) do
                callback(subCategory, category)

                if subCategory.subMenu then
                    for _, subSubCategory in pairs(subCategory.subMenu) do
                        callback(subSubCategory, subCategory, category)
                    end
                end
            end
        end
    end
end

function CategoriesListMixin:SetCategories(categories)
    --[[	Categories format : 
        {
            { text = "Menu 1" },
            { text = "Menu 2", subMenu = {
                { text = "Sub 2.1" },
                { text = "Sub 2.2", subMenu = {
                    { text = "SubSub 2.2.1" },
                    { text = "SubSub 2.2.2" },
                    { text = "SubSub 2.2.3" },
                    }},
                { text = "Sub 2.3" },
                }},
            { text = "Menu 3" },
            { text = "Menu 4" },
        }	
--]]
    self.categories = categories
    self:UpdateCategories()
end

function CategoriesListMixin:GetNumVisibleCategories()
    local numCategories = #self.categories
    local count = numCategories -- we already know that level 1 is always visible

    for i = 1, numCategories do
        local category = self.categories[i]

        -- is there a level 2 and is it expanded ?
        if category.subMenu and category.isExpanded then
            count = count + #category.subMenu -- add level 2 size

            for j = 1, #category.subMenu do
                local subCategory = category.subMenu[j]

                -- is there a level 3 and is it expanded ?
                if subCategory.subMenu and subCategory.isExpanded then
                    count = count + #subCategory.subMenu -- add level 3 size
                end
            end
        end
    end

    return count
end

function CategoriesListMixin:UpdateCategories()
    local currentButton = 0

    local scrollFrame = self.ScrollFrame
    local numRows = scrollFrame.numRows
    local offset = scrollFrame:GetOffset()

    local function IterateVisibleCategories(list, callback)
        for i = 1, #list do
            -- the offset will also represent the amount of lines to skip, so decrease it until it reaches 0
            if offset == 0 then
                currentButton = currentButton + 1
                if currentButton > numRows then
                    return
                end

                callback(list[i], true)
            else
                offset = offset - 1
                callback(list[i])
            end
        end
    end

    -- Level 1
    IterateVisibleCategories(
        self.categories,
        function(item, addItem)
            if addItem then
                self.Buttons[currentButton]:SetCategory(item.text)
                self.Buttons[currentButton]:SetData(item)
                self.Buttons[currentButton]:SetSelected(item)
            end

            if item.subMenu and item.isExpanded then
                -- Level 2
                IterateVisibleCategories(
                    item.subMenu,
                    function(subItem, addSubItem)
                        if addSubItem then
                            self.Buttons[currentButton]:SetSubCategory(subItem.text)
                            self.Buttons[currentButton]:SetData(subItem)
                            self.Buttons[currentButton]:SetSelected(subItem)
                        end

                        if subItem.subMenu and subItem.isExpanded then
                            -- Level 3
                            IterateVisibleCategories(
                                subItem.subMenu,
                                function(subsubItem, addSubSubItem)
                                    if addSubSubItem then
                                        self.Buttons[currentButton]:SetSubSubCategory(subsubItem.text)
                                        self.Buttons[currentButton]:SetData(subsubItem)
                                        self.Buttons[currentButton]:SetSelected(subsubItem)
                                    end
                                end
                            )
                        end
                    end
                )
            end
        end
    )

    -- Hide unused buttons
    currentButton = currentButton + 1
    while currentButton <= numRows do
        local button = self.Buttons[currentButton]

        button:Hide()
        button:SetData(nil)
        currentButton = currentButton + 1
    end

    scrollFrame:Update(self:GetNumVisibleCategories())
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

function CategoryButtonMixin:SetData(data)
    -- let the frame know to which data it is pointing
    self.data = data

    -- let the data point back to a parent button
    if data then
        data._parentButton = self
    end
end

function CategoryButtonMixin:SetSelected(data)
    if data.isSelected then
        self.SelectedTexture:SetShown(true)
    else
        self.SelectedTexture:SetShown(false)
    end
end

function CategoryButtonMixin:Button_OnClick(button)
    local data = self.data
    if button ~= "LeftButton" or not data then
        return
    end

    if data.subMenu then
        -- toggle the subMenu
        if data.isExpanded then
            data.isExpanded = nil
        else
            data.isExpanded = true
        end
    end

    if data.callback then
        -- if a callback exists for this menu item, call it
        -- and pass a reference to both the data and the button itself
        -- (could be useful to update the text of the button that has just been clicked)
        data.callback(data, self)
    end

    -- Hide the selection on all buttons
    for _, menuButton in pairs(self:GetParent().Buttons) do
        menuButton.SelectedTexture:SetShown(false)
    end

    local parent = self:GetParent()

    -- Select only the category we just clicked
    if not data.subMenu then
        parent:UnselectAll() -- only unselect all if we are actually
        data.isSelected = true -- going to select another item
    end

    parent:UpdateCategories()
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

Custom_UIPanelScrollFrameMixin = {}
function Custom_UIPanelScrollFrameMixin:OnLoad()
    local scrollBar = self.ScrollBar

    scrollBar.ScrollDownButton:Disable()
    scrollBar.ScrollUpButton:Disable()
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValue(0)

    self.offset = 0

    if self.scrollBarHideable then
        scrollBar:Hide()
        scrollBar.ScrollDownButton:Hide()
        scrollBar.ScrollUpButton:Hide()
    else
        scrollBar.ScrollDownButton:Disable()
        scrollBar.ScrollUpButton:Disable()
        scrollBar.ScrollDownButton:Show()
        scrollBar.ScrollUpButton:Show()
    end

    if self.noScrollThumb then
        scrollBar.ThumbTexture:Hide()
    end

    if not self.numRows or not self.rowTemplate then
        return
    end

    local prefix = self.rowPrefix
    local parent = self:GetParent()
    local xOffset = self.xOffset or 0
    local yOffset = self.yOffset or 0

    -- auto create the buttons, with the quantity passed as key
    for i = 1, self.numRows do
        local button = CreateFrame("Button", nil, parent, self.rowTemplate)

        if i == 1 then
            button:SetPoint("TOPLEFT", xOffset, yOffset)
        else
            -- attach to previous frame
            button:SetPoint("TOPLEFT", parent[prefix .. (i - 1)], "BOTTOMLEFT", 0, 0)
        end

        button:SetID(i)
        parent[prefix .. i] = button
    end
end

function Custom_UIPanelScrollFrameMixin:GetOffset()
    return self.offset
end

function Custom_UIPanelScrollFrameMixin:SetOffset(offset)
    self.offset = offset
end

function Custom_UIPanelScrollFrameMixin:OnScrollRangeChanged(xrange, yrange)
    local scrollBar = self.ScrollBar

    if not yrange then
        yrange = self:GetVerticalScrollRange()
    end

    local value = scrollBar:GetValue()
    if value > yrange then
        value = yrange
    end

    scrollBar:SetMinMaxValues(0, yrange)
    scrollBar:SetValue(value)

    if floor(yrange) == 0 then
        if self.scrollBarHideable then
            scrollBar:Hide()
            scrollBar.ScrollDownButton:Hide()
            scrollBar.ScrollUpButton:Hide()
            scrollBar.ThumbTexture:Hide()
        else
            scrollBar.ScrollDownButton:Disable()
            scrollBar.ScrollUpButton:Disable()
            scrollBar.ScrollDownButton:Show()
            scrollBar.ScrollUpButton:Show()

            if not self.noScrollThumb then
                scrollBar.ThumbTexture:Show()
            end
        end
    else
        scrollBar.ScrollDownButton:Show()
        scrollBar.ScrollUpButton:Show()
        scrollBar:Show()

        if not self.noScrollThumb then
            scrollBar.ThumbTexture:Show()
        end

        -- The 0.005 is to account for precision errors
        if (yrange - value) > 0.005 then
            scrollBar.ScrollDownButton:Enable()
        else
            scrollBar.ScrollDownButton:Disable()
        end
    end

    -- Hide/show scrollframe borders
    local top = self.Top
    local bottom = self.Bottom
    local middle = self.Middle

    if top and bottom and self.scrollBarHideable then
        if self:GetVerticalScrollRange() == 0 then
            top:Hide()
            bottom:Hide()
        else
            top:Show()
            bottom:Show()
        end
    end

    if middle and self.scrollBarHideable then
        if self:GetVerticalScrollRange() == 0 then
            middle:Hide()
        else
            middle:Show()
        end
    end
end

function Custom_UIPanelScrollFrameMixin:OnMouseWheel(delta)
    local scrollBar = self.ScrollBar
    local scrollStep = scrollBar.scrollStep or scrollBar:GetHeight() / 2

    local value = scrollBar:GetValue()

    if delta > 0 then
        value = value - scrollStep
    else
        value = value + scrollStep
    end

    scrollBar:SetValue(value)
end

function Custom_UIPanelScrollFrameMixin:OnVerticalScroll(offset, rowHeight, updateFunction, arg1, arg2, arg3)
    local scrollBar = self.ScrollBar
    scrollBar:SetValue(offset)

    self.offset = floor((offset / rowHeight) + 0.5)

    if updateFunction then
        updateFunction(arg1, arg2, arg3)
    end
end

function Custom_UIPanelScrollFrameMixin:Update(numItems, numToDisplay, buttonHeight)
    -- My own FauxScrollFrame_Update() from SharedUIPanelTemplates.lua
    -- If more than one screen full of skills then show the scrollbar

    numToDisplay = numToDisplay or self.numRows
    buttonHeight = buttonHeight or self.rowHeight

    local scrollBar = self.ScrollBar

    if numItems > numToDisplay then
        self:Show()
    else
        scrollBar:SetValue(0)

        -- only hide if consumer allows it
        if self.scrollBarHideable then
            self:Hide()
        end
    end

    if not self:IsShown() then
        return
    end

    local scrollChildFrame = self.ScrollChildFrame
    local scrollFrameHeight = 0
    local scrollChildHeight = 0

    if numItems > 0 then
        scrollFrameHeight = (numItems - numToDisplay) * buttonHeight
        scrollChildHeight = numItems * buttonHeight
        if scrollFrameHeight < 0 then
            scrollFrameHeight = 0
        end
        scrollChildFrame:Show()
    else
        scrollChildFrame:Hide()
    end

    local maxRange = (numItems - numToDisplay) * buttonHeight
    if maxRange < 0 then
        maxRange = 0
    end

    scrollBar:SetMinMaxValues(0, maxRange)
    scrollBar:SetValueStep(buttonHeight)
    scrollBar:SetStepsPerPage(numToDisplay - 1)
    scrollChildFrame:SetHeight(scrollChildHeight)

    local scrollUpButton = scrollBar.ScrollUpButton
    local scrollDownButton = scrollBar.ScrollDownButton

    -- Arrow button handling
    if scrollBar:GetValue() == 0 then
        scrollUpButton:Disable()
    else
        scrollUpButton:Enable()
    end

    if ((scrollBar:GetValue() - scrollFrameHeight) == 0) then
        scrollDownButton:Disable()
    else
        scrollDownButton:Enable()
    end
end

function Custom_UIPanelScrollFrameMixin:GetRow(index)
    --  ex: returns parent["Entry6"]
    local parent = self:GetParent()
    return parent[self.rowPrefix .. index]
end
