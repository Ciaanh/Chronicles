local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
    Shared Vertical List Template - Generic Implementation
    
    DESIGN PHILOSOPHY:
    - Provides a reusable, configurable vertical list component
    - Maintains Chronicles addon's established bookmark visual style
    - Supports multiple item types (characters, factions, events, etc.)
    - Uses configuration-driven approach for flexibility
    
    FEATURES:
    - Configurable item types through KeyValues
    - Consistent bookmark-style visual treatment
    - Integrated search functionality with customizable placeholders
    - State management integration with configurable keys
    - Generic data provider interface
    - Responsive tooltip system
    - Count display with customizable formatting
    - Reusable across different content types
    - Direct stateManagerKey passing (no parent traversal required)
    
    CONFIGURATION:
    Templates can be specialized by setting KeyValues:
    - itemType: Type of items being displayed ("character", "faction", etc.)
    - searchPlaceholder: Custom search box placeholder text
    - countLabelFormat: Format string for item count display
    - stateManagerKey: Key for state management integration
    - dataSourceMethod: Method name for retrieving data
    - templateKey: Template key for item rendering
    
    USAGE EXAMPLES:
    - VerticalCharacterListSharedTemplate: Pre-configured for characters
    - VerticalFactionListSharedTemplate: Pre-configured for factions
    - Custom implementations can inherit from VerticalListTemplate directly
    
    RECENT CHANGES:
    - Refactored to pass stateManagerKey directly to each item during initialization
    - Eliminated parent traversal in OnClick handler for better performance and reliability
    - Each list item now stores its own stateManagerKey for direct access
--]]
-- -------------------------
-- Shared Vertical List Item Mixin
-- -------------------------
VerticalListItemMixin = {}

function VerticalListItemMixin:Init(itemData)
    if not itemData then
        return
    end

    -- Handle different data structures (direct item data or wrapper structure)
    local item = itemData.character or itemData.faction or itemData.item or itemData

    if not item or not item.name then
        return
    end

    self.Item = item
    self.ItemType = self:GetParent():GetParent().itemType or "generic"

    -- Store the stateManagerKey directly from the itemData to eliminate parent traversal
    self.stateManagerKey = itemData.stateManagerKey or "generic"
    local contentTexture = self.Content
    local sideTexture = self.Side
    local textElement = self.ItemName or self.CharacterName -- Support both field names for compatibility    -- Set item name
    if textElement then
        textElement:SetText(item.name)
    end

    -- Configure bookmark textures for left orientation
    if contentTexture then
        contentTexture:SetTexCoord(0, 1, 0, 1)
        contentTexture:ClearAllPoints()
        contentTexture:SetPoint("RIGHT", self, "RIGHT", 0, 0)
    end

    if sideTexture then
        sideTexture:SetTexCoord(0, 1, 0, 1)
        sideTexture:ClearAllPoints()
        sideTexture:SetPoint("LEFT", self, "LEFT", 0, 0)
    end

    if textElement then
        textElement:ClearAllPoints()
        textElement:SetPoint("LEFT", self, "LEFT", 25, 0)
    end

    self:SetSelected(false)
end

function VerticalListItemMixin:OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    -- Use the stateManagerKey stored during initialization instead of parent traversal
    local stateManagerKey = self.stateManagerKey or "generic"

    -- Only handle state management if the item has been properly configured
    if private.Core.StateManager and self.Item and stateManagerKey ~= "generic" then
        local itemId = self.Item.id
        local collectionName = self.Item.source

        if itemId and collectionName then
            local selectionKey = private.Core.StateManager.buildSelectionKey(stateManagerKey)
            local stateData = {}

            -- Build appropriate state data based on item type
            if stateManagerKey == "character" then
                stateData = {characterId = itemId, collectionName = collectionName}
            elseif stateManagerKey == "faction" then
                stateData = {factionId = itemId, collectionName = collectionName}
            else
                stateData = {itemId = itemId, collectionName = collectionName}
            end

            private.Core.StateManager.setState(
                selectionKey,
                stateData,
                string.format("%s selected from vertical list", stateManagerKey)
            )
        end
    end

    self:SetSelected(true)
end

