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
local Cache = private.Core.Cache
local TableUtils = private.Core.Utils.TableUtils

local function countEntries(tbl)
    if type(tbl) ~= "table" then
        return 0
    end

    if TableUtils and TableUtils.Length then
        return TableUtils.Length(tbl)
    end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Total book pages the entity's chapters occupy. Part of the cache key because chapter *count* alone
-- cannot see a chapter gaining a page: since one entry in chapter.pages is one book page, an edit that
-- adds a page changes the document count and the whole navigation mapping while leaving the chapter
-- count identical, and the reader would keep getting the cached pre-edit book until a /reload.
local function countPages(entity)
    if type(entity.chapters) ~= "table" then
        return 0
    end

    local HTMLBuilderRef = private.Core.Utils.HTMLBuilder
    local total = 0

    for _, chapter in pairs(entity.chapters) do
        if HTMLBuilderRef and HTMLBuilderRef.GetChapterPageCount then
            total = total + HTMLBuilderRef.GetChapterPageCount(chapter)
        else
            total = total + countEntries(chapter and chapter.pages)
        end
    end

    return total
end

local function buildEntityCacheKey(entity)
    if type(entity) ~= "table" then
        return nil
    end

    if entity.__cacheKey then
        return tostring(entity.__cacheKey)
    end

    local id = entity.id or entity.eventId or entity.characterId or entity.factionId or entity.name or entity.label
    if not id then
        return nil
    end

    local source = entity.source or entity.collection or entity.collectionName or "default"
    local revision =
        entity.lastModified or entity.updatedAt or entity.version or (entity.metadata and entity.metadata.revision) or 0
    local chaptersCount = countEntries(entity.chapters)
    local descriptionLength = entity.description and #entity.description or 0

    return string.format(
        "%s:%s:%s:%s:%s:%s",
        tostring(source),
        tostring(id),
        tostring(revision),
        tostring(chaptersCount),
        tostring(countPages(entity)),
        tostring(descriptionLength)
    )
end

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

    local cacheKey = buildEntityCacheKey(entity)
    if cacheKey and Cache and Cache.getBookContent then
        local cachedPayload = Cache.getBookContent(cacheKey)
        if cachedPayload then
            return cachedPayload
        end
    end

    -- Generate list of HTML documents using HTMLBuilder
    local htmlDocuments
    local navigationData
    if HTMLBuilder.CreateEntityHTML then
        local htmlResult = HTMLBuilder.CreateEntityHTML(entity)

        -- HTMLBuilder.CreateEntityHTML returns {documents = [...], navigationData = {...}}
        -- Both halves matter: the documents are the pages, and navigationData maps chapter ids to
        -- page indices, which is what makes the table-of-contents links clickable.
        if htmlResult and htmlResult.documents then
            htmlDocuments = htmlResult.documents
            navigationData = htmlResult.navigationData
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

    -- Return array of section objects, each with an elements array. navigationData rides along as a
    -- named field: it is not a section, so ipairs-based consumers skip it, and BookContainerTemplate
    -- reads it off the returned table to resolve chapter links.
    local result = {
        {
            elements = elements
        }
    }
    result.navigationData = navigationData

    if cacheKey and Cache and Cache.setBookContent then
        Cache.setBookContent(cacheKey, result)
    end

    return result
end

-- Note: Wrapper functions removed as they were unnecessary
-- Domain files should call ContentUtils.TransformEntityToBook directly

return ContentUtils
