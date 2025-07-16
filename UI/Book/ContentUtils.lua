--[[
    ContentUtils.lua
    
    Content transformation utilities for the new HTML-based book system.
    Transforms entity data into complete HTML documents using NewHTMLBuilder.
    
    This is a NEW implementation designed to work with the single HTML container
    approach, replacing the multi-template system.
]]
local FOLDER_NAME, private = ...

-- Import dependencies
local HTMLBuilder = private.Core.Utils.HTMLBuilder

-- Initialize ContentUtils namespace
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.ContentUtils = {}
local ContentUtils = private.Core.Utils.ContentUtils

-- =============================================================================================
-- MAIN TRANSFORMATION FUNCTIONS
-- =============================================================================================

--[[
    Type Definition for Book Content Structure
    =========================================
    @return BookContent[] - Array of book sections with the following structure:
    {
        [1] = {  -- Title section
            -- Optional header for section/chapter
            header = {  
                templateKey = string,  -- Template identifier (e.g. "CHAPTER_HEADER")
                text = string          -- Header text content
            },
            -- Required array of content elements
            elements = {
                {
                    templateKey = string,  -- Template identifier (e.g. "HTML_CONTENT", "TEXT_CONTENT")
                    
                    -- Content properties based on templateKey:
                    -- For HTML_CONTENT:
                    htmlContent = string,   -- HTML formatted content
                    title = string,         -- Optional title for reference
                    entity = table,         -- Optional original entity reference
                }
                -- Additional elements...
            }
        },
        -- Additional sections...
    }
]]
--[[
    Transform any entity into HTML book content for the new system
    @param entity [table] Entity data (event, character, faction)
    @param options [table] Optional styling and layout options
    @return [table] New book format with multiple HTML content elements
]]
function ContentUtils.TransformEntityToBook(entity, options)
    if not entity then
        return {
            {
                elements = {
                    {
                        templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                        htmlContent = "<div>No content available</div>",
                        title = "Empty"
                    }
                }
            }
        }
    end

    -- Generate list of HTML documents using HTMLBuilder
    local htmlDocuments
    if HTMLBuilder.CreateEntityHTML then
        htmlDocuments = HTMLBuilder.CreateEntityHTML(entity, options)
    else
        -- Create simple fallback HTML
        local title = entity.name or entity.label or "Unknown"
        local description = entity.description or "No description available"
        htmlDocuments = {
            string.format("<html><body><h1>%s</h1><p>%s</p></body></html>", title, description)
        }
    end
    
    -- Ensure we have a valid array of HTML documents
    if not htmlDocuments or type(htmlDocuments) ~= "table" or #htmlDocuments == 0 then
        local title = entity.name or entity.label or "Unknown"
        htmlDocuments = {
            string.format("<html><body><h1>%s</h1><p>No content available</p></body></html>", title)
        }
    end
    
    local title = entity.name or entity.label or "Chronicles Content"

    -- Create one section with multiple elements, one for each HTML document
    local elements = {}
    for i, htmlContent in ipairs(htmlDocuments) do
        -- local elementTitle = title
        -- if #htmlDocuments > 1 then
        --     elementTitle = title .. " - Page " .. i
        -- end
        
        table.insert(elements, {
            templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
            htmlContent = htmlContent, -- Use 'htmlContent' property for HTMLContentMixin
            -- title = elementTitle,
            -- entity = entity -- Keep reference for debugging/future use
        })
    end

    -- Return array of section objects, each with an elements array
    local result = {
        {
            elements = elements
        }
    }

    return result
end

--[[
    Transform event entity to new HTML book format
    @param event [table] Event entity data
    @param options [table] Optional styling and layout options
    @return [table] New book format
]]
function ContentUtils.TransformEventToNewBook(event, options)
    return ContentUtils.TransformEntityToBook(event, options)
end

