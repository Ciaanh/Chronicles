--[[
    Chronicles DataRegistry Module
    
    Handles database registration and library status management functionality.
    
    RESPONSIBILITIES:
    - Database registration (Events, Factions, Characters)
    - Library status management (Get/Set library status)
    - Library enumeration and state management
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

-- Helper function to safely access Chronicles
local function getChronicles()
    return private.Chronicles
end

-----------------------------------------------------------------------------------------
-- Database Registration Operations ----------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Register an Events database for a library
    @param libraryName [string] Name of the library/plugin
    @param db [table] Events database to register
    @return [boolean] Success status
]]
function DataRegistry.registerEventDB(libraryName, db)
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. libraryName
        )
        return false
    end

    if Chronicles.Data.Events[libraryName] ~= nil then
        private.Core.Logger.error("DataRegistry", libraryName .. " is already registered by another plugin in Events.")
        return false
    end    if db == nil then
        private.Core.Logger.warn(
            "DataRegistry",
            "Library '" .. libraryName .. "' is trying to register a nil events database."
        )
    end 
    
    -- Use StateManager path for status management
    local dbTypePath = "settings.libraries.databases.events." .. libraryName
    local isActive = private.Core.StateManager.getState(dbTypePath)
    
    -- Only set default value if:
    -- 1. No saved state exists AND
    -- 2. StateManager hasn't loaded saved state yet (first-time run)
    if (isActive == nil) then
        -- Check if StateManager has loaded saved state - if so, respect the absence of this library
        -- (it might have been disabled and removed from saved state)
        if private.Core.StateManager.isStateLoaded() then
            -- StateManager has loaded, so absence means this library is new or was removed
            -- For new libraries after initial setup, default to true
            isActive = true
        else
            -- StateManager hasn't loaded yet, default to true for first-time initialization
            isActive = true
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
    end

    Chronicles.Data.Events[libraryName] = {
        data = db or {}, -- Ensure data is never nil
        name = libraryName
    }

    -- Invalidate caches since we registered new event data
    private.Core.Cache.invalidate("periodsFillingBySteps")
    private.Core.Cache.invalidate("minEventYear")
    private.Core.Cache.invalidate("maxEventYear")
    private.Core.Cache.invalidate("librariesNames")
    private.Core.Cache.invalidate("searchCache")

    return true
end

--[[
    Register a Factions database for a library
    @param libraryName [string] Name of the library/plugin
    @param db [table] Factions database to register
    @return [boolean] Success status
]]
function DataRegistry.registerFactionDB(libraryName, db)
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. libraryName
        )
        return false
    end    if Chronicles.Data.Factions[libraryName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            libraryName .. " is already registered by another plugin in Factions."
        )
        return false
    end 
    
    -- Use StateManager path for status management
    local dbTypePath = "settings.libraries.databases.factions." .. libraryName
    local isActive = private.Core.StateManager.getState(dbTypePath)
    
    -- Only set default value if no saved state exists and StateManager hasn't loaded yet
    if (isActive == nil) then
        if private.Core.StateManager.isStateLoaded() then
            isActive = true -- New library after initial setup
        else
            isActive = true -- First-time initialization
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
    end

    Chronicles.Data.Factions[libraryName] = {
        data = db,
        name = libraryName
    }

    return true
end

--[[
    Register a Characters database for a library
    @param libraryName [string] Name of the library/plugin
    @param db [table] Characters database to register
    @return [boolean] Success status
]]
function DataRegistry.registerCharacterDB(libraryName, db)
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to register " .. libraryName
        )
        return false
    end    if Chronicles.Data.Characters[libraryName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            libraryName .. " is already registered by another plugin in Characters."
        )
        return false
    end 
    
    -- Use StateManager path for status management
    local dbTypePath = "settings.libraries.databases.characters." .. libraryName
    local isActive = private.Core.StateManager.getState(dbTypePath)
    
    -- Only set default value if no saved state exists and StateManager hasn't loaded yet
    if (isActive == nil) then
        if private.Core.StateManager.isStateLoaded() then
            isActive = true -- New library after initial setup
        else
            isActive = true -- First-time initialization
        end
        private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
    end

    Chronicles.Data.Characters[libraryName] = {
        data = db,
        name = libraryName
    }

    return true
end

-----------------------------------------------------------------------------------------
-- Library Status Management -----------------------------------------------------------
-----------------------------------------------------------------------------------------

