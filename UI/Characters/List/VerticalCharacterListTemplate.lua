local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
    VerticalCharacterList - Bookmark-Style Character List Implementation
    
    DESIGN ALIGNMENT:
    - Redesigned to match Chronicles addon's established bookmark design patterns
    - Uses the same bookmark textures as EventListItemTemplate and FactionListItemTemplate
    - Consistent typography using ChroniclesFontFamily_Text_Medium and ChroniclesFontFamily_Text_Shadow_Small
    - Applies WHITE_FONT_COLOR scheme for visual consistency
    - Maintains 150x110 sizing pattern used throughout the addon
    
    FEATURES:
    - Vertical list of characters with bookmark-style visual treatment
    - Character selection integration with state management
    - Enhanced visual hierarchy with proper spacing and typography
    - Responsive to character data changes
    - Works independently from character book
    - Search functionality with book-style background textures
    - Tooltip integration for character information
    
    LAYOUT:
    - Fixed width (160px) with bookmark texture styling
    - Character items sized at 150x110px to match other list components
    - Scroll frame for handling large character lists with proper spacing
    - Book-style background using spellbook textures
    - Header with character count using Chronicles font family
--]]
-- -------------------------
-- Vertical Character List Item
-- -------------------------
VerticalCharacterListItemMixin = {}

function VerticalCharacterListItemMixin:Init(characterData)
    if not characterData then
        return
    end

    -- Handle both direct character data and paged list data structure
    local character = characterData.character or characterData

    if not character or not character.name then
        return
    end

    self.Character = character

    -- Set up bookmark textures similar to EventListItemTemplate
    local contentTexture = self.Content
    local sideTexture = self.Side
    local textElement = self.CharacterName

    -- Set character name
    textElement:SetText(character.name)

    -- Set texture coordinates for left orientation (default)
    if contentTexture then
        contentTexture:SetTexCoord(0, 1, 0, 1)
        contentTexture:ClearAllPoints()
        contentTexture:SetPoint("RIGHT", self, nil, 0, 0)
    end

    if sideTexture then
        sideTexture:SetTexCoord(0, 1, 0, 1)
        sideTexture:ClearAllPoints()
        sideTexture:SetPoint("LEFT", self, nil, 0, 0)
    end

    if textElement then
        textElement:ClearAllPoints()
        textElement:SetPoint("LEFT", self, nil, 0, 0)
    end

    self:SetSelected(false)
end

function VerticalCharacterListItemMixin:OnClick()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    if private.Core.StateManager then
        local characterId = self.Character and self.Character.id or nil
        local collectionName = self.Character and self.Character.source or nil

        if characterId and collectionName then
            local characterSelection = {
                characterId = characterId,
                collectionName = collectionName
            }

            private.Core.StateManager.setState(
                private.Core.StateManager.buildSelectionKey("character"),
                characterSelection,
                "Character selected from vertical list: " ..
                    tostring(characterId) .. " (" .. tostring(collectionName) .. ")"
            )
        end
    end

    self:SetSelected(true)
    -- Use state-based approach only - consistent with event selection pattern
    -- The CharacterBookTemplate subscribes to state changes instead of listening for events
end

