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

    This is a layout constraint, not a data one. The front matter shares a fixed 500x520 view with the
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
    Resolve cross-referenced ids into display names.

    Ids that resolve to nothing are skipped rather than rendered as a placeholder: a disabled
    collection legitimately yields no names, and "Unknown" repeated three times is worse than a shorter
    list.

    @param refs [table|nil] Either {[collectionName] = {id, ...}} or a flat {id, ...}
    @param kind [string] "character" or "faction", selecting the finder
    @param fallbackCollection [string|nil] Collection for the flat shape, normally entity.source
    @return [table|nil] Sequential array of names capped at MAX_NAMES, nil when there is nothing to show
    @return [number] How many further names were omitted by the cap
]]
function FrontMatter.ResolveNames(refs, kind, fallbackCollection)
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

    local names = {}

    local function resolveOne(id, collectionName)
        if type(id) ~= "number" or not collectionName then
            return
        end

        -- Every id is resolved even past the cap, rather than stopping at MAX_NAMES: the "+ N more"
        -- count has to describe names the reader would recognise, and ids that resolve to nothing
        -- (a disabled collection, a stale reference) are not among them.
        local record = data[finderName](data, id, FrontMatter.NormaliseCollectionName(collectionName))
        if record and record.name and record.name ~= "" then
            table.insert(names, record.name)
        end
    end

    if isFlatIdArray(refs) then
        for _, id in ipairs(refs) do
            resolveOne(id, fallbackCollection)
        end
    else
        -- pairs, so the iteration order across collections is undefined. Sorting the ids inside each
        -- collection is not enough to make the whole list stable, and the alternative is sorting the
        -- resolved names, which is what happens below.
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

    if #names == 0 then
        return nil, 0
    end

    -- Alphabetical, so the same event reads the same way on every render. pairs() over the collection
    -- keys above gives no order at all, and a list that reshuffles between openings looks like a bug.
    -- Sorting before the cap also makes *which* names survive truncation deterministic.
    table.sort(names)

    local omitted = 0
    if #names > MAX_NAMES then
        omitted = #names - MAX_NAMES
        for index = #names, MAX_NAMES + 1, -1 do
            names[index] = nil
        end
    end

    return names, omitted
end

return FrontMatter
