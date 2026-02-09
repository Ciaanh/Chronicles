---@meta
-- Chronicles Domain Types
-- This file contains type definitions for the Chronicles addon domain objects
-- These match the actual data structures used throughout the addon

---@class ChroniclesEvent
---@field id number Unique identifier for the event
---@field label string Event name/title
---@field chapters ChroniclesChapter[] Event chapters/content (array of chapter objects)
---@field yearStart number Start year of the event
---@field yearEnd number End year of the event
---@field eventType number Type/category of event
---@field timeline number|nil Timeline ID this event belongs to
---@field order number|nil Display order in timeline
---@field characters table|nil Associated characters (array of character objects)
---@field factions table|nil Associated factions (array of faction objects)
---@field author string|nil Author of the event entry
---@field source string|nil Source collection name

---@class ChroniclesCharacter
---@field id number Unique identifier for the character
---@field name string Character name
---@field chapters ChroniclesChapter[] Character chapters/content (array of chapter objects)
---@field timeline number|nil Timeline ID this character belongs to
---@field factions table|nil Associated factions (array of faction objects)
---@field author string|nil Author of the character entry
---@field description string|nil Character description
---@field image string|nil Character portrait/image path
---@field source string|nil Source collection name

---@class ChroniclesFaction
---@field id number Unique identifier for the faction
---@field name string Faction name
---@field chapters ChroniclesChapter[]|nil Faction chapters/content (array of chapter objects)
---@field timeline number|nil Timeline ID this faction belongs to
---@field author string|nil Author of the faction entry
---@field description string|nil Faction description
---@field image string|nil Faction image/crest path
---@field source string|nil Source collection name

---@class ChroniclesChapter
---@field header number|string Chapter header/title identifier
---@field pages string[] Content of the chapter (array of strings, text or HTML)

---@class ChroniclesTimelinePeriod
---@field lower number Lower bound of the period (year)
---@field upper number Upper bound of the period (year)
---@field text string|nil Period label/name (optional)
---@field hasEvents boolean Whether this period contains events
---@field nbEvents number Number of events in this period

---@class ChroniclesTimelineConfig
---@field isOverlapping boolean Whether timeline crosses year 0
---@field pastEvents boolean Whether there are events before historyStartYear
---@field futurEvents boolean Whether there are events after currentYear
---@field before number Number of periods before year 0
---@field after number Number of periods after year 0
---@field minYear number Minimum year in timeline
---@field maxYear number Maximum year in timeline
---@field numberOfTimelineBlock number Total number of timeline blocks

-- Global type aliases for commonly used types
---@alias ChroniclesEventId number
---@alias ChroniclesCharacterId number
---@alias ChroniclesFactionId number
---@alias ChroniclesYear number
