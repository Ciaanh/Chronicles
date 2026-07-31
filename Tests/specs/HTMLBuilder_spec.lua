--[[
    Specs for HTMLBuilder.CreateEntityHTML — the contract between the page loop and the navigation
    mapping.

    This is the pair that silently broke once already. The document loop walks chapter.pages while
    CreateChapterNavigationData counted chapter.pageCount, a field no record sets, so every chapter
    advanced the mapping by exactly one page no matter how many pages it had. Both now derive from
    GetChapterPageCount, and these specs are what keep them derived from the same thing.

    Two units are in play and the specs are explicit about which is which:
      * pageMapping is in *document* units, indices into the documents array.
      * the pager displays *spreads* of viewsPerPage documents, so document 5 is on page 3.
    DocumentIndexToSpread is the conversion, and it is asserted separately from the mapping.

    CreateEntityHTML is pure string building over a plain table, so none of this needs a widget.
]]

local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/StringUtils.lua", private)
H.loadModule("Core/Utils/HelperUtils.lua", private)
-- The builder reads constants.config.book.viewsPerPage to print contents page numbers, and
-- constants.eventType to name an event's type on the metadata line.
private.constants.config = {book = {viewsPerPage = 2}}
private.constants.eventType = {
    [0] = "undefined",
    [1] = "event",
    [2] = "era",
    [3] = "war",
    [4] = "battle"
}
H.loadModule("UI/Book/FrontMatter.lua", private)
H.loadModule("UI/Book/HTMLBuilder.lua", private)

local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- The stubbed AceLocale hands back an empty table, so every Locale[...] lookup falls through to the
-- builder's own literal fallback. That is what these specs assert against: " . " for the separator,
-- "Year %d" for a single-year date, and the bare key for a head with no translation.
local SEPARATOR = " . "

-- -------------------------
-- Fixtures
-- -------------------------

--[[
    Build an entity with `chapterCount` chapters of `pagesPerChapter` plain-text pages each.
    Page text is unique and greppable so authored order can be asserted.
]]
local function makeEntity(chapterCount, pagesPerChapter)
    local chapters = {}

    for chapterIndex = 1, chapterCount do
        local pages = {}
        for pageIndex = 1, pagesPerChapter do
            table.insert(pages, string.format("body c%d p%d", chapterIndex, pageIndex))
        end
        table.insert(chapters, {id = "c" .. chapterIndex, title = "Chapter " .. chapterIndex, pages = pages})
    end

    return {id = 1, name = "Fixture", yearStart = 10, yearEnd = 20, chapters = chapters}
end

-- Index of the first document whose body contains `needle`, or nil.
local function findDocument(documents, needle)
    for index, document in ipairs(documents) do
        if string.find(document, needle, 1, true) then
            return index
        end
    end
    return nil
end

-- -------------------------
-- One page in, one page out
-- -------------------------

