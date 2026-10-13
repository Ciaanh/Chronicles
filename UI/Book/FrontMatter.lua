--[[
    FrontMatter.lua

    Resolves the cross-references an entity carries into display names for the book's front matter.

    Records store relationships as numeric ids only, never names, and they store them in two different
    shapes:

        event.characters   = {["dragonflight"] = {79, 81, 82}}   -- keyed by collection
        event.factions     = {["dragonflight"] = {57, 58, 59}}
        character.factions = {57}                                -- flat; the collection is entity.source

    so resolving them means a lookup per id against the right collection, and handling both shapes.

    The collection keys in cross-references are lowercase while collections register capitalised
    ("dragonflight" against RegisterEventDB("Dragonflight", ...)). Both GetCollectionStatus and the
    Data.Characters[collectionName] index are case-sensitive, so the naive lookup returns nil for every
    reference in the shipped data. NormaliseCollectionName is what bridges that; the durable fix is for
    the generator (Chronicles-tauri, src/app/addon/services/dbService.ts) to emit the registered name in
    cross-reference keys, after which this normalisation becomes a harmless no-op instead of the only
    thing making the lookups work.
]]
local FOLDER_NAME, private = ...

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.FrontMatter = {}
local FrontMatter = private.Core.Utils.FrontMatter

