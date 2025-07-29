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

-- Portrait settings for WoW image display
local PORTRAIT_SETTINGS = {
    width = "140",
    height = "140",
    align = "right"
}

-- HTML entities for SimpleHTML
local HTML_ENTITIES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;"
}

-- Extended HTML entities from LibMarkdown for spacing
local EXTENDED_ENTITIES = {
    ["&nbsp;"] = "&nbsp;", -- Non-breaking space
    ["&emsp;"] = "&emsp;", -- Font-size space
    ["&ensp;"] = "&ensp;", -- Half font-size space
    ["&em13;"] = "&em13;", -- 1/3 font-size space
    ["&em14;"] = "&em14;", -- 1/4 font-size space
    ["&thinsp;"] = "&thinsp;" -- 1/5 font-size space (non-breaking)
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
    @return [string] HTML title element
]]
function HTMLBuilder.CreateTitle(title)
    if not title or title == "" then
        return ""
    end

    --local coloredTitle = ApplyWoWColor(safeTitle, WOW_COLORS.title)

    local divider = HTMLBuilder.CreateDecorativeDivider()

    return string.format('<h1 align="center">%s</h1>%s', title, divider)
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

    return string.format("<h2>%s</h2>", subtitle)
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

    return string.format('<p align="right">%s</p>', author)
end

--[[
    Create a date range block for events
    Uses <p> with align="center" which is supported by SimpleHTML
    @param yearStart [number] Start year
    @param yearEnd [number] End year
    @return [string] HTML date range element
]]
function HTMLBuilder.CreateDateRange(yearStart, yearEnd)
    if not yearStart and not yearEnd then
        return ""
    end

    local dateText = ""
    if yearStart and yearEnd then
        if yearStart == yearEnd then
            dateText = string.format("Year %d", yearStart)
        else
            dateText = string.format("Years %d - %d", yearStart, yearEnd)
        end
    elseif yearStart then
        dateText = string.format("From Year %d", yearStart)
    elseif yearEnd then
        dateText = string.format("Until Year %d", yearEnd)
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
    @param options [table] Optional styling (align: left, center, right)
    @return [string] HTML paragraph element
]]
function HTMLBuilder.CreateParagraph(text, options)
    if not text or text == "" then
        return ""
    end

    options = options or {}
    if options.align then
        return string.format('<p align="%s">%s</p>', options.align, text)
    else
        return string.format("<p>%s</p>", text)
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

    local href = linkType .. ":" .. tostring(linkData)

    return string.format('<a href="%s">%s</a>', href, text)
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

    local navigationContent = table.concat(linkElements, separator)
    return HTMLBuilder.CreateParagraph(navigationContent, {align = "center"})
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
            (dividerPath .. "ChapterDivider")
        )
    elseif dividerType == "section" then
        return string.format(
            '<img src="%s" width="128" height="16" align="center"/>',
            (dividerPath .. "SectionDivider")
        )
    else
        return string.format('<img src="%s" width="450" height="25" align="center"/>', (dividerPath .. "Divider"))
    end
end

--[[
    Create a table of contents with clickable navigation links
    @param entity [table] Entity with chapters
    @param navigationData [table] Navigation data with page mapping
    @return [string] HTML table of contents
]]
function HTMLBuilder.CreateTableOfContents(entity, navigationData)
    if not entity or not entity.chapters then
        return ""
    end

    local tocContent = HTMLBuilder.CreateSubtitle("Contents")

    for i, chapter in ipairs(entity.chapters) do
        local chapterTitle = chapter.header or ("Chapter " .. i)
        local chapterNumber = string.format("Chapter %d", i)

        -- Create clickable link to navigate to the chapter
        local chapterLink = HTMLBuilder.CreateLink(chapterTitle, "chapter", chapter.id or ("chapter_" .. i))

        -- Format: "Chapter 1: Chapter Title"
        local tocEntry = string.format("%s: %s", chapterNumber, chapterLink)
        tocContent = tocContent .. HTMLBuilder.CreateParagraph(tocEntry, {align = "left"})
    end

    return tocContent
end

