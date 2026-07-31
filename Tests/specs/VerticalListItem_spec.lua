--[[
    Specs for the one shared rail row, VerticalListItemMixin.

    Both rails render this row since the Events tab's own template was merged into it, and the two
    shapes it depends on both fail *silently* when they drift:

      * Init returns early on a nil item.name, so a producer that forgets to supply a name renders
        rows that exist, respond to clicks, and show no text.
      * OnClick writes the selection state, and each book consumer in MainFrameUI reads exactly one
        of eventId / characterId / factionId. A row whose type has no branch writes {itemId}, which
        every consumer ignores, so clicking it does nothing at all and nothing errors.

    CreateScrollBoxListLinearView is not stubbed, so the list mixin's view wiring is out of reach —
    but Init, OnClick and SetSelected are pure table manipulation and are the risky part.
]]

local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
private.Core.Utils.Spacing = {xs = 4, sm = 8, md = 12}
H.loadModule("UI/VerticalListTemplate.lua", private)

local VerticalListItemMixin = _G.VerticalListItemMixin

-- -------------------------
-- Test doubles
-- -------------------------

local function makeTextElement()
    local element = {}
    function element:SetText(text)
        self.text = text
    end
    function element:SetWordWrap() end
    function element:SetMaxLines() end
    function element:SetJustifyV() end
    return element
end

-- A row frame as the XML template builds it: the mixin's methods copied onto a table carrying the
-- template's parentKey children. This is what WoW's mixin= attribute does.
local function makeRow()
    local row = {
        ItemName = makeTextElement(),
        SelectedGlow = {
            shown = false,
            SetShown = function(self, shown)
                self.shown = shown
            end
        }
    }

    for key, value in pairs(VerticalListItemMixin) do
        row[key] = value
    end

    return row
end

--[[
    Install a recording StateManager double.
    @param stored [table|nil] the value getState should return for any key
    @return [table] {writes = {{key, value, description}, ...}}
]]
local function installStateManager(stored)
    local recorder = {writes = {}}

    private.Core.StateManager = {
        buildSelectionKey = function(entityType)
            return "selection." .. entityType .. ".selected"
        end,
        getState = function()
            return stored
        end,
        setState = function(key, value, description)
            table.insert(recorder.writes, {key = key, value = value, description = description})
        end
    }

    return recorder
end

-- -------------------------
-- Init
-- -------------------------

T.describe("VerticalListItemMixin:Init", function()
    T.it("renders an event row from the producer's item.name", function()
        local row = makeRow()

        -- The shape EventListMixin:UpdateFromSelectedPeriod emits: the event record itself, with the
        -- label copied to name because the row reads name at three sites and events carry label.
        row:Init(
            {
                item = {id = 7, name = "The Sundering", label = "The Sundering", source = "Origins"},
                itemType = "event",
                stateManagerKey = "event"
            }
        )

        assert_.equals(row.ItemName.text, "The Sundering", "row label")
        assert_.equals(row.Item.id, 7, "row keeps the item for OnClick and the tooltip")
        assert_.equals(row.ItemType, "event")
        assert_.equals(row.stateManagerKey, "event")
    end)

    T.it("renders nothing at all when the item has no name", function()
        -- This is the silent failure the producer's `name = event.label` exists to prevent: an event
        -- carrying only `label` passes through Init untouched rather than raising.
        local row = makeRow()

        row:Init({item = {id = 7, label = "The Sundering", source = "Origins"}, stateManagerKey = "event"})

        assert_.isNil(row.ItemName.text, "no text was set")
        assert_.isNil(row.Item, "no item was stored")
    end)

    T.it("accepts the character and faction wrapper keys as well as item", function()
        local characterRow = makeRow()
        characterRow:Init({character = {id = 1, name = "Tyrande", source = "Classic"}, itemType = "character"})
        assert_.equals(characterRow.ItemName.text, "Tyrande")

        local factionRow = makeRow()
        factionRow:Init({faction = {id = 2, name = "Kirin Tor", source = "Classic"}, itemType = "faction"})
        assert_.equals(factionRow.ItemName.text, "Kirin Tor")
    end)

    T.it("clears the selected state so a pooled row does not arrive lit", function()
        local row = makeRow()
        row.SelectedGlow.shown = true

        row:Init({item = {id = 7, name = "The Sundering", source = "Origins"}, stateManagerKey = "event"})

        assert_.isFalse(row.SelectedGlow.shown)
        assert_.isFalse(row.isSelected)
    end)
end)

-- -------------------------
-- OnClick
-- -------------------------

