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
    @return [table] New book format with single HTML content element
]]
function ContentUtils.TransformEntityToBook(entity, options)
    print("ContentUtils.TransformEntityToBook called with entity:", entity and entity.name or "nil")
    if not entity then
        print("ContentUtils: No entity provided")
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

    -- Generate complete HTML content using HTMLBuilder
    local htmlContent = HTMLBuilder.CreateEntityHTML(entity, options)
    local title = entity.name or entity.label or "Chronicles Content"

    -- Return array of section objects, each with an elements array
    local result = {
        {
            elements = {
                {
                    templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                    htmlContent = htmlContent, -- Use 'htmlContent' property for HTMLContentMixin
                    title = title,
                    entity = entity -- Keep reference for debugging/future use
                }
            }
        }
    }

    print("ContentUtils: Returning result with section count:", #result)
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

-- =============================================================================================
-- DEBUGGING AND TESTING UTILITIES
-- =============================================================================================

--[[
    Create a test entity for development purposes
    @param entityType [string] Type of entity to create ("event", "character", "faction")
    @return [table] Test entity data
]]
function ContentUtils.CreateTestEntity(entityType)
    entityType = entityType or "character"

    local testEntities = {
        character = {
            id = 1,
            name = "Tyrande Whisperwind",
            description = "High Priestess of Elune and leader of the night elves. Tyrande has guided her people through countless trials, from the War of the Ancients to the modern conflicts of Azeroth.",
            image = "Interface/AddOns/Chronicles/Art/Portrait/Tyrande.tga",
            author = "Chronicles Team",
            timeline = 1,
            chapters = {
                {
                    header = "Early Life",
                    pages = {
                        "Born in the ancient city of Suramar, Tyrande showed an affinity for the goddess Elune from an early age.",
                        "She trained as a priestess in the Temple of Elune, learning the sacred arts of her people.",
                        "During her youth, she formed close bonds with Malfurion Stormrage and his brother Illidan."
                    }
                },
                {
                    header = "War of the Ancients",
                    pages = {
                        "When the Burning Legion first invaded Azeroth, Tyrande stood alongside the resistance.",
                        "She fought bravely in the War of the Ancients, helping to prevent the world's destruction.",
                        "Her courage and faith in Elune proved instrumental in the Legion's defeat."
                    }
                },
                {
                    header = "Leader of the Kaldorei",
                    pages = {
                        "After the war, Tyrande became the High Priestess and leader of the night elf people.",
                        "She guided them through the long vigil, watching over the World Tree Nordrassil.",
                        "Her wisdom and strength have been a beacon for her people through dark times."
                    }
                }
            }
        },
        event = {
            id = 1,
            name = "The War of the Ancients",
            label = "War of the Ancients",
            yearStart = -10000,
            yearEnd = -9500,
            author = "Chronicles Team",
            timeline = 1,
            eventType = 3,
            description = "The first invasion of the Burning Legion, a cataclysmic war that reshaped Azeroth forever.",
            chapters = {
                {
                    header = "The Legion's Arrival",
                    pages = {
                        "Queen Azshara and her Highborne opened a portal for the Burning Legion.",
                        "Demons poured through the portal, beginning their assault on Azeroth.",
                        "The kaldorei empire was caught unprepared for this otherworldly threat."
                    }
                },
                {
                    header = "The Resistance Forms",
                    pages = {
                        "Malfurion Stormrage learned druidism from Cenarius to fight the Legion.",
                        "Tyrande Whisperwind led the priestesses of Elune in battle.",
                        "Unlikely alliances formed between different races to face the common threat."
                    }
                }
            }
        },
        faction = {
            id = 1,
            name = "Darnassus",
            description = "The great tree city of the night elves, serving as their capital and spiritual center. Built upon Teldrassil, it represents the rebirth of night elf civilization.",
            image = "Interface/AddOns/Chronicles/Art/Images/NightElfCrest.tga",
            author = "Chronicles Team",
            timeline = 1,
            chapters = {
                {
                    header = "Foundation",
                    pages = {
                        "After the destruction of Mount Hyjal's World Tree, the night elves needed a new home.",
                        "Fandral Staghelm proposed growing a new World Tree, despite concerns from other druids.",
                        "Teldrassil was grown, and upon it the great city of Darnassus was built."
                    }
                },
                {
                    header = "Architecture and Design",
                    pages = {
                        "The city was carved into the living wood of Teldrassil itself.",
                        "Great branches form the roads and platforms of the city.",
                        "The Temple of the Moon stands as the spiritual heart of Darnassus."
                    }
                }
            }
        }
    }

    return testEntities[entityType] or testEntities.character
end

--[[
    Generate a test HTML book for development
    @param entityType [string] Type of entity to test
    @return [table] New book format with test content
]]
function ContentUtils.CreateTestBook(entityType)
    local testEntity = ContentUtils.CreateTestEntity(entityType)
    return ContentUtils.TransformEntityToBook(testEntity)
end

return ContentUtils
