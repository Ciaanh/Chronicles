--[[
    FixtureEventsDB.lua — a local test rig, not shipped content.

    The reduced content set cannot exercise the book: 320 of 321 events have exactly one chapter, no
    locale string contains HTML, the longest body text is 1148 characters, and the widest event names
    three characters. So nothing in DB/ proves that a chaptered, long, heavily cross-referenced entity
    renders correctly — which is precisely the shape content is growing towards.

    These four records are that shape.

    LOADING IT (two temporary lines, both reverted before committing)

      1. DB/DB.xml, before DB.lua like every real collection:
             <Script file="99_Fixture\FixtureEventsDB.lua"/>
      2. DB/DB.lua, inside private.registerInternalDBs():
             if DB.FixtureEventsDB then Data:RegisterEventDB("Fixture", DB.FixtureEventsDB) end

    Then restart the client — a new file is not picked up by /reload — verify, and remove both lines.
    The file itself stays checked in: it is listed in the harness manifest's checkIgnore so `check` does
    not report it as an orphan, and in packageExclude so `package` never ships it.

    Text is literal rather than Locale[...] on purpose, so verifying needs no locale edit either.

    WHAT EACH RECORD PROVES

      9001  Five chapters of three pages: 16 documents, a five-row contents list, and page numbers in
            spread units (chapter 2 starts at document 5 and must print as page 3). This is the record
            that catches a document index being handed to the pager unconverted, because it is the only
            shape where the two numbers differ visibly.
      9002  One 3000-character page, roughly ten times the p95 of the shipped data: the body view
            scrolls rather than clipping, the scroll bar appears, and the wheel reaches it.
      9003  Twenty characters and twenty factions: the front matter's name lists truncate at eight with
            "+ N more" instead of growing the front-matter document past its 520 view and pushing the
            body prose onto the next page. The ids are deliberately unresolvable, which also proves the
            resolver skips what it cannot find rather than rendering placeholders.
      9004  The shape the whole DB currently has: one chapter, one short page, no cross-references. It
            is here so a regression in the common case is visible beside the exotic ones.
]]
local FOLDER_NAME, private = ...

private.DB = private.DB or {}

-- ~3000 characters, built rather than pasted so the file stays readable
local LONG_PAGE =
    string.rep(
    "The archivists disagree about this passage, and their disagreement is itself part of the record. " ..
        "Each retelling adds a name, drops a year, and moves the blame one house further east. ",
    16
)

local function chapters(count, pagesPerChapter)
    local built = {}

    for chapterIndex = 1, count do
        local pages = {}
        for pageIndex = 1, pagesPerChapter do
            table.insert(
                pages,
                string.format(
                    "Chapter %d, page %d. This page exists to be counted: it must be its own book page, " ..
                        "in this order, and the contents row for chapter %d must point at the page holding " ..
                        "chapter %d page 1.",
                    chapterIndex,
                    pageIndex,
                    chapterIndex,
                    chapterIndex
                )
            )
        end

        table.insert(
            built,
            {
                header = string.format("Fixture chapter %d", chapterIndex),
                pages = pages
            }
        )
    end

    return built
end

local function idRange(first, count)
    local ids = {}
    for offset = 0, count - 1 do
        table.insert(ids, first + offset)
    end
    return ids
end

private.DB.FixtureEventsDB = {
    [9001] = {
        id = 9001,
        label = "Fixture: five chapters of three pages",
        chapters = chapters(5, 3),
        yearStart = 900,
        yearEnd = 950,
        eventType = 3,
        timeline = 1,
        order = 0,
        characters = {},
        factions = {}
    },
    [9002] = {
        id = 9002,
        label = "Fixture: one very long page",
        chapters = {
            {
                header = "A page that overflows its view",
                pages = {LONG_PAGE}
            }
        },
        yearStart = 951,
        yearEnd = 951,
        eventType = 1,
        timeline = 1,
        order = 1,
        characters = {},
        factions = {}
    },
    [9003] = {
        id = 9003,
        label = "Fixture: twenty characters and twenty factions",
        chapters = {
            {
                header = "",
                pages = {"The front matter beside this page must stay shorter than its view."}
            }
        },
        yearStart = 952,
        yearEnd = 952,
        eventType = 4,
        timeline = 1,
        order = 2,
        characters = {["fixture"] = idRange(9100, 20)},
        factions = {["fixture"] = idRange(9200, 20)}
    },
    [9004] = {
        id = 9004,
        label = "Fixture: the ordinary case",
        chapters = {
            {
                header = "",
                pages = {"One chapter, one short page, no cross-references."}
            }
        },
        yearStart = 953,
        yearEnd = 953,
        eventType = 1,
        timeline = 1,
        order = 3,
        characters = {},
        factions = {}
    }
}
