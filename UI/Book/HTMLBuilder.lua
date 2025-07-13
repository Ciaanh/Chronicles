--[[
    HTMLBuilder.lua
    
    Dedicated HTML content generation utilities for the Chronicles addon.
    Provides consistent styling and structured HTML creation for book content.
]]

local FOLDER_NAME, private = ...

-- Import dependencies
local StringUtils = private.Core.Utils.StringUtils

-- Initialize HTMLBuilder namespace
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.HTMLBuilder = {}
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- =============================================================================================
-- HTML STYLING CONSTANTS
-- =============================================================================================

local STYLES = {
    colors = {
        title = "#ffd100",
        subtitle = "#ffd100", 
        text = "#ffffff",
        author = "#aaaaaa",
        date = "#ffd100"
    },
    fonts = {
        title = "18px",
        subtitle = "16px", 
        text = "14px",
        author = "12px"
    },
    spacing = {
        titleMargin = "10px",
        sectionMargin = "20px",
        paragraphMargin = "10px",
        portraitMargin = "0 0 15px 15px"
    },
    portrait = {
        width = "120",
        height = "120",
        align = "right"
    }
}

-- =============================================================================================
-- CORE HTML STRUCTURE BUILDERS
-- =============================================================================================

--[[
    Create a complete HTML document wrapper
    @param content [string] Body content
    @return [string] Complete HTML document
]]
function HTMLBuilder.CreateDocument(content)
    return string.format("<html><body>%s</body></html>", content or "")
end

--[[
    Create a portrait image element
    @param portraitPath [string] Path to portrait image
    @param options [table] Optional styling overrides
    @return [string] HTML img element
]]
function HTMLBuilder.CreatePortrait(portraitPath, options)
    if not portraitPath or portraitPath == "" then
        return ""
    end
    
    options = options or {}
    local width = options.width or STYLES.portrait.width
    local height = options.height or STYLES.portrait.height
    local align = options.align or STYLES.portrait.align
    local margin = options.margin or STYLES.spacing.portraitMargin
    
    return string.format(
        '<img src="%s" width="%s" height="%s" align="%s" style="margin: %s;" />',
        portraitPath, width, height, align, margin
    )
end

--[[
    Create a paragraph element
    @param text [string] Paragraph text
    @param options [table] Optional styling overrides
    @return [string] HTML paragraph element
]]
function HTMLBuilder.CreateParagraph(text, options)
    if not text or text == "" then
        return ""
    end
    
    options = options or {}
    local margin = options.margin or STYLES.spacing.paragraphMargin
    local align = options.align or "justify"
    
    return string.format(
        '<p style="margin-bottom: %s; text-align: %s;">%s</p>',
        margin, align, text
    )
end

-- =============================================================================================
-- SPECIALIZED CONTENT BUILDERS
-- =============================================================================================

--[[
    Create HTML for a main title (character/faction/event name)
    @param text [string] Title text
    @param options [table] Optional styling and content options
    @return [string] HTML for the title section
]]
function HTMLBuilder.CreateTitle(text, options)
    if not text or text == "" then
        return ""
    end
    
    options = options or {}
    local color = options.color or STYLES.colors.title
    local fontSize = options.fontSize or STYLES.fonts.title
    local margin = options.margin or STYLES.spacing.titleMargin
    local align = options.align or "center"
    
    return string.format(
        '<h1 style="color: %s; font-size: %s; text-align: %s; margin-bottom: %s;">%s</h1>',
        color, fontSize, align, margin, text
    )
end

--[[
    Create HTML for an event title with date range
    @param text [string] Event title
    @param yearStart [number] Start year (optional)
    @param yearEnd [number] End year (optional)
    @param options [table] Optional styling overrides
    @return [string] HTML for the event title section
]]
function HTMLBuilder.CreateEventTitle(text, yearStart, yearEnd, options)
    local content = {}
    
    -- Main title
    if text and text ~= "" then
        table.insert(content, HTMLBuilder.CreateTitle(text, options))
    end
    
    -- Date range
    local dateStr = HTMLBuilder.CreateDateRange(yearStart, yearEnd)
    if dateStr ~= "" then
        table.insert(content, string.format(
            '<div style="text-align: center; margin-bottom: %s;">%s</div>',
            STYLES.spacing.titleMargin, dateStr
        ))
    end
    
    return table.concat(content, "\n")
end

--[[
    Create HTML for a date range display
    @param yearStart [number] Start year (optional)
    @param yearEnd [number] End year (optional)
    @return [string] HTML for date range
]]
function HTMLBuilder.CreateDateRange(yearStart, yearEnd)
    if not yearStart and not yearEnd then
        return ""
    end
    
    local color = STYLES.colors.date
    local fontSize = STYLES.fonts.subtitle
    
    if yearStart and yearEnd then
        return string.format(
            '<span style="font-size: %s; color: %s;">%d - %d</span>',
            fontSize, color, yearStart, yearEnd
        )
    elseif yearStart then
        return string.format(
            '<span style="font-size: %s; color: %s;">Year %d</span>',
            fontSize, color, yearStart
        )
    end
    
    return ""
end

--[[
    Create HTML for author attribution
    @param author [string] Author name
    @param options [table] Optional styling overrides
    @return [string] HTML for author section
]]
function HTMLBuilder.CreateAuthor(author, options)
    if not author or author == "" then
        return ""
    end
    
    options = options or {}
    local color = options.color or STYLES.colors.author
    local fontSize = options.fontSize or STYLES.fonts.author
    local align = options.align or "right"
    local margin = options.margin or STYLES.spacing.sectionMargin
    
    return string.format(
        '<div style="text-align: %s; font-size: %s; color: %s; margin-bottom: %s;">%s</div>',
        align, fontSize, color, margin, author
    )
