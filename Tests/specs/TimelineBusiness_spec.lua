local T = _G.T
local H = _G.H
local assert_ = T.assert

-- The real config constants (mirrors Constants.lua) so boundary-year tests
-- exercise the same numbers the addon uses in production.
local function realConfig()
    return {
        currentYear = 42,
        historyStartYear = -150000,
        mythos = -999999,
        futur = 999999,
        timeline = {
            pageSize = 8,
            densityTiers = {
                {below = 10, texture = "low-events"},
                {below = 25, texture = "medium-events"}
            },
            denseTexture = "high-events",
            noEventsTexture = "no-events"
        },
        stepValues = {1000, 500, 100, 10}
    }
end

-- Build a `private` table wired with the dependencies TimelineBusiness pulls
-- at runtime. `chroniclesData` controls what getChronicles().Data resolves to
-- (pass nil to simulate "data not ready").
local function buildPrivate(chroniclesData)
    local private = H.newPrivate()
    private.constants.config = realConfig()

    private.Core.Utils.HelperUtils = {
        getChronicles = function()
            if chroniclesData == nil then
                return nil
            end
            return {Data = chroniclesData}
        end
    }

    -- In-memory state store so setState/getState behave like the real thing
    -- for the pagination paths that read back what they wrote.
    local store = {}
    private.Core.StateManager = {
        buildTimelineKey = function(key)
            return "timeline." .. key
        end,
        getState = function(key)
            return store[key]
        end,
        setState = function(key, value)
            store[key] = value
        end
    }

    private.Core.Cache = {
        getPeriodsFillingBySteps = function()
            return {}
        end,
        getSearchEvents = function()
            return {}
        end
    }

    H.loadModule("Core/Data/TimelineBusiness.lua", private)
    return private, private.Core.Data.TimelineBusiness, store
end

T.describe("TimelineBusiness.calculateTimelineConfig", function()
    T.it("returns a zeroed config when Chronicles data is unavailable", function()
        local _, TB = buildPrivate(nil)
        local cfg = TB.calculateTimelineConfig(-1000, 1000, 1000)
        assert_.equals(cfg.numberOfTimelineBlock, 0)
        assert_.isFalse(cfg.isOverlapping)
    end)

    T.it("handles an overlapping BC->AD range within bounds (step 1000)", function()
        local _, TB = buildPrivate({})
        local cfg = TB.calculateTimelineConfig(-150000, 42, 1000)
        assert_.isTrue(cfg.isOverlapping)
        assert_.isFalse(cfg.pastEvents, "min year equals historyStartYear, not before it")
        assert_.isFalse(cfg.futurEvents, "max year equals currentYear, not after it")
        assert_.equals(cfg.before, 150) -- ceil(150000 / 1000)
        assert_.equals(cfg.after, 1) -- ceil(42 / 1000)
        assert_.equals(cfg.numberOfTimelineBlock, 151)
    end)

    T.it("clamps and flags past+future for the extreme mythos/futur range", function()
        local _, TB = buildPrivate({})
        local cfg = TB.calculateTimelineConfig(-999999, 999999, 1000)
        assert_.isTrue(cfg.pastEvents)
        assert_.isTrue(cfg.futurEvents)
        assert_.isTrue(cfg.isOverlapping)
        assert_.equals(cfg.minYear, -150000, "min clamped to historyStartYear")
        assert_.equals(cfg.maxYear, 42, "max clamped to currentYear")
        -- base 151 (before 150 + after 1) + 1 past + 1 future = 153
        assert_.equals(cfg.numberOfTimelineBlock, 153)
        assert_.equals(cfg.before, 151)
        assert_.equals(cfg.after, 2)
    end)

    T.it("computes a non-overlapping all-BC range by length", function()
        local _, TB = buildPrivate({})
        local cfg = TB.calculateTimelineConfig(-5000, -1000, 1000)
        assert_.isFalse(cfg.isOverlapping)
        assert_.equals(cfg.before, 5) -- ceil(5000 / 1000)
        assert_.equals(cfg.after, 0)
        assert_.equals(cfg.numberOfTimelineBlock, 4) -- ceil(|−5000 − (−1000)| / 1000)
    end)
end)

T.describe("TimelineBusiness.getStepValueIndex", function()
    T.it("maps each configured step to its 1-based index", function()
        local _, TB = buildPrivate({})
        assert_.equals(TB.getStepValueIndex(1000), 1)
        assert_.equals(TB.getStepValueIndex(500), 2)
        assert_.equals(TB.getStepValueIndex(100), 3)
        assert_.equals(TB.getStepValueIndex(10), 4)
    end)

    T.it("returns nil for a step that is not configured", function()
        local _, TB = buildPrivate({})
        assert_.isNil(TB.getStepValueIndex(250))
    end)
end)

