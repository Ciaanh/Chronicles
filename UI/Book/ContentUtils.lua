--[[
    ContentUtils.lua
    
    Content structure creation and layout utilities for the Chronicles addon book template system.
    Focuses on content organization, template structure creation, and layout calculations.
    Uses HTMLBuilder for HTML generation.
]]

local FOLDER_NAME, private = ...

-- Import dependencies
local StringUtils = private.Core.Utils.StringUtils
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- Initialize ContentUtils namespace
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.ContentUtils = {}
local ContentUtils = private.Core.Utils.ContentUtils

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

-- =============================================================================================
-- DEPRECATED WRAPPER FUNCTIONS (REMOVE AFTER TEMPLATE MIGRATION)
-- =============================================================================================
-- These functions are kept temporarily for backward compatibility.
-- Templates should use HTMLBuilder directly instead of these wrappers.

--[[
    @deprecated Use HTMLBuilder.ConvertTextToHTML() directly
    Convert plain text content to structured HTML
]]
function ContentUtils.ConvertTextToHTML(content, portraitPath)
    local htmlContent = HTMLBuilder.ConvertTextToHTML(content)
    if portraitPath and portraitPath ~= "" then
        htmlContent = HTMLBuilder.InjectPortrait(HTMLBuilder.CreateDocument(htmlContent), portraitPath)
    else
        htmlContent = HTMLBuilder.CreateDocument(htmlContent)
    end
    return htmlContent
end

--[[
    @deprecated Use HTMLBuilder.InjectPortrait() directly
    Inject portrait into HTML content
]]
function ContentUtils.InjectPortraitIntoHTML(htmlContent, portraitPath)
    return HTMLBuilder.InjectPortrait(htmlContent, portraitPath)
end

--[[
    @deprecated Use HTMLBuilder.IsChapterHeader() directly
    Simple heuristic to detect chapter headers
]]
function ContentUtils.IsChapterHeader(line)
    return HTMLBuilder.IsChapterHeader(line)
end

--[[
    @deprecated Use HTMLBuilder.CreateChapter() directly
    Create HTML content for a complete chapter
]]
function ContentUtils.CreateChapterHTML(chapter)
    return HTMLBuilder.CreateChapter(chapter)
end
