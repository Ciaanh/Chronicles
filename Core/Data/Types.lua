--[[
    Types.lua - Centralized type definitions and validators for Chronicles addon
    
    This module contains all data structure definitions and validation functions
    for events, characters, factions, and related objects used throughout the
    Chronicles addon.
--]]
local private = ...

-- Create the Types module if it doesn't exist
if not private.Core.Data then
    private.Core.Data = {}
end

private.Core.Data.Types = {}

-- -------------------------
-- TYPE DEFINITIONS
-- -------------------------

--[[
    Event Data Structure:
    {
        id = [integer]                  -- Unique identifier for the event
        label = [string]                -- Event name/title
        chapters = { [chapter] }        -- Event chapters/content (array of chapter objects)
        yearStart = [integer]           -- Start year of the event
        yearEnd = [integer]             -- End year of the event
        eventType = [integer]           -- Type/category of event
        timeline = [integer]            -- Timeline ID this event belongs to
        order = [integer]               -- Display order in timeline
        characters = { [character] }    -- Associated characters (array of character objects)
        factions = { [faction] }        -- Associated factions (array of faction objects)
        author = [string]               -- Author of the event entry
    }
--]]
--[[
    Character Data Structure:
    {
        id = [integer]                      -- Unique identifier for the character
        name = [string]                     -- Character name
        chapters = { [chapter] }            -- Character chapters/content (array of chapter objects)
        timeline = [integer]                -- Timeline ID this character belongs to
        factions = { [faction] }            -- Associated factions (array of faction objects)
        author = [string]                   -- Author of the character entry
        description = [string]              -- Character description
        image = [string]                    -- Character portrait/image path
    }
--]]
--[[
    Faction Data Structure:
    {
        id = [integer]              -- Unique identifier for the faction
        name = [string]             -- Faction name
        chapters = { [chapter] }    -- Faction chapters/content (array of chapter objects)
        timeline = [integer]        -- Timeline ID this faction belongs to
        author = [string]           -- Author of the faction entry
        description = [string]      -- Faction description
        image = [string]            -- Faction image/crest path
    }
--]]
--[[
    Chapter Data Structure:
    {
        header = [integer]          -- Title/header identifier for the chapter
        pages = { [string] }        -- Content of the chapter (array of strings, text or HTML)
    }
--]]
--[[
    Timeline Period Data Structure:
    {
        lower = [integer]           -- Lower bound of the period (year)
        upper = [integer]           -- Upper bound of the period (year)
        label = [string]            -- Period label/name (optional)
        description = [string]      -- Period description (optional)
    }
--]]
-- -------------------------
-- VALIDATION FUNCTIONS
-- -------------------------

local Types = private.Core.Data.Types

--[[
    Check if an event object has all required fields and valid data
    @param event [table] Event object to validate
    @return [boolean] True if event is valid
    @return [string] Error message if validation fails (optional)
--]]
function Types.IsValidEvent(event)
    if type(event) ~= "table" then
        return false, "Event must be a table"
    end

    -- Check required fields
    if type(event.id) ~= "number" then
        return false, "Event ID must be a number"
    end

    if type(event.label) ~= "string" or event.label == "" then
        return false, "Event label must be a non-empty string"
    end

    if type(event.yearStart) ~= "number" then
        return false, "Event yearStart must be a number"
    end

    if type(event.yearEnd) ~= "number" then
        return false, "Event yearEnd must be a number"
    end

    if event.yearStart > event.yearEnd then
        return false, "Event yearStart cannot be greater than yearEnd"
    end

    if event.chapters and type(event.chapters) ~= "table" then
        return false, "Event chapters must be an array"
    end

    if event.eventType and type(event.eventType) ~= "number" then
        return false, "Event eventType must be a number"
    end

    if event.timeline and type(event.timeline) ~= "number" then
        return false, "Event timeline must be a number"
    end

    if event.order and type(event.order) ~= "number" then
        return false, "Event order must be a number"
    end

    if event.characters and type(event.characters) ~= "table" then
        return false, "Event characters must be an array"
    end

    if event.factions and type(event.factions) ~= "table" then
        return false, "Event factions must be an array"
    end

    if event.author and type(event.author) ~= "string" then
        return false, "Event author must be a string"
    end

    return true, nil
end

--[[
    Check if a character object has all required fields and valid data
    @param character [table] Character object to validate
    @return [boolean] True if character is valid
    @return [string] Error message if validation fails (optional)
--]]
function Types.IsValidCharacter(character)
    if type(character) ~= "table" then
        return false, "Character must be a table"
    end

    -- Check required fields
    if type(character.id) ~= "number" then
        return false, "Character ID must be a number"
    end

    if type(character.name) ~= "string" or character.name == "" then
        return false, "Character name must be a non-empty string"
    end

    if character.chapters and type(character.chapters) ~= "table" then
        return false, "Character chapters must be an array"
    end

    if character.timeline and type(character.timeline) ~= "number" then
        return false, "Character timeline must be a number"
    end

    if character.factions and type(character.factions) ~= "table" then
        return false, "Character factions must be an array"
    end

    if character.author and type(character.author) ~= "string" then
        return false, "Character author must be a string"
    end

    if character.description and type(character.description) ~= "string" then
        return false, "Character description must be a string"
    end

    if character.image and type(character.image) ~= "string" then
        return false, "Character image must be a string"
    end

    return true, nil
