local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

local Spacing = private.Core.Utils.Spacing

--[[
    Shared Vertical List Template

    The scrolling rail used by both the Characters and the Factions tabs: bookmark-styled rows, a
    search box, and a count label. Two virtual templates specialise it, each calling
    VerticalListMixin.OnLoad followed by ConfigureForCharacters or ConfigureForFactions.

    Specialisation happens in Lua, not through XML KeyValues. Two constraints force that: the
    user-visible strings must come from the locale table, which XML cannot reach, and the ConfigureFor*
    call runs immediately after OnLoad in the same <OnLoad> block, so Lua assignments would win over
    KeyValues regardless.

    stateManagerKey doubles as a guard: while it is still "generic" the frame is unconfigured, so item
    clicks, state subscriptions and selection sync all no-op rather than writing to a bogus state key.
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

    -- itemType and stateManagerKey both travel in the element data rather than being read back up
    -- the frame chain: scroll-box rows are parented to the scroll target, so the old
    -- GetParent():GetParent() walk no longer reaches the list frame that owns the configuration.
    self.ItemType = itemData.itemType or "generic"
    self.stateManagerKey = itemData.stateManagerKey or "generic"

    local textElement = self.ItemName or self.CharacterName -- Support both field names for compatibility
    if textElement then
        textElement:SetText(item.name)
        textElement:SetWordWrap(true)
        textElement:SetMaxLines(2)
        textElement:SetJustifyV("MIDDLE")
    end

    -- Texture and text placement is entirely the template's, not re-applied per row. The old
    -- ClearAllPoints/SetPoint pass here reproduced the XML anchors, and would now override the
    -- Content texture's two-point stretch with a single point, collapsing it to zero width.

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

            -- Build appropriate state data based on item type. The field name is not cosmetic: each
            -- book consumer in MainFrameUI reads exactly one of eventId / characterId / factionId and
            -- silently shows the empty book for anything else, so a row whose type has no branch here
            -- looks like it does nothing when clicked.
            if stateManagerKey == "character" then
                stateData = {characterId = itemId, collectionName = collectionName}
            elseif stateManagerKey == "faction" then
                stateData = {factionId = itemId, collectionName = collectionName}
            elseif stateManagerKey == "event" then
                -- Dedup, carried over from the Events tab's own row handler when the two templates
                -- merged: re-selecting the event that is already open is a no-op rather than a
                -- redundant state write. Characters and factions deliberately keep re-writing, which
                -- is how a book that failed to render once can be reopened by clicking the row again.
                local currentSelection = private.Core.StateManager.getState(selectionKey)
                if
                    currentSelection and currentSelection.eventId == itemId and
                        currentSelection.collectionName == collectionName
                 then
                    self:SetSelected(true)
                    return
                end

                stateData = {eventId = itemId, collectionName = collectionName}
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
        GameTooltip:SetText(self.Item.name or Locale["TooltipDefaultItemName"], 1, 1, 1)

        -- Add contextual information based on item type
        if self.Item.chapters and #self.Item.chapters > 0 then
            GameTooltip:AddLine(string.format(Locale["TooltipChapterCount"], #self.Item.chapters), 0.6, 0.8, 0.6)
        end

        if self.Item.author then
            GameTooltip:AddLine(string.format(Locale["TooltipCreatedBy"], self.Item.author), 0.7, 0.7, 0.7)
        end

        -- Add item type specific information
        local itemType = self.ItemType
        if itemType == "faction" and self.Item.allegiance then
            GameTooltip:AddLine(string.format(Locale["TooltipAllegiance"], self.Item.allegiance), 0.8, 0.8, 0.6)
        elseif itemType == "character" and self.Item.race then
            GameTooltip:AddLine(string.format(Locale["TooltipRace"], self.Item.race), 0.6, 0.8, 1.0)
        end

        GameTooltip:Show()
    end
end

function VerticalListItemMixin:OnLeave()
    GameTooltip:Hide()
end

function VerticalListItemMixin:SetSelected(selected)
    -- Maintain internal selection state for consistency
    self.isSelected = selected

    -- Light the bookmark plate. Guarded on the texture rather than assumed: SetSelected is also
    -- called from Init, which can run before a template revision that lacks SelectedGlow is reloaded.
    if self.SelectedGlow then
        self.SelectedGlow:SetShown(selected)
    end
end

-- -------------------------
-- Shared Vertical List Mixin
-- -------------------------
VerticalListMixin = {}

function VerticalListMixin:OnLoad()
    -- Configuration lives here rather than in XML KeyValues: the specialised rails call
    -- ConfigureFor* immediately after this function, so Lua wins either way, and the user-visible
    -- strings have to come from the locale table, which XML cannot reach.
    self.itemType = "generic"
    self.searchPlaceholder = Locale["SearchPlaceholder"]
    self.countLabelFormat = Locale["ListCountItems"]
    self.enableSearch = true
    self.enableCount = true
    self.stateManagerKey = "generic"
    self.templateKey = private.constants.templateKeys.GENERIC_LIST_ITEM

    -- Initialize state
    self.selectedItem = nil
    self.allItems = {}
    self.currentSearchTerm = ""
    -- Set by EntityFilterStripTemplate's chips; a value the search box cannot express
    self.currentFieldFilter = nil

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

    self:InitializeItemList()
end

--[[
    Wire the scroll box to its scroll bar with a linear, single-column view

    The rail scrolls rather than pages, so there is no page to turn and no paging control. The row
    template is still resolved through the shared template registry, keeping
    templateKeys.GENERIC_LIST_ITEM the single source of truth for what a row looks like.
]]
function VerticalListMixin:InitializeItemList()
    if self._itemViewReady or not self.ItemList or not self.ItemListScrollBar then
        return
    end

    local templates = private.constants and private.constants.templates
    local rowTemplate = templates and templates[private.constants.templateKeys.GENERIC_LIST_ITEM]
    if not rowTemplate or not rowTemplate.template then
        return
    end

    local view = CreateScrollBoxListLinearView(Spacing.xs, Spacing.xs, 0, 0, Spacing.xs)
    view:SetElementInitializer(
        rowTemplate.template,
        function(row, elementData)
            row:Init(elementData)
        end
    )
    -- Fixed row height; skips the per-frame measurement pass that can otherwise yield a zero extent.
    -- Must stay equal to VerticalListItemTemplate's <Size y> in VerticalListTemplate.xml: the view
    -- sizes rows from this number, so changing only the XML moves nothing.
    view:SetElementExtent(88)

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ItemList, self.ItemListScrollBar, view)
    self._itemViewReady = true
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
-- Built-in configuration for character lists
function VerticalListMixin:ConfigureForCharacters()
    self.itemType = "character"
    self.searchPlaceholder = Locale["SearchCharactersPlaceholder"]
    self.countLabelFormat = Locale["ListCountCharacters"]
    self.stateManagerKey = "character"
    self.templateKey = private.constants.templateKeys.GENERIC_LIST_ITEM

    -- Update search placeholder if search box exists
    if self.SearchBox and self.SearchBox.PlaceholderText then
        self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
    end

    self:InitializeStateSubscriptions()
end

-- Built-in configuration for faction lists
function VerticalListMixin:ConfigureForFactions()
    self.itemType = "faction"
    self.searchPlaceholder = Locale["SearchFactionsPlaceholder"]
    self.countLabelFormat = Locale["ListCountFactions"]
    self.stateManagerKey = "faction"
    self.templateKey = private.constants.templateKeys.GENERIC_LIST_ITEM

    -- Update search placeholder if search box exists
    if self.SearchBox and self.SearchBox.PlaceholderText then
        self.SearchBox.PlaceholderText:SetText(self.searchPlaceholder)
    end

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

--[[
    Flatten a keyed item collection into a name-ordered array

    The data sources hand back tables keyed by id, so pairs() order is undefined and the rail would
    render in a different order from one refresh to the next. Sorting by name, with id as the
    tiebreak, makes the order stable and alphabetical.

    @param items [table] Item collection, keyed or sequential
    @return [table] Sequential array of items that have a name
]]
local function toSortedItemArray(items)
    local sorted = {}

    for _, item in pairs(items) do
        if item and item.name then
            table.insert(sorted, item)
        end
    end

    table.sort(
        sorted,
        function(left, right)
            if left.name == right.name then
                return tostring(left.id) < tostring(right.id)
            end
            return left.name < right.name
        end
    )

    return sorted
end

function VerticalListMixin:RefreshItemList()
    local items = self:GetDataFromSource()

    if not items then
        return
    end

    -- Cache all items for search performance, in stable display order
    self.allItems = toSortedItemArray(items)

    -- Both filters, in order: the name term from the search box or the strip's letter row, then the
    -- field value from the strip's chips. They narrow together.
    local filteredItems = self:FilterItemsByName(self.allItems, self.currentSearchTerm)
    filteredItems = self:FilterItemsByField(filteredItems, self.currentFieldFilter)

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
    items = items or {}

    -- The scroll box takes one flat element per row; the previous paged grid needed the extra
    -- {{elements = {...}}} nesting to describe a page, and there are no pages any more.
    local elements = {}

    for _, item in ipairs(items) do
        table.insert(
            elements,
            {
                templateKey = self.templateKey or private.constants.templateKeys.GENERIC_LIST_ITEM,
                item = item,
                -- itemType and stateManagerKey travel with each row; see VerticalListItemMixin:Init
                itemType = self.itemType,
                stateManagerKey = self.stateManagerKey
            }
        )
    end

    self:SetItemDataProvider(elements)
    self:UpdateItemCount(#elements)

    -- Sync selection state after data update
    self:SyncWithCurrentSelection()
end

function VerticalListMixin:SetItemDataProvider(elements)
    -- Ensure the view is attached before assigning a data provider
    self:InitializeItemList()

    if not self._itemViewReady or not self.ItemList.SetDataProvider then
        return
    end

    self.ItemList:SetDataProvider(CreateDataProvider(elements or {}), ScrollBoxConstants.RetainScrollPosition)
end

--[[
    Filter the rail by name.

    Two match modes. A term beginning with "^" is an *anchored* match on the first character, which is
    what the A to Z jump row in EntityFilterStripTemplate writes: clicking "S" must show names starting
    with S, not every name containing one. Anything else is the plain substring match a typed search
    wants, so "sun" still finds "The Sundering".

    The caret is a deliberate reuse of Lua pattern syntax as a marker, not a pattern: the rest of the
    term is still matched literally, so a name containing pattern characters cannot break the search.

    @param items [table] Sequential array of entries, already sorted
    @param searchTerm [string|nil]
    @return [table] Sequential array
]]
function VerticalListMixin:FilterItemsByName(items, searchTerm)
    if not searchTerm or searchTerm == "" then
        return items
    end

    local filtered = {}
    local anchored = string.sub(searchTerm, 1, 1) == "^"
    local needle = string.lower(anchored and string.sub(searchTerm, 2) or searchTerm)

    if needle == "" then
        return items
    end

    -- Sequential in, sequential out: the caller passes an already-sorted array, and preserving the
    -- source keys here (as the previous pairs() version did) would reintroduce undefined order.
    for _, item in ipairs(items) do
        if item.name then
            local name = string.lower(item.name)
            local matches
            if anchored then
                matches = string.sub(name, 1, #needle) == needle
            else
                matches = string.find(name, needle, 1, true) ~= nil
            end

            if matches then
                table.insert(filtered, item)
            end
        end
    end

    return filtered
end

--[[
    Filter the rail by an allegiance or race value.

    Separate from the name filter because it reads a different field: the filter strip's chips select a
    value the search box has no way to express. Both are applied, so a chip and a typed term narrow
    together rather than replacing each other.

    @param items [table] Sequential array of entries
    @param value [string|nil] Exact field value, nil for no field filter
    @return [table] Sequential array
]]
function VerticalListMixin:FilterItemsByField(items, value)
    if not value or value == "" then
        return items
    end

    local filtered = {}
    for _, item in ipairs(items) do
        if item.allegiance == value or item.race == value then
            table.insert(filtered, item)
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

function VerticalListMixin:ForEachRenderedRow(callback)
    -- Guard on the view being wired: ForEachFrame on a ScrollBox with no view indexes a nil view
    -- and errors. Selection sync can fire during login rehydration, before the first data provider.
    if not callback or not self._itemViewReady or type(self.ItemList.ForEachFrame) ~= "function" then
        return
    end

    self.ItemList:ForEachFrame(callback)
end

function VerticalListMixin:SyncWithCurrentSelection()
    -- Synchronize visual selection state with the stored state
    if not private.Core.StateManager or not self.stateManagerKey or self.stateManagerKey == "generic" then
        return
    end
    
    if not self.ItemList then
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
    -- Clear visual selection from all rows the scroll box currently has realised
    if not self.ItemList then
        return
    end

    self:ForEachRenderedRow(
        function(row)
            if row and row.SetSelected then
                row:SetSelected(false)
            end
        end
    )
end

function VerticalListMixin:UpdateVisualSelection(selectedId)
    -- Update visual selection to match the selected item ID
    if not self.ItemList or not selectedId then
        return
    end

    self:ForEachRenderedRow(
        function(row)
            if row and row.Item and row.Item.id and row.SetSelected then
                row:SetSelected(row.Item.id == selectedId)
            end
        end
    )
end
