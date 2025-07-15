--[[
    HTMLBuilder.lua
    
    Enhanced HTML content generation for the new Chronicles book system.
    Generates complete HTML documents for single-container display.
    
    This is a NEW implementation designed to replace the multi-template system
    with a single HTML container that can display all content types.
]]

local FOLDER_NAME, private = ...

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
        subtitle = "#d4af37", 
        text = "#ffffff",
        author = "#cccccc",
        date = "#ffd100",
        chapter = "#e6b800",
        background = "#0a0a0a"
    },
    fonts = {
        title = "24px",
        subtitle = "20px", 
        chapter = "18px",
        text = "14px",
        author = "13px",
        date = "16px"
    },
    spacing = {
        titleMargin = "0 0 20px 0",
        subtitleMargin = "0 0 15px 0",
        chapterMargin = "25px 0 15px 0",
        paragraphMargin = "0 0 12px 0",
        portraitMargin = "0 0 15px 15px",
        sectionMargin = "30px 0"
    },
    portrait = {
        width = "140",
        height = "140",
        align = "right",
        borderRadius = "8px"
    }
}

-- =============================================================================================
-- BASE HTML STRUCTURE
-- =============================================================================================

--[[
    Create the base HTML document structure
    @param content [string] HTML body content
    @param title [string] Document title (optional)
    @return [string] Complete HTML document
]]
-- function HTMLBuilder.CreateHTMLDocument(content, title)
--     title = title or "Chronicles Content"
    
--     local html = string.format([[
-- <!DOCTYPE html>
-- <html>
-- <head>
--     <title>%s</title>
--     <style>
--         body {
--             background-color: %s;
--             color: %s;
--             font-family: "Friz Quadrata TT", serif;
--             font-size: %s;
--             line-height: 1.6;
--             margin: 20px;
--             padding: 0;
--         }
        
--         .title {
--             color: %s;
--             font-size: %s;
--             font-weight: bold;
--             text-align: center;
--             margin: %s;
--             text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
--         }
        
--         .subtitle {
--             color: %s;
--             font-size: %s;
--             font-weight: bold;
--             text-align: center;
--             margin: %s;
--         }
        
--         .chapter-header {
--             color: %s;
--             font-size: %s;
--             font-weight: bold;
--             margin: %s;
--             border-bottom: 2px solid %s;
--             padding-bottom: 5px;
--         }
        
--         .author {
--             color: %s;
--             font-size: %s;
--             text-align: right;
--             font-style: italic;
--             margin: 10px 0;
--         }
        
--         .date-range {
--             color: %s;
--             font-size: %s;
--             text-align: center;
--             font-weight: bold;
--             margin: 10px 0;
--         }
        
--         .content-paragraph {
--             margin: %s;
--             text-align: justify;
--         }
        
--         .portrait {
--             border-radius: %s;
--             margin: %s;
--             box-shadow: 2px 2px 8px rgba(0,0,0,0.5);
--         }
        
--         .section {
--             margin: %s;
--         }
        
--         .cover-layout {
--             display: flex;
--             align-items: flex-start;
--             gap: 20px;
--         }
        
--         .cover-content {
--             flex: 1;
--         }
        
--         .cover-portrait {
--             flex-shrink: 0;
--         }
        
--         .divider {
--             width: 300px;
--             height: 2px;
--             background: linear-gradient(to right, transparent, %s, transparent);
--             margin: 20px auto;
--         }
        
--         .page-break {
--             page-break-before: always;
--             margin: 40px 0;
--         }
--     </style>
-- </head>
-- <body>
-- %s
-- </body>
-- </html>]], 
--     title,
--     STYLES.colors.background, STYLES.colors.text, STYLES.fonts.text,
--     STYLES.colors.title, STYLES.fonts.title, STYLES.spacing.titleMargin,
--     STYLES.colors.subtitle, STYLES.fonts.subtitle, STYLES.spacing.subtitleMargin,
--     STYLES.colors.chapter, STYLES.fonts.chapter, STYLES.spacing.chapterMargin, STYLES.colors.chapter,
--     STYLES.colors.author, STYLES.fonts.author,
--     STYLES.colors.date, STYLES.fonts.date,
--     STYLES.spacing.paragraphMargin,
--     STYLES.portrait.borderRadius, STYLES.spacing.portraitMargin,
--     STYLES.spacing.sectionMargin,
--     STYLES.colors.chapter,
--     content
--     )
    
--     return html
-- end
function HTMLBuilder.CreateHTMLDocument(content, title)
    title = title or "Chronicles Content"
    
    local html = string.format([[
<html>
<body>
%s
</body>
</html>]], 
    content
    )
    
    return html