end

--[[
    Check if a faction object has all required fields and valid data
    @param faction [table] Faction object to validate
    @return [boolean] True if faction is valid
    @return [string] Error message if validation fails (optional)
--]]
function Types.IsValidFaction(faction)
    if type(faction) ~= "table" then
        return false, "Faction must be a table"
    end

    -- Check required fields
    if type(faction.id) ~= "number" then
        return false, "Faction ID must be a number"
    end

    if type(faction.name) ~= "string" or faction.name == "" then
        return false, "Faction name must be a non-empty string"
    end

    -- Validate optional fields if present
    if faction.chapters and type(faction.chapters) ~= "table" then
        return false, "Faction chapters must be an array"
    end

    if faction.timeline and type(faction.timeline) ~= "number" then
        return false, "Faction timeline must be a number"
    end

    if faction.author and type(faction.author) ~= "string" then
        return false, "Faction author must be a string"
    end

    if faction.description and type(faction.description) ~= "string" then
        return false, "Faction description must be a string"
    end

    if faction.image and type(faction.image) ~= "string" then
        return false, "Faction image must be a string"
    end

    return true, nil
end

--[[
    Check if a chapter object has valid structure
    @param chapter [table] Chapter object to validate
    @return [boolean] True if chapter is valid
    @return [string] Error message if validation fails (optional)
--]]
function Types.IsValidChapter(chapter)
    if type(chapter) ~= "table" then
        return false, "Chapter must be a table"
    end

    if type(chapter.header) ~= "number" then
        return false, "Chapter header must be a number"
    end

    if type(chapter.pages) ~= "table" then
        return false, "Chapter pages must be an array of strings"
    end

    -- Validate that pages array contains only strings
    for i, page in ipairs(chapter.pages) do
        if type(page) ~= "string" then
            return false, "Chapter page " .. i .. " must be a string"
        end
    end

    return true, nil
end

--[[
    Check if a timeline period object has valid structure
    @param period [table] Timeline period object to validate
    @return [boolean] True if period is valid
    @return [string] Error message if validation fails (optional)
--]]
function Types.IsValidTimelinePeriod(period)
    if type(period) ~= "table" then
        return false, "Timeline period must be a table"
    end

    if type(period.lower) ~= "number" then
        return false, "Timeline period lower bound must be a number"
    end

    if type(period.upper) ~= "number" then
        return false, "Timeline period upper bound must be a number"
    end

    if period.lower > period.upper then
        return false, "Timeline period lower bound cannot be greater than upper bound"
    end

    if period.label and type(period.label) ~= "string" then
        return false, "Timeline period label must be a string"
    end

    if period.description and type(period.description) ~= "string" then
        return false, "Timeline period description must be a string"
    end

    return true, nil
end

-- -------------------------
-- UTILITY FUNCTIONS
-- -------------------------

--[[
    Check if a value is a valid year (reasonable range for the game universe)
    @param year [number] Year to validate
    @return [boolean] True if year is valid
--]]
function Types.IsValidYear(year)
    if type(year) ~= "number" then
        return false
    end

    -- Reasonable year range for Warcraft universe (adjust as needed)
    -- Negative years for "before" events, positive for "after"
    return year >= -50000 and year <= 50000
end

--[[
    Check if a value is a valid ID (positive integer)
    @param id [number] ID to validate
    @return [boolean] True if ID is valid
--]]
function Types.IsValidId(id)
    return type(id) == "number" and id > 0 and math.floor(id) == id
end

--[[
    Check if a value is a non-empty string
    @param str [string] String to validate
    @return [boolean] True if string is valid
--]]
function Types.IsValidString(str)
    return type(str) == "string" and str ~= ""
end

--[[
    Check if a value is a valid table/array
    @param tbl [table] Table to validate
    @return [boolean] True if table is valid
--]]
function Types.IsValidTable(tbl)
    return type(tbl) == "table"
end

-- -------------------------
-- EVENT SCHEMA VALIDATION (for EventManager compatibility)
-- -------------------------

--[[
    Validate event data according to specific event schemas
    @param eventType [string] Type of event from constants
    @param data [table] Event data to validate
    @return [boolean] True if data is valid for the event type
    @return [string] Error message if validation fails (optional)
--]]
function Types.ValidateEventSchema(eventType, data)
    if not eventType or not data then
        return false, "Event type and data are required"
    end

    -- Event-specific validation based on Chronicles event constants
    if eventType == "AddonStartup" then
        if not data.version or not data.timestamp then
            return false, "AddonStartup event requires version and timestamp"
        end
    end

    return true, nil
end

-- Make the module accessible
return private.Core.Data.Types