--[[
    How many names a list renders before it truncates.

    This is a layout constraint, not a data one. The front matter shares a fixed 500x510 view with the
    title, metadata and contents list; a document taller than the view pushes the body text onto the
    next page, so the reader clicks a contents row and lands on front matter with no prose. Nothing in
    the data model bounds the reference count (today's widest event has 3), so the cap is here.
]]
local MAX_NAMES = 8

-- =============================================================================================
-- COLLECTION NAME NORMALISATION
-- =============================================================================================

--[[
    Map a cross-reference's collection key onto the name that collection actually registered under.

    Deliberately not cached: plugins register collections after login through
    Chronicles:RegisterPluginDB, so a map built once at load would miss them, and a book render happens
    only when the reader selects something. Fifteen string comparisons per list is not worth the
    staleness risk.

    @param collectionName [string] Collection key as written in the cross-reference
    @return [string] The registered collection name, or collectionName unchanged if no match
]]
function FrontMatter.NormaliseCollectionName(collectionName)
    if type(collectionName) ~= "string" or collectionName == "" then
        return collectionName
    end

    local chronicles = private.Core.Utils.HelperUtils and private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data or not chronicles.Data.GetCollectionsNames then
        return collectionName
    end

    local registered = chronicles.Data:GetCollectionsNames()
    if type(registered) ~= "table" then
        return collectionName
    end

    local wanted = string.lower(collectionName)
    for _, collection in ipairs(registered) do
        if collection and type(collection.name) == "string" and string.lower(collection.name) == wanted then
            return collection.name
        end
    end

    return collectionName
end

-- =============================================================================================
-- NAME RESOLUTION
-- =============================================================================================

local FINDERS = {
    character = "FindCharacterByIdAndCollection",
    faction = "FindFactionByIdAndCollection"
}

--[[
    Is this a flat array of ids rather than a collection-keyed table?

    An empty table answers true and resolves to nothing either way, so the ambiguity is harmless.
]]
local function isFlatIdArray(refs)
    for key, value in pairs(refs) do
        if type(key) ~= "number" or type(value) ~= "number" then
            return false
        end
    end

    return true
end

--[[
    Resolve cross-referenced ids into the records they name.

    Ids that resolve to nothing are skipped rather than rendered as a placeholder: a disabled
    collection legitimately yields no names, and "Unknown" repeated three times is worse than a shorter
    list.

    Each entry keeps the id and the collection it was found in, normalised to the registered name, so
    the book can turn it into a link that opens that record.

    @param refs [table|nil] Either {[collectionName] = {id, ...}} or a flat {id, ...}
    @param kind [string] "character" or "faction", selecting the finder
    @param fallbackCollection [string|nil] Collection for the flat shape, normally entity.source
    @return [table|nil] Sequential array of {name, id, collection} capped at MAX_NAMES, sorted by name,
                        nil when there is nothing to show
    @return [number] How many further entries were omitted by the cap
]]
function FrontMatter.ResolveEntries(refs, kind, fallbackCollection)
    if type(refs) ~= "table" then
        return nil, 0
    end

    local finderName = FINDERS[kind]
    if not finderName then
        return nil, 0
    end

    local chronicles = private.Core.Utils.HelperUtils and private.Core.Utils.HelperUtils.getChronicles()
    local data = chronicles and chronicles.Data
    if not data or type(data[finderName]) ~= "function" then
        return nil, 0
    end

    local entries = {}

    local function resolveOne(id, collectionName)
        if type(id) ~= "number" or not collectionName then
            return
        end

        -- Every id is resolved even past the cap, rather than stopping at MAX_NAMES: the "+ N more"
        -- count has to describe names the reader would recognise, and ids that resolve to nothing
        -- (a disabled collection, a stale reference) are not among them.
        local registeredName = FrontMatter.NormaliseCollectionName(collectionName)
        local record = data[finderName](data, id, registeredName)
        if record and record.name and record.name ~= "" then
            table.insert(entries, {name = record.name, id = id, collection = registeredName})
        end
    end

    if isFlatIdArray(refs) then
        for _, id in ipairs(refs) do
            resolveOne(id, fallbackCollection)
        end
    else
        -- pairs, so the iteration order across collections is undefined; the sort below is what makes
        -- the list stable.
        for collectionName, ids in pairs(refs) do
            if type(ids) == "table" then
                for _, id in ipairs(ids) do
                    resolveOne(id, collectionName)
                end
            elseif type(ids) == "number" then
                -- A single id written without its array wrapper
                resolveOne(ids, collectionName)
            end
        end
    end

    if #entries == 0 then
        return nil, 0
    end

    -- Alphabetical, so the same event reads the same way on every render, and so *which* names survive
    -- truncation is deterministic. Ties (two records with one name, like Durotan and his alternate-timeline
    -- self when both are named alike) break on collection, then id.
    table.sort(
        entries,
        function(a, b)
            if a.name ~= b.name then
                return a.name < b.name
            end
            if a.collection ~= b.collection then
                return tostring(a.collection) < tostring(b.collection)
            end
            return a.id < b.id
        end
    )

    local omitted = 0
    if #entries > MAX_NAMES then
        omitted = #entries - MAX_NAMES
        for index = #entries, MAX_NAMES + 1, -1 do
            entries[index] = nil
        end
    end

    return entries, omitted
end

--[[
    Resolve cross-referenced ids into display names only.

    Kept for callers that only print names; see ResolveEntries for the contract.

    @return [table|nil] Sequential array of names, nil when there is nothing to show
    @return [number] How many further names were omitted by the cap
]]
function FrontMatter.ResolveNames(refs, kind, fallbackCollection)
    local entries, omitted = FrontMatter.ResolveEntries(refs, kind, fallbackCollection)
    if not entries then
        return nil, 0
    end

    local names = {}
    for index, entry in ipairs(entries) do
        names[index] = entry.name
    end

    return names, omitted
end

-- =============================================================================================
-- RELATED EVENTS
-- =============================================================================================

--[[
    The events on either side of an event in reading order

    @param events [table] Sequential array of events already in reading order (Events.FilterEvents)
    @param event [table] The event being read; matched by id and source, since ids repeat across
                         collections
    @return [table|nil] The previous event, nil at the start or when the event is not in the list
    @return [table|nil] The next event, nil at the end or when the event is not in the list
]]
function FrontMatter.FindEventNeighbours(events, event)
    if type(events) ~= "table" or type(event) ~= "table" then
        return nil, nil
    end

    for index, candidate in ipairs(events) do
        if candidate.id == event.id and candidate.source == event.source then
            return events[index - 1], events[index + 1]
        end
    end

    return nil, nil
end

-- How many "Appears in" lines a character or faction page prints before "+ N more"
local MAX_APPEARANCES = 12

--[[
    The events that reference a character or a faction

    Events key their references by collection, in lowercase in the shipped data, while the record's
    own collection is the registered, capitalised name: the comparison ignores case for that reason.

    @param events [table] Sequential array of events in reading order
    @param kind [string] "character" or "faction", selecting event.characters or event.factions
    @param id [number] The record's id
    @param collection [string] The record's collection (registered name)
    @return [table] Sequential array of events, in the order given, capped at MAX_APPEARANCES
    @return [number] How many further events were omitted by the cap
    @return [number] The total count before the cap
]]
function FrontMatter.FindEventsReferencing(events, kind, id, collection)
    local field = (kind == "character" and "characters") or (kind == "faction" and "factions") or nil
    if type(events) ~= "table" or not field or type(id) ~= "number" or type(collection) ~= "string" then
        return {}, 0, 0
    end

    local wanted = string.lower(collection)
    local found = {}

    for _, event in ipairs(events) do
        local refs = event[field]
        if type(refs) == "table" then
            local matched = false
            for refCollection, ids in pairs(refs) do
                if type(refCollection) == "string" and string.lower(refCollection) == wanted then
                    if type(ids) == "table" then
                        for _, refId in ipairs(ids) do
                            if refId == id then
                                matched = true
                                break
                            end
                        end
                    elseif ids == id then
                        matched = true
                    end
                end
                if matched then
                    break
                end
            end
            if matched then
                table.insert(found, event)
            end
        end
    end

    local total = #found
    local omitted = 0
    if total > MAX_APPEARANCES then
        omitted = total - MAX_APPEARANCES
        for index = total, MAX_APPEARANCES + 1, -1 do
            found[index] = nil
        end
    end

    return found, omitted, total
end

return FrontMatter
