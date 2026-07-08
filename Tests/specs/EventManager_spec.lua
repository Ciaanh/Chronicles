local T = _G.T
local H = _G.H
local assert_ = T.assert

-- EventManager builds its schema table from private.constants.events at load,
-- so the events catalog must be present. Mirror Constants.lua.
local function buildPrivate()
    local private = H.newPrivate()
    private.constants.events = {
        AddonStartup = "Addon.STARTUP",
        AddonShutdown = "Addon.SHUTDOWN",
        TimelineInit = "Timeline.INIT",
        UIRefresh = "Timeline.CLEAN",
        TimelinePreviousButtonVisible = "Timeline.PREVIOUS_VISIBLE",
        TimelineNextButtonVisible = "Timeline.NEXT_VISIBLE",
        DisplayTimelineLabel = "Timeline.DisplayLabel",
        DisplayTimelinePeriod = "Timeline.DisplayPeriod",
        DisplayEventsForYear = "Timeline.DisplayEventsForYear",
        TabUITabSet = "TabUI.TabSet",
        SettingsEventTypeChecked = "Settings.EVENT_TYPE_CHECKED",
        SettingsCollectionChecked = "Settings.COLLECTION_CHECKED"
    }
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
        local ok = V:validate(events.TabUITabSet, "not a table")
        assert_.isFalse(ok)
    end)

    T.it("AddonStartup accepts an empty table (no bogus required fields)", function()
        -- Regression: AddonStartup used to declare required version/timestamp
        -- that its real payload ({}) never provides.
        local _, V, events = buildPrivate()
        local ok = V:validate(events.AddonStartup, {})
        assert_.isTrue(ok)
    end)

    T.it("AddonShutdown accepts a nil payload", function()
        local _, V, events = buildPrivate()
        local ok = V:validate(events.AddonShutdown, nil)
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