--[[
    Transform character entity to new HTML book format
    @param character [table] Character entity data
    @param options [table] Optional styling and layout options
    @return [table] New book format
]]
function ContentUtils.TransformCharacterToNewBook(character, options)
    return ContentUtils.TransformEntityToBook(character, options)
end

--[[
    Transform faction entity to new HTML book format
    @param faction [table] Faction entity data
    @param options [table] Optional styling and layout options
    @return [table] New book format
]]
function ContentUtils.TransformFactionToNewBook(faction, options)
    return ContentUtils.TransformEntityToBook(faction, options)
end

-- =============================================================================================
-- CONTENT ANALYSIS AND UTILITIES
-- =============================================================================================

--[[
    Analyze entity content and provide layout recommendations
    @param entity [table] Entity data
    @return [table] Analysis results with layout suggestions
]]
function ContentUtils.AnalyzeEntityContent(entity)
    if not entity then
        return {
            hasContent = false,
            contentType = "empty",
            layoutSuggestion = "simple"
        }
    end

    local analysis = {
        hasContent = false,
        contentType = "unknown",
        layoutSuggestion = "simple",
        hasPortrait = false,
        hasDescription = false,
        hasChapters = false,
        chapterCount = 0,
        estimatedLength = "short",
        hasDateRange = false
    }

    -- Check for portrait
    if entity.image and entity.image ~= "" then
        analysis.hasPortrait = true
    end

    -- Check for description
    if entity.description and entity.description ~= "" then
        analysis.hasDescription = true
        analysis.hasContent = true
    end

    -- Check for chapters
    if entity.chapters and #entity.chapters > 0 then
        analysis.hasChapters = true
        analysis.chapterCount = #entity.chapters
        analysis.hasContent = true
    end

    -- Check for date range (events)
    if entity.yearStart or entity.yearEnd then
        analysis.hasDateRange = true
        analysis.contentType = "event"
    elseif analysis.hasPortrait or analysis.hasDescription then
        analysis.contentType = entity.factions and "character" or "faction"
    end

    -- Determine layout suggestion
    if analysis.hasPortrait and analysis.hasDescription then
        analysis.layoutSuggestion = "cover"
    elseif analysis.hasDateRange then
        analysis.layoutSuggestion = "event_title"
    elseif analysis.hasChapters and analysis.chapterCount > 3 then
        analysis.layoutSuggestion = "multi_chapter"
    else
        analysis.layoutSuggestion = "simple"
    end

    -- Estimate content length
    local totalLength = 0
    if entity.description then
        totalLength = totalLength + string.len(entity.description)
    end
    if entity.chapters then
        for _, chapter in ipairs(entity.chapters) do
            if chapter.pages then
                for _, page in ipairs(chapter.pages) do
                    totalLength = totalLength + string.len(page or "")
                end
            end
        end
    end

    if totalLength < 500 then
        analysis.estimatedLength = "short"
    elseif totalLength < 2000 then
        analysis.estimatedLength = "medium"
    else
        analysis.estimatedLength = "long"
    end

    return analysis
end

--[[
    Create content options based on entity analysis
    @param entity [table] Entity data
    @return [table] Recommended options for HTML generation
]]
function ContentUtils.CreateRecommendedOptions(entity)
    local analysis = ContentUtils.AnalyzeEntityContent(entity)
    local options = {}

    -- Layout-specific options
    if analysis.layoutSuggestion == "cover" then
        options.useCoverLayout = true
        options.portraitPlacement = "right"
    elseif analysis.layoutSuggestion == "event_title" then
        options.emphasizeDates = true
        options.centerTitle = true
    elseif analysis.layoutSuggestion == "multi_chapter" then
        options.addPageBreaks = true
        options.emphasizeChapters = true
    end

    -- Length-specific options
    if analysis.estimatedLength == "long" then
        options.enablePagination = true
        options.addTableOfContents = true
    end

    return options
end

return ContentUtils
