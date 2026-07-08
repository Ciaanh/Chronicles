local T = _G.T
local H = _G.H
local assert_ = T.assert

-- Build a `private` with a fake AceDB-backed Chronicles so StateManager.init()
-- can hydrate its in-memory store from "SavedVariables", and rehydrate() has
-- real restored values to re-emit.
local function buildPrivate(globalDb)
    local private = H.newPrivate()
    local chronicles = {db = {global = globalDb or {}}}
    private.Core.Utils.HelperUtils = {
        getChronicles = function()
            return chronicles
        end
    }
    H.loadModule("Core/Infrastructure/StateManager.lua", private)
    return private, private.Core.StateManager, chronicles
end

T.describe("StateManager.rehydrate", function()
    T.it("re-emits a restored value to subscribers as newValue == oldValue", function()
        local _, SM = buildPrivate({uiState = {activeTab = "events"}})
        SM.init()

        local key = SM.buildUIStateKey("activeTab")
        local seen = {}
        SM.subscribe(key, function(newValue, oldValue)
            seen.new = newValue
            seen.old = oldValue
        end, "test")

        local notified = SM.rehydrate(key)
        assert_.isTrue(notified)
        assert_.equals(seen.new, "events")
        assert_.equals(seen.old, "events", "restored state should present as unchanged")
    end)

    T.it("returns false and does not notify for a key with no stored value", function()
        local _, SM = buildPrivate({})
        SM.init()

        local key = SM.buildUIStateKey("activeTab")
        local called = false
        SM.subscribe(key, function()
            called = true
        end, "test")

        assert_.isFalse(SM.rehydrate(key))
        assert_.isFalse(called)
    end)

    T.it("returns false for an invalid key without raising", function()
        local _, SM = buildPrivate({})
        SM.init()
        assert_.isFalse(SM.rehydrate(nil))
        assert_.isFalse(SM.rehydrate(""))
    end)

    T.it("does not re-persist: the stored value is unchanged after rehydrate", function()
        local _, SM, chronicles = buildPrivate({timelineState = {currentStep = 500}})
        SM.init()

        local key = SM.buildTimelineKey("currentStep")
        -- Corrupt the persisted copy to prove rehydrate does not write back.
        chronicles.db.global.timelineState.currentStep = "SENTINEL"

        SM.rehydrate(key)

        assert_.equals(SM.getState(key), 500, "in-memory value is re-emitted, not mutated")
        assert_.equals(
            chronicles.db.global.timelineState.currentStep,
            "SENTINEL",
            "rehydrate must not persist to AceDB"
        )
    end)
end)
