local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
    VerticalCharacterList - Alternative Character List Implementation
    
    DESIGN INSPIRATION:
    - Based on WoW's character selection frame title list layout
    - Vertical scrolling list as an alternative to horizontal character lists
    - Clean, minimal character entries displaying only character names
    - Simple design that works as a standalone character selector
    
    FEATURES:
    - Vertical list of characters with scroll support
    - Character selection integration with state management
    - Hover effects and visual feedback
    - Responsive to character data changes
    - Works independently from character book
    - Displays only character names for clean, uncluttered UI
    
    LAYOUT:
    - Fixed width (220px) designed as alternative to horizontal lists
    - Variable height items (32px each) for compact display
    - Scroll frame for handling large character lists
    - Header with character count and refresh functionality
--]]
-- -------------------------
-- Vertical Character List Item
-- -------------------------
VerticalCharacterListItemMixin = {}

function VerticalCharacterListItemMixin:Init(characterData)
    if not characterData or not characterData.character then
        return
    end

    self.Character = characterData.character

    if self.Character.name then
        self.CharacterName:SetText(self.Character.name)
    else
        self.CharacterName:SetText("Unknown Character")
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
    if self.HoverHighlight then
        self.HoverHighlight:Show()
    end

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
    if self.HoverHighlight then
        self.HoverHighlight:Hide()
    end

    GameTooltip:Hide()
end

function VerticalCharacterListItemMixin:SetSelected(selected)
    if self.SelectionHighlight then
        if selected then
            self.SelectionHighlight:Show()
            if self.StatusIndicator then
                self.StatusIndicator:SetColorTexture(0.0, 0.7, 1.0, 1.0)
            end
        else
            self.SelectionHighlight:Hide()
            if self.StatusIndicator then
                self.StatusIndicator:SetColorTexture(0.3, 0.4, 0.6, 0.7) -- Default color
            end
        end
    end
end

-- -------------------------
-- Vertical Character List
-- -------------------------
VerticalCharacterListMixin = {}

function VerticalCharacterListMixin:OnLoad()
    if self.HeaderText then
        self.HeaderText:SetText("Characters")
    end

    self.characterItems = {}
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
                    -- Find the character item that corresponds to this selection
                    local characterId = newCharacterSelection.characterId or newCharacterSelection
                    for _, item in pairs(self.characterItems) do
                        if item.Character and item.Character.id == characterId then
                            self:UpdateSelectionStates(item)
                            break
                        end
                    end
                end
            end,
            "VerticalCharacterListMixin"
        )
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
    self:ClearCharacterItems()

    local contentFrame = self.CharacterScrollFrame.Content
    local yOffset = 0
    local itemHeight = 24 -- Compact height for character name only display
    local itemCount = 0

    for _, character in pairs(characters) do
        if character and type(character) == "table" and character.name then
            local characterItem = CreateFrame("Button", nil, contentFrame, "VerticalCharacterListItemTemplate")
            if characterItem then
                characterItem:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -yOffset)
                characterItem:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -yOffset)

                local characterData = {
                    character = character
                }
                characterItem:Init(characterData)

                table.insert(self.characterItems, characterItem)
                yOffset = yOffset + itemHeight
                itemCount = itemCount + 1
            end
        end
    end

    if contentFrame then
        contentFrame:SetHeight(math.max(yOffset, 1))
    end

    self:UpdateCharacterCount(itemCount)

    -- Check for existing character selection and update display accordingly
    self:SyncWithCurrentSelection()
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

function VerticalCharacterListMixin:ClearCharacterItems()
    for _, item in ipairs(self.characterItems) do
        if item then
            item:Hide()
            item:SetParent(nil)
        end
    end
    self.characterItems = {}
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

function VerticalCharacterListMixin:UpdateSelectionStates(selectedItem)
    for _, item in ipairs(self.characterItems) do
        if item then
            item:SetSelected(item == selectedItem)
        end
    end
    self.selectedCharacter = selectedItem
end

function VerticalCharacterListMixin:SyncWithCurrentSelection()
    -- Check if there's already a selected character in StateManager
    if private.Core.StateManager then
        local selectedCharacterKey = private.Core.StateManager.buildSelectionKey("character")
        local currentSelection = private.Core.StateManager.getState(selectedCharacterKey)

        if currentSelection then
            -- Find the character item that corresponds to this selection
            local characterId = currentSelection.characterId or currentSelection

            for _, item in pairs(self.characterItems) do
                if item.Character and item.Character.id == characterId then
                    self:UpdateSelectionStates(item)
                    break
                end
            end
        end
    end
end
