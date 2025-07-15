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
    title = "|cFFffd100",
    subtitle = "|cFFd4af37", 
    text = "|cFFffffff",
    author = "|cFFcccccc",
    date = "|cFFffd100",
    chapter = "|cFFe6b800",
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
    ["&nbsp;"] = "&nbsp;",    -- Non-breaking space
    ["&emsp;"] = "&emsp;",    -- Font-size space
    ["&ensp;"] = "&ensp;",    -- Half font-size space
    ["&em13;"] = "&em13;",    -- 1/3 font-size space
    ["&em14;"] = "&em14;",    -- 1/4 font-size space
    ["&thinsp;"] = "&thinsp;" -- 1/5 font-size space (non-breaking)
}

-- =============================================================================================
-- UTILITY FUNCTIONS
-- =============================================================================================

local function EscapeHTMLText(text)
    if not text then return "" end
    text = tostring(text)
    for char, entity in pairs(HTML_ENTITIES) do
        text = text:gsub(char, entity)
    end
    return text
end

local function ApplyWoWColor(text, colorCode)
    if not text or text == "" then return "" end
    if not colorCode then return text end
    
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
    if not content then content = "" end
    
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

    local safeTitle = EscapeHTMLText(title)
    local coloredTitle = ApplyWoWColor(safeTitle, WOW_COLORS.title)
    return string.format("<h1>%s</h1>", coloredTitle)
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

    local safeSubtitle = EscapeHTMLText(subtitle)
    local coloredSubtitle = ApplyWoWColor(safeSubtitle, WOW_COLORS.subtitle)
    return string.format("<h2>%s</h2>", coloredSubtitle)
end

--[[
    Create a chapter header block with WoW color codes
    Uses <h3> which is supported by SimpleHTML
    @param header [string] Chapter header text
    @return [string] HTML chapter header element
]]
function HTMLBuilder.CreateChapterHeader(header)
    if not header or header == "" then
        return ""
    end

    local safeHeader = EscapeHTMLText(header)
    local coloredHeader = ApplyWoWColor(safeHeader, WOW_COLORS.chapter)
    return string.format("<h3>%s</h3>", coloredHeader)
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

    local safeAuthor = EscapeHTMLText(author)
    local coloredAuthor = ApplyWoWColor(safeAuthor, WOW_COLORS.author)
    return string.format('<p align="right">%s</p>', coloredAuthor)
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

    local safeDateText = EscapeHTMLText(dateText)
    local coloredDate = ApplyWoWColor(safeDateText, WOW_COLORS.date)
    return string.format('<p align="center">%s</p>', coloredDate)
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

    -- Ensure path is properly escaped for HTML
    local safePath = EscapeHTMLText(portraitPath)
    
    return string.format('<img src="%s" width="%s" height="%s" align="%s"/>', safePath, width, height, align)
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
    local safeText = EscapeHTMLText(text)
    
    if options.align then
        return string.format('<p align="%s">%s</p>', options.align, safeText)
    else
        return string.format("<p>%s</p>", safeText)
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
    Create a hyperlink element (basic support in SimpleHTML)
    Uses <a> with href attribute - supported by SimpleHTML but requires frame handler
    @param text [string] Link text
    @param url [string] Link URL or reference
    @return [string] HTML link element
]]
function HTMLBuilder.CreateLink(text, url)
    if not text or text == "" or not url or url == "" then
        return EscapeHTMLText(text or "")
    end

    local safeText = EscapeHTMLText(text)
    local safeUrl = EscapeHTMLText(url)
    
    return string.format('<a href="%s">%s</a>', safeUrl, safeText)
end

--[[
    Create a hyperlink element for Chronicles navigation
    Uses <a> with href attribute - supported by SimpleHTML but requires frame handler
    @param text [string] Link text to display
    @param linkType [string] Type of link (event, character, faction, external)
    @param linkData [string|number] Link data (ID, name, or URL)
    @return [string] HTML link element
]]
function HTMLBuilder.CreateChroniclesLink(text, linkType, linkData)
    if not text or text == "" or not linkType or not linkData then
        return EscapeHTMLText(text or "")
    end

    local safeText = EscapeHTMLText(text)
    local safeLinkData = EscapeHTMLText(tostring(linkData))
    local href = linkType .. ":" .. safeLinkData
    
    return string.format('<a href="%s">%s</a>', href, safeText)
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
            table.insert(linkElements, HTMLBuilder.CreateChroniclesLink(link.text, link.linkType, link.linkData))
        end
    end

    if #linkElements == 0 then
        return ""
    end

    local navigationContent = table.concat(linkElements, separator)
    return HTMLBuilder.CreateParagraph(navigationContent, {align = "center"})
end

