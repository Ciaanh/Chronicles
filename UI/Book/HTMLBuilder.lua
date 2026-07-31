--[[
    HTMLBuilder.lua
    
    Enhanced HTML content generation for the Chronicles book system.
    Generates SimpleHTML-compatible content for World of Warcraft addons.
    
    IMPORTANT: This builder is designed specifically for WoW's SimpleHTML widget,
    which has VERY LIMITED HTML support compared to web browsers.
    
    SUPPORTED HTML ELEMENTS (SimpleHTML):
    - <html>, <body> - Basic document structure
    - <h1>, <h2>, <h3> - Headings (h4+ are treated as h3)
    - <p align="left|center|right"> - Paragraphs with alignment
    - <br/> - Line breaks
    - <img src="path" width="N" height="N" align="left|center|right"/> - Images
    - <a href="url">text</a> - Links (requires frame hyperlink handler)
    
    NOT SUPPORTED:
    - CSS styling, <style> tags, or most HTML attributes
    - <div>, <span>, <ul>, <ol>, <li> - Use paragraphs instead
    - Complex layouts - SimpleHTML is very basic
    - Most HTML entities except: &amp; &lt; &gt; &quot;
    
    EXTENDED ENTITIES (via LibMarkdown):
    - &nbsp; &emsp; &ensp; &em13; &em14; &thinsp; - Spacing entities
    
    WOW COLOR CODES:
    - Use |cFFRRGGBB for colors, |r to reset
    - These work within any text content
]]
local FOLDER_NAME, private = ...

-- Import dependencies
local StringUtils = private.Core.Utils.StringUtils
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-- Initialize HTMLBuilder namespace
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.HTMLBuilder = {}
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- =============================================================================================
-- CONSTANTS
-- =============================================================================================

-- WoW color codes
local WOW_COLORS = {
    title = "|cFFffd100", -- Gold
    subtitle = "|cFFd4af37", -- Dark gold
    text = "|cFFffffff", -- White
    author = "|cFFcccccc", -- Light gray
    date = "|cFFffd100", -- Gold
    chapter = "|cFFe6b800", -- Yellow gold
    quote = "|cFFaaaaaa", -- Medium gray
    source = "|cFF888888", -- Dark gray
    important = "|cFFff6600", -- Orange
    warning = "|cFFff0000", -- Red
    success = "|cFF00ff00", -- Green
    reset = "|r"
}

-- Portrait settings for WoW image display. Powers of two, because SimpleHTML's <img> wants them, and
-- left-aligned so the slot seats at the top-left of the front matter when data eventually exists: no
-- record in the DB carries an image field today.
local PORTRAIT_SETTINGS = {
    width = "128",
    height = "128",
    align = "left"
}

-- HTML entities for SimpleHTML
local HTML_ENTITIES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;"
}

-- =============================================================================================
-- UTILITY FUNCTIONS
-- =============================================================================================

local function ApplyWoWColor(text, colorCode)
    if not text or text == "" then
        return ""
    end
    if not colorCode then
        return text
    end

    return colorCode .. text .. WOW_COLORS.reset
end

-- Minimal HTML escaping for SimpleHTML-safe text. One pass over a replacement table rather than
-- chained gsubs: chaining has to escape "&" first or it re-escapes its own output into "&amp;lt;".
local function EscapeHTML(text)
    if not text or text == "" then
        return ""
    end
    return (text:gsub('[&<>"]', HTML_ENTITIES))
end

--[[
    Extract inner HTML content from a full HTML string.
    Prefers <body>...</body>, falls back to <html>...</html>, and finally the original string.
    Case-insensitive search while preserving original content.
    @param html [string]
    @return [string] inner content
]]
local function ExtractInnerHTML(html)
    if not html or html == "" then return "" end

    local lower = html:lower()
    local sOpen, eOpen = lower:find("<body[^>]*>")
    if sOpen then
        local sClose = lower:find("</body>", eOpen + 1, true)
        if sClose then
            return html:sub(eOpen + 1, sClose - 1)
        end
    end

    sOpen, eOpen = lower:find("<html[^>]*>")
    if sOpen then
        local sClose = lower:find("</html>", eOpen + 1, true)
        if sClose then
            return html:sub(eOpen + 1, sClose - 1)
        end
    end

    return html
end

-- =============================================================================================
-- HTML BUILDERS
-- =============================================================================================

