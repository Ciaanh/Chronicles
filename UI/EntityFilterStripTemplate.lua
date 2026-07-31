local FOLDER_NAME, private = ...

local Spacing = private.Core.Utils.Spacing

--[[
    EntityFilterStripTemplate.lua

    The filter strip above the Characters and Factions rails.

    Two rows, both driving the rail's own currentSearchTerm so there is exactly one filter in play:

      * An A to Z jump row. Clicking a letter sets the term to "^<letter>", which the rail's
        FilterItemsByName understands as an anchored match. Letters with no entries behind them are drawn
        dim and stop responding.
      * Allegiance and race chips, built from the distinct values actually present in the rail's entries
        rather than from a hardcoded list, because both fields are free text authored per record.

    The strip owns no data. It reads the rail's allItems and writes the rail's search term, so a change of
    collection or a settings toggle refreshes it through the same path that refreshes the rail.
]]

-- =============================================================================================
-- LETTER
-- =============================================================================================

EntityFilterLetterMixin = {}

--[[
    @param letter [string] The single character this button jumps to
    @param strip [table] The owning strip
    @param hasEntries [boolean] Whether any entry starts with this letter
]]
function EntityFilterLetterMixin:Init(letter, strip, hasEntries)
    self.letter = letter
    self.strip = strip
    self.hasEntries = hasEntries

    self.Text:SetText(letter)
    self:SetEnabled(hasEntries)

    -- Dim rather than hidden: the alphabet is a fixed target the reader aims at by position, and a row
    -- with holes in it is harder to use than one with greyed-out letters.
    if hasEntries then
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    else
        self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end

    self:SetSelected(false)
end

function EntityFilterLetterMixin:SetSelected(selected)
    self.isSelected = selected

    if self.SelectedGlow then
        self.SelectedGlow:SetShown(selected)
    end
end

function EntityFilterLetterMixin:OnClick()
    if not self.hasEntries or not self.strip then
        return
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    self.strip:ToggleLetter(self.letter)
end

function EntityFilterLetterMixin:OnEnter()
    if self.HighlightTexture and self.hasEntries then
        self.HighlightTexture:Show()
    end
end

function EntityFilterLetterMixin:OnLeave()
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end
end

-- =============================================================================================
-- CHIP
-- =============================================================================================

EntityFilterChipMixin = {}

--[[
    @param value [string] The allegiance or race this chip filters to
    @param strip [table] The owning strip
]]
function EntityFilterChipMixin:Init(value, strip)
    self.value = value
    self.strip = strip

    self.Text:SetText(value)
    self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    self:SetSelected(false)
end

function EntityFilterChipMixin:SetSelected(selected)
    self.isSelected = selected

    if self.SelectedGlow then
        self.SelectedGlow:SetShown(selected)
    end
end

function EntityFilterChipMixin:OnClick()
    if not self.strip then
        return
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    self.strip:ToggleChip(self.value)
end

function EntityFilterChipMixin:OnEnter()
    if self.value then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.value, HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end
end

function EntityFilterChipMixin:OnLeave()
    GameTooltip:Hide()
end

-- =============================================================================================
-- STRIP
-- =============================================================================================

EntityFilterStripMixin = {}

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local LETTER_WIDTH = 40
local CHIP_WIDTH = 120
local MAX_CHIPS = 8

function EntityFilterStripMixin:OnLoad()
    self.letterPool = {}
    self.chipPool = {}
    self.activeLetter = nil
    self.activeChip = nil

    -- Refreshed on the same signals the rail is: a collection toggle or an event-type toggle changes
    -- which entries exist, and therefore which letters and chips are live.
    private.Core.registerCallback(private.constants.events.UIRefresh, self.Refresh, self)
    private.Core.registerCallback(private.constants.events.AddonStartup, self.Refresh, self)
end

--[[
    Which rail this strip filters.

    The strip is a sibling of the rail inside a tab frame, and the tabs name their rails differently
    (MyCharacterList, MyFactionList), so the link is made by looking for the one sibling that carries the
    rail's contract rather than by hardcoding a key per tab.

    @return [table|nil]
]]
function EntityFilterStripMixin:GetRail()
    if self.rail then
        return self.rail
    end

    local parent = self:GetParent()
    if not parent then
        return nil
    end

    for _, child in ipairs({parent:GetChildren()}) do
        if child ~= self and type(child.FilterItemsByName) == "function" and child.allItems then
            self.rail = child
            return child
        end
    end

    return nil
end

--[[
    Rebuild both rows from what the rail currently holds.

    Pooled, like the timeline's periods: the alphabet is fixed at 26 but the chip set is data-driven, and
    creating frames per refresh would leak one set per settings toggle.
]]
function EntityFilterStripMixin:Refresh()
    local rail = self:GetRail()
    if not rail then
        return
    end

    local items = rail.allItems or {}

    self:BuildLetterRow(items)
    self:BuildChipRow(items)
end