--[[
    Create chapter navigation data structure
    @param entity [table] Entity with chapters
    @return [table] Navigation data with chapter mappings
]]
function HTMLBuilder.CreateChapterNavigationData(entity)
    if not entity or not entity.chapters then
        return {}
    end

    local navigationData = {
        chapters = {},
        pageMapping = {}, -- Maps chapter ID to page index in htmlDocuments
        chapterLookup = {} -- Maps chapter ID to chapter data
    }

    local currentPageIndex = 1

    -- Cover page (page 1)
    navigationData.pageMapping["cover"] = currentPageIndex
    currentPageIndex = currentPageIndex + 1

    -- TOC page (only if entity has more than 1 chapter)
    if entity.chapters and #entity.chapters > 1 then
        navigationData.pageMapping["toc"] = currentPageIndex
        currentPageIndex = currentPageIndex + 1
    end

    -- Chapter pages
    for i, chapter in ipairs(entity.chapters) do
        local chapterId = chapter.id or ("chapter_" .. i)

        navigationData.chapters[i] = {
            id = chapterId,
            title = chapter.header or ("Chapter " .. i),
            startPage = currentPageIndex,
            index = i
        }

        navigationData.pageMapping[chapterId] = currentPageIndex
        navigationData.chapterLookup[chapterId] = navigationData.chapters[i]

        -- Account for multiple pages per chapter if needed
        local pagesInChapter = chapter.pageCount or 1
        currentPageIndex = currentPageIndex + pagesInChapter
    end

    return navigationData
end

--[[
    Create page header with chapter information
    @param chapter [table] Chapter data
    @param navigationData [table] Navigation data
    @return [string] HTML page header
]]
function HTMLBuilder.CreatePageHeader(chapter, navigationData)
    if not chapter then
        return ""
    end

    local headerContent =
        HTMLBuilder.CreateParagraph(string.format("Chapter %d: %s", chapter.index, chapter.title), {align = "center"})

    return headerContent .. HTMLBuilder.CreateDivider()
end

--[[
    HYPERLINK USAGE EXAMPLE:
    
    To use hyperlinks in Chronicles, you need to set up a hyperlink handler on your SimpleHTML frame:
    
    -- Enable hyperlinks on your frame
    frame:SetHyperlinksEnabled(true)
    
    -- Set up the hyperlink click handler
    frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        local linkType, linkData = link:match("([^:]+):(.+)")
        
        if linkType == "chapter" then
            -- Navigate to specific chapter using BookContainerTemplate
            if self.BookContainer then
                self.BookContainer:NavigateToChapter(linkData)
                PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
            end
        elseif linkType == "toc" then
            -- Navigate to table of contents
            if self.BookContainer then
                self.BookContainer:NavigateToChapter("toc")
            end
        elseif linkType == "cover" then
            -- Navigate to cover page
            if self.BookContainer then
                self.BookContainer:NavigateToChapter("cover")
            end
        elseif linkType == "event" then
            local eventId = tonumber(linkData)
            if eventId and private.Core.StateManager then
                private.Core.StateManager.setState("selection.event", eventId, "Hyperlink navigation")
            end
        elseif linkType == "character" then
            if private.Core.StateManager then
                private.Core.StateManager.setState("selection.character", linkData, "Hyperlink navigation")
            end
        elseif linkType == "faction" then
            if private.Core.StateManager then
                private.Core.StateManager.setState("selection.faction", linkData, "Hyperlink navigation")
            end
        elseif linkType == "external" then
            -- Copy external URLs to clipboard (WoW can't open external browsers)
            if linkData and linkData ~= "" then
                -- Note: You'd need to implement clipboard functionality
                print("External link: " .. linkData)
            end
        end
    end)
    
    -- INTEGRATION WITH BOOKCONTAINERTEMPLATE:
    
    -- In BookContainerMixin or related module, add these functions:
    function BookContainerMixin:SetupChapterNavigation(navigationData)
        self.chapterNavigationData = navigationData
        if self.PagedDetails then
            self.PagedDetails.chapterNavigationData = navigationData
        end
    end

    function BookContainerMixin:NavigateToChapter(chapterId)
        if not self.chapterNavigationData then return false end
        
        local pageIndex = self.chapterNavigationData.pageMapping[chapterId]
        if pageIndex then
            if self.PagedDetails and self.PagedDetails.PagingControls then
                self.PagedDetails.PagingControls:SetCurrentPage(pageIndex)
                return true
            end
        end
        return false
    end
    
    -- Example usage in HTML generation:
    local bookData = HTMLBuilder.CreateEntityHTML(entity)
    
    -- Set up the book container with navigation
    if self.BookContainer then
        self.BookContainer:SetupChapterNavigation(bookData.navigationData)
        self.BookContainer.PagedDetails:SetContent(bookData.documents)
        
        -- Enable hyperlinks on view frames
        for _, viewFrame in ipairs(self.BookContainer.PagedDetails.ViewFrames) do
            if viewFrame.ScrollFrame and viewFrame.ScrollFrame.Child then
                viewFrame.ScrollFrame.Child:SetHyperlinksEnabled(true)
            end
        end
    end
--]]
-- =============================================================================================
-- NAVIGATION UTILITY FUNCTIONS
-- =============================================================================================

