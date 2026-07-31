--[[
    Specs for FrontMatter.ResolveNames — the front matter's id-to-name resolver.

    Records store relationships as ids in two different shapes and the collection keys they name are
    lowercase while collections register capitalised. Both facts are load-bearing: get either wrong and
    the front matter renders nothing at all for the ~40% of events that carry references, silently,
    because an unresolvable id is skipped by design.
]]

local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/HelperUtils.lua", private)
H.loadModule("UI/Book/FrontMatter.lua", private)

local FrontMatter = private.Core.Utils.FrontMatter

-- -------------------------
-- Test doubles
-- -------------------------

--[[
    Install a Data facade over fixed records.

    Collections are keyed by their *registered* (capitalised) name and the finders are strict about
    case, exactly as the real ones are: Data.Characters[collectionName] is a plain table index and
    GetCollectionStatus builds a state key from the name verbatim.

    @param characters [table] {[RegisteredName] = {[id] = name}}
    @param factions [table] same shape
    @return [table] {lookups = <count of finder calls>}
]]
local function installData(characters, factions)
    local recorder = {lookups = 0}

    local function finder(store)
        return function(_, id, collectionName)
            recorder.lookups = recorder.lookups + 1
            local collection = store[collectionName]
            local name = collection and collection[id]
            if not name then
                return nil
            end
            return {id = id, name = name, source = collectionName}
        end
    end

    local registeredNames = {}
    local seen = {}
    for _, store in ipairs({characters, factions}) do
        for collectionName in pairs(store) do
            if not seen[collectionName] then
                seen[collectionName] = true
                table.insert(registeredNames, {name = collectionName, isActive = true})
            end
        end
    end
    table.sort(
        registeredNames,
        function(left, right)
            return left.name < right.name
        end
    )

    private.Chronicles = {
        Data = {
            FindCharacterByIdAndCollection = finder(characters),
            FindFactionByIdAndCollection = finder(factions),
            GetCollectionsNames = function()
                return registeredNames
            end
        }
    }

    return recorder
end

-- -------------------------
-- The two reference shapes
-- -------------------------

T.describe("FrontMatter.ResolveNames shapes", function()
    T.it("resolves an event's collection-keyed references", function()
        installData({Dragonflight = {[79] = "Alexstrasza", [81] = "Iridikron"}}, {})

        local names = FrontMatter.ResolveNames({["Dragonflight"] = {79, 81}}, "character")

        assert_.deepEquals(names, {"Alexstrasza", "Iridikron"})
    end)

    T.it("resolves a character's flat id array against the fallback collection", function()
        installData({}, {Dragonflight = {[57] = "Dragonflights", [58] = "Primalists"}})

        local names = FrontMatter.ResolveNames({57, 58}, "faction", "Dragonflight")

        assert_.deepEquals(names, {"Dragonflights", "Primalists"})
    end)

    T.it("returns nothing for a flat array with no fallback collection to resolve against", function()
        installData({}, {Dragonflight = {[57] = "Dragonflights"}})

        local names = FrontMatter.ResolveNames({57}, "faction", nil)

        assert_.isNil(names)
    end)

    T.it("spans several collections in one reference table", function()
        installData({Dragonflight = {[79] = "Alexstrasza"}, Legion = {[12] = "Illidan"}}, {})

        local names = FrontMatter.ResolveNames({["Dragonflight"] = {79}, ["Legion"] = {12}}, "character")

        -- Sorted, because pairs() over the collection keys has no defined order and a list that
        -- reshuffles between openings of the same event looks like a bug
        assert_.deepEquals(names, {"Alexstrasza", "Illidan"})
    end)
end)

-- -------------------------
-- The case mismatch
-- -------------------------