T.describe("TimelineBusiness.consolidateTimelinePeriods", function()
    T.it("merges a run of empty periods into the following populated one", function()
        local _, TB = buildPrivate({})
        local blocks = {
            {lower = 1, upper = 10, hasEvents = true, nbEvents = 2},
            {lower = 11, upper = 20, hasEvents = false, nbEvents = 0},
            {lower = 21, upper = 30, hasEvents = false, nbEvents = 0},
            {lower = 31, upper = 40, hasEvents = true, nbEvents = 5}
        }
        local result = TB.consolidateTimelinePeriods(blocks)
        assert_.equals(#result, 3)
        assert_.equals(result[1].lower, 1)
        assert_.equals(result[1].upper, 10)
        -- the two empty blocks collapse into one spanning 11..30
        assert_.equals(result[2].lower, 11)
        assert_.equals(result[2].upper, 30)
        assert_.isFalse(result[2].hasEvents)
        assert_.equals(result[3].lower, 31)
    end)

    T.it("collapses trailing empty periods and always keeps the last block", function()
        local _, TB = buildPrivate({})
        local blocks = {
            {lower = 1, upper = 10, hasEvents = false, nbEvents = 0},
            {lower = 11, upper = 20, hasEvents = false, nbEvents = 0}
        }
        local result = TB.consolidateTimelinePeriods(blocks)
        assert_.equals(#result, 1)
        assert_.equals(result[1].lower, 1)
        assert_.equals(result[1].upper, 20)
    end)
end)

T.describe("TimelineBusiness.calculateTimelinePagination", function()
    T.it("returns page-1 defaults when periods is nil", function()
        local _, TB = buildPrivate({})
        local p = TB.calculateTimelinePagination(nil, 1)
        assert_.equals(p.currentPage, 1)
        assert_.equals(p.maxPage, 1)
        assert_.equals(p.pageSize, 8)
        assert_.equals(p.totalPeriods, 0)
        assert_.isFalse(p.showPrevious)
        assert_.isFalse(p.showNext)
    end)

    T.it("computes bounds and nav flags on the first page", function()
        local _, TB = buildPrivate({})
        local periods = {}
        for i = 1, 20 do
            periods[i] = {lower = i, upper = i}
        end
        local p = TB.calculateTimelinePagination(periods, 1)
        assert_.equals(p.maxPage, 3) -- ceil(20 / 8)
        assert_.equals(p.firstIndex, 1)
        assert_.isFalse(p.showPrevious)
        assert_.isTrue(p.showNext)
    end)

    T.it("clamps the last page's first index to fit the page window", function()
        local _, TB = buildPrivate({})
        local periods = {}
        for i = 1, 20 do
            periods[i] = {lower = i, upper = i}
        end
        local p = TB.calculateTimelinePagination(periods, 3)
        assert_.equals(p.currentPage, 3)
        assert_.equals(p.firstIndex, 13) -- 20 - (8 - 1)
        assert_.isTrue(p.showPrevious)
        assert_.isFalse(p.showNext)
    end)

    T.it("defaults a nil currentPage to the last page", function()
        local _, TB = buildPrivate({})
        local periods = {}
        for i = 1, 20 do
            periods[i] = {lower = i, upper = i}
        end
        local p = TB.calculateTimelinePagination(periods, nil)
        assert_.equals(p.currentPage, 3)
    end)
end)

T.describe("TimelineBusiness.getEventDensityTexture", function()
    -- The ladder is a constant with two consumers in the addon (the crystal a period paints and the
    -- legend that explains the colours) and a third in the Chronicles-tauri companion's period band.
    -- These cases are the contract all three share; the companion mirrors them in Vitest.
    T.it("classifies each boundary the same way on both sides of it", function()
        local _, TB = buildPrivate({})

        assert_.equals(TB.getEventDensityTexture(0), "low-events")
        assert_.equals(TB.getEventDensityTexture(9), "low-events")
        assert_.equals(TB.getEventDensityTexture(10), "medium-events", "10 is the low tier's ceiling, not in it")
        assert_.equals(TB.getEventDensityTexture(24), "medium-events")
        assert_.equals(TB.getEventDensityTexture(25), "high-events", "25 is the medium tier's ceiling")
        assert_.equals(TB.getEventDensityTexture(99), "high-events")
    end)

    T.it("returns the winning tier's ceiling, and nothing for the dense case", function()
        -- The legend labels are built from this second return value rather than from literals
        local _, TB = buildPrivate({})

        local _, lowCeiling = TB.getEventDensityTexture(3)
        local _, mediumCeiling = TB.getEventDensityTexture(15)
        local _, denseCeiling = TB.getEventDensityTexture(500)

        assert_.equals(lowCeiling, 10)
        assert_.equals(mediumCeiling, 25)
        assert_.isNil(denseCeiling, "nothing bounds the dense tier from above")
    end)

    T.it("treats a nil count as zero rather than raising", function()
        local _, TB = buildPrivate({})

        assert_.equals(TB.getEventDensityTexture(nil), "low-events")
    end)
end)

T.describe("TimelineBusiness.buildEraEntries", function()
    T.it("keeps era events only, sorted by year then order", function()
        local _, TB = buildPrivate({})
        local entries = TB.buildEraEntries({
            {eventType = 2, yearStart = 26, order = 1, label = "Reopening of the Dark Portal", source = "burningcrusade"},
            {eventType = 1, yearStart = 1, order = 15, label = "Birth of Thrall", source = "greatwars"},
            {eventType = 2, yearStart = 0, order = 3, label = "The Great Wars", source = "expansions"},
            {eventType = 2, yearStart = 26, order = 0, label = "The Burning Crusade", source = "expansions"}
        })

        assert_.equals(#entries, 3)
        assert_.equals(entries[1].label, "The Great Wars")
        assert_.equals(entries[2].label, "The Burning Crusade", "same year: lower order first")
        assert_.equals(entries[3].label, "Reopening of the Dark Portal")
        assert_.equals(entries[3].year, 26)
    end)

    T.it("skips the Mythos and Futur sentinels and unlabelled records", function()
        local _, TB = buildPrivate({})
        local entries = TB.buildEraEntries({
            {eventType = 2, yearStart = -999999, label = "Before time"},
            {eventType = 2, yearStart = 999999, label = "After time"},
            {eventType = 2, yearStart = 12}
        })

        assert_.equals(#entries, 0)
    end)

    T.it("returns an empty list for nil input", function()
        local _, TB = buildPrivate({})
        assert_.equals(#TB.buildEraEntries(nil), 0)
    end)
end)

T.describe("TimelineBusiness.buildYearBuckets", function()
    -- Year 0 to 9 of the shipped data: 17, 1, 0, 2, 1, 4, 4, 2, 0, 0
    T.it("counts events per year in a 10-year period", function()
        local _, TB = buildPrivate({})
        local events = {}
        local perYear = {17, 1, 0, 2, 1, 4, 4, 2, 0, 0}
        for year = 0, 9 do
            for _ = 1, perYear[year + 1] do
                table.insert(events, {yearStart = year})
            end
        end

        local buckets = TB.buildYearBuckets(events, 0, 9, 10)

        assert_.equals(#buckets, 10)
        for year = 0, 9 do
            assert_.equals(buckets[year + 1].lower, year)
            assert_.equals(buckets[year + 1].upper, year)
            assert_.equals(buckets[year + 1].count, perYear[year + 1])
        end
    end)

    T.it("groups years into equal buckets for wider periods", function()
        local _, TB = buildPrivate({})
        local buckets = TB.buildYearBuckets({{yearStart = -1000}, {yearStart = -901}, {yearStart = -900}, {yearStart = -1}}, -1000, -1, 10)

        assert_.equals(#buckets, 10)
        assert_.equals(buckets[1].lower, -1000)
        assert_.equals(buckets[1].upper, -901)
        assert_.equals(buckets[1].count, 2)
        assert_.equals(buckets[2].count, 1)
        assert_.equals(buckets[10].upper, -1)
        assert_.equals(buckets[10].count, 1)
    end)

    T.it("clamps the bucket count to the number of years", function()
        local _, TB = buildPrivate({})
        local buckets = TB.buildYearBuckets({{yearStart = 5}}, 5, 5, 10)

        assert_.equals(#buckets, 1)
        assert_.equals(buckets[1].count, 1)
    end)

    T.it("returns nothing for the unbounded Mythos and Futur periods", function()
        local _, TB = buildPrivate({})

        assert_.equals(#TB.buildYearBuckets({}, -999999, -150001, 10), 0)
        assert_.equals(#TB.buildYearBuckets({}, 43, 999999, 10), 0)
    end)
end)

T.describe("TimelineBusiness.countEventsByType", function()
    T.it("counts per type and returns the total", function()
        local _, TB = buildPrivate({})
        local counts, total = TB.countEventsByType({{eventType = 1}, {eventType = 1}, {eventType = 4}, {}})

        assert_.equals(counts[1], 2)
        assert_.equals(counts[4], 1)
        assert_.equals(counts[0], 1, "a record with no type counts as undefined")
        assert_.equals(total, 4)
    end)
end)

T.describe("TimelineBusiness bucket clamping", function()
    -- A period lists every event overlapping it, so one that began before the period must still land
    -- in a bar, or the bars would not add up to the rail's count.
    T.it("counts an event that began before the period in the first bucket", function()
        local _, TB = buildPrivate({})
        local buckets = TB.buildYearBuckets({{yearStart = -3, yearEnd = 4}, {yearStart = 9}}, 0, 9, 10)

        assert_.equals(buckets[1].count, 1)
        assert_.equals(buckets[10].count, 1)
    end)

    T.it("matches events to buckets with the same rule", function()
        local _, TB = buildPrivate({})
        local buckets = TB.buildYearBuckets({}, 0, 9, 10)

        assert_.isTrue(TB.isEventInBucket({yearStart = -3}, buckets[1], 0, 9))
        assert_.isTrue(TB.isEventInBucket({yearStart = 5}, buckets[6], 0, 9))
        assert_.isFalse(TB.isEventInBucket({yearStart = 5}, buckets[5], 0, 9))
        assert_.isFalse(TB.isEventInBucket({}, buckets[1], 0, 9))
    end)
end)