T.describe("VerticalListItemMixin:OnClick", function()
    T.it("writes {eventId, collectionName} for an event row", function()
        -- MainFrameUIMixin:UpdateEventBookContent reads eventId and collectionName; {itemId} would
        -- leave the book empty with no error anywhere.
        local recorder = installStateManager(nil)
        local row = makeRow()
        row:Init(
            {
                item = {id = 7, name = "The Sundering", source = "Origins"},
                itemType = "event",
                stateManagerKey = "event"
            }
        )

        row:OnClick()

        assert_.equals(#recorder.writes, 1, "one state write")
        assert_.equals(recorder.writes[1].key, "selection.event.selected")
        assert_.deepEquals(recorder.writes[1].value, {eventId = 7, collectionName = "Origins"})
        assert_.isTrue(row.isSelected)
    end)

    T.it("does not re-write the state when the clicked event is already the selection", function()
        local recorder = installStateManager({eventId = 7, collectionName = "Origins"})
        local row = makeRow()
        row:Init(
            {
                item = {id = 7, name = "The Sundering", source = "Origins"},
                itemType = "event",
                stateManagerKey = "event"
            }
        )

        row:OnClick()

        assert_.equals(#recorder.writes, 0, "the dedup suppressed the write")
        assert_.isTrue(row.isSelected, "the row is still shown as the selection")
    end)

    T.it("still writes when the same id belongs to a different collection", function()
        local recorder = installStateManager({eventId = 7, collectionName = "Dragonflight"})
        local row = makeRow()
        row:Init(
            {
                item = {id = 7, name = "The Sundering", source = "Origins"},
                itemType = "event",
                stateManagerKey = "event"
            }
        )

        row:OnClick()

        assert_.equals(#recorder.writes, 1, "collection is part of the identity")
    end)

    T.it("writes {characterId} and {factionId} for the rails that already worked", function()
        local recorder = installStateManager(nil)

        local characterRow = makeRow()
        characterRow:Init({item = {id = 1, name = "Tyrande", source = "Classic"}, stateManagerKey = "character"})
        characterRow:OnClick()

        local factionRow = makeRow()
        factionRow:Init({item = {id = 2, name = "Kirin Tor", source = "Classic"}, stateManagerKey = "faction"})
        factionRow:OnClick()

        assert_.deepEquals(recorder.writes[1].value, {characterId = 1, collectionName = "Classic"})
        assert_.deepEquals(recorder.writes[2].value, {factionId = 2, collectionName = "Classic"})
    end)

    T.it("writes nothing for an unconfigured row", function()
        -- stateManagerKey stays "generic" until a rail configures itself; a click then has no state
        -- key to write to and must no-op rather than inventing one.
        local recorder = installStateManager(nil)
        local row = makeRow()
        row:Init({item = {id = 7, name = "The Sundering", source = "Origins"}})

        row:OnClick()

        assert_.equals(#recorder.writes, 0)
    end)
end)

-- -------------------------
-- SetSelected
-- -------------------------

T.describe("VerticalListItemMixin:SetSelected", function()
    T.it("shows and hides the bookmark glow", function()
        local row = makeRow()

        row:SetSelected(true)
        assert_.isTrue(row.SelectedGlow.shown)
        assert_.isTrue(row.isSelected)

        row:SetSelected(false)
        assert_.isFalse(row.SelectedGlow.shown)
        assert_.isFalse(row.isSelected)
    end)

    T.it("does not raise on a row template with no glow texture", function()
        local row = makeRow()
        row.SelectedGlow = nil

        row:SetSelected(true)

        assert_.isTrue(row.isSelected)
    end)
end)

-- -------------------------
-- Rail filtering
-- -------------------------

T.describe("VerticalListMixin filtering", function()
    local VerticalListMixin = _G.VerticalListMixin

    local items = {
        {id = 1, name = "Alexstrasza", race = "Dragon"},
        {id = 2, name = "Anduin Wrynn", race = "Human"},
        {id = 3, name = "Sylvanas Windrunner", race = "Undead"},
        {id = 4, name = "The Sundering", race = "Human"}
    }

    T.it("matches a typed term anywhere in the name", function()
        local result = VerticalListMixin.FilterItemsByName(nil, items, "sun")

        assert_.equals(#result, 1)
        assert_.equals(result[1].name, "The Sundering")
    end)

    T.it("anchors a caret term to the first character", function()
        -- What the filter strip's A to Z row writes. "^S" must mean names starting with S, so
        -- "The Sundering" is excluded even though it contains one.
        local result = VerticalListMixin.FilterItemsByName(nil, items, "^S")

        assert_.equals(#result, 1)
        assert_.equals(result[1].name, "Sylvanas Windrunner")
    end)

    T.it("is case insensitive in both modes", function()
        assert_.equals(#VerticalListMixin.FilterItemsByName(nil, items, "^a"), 2)
        assert_.equals(#VerticalListMixin.FilterItemsByName(nil, items, "ALEX"), 1)
    end)

    T.it("returns everything for an empty term or a bare caret", function()
        assert_.equals(#VerticalListMixin.FilterItemsByName(nil, items, ""), 4)
        assert_.equals(#VerticalListMixin.FilterItemsByName(nil, items, nil), 4)
        assert_.equals(#VerticalListMixin.FilterItemsByName(nil, items, "^"), 4)
    end)

    T.it("filters by an exact field value for the strip's chips", function()
        local result = VerticalListMixin.FilterItemsByField(nil, items, "Human")

        assert_.equals(#result, 2)
    end)

    T.it("passes everything through when no chip is selected", function()
        assert_.equals(#VerticalListMixin.FilterItemsByField(nil, items, nil), 4)
        assert_.equals(#VerticalListMixin.FilterItemsByField(nil, items, ""), 4)
    end)
end)