--[[
    @param items [table] The rail's entries
]]
function EntityFilterStripMixin:BuildLetterRow(items)
    local UIUtils = private.Core.Utils.UIUtils
    if not UIUtils or not self.LetterRow then
        return
    end

    -- Which initials are represented, so a letter with nothing behind it can be dimmed
    local present = {}
    for _, item in ipairs(items) do
        if item.name and item.name ~= "" then
            present[string.upper(string.sub(item.name, 1, 1))] = true
        end
    end

    for index = 1, #ALPHABET do
        local letter = string.sub(ALPHABET, index, index)
        local button = UIUtils.AcquirePooledFrame(self.letterPool, "EntityFilterLetterTemplate", self.LetterRow, index, "Button")

        button:ClearAllPoints()
        if index == 1 then
            button:SetPoint("LEFT", self.LetterRow, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", self.letterPool[index - 1], "RIGHT", Spacing.xs, 0)
        end
        button:SetWidth(LETTER_WIDTH)

        button:Init(letter, self, present[letter] == true)
        if self.activeLetter == letter then
            button:SetSelected(true)
        end
    end

    UIUtils.ReleaseFramesAbove(self.letterPool, #ALPHABET)
end

--[[
    Build the chip row from the distinct allegiance or race values present.

    Both fields are free text on the record, so the set cannot be hardcoded: it is whatever the content
    happens to use. Capped, because nothing bounds how many distinct values a collection may carry and a
    row that wraps would eat the band the strip is here to fill.

    @param items [table] The rail's entries
]]
function EntityFilterStripMixin:BuildChipRow(items)
    local UIUtils = private.Core.Utils.UIUtils
    if not UIUtils or not self.ChipRow then
        return
    end

    local seen = {}
    local values = {}
    for _, item in ipairs(items) do
        local value = item.allegiance or item.race
        if value and value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(values, value)
        end
    end

    table.sort(values)

    local count = math.min(#values, MAX_CHIPS)
    for index = 1, count do
        local chip = UIUtils.AcquirePooledFrame(self.chipPool, "EntityFilterChipTemplate", self.ChipRow, index, "Button")

        chip:ClearAllPoints()
        if index == 1 then
            chip:SetPoint("LEFT", self.ChipRow, "LEFT", 0, 0)
        else
            chip:SetPoint("LEFT", self.chipPool[index - 1], "RIGHT", Spacing.sm, 0)
        end
        chip:SetWidth(CHIP_WIDTH)

        chip:Init(values[index], self)
        if self.activeChip == values[index] then
            chip:SetSelected(true)
        end
    end

    UIUtils.ReleaseFramesAbove(self.chipPool, count)
    self.ChipRow:SetShown(count > 0)
end

-- =============================================================================================
-- FILTERING
-- =============================================================================================

--[[
    Push a search term into the rail, exactly as if it had been typed.

    Writes through the rail's own search box when there is one, so the box shows what is filtering and
    clearing it by hand still works. That is the whole point of routing through one term: the strip and
    the box are two ways to say the same thing, not two filters.

    @param term [string] Term, "^X" for an anchored initial match, or "" to clear
]]
function EntityFilterStripMixin:ApplySearchTerm(term)
    local rail = self:GetRail()
    if not rail then
        return
    end

    if rail.SearchBox and rail.SearchBox.SetText then
        -- SetText fires OnTextChanged, which is the rail's own throttled filter path
        rail.SearchBox:SetText(term)
        return
    end

    rail.currentSearchTerm = term
    if rail.RefreshItemList then
        rail:RefreshItemList()
    end
end

--[[
    Select a letter, or clear it when the selected one is clicked again.

    @param letter [string]
]]
function EntityFilterStripMixin:ToggleLetter(letter)
    local isSame = self.activeLetter == letter

    self.activeLetter = (not isSame) and letter or nil
    self.activeChip = nil

    for _, button in ipairs(self.letterPool) do
        button:SetSelected(button.letter == self.activeLetter)
    end
    for _, chip in ipairs(self.chipPool) do
        chip:SetSelected(false)
    end

    self:ApplySearchTerm(self.activeLetter and ("^" .. self.activeLetter) or "")
end

--[[
    Select a chip, or clear it when the selected one is clicked again.

    @param value [string]
]]
function EntityFilterStripMixin:ToggleChip(value)
    local isSame = self.activeChip == value

    self.activeChip = (not isSame) and value or nil
    self.activeLetter = nil

    for _, chip in ipairs(self.chipPool) do
        chip:SetSelected(chip.value == self.activeChip)
    end
    for _, button in ipairs(self.letterPool) do
        button:SetSelected(false)
    end

    -- A chip filters by a field the rail's own search does not read, so it cannot go through the search
    -- term. It sets the rail's field filter instead, and the rail applies both.
    local rail = self:GetRail()
    if rail then
        rail.currentFieldFilter = self.activeChip
        if rail.SearchBox and rail.SearchBox.SetText then
            rail.SearchBox:SetText("")
        elseif rail.RefreshItemList then
            rail:RefreshItemList()
        end
    end
end