--[[
    Create a minimal HTML document structure compatible with SimpleHTML
    SimpleHTML only supports: <html>, <body>, <h1>, <h2>, <h3>, <p>, <br/>, <img>, <a>
    No CSS, no styling attributes except align on <p> and <img>
    @param content [string] HTML body content
    @return [string] Complete HTML document
]]
function HTMLBuilder.CreateHTMLDocument(content)
    if not content then
        content = ""
    end

    -- SimpleHTML requires minimal structure - no CSS, no DOCTYPE, no head styling
    local html = string.format("<html><body>%s</body></html>", content)
    return html
end

-- =============================================================================================
-- CONTENT BLOCK BUILDERS
-- =============================================================================================

--[[
    Create a title block with WoW color codes
    Uses <h1> which is supported by SimpleHTML
    @param title [string] Title text
    @param options [table] Optional; set options.divider = false to omit the rule under the title, for
                           callers that put something between the two (the front matter's metadata line)
    @return [string] HTML title element
]]
function HTMLBuilder.CreateTitle(title, options)
    if not title or title == "" then
        return ""
    end

    --local coloredTitle = ApplyWoWColor(safeTitle, WOW_COLORS.title)

    local divider = ""
    if not options or options.divider ~= false then
        divider = HTMLBuilder.CreateDecorativeDivider()
    end

    return string.format('<h1 align="center">%s</h1>%s', EscapeHTML(title), divider)
end

--[[
    Create a subtitle block with WoW color codes
    Uses <h2> which is supported by SimpleHTML
    @param subtitle [string] Subtitle text
    @return [string] HTML subtitle element
]]
function HTMLBuilder.CreateSubtitle(subtitle)
    if not subtitle or subtitle == "" then
        return ""
    end

    return string.format("<h2>%s</h2>", EscapeHTML(subtitle))
end

--[[
    Create an author attribution block with WoW color codes
    Uses <p> with align attribute which is supported by SimpleHTML
    @param author [string] Author name
    @return [string] HTML author element
]]
function HTMLBuilder.CreateAuthor(author)
    if not author or author == "" then
        return ""
    end

    return string.format('<p align="right">%s</p>', EscapeHTML(author))
end

--[[
    The wording of an event's date, as plain text.

    Split out from CreateDateRange so the front matter's metadata line can join the same phrasing with
    the event type and collection instead of reproducing it. One wording, two placements.

    @param yearStart [number] Start year
    @param yearEnd [number] End year
    @return [string] Date text, empty when neither bound is given
]]
function HTMLBuilder.GetDateRangeText(yearStart, yearEnd)
    if not yearStart and not yearEnd then
        return ""
    end

    local dateText = ""
    if yearStart and yearEnd then
        if yearStart == yearEnd then
            dateText = Locale["BOOK_DATE_YEAR"] and string.format(Locale["BOOK_DATE_YEAR"], yearStart) or
                           string.format("Year %d", yearStart)
        else
            dateText = Locale["BOOK_DATE_YEARS_RANGE"] and
                           string.format(Locale["BOOK_DATE_YEARS_RANGE"], yearStart, yearEnd) or
                           string.format("Years %d - %d", yearStart, yearEnd)
        end
    elseif yearStart then
        dateText = Locale["BOOK_DATE_FROM_YEAR"] and string.format(Locale["BOOK_DATE_FROM_YEAR"], yearStart) or
                       string.format("From Year %d", yearStart)
    elseif yearEnd then
        dateText = Locale["BOOK_DATE_UNTIL_YEAR"] and string.format(Locale["BOOK_DATE_UNTIL_YEAR"], yearEnd) or
                       string.format("Until Year %d", yearEnd)
    end

    return dateText
end

--[[
    Create a date range block for events
    Uses <p> with align which is supported by SimpleHTML
    @param yearStart [number] Start year
    @param yearEnd [number] End year
    @return [string] HTML date range element
]]
function HTMLBuilder.CreateDateRange(yearStart, yearEnd)
    local dateText = HTMLBuilder.GetDateRangeText(yearStart, yearEnd)
    if dateText == "" then
        return ""
    end

    return string.format('<p align="right">%s</p>', dateText)
end

--[[
    Create a portrait image element compatible with WoW texture paths
    Uses <img> with src, width, height, align attributes - all supported by SimpleHTML
    @param portraitPath [string] Path to portrait image
    @param options [table] Optional styling overrides
    @return [string] HTML img element
]]
function HTMLBuilder.CreatePortrait(portraitPath, options)
    if not portraitPath or portraitPath == "" then
        return ""
    end

    options = options or {}
    local width = options.width or PORTRAIT_SETTINGS.width
    local height = options.height or PORTRAIT_SETTINGS.height
    local align = options.align or PORTRAIT_SETTINGS.align

    return string.format('<img src="%s" width="%s" height="%s" align="%s"/>', portraitPath, width, height, align)
end

--[[
    Create a paragraph element with text escaping
    Uses <p> with optional align attribute - both supported by SimpleHTML
    @param text [string] Paragraph text
    @param options [table] Optional styling (align: left, center, right) and options.escape = false for
                           content this builder has already turned into markup. Escaping is the default
                           because most callers pass author text; a caller that has just built an <a>
                           element must opt out, or the reader sees &lt;a href=... spelled out. That was
                           happening to every table-of-contents row and every CreateNavigationLinks list.
    @return [string] HTML paragraph element
]]
function HTMLBuilder.CreateParagraph(text, options)
    if not text or text == "" then
        return ""
    end

    options = options or {}
    local safe = text
    if options.escape ~= false then
        safe = EscapeHTML(text)
    end
    if options.align then
        return string.format('<p align="%s">%s</p>', options.align, safe)
    else
        return string.format("<p>%s</p>", safe)
    end
end

--[[
    Create a visual divider using line breaks
    Uses <br/> which is supported by SimpleHTML
    @return [string] HTML divider element
]]
function HTMLBuilder.CreateDivider()
    return "<br/><br/>"
end

--[[
    Create a page break using multiple line breaks
    Uses <br/> which is supported by SimpleHTML
    @return [string] HTML page break element
]]
function HTMLBuilder.CreatePageBreak()
    return "<br/><br/><br/>"
end

--[[
    Create a hyperlink element for Chronicles navigation
    Uses <a> with href attribute - supported by SimpleHTML but requires frame handler
    @param text [string] Link text to display
    @param linkType [string] Type of link (event, character, faction, external)
    @param linkData [string|number] Link data (ID, name, or URL)
    @return [string] HTML link element
]]
function HTMLBuilder.CreateLink(text, linkType, linkData)
    if not text or text == "" or not linkType or not linkData then
        return text or ""
    end

    local href = string.format("chronicles:%s:%s", linkType, tostring(linkData))

    return string.format('<a href="%s">%s</a>', href, EscapeHTML(text))
end

--[[
    Create multiple navigation links in a paragraph
    @param links [table] Array of {text, linkType, linkData} tables
    @param separator [string] Separator between links (default: " | ")
    @return [string] HTML paragraph with multiple links
]]
function HTMLBuilder.CreateNavigationLinks(links, separator)
    if not links or #links == 0 then
        return ""
    end

    separator = separator or " | "
    local linkElements = {}

    for _, link in ipairs(links) do
        if link.text and link.linkType and link.linkData then
            table.insert(linkElements, HTMLBuilder.CreateLink(link.text, link.linkType, link.linkData))
        end
    end

    if #linkElements == 0 then
        return ""
    end

    -- escape = false: these are <a> elements built by CreateLink, which has already escaped their text
    local navigationContent = table.concat(linkElements, separator)
    return HTMLBuilder.CreateParagraph(navigationContent, {align = "center", escape = false})
end

--[[
    Create decorative dividers with different types
    @param dividerType [string] Type of divider: "chapter", "section", or default
    @return [string] HTML img element for divider
]]
function HTMLBuilder.CreateDecorativeDivider(dividerType)
    local dividerPath = "Interface\\AddOns\\Chronicles\\Art\\"

    if dividerType == "chapter" then
        return string.format(
            '<img src="%s" width="256" height="32" align="center"/>',
            (dividerPath .. "ChapterDivider.tga")
        )
    elseif dividerType == "section" then
        return string.format(
            '<img src="%s" width="128" height="16" align="center"/>',
            (dividerPath .. "SectionDivider.tga")
        )
    else
        return string.format('<img src="%s" width="450" height="25" align="center"/>', (dividerPath .. "Divider.tga"))
    end
end

--[[
    Create a table of contents with clickable navigation links
    @param entity [table] Entity with chapters
    @param navigationData [table] Navigation data with page mapping
    @return [string] HTML table of contents
]]
-- The id a chapter is addressed by in a "chronicles:chapter:<id>" link. Both the table of contents
-- (which emits the link) and CreateChapterNavigationData (which builds the id -> page mapping the
-- link is resolved against) must derive it the same way, or every TOC entry silently goes nowhere.
local function ChapterLinkId(chapter, index)
    return chapter.id or ("chapter_" .. index)
end

function HTMLBuilder.CreateTableOfContents(entity, navigationData)
    if not entity or not entity.chapters then
        return ""
    end

    local tocTitle = Locale["BOOK_CONTENTS_TITLE"] or "Contents"
    local tocContent = HTMLBuilder.CreateSubtitle(tocTitle)
    local pageMapping = navigationData and navigationData.pageMapping

    for i, chapter in ipairs(entity.chapters) do
        local chapterTitle = chapter.title or chapter.header or ((Locale["BOOK_CHAPTER_N"] and string.format(Locale["BOOK_CHAPTER_N"], i)) or ("Chapter " .. i))
        local chapterNumber = (Locale["BOOK_CHAPTER_N"] and string.format(Locale["BOOK_CHAPTER_N"], i)) or string.format("Chapter %d", i)
        local chapterId = ChapterLinkId(chapter, i)

        -- Create clickable link to navigate to the chapter
        local chapterLink = HTMLBuilder.CreateLink(chapterTitle, "chapter", chapterId)

        -- Format: "Chapter 1: Chapter Title"
        local tocEntry = string.format("%s: %s", chapterNumber, chapterLink)

        -- ...and the page it is on, which is what makes this a table of contents rather than a list of
        -- links. The mapping is in document units and the reader sees spreads, so convert: chapter 2 of
        -- a book whose chapters run three pages each starts at document 5 and is printed as page 3.
        local documentIndex = pageMapping and pageMapping[chapterId]
        if documentIndex then
            local pageFmt = Locale["BOOK_CONTENTS_PAGE_N"] or "%d"
            local separator = Locale["BOOK_FRONT_META_SEPARATOR"] or " . "
            tocEntry =
                tocEntry .. separator .. string.format(pageFmt, HTMLBuilder.DocumentIndexToSpread(documentIndex))
        end

        -- escape = false: tocEntry holds the <a> element CreateLink built, and CreateLink has already
        -- escaped the chapter title inside it
        tocContent = tocContent .. HTMLBuilder.CreateParagraph(tocEntry, {align = "left", escape = false})
    end

    return tocContent
end

--[[
    How many book pages a chapter occupies.

    One entry in chapter.pages is one book page. This is the single derivation of that count: both
    the document loop in CreateEntityHTML and the id -> page mapping in CreateChapterNavigationData
    call it, so the mapping cannot drift from the documents actually emitted. It replaces a
    chapter.pageCount field that no record has ever set, which is why a contents link into chapter 3
    of a paged book used to land on the wrong page.

    A chapter with no pages array still occupies one page: either it carries the single-field
    chapter.content alternative, or it is empty and renders as a blank page under its heading.

    @param chapter [table] Chapter data
    @return [number] Page count, never below 1 for a chapter that exists
]]
function HTMLBuilder.GetChapterPageCount(chapter)
    if not chapter then
        return 0
    end

    local pages = chapter.pages
    if type(pages) == "table" and #pages > 0 then
        return #pages
    end

    return 1
end

--[[
    Convert a document index into the page the reader will see it on.

    pageMapping counts documents; the book displays a spread of viewsPerPage documents per page. The
    builder has no frame to ask, so it reads the constant that BookContainerTemplate.xml's KeyValue is
    kept equal to. Anything holding the actual frame should call its GetPageForViewDataIndex instead,
    which is the same arithmetic against the value the pager is really using.

    @param documentIndex [number] 1-based index into the htmlDocuments array
    @return [number] 1-based displayed page number
]]
function HTMLBuilder.DocumentIndexToSpread(documentIndex)
    if not documentIndex or documentIndex < 1 then
        return 1
    end

    local bookConfig = private.constants and private.constants.config and private.constants.config.book
    local viewsPerPage = (bookConfig and bookConfig.viewsPerPage) or 1
    if viewsPerPage < 1 then
        viewsPerPage = 1
    end

    return math.ceil(documentIndex / viewsPerPage)
end

--[[
    Create chapter navigation data structure

    pageMapping is in *document* units, i.e. indices into the htmlDocuments array, because the
    builder has no access to the book frame's viewsPerPage. Consumers convert: a displayed page is a
    spread of viewsPerPage views, so document index 5 is on spread 3 at viewsPerPage = 2. Convert at
    the point of use (HTMLContentMixin:NavigateToChapter, and the printed contents page numbers),
    never here.

    @param entity [table] Entity with chapters
    @return [table] Navigation data with chapter mappings
]]
function HTMLBuilder.CreateChapterNavigationData(entity)
    if not entity or not entity.chapters then
        return {}
    end

    local navigationData = {
        chapters = {},
        pageMapping = {}, -- Maps chapter ID to document index in htmlDocuments
        chapterLookup = {} -- Maps chapter ID to chapter data
    }

    -- Front matter is always document 1, and there is no separate contents document: the contents
    -- list lives on the front matter. A page that exists only for entities with more than one chapter
    -- made the whole book's numbering depend on chapter count in a second, redundant way, and every
    -- contents row has to carry a page number regardless.
    local currentPageIndex = 1
    navigationData.pageMapping["cover"] = currentPageIndex
    currentPageIndex = currentPageIndex + 1

    -- Chapter pages
    for i, chapter in ipairs(entity.chapters) do
        local chapterId = ChapterLinkId(chapter, i)

        navigationData.chapters[i] = {
            id = chapterId,
            title = chapter.title or chapter.header or ((Locale["BOOK_CHAPTER_N"] and string.format(Locale["BOOK_CHAPTER_N"], i)) or ("Chapter " .. i)),
            startPage = currentPageIndex,
            index = i
        }

        navigationData.pageMapping[chapterId] = currentPageIndex
        navigationData.chapterLookup[chapterId] = navigationData.chapters[i]

        -- Same derivation the document loop walks, so the two cannot disagree
        currentPageIndex = currentPageIndex + HTMLBuilder.GetChapterPageCount(chapter)
    end

    return navigationData
end

--[[
    Create page header with chapter information
    @param chapter [table] A navigationData.chapters entry, carrying index and title
    @return [string] HTML page header
]]
function HTMLBuilder.CreatePageHeader(chapter)
    if not chapter then
        return ""
    end

    local headerFmt = Locale["BOOK_CHAPTER_HEADER"] or "Chapter %d: %s"
    local headerContent = HTMLBuilder.CreateParagraph(string.format(headerFmt, chapter.index, EscapeHTML(chapter.title or "")), {align = "center"})

    return headerContent .. HTMLBuilder.CreateDivider()
end

-- =============================================================================================
-- ENTITY CONTENT GENERATION
-- =============================================================================================

--[[
    Render one authored page into body HTML.

    Three shapes, applied per page rather than per chapter. The distinction used to decide whether a
    page became its own book page or was concatenated into the chapter's single page, which meant
    every authored page break collapsed unless the author wrote a literal <html> document: no locale
    string in the DB does. Now it decides only how the content is wrapped.

    A full document goes through ExtractInnerHTML rather than being passed along untouched, so it
    ends up wrapped by CreateHTMLDocument like its siblings instead of reaching the widget with
    whatever wrapper the author happened to write.

    @param page [string] One entry from chapter.pages, or a chapter.content field
    @return [string] Body HTML, empty string for an absent or empty page
]]
local function RenderPageBody(page)
    if not page or page == "" then
        return ""
    end

    if StringUtils.ContainsHTML(page) then
        return ExtractInnerHTML(page)
    end

    -- Fragment: some markup but not a document, so it is already body content
    if string.find(page, "<[^>]+>") then
        return page
    end

    return HTMLBuilder.CreateParagraph(page)
end

--[[
    Build the heading that opens a chapter: its "Chapter n: title" line and, when the record actually
    carries one, the chapter header and its section rule. It goes on the chapter's first page only.

    The header is tested against "" as well as nil: the generator emits Locale[""] for a chapter with
    no header, which resolves to an empty string, and an empty <h3> plus a divider is visible noise.

    @param chapterData [table|nil] The navigation entry for this chapter
    @param chapter [table] Chapter data
    @return [string] Heading HTML, possibly empty
]]
local function BuildChapterHeading(chapterData, chapter)
    local heading = ""

    if chapterData then
        heading = heading .. HTMLBuilder.CreatePageHeader(chapterData)
    end

    if chapter.header and chapter.header ~= "" then
        heading =
            heading .. string.format("<h3>%s</h3>", chapter.header) .. HTMLBuilder.CreateDecorativeDivider("section")
    end

    return heading
end

--[[
    The front matter's metadata line: year, event type and collection, joined by a separator.

    Parts that are absent are dropped rather than rendered empty, so a character (no year, no event
    type) gets its collection alone and nothing ever renders a bare separator.

    @param entity [table] Entity data
    @return [string] Paragraph HTML, empty string when the entity carries none of the three
]]
local function BuildMetadataLine(entity)
    local parts = {}

    local dateText = HTMLBuilder.GetDateRangeText(entity.yearStart, entity.yearEnd)
    if dateText ~= "" then
        table.insert(parts, dateText)
    end

    local eventTypes = private.constants and private.constants.eventType
    local eventTypeKey = eventTypes and entity.eventType and eventTypes[entity.eventType]
    -- "undefined" is the zero value of the enum, not a type a reader wants to be told about
    if eventTypeKey and eventTypeKey ~= "undefined" then
        table.insert(parts, Locale[eventTypeKey] or eventTypeKey)
    end

    if entity.source and entity.source ~= "" then
        table.insert(parts, Locale[entity.source] or entity.source)
    end

    if #parts == 0 then
        return ""
    end

    local separator = Locale["BOOK_FRONT_META_SEPARATOR"] or " . "
    return HTMLBuilder.CreateParagraph(table.concat(parts, separator), {align = "center"})
end

--[[
    One cross-reference block: a sub-head and a single paragraph of resolved names.

    Returns an empty string when nothing resolved, which is what keeps an event with no factions from
    showing a FACTIONS heading over blank space. That is the common case in the current data: roughly
    two events in five carry either kind of reference.

    @param refs [table|nil] The entity's raw reference table, either shape
    @param kind [string] "character" or "faction"
    @param fallbackCollection [string|nil] Collection for the flat shape, normally entity.source
    @param headingKey [string] Locale key for the sub-head
    @return [string] HTML block, possibly empty
]]
local function BuildReferenceBlock(refs, kind, fallbackCollection, headingKey)
    local FrontMatter = private.Core.Utils.FrontMatter
    if not FrontMatter or not FrontMatter.ResolveNames then
        return ""
    end

    local names, omitted = FrontMatter.ResolveNames(refs, kind, fallbackCollection)
    if not names then
        return ""
    end

    local separator = Locale["BOOK_FRONT_META_SEPARATOR"] or " . "
    local line = table.concat(names, separator)

    if omitted and omitted > 0 then
        local moreFmt = Locale["BOOK_FRONT_MORE"] or "+ %d more"
        line = line .. separator .. string.format(moreFmt, omitted)
    end

    return HTMLBuilder.CreateSubtitle(Locale[headingKey] or headingKey) .. HTMLBuilder.CreateParagraph(line)
end

--[[
    Create a list of HTML documents for any entity type (event, character, faction)
    This is the main function called by ContentUtils.TransformEntityToBook
    @param entity [table] Entity data with properties like name, description, chapters, etc.
    @return [table] Table with 'documents' array and 'navigationData' for BookContainerTemplate
]]
function HTMLBuilder.CreateEntityHTML(entity)
    if not entity then
        local errorTitle = Locale["BOOK_ERROR_TITLE"] or "Error"
        local errorMsg = Locale["BOOK_ERROR_NO_ENTITY"] or "No entity data provided"
        return {
            documents = {
                HTMLBuilder.CreateHTMLDocument(
                    HTMLBuilder.CreateTitle(errorTitle) .. HTMLBuilder.CreateParagraph(errorMsg)
                )
            },
            navigationData = {}
        }
    end

    local htmlDocuments = {}

    -- Create navigation data structure first
    local navigationData = HTMLBuilder.CreateChapterNavigationData(entity)

    -- Front matter, the left half of the spread. It carries who and when, so the right half can be
    -- nothing but prose: portrait, title, metadata line, rule, the resolved cross-reference lists, and
    -- the contents list appended further down.
    local coverContent = ""
    local title = entity.name or entity.label or (Locale["BOOK_UNTITLED"] or "Untitled")

    -- Portrait first so it seats at the top. No record in the DB carries an image field yet and the art
    -- directory holds one portrait, so this is a slot waiting for data, not a feature: absent image,
    -- absent slot. There is deliberately no fallback to a collection crest, because there are no crests.
    if entity.image and entity.image ~= "" then
        coverContent = coverContent .. HTMLBuilder.CreatePortrait(entity.image)
    end

    -- The rule goes under the metadata rather than under the title, so title and metadata read as one
    -- block of identity and the rule separates it from the reference lists.
    coverContent = coverContent .. HTMLBuilder.CreateTitle(title, {divider = false})
    coverContent = coverContent .. BuildMetadataLine(entity)
    coverContent = coverContent .. HTMLBuilder.CreateDecorativeDivider()

    -- Add author if present
    if entity.author and entity.author ~= "" then
        coverContent = coverContent .. HTMLBuilder.CreateAuthor(entity.author)
    end

    -- Cross-references, resolved from ids to names. Events key them by collection; a character's
    -- factions are a flat id array whose collection is the character's own source.
    coverContent = coverContent .. BuildReferenceBlock(entity.factions, "faction", entity.source, "BOOK_FRONT_FACTIONS")
    coverContent =
        coverContent .. BuildReferenceBlock(entity.characters, "character", entity.source, "BOOK_FRONT_CHARACTERS")

    -- Add description if present
    if entity.description and entity.description ~= "" then
        -- If it's a full HTML document, extract inner content so it renders on the cover page
        if StringUtils.ContainsHTML(entity.description) then
            coverContent = coverContent .. ExtractInnerHTML(entity.description)
        elseif string.find(entity.description, "<[^>]+>") then
            -- Description contains some HTML tags, append as-is
            coverContent = coverContent .. entity.description
        else
            -- Plain text description, wrap in paragraph
            coverContent = coverContent .. HTMLBuilder.CreateParagraph(entity.description)
        end
    end

    -- Contents, on the front matter rather than on a page of its own. Hidden at one chapter because a
    -- single-chapter entity has nothing to navigate to; this is a #chapters test, so an entity that
    -- gains a second chapter gets a contents list with no further work.
    if entity.chapters and #entity.chapters > 1 then
        coverContent = coverContent .. HTMLBuilder.CreateTableOfContents(entity, navigationData)
    end

    -- Add cover page as first document (if it has content)
    if coverContent ~= "" then
        table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(coverContent))
    end

    -- Add chapters as documents: one per authored page, in authored order.
    --
    -- There is deliberately one list. The previous shape kept a second, per-chapter side-list holding
    -- only the full-HTML pages and appended it after the chapter's concatenated text, so a chapter
    -- mixing plain and HTML pages rendered out of the order it was written in. With every page a
    -- document there is nothing to reorder.
    if entity.chapters and type(entity.chapters) == "table" then
        for i, chapter in ipairs(entity.chapters) do
            local heading = BuildChapterHeading(navigationData.chapters[i], chapter)
            local pages = (type(chapter.pages) == "table" and #chapter.pages > 0) and chapter.pages or nil

            if pages then
                for pageIndex, page in ipairs(pages) do
                    local content = RenderPageBody(page)
                    if pageIndex == 1 then
                        content = heading .. content
                    end

                    -- Emitted unconditionally, including for an empty page. The count must equal
                    -- GetChapterPageCount(chapter) or every later chapter's contents link points at
                    -- the wrong page; an authored empty page showing as a blank page is the honest
                    -- rendering of the record, and silently renumbering the book is not.
                    table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(content))
                end
            else
                -- Single chapter.content field, the documented alternative to a pages array. It stays
                -- one page: it is one field, so there is nothing in it to break pages on.
                table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(heading .. RenderPageBody(chapter.content)))
            end
        end
    end

    -- If no documents were generated, create a minimal message
    if #htmlDocuments == 0 then
        local fallbackText = Locale["BOOK_NO_CONTENT"] or "No content available."
        local fallbackContent = HTMLBuilder.CreateParagraph(fallbackText, { align = "center" })
        table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(fallbackContent))
    end

    -- Return both documents and navigation data
    return {
        documents = htmlDocuments,
        navigationData = navigationData
    }
end