-- --[[
--     Create back to table of contents link
--     @return [string] HTML link to TOC
-- ]]
-- function HTMLBuilder.CreateBackToTOCLink()
--     return HTMLBuilder.CreateLink("← Back to Contents", "toc", "main")
-- end

-- --[[
--     Create back to cover page link
--     @return [string] HTML link to cover
-- ]]
-- function HTMLBuilder.CreateBackToCoverLink()
--     return HTMLBuilder.CreateLink("← Back to Cover", "cover", "main")
-- end

-- =============================================================================================
-- ENTITY CONTENT GENERATION
-- =============================================================================================

--[[
    Create a list of HTML documents for any entity type (event, character, faction)
    This is the main function called by ContentUtils.TransformEntityToBook
    @param entity [table] Entity data with properties like name, description, chapters, etc.
    @param options [table] Optional styling and layout options
    @return [table] Table with 'documents' array and 'navigationData' for BookContainerTemplate
]]
function HTMLBuilder.CreateEntityHTML(entity, options)
    if not entity then
        return {
            documents = {
                HTMLBuilder.CreateHTMLDocument(
                    HTMLBuilder.CreateTitle("Error") .. HTMLBuilder.CreateParagraph("No entity data provided")
                )
            },
            navigationData = {}
        }
    end

    options = options or {}
    local htmlDocuments = {}

    -- Create navigation data structure first
    local navigationData = HTMLBuilder.CreateChapterNavigationData(entity)

    -- Create main/cover page with title, description and portrait
    local coverContent = ""
    local title = entity.name or entity.label or "Untitled"

    coverContent = coverContent .. HTMLBuilder.CreateTitle(title)

    -- Add date range for events
    if entity.yearStart or entity.yearEnd then
        coverContent = coverContent .. HTMLBuilder.CreateDateRange(entity.yearStart, entity.yearEnd)
    end

    -- Add author if present
    if entity.author and entity.author ~= "" then
        coverContent = coverContent .. HTMLBuilder.CreateAuthor(entity.author)
    end

    -- Add portrait/image if present
    if entity.image and entity.image ~= "" then
        coverContent = coverContent .. HTMLBuilder.CreatePortrait(entity.image)
    end

    -- Add description if present
    if entity.description and entity.description ~= "" then
        -- Check if description is a complete HTML document using StringUtils
        if StringUtils.ContainsHTML(entity.description) then
            -- Description is a complete HTML document, add it as separate document
            table.insert(htmlDocuments, entity.description)
        elseif string.find(entity.description, "<[^>]+>") then
            -- Description contains HTML tags but isn't a complete document, use it directly
            coverContent = coverContent .. entity.description
        else
            -- Plain text description, wrap in paragraph
            coverContent = coverContent .. HTMLBuilder.CreateParagraph(entity.description)
        end
    end

    -- Add cover page as first document (if it has content)
    if coverContent ~= "" then
        table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(coverContent))
    end

    -- Create table of contents page (only create if entity has more than 1 chapter)
    if entity.chapters and #entity.chapters > 1 then
        local tocContent = HTMLBuilder.CreateTableOfContents(entity, navigationData)
        local toc = HTMLBuilder.CreateHTMLDocument(tocContent)
        table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(toc))

        print("Creating Table of Contents", toc)
    end

    -- Add chapters as separate documents if present
    if entity.chapters and type(entity.chapters) == "table" then
        for i, chapter in ipairs(entity.chapters) do
            local chapterData = navigationData.chapters[i]
            local chapterContent = ""
            local chapterDocuments = {}

            -- Create chapter header with navigation
            if chapterData then
                chapterContent = chapterContent .. HTMLBuilder.CreatePageHeader(chapterData, navigationData)
            end

            if chapter.header then
                chapterContent =
                    chapterContent ..
                    string.format("<h3>%s</h3>", chapter.header) .. HTMLBuilder.CreateDecorativeDivider("section") --"chapter"
            end

            if chapter.pages and type(chapter.pages) == "table" then
                for _, page in ipairs(chapter.pages) do
                    if page and page ~= "" then
                        -- Check if page content is a complete HTML document using StringUtils
                        if StringUtils.ContainsHTML(page) then
                            -- Page is a complete HTML document, add to chapter documents
                            table.insert(chapterDocuments, page)
                        elseif string.find(page, "<[^>]+>") then
                            -- Page contains HTML tags but isn't a complete document
                            chapterContent = chapterContent .. page
                        else
                            chapterContent = chapterContent .. HTMLBuilder.CreateParagraph(page)
                        end
                    end
                end
            end

            -- -- Add navigation footer if we have chapter data
            -- if chapterData then
            --     local navigation = HTMLBuilder.CreateChapterNavigationBar(chapterData, navigationData)
            --     chapterContent = chapterContent .. HTMLBuilder.CreateDivider() .. navigation
            -- end

            print(HTMLBuilder.CreateDecorativeDivider())

            -- Add chapter content as a document if it has content
            if chapterContent ~= "" then
                table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(chapterContent))
            end

            -- Add any complete HTML page documents for this chapter in order
            for _, pageDoc in ipairs(chapterDocuments) do
                table.insert(htmlDocuments, pageDoc)
            end
        end
    end

    -- If no documents were generated, create a minimal message
    if #htmlDocuments == 0 then
        local fallbackContent =
            HTMLBuilder.CreateTitle(title) ..
            HTMLBuilder.CreateParagraph(
                "No content available for this " ..
                    (entity.eventType and "event" or entity.factions and "character" or "faction") .. "."
            )
        table.insert(htmlDocuments, HTMLBuilder.CreateHTMLDocument(fallbackContent))
    end

    -- Return both documents and navigation data
    return {
        documents = htmlDocuments,
        navigationData = navigationData
    }