T.describe("HTMLBuilder.CreateEntityHTML document count", function()
    T.it("emits front matter plus one body page for a single-page chapter", function()
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(1, 1))

        assert_.equals(#result.documents, 2, "cover + one body page")
    end)

    T.it("honours a three-page chapter as three pages, not one long one", function()
        -- The regression this whole item exists for: plain-text pages were concatenated into a single
        -- document, so an authored page break turned into a scroll bar.
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(1, 3))

        assert_.equals(#result.documents, 4, "cover + three body pages")
    end)

    T.it("emits sixteen documents for five chapters of three pages", function()
        -- No shipped record looks like this yet, which is exactly why it is asserted here.
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(5, 3))

        assert_.equals(#result.documents, 16, "cover + 15 body pages")
    end)

    T.it("keeps authored page order", function()
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(2, 2))

        local first = findDocument(result.documents, "body c1 p1")
        local second = findDocument(result.documents, "body c1 p2")
        local third = findDocument(result.documents, "body c2 p1")
        local fourth = findDocument(result.documents, "body c2 p2")

        assert_.equals(first, 2)
        assert_.equals(second, 3)
        assert_.equals(third, 4)
        assert_.equals(fourth, 5)
    end)

    T.it("renders a chapter mixing a plain page and a full HTML page in array order", function()
        -- The old shape collected full-HTML pages into a side-list appended *after* the chapter's
        -- concatenated text, so a mixed chapter came out in the wrong order.
        local entity = {
            id = 2,
            name = "Mixed",
            chapters = {
                {
                    id = "c1",
                    title = "Mixed",
                    pages = {"plain first", "<html><body><p>markup second</p></body></html>", "plain third"}
                }
            }
        }

        local result = HTMLBuilder.CreateEntityHTML(entity)

        assert_.equals(#result.documents, 4, "cover + three body pages")
        assert_.equals(findDocument(result.documents, "plain first"), 2)
        assert_.equals(findDocument(result.documents, "markup second"), 3)
        assert_.equals(findDocument(result.documents, "plain third"), 4)
    end)

    T.it("wraps a full HTML page like its siblings instead of shipping the author's wrapper", function()
        local entity = {
            id = 3,
            name = "Wrapped",
            chapters = {{id = "c1", title = "Wrapped", pages = {"<html><body><p>inner</p></body></html>"}}}
        }

        local result = HTMLBuilder.CreateEntityHTML(entity)
        local bodyPage = result.documents[2]

        -- Exactly one document wrapper, not the author's nested inside ours
        local _, openTags = string.gsub(bodyPage, "<html>", "")
        assert_.equals(openTags, 1, "single html wrapper")
        assert_.isNotNil(string.find(bodyPage, "<p>inner</p>", 1, true), "inner content survived")
    end)

    T.it("keeps the single chapter.content field as one page", function()
        local entity = {
            id = 4,
            name = "Single field",
            chapters = {{id = "c1", title = "Single field", content = "one field of prose"}}
        }

        local result = HTMLBuilder.CreateEntityHTML(entity)

        assert_.equals(#result.documents, 2)
        assert_.equals(findDocument(result.documents, "one field of prose"), 2)
    end)
end)

-- -------------------------
-- Page counting
-- -------------------------

T.describe("HTMLBuilder.GetChapterPageCount", function()
    T.it("counts the pages array", function()
        assert_.equals(HTMLBuilder.GetChapterPageCount({pages = {"a", "b", "c"}}), 3)
    end)

    T.it("floors at one page for a chapter with no pages array", function()
        assert_.equals(HTMLBuilder.GetChapterPageCount({content = "prose"}), 1)
        assert_.equals(HTMLBuilder.GetChapterPageCount({}), 1)
        assert_.equals(HTMLBuilder.GetChapterPageCount({pages = {}}), 1)
    end)

    T.it("returns zero for no chapter at all", function()
        assert_.equals(HTMLBuilder.GetChapterPageCount(nil), 0)
    end)
end)

-- -------------------------
-- Navigation mapping, in document units
-- -------------------------

T.describe("HTMLBuilder navigation mapping", function()
    T.it("maps each chapter to the index of its first document", function()
        -- 5 chapters x 3 pages, cover at 1: chapter 1 starts at 2, chapter 2 at 5, chapter 3 at 8...
        local entity = makeEntity(5, 3)
        local result = HTMLBuilder.CreateEntityHTML(entity)
        local mapping = result.navigationData.pageMapping

        assert_.equals(mapping["cover"], 1)
        assert_.equals(mapping["c1"], 2)
        assert_.equals(mapping["c2"], 5)
        assert_.equals(mapping["c3"], 8)
        assert_.equals(mapping["c4"], 11)
        assert_.equals(mapping["c5"], 14)
    end)

    T.it("points every chapter at a document that actually contains its first page", function()
        -- The assertion that catches the mapping drifting from the loop again, whatever the cause:
        -- it compares the mapping against the emitted documents rather than against a second formula.
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(5, 3))
        local mapping = result.navigationData.pageMapping

        for chapterIndex = 1, 5 do
            local documentIndex = mapping["c" .. chapterIndex]
            local expected = string.format("body c%d p1", chapterIndex)
            assert_.isNotNil(
                string.find(result.documents[documentIndex], expected, 1, true),
                string.format("document %d should hold %q", documentIndex, expected)
            )
        end
    end)

    T.it("advances by one document for a chapter that has no pages array", function()
        local entity = {
            id = 5,
            name = "Mixed shapes",
            chapters = {
                {id = "c1", title = "Field", content = "prose"},
                {id = "c2", title = "Pages", pages = {"p1", "p2"}}
            }
        }

        local result = HTMLBuilder.CreateEntityHTML(entity)

        assert_.equals(result.navigationData.pageMapping["c1"], 2)
        assert_.equals(result.navigationData.pageMapping["c2"], 3)
        assert_.equals(#result.documents, 4)
    end)
end)

-- -------------------------
-- Document units to spreads
-- -------------------------

T.describe("HTMLBuilder.DocumentIndexToSpread", function()
    T.it("pairs documents into spreads", function()
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(1), 1)
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(2), 1)
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(3), 2)
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(4), 2)
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(5), 3)
    end)

    T.it("puts chapter 2 of a sixteen-document book on spread 3", function()
        -- The unit-confusion assertion. Chapter 2's first document is index 5; handing 5 straight to
        -- the pager would open spread 5, which is chapter 4's territory.
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(5, 3))
        local documentIndex = result.navigationData.pageMapping["c2"]

        assert_.equals(documentIndex, 5, "mapping stays in document units")
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(documentIndex), 3, "displayed page")
    end)

    T.it("clamps a bad index to the first page rather than returning zero", function()
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(0), 1)
        assert_.equals(HTMLBuilder.DocumentIndexToSpread(nil), 1)
    end)
