--[[
    ContentUtils.lua
    
    Content conversion and layout utilities for the Chronicles addon book template system.
    Provides text-to-HTML conversion, portrait integration, and content structure creation.
]]

local FOLDER_NAME, private = ...

-- Import dependencies
local StringUtils = private.Core.Utils.StringUtils

-- Initialize ContentUtils namespace
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.ContentUtils = {}
local ContentUtils = private.Core.Utils.ContentUtils

-- =============================================================================================
-- CONTENT CONVERSION UTILITIES
-- =============================================================================================

--[[
    Convert plain text content to structured HTML
    @param content [string] Plain text content
    @param portraitPath [string] Optional portrait image path
    @return [string] Formatted HTML content
]]
function ContentUtils.ConvertTextToHTML(content, portraitPath)
    local html = "<html><body>"
    if portraitPath and portraitPath ~= "" then
        html = html .. string.format('<img src="%s" width="120" height="120" align="right" style="margin: 0 0 10px 15px;" />', portraitPath)
    end
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        line = StringUtils.Trim(line)
        if line ~= "" then
            if ContentUtils.IsChapterHeader(line) then
                table.insert(lines, string.format('<h2 style="color: #ffd100; margin-top: 20px;">%s</h2>', line))
            else
                table.insert(lines, string.format('<p style="margin-bottom: 10px; text-align: justify;">%s</p>', line))
            end
        end
    end
    html = html .. table.concat(lines, "\n") .. "</body></html>"
    return html
end

--[[
    Inject portrait into HTML content
    @param htmlContent [string] Original HTML content
    @param portraitPath [string] Portrait image path
    @return [string] HTML with integrated portrait
]]
function ContentUtils.InjectPortraitIntoHTML(htmlContent, portraitPath)
    local portraitImg = string.format('<img src="%s" width="120" height="120" align="right" style="margin: 0 0 15px 15px;" />', portraitPath)
    if htmlContent:find("<body>") then
        htmlContent = htmlContent:gsub("(<body[^>]*>)", "%1" .. portraitImg)
    else
        htmlContent = portraitImg .. htmlContent
    end
    return htmlContent
end

