local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

--[[
    VerticalCharacterList - Alternative Character List Implementation
    
    DESIGN INSPIRATION:
    - Based on WoW's character selection frame title list layout
    - Vertical scrolling list as an alternative to horizontal character lists
    - Compact character entries with name and status information
    - Clean, minimal design that works as a standalone character selector
    
    FEATURES:
    - Vertical list of characters with scroll support
    - Character selection integration with state management
    - Hover effects and visual feedback
    - Responsive to character data changes
    - Works independently from character book
    
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

    local statusText = ""
    if self.Character.yearStart then
        if self.Character.yearEnd then
            statusText = tostring(self.Character.yearStart) .. " - " .. tostring(self.Character.yearEnd)
        else
            statusText = "From " .. tostring(self.Character.yearStart)
        end
    elseif self.Character.yearEnd then
        statusText = "Died " .. tostring(self.Character.yearEnd)
    else
        statusText = "Timeline unknown"
    end

    if self.CharacterStatus then
        self.CharacterStatus:SetText(statusText)
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

    if self:GetParent() and self:GetParent():GetParent() and self:GetParent():GetParent().UpdateSelectionStates then
        self:GetParent():GetParent():UpdateSelectionStates(self)
    end
end

function VerticalCharacterListItemMixin:OnEnter()
    if self.HoverHighlight then
        self.HoverHighlight:Show()
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)

    if self.Character then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.Character.name or "Character", 1, 1, 1)

        if self.Character.id then
            GameTooltip:AddLine("ID: " .. tostring(self.Character.id), 0.7, 0.8, 0.9)
        end

        local yearText = ""
        if self.Character.yearStart then
            if self.Character.yearEnd then
                yearText = "Active: " .. tostring(self.Character.yearStart) .. " - " .. tostring(self.Character.yearEnd)
            else
                yearText = "Active from: " .. tostring(self.Character.yearStart)
            end
            GameTooltip:AddLine(yearText, 0.7, 0.8, 0.9)
        elseif self.Character.yearEnd then
            GameTooltip:AddLine("Died: " .. tostring(self.Character.yearEnd), 0.7, 0.8, 0.9)
        end

        if self.Character.timeline then
            GameTooltip:AddLine("Timeline: " .. tostring(self.Character.timeline), 0.7, 0.8, 0.9)
        end

        if self.Character.author then
            GameTooltip:AddLine("Author: " .. self.Character.author, 0.6, 0.7, 0.8)
        end

        if self.Character.biography then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Biography:", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(self.Character.biography, 0.7, 0.7, 0.7, true)
        end

        if self.Character.factions and #self.Character.factions > 0 then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Associated Factions:", 0.8, 0.8, 0.8)
            for i, faction in ipairs(self.Character.factions) do
                if faction and faction.name then
                    GameTooltip:AddLine("• " .. faction.name, 0.7, 0.7, 0.7)
                end
            end
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
            if self.LeftBorder then
                self.LeftBorder:SetColorTexture(0.0, 0.7, 1.0, 1.0)
            end
        else
            self.SelectionHighlight:Hide()
            if self.LeftBorder then
                self.LeftBorder:SetColorTexture(0.3, 0.4, 0.6, 0.7)
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

    private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)
    private.Core.registerCallback(private.constants.events.AddonStartup, self.OnAddonStartup, self)
end

function VerticalCharacterListMixin:OnShow()
    self:RefreshCharacterList()
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

    self:ClearCharacterItems()

    local contentFrame = self.CharacterScrollFrame.Content
    local yOffset = 0
    local itemHeight = 34
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

function VerticalCharacterListMixin:SearchCharacters(searchTerm)
    if not searchTerm or searchTerm == "" then
        self:RefreshCharacterList()
        return
    end

    local characters = private.Core.Cache and private.Core.Cache.getSearchCharacters(searchTerm) or {}

    if not characters then
        self:UpdateCharacterCount(0)
        return
    end

    self:ClearCharacterItems()

    local contentFrame = self.CharacterScrollFrame.Content
    local yOffset = 0
    local itemHeight = 34
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
end
