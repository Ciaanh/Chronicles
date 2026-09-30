local T = _G.T
local H = _G.H
local assert_ = T.assert

-- EventManager builds its schema table from private.constants.events at load, so the events catalog
-- must be present. Load the real Constants.lua rather than mirroring it: a hand-copied catalog
-- drifts silently whenever an event is added, renamed or retired, leaving these tests asserting
-- against a schema table production no longer builds.
local function buildPrivate()
    local private = H.newPrivate()
    H.loadModule("Constants.lua", private)
    -- Constants.lua assigns a fresh private.Core, so restore the skeleton newPrivate() provides.
    private.Core.Utils = private.Core.Utils or {}
    H.loadModule("Core/Infrastructure/EventManager.lua", private)
    return private, private.Core.EventManager.Validator, private.constants.events
end

T.describe("EventManager.Validator required-field enforcement", function()
    T.it("rejects a payload missing a declared required field", function()
        local _, V, events = buildPrivate()
        -- SettingsCollectionChecked requires collectionName + isActive.
        local ok, err = V:validate(events.SettingsCollectionChecked, {isActive = true})
        assert_.isFalse(ok)
        assert_.isNotNil(err)
    end)

    T.it("accepts a payload with all required fields present", function()
        local _, V, events = buildPrivate()
        local ok = V:validate(events.SettingsCollectionChecked, {collectionName = "X", isActive = true})
        assert_.isTrue(ok)
    end)

    T.it("rejects a non-table payload when fields are required", function()
        local _, V, events = buildPrivate()
        local ok = V:validate(events.SettingsCollectionChecked, "not a table")
        assert_.isFalse(ok)
    end)

    T.it("AddonStartup accepts an empty table (no bogus required fields)", function()
        -- Regression: AddonStartup used to declare required version/timestamp
        -- that its real payload ({}) never provides.
        local _, V, events = buildPrivate()
        local ok = V:validate(events.AddonStartup, {})
        assert_.isTrue(ok)
    end)

    T.it("TimelineInit accepts a nil payload", function()
        -- Core/Data.lua triggers TimelineInit with no payload at all, so a nil must validate.
        local _, V, events = buildPrivate()
        local ok = V:validate(events.TimelineInit, nil)
        assert_.isTrue(ok)
    end)

    T.it("passes through validation for an unknown event", function()
        local _, V = buildPrivate()
        local ok = V:validate("Some.Unregistered.Event", {anything = true})
        assert_.isTrue(ok)
    end)

    T.it("resolves dynamic indexed timeline label events to their schema", function()
        local _, V, events = buildPrivate()
        -- DisplayTimelineLabel schema accepts a string or nil.
        local ok = V:validate(events.DisplayTimelineLabel .. "3", "1200")
        assert_.isTrue(ok)
        local bad = V:validate(events.DisplayTimelineLabel .. "3", {})
        assert_.isFalse(bad)
    end)
end)
