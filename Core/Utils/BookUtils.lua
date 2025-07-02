local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Utils.BookUtils = {}

--[[
    Shared utilities with error handling
]]
local StringUtils = private.Core.Utils.StringUtils

--[[
    Create a cover page that follows the standard header/elements structure
    @param entity table - The entity object with name, description, image
    @return table - Cover page with header and scrollable elements
]]
local function CreateCoverPage(entity)
    local coverPage = {
        templateKey = private.constants.bookTemplateKeys.COVER_PAGE,
        name = entity.name or entity.label or "Unknown Entity",
        author = entity.author and (Locale["Author"] .. entity.author) or nil,
        text = entity.description or nil,  -- Include description directly
        image = entity.image or nil        -- Include image directly
    }

    return coverPage
end

--[[
    Transform title and pages into a structured chapter object for UI rendering
    
    This function processes raw chapter content and creates a structured object
    with proper template keys for the UI rendering system. It handles both
    text and HTML content, applying appropriate template mappings.
    
    @param title string|nil - Title of the chapter (optional)
    @param pages table - Array of content strings (text or HTML)
    @return table - Chapter object with header and elements array
]]
local function CreateChapter(title, pages)
    local chapter = {elements = {}}

    if (title ~= nil and title ~= "") then
        chapter.header = {
            templateKey = private.constants.bookTemplateKeys.CHAPTER_HEADER,
            text = title
        }
    end

    for key, text in pairs(pages) do
        if StringUtils and StringUtils.ContainsHTML and StringUtils.ContainsHTML(text) then
            table.insert(
                chapter.elements,
                {
                    templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                    text = StringUtils.CleanHTML and StringUtils.CleanHTML(text) or text
                }
            )
        else
            -- transform text => adjust line to width
            -- then for each line add itemEntry
            local lines
            if StringUtils and StringUtils.SplitTextToFitWidth then
                lines = StringUtils.SplitTextToFitWidth(text, private.constants.viewWidth)
            else
                -- Fallback: treat as single line
                lines = {text}
            end

            for i, value in ipairs(lines) do
                local line = {
                    templateKey = private.constants.bookTemplateKeys.TEXT_CONTENT,
                    text = value
                }

                table.insert(chapter.elements, line)
            end
        end
    end

    return chapter
end

--[[
    Generic function to transform any entity (event, character, faction) into a book format
    Creates either a cover page or title page based on available data.
    
    @param entity table - The entity object (event/character/faction)
    @return table - Book representation of the entity
]]
function private.Core.Utils.BookUtils.TransformEntityToBook(entity)
    if not entity then
        return {}
    end

    local data = {}

    -- Determine if we should create a cover page or title page
    local shouldUseCoverPage =
        (entity.description and entity.description ~= "") or (entity.image and entity.image ~= "")

    if shouldUseCoverPage then
        -- Create cover page as a direct element, not with header/elements structure
        local coverPage = CreateCoverPage(entity)
        table.insert(data, {
            elements = { coverPage }
        })
    else
        -- Create traditional title page as a direct element, not with header/elements structure
        local titleTemplateKey = private.constants.bookTemplateKeys.SIMPLE_TITLE
        if entity.yearStart or entity.yearEnd then
            titleTemplateKey = private.constants.bookTemplateKeys.EVENT_TITLE
        end

        local titleElement = {
            templateKey = titleTemplateKey,
            text = entity.name or entity.label or "Unknown Entity",
            yearStart = entity.yearStart,
            yearEnd = entity.yearEnd,
            author = entity.author and (Locale["Author"] .. entity.author) or nil
        }

        table.insert(data, {
            elements = { titleElement }
        })
    end

    -- Process chapters if available (same as before)
    if entity.chapters and #entity.chapters > 0 then
        for key, chapter in pairs(entity.chapters) do
            local bookChapter = CreateChapter(chapter.header, chapter.pages)
            table.insert(data, bookChapter)
        end
    end

    return data
end

--[[
    Convenience function for transforming events to books
    @param event table - Event object
    @return table - Book representation
]]
function private.Core.Utils.BookUtils.TransformEventToBook(event)
    return private.Core.Utils.BookUtils.TransformEntityToBook(event)
end

--[[
    Convenience function for transforming characters to books
    @param character table - Character object
    @return table - Book representation
]]
function private.Core.Utils.BookUtils.TransformCharacterToBook(character)
    return private.Core.Utils.BookUtils.TransformEntityToBook(character)
end

--[[
    Convenience function for transforming factions to books
    @param faction table - Faction object
    @return table - Book representation
]]
function private.Core.Utils.BookUtils.TransformFactionToBook(faction)
    return private.Core.Utils.BookUtils.TransformEntityToBook(faction)
end
