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
function DataRegistry.registerEventDB(collectionName, db) -- Ensure Chronicles.Data is initialized
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. collectionName
        )
        return false
    end

    if chronicles.Data.Events[collectionName] ~= nil then
        private.Core.Logger.error("DataRegistry", collectionName .. " is already registered by another plugin in Events.")
        return false
    end
    if db == nil then
        private.Core.Logger.warn(
            "DataRegistry",
            "Collection '" .. collectionName .. "' is trying to register a nil events database."
        )
    end -- Use StateManager path for status management
    local dbTypePath = "collections." .. collectionName
    local isActive = private.Core.StateManager.getState(dbTypePath)

    -- Only set default value if no saved state exists
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        -- Check if StateManager has loaded saved state - if so, respect the absence of this collection
        -- (it might have been disabled and removed from saved state)
        if private.Core.StateManager.isStateLoaded() then
            -- StateManager has loaded, so absence means this collection is new or was removed
            -- For new collections after initial setup, default to true
            isActive = true
        else
            -- StateManager hasn't loaded yet, default to true for first-time initialization
            isActive = true
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Collection status initialization: " .. collectionName)
    end

    chronicles.Data.Events[collectionName] = {
        data = db or {}, -- Ensure data is never nil
        name = collectionName
    }

    -- Invalidate caches since we registered new event data
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("minEventYear")
    private.Core.Cache.invalidate("maxEventYear")
    private.Core.Cache.invalidate("collectionsNames")
    private.Core.Cache.invalidate("searchCache")

    return true
end

--[[
    Register a Factions database for a collection
    @param collectionName [string] Name of the collection/plugin
    @param db [table] Factions database to register
    @return [boolean] Success status
]]
function DataRegistry.registerFactionDB(collectionName, db)
    -- Ensure Chronicles.Data is initialized
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. collectionName
        )
        return false
    end
    if chronicles.Data.Factions[collectionName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            collectionName .. " is already registered by another plugin in Factions."
        )
        return false
    end
    -- Use StateManager path for status management
    local dbTypePath = "collections." .. collectionName
    local isActive = private.Core.StateManager.getState(dbTypePath)

    -- Only set default value if no saved state exists
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        if private.Core.StateManager.isStateLoaded() then
            isActive = true -- New collection after initial setup
        else
            isActive = true -- First-time initialization
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Collection status initialization: " .. collectionName)
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
    -- Ensure Chronicles.Data is initialized
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. collectionName
        )
        return false
    end
    if chronicles.Data.Characters[collectionName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            collectionName .. " is already registered by another plugin in Characters."
        )
        return false
    end -- Use StateManager path for status management
    local dbTypePath = "collections." .. collectionName
    local isActive = private.Core.StateManager.getState(dbTypePath)

    -- Only set default value if no saved state exists
    -- If the collection status is already set (either from saved state or previous registration), don't overwrite it
    if (isActive == nil) then
        if private.Core.StateManager.isStateLoaded() then
            isActive = true -- New collection after initial setup
        else
            isActive = true -- First-time initialization
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Collection status initialization: " .. collectionName)
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
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to get collection status for " .. collectionName
        )
        return false
    end

    local dbTypePath = "collections." .. collectionName
    local isActive = private.Core.StateManager.getState(dbTypePath)

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
    -- Ensure Chronicles.Data is initialized
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.Data then
        private.Core.Logger.error("DataRegistry", "Chronicles.Data not initialized when trying to get collections names")
        return {}
    end

    local dataGroups = {} -- Process Events collections using StateManager paths
    for eventCollectionName, group in pairs(chronicles.Data.Events) do
        if (eventCollectionName ~= "myjournal") then
            local dbTypePath = "collections." .. eventCollectionName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New collection after initial setup
                else
                    isActive = true -- First-time initialization
                end
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
    -- Process Factions collections using StateManager paths
    for factionCollectionName, group in pairs(chronicles.Data.Factions) do
        if (factionCollectionName ~= "myjournal") then
            local dbTypePath = "collections." .. factionCollectionName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New collection after initial setup
                else
                    isActive = true -- First-time initialization
                end
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
    -- Process Characters collections using StateManager paths
    for characterCollectionName, group in pairs(chronicles.Data.Characters) do
        if (characterCollectionName ~= "myjournal") then
            local dbTypePath = "collections." .. characterCollectionName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New collection after initial setup
                else
                    isActive = true -- First-time initialization
                end
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

    return dataGroups
end

-- -------------------------
-- Module Export
-- -------------------------

-- Expose the DataRegistry module for use by other components
return DataRegistry
