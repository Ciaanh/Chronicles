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
    @return [table] New book format with multiple HTML content elements
]]
function ContentUtils.TransformEntityToBook(entity)
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
        local htmlResult = HTMLBuilder.CreateEntityHTML(entity)
        
        -- HTMLBuilder.CreateEntityHTML returns {documents = [...], navigationData = {...}}
        -- We need the documents array for content transformation
        if htmlResult and htmlResult.documents then
            htmlDocuments = htmlResult.documents
        elseif htmlResult and type(htmlResult) == "table" and #htmlResult > 0 then
            -- Fallback: if it's an array, use it directly
            htmlDocuments = htmlResult
        else
            -- Create simple fallback HTML
            local title = entity.name or entity.label or "Unknown"
            local description = entity.description or "No description available"
            htmlDocuments = {
                string.format("<html><body><h1>%s</h1><p>%s</p></body></html>", title, description)
            }
        end
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
    
    -- local title = entity.name or entity.label or "Chronicles Content"

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

-- Note: Wrapper functions removed as they were unnecessary
-- Domain files should call ContentUtils.TransformEntityToBook directly

return ContentUtils