--[[
    HYPERLINK USAGE EXAMPLE:
    
    To use hyperlinks in Chronicles, you need to set up a hyperlink handler on your SimpleHTML frame:
    
    -- Enable hyperlinks on your frame
    frame:SetHyperlinksEnabled(true)
    
    -- Set up the hyperlink click handler
    frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        local linkType, linkData = link:match("([^:]+):(.+)
        
        if linkType == "event" then
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
    
    -- Example usage in HTML generation:
    local navigationLinks = {
        {text = "View Timeline", linkType = "timeline", linkData = "main"},
        {text = "Browse Events", linkType = "tab", linkData = "events"},
        {text = "Character List", linkType = "tab", linkData = "characters"}
    }
    
    local html = HTMLBuilder.CreateHTMLDocument(
        HTMLBuilder.CreateTitle("Welcome to Chronicles") ..
        HTMLBuilder.CreateParagraph("Explore the world of Azeroth through interactive timelines.") ..
        HTMLBuilder.CreateNavigationLinks(navigationLinks) ..
        HTMLBuilder.CreateParagraph("Click " .. HTMLBuilder.CreateChroniclesLink("here", "event", 123) .. " to view the First War.")
    )
--]]

-- =============================================================================================
-- ENTITY CONTENT GENERATION
-- =============================================================================================

--[[
    Create complete HTML content for any entity type (event, character, faction)
    This is the main function called by ContentUtils.TransformEntityToBook
    @param entity [table] Entity data with properties like name, description, chapters, etc.
    @param options [table] Optional styling and layout options
    @return [string] Complete HTML document for the entity
]]
function HTMLBuilder.CreateEntityHTML(entity, options)
    if not entity then
        return HTMLBuilder.CreateHTMLDocument(
            HTMLBuilder.CreateTitle("Error") ..
            HTMLBuilder.CreateParagraph("No entity data provided")
        )
    end

    options = options or {}
    local content = ""

    -- Add title (entity name)
    local title = entity.name or entity.label or "Untitled"
    content = content .. HTMLBuilder.CreateTitle(title)

    -- Add date range for events
    if entity.yearStart or entity.yearEnd then
        content = content .. HTMLBuilder.CreateDateRange(entity.yearStart, entity.yearEnd)
    end

    -- Add author if present
    if entity.author and entity.author ~= "" then
        content = content .. HTMLBuilder.CreateAuthor(entity.author)
    end

    -- Add portrait/image if present
    if entity.image and entity.image ~= "" then
        content = content .. HTMLBuilder.CreatePortrait(entity.image)
    end

    -- Add description if present
    if entity.description and entity.description ~= "" then
        -- Check if description is a complete HTML document using StringUtils
        if StringUtils.ContainsHTML(entity.description) then
            -- Description is a complete HTML document, return it directly
            return entity.description
        elseif string.find(entity.description, "<[^>]+>") then
            -- Description contains HTML tags but isn't a complete document, use it directly
            content = content .. entity.description
        else
            -- Plain text description, wrap in paragraph
            content = content .. HTMLBuilder.CreateParagraph(entity.description)
        end
        content = content .. HTMLBuilder.CreateDivider()
    end

    -- Add chapters if present
    if entity.chapters and type(entity.chapters) == "table" then
        for _, chapter in ipairs(entity.chapters) do
            if chapter.header then
                content = content .. HTMLBuilder.CreateChapterHeader(chapter.header)
            end
            
            if chapter.pages and type(chapter.pages) == "table" then
                for _, page in ipairs(chapter.pages) do
                    if page and page ~= "" then
                        -- Check if page content is a complete HTML document using StringUtils
                        if StringUtils.ContainsHTML(page) then
                            -- Page is a complete HTML document, return it directly
                            return page
                        elseif string.find(page, "<[^>]+>") then
                            -- Page contains HTML tags but isn't a complete document
                            content = content .. page
                        else
                            content = content .. HTMLBuilder.CreateParagraph(page)
                        end
                    end
                end
            end
            
            content = content .. HTMLBuilder.CreateDivider()
        end
    end

    -- If no content was generated, create a minimal message
    if content == "" or content == HTMLBuilder.CreateTitle(title) then
        content = content .. HTMLBuilder.CreateParagraph("No content available for this " .. (entity.eventType and "event" or entity.factions and "character" or "faction") .. ".")
    end

    return HTMLBuilder.CreateHTMLDocument(content)
end

--[[
    Create a test HTML document for debugging
    @return [string] Test HTML document
]]
function HTMLBuilder.CreateTestHTML()
    local content = HTMLBuilder.CreateTitle("Test Content") ..
                   HTMLBuilder.CreateSubtitle("This is a test") ..
                   HTMLBuilder.CreateParagraph("This is a simple test paragraph to verify HTML display is working.") ..
                   HTMLBuilder.CreateDivider() ..
                   HTMLBuilder.CreateChapterHeader("Test Chapter") ..
                   HTMLBuilder.CreateParagraph("Chapter content goes here.") ..
                   HTMLBuilder.CreateAuthor("Chronicles Team")
    
    return HTMLBuilder.CreateHTMLDocument(content)
end

-- =============================================================================================
-- VALIDATION AND DEBUG FUNCTIONS
-- =============================================================================================

--[[
    Validate that an HTML string is compatible with SimpleHTML
    @param htmlString [string] HTML content to validate
    @return [boolean, string] isValid, errorMessage
]]
function HTMLBuilder.ValidateSimpleHTML(htmlString)
    if not htmlString or htmlString == "" then
        return false, "Empty HTML content"
    end

    -- Check for unsupported tags
    local unsupportedTags = {"<div", "<span", "<style", "<script", "<ul", "<ol", "<li", "<table"}
    for _, tag in ipairs(unsupportedTags) do
        if string.find(htmlString, tag) then
            return false, "Unsupported HTML tag found: " .. tag
        end
    end

    -- Check for required structure
    if not string.find(htmlString, "<html>") or not string.find(htmlString, "<body>") then
        return false, "Missing required <html> or <body> tags"
    end

    return true, "Valid SimpleHTML"
end