end)

-- -------------------------
-- Contents list
-- -------------------------

T.describe("HTMLBuilder contents list", function()
    T.it("emits no contents block for a single-chapter entity", function()
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(1, 3))

        assert_.isNil(findDocument(result.documents, "chronicles:chapter:"), "no chapter links anywhere")
    end)

    T.it("puts the contents on the front matter, not on a page of its own", function()
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(3, 1))

        assert_.equals(findDocument(result.documents, "chronicles:chapter:c1"), 1, "contents is on document 1")
        assert_.equals(#result.documents, 4, "front matter + three body pages, no contents page")
    end)

    T.it("prints each row's page number in spread units", function()
        -- 5 chapters x 3 pages: chapter 2 starts at document 5, which the reader sees as page 3.
        local result = HTMLBuilder.CreateEntityHTML(makeEntity(5, 3))
        local frontMatter = result.documents[1]

        assert_.isNotNil(
            string.find(frontMatter, "chronicles:chapter:c2\">Chapter 2</a>" .. SEPARATOR .. "3", 1, true),
            "chapter 2 is printed as page 3"
        )
    end)

    T.it("emits the chapter link as markup, not as escaped text", function()
        -- CreateParagraph escapes by default, which turned every contents row into a visible
        -- &lt;a href=... string. The rows have to opt out of escaping.
        local frontMatter = HTMLBuilder.CreateEntityHTML(makeEntity(2, 1)).documents[1]

        assert_.isNotNil(string.find(frontMatter, '<a href="chronicles:chapter:c1">', 1, true), "real anchor")
        assert_.isNil(string.find(frontMatter, "&lt;a href", 1, true), "not escaped")
    end)
end)

-- -------------------------
-- Front matter
-- -------------------------