T.describe("FrontMatter collection name normalisation", function()
    T.it("resolves lowercase reference keys against capitalised registrations", function()
        -- This is the shape every record in the DB actually has: characters={["dragonflight"] = {...}}
        -- against RegisterCharacterDB("Dragonflight", ...). Without normalisation this returns nil for
        -- every reference in the shipped data.
        installData({Dragonflight = {[79] = "Alexstrasza", [81] = "Iridikron", [82] = "Vyranoth"}}, {})

        local names = FrontMatter.ResolveNames({["dragonflight"] = {79, 81, 82}}, "character")

        assert_.deepEquals(names, {"Alexstrasza", "Iridikron", "Vyranoth"})
    end)

    T.it("normalises the flat shape's fallback collection too", function()
        installData({}, {Dragonflight = {[57] = "Dragonflights"}})

        local names = FrontMatter.ResolveNames({57}, "faction", "dragonflight")

        assert_.deepEquals(names, {"Dragonflights"})
    end)

    T.it("passes an unknown collection through unchanged rather than guessing", function()
        installData({Dragonflight = {[79] = "Alexstrasza"}}, {})

        assert_.equals(FrontMatter.NormaliseCollectionName("Midnight"), "Midnight")
    end)
end)

-- -------------------------
-- Nothing to show
-- -------------------------

T.describe("FrontMatter.ResolveNames empty cases", function()
    T.it("returns nil rather than an empty table", function()
        installData({Dragonflight = {[79] = "Alexstrasza"}}, {})

        assert_.isNil(FrontMatter.ResolveNames(nil, "character"))
        assert_.isNil(FrontMatter.ResolveNames({}, "character"))
        assert_.isNil(FrontMatter.ResolveNames({["Dragonflight"] = {}}, "character"))
    end)

    T.it("skips ids that resolve to nothing instead of rendering a placeholder", function()
        -- A disabled collection legitimately resolves to nothing, and "Unknown" three times over is
        -- worse than a shorter list.
        installData({Dragonflight = {[79] = "Alexstrasza"}}, {})

        local names = FrontMatter.ResolveNames({["Dragonflight"] = {79, 999}}, "character")

        assert_.deepEquals(names, {"Alexstrasza"})
    end)

    T.it("returns nil when every id is unresolvable", function()
        installData({Dragonflight = {}}, {})

        assert_.isNil(FrontMatter.ResolveNames({["Dragonflight"] = {1, 2, 3}}, "character"))
    end)

    T.it("returns nil for an unknown kind", function()
        installData({Dragonflight = {[79] = "Alexstrasza"}}, {})

        assert_.isNil(FrontMatter.ResolveNames({["Dragonflight"] = {79}}, "creature"))
    end)

    T.it("returns nil when the data layer is not available", function()
        private.Chronicles = nil

        assert_.isNil(FrontMatter.ResolveNames({["Dragonflight"] = {79}}, "character"))
    end)
end)

-- -------------------------
-- The cap
-- -------------------------

T.describe("FrontMatter.ResolveNames truncation", function()
    -- 12 resolvable references, named so that sorting is predictable
    local function installTwelve()
        local records = {}
        for id = 1, 12 do
            records[id] = string.format("Name %02d", id)
        end
        installData({Legion = records}, {})

        local ids = {}
        for id = 1, 12 do
            table.insert(ids, id)
        end
        return ids
    end

    T.it("caps the list at eight names and reports the remainder", function()
        -- The cap is what keeps the front matter shorter than its 520 view. Without it an event
        -- referencing thirty characters pushes the body prose onto the next page, and the reader
        -- clicks a contents row to land on front matter with no text.
        local ids = installTwelve()

        local names, omitted = FrontMatter.ResolveNames({["Legion"] = ids}, "character")

        assert_.equals(#names, 8)
        assert_.equals(omitted, 4)
        assert_.equals(names[1], "Name 01", "the surviving names are the alphabetically first")
        assert_.equals(names[8], "Name 08")
    end)

    T.it("reports no remainder when the list fits", function()
        installData({Legion = {[1] = "Only"}}, {})

        local names, omitted = FrontMatter.ResolveNames({["Legion"] = {1}}, "character")

        assert_.equals(#names, 1)
        assert_.equals(omitted, 0)
    end)

    T.it("counts only names the reader would have seen, not unresolvable ids", function()
        -- Ids past the cap are still resolved: an omitted-count that includes stale references would
        -- promise names that do not exist.
        local ids = installTwelve()
        for _, id in ipairs({101, 102, 103}) do
            table.insert(ids, id)
        end

        local _, omitted = FrontMatter.ResolveNames({["Legion"] = ids}, "character")

        assert_.equals(omitted, 4, "the three unresolvable ids are not counted as more")
    end)
end)
