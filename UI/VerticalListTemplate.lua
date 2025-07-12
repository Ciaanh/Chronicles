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
    
    IMPORTANT: State Management Protection
    
    The template includes protection against invalid stateManagerKey values.
    All state management operations (item clicks, state subscriptions, 
    selection synchronization) will only execute when the stateManagerKey
    is properly configured (not "generic"). This prevents runtime errors
    during initialization and ensures robust operation.
--]]
--[[
    EXAMPLE 1: Using Pre-configured Character List
    
    In your XML:
    <Frame parentKey="MyCharacterList" inherits="VerticalCharacterListSharedTemplate">
        <Size x="150" y="650"/>
        <Anchors>
            <Anchor point="BOTTOMLEFT" x="0" y="0" />
        </Anchors>
    </Frame>
    
    The VerticalCharacterListSharedTemplate is pre-configured with:
    - itemType = "character"
    - searchPlaceholder = "Search Characters..."    - countLabelFormat = "%d Characters"
    - stateManagerKey = "character"
    - dataSourceMethod = "getAllCharacters"
    - templateKey = "GENERIC_LIST_ITEM"
--]]
--[[
    EXAMPLE 2: Using Pre-configured Faction List
    
    In your XML:
    <Frame parentKey="MyFactionList" inherits="VerticalFactionListSharedTemplate">
        <Size x="150" y="650"/>
        <Anchors>
            <Anchor point="BOTTOMLEFT" x="0" y="0" />
        </Anchors>
    </Frame>
    
    The VerticalFactionListSharedTemplate is pre-configured with:
    - itemType = "faction"
    - searchPlaceholder = "Search Factions..."
    - countLabelFormat = "%d Factions"
    - stateManagerKey = "faction"
    - dataSourceMethod = "SearchFactions"
    - templateKey = "GENERIC_LIST_ITEM"
--]]
--[[
    EXAMPLE 3: Custom Configuration
    
    You can create your own specialized template by inheriting from VerticalListTemplate
    and setting custom KeyValues:
    
    <Frame name="MyCustomVerticalListTemplate" inherits="VerticalListTemplate" virtual="true">
        <KeyValues>
            <KeyValue key="itemType" value="event" type="string" />
            <KeyValue key="searchPlaceholder" value="Search Events..." type="string" />
            <KeyValue key="countLabelFormat" value="%d Events Found" type="string" />
            <KeyValue key="stateManagerKey" value="event" type="string" />
            <KeyValue key="dataSourceMethod" value="getAllEvents" type="string" />
            <KeyValue key="templateKey" value="EVENT_LIST_ITEM" type="string" />
        </KeyValues>
    </Frame>
--]]
--[[
    EXAMPLE 4: Runtime Configuration
    
    You can also configure the template at runtime:
    
    function ConfigureMyList(listFrame)
        listFrame:ConfigureForCharacters()  -- Built-in character configuration
        -- or
        listFrame:ConfigureForFactions()    -- Built-in faction configuration
        -- or custom configuration:
        listFrame.itemType = "myCustomType"
        listFrame.searchPlaceholder = "Search My Items..."
        listFrame.countLabelFormat = "%d My Items"
        listFrame.stateManagerKey = "myCustom"
        listFrame.dataSourceMethod = "getAllMyItems"
        listFrame.templateKey = "MY_CUSTOM_LIST_ITEM"
        listFrame:RefreshItemList()
    end
--]]
--[[
    IMPLEMENTATION NOTES:
    
    The shared template avoids the GetKeyValue error by using a different approach:
    
    1. The base VerticalListMixin sets defaults in OnLoad()
    2. Specialized mixins (VerticalCharacterListSharedMixin, VerticalFactionListSharedMixin) 
       override these defaults using configuration methods
    3. Configuration can also be done at runtime using the provided methods
    4. This approach is more compatible with WoW's addon framework
    
    Error that was fixed:
    - GetKeyValue is not a standard WoW API method
    - KeyValues in XML are not accessible via GetKeyValue()
    - The solution uses mixin inheritance and configuration methods instead
--]]
--[[
    EXAMPLE 5: Integration with Existing Code
    
    The new template can be used alongside existing templates without modification:
    
    -- In MainFrameUI.xml, you could add:
    <Frame parentKey="Characters" frameLevel="100" hidden="true">
        <Frames>
            <!-- New shared template for factions in character tab -->
            <Frame parentKey="RelatedFactions" inherits="VerticalFactionListSharedTemplate">
                <Size x="150" y="300"/>
                <Anchors>
                    <Anchor point="BOTTOMRIGHT" x="-10" y="0" />
                </Anchors>
            </Frame>
            
            <Frame parentKey="Book" inherits="CharacterBookTemplate">
                <Size x="1200" y="650"/>
                <Anchors>
                    <Anchor point="BOTTOM" />
                </Anchors>
            </Frame>
        </Frames>
    </Frame>
--]]
--[[
    BENEFITS OF THE SHARED TEMPLATE:
    
    1. CONSISTENCY: All vertical lists use the same bookmark visual style
    2. MAINTAINABILITY: Single template to update for visual changes
    3. FLEXIBILITY: Configuration-driven approach for different item types
    4. REUSABILITY: Can be used for any item type with minimal setup
    5. STATE MANAGEMENT: Integrated with Chronicles state management system
    6. SEARCH: Built-in search functionality with customizable placeholders
    7. PERFORMANCE: Optimized data handling and rendering
    8. ACCESSIBILITY: Consistent tooltip and interaction patterns
    
    BACKWARDS COMPATIBILITY:
    
    - New shared template can be used alongside existing templates
    - No modifications to existing code are required
    - Gradual migration possible if desired
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
        textElement:SetPoint("RIGHT", self, "RIGHT", 5, 0)
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
    self.searchPlaceholder = Locale["SearchCharactersPlaceholder"]
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
    self.searchPlaceholder = Locale["SearchCharactersPlaceholder"]
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
    self.searchPlaceholder = Locale["SearchCharactersPlaceholder"]
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
    -- Synchronize visual selection state with the stored state
    if not private.Core.StateManager or not self.stateManagerKey or self.stateManagerKey == "generic" then
        return
    end
    
    if not self.PagedItemList then
        return
    end

    local selectedItemKey = private.Core.StateManager.buildSelectionKey(self.stateManagerKey)
    local currentSelection = private.Core.StateManager.getState(selectedItemKey)
    
    if not currentSelection then
        -- Clear all selections if nothing is selected
        self:ClearAllSelections()
        return
    end

    -- Get the selected item ID based on the state manager key
    local selectedId = nil
    if self.stateManagerKey == "character" then
        selectedId = currentSelection.characterId
    elseif self.stateManagerKey == "faction" then
        selectedId = currentSelection.factionId
    else
        selectedId = currentSelection.itemId
    end

    if not selectedId then
        self:ClearAllSelections()
        return
    end

    -- Update visual selection for all visible items
    self:UpdateVisualSelection(selectedId)
end

function VerticalListMixin:ClearAllSelections()
    -- Clear visual selection from all visible list items
    if not self.PagedItemList then
        return
    end
    
    local frames = self.PagedItemList:GetFrames()
    if frames then
        for _, frame in pairs(frames) do
            if frame.SetSelected then
                frame:SetSelected(false)
            end
        end
    end
end

function VerticalListMixin:UpdateVisualSelection(selectedId)
    -- Update visual selection to match the selected item ID
    if not self.PagedItemList or not selectedId then
        return
    end
    
    local frames = self.PagedItemList:GetFrames()
    if frames then
        for _, frame in pairs(frames) do
            if frame.Item and frame.Item.id and frame.SetSelected then
                local isSelected = (frame.Item.id == selectedId)
                frame:SetSelected(isSelected)
            end
        end
    end
end
