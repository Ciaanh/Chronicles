--[[
    Specs for Core/Domain/Navigation.lua: opening a record and the back/forward history.

    The StateManager double notifies synchronously inside setState, like the real one, and forwards each
    selection change to Navigation.Record the way MainFrameUI's subscriptions do. That loop is the part
    that breaks quietly: a replayed entry recorded again would make Back bounce between two books.
]]

local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Domain/Navigation.lua", private)
local Navigation = private.Core.Navigation

local function install()
    Navigation.Reset()

    local store = {}
    local tabs = {}
    private.Core.StateManager = {
        buildSelectionKey = function(kind)
            return "ui.selection." .. kind
        end,
        getState = function(key)
            return store[key]
        end,
        setState = function(key, value)
            store[key] = value
            -- MainFrameUI's subscription, synchronous like StateManager.notifySubscribers
            Navigation.Record(key:match("ui%.selection%.(.+)$"), value)
        end
    }
    Navigation.SetTabSwitcher(function(kind)
        table.insert(tabs, kind)
    end)

    return store, tabs
end

T.describe("Navigation.Open", function()
    T.it("switches to the record's tab and writes the selection the books read", function()
        local store, tabs = install()

        assert_.isTrue(Navigation.Open("character", 7, "Greatwars"))

        assert_.equals(tabs[1], "character")
        assert_.deepEquals(store["ui.selection.character"], {characterId = 7, collectionName = "Greatwars"})
    end)

    T.it("refuses what does not name a record", function()
        install()

        assert_.isFalse(Navigation.Open("chapter", 1, "Greatwars"))
        assert_.isFalse(Navigation.Open("event", nil, "Greatwars"))
        assert_.isFalse(Navigation.Open("event", 1, nil))
    end)
end)

T.describe("Navigation history", function()
    T.it("goes back to the event after following a link, and forward again", function()
        local store, tabs = install()

        private.Core.StateManager.setState("ui.selection.event", {eventId = 105, collectionName = "Greatwars"})
        Navigation.Open("character", 7, "Greatwars")

        assert_.isTrue(Navigation.CanGoBack())
        assert_.isTrue(Navigation.Back())
        assert_.equals(tabs[#tabs], "event", "back shows the event's tab")
        assert_.deepEquals(store["ui.selection.event"], {eventId = 105, collectionName = "Greatwars"})
        assert_.isTrue(Navigation.CanGoForward())

        assert_.isTrue(Navigation.Forward())
        assert_.equals(tabs[#tabs], "character")
        assert_.isFalse(Navigation.CanGoForward())
    end)

    T.it("does not record the replay of an entry", function()
        install()

        Navigation.Open("event", 1, "Greatwars")
        Navigation.Open("event", 2, "Greatwars")
        Navigation.Back()
        Navigation.Back()

        assert_.isFalse(Navigation.CanGoBack(), "two entries, now at the first")
        assert_.equals(#Navigation.GetTrail(10), 1)
    end)

    T.it("ignores a repeat of the current entry", function()
        install()

        Navigation.Open("event", 1, "Greatwars")
        Navigation.Open("event", 1, "Greatwars")

        assert_.isFalse(Navigation.CanGoBack())
    end)

    T.it("drops the forward branch when a new record is opened after going back", function()
        install()

        Navigation.Open("event", 1, "Greatwars")
        Navigation.Open("event", 2, "Greatwars")
        Navigation.Back()
        Navigation.Open("faction", 3, "Greatwars")

        assert_.isFalse(Navigation.CanGoForward())
        local trail = Navigation.GetTrail(10)
        assert_.equals(#trail, 2)
        assert_.equals(trail[2].kind, "faction")
    end)

    T.it("returns the most recent entries for the breadcrumb", function()
        install()

        for id = 1, 5 do
            Navigation.Open("event", id, "Greatwars")
        end

        local trail = Navigation.GetTrail(3)
        assert_.equals(#trail, 3)
        assert_.equals(trail[1].id, 3)
        assert_.equals(trail[3].id, 5)
    end)

    T.it("tells its listeners about every change", function()
        install()
        local calls = 0
        Navigation.AddListener(function()
            calls = calls + 1
        end)

        Navigation.Open("event", 1, "Greatwars")
        Navigation.Open("event", 2, "Greatwars")
        Navigation.Back()

        assert_.equals(calls, 3)
    end)
end)

T.describe("Navigation and tab switches", function()
    T.it("does not record the target tab's old selection while opening a link", function()
        local store = install()
        store["ui.selection.character"] = {characterId = 2, collectionName = "Greatwars"}

        -- The real switcher shows the tab, and showing a tab records that tab's current selection
        Navigation.SetTabSwitcher(function(kind)
            Navigation.Record(kind, store["ui.selection." .. kind])
        end)

        private.Core.StateManager.setState("ui.selection.event", {eventId = 105, collectionName = "Greatwars"})
        Navigation.Open("character", 7, "Greatwars")

        local trail = Navigation.GetTrail(10)
        assert_.equals(#trail, 2, "event, then the linked character, and not character 2 in between")
        assert_.equals(trail[2].id, 7)
    end)
end)

T.describe("Navigation reveal hook", function()
    T.it("reveals what a link or a Back opens, and not a rail click", function()
        install()
        local revealed = {}
        Navigation.SetRevealer(function(entry)
            table.insert(revealed, entry.kind .. ":" .. entry.id)
        end)

        -- A rail click: the selection is written directly, Navigation only records it
        private.Core.StateManager.setState("ui.selection.event", {eventId = 105, collectionName = "Greatwars"})
        Navigation.Open("character", 7, "Greatwars")
        Navigation.Back()

        assert_.deepEquals(revealed, {"character:7", "event:105"})
    end)
end)