end

-- =============================================================================================
-- CONTENT BLOCK BUILDERS
-- =============================================================================================

--[[
    Create a title block
    @param title [string] Title text
    @param options [table] Optional styling overrides
    @return [string] HTML title element
]]
function HTMLBuilder.CreateTitle(title, options)
    if not title or title == "" then
        return ""
    end
    
    options = options or {}
    local class = options.class or "title"
    
    return string.format('<div class="%s">%s</div>', class, title)
end

--[[
    Create a subtitle block
    @param subtitle [string] Subtitle text
    @param options [table] Optional styling overrides
    @return [string] HTML subtitle element
]]
function HTMLBuilder.CreateSubtitle(subtitle, options)
    if not subtitle or subtitle == "" then
        return ""
    end
    
    options = options or {}
    local class = options.class or "subtitle"
    
    return string.format('<div class="%s">%s</div>', class, subtitle)
end

--[[
    Create a chapter header block
    @param header [string] Chapter header text
    @param options [table] Optional styling overrides
    @return [string] HTML chapter header element
]]
function HTMLBuilder.CreateChapterHeader(header, options)
    if not header or header == "" then
        return ""
    end
    
    options = options or {}
    local class = options.class or "chapter-header"
    
    return string.format('<div class="%s">%s</div>', class, header)
end

--[[
    Create an author attribution block
    @param author [string] Author name
    @param options [table] Optional styling overrides
    @return [string] HTML author element
]]
function HTMLBuilder.CreateAuthor(author, options)
    if not author or author == "" then
        return ""
    end
    
    options = options or {}
    local class = options.class or "author"
    local prefix = options.prefix or "by "
    
    return string.format('<div class="%s">%s%s</div>', class, prefix, author)
end