function VerticalCharacterListItemMixin:OnEnter()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)

    if self.Character then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.Character.name or "Character", 1, 1, 1)

        -- Add content information if available
        if self.Character.chapters and #self.Character.chapters > 0 then
            GameTooltip:AddLine("Available Content: " .. #self.Character.chapters .. " chapters", 0.6, 0.8, 0.6)
        end

        -- Add author information if available
        if self.Character.author then
            GameTooltip:AddLine("Created by: " .. self.Character.author, 0.7, 0.7, 0.7)
        end

        GameTooltip:Show()
    end
end

function VerticalCharacterListItemMixin:OnLeave()
    GameTooltip:Hide()
end

function VerticalCharacterListItemMixin:SetSelected(selected)
    -- Since we're using bookmark textures, we don't need selection highlights
    -- The visual feedback is provided by hover effects and the book-style appearance
    -- Keep the same internal tracking for consistency with other templates
    if selected then
        -- Optional: Could add a subtle glow or border effect here
    else
        -- Reset any selection effects
    end
end

-- -------------------------
-- Vertical Character List
-- -------------------------
VerticalCharacterListMixin = {}

function VerticalCharacterListMixin:OnLoad()
    self.selectedCharacter = nil
    self.allCharacters = {} -- Cache of all characters for search performance
    self.currentSearchTerm = ""

    -- Initialize search box
    if self.SearchBox then
        self.SearchBox:SetScript(
            "OnTextChanged",
            function(editBox, userInput)
                if userInput then
                    self:OnSearchTextChanged(editBox:GetText())
                end
            end
        )
        self.SearchBox:SetScript(
            "OnEnterPressed",
            function(editBox)
                editBox:ClearFocus()
            end
        )
        self.SearchBox:SetScript(
            "OnEscapePressed",
            function(editBox)
                editBox:SetText("")
                editBox:ClearFocus()
            end
        )
    end

    private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
    private.Core.registerCallback(private.constants.events.AddonStartup, self.OnAddonStartup, self)

    -- Use state-based subscription for character selection - consistent with event selection pattern
    if private.Core.StateManager then
        local selectedCharacterKey = private.Core.StateManager.buildSelectionKey("character")
        private.Core.StateManager.subscribe(
            selectedCharacterKey,
            function(newCharacterSelection, oldCharacterSelection)
                if newCharacterSelection then
                    self:SyncWithCurrentSelection()
                end
            end,
            "VerticalCharacterListMixin"
        )
    end

    -- Initialize the paged character list with template data
    if self.PagedCharacterList and private.constants and private.constants.templates then
        self.PagedCharacterList:SetElementTemplateData(private.constants.templates)
    end
end

function VerticalCharacterListMixin:InitializeSearchPlaceholder()
    if self.SearchBox and self.SearchBox.PlaceholderText then
        self.SearchBox.PlaceholderText:SetText(Locale["SearchCharactersPlaceholder"])
        self.SearchBox.PlaceholderText:Show()
    end
end

function VerticalCharacterListMixin:OnShow()
    self:RefreshCharacterList()
    -- Ensure selection state is synced when the UI becomes visible
    self:SyncWithCurrentSelection()
end

function VerticalCharacterListMixin:OnUIRefresh()
    self:RefreshCharacterList()
end

function VerticalCharacterListMixin:OnAddonStartup()
    self:RefreshCharacterList()
end

function VerticalCharacterListMixin:RefreshCharacterList()
    local characters = private.Core.Cache and private.Core.Cache.getAllCharacters() or {}

    if not characters then
        self:UpdateCharacterCount(0)
        self:SetCharacterDataProvider({})
        return
    end

    -- Cache all characters for search performance
    self.allCharacters = characters

    -- Apply current search filter if any
    local filteredCharacters =
        self.currentSearchTerm and self.currentSearchTerm ~= "" and
        self:FilterCharactersByName(characters, self.currentSearchTerm) or
        characters

    self:DisplayCharacters(filteredCharacters)
end

function VerticalCharacterListMixin:DisplayCharacters(characters)
    local content = {
        elements = {}
    }

    local characterCount = 0
    for _, character in pairs(characters) do
        if character and type(character) == "table" and character.name then
            local characterSummary = {
                templateKey = private.constants.templateKeys.VERTICAL_CHARACTER_LIST_ITEM,
                text = character.name,
                character = character
            }
            table.insert(content.elements, characterSummary)
            characterCount = characterCount + 1
        end
    end

    local data = {}
    table.insert(data, content)

    self:SetCharacterDataProvider(data)
    self:UpdateCharacterCount(characterCount)

    -- Check for existing character selection and update display accordingly
    self:SyncWithCurrentSelection()
end

function VerticalCharacterListMixin:SetCharacterDataProvider(data)
    if self.PagedCharacterList then
        local dataProvider = CreateDataProvider(data)
        local retainScrollPosition = false
        self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
    end
end

function VerticalCharacterListMixin:FilterCharactersByName(characters, searchTerm)
    if not searchTerm or searchTerm == "" then
        return characters
    end

    local filtered = {}
    local lowerSearchTerm = string.lower(searchTerm)

    for _, character in pairs(characters) do
        if character.name then
            local lowerName = string.lower(character.name)
            if string.find(lowerName, lowerSearchTerm, 1, true) then
                filtered[character.id] = character
            end
        end
    end

    return filtered
end

function VerticalCharacterListMixin:OnSearchTextChanged(text)
    self.currentSearchTerm = text

    -- Throttle search to avoid too many updates
    if self.searchThrottle then
        C_Timer.After(
            0.3,
            function()
                if self.currentSearchTerm == text then -- Only search if text hasn't changed
                    local filteredCharacters = self:FilterCharactersByName(self.allCharacters, text)
                    self:DisplayCharacters(filteredCharacters)
                end
            end
        )
    else
        self.searchThrottle = true
        C_Timer.After(
            0.3,
            function()
                self.searchThrottle = nil
                local filteredCharacters = self:FilterCharactersByName(self.allCharacters, self.currentSearchTerm)
                self:DisplayCharacters(filteredCharacters)
            end
        )
    end
end

function VerticalCharacterListMixin:UpdateCharacterCount(count)
    if self.CountLabel then
        if count == 0 then
            self.CountLabel:SetText("No characters")
        elseif count == 1 then
            self.CountLabel:SetText("1 character")
        else
            self.CountLabel:SetText(count .. " characters")
        end
    end
end

function VerticalCharacterListMixin:SyncWithCurrentSelection()
    -- The paged list handles selection internally through the item mixins
    -- This method is kept for compatibility but the actual selection sync
    -- is handled by the individual items through state management
    if private.Core.StateManager then
        local selectedCharacterKey = private.Core.StateManager.buildSelectionKey("character")
        local currentSelection = private.Core.StateManager.getState(selectedCharacterKey)

    -- The selection state is now handled by individual character items
    -- when they are created and initialized through the paged list system
    end
end
