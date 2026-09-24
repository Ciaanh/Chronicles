--[[
=================================================================================
Module: Navigation
Purpose: Open a record from anywhere (a link in the book) and walk back and forth
         through what the reader opened
Dependencies: private.Core.StateManager
Author: Chronicles Team
=================================================================================

The selection state stays the single source of truth for which book is open:
Navigation only writes it, the same keys and shapes the rails write
({eventId|characterId|factionId, collectionName}), so every existing consumer
(the books in MainFrameUI, the rail highlights) follows without knowing
Navigation exists.

History is recorded from the selection changes themselves (MainFrameUI calls
Record from its three selection subscriptions), so a rail click, a link and a
timeline jump all land in it the same way. Back and Forward replay an entry
by writing its selection again, under a guard so the replay is not recorded
as a new entry. That guard relies on StateManager notifying subscribers
synchronously inside setState, which it does.

Showing the right tab is the UI's job: MainFrameUI registers a switcher that
takes a kind ("event", "character", "faction").

Usage Example:
    private.Core.Navigation.Open("character", 7, "Greatwars")
    private.Core.Navigation.Back()
=================================================================================
]]
local FOLDER_NAME, private = ...

private.Core.Navigation = {}
local Navigation = private.Core.Navigation

local MAX_HISTORY = 50

-- The selection field each kind writes, matching VerticalListItemMixin:OnClick
local SELECTION_FIELDS = {
    event = "eventId",
    character = "characterId",
    faction = "factionId"
}

local history = {}
local position = 0
local replaying = false
-- Raised while Navigation shows a tab itself: showing the tab records that tab's current selection (see
-- MainFrameUI's tab hook), which is the *old* one when a link is about to select a new one.
local switchingTab = false
local tabSwitcher = nil
local revealer = nil
local listeners = {}

local function notify()
    for _, listener in ipairs(listeners) do
        local ok, err = pcall(listener)
        if not ok and geterrorhandler then
            geterrorhandler()(err)
        end
    end
end

local function sameEntry(a, b)
    return a and b and a.kind == b.kind and a.id == b.id and a.collection == b.collection
end

--[[
    The selection-state value for a record, in the shape the book consumers read

    @param kind [string] "event", "character" or "faction"
    @param id [number] Record id
    @param collection [string] Registered collection name
    @return [table|nil] {<kind>Id = id, collectionName = collection}, nil for an unknown kind
]]
function Navigation.BuildSelection(kind, id, collection)
    local field = SELECTION_FIELDS[kind]
    if not field then
        return nil
    end

    return {[field] = id, collectionName = collection}
end

--[[
    Read a selection-state value back into an entry

    @param kind [string] "event", "character" or "faction"
    @param selection [table|nil] The selection-state value
    @return [table|nil] {kind, id, collection}, nil when the selection names nothing
]]
function Navigation.EntryFromSelection(kind, selection)
    local field = SELECTION_FIELDS[kind]
    if not field or type(selection) ~= "table" then
        return nil
    end

    local id = selection[field]
    if id == nil or not selection.collectionName then
        return nil
    end

    return {kind = kind, id = id, collection = selection.collectionName}
end

function Navigation.SetTabSwitcher(switcher)
    tabSwitcher = switcher
end

--[[
    Register what brings an opened record into view beyond its book: the timeline period of an event,
    the rail row. Called after a link or a Back/Forward opens a record, never for a rail click, since the
    reader is already looking at the row they clicked.

    @param fn [function] fn(entry) with entry = {kind, id, collection}
]]
function Navigation.SetRevealer(fn)
    revealer = fn
end

function Navigation.AddListener(listener)
    if type(listener) == "function" then
        table.insert(listeners, listener)
    end
end

local function showEntry(entry)
    if tabSwitcher then
        switchingTab = true
        local ok, err = pcall(tabSwitcher, entry.kind)
        switchingTab = false
        if not ok then
            error(err, 0)
        end
    end

    local stateManager = private.Core.StateManager
    if not stateManager then
        return
    end

    stateManager.setState(
        stateManager.buildSelectionKey(entry.kind),
        Navigation.BuildSelection(entry.kind, entry.id, entry.collection),
        "Navigation: " .. entry.kind .. " opened"
    )

    if revealer then
        local ok, err = pcall(revealer, entry)
        if not ok and geterrorhandler then
            geterrorhandler()(err)
        end
    end
end

--[[
    Open a record: show its tab and select it

    The selection write is what records it in the history, through MainFrameUI's subscription.

    @param kind [string] "event", "character" or "faction"
    @param id [number] Record id
    @param collection [string] Registered collection name
    @return [boolean] false when the arguments do not name a record
]]
function Navigation.Open(kind, id, collection)
    if not SELECTION_FIELDS[kind] or id == nil or not collection then
        return false
    end

    showEntry({kind = kind, id = id, collection = collection})
    return true
end

--[[
    Record a selection change in the history

    Called for every selection write. Ignored while a Back or Forward is replaying an entry, and when it
    repeats the current entry (a rail row clicked twice, a book re-rendered). A new entry after going
    back drops the forward branch, the way a browser does.

    @param kind [string] "event", "character" or "faction"
    @param selection [table|nil] The new selection-state value
]]
function Navigation.Record(kind, selection)
    if replaying or switchingTab then
        return
    end

    local entry = Navigation.EntryFromSelection(kind, selection)
    if not entry or sameEntry(history[position], entry) then
        return
    end

    for index = #history, position + 1, -1 do
        history[index] = nil
    end

    table.insert(history, entry)
    if #history > MAX_HISTORY then
        table.remove(history, 1)
    end
    position = #history

    notify()
end

local function moveTo(newPosition)
    if newPosition < 1 or newPosition > #history then
        return false
    end

    position = newPosition
    replaying = true
    local ok, err = pcall(showEntry, history[position])
    replaying = false

    notify()

    if not ok then
        error(err, 0)
    end
    return true
end

function Navigation.CanGoBack()
    return position > 1
end

function Navigation.CanGoForward()
    return position < #history
end

function Navigation.Back()
    return moveTo(position - 1)
end

function Navigation.Forward()
    return moveTo(position + 1)
end

--[[
    The entries up to the current one, most recent last

    @param count [number] How many to return at most
    @return [table] Sequential array of {kind, id, collection}
]]
function Navigation.GetTrail(count)
    local trail = {}
    local first = math.max(1, position - (count or position) + 1)
    for index = first, position do
        table.insert(trail, history[index])
    end
    return trail
end

-- For specs: forget the history and the registered UI hooks
function Navigation.Reset()
    history = {}
    position = 0
    replaying = false
    switchingTab = false
    tabSwitcher = nil
    revealer = nil
    listeners = {}
end

return Navigation
