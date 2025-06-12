--[[
    Chronicles DataRegistry Module
    
    Handles database registration and collection status management functionality.
    
    RESPONSIBILITIES:
    - Database registration (Events, Factions, Characters)
    - Collection status management (Get/Set collection status)
    - Collection enumeration and state management
    - Cross-database status synchronization
--]]
local FOLDER_NAME, private = ...

-- Initialize DataRegistry module with proper namespace creation
if not private.Core then
    private.Core = {}
end
if not private.Core.Data then
    private.Core.Data = {}
end
private.Core.Data.DataRegistry = {}
local DataRegistry = private.Core.Data.DataRegistry

-- -------------------------
-- Database Registration Operations
-- -------------------------

--[[
    Register an Events database for a collection
    @param collectionName [string] Name of the collection/plugin
    @param db [table] Events database to register
    @return [boolean] Success status
]]
function DataRegistry.registerEventDB(collectionName, db)
    local chronicles = private.Chronicles
    if not chronicles or not chronicles.Data then
        return false
    end

    if not collectionName or type(collectionName) ~= "string" or collectionName == "" then
        return false
    end

    if chronicles.Data.Events[collectionName] ~= nil then
        return false
    end

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    local isActive = private.Core.StateManager.getState(collectionKey)

    -- Only set default value if no saved state exists
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        isActive = true
        private.Core.StateManager.setState(
            collectionKey,
            isActive,
            "Collection status initialization: " .. collectionName
        )
    end

    chronicles.Data.Events[collectionName] = {
        data = db or {},
        name = collectionName
    }

    private.Core.Cache.invalidate(private.Core.Cache.KEYS.PERIODS_FILLING)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MIN_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.MAX_EVENT_YEAR)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.COLLECTIONS_NAMES)
    private.Core.Cache.invalidate(private.Core.Cache.KEYS.FILTERED_EVENTS)

    return true
end

--[[
    Register a Factions database for a collection
    @param collectionName [string] Name of the collection/plugin
    @param db [table] Factions database to register
    @return [boolean] Success status
]]
function DataRegistry.registerFactionDB(collectionName, db)
    local chronicles = private.Chronicles
    if not chronicles or not chronicles.Data then
        return false
    end

    if not collectionName or type(collectionName) ~= "string" or collectionName == "" then
        return false
    end

    if chronicles.Data.Factions[collectionName] ~= nil then
        return false
    end

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    local isActive = private.Core.StateManager.getState(collectionKey)
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        isActive = true
        private.Core.StateManager.setState(
            collectionKey,
            isActive,
            "Collection status initialization: " .. collectionName
        )
    end

    chronicles.Data.Factions[collectionName] = {
        data = db,
        name = collectionName
    }

    return true
end

--[[
    Register a Characters database for a collection
    @param collectionName [string] Name of the collection/plugin
    @param db [table] Characters database to register
    @return [boolean] Success status
]]
function DataRegistry.registerCharacterDB(collectionName, db)
    local chronicles = private.Chronicles
    if not chronicles or not chronicles.Data then
        return false
    end
    if not collectionName or type(collectionName) ~= "string" or collectionName == "" then
        return false
    end

    if chronicles.Data.Characters[collectionName] ~= nil then
        return false
    end

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    local isActive = private.Core.StateManager.getState(collectionKey)

    -- Only set default value if no saved state exists
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        isActive = true
        private.Core.StateManager.setState(
            collectionKey,
            isActive,
            "Collection status initialization: " .. collectionName
        )
    end

    chronicles.Data.Characters[collectionName] = {
        data = db,
        name = collectionName
    }

    return true
end

-- -------------------------
-- Collection Status Management
-- -------------------------

--[[
    Get the status of a collection (whether it's active/enabled)
    @param collectionName [string] Name of the collection
    @return [boolean] Collection status (true if active)
]]
function DataRegistry.getCollectionStatus(collectionName) -- Ensure Chronicles.Data is initialized
    local chronicles = private.Chronicles
    if not chronicles or not chronicles.Data then
        return false
    end

    if not collectionName or type(collectionName) ~= "string" or collectionName == "" then
        return false
    end

    local collectionKey = private.Core.StateManager.buildCollectionKey(collectionName)
    local isActive = private.Core.StateManager.getState(collectionKey)

    if isActive ~= nil and isActive then
        return true
    end

    return false
end

-- -------------------------
-- Collection Enumeration and Utilities
-- -------------------------

--[[
    Helper function to check if a value exists in a lookup table
    @param value [string] Value to search for
    @param lookUpTable [table] Table to search in
    @return [boolean] True if value exists in table
]]
local function existInTable(value, lookUpTable)
    for key, item in pairs(lookUpTable) do
        if (item.name == value) then
            return true
        end
    end
    return false
end

--[[
    Get a list of all registered collections with their status
    @return [table] Array of collection information objects
]]
function DataRegistry.getCollectionsNames()
    local chronicles = private.Chronicles
    if not chronicles or not chronicles.Data then
        return {}
    end
    local dataGroups = {}
    for eventCollectionName, group in pairs(chronicles.Data.Events) do
        if (eventCollectionName ~= "myjournal") then
            if eventCollectionName and type(eventCollectionName) == "string" and eventCollectionName ~= "" then
                local collectionKey = private.Core.StateManager.buildCollectionKey(eventCollectionName)
                local isActive = private.Core.StateManager.getState(collectionKey)
                if isActive == nil then
                    isActive = true
                end

                local groupProjection = {
                    name = group.name,
                    isActive = isActive
                }

                if not existInTable(eventCollectionName, dataGroups) then
                    table.insert(dataGroups, groupProjection)
                end
            end
        end
    end

    for factionCollectionName, group in pairs(chronicles.Data.Factions) do
        if (factionCollectionName ~= "myjournal") then
            if factionCollectionName and type(factionCollectionName) == "string" and factionCollectionName ~= "" then
                local collectionKey = private.Core.StateManager.buildCollectionKey(factionCollectionName)
                local isActive = private.Core.StateManager.getState(collectionKey)
                if isActive == nil then
                    isActive = true
                end
                local groupProjection = {
                    name = group.name,
                    isActive = isActive
                }
                if not existInTable(factionCollectionName, dataGroups) then
                    table.insert(dataGroups, groupProjection)
                end
            end
        end
    end

    for characterCollectionName, group in pairs(chronicles.Data.Characters) do
        if (characterCollectionName ~= "myjournal") then
            if characterCollectionName and type(characterCollectionName) == "string" and characterCollectionName ~= "" then
                local collectionKey = private.Core.StateManager.buildCollectionKey(characterCollectionName)
                local isActive = private.Core.StateManager.getState(collectionKey)
                if isActive == nil then
                    isActive = true
                end
                local groupProjection = {
                    name = group.name,
                    isActive = isActive
                }

                if not existInTable(characterCollectionName, dataGroups) then
                    table.insert(dataGroups, groupProjection)
                end
            end
        end
    end

    return dataGroups
end

-- -------------------------
-- Module Export
-- -------------------------

-- Expose the DataRegistry module for use by other components
return DataRegistry