--[[
    Create a date range block for events
    @param yearStart [number] Start year
    @param yearEnd [number] End year
    @param options [table] Optional styling overrides
    @return [string] HTML date range element
]]
function HTMLBuilder.CreateDateRange(yearStart, yearEnd, options)
    if not yearStart and not yearEnd then
        return ""
    end
    
    options = options or {}
    local class = options.class or "date-range"
    
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
    
    return string.format('<div class="%s">%s</div>', class, dateText)
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
    local class = options.class or "portrait"
    
    return string.format(
        '<img src="%s" width="%s" height="%s" align="%s" class="%s" />',
        portraitPath, width, height, align, class
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
    local class = options.class or "content-paragraph"
    
    return string.format('<div class="%s">%s</div>', class, text)
end

--[[
    Create a section container
    @param content [string] Section content
    @param options [table] Optional styling overrides
    @return [string] HTML section element
]]
function HTMLBuilder.CreateSection(content, options)
    if not content or content == "" then
        return ""
    end
    
    options = options or {}
    local class = options.class or "section"
    
    return string.format('<div class="%s">%s</div>', class, content)
end

--[[
    Create a visual divider
    @param options [table] Optional styling overrides
    @return [string] HTML divider element
]]
function HTMLBuilder.CreateDivider(options)
    options = options or {}
    local class = options.class or "divider"
    
    return string.format('<div class="%s"></div>', class)
end

--[[
    Create a page break
    @param options [table] Optional styling overrides
    @return [string] HTML page break element
]]
function HTMLBuilder.CreatePageBreak(options)
    options = options or {}
    local class = options.class or "page-break"
    
    return string.format('<div class="%s"></div>', class)
end

-- =============================================================================================
-- SPECIALIZED CONTENT BUILDERS
-- =============================================================================================

--[[
    Create a cover page layout with portrait and content
    @param entity [table] Entity data
    @param options [table] Optional styling overrides
    @return [string] HTML cover page layout
]]
function HTMLBuilder.CreateCoverPage(entity, options)
    if not entity then
        return ""
    end
    
    options = options or {}
    local content = {}
    
    -- Title
    if entity.name or entity.label then
        table.insert(content, HTMLBuilder.CreateTitle(entity.name or entity.label, options))
    end
    
    -- Author
    if entity.author then
        table.insert(content, HTMLBuilder.CreateAuthor(entity.author, options))
    end
    
    -- Cover layout with portrait and description
    if entity.image or entity.description then
        local coverContent = {}
        
        -- Portrait
        if entity.image then
            table.insert(coverContent, string.format(
                '<div class="cover-portrait">%s</div>',
                HTMLBuilder.CreatePortrait(entity.image, options)
            ))
        end
        
        -- Description content
        if entity.description then
            table.insert(coverContent, string.format(
                '<div class="cover-content">%s</div>',
                HTMLBuilder.CreateParagraph(entity.description, options)
            ))
        end
        
        local coverLayout = string.format(
            '<div class="cover-layout">%s</div>',
            table.concat(coverContent, "")
        )
        table.insert(content, coverLayout)
    end
    
    return table.concat(content, "")
end

--[[
    Create an event title page with date range
    @param entity [table] Event entity data
    @param options [table] Optional styling overrides
    @return [string] HTML event title page
]]
function HTMLBuilder.CreateEventTitle(entity, options)
    if not entity then
        return ""
    end
    
    options = options or {}
    local content = {}
    
    -- Title
    if entity.name or entity.label then
        table.insert(content, HTMLBuilder.CreateTitle(entity.name or entity.label, options))
    end
    
    -- Date range
    if entity.yearStart or entity.yearEnd then
        table.insert(content, HTMLBuilder.CreateDateRange(entity.yearStart, entity.yearEnd, options))
    end
    
    -- Divider
    table.insert(content, HTMLBuilder.CreateDivider(options))
    
    -- Author
    if entity.author then
        table.insert(content, HTMLBuilder.CreateAuthor(entity.author, options))
    end
    
    return table.concat(content, "")
end

--[[
    Create chapter content with header and pages
    @param chapter [table] Chapter data
    @param options [table] Optional styling overrides
    @return [string] HTML chapter content
]]
function HTMLBuilder.CreateChapter(chapter, options)
    if not chapter then
        return ""
    end
    
    options = options or {}
    local content = {}
    
    -- Chapter header
    if chapter.header then
        table.insert(content, HTMLBuilder.CreateChapterHeader(chapter.header, options))
    end
    
    -- Chapter pages
    if chapter.pages then
        for _, page in ipairs(chapter.pages) do
            if page and page ~= "" then
                -- Handle localization if needed
                local pageContent = page
                if private.Locale and private.Locale[page] then
                    pageContent = private.Locale[page]
                end
                
                table.insert(content, HTMLBuilder.CreateParagraph(pageContent, options))
            end
        end
    end
    
    return HTMLBuilder.CreateSection(table.concat(content, ""), options)
end

-- =============================================================================================
-- MAIN CONTENT GENERATION
-- =============================================================================================

--[[
    Transform any entity into complete HTML content
    @param entity [table] Entity data (event, character, faction)
    @param options [table] Optional styling and layout options
    @return [string] Complete HTML document ready for display
]]
function HTMLBuilder.CreateEntityHTML(entity, options)
    -- print("HTMLBuilder.CreateEntityHTML called with entity:", entity and entity.name or entity and entity.label or "nil")
    if not entity then
        -- print("HTMLBuilder: No entity provided")
        return HTMLBuilder.CreateHTMLDocument("<div>No content available</div>", "Empty")
    end
    
    options = options or {}
    local content = {}
    
    -- Determine content type and create appropriate title section
    local shouldUseCoverPage = (entity.description and entity.description ~= "") or 
                              (entity.image and entity.image ~= "")
    
    if shouldUseCoverPage then
        -- Create cover page layout
        table.insert(content, HTMLBuilder.CreateCoverPage(entity, options))
    elseif entity.yearStart or entity.yearEnd then
        -- Create event title page
        table.insert(content, HTMLBuilder.CreateEventTitle(entity, options))
    else
        -- Create simple title page
        local titleContent = {}
        if entity.name or entity.label then
            table.insert(titleContent, HTMLBuilder.CreateTitle(entity.name or entity.label, options))
        end
        if entity.author then
            table.insert(titleContent, HTMLBuilder.CreateAuthor(entity.author, options))
        end
        table.insert(content, table.concat(titleContent, ""))
    end
    
    -- Add divider after title section
    if #content > 0 then
        table.insert(content, HTMLBuilder.CreateDivider(options))
    end
    
    -- Process chapters
    if entity.chapters and #entity.chapters > 0 then
        for i, chapter in ipairs(entity.chapters) do
            if i > 1 then
                -- Add page break between chapters (except before first)
                table.insert(content, HTMLBuilder.CreatePageBreak(options))
            end
            table.insert(content, HTMLBuilder.CreateChapter(chapter, options))
        end
    end
    
    local htmlContent = table.concat(content, "")
    local title = entity.name or entity.label or "Chronicles Content"
    
    return HTMLBuilder.CreateHTMLDocument(htmlContent, title)
end

return HTMLBuilder