T.describe("HTMLBuilder front matter", function()
    -- Two characters and two factions in a capitalised collection, referenced the way the DB writes
    -- them: lowercase keys.
    local function installData()
        local function finder(store)
            return function(_, id, collectionName)
                local collection = store[collectionName]
                local name = collection and collection[id]
                return name and {id = id, name = name} or nil
            end
        end

        private.Chronicles = {
            Data = {
                FindCharacterByIdAndCollection = finder({Dragonflight = {[79] = "Alexstrasza", [81] = "Iridikron"}}),
                FindFactionByIdAndCollection = finder({Dragonflight = {[57] = "Dragonflights"}}),
                GetCollectionsNames = function()
                    return {{name = "Dragonflight", isActive = true}}
                end
            }
        }
    end

    local function makeEvent(overrides)
        local event = {
            id = 180,
            label = "Dragon Isles Reawaken",
            yearStart = 40,
            yearEnd = 40,
            eventType = 4,
            source = "Dragonflight",
            chapters = {{id = "c1", title = "Only", pages = {"prose"}}}
        }

        for key, value in pairs(overrides or {}) do
            event[key] = value
        end

        return event
    end

    T.it("joins year, event type and collection on one metadata line", function()
        installData()

        local frontMatter = HTMLBuilder.CreateEntityHTML(makeEvent()).documents[1]

        assert_.isNotNil(
            string.find(frontMatter, "Year 40" .. SEPARATOR .. "battle" .. SEPARATOR .. "Dragonflight", 1, true),
            "metadata line"
        )
    end)

    T.it("resolves cross-references into names under their own heads", function()
        installData()

        local frontMatter =
            HTMLBuilder.CreateEntityHTML(
            makeEvent({characters = {["dragonflight"] = {79, 81}}, factions = {["dragonflight"] = {57}}})
        ).documents[1]

        assert_.isNotNil(string.find(frontMatter, "Alexstrasza" .. SEPARATOR .. "Iridikron", 1, true), "characters")
        assert_.isNotNil(string.find(frontMatter, "Dragonflights", 1, true), "factions")
        assert_.isNotNil(string.find(frontMatter, "BOOK_FRONT_CHARACTERS", 1, true), "characters head")
        assert_.isNotNil(string.find(frontMatter, "BOOK_FRONT_FACTIONS", 1, true), "factions head")
    end)

    T.it("renders no heading at all for an entity with no references", function()
        installData()

        local frontMatter = HTMLBuilder.CreateEntityHTML(makeEvent()).documents[1]

        assert_.isNil(string.find(frontMatter, "BOOK_FRONT_CHARACTERS", 1, true), "no empty characters head")
        assert_.isNil(string.find(frontMatter, "BOOK_FRONT_FACTIONS", 1, true), "no empty factions head")
    end)

    T.it("never renders a bare separator", function()
        installData()

        -- A character: no year, no event type, so the metadata line is the collection alone
        local frontMatter =
            HTMLBuilder.CreateEntityHTML(
            {
                id = 79,
                name = "Alexstrasza",
                source = "Dragonflight",
                chapters = {{id = "c1", pages = {"prose"}}}
            }
        ).documents[1]

        assert_.isNotNil(string.find(frontMatter, "Dragonflight", 1, true), "collection is still named")
        assert_.isNil(string.find(frontMatter, ">" .. SEPARATOR, 1, true), "no paragraph opens with a separator")
        assert_.isNil(string.find(frontMatter, SEPARATOR .. "<", 1, true), "none ends with one either")
        assert_.isNil(string.find(frontMatter, SEPARATOR .. SEPARATOR, 1, true), "and none doubles up")
    end)

    T.it("omits the metadata line entirely when there is nothing to put on it", function()
        installData()

        local frontMatter =
            HTMLBuilder.CreateEntityHTML({id = 1, name = "Bare", chapters = {{id = "c1", pages = {"prose"}}}}).documents[
            1
        ]

        assert_.isNotNil(string.find(frontMatter, "Bare", 1, true), "the title is still there")
        assert_.isNil(string.find(frontMatter, SEPARATOR, 1, true), "and no separator anywhere")
    end)

    T.it("shows no portrait slot for a record with no image", function()
        installData()

        local frontMatter = HTMLBuilder.CreateEntityHTML(makeEvent()).documents[1]

        assert_.isNil(string.find(frontMatter, "<img src=\"Interface\\AddOns\\Chronicles\\Art\\Portrait", 1, true))
    end)

    T.it("renders a 128px left-aligned portrait when a record does carry an image", function()
        installData()

        local frontMatter =
            HTMLBuilder.CreateEntityHTML(makeEvent({image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande"}))
            .documents[1]

        assert_.isNotNil(string.find(frontMatter, 'width="128" height="128" align="left"', 1, true))
    end)
end)