--[[
    Simple heuristic to detect chapter headers
    @param line [string] Text line
    @return [boolean] True if likely a chapter header
]]
function ContentUtils.IsChapterHeader(line)
    local trimmed = StringUtils.Trim(line):lower()
    return trimmed:find("^chapter") or trimmed:find("^part ") or (#trimmed < 50 and not trimmed:find("%."))
end

--[[
    Create HTML content for a complete chapter
    @param chapter [table] Chapter with header and pages  
    @return [string] Complete HTML for the chapter
]]
function ContentUtils.CreateChapterHTML(chapter)
    local html = "<html><body>"
    if chapter.header and chapter.header ~= "" then
        local headerText = chapter.header
        if private.Locale and private.Locale[chapter.header] then
            headerText = private.Locale[chapter.header]
        end
        html = html .. string.format('<h1 style="color: #ffd100; text-align: center; margin-bottom: 20px;">%s</h1>', headerText)
    end
    if chapter.pages then
        for _, pageKey in ipairs(chapter.pages) do
            local pageContent = pageKey
            if private.Locale and private.Locale[pageKey] then
                pageContent = private.Locale[pageKey]
            end
            if StringUtils.ContainsHTML and StringUtils.ContainsHTML(pageContent) then
                local cleanContent = StringUtils.CleanHTML and StringUtils.CleanHTML(pageContent) or pageContent
                html = html .. cleanContent
            else
                local paragraphs = {}
                for line in pageContent:gmatch("[^\r\n]+") do
                    line = StringUtils.Trim(line)
                    if line ~= "" then
                        table.insert(paragraphs, string.format('<p style="margin-bottom: 10px; text-align: justify;">%s</p>', line))
                    end
                end
                html = html .. table.concat(paragraphs, "\n")
            end
        end
    end
    html = html .. "</body></html>"
    return html
end

-- =============================================================================================
-- CONTENT LAYOUT UTILITIES
-- =============================================================================================

--[[
    Calculate optimal content dimensions and pagination
    @param content [string] Raw content (HTML or text)
    @param maxWidth [number] Maximum width in pixels
    @param maxHeight [number] Maximum height in pixels (optional)
    @param portraitPath [string] Optional portrait image path
    @return [table] {pages = {}, estimatedHeight = number, hasPortrait = boolean}
]]
function ContentUtils.CalculateContentLayout(content, maxWidth, maxHeight, portraitPath)
    local result = {
        pages = {},
        estimatedHeight = 0,
        hasPortrait = portraitPath and portraitPath ~= ""
    }
    local isHTML = StringUtils.ContainsHTML and StringUtils.ContainsHTML(content) or string.find(content, "<[^>]+>") ~= nil
    if isHTML then
        result.pages = ContentUtils.SplitHTMLContent(content, maxWidth, maxHeight, portraitPath)
    else
        local htmlContent = ContentUtils.ConvertTextToHTML(content, portraitPath)
        result.pages = {htmlContent}
    end
    result.estimatedHeight = #result.pages * (maxHeight or 400)
    return result
end

--[[
    Split HTML content into manageable pages
    @param content [string] HTML content
    @param maxWidth [number] Maximum width
    @param maxHeight [number] Maximum height
    @param portraitPath [string] Portrait path
    @return [table] Array of HTML page strings
]]
function ContentUtils.SplitHTMLContent(content, maxWidth, maxHeight, portraitPath)
    local pages = {}
    local cleanContent = StringUtils.CleanHTML and StringUtils.CleanHTML(content) or content
    if portraitPath and portraitPath ~= "" and not cleanContent:find("<img[^>]*src=") then
        cleanContent = ContentUtils.InjectPortraitIntoHTML(cleanContent, portraitPath)
    end
    table.insert(pages, cleanContent)
    return pages
end

-- =============================================================================================
-- CONTENT STRUCTURE CREATION UTILITIES
-- =============================================================================================

--[[
    Create unified content data for book display
    @param entity [table] Entity with chapters and description
    @return [table] Unified content structure compatible with existing templates
]]
function ContentUtils.CreateUnifiedContent(entity)
    if not entity then return {} end
    local data = {}
    local titleElement = {
        templateKey = private.constants.bookTemplateKeys.CHAPTER_HEADER,
        text = entity.name or entity.label or "Unknown Entity"
    }
    table.insert(data, { elements = {titleElement} })
    if entity.description and entity.description ~= "" then
        local descElement = {
            templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
            content = entity.description
        }
        table.insert(data, { elements = {descElement} })
    end
    if entity.chapters and #entity.chapters > 0 then
        for _, chapter in ipairs(entity.chapters) do
            local bookChapter = ContentUtils.CreateChapterInOldFormat(chapter)
            table.insert(data, bookChapter)
        end
    end
    return data
end

--[[
    Create a chapter in the old nested format for compatibility
    @param chapter [table] Chapter with header and pages
    @return [table] Chapter object with header and elements array
]]
function ContentUtils.CreateChapterInOldFormat(chapter)
    local bookChapter = {elements = {}}
    if chapter.header and chapter.header ~= "" then
        local headerText = chapter.header
        if private.Locale and private.Locale[chapter.header] then
            headerText = private.Locale[chapter.header]
        end
        bookChapter.header = {
            templateKey = private.constants.bookTemplateKeys.CHAPTER_HEADER,
            text = headerText
        }
    end
    if chapter.pages then
        for _, pageKey in ipairs(chapter.pages) do
            local pageContent = pageKey
            if private.Locale and private.Locale[pageKey] then
                pageContent = private.Locale[pageKey]
            end
            if StringUtils.ContainsHTML and StringUtils.ContainsHTML(pageContent) then
                table.insert(bookChapter.elements, {
                    templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                    content = StringUtils.CleanHTML and StringUtils.CleanHTML(pageContent) or pageContent
                })
            else
                local lines
                if StringUtils and StringUtils.SplitTextToFitWidth then
                    lines = StringUtils.SplitTextToFitWidth(pageContent, private.constants.viewWidth)
                else
                    lines = {pageContent}
                end
                for _, line in ipairs(lines) do
                    table.insert(bookChapter.elements, {
                        templateKey = private.constants.bookTemplateKeys.TEXT_CONTENT,
                        text = line
                    })
                end
            end
        end
    end
    return bookChapter
end