--[[
    Get the status of a library (whether it's active/enabled)
    @param libraryName [string] Name of the library
    @return [boolean] Library status (true if active)
]]
function DataRegistry.getLibraryStatus(libraryName)
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to get library status for " .. libraryName
        )
        return false
    end

    local isEventActive = nil
    local isFactionActive = nil
    local isCharacterActive = nil    -- Check Events database status using StateManager paths
    if Chronicles.Data.Events[libraryName] ~= nil then
        local dbTypePath = "settings.libraries.databases.events." .. libraryName
        local isActive = private.Core.StateManager.getState(dbTypePath)
        if (isActive == nil) then
            -- Only set default if StateManager hasn't loaded saved state yet
            if private.Core.StateManager.isStateLoaded() then
                isActive = true -- New library after initial setup
            else
                isActive = true -- First-time initialization
            end
            private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        isEventActive = isActive
    end    -- Check Factions database status using StateManager paths
    if Chronicles.Data.Factions[libraryName] ~= nil then
        local dbTypePath = "settings.libraries.databases.factions." .. libraryName
        local isActive = private.Core.StateManager.getState(dbTypePath)
        if (isActive == nil) then
            -- Only set default if StateManager hasn't loaded saved state yet
            if private.Core.StateManager.isStateLoaded() then
                isActive = true -- New library after initial setup
            else
                isActive = true -- First-time initialization
            end
            private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
        end
        isFactionActive = isActive
    end    -- Check Characters database status using StateManager paths
    if Chronicles.Data.Characters[libraryName] ~= nil then
        local dbTypePath = "settings.libraries.databases.characters." .. libraryName
        local isActive = private.Core.StateManager.getState(dbTypePath)
        if (isActive == nil) then
            -- Only set default if StateManager hasn't loaded saved state yet
            if private.Core.StateManager.isStateLoaded() then
                isActive = true -- New library after initial setup
            else
                isActive = true -- First-time initialization
            end
            private.Core.StateManager.setState(dbTypePath, isActive, "Library status initialization: " .. libraryName)
        end
        isCharacterActive = isActive
    end-- Cross-database status synchronization logic using StateManager paths
    if (isEventActive) then
        if Chronicles.Data.Factions[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.factions." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.characters." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
        end
        return true
    end

    if (isFactionActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.events." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.characters." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
        end
        return true
    end

    if (isCharacterActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.events." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        if Chronicles.Data.Factions[libraryName] ~= nil then
            private.Core.StateManager.setState(
                "settings.libraries.databases.factions." .. libraryName,
                true,
                "Library status sync: " .. libraryName
            )
        end
        return true
    end

    return false
end

--[[
    Set the status of a library (enable/disable)
    @param libraryName [string] Name of the library
    @param status [boolean] New status to set
]]
function DataRegistry.setLibraryStatus(libraryName, status)
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error(
            "DataRegistry",
            "Chronicles.Data not initialized when trying to set library status for " .. libraryName
        )
        return
    end
    local hadChange = false -- Update Events database status using StateManager paths
    if Chronicles.Data.Events[libraryName] ~= nil then
        local dbTypePath = "settings.libraries.databases.events." .. libraryName
        local oldStatus = private.Core.StateManager.getState(dbTypePath)
        private.Core.StateManager.setState(dbTypePath, status, "Library status update: " .. libraryName)
        if oldStatus ~= status then
            hadChange = true
        end
    end

    -- Update Factions database status using StateManager paths
    if Chronicles.Data.Factions[libraryName] ~= nil then
        private.Core.StateManager.setState(
            "settings.libraries.databases.factions." .. libraryName,
            status,
            "Library status update: " .. libraryName
        )
    end

    -- Update Characters database status using StateManager paths
    if Chronicles.Data.Characters[libraryName] ~= nil then
        private.Core.StateManager.setState(
            "settings.libraries.databases.characters." .. libraryName,
            status,
            "Library status update: " .. libraryName
        )
    end

    -- Only invalidate cache if there was an actual change to event status
    if hadChange then
        private.Core.Cache.invalidate("periodsFillingBySteps")
        private.Core.Cache.invalidate("searchCache")
    end
end

-----------------------------------------------------------------------------------------
-- Library Enumeration and Utilities ---------------------------------------------------
-----------------------------------------------------------------------------------------

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
    Get a list of all registered libraries with their status
    @return [table] Array of library information objects
]]
function DataRegistry.getLibrariesNames()
    -- Ensure Chronicles.Data is initialized
    local Chronicles = getChronicles()
    if not Chronicles or not Chronicles.Data then
        private.Core.Logger.error("DataRegistry", "Chronicles.Data not initialized when trying to get libraries names")
        return {}
    end

    local dataGroups = {}    -- Process Events libraries using StateManager paths
    for eventLibraryName, group in pairs(Chronicles.Data.Events) do
        if (eventLibraryName ~= "myjournal") then
            local dbTypePath = "settings.libraries.databases.events." .. eventLibraryName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New library after initial setup
                else
                    isActive = true -- First-time initialization
                end
            end

            local groupProjection = {
                name = group.name,
                isActive = isActive
            }

            DataRegistry.setLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not existInTable(eventLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end    -- Process Factions libraries using StateManager paths
    for factionLibraryName, group in pairs(Chronicles.Data.Factions) do
        if (factionLibraryName ~= "myjournal") then
            local dbTypePath = "settings.libraries.databases.factions." .. factionLibraryName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New library after initial setup
                else
                    isActive = true -- First-time initialization
                end
            end

            local groupProjection = {
                name = group.name,
                isActive = isActive
            }

            DataRegistry.setLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not existInTable(factionLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end    -- Process Characters libraries using StateManager paths
    for characterLibraryName, group in pairs(Chronicles.Data.Characters) do
        if (characterLibraryName ~= "myjournal") then
            local dbTypePath = "settings.libraries.databases.characters." .. characterLibraryName
            local isActive = private.Core.StateManager.getState(dbTypePath)
            if isActive == nil then
                -- Only set default if StateManager hasn't loaded saved state yet
                if private.Core.StateManager.isStateLoaded() then
                    isActive = true -- New library after initial setup
                else
                    isActive = true -- First-time initialization
                end
            end

            local groupProjection = {
                name = group.name,
                isActive = isActive
            }

            DataRegistry.setLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not existInTable(characterLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    return dataGroups
end

-----------------------------------------------------------------------------------------
-- Module Export ------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Expose the DataRegistry module for use by other components
return DataRegistry
