local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

--[[
=================================================================================
Module: Events
Purpose: Event domain helpers for the Chronicles timeline
Dependencies: ContentUtils (via private.Core.Utils), Chronicles.Data facade
Author: Chronicles Team
=================================================================================

This module exposes the event-side domain helpers:
- TransformEventToBook: unified book representation of an event, via ContentUtils
  (used by UI/MainFrameUI.lua)
- FilterEvents: keeps only events whose collection and event type are both
  enabled, sorted by yearStart then order (used by the timeline and event list)

Content processing itself (HTML vs text detection, chapter and page handling,
template key mapping) lives in Core/Utils/ContentUtils.lua, not here.

Searching is not here either: it is Core/Data/SearchEngine.lua's camelCase
searchEvents, reached through the Chronicles.Data:SearchEvents facade proxy. Do
not add a PascalCase Search* to this module -- the facade resolves the camelCase
name only, so it would never be called.

Usage Example:
    local book = private.Core.Events.TransformEventToBook(event)
    local visible = private.Core.Events.FilterEvents(events)
=================================================================================
]]
private.Core.Events = {}

--[[
    Event Data Structure:
    id = [integer]					-- Id of the event
    label = [string]				-- Event name/title
    chapters = { [chapter] }		-- Event chapters/content
    yearStart = [integer]			-- Start year
    yearEnd = [integer]				-- End year
    eventType = [integer]			-- Type/category of event
    timeline = [integer]			-- Timeline ID
    order = [integer]				-- Display order
    characters = { [character] }	-- Associated characters
    factions = { [faction] }		-- Associated factions
    author = [string]				-- Author of the event

    Chapter Data Structure:
    header = [integer]				-- Title of the chapter
    pages = { [string] }			-- Content of the chapter, either text or HTML
]]
--[[
    Transform the event into a unified book (primary method)
    @param event [event] Event object
    @return [table] Unified book representation of the event
]]
function private.Core.Events.TransformEventToBook(event)
    if not event then
        return nil
    end

    if not private.Core.Utils.ContentUtils then
        error("TransformEventToBook: ContentUtils not loaded")
    end
    
    if not private.Core.Utils.ContentUtils.TransformEntityToBook then
        error("TransformEventToBook: ContentUtils.TransformEntityToBook not available")
    end

    local result = private.Core.Utils.ContentUtils.TransformEntityToBook(event)
    return result
end

--[[
    Check the status of each event group and type status
	If both are true, add the event to the list
	Sort the list by yearStart and order
	@param events { [event] }
--]]
function private.Core.Events.FilterEvents(events)
    local foundEvents = {}
    for eventIndex in pairs(events) do
        local event = events[eventIndex]

        local eventGroupStatus = Chronicles.Data:GetCollectionStatus(event.source)
        local eventTypeStatus = Chronicles.Data:GetEventTypeStatus(event.eventType)

        if eventGroupStatus and eventTypeStatus then
            table.insert(foundEvents, event)
        end
    end

    table.sort(
        foundEvents,
        function(a, b)
            if (a.yearStart == b.yearStart) then
                return a.order < b.order
            end
            return a.yearStart < b.yearStart
        end
    )
    return foundEvents
end