function VerticalListItemMixin:OnEnter()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)

    if self.Item then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.Item.name or "Item", 1, 1, 1)

        -- Add contextual information based on item type
        if self.Item.chapters and #self.Item.chapters > 0 then
            GameTooltip:AddLine("Available Content: " .. #self.Item.chapters .. " chapters", 0.6, 0.8, 0.6)
        end

        if self.Item.author then
            GameTooltip:AddLine("Created by: " .. self.Item.author, 0.7, 0.7, 0.7)
        end

        -- Add item type specific information
        local itemType = self.ItemType
        if itemType == "faction" and self.Item.allegiance then
            GameTooltip:AddLine("Allegiance: " .. self.Item.allegiance, 0.8, 0.8, 0.6)
        elseif itemType == "character" and self.Item.race then
            GameTooltip:AddLine("Race: " .. self.Item.race, 0.6, 0.8, 1.0)
        end

        GameTooltip:Show()
    end
end

function VerticalListItemMixin:OnLeave()
    GameTooltip:Hide()
end

function VerticalListItemMixin:SetSelected(selected)
    -- Bookmark-style visual feedback through hover states
    -- Maintain internal selection state for consistency
    self.isSelected = selected
end

-- -------------------------
-- Shared Vertical List Mixin
-- -------------------------
VerticalListMixin = {}

function VerticalListMixin:OnLoad()
    -- Initialize configuration with defaults (KeyValues are applied via template inheritance)
    self.itemType = "generic"
    self.searchPlaceholder = "Search..."
    self.countLabelFormat = "%d items"
    self.enableSearch = true
    self.enableCount = true
    self.stateManagerKey = "generic"
    self.dataSourceMethod = "getAllItems"
    self.templateKey = "GENERIC_LIST_ITEM"

    -- Initialize state
    self.selectedItem = nil
    self.allItems = {}
    self.currentSearchTerm = ""

    -- Configure search box
    if self.SearchBox and self.enableSearch then
        if self.SearchBox.PlaceholderText then
            self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
        end
    else
        -- Hide search box if disabled
        if self.SearchBox then
            self.SearchBox:Hide()
        end
    end

    -- Configure count label
    if not self.enableCount and self.CountLabel then
        self.CountLabel:Hide()
    end -- Register for addon events
    private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
    private.Core.registerCallback(private.constants.events.AddonStartup, self.OnAddonStartup, self)

    -- Initialize template data for paged list
    -- Only set template data if both PagedItemList and templates are available
    if self.PagedItemList and private.constants and private.constants.templates then
        self.PagedItemList:SetElementTemplateData(private.constants.templates)
    end
end

-- Initialize state subscriptions after configuration
function VerticalListMixin:InitializeStateSubscriptions()
    -- Subscribe to state changes for selection synchronization
    if private.Core.StateManager and self.stateManagerKey ~= "generic" then
        local selectedItemKey = private.Core.StateManager.buildSelectionKey(self.stateManagerKey)
        private.Core.StateManager.subscribe(
            selectedItemKey,
            function(newValue, oldValue, context)
                self:OnSelectionStateChanged(newValue, oldValue, context)
            end,
            "VerticalListMixin:" .. (self.stateManagerKey or "unknown")
        )
    end
end

-- Configuration method for specialized templates
function VerticalListMixin:ConfigureTemplate()
    -- This method can be overridden by specialized templates
    -- or we can detect the template type and configure accordingly
end

-- Built-in configuration for character lists
function VerticalListMixin:ConfigureForCharacters()
    self.itemType = "character"
    self.searchPlaceholder = "Search..."
    self.countLabelFormat = "%d Characters"
    self.stateManagerKey = "character"
    self.dataSourceMethod = "getAllCharacters"
    self.templateKey = "GENERIC_LIST_ITEM"

    -- Update search placeholder if search box exists
    if self.SearchBox and self.SearchBox.PlaceholderText then
        self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
    end

    -- Always initialize state subscriptions (needed regardless of KeyValues)
    self:InitializeStateSubscriptions()
end

-- Built-in configuration for faction lists
function VerticalListMixin:ConfigureForFactions()
    self.itemType = "faction"
    self.searchPlaceholder = "Search..."
    self.countLabelFormat = "%d Factions"
    self.stateManagerKey = "faction"
    self.dataSourceMethod = "SearchFactions"
    self.templateKey = "GENERIC_LIST_ITEM"

    -- Update search placeholder if search box exists
    if self.SearchBox and self.SearchBox.PlaceholderText then
        self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
    end

    -- Always initialize state subscriptions (needed regardless of KeyValues)
    self:InitializeStateSubscriptions()
end

function VerticalListMixin:InitializeSearchPlaceholder()
    if self.SearchBox and self.SearchBox.PlaceholderText and self.enableSearch then
        self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
        self.SearchBox.PlaceholderText:Show()
    end
end

function VerticalListMixin:OnShow()
    self:RefreshItemList()
    self:SyncWithCurrentSelection()
end

function VerticalListMixin:OnUIRefresh()
    self:RefreshItemList()
end

function VerticalListMixin:OnAddonStartup()
    self:RefreshItemList()
end

function VerticalListMixin:RefreshItemList()
    local items = self:GetDataFromSource()

    if not items then
        return
    end

    -- Cache all items for search performance
    self.allItems = items

    -- Apply current search filter if any
    local filteredItems = self:FilterItemsByName(items, self.currentSearchTerm)

    self:DisplayItems(filteredItems)
end

function VerticalListMixin:GetDataFromSource()
    -- Use configuration-driven data retrieval
    if self.itemType == "character" and private.Core.Cache then
        return private.Core.Cache.getAllCharacters() or {}
    elseif self.itemType == "faction" and private.Chronicles and private.Chronicles.Data then
        return private.Chronicles.Data:SearchFactions() or {}
    else
        -- Generic fallback - can be extended for other item types
        return {}
    end
end

function VerticalListMixin:DisplayItems(items)
    if not items then
        items = {}
    end

    local content = {
        elements = {}
    }

    local itemCount = 0

    for _, item in pairs(items) do
        if item and item.name then
            local templateKey = self.templateKey

            -- Fallback to generic template if the specific template key doesn't exist
            if not templateKey then
                templateKey = "GENERIC_LIST_ITEM"
            end

            local itemSummary = {
                templateKey = templateKey,
                [self.itemType] = item,
                -- Pass the stateManagerKey to each item during initialization
                stateManagerKey = self.stateManagerKey
            }
            table.insert(content.elements, itemSummary)
            itemCount = itemCount + 1
        end
    end

    local data = {}
    table.insert(data, content)

    self:SetItemDataProvider(data)
    self:UpdateItemCount(itemCount)

    -- Sync selection state after data update
    self:SyncWithCurrentSelection()
end

function VerticalListMixin:SetItemDataProvider(data)
    if not self.PagedItemList then
        return
    end

    -- Ensure we have valid data structure
    if not data or #data == 0 then
        -- Create empty data structure to prevent errors
        data = {{elements = {}}}
    end

    -- Verify that template data has been set
    if not self.PagedItemList.elementTemplateData then
        if private.constants and private.constants.templates then
            self.PagedItemList:SetElementTemplateData(private.constants.templates)
        else
            -- If templates aren't available yet, defer the operation
            return
        end
    end

    local dataProvider = CreateDataProvider(data)
    local retainScrollPosition = true
    self.PagedItemList:SetDataProvider(dataProvider, retainScrollPosition)
end

function VerticalListMixin:FilterItemsByName(items, searchTerm)
    if not searchTerm or searchTerm == "" then
        return items
    end

    local filtered = {}
    local lowerSearchTerm = string.lower(searchTerm)

    for _, item in pairs(items) do
        if item and item.name and string.find(string.lower(item.name), lowerSearchTerm, 1, true) then
            filtered[_] = item
        end
    end

    return filtered
end

function VerticalListMixin:OnSearchTextChanged(text)
    self.currentSearchTerm = text

    -- Throttle search to avoid excessive updates
    if self.searchThrottle then
        self.searchThrottle:Cancel()
    end

    self.searchThrottle =
        C_Timer.NewTimer(
        0.3,
        function()
            self:RefreshItemList()
        end
    )
end

function VerticalListMixin:UpdateItemCount(count)
    if self.CountLabel and self.enableCount then
        local formattedText = string.format(self.countLabelFormat, count)
        self.CountLabel:SetText(formattedText)
    end
end

function VerticalListMixin:OnSelectionStateChanged(newValue, oldValue, context)
    -- Handle selection state changes from external sources
    self:SyncWithCurrentSelection()
end

function VerticalListMixin:SyncWithCurrentSelection()
    -- Selection state is handled by individual items through state management
    -- This method provides a hook for future enhancements
    if private.Core.StateManager and self.stateManagerKey and self.stateManagerKey ~= "generic" then
        local selectedItemKey = private.Core.StateManager.buildSelectionKey(self.stateManagerKey)
        local currentSelection = private.Core.StateManager.getState(selectedItemKey)

    -- Individual list items will handle their own selection state
    -- based on this shared state information
    end
end