end

--[[
    Create HTML for a chapter header
    @param text [string] Header text
    @param options [table] Optional styling overrides
    @return [string] HTML for the chapter header
]]
function HTMLBuilder.CreateChapterHeader(text, options)
    if not text or text == "" then
        return ""
    end
    
    options = options or {}
    local color = options.color or STYLES.colors.subtitle
    local fontSize = options.fontSize or STYLES.fonts.subtitle
    local align = options.align or "center"
    local marginTop = options.marginTop or "30px"
    local marginBottom = options.marginBottom or "15px"
    
    return string.format(
        '<h2 style="color: %s; font-size: %s; text-align: %s; margin-top: %s; margin-bottom: %s;">%s</h2>',
        color, fontSize, align, marginTop, marginBottom, text
    )
end

-- =============================================================================================
-- COMPOSITE CONTENT BUILDERS
-- =============================================================================================

--[[
    Create a complete cover page with title, portrait, and description
    @param entity [table] Entity data {name, author, description, image}
    @param options [table] Optional styling overrides
    @return [string] Complete HTML for cover page
]]
function HTMLBuilder.CreateCoverPage(entity, options)
    if not entity then
        return ""
    end
    
    local content = {}
    
    -- Portrait (if available)
    if entity.image then
        table.insert(content, HTMLBuilder.CreatePortrait(entity.image, options))
    end
    
    -- Title
    local title = entity.name or entity.label
    if title then
        table.insert(content, HTMLBuilder.CreateTitle(title, options))
    end
    
    -- Author
    if entity.author then
        table.insert(content, HTMLBuilder.CreateAuthor(entity.author, options))
    end
    
    -- Description content
    if entity.description then
        local description = HTMLBuilder.ConvertTextToHTML(entity.description)
        table.insert(content, description)
    end
    
    return HTMLBuilder.CreateDocument(table.concat(content, "\n"))
end

--[[
    Create HTML for a complete chapter with header and content
    @param chapter [table] Chapter data {header, pages}
    @param options [table] Optional styling overrides
    @return [string] Complete HTML for chapter
]]
function HTMLBuilder.CreateChapter(chapter, options)
    if not chapter then
        return ""
    end
    
    local content = {}
    
    -- Chapter header
    if chapter.header and chapter.header ~= "" then
        local headerText = chapter.header
        -- Handle localization if available
        if private.Locale and private.Locale[chapter.header] then
            headerText = private.Locale[chapter.header]
        end
        table.insert(content, HTMLBuilder.CreateChapterHeader(headerText, options))
    end
    
    -- Chapter pages
    if chapter.pages then
        for _, pageKey in ipairs(chapter.pages) do
            local pageContent = pageKey
            -- Handle localization if available
            if private.Locale and private.Locale[pageKey] then
                pageContent = private.Locale[pageKey]
            end
            
            local pageHTML = HTMLBuilder.ConvertTextToHTML(pageContent)
            table.insert(content, pageHTML)
        end
    end
    
    return HTMLBuilder.CreateDocument(table.concat(content, "\n"))
end

-- =============================================================================================
-- TEXT CONVERSION UTILITIES
-- =============================================================================================

--[[
    Convert plain text to formatted HTML paragraphs
    @param content [string] Plain text content
    @param options [table] Optional conversion options
    @return [string] HTML content (without document wrapper)
]]
function HTMLBuilder.ConvertTextToHTML(content, options)
    if not content or content == "" then
        return ""
    end
    
    -- If already HTML, clean and return
    if StringUtils.ContainsHTML and StringUtils.ContainsHTML(content) then
        return StringUtils.CleanHTML and StringUtils.CleanHTML(content) or content
    end
    
    options = options or {}
    local paragraphs = {}
    
    for line in content:gmatch("[^\r\n]+") do
        line = StringUtils.Trim and StringUtils.Trim(line) or line:match("^%s*(.-)%s*$")
        if line ~= "" then
            if HTMLBuilder.IsChapterHeader(line) then
                table.insert(paragraphs, HTMLBuilder.CreateChapterHeader(line, options))
            else
                table.insert(paragraphs, HTMLBuilder.CreateParagraph(line, options))
            end
        end
    end
    
    return table.concat(paragraphs, "\n")
end

--[[
    Simple heuristic to detect chapter headers in plain text
    @param line [string] Text line
    @return [boolean] True if likely a chapter header
]]
function HTMLBuilder.IsChapterHeader(line)
    if not line or line == "" then
        return false
    end
    
    local trimmed = line:match("^%s*(.-)%s*$"):lower()
    return trimmed:find("^chapter") or 
           trimmed:find("^part ") or 
           (#trimmed < 50 and not trimmed:find("%."))
end

-- =============================================================================================
-- INTEGRATION HELPERS
-- =============================================================================================

--[[
    Inject portrait into existing HTML content
    @param htmlContent [string] Original HTML content
    @param portraitPath [string] Portrait image path
    @return [string] HTML with integrated portrait
]]
function HTMLBuilder.InjectPortrait(htmlContent, portraitPath)
    if not portraitPath or portraitPath == "" then
        return htmlContent
    end
    
    local portraitImg = HTMLBuilder.CreatePortrait(portraitPath)
    
    if htmlContent:find("<body>") then
        return htmlContent:gsub("(<body[^>]*>)", "%1" .. portraitImg)
    else
        return portraitImg .. htmlContent
    end
end
