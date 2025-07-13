--[[
    HTMLBuilder.lua
    
    HTML content block generation utilities for the Chronicles addon.
    Provides functions to generate HTML content blocks that will be passed to the single HTMLContentTemplate.
    
    This module focuses ONLY on generating HTML content blocks (paragraphs, titles, portraits, etc.)
    and does NOT handle HTML document containers, scrolling, or display logic.
    
    All generated content is designed to be consumed by the HTMLContentTemplate - the single HTML container.
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
-- HTML CONTENT BLOCK BUILDERS
-- =============================================================================================

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
-- CONTENT COMBINATION UTILITIES
-- =============================================================================================

--[[
    Combine multiple HTML content blocks into a single content string
    @param contentBlocks [table] Array of HTML content strings
    @param separator [string] Optional separator between blocks (default: newline)
    @return [string] Combined HTML content
]]
function HTMLBuilder.CombineContentBlocks(contentBlocks, separator)
    if not contentBlocks or #contentBlocks == 0 then
        return ""
    end
    
    separator = separator or "\n"
    local validBlocks = {}
    
    for _, block in ipairs(contentBlocks) do
        if block and block ~= "" then
            table.insert(validBlocks, block)
        end
    end
    
    return table.concat(validBlocks, separator)
end

--[[
    Create a content block with portrait and text combined
    @param text [string] Text content
    @param portraitPath [string] Portrait image path (optional)
    @param options [table] Optional styling overrides
    @return [string] Combined HTML content block
]]
function HTMLBuilder.CreateContentWithPortrait(text, portraitPath, options)
    local content = {}
    
    -- Add portrait if provided
    if portraitPath and portraitPath ~= "" then
        table.insert(content, HTMLBuilder.CreatePortrait(portraitPath, options))
    end
    
    -- Convert and add text content
    if text and text ~= "" then
        local htmlText = HTMLBuilder.ConvertTextToHTML(text, options)
        table.insert(content, htmlText)
    end
    
    return HTMLBuilder.CombineContentBlocks(content)
end

-- =============================================================================================
-- ADVANCED CONTENT BUILDERS
-- =============================================================================================

--[[
    Create a divider/separator element
    @param options [table] Optional styling overrides
    @return [string] HTML divider element
]]
function HTMLBuilder.CreateDivider(options)
    options = options or {}
    local width = options.width or "80%"
    local color = options.color or STYLES.colors.author
    local margin = options.margin or STYLES.spacing.sectionMargin
    
    return string.format(
        '<hr style="width: %s; border: 1px solid %s; margin: %s auto;" />',
        width, color, margin
    )
end

--[[
    Create a text block with optional styling
    @param text [string] Text content
    @param styleClass [string] Optional CSS class name equivalent
    @param options [table] Optional styling overrides
    @return [string] HTML text block
]]
function HTMLBuilder.CreateTextBlock(text, styleClass, options)
    if not text or text == "" then
        return ""
    end
    
    options = options or {}
    local color = options.color or STYLES.colors.text
    local fontSize = options.fontSize or STYLES.fonts.text
    local margin = options.margin or STYLES.spacing.paragraphMargin
    local align = options.align or "left"
    
    -- Apply style class variations
    if styleClass == "quote" then
        color = options.color or STYLES.colors.author
        fontSize = options.fontSize or STYLES.fonts.text
        margin = options.margin or "15px"
        return string.format(
            '<blockquote style="color: %s; font-size: %s; margin: %s; padding-left: 20px; border-left: 3px solid %s; font-style: italic;">%s</blockquote>',
            color, fontSize, margin, STYLES.colors.subtitle, text
        )
    elseif styleClass == "emphasis" then
        return string.format(
            '<div style="color: %s; font-size: %s; margin: %s; text-align: %s; font-weight: bold;">%s</div>',
            STYLES.colors.title, fontSize, margin, align, text
        )
    else
        return string.format(
            '<div style="color: %s; font-size: %s; margin: %s; text-align: %s;">%s</div>',
            color, fontSize, margin, align, text
        )
    end
end

--[[
    Create a list (ordered or unordered)
    @param items [table] Array of list items
    @param ordered [boolean] True for ordered list, false for unordered
    @param options [table] Optional styling overrides
    @return [string] HTML list element
]]
function HTMLBuilder.CreateList(items, ordered, options)
    if not items or #items == 0 then
        return ""
    end
    
    options = options or {}
    local color = options.color or STYLES.colors.text
    local fontSize = options.fontSize or STYLES.fonts.text
    local margin = options.margin or STYLES.spacing.paragraphMargin
    
    local listTag = ordered and "ol" or "ul"
    local listItems = {}
    
    for _, item in ipairs(items) do
        if item and item ~= "" then
            table.insert(listItems, string.format('<li>%s</li>', item))
        end
    end
    
    if #listItems == 0 then
        return ""
    end
    
    return string.format(
        '<%s style="color: %s; font-size: %s; margin: %s;">%s</%s>',
        listTag, color, fontSize, margin, table.concat(listItems, ""), listTag
    )
end