end

-- --[[
--     Create an enhanced cover page with better formatting
--     @param entity [table] Entity data
--     @return [string] Complete HTML document for cover page
-- ]]
-- function HTMLBuilder.CreateEnhancedCoverPage(entity)
--     local coverContent = ""

--     -- Add title with fancy formatting
--     local title = entity.name or entity.label or "Untitled"
--     coverContent = coverContent .. HTMLBuilder.CreateTitle(title)

--     -- Add image centered if it's a cover image
--     if entity.coverImage then
--         coverContent =
--             coverContent ..
--             HTMLBuilder.CreatePortrait(entity.coverImage, {width = "300", height = "300", align = "center"})
--     elseif entity.image then
--         coverContent = coverContent .. HTMLBuilder.CreatePortrait(entity.image)
--     end

--     -- Add author with special formatting
--     if entity.author then
--         coverContent = coverContent .. HTMLBuilder.CreateAuthor(WOW_COLORS.author .. entity.author .. WOW_COLORS.reset)
--     end

--     -- Add short summary/preview if available
--     if entity.summary then
--         coverContent = coverContent .. HTMLBuilder.CreateParagraph(entity.summary, {align = "center"})
--     end

--     -- Add date range for events on cover page
--     if entity.yearStart or entity.yearEnd then
--         coverContent = coverContent .. HTMLBuilder.CreateDateRange(entity.yearStart, entity.yearEnd)
--     end

--     return HTMLBuilder.CreateHTMLDocument(coverContent)
-- end

-- =============================================================================================
-- VALIDATION AND DEBUG FUNCTIONS
-- =============================================================================================

-- --[[
--     Validate that an HTML string is compatible with SimpleHTML
--     @param htmlString [string] HTML content to validate
--     @return [boolean, string] isValid, errorMessage
-- ]]
-- function HTMLBuilder.ValidateSimpleHTML(htmlString)
--     if not htmlString or htmlString == "" then
--         return false, "Empty HTML content"
--     end

--     -- Check for unsupported tags
--     local unsupportedTags = {"<div", "<span", "<style", "<script", "<ul", "<ol", "<li", "<table"}
--     for _, tag in ipairs(unsupportedTags) do
--         if string.find(htmlString:lower(), tag) then
--             return false, "Unsupported HTML tag found: " .. tag
--         end
--     end

--     -- Check for required structure
--     if not string.find(htmlString, "<html>") or not string.find(htmlString, "<body>") then
--         return false, "Missing required <html> or <body> tags"
--     end

--     return true, "Valid SimpleHTML"
-- end
