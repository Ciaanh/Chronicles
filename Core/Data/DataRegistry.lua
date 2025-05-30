--[[
    Chronicles DataRegistry Module
    
    Part of the Clean Code reorganization initiative - Phase 2
    
    This module handles all database registration and library status management functionality.
    Extracted from Data.lua to follow Single Responsibility Principle.
    
    RESPONSIBILITIES:
    - Database registration (Events, Factions, Characters)
    - Library status management (Get/Set library status)
    - Library enumeration and state management
    - Cross-database status synchronization
    
    USAGE:
    - Called by Data.lua through delegation pattern
    - Used by external plugins for database registration
    - Maintains backward compatibility through Data.lua facade
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
    end

    if db == nil then
        private.Core.Logger.warn(
            "DataRegistry",
            "Library '" .. libraryName .. "' is trying to register a nil events database."
        )
    end

    local isActive = Chronicles.db.global.EventDBStatuses[libraryName]
    if (isActive == nil) then
        isActive = true
        Chronicles.db.global.EventDBStatuses[libraryName] = isActive
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
    end

    if Chronicles.Data.Factions[libraryName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            libraryName .. " is already registered by another plugin in Factions."
        )
        return false
    end

    local isActive = Chronicles.db.global.FactionDBStatuses[libraryName]
    if (isActive == nil) then
        isActive = true
        Chronicles.db.global.FactionDBStatuses[libraryName] = isActive
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
    end

    if Chronicles.Data.Characters[libraryName] ~= nil then
        private.Core.Logger.error(
            "DataRegistry",
            libraryName .. " is already registered by another plugin in Characters."
        )
        return false
    end

    local isActive = Chronicles.db.global.CharacterDBStatuses[libraryName]
    if (isActive == nil) then
        isActive = true
        Chronicles.db.global.CharacterDBStatuses[libraryName] = isActive
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
    local isCharacterActive = nil

    -- Check Events database status
    if Chronicles.Data.Events[libraryName] ~= nil then
        local isActive = Chronicles.db.global.EventDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.EventDBStatuses[libraryName] = isActive
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        isEventActive = isActive
    end

    -- Check Factions database status
    if Chronicles.Data.Factions[libraryName] ~= nil then
        local isActive = Chronicles.db.global.FactionDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.FactionDBStatuses[libraryName] = isActive
        end
        isFactionActive = isActive
    end

    -- Check Characters database status
    if Chronicles.Data.Characters[libraryName] ~= nil then
        local isActive = Chronicles.db.global.CharacterDBStatuses[libraryName]
        if (isActive == nil) then
            isActive = true
            Chronicles.db.global.CharacterDBStatuses[libraryName] = isActive
        end
        isCharacterActive = isActive
    end

    -- Cross-database status synchronization logic
    if (isEventActive) then
        if Chronicles.Data.Factions[libraryName] ~= nil then
            Chronicles.db.global.FactionDBStatuses[libraryName] = true
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            Chronicles.db.global.CharacterDBStatuses[libraryName] = true
        end
        return true
    end

    if (isFactionActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            Chronicles.db.global.EventDBStatuses[libraryName] = true
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        if Chronicles.Data.Characters[libraryName] ~= nil then
            Chronicles.db.global.CharacterDBStatuses[libraryName] = true
        end
        return true
    end

    if (isCharacterActive) then
        if Chronicles.Data.Events[libraryName] ~= nil then
            Chronicles.db.global.EventDBStatuses[libraryName] = true
            private.Core.Cache.invalidate("periodsFillingBySteps")
            private.Core.Cache.invalidate("searchCache")
        end
        if Chronicles.Data.Factions[libraryName] ~= nil then
            Chronicles.db.global.FactionDBStatuses[libraryName] = true
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

    local hadChange = false

    -- Update Events database status
    if Chronicles.Data.Events[libraryName] ~= nil then
        local oldStatus = Chronicles.db.global.EventDBStatuses[libraryName]
        Chronicles.db.global.EventDBStatuses[libraryName] = status
        if oldStatus ~= status then
            hadChange = true
        end
    end

    -- Update Factions database status
    if Chronicles.Data.Factions[libraryName] ~= nil then
        Chronicles.db.global.FactionDBStatuses[libraryName] = status
    end

    -- Update Characters database status
    if Chronicles.Data.Characters[libraryName] ~= nil then
        Chronicles.db.global.CharacterDBStatuses[libraryName] = status
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

    local dataGroups = {}

    -- Process Events libraries
    for eventLibraryName, group in pairs(Chronicles.Data.Events) do
        if (eventLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.EventDBStatuses[eventLibraryName]
            }

            DataRegistry.setLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not existInTable(eventLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    -- Process Factions libraries
    for factionLibraryName, group in pairs(Chronicles.Data.Factions) do
        if (factionLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.FactionDBStatuses[factionLibraryName]
            }

            DataRegistry.setLibraryStatus(groupProjection.name, groupProjection.isActive)

            if not existInTable(factionLibraryName, dataGroups) then
                table.insert(dataGroups, groupProjection)
            end
        end
    end

    -- Process Characters libraries
    for characterLibraryName, group in pairs(Chronicles.Data.Characters) do
        if (characterLibraryName ~= "myjournal") then
            local groupProjection = {
                name = group.name,
                isActive = Chronicles.db.global.CharacterDBStatuses[characterLibraryName]
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
