local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: DependencyContainer
Purpose: Centralized dependency injection to eliminate circular dependencies
Author: Chronicles Team
=================================================================================

This module provides a lightweight dependency injection container to resolve
circular dependency issues throughout the Chronicles addon.

Key Features:
- Lazy initialization of dependencies
- Safe access to modules before they're fully loaded
- Circular dependency detection and resolution
- Clear dependency mapping

Usage Example:
    local container = private.Core.DependencyContainer
    container.register("Timeline", private.Core.Timeline)
    local timeline = container.resolve("Timeline")

Benefits:
- Eliminates direct module references that cause circular dependencies
- Provides a single source of truth for module resolution
- Enables better testing through dependency mocking
- Clear visibility of inter-module dependencies

=================================================================================
]]

private.Core.DependencyContainer = {}
local DependencyContainer = private.Core.DependencyContainer

-- Container storage
local dependencies = {}
local resolvers = {}
local isResolving = {}

--[[
    Register a dependency with the container
    @param name [string] Unique name for the dependency
    @param dependency [any] The dependency to register (can be nil for lazy loading)
    @param resolver [function] Optional resolver function for lazy loading
]]
function DependencyContainer.register(name, dependency, resolver)
    if type(name) ~= "string" or name == "" then
        error("Dependency name must be a non-empty string")
    end
    
    dependencies[name] = dependency
    if resolver and type(resolver) == "function" then
        resolvers[name] = resolver
    end
end

--[[
    Resolve a dependency from the container
    @param name [string] Name of the dependency to resolve
    @return [any] The resolved dependency or nil if not found
]]
function DependencyContainer.resolve(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    
    -- Check for circular dependency
    if isResolving[name] then
        error("Circular dependency detected for: " .. name)
    end
    
    -- Return cached dependency if available
    if dependencies[name] ~= nil then
        return dependencies[name]
    end
    
    -- Try to resolve using resolver function
    if resolvers[name] then
        isResolving[name] = true
        
        local success, result = pcall(resolvers[name])
        isResolving[name] = nil
        
        if success and result ~= nil then
            dependencies[name] = result
            return result
        end
    end
    
    return nil
end

--[[
    Check if a dependency is registered
    @param name [string] Name of the dependency
    @return [boolean] True if dependency is registered
]]
function DependencyContainer.isRegistered(name)
    return dependencies[name] ~= nil or resolvers[name] ~= nil
end

--[[
    Clear all dependencies (useful for testing)
]]
function DependencyContainer.clear()
    dependencies = {}
    resolvers = {}
    isResolving = {}
end

--[[
    Get all registered dependency names
    @return [table] Array of dependency names
]]
function DependencyContainer.getRegisteredNames()
    local names = {}
    
    for name, _ in pairs(dependencies) do
        table.insert(names, name)
    end
    
    for name, _ in pairs(resolvers) do
        if not dependencies[name] then
            table.insert(names, name)
        end
    end
    
    return names
end

-- Register common Chronicles dependencies with lazy resolvers
DependencyContainer.register("Chronicles", nil, function()
    return private.Chronicles
end)

DependencyContainer.register("StateManager", nil, function()
    return private.Core.StateManager
end)

DependencyContainer.register("Timeline", nil, function()
    return private.Core.Timeline
end)

DependencyContainer.register("TimelineBusiness", nil, function()
    return private.Core.Data and private.Core.Data.TimelineBusiness
end)

DependencyContainer.register("EventManager", nil, function()
    return private.Core.EventManager
end)

DependencyContainer.register("Cache", nil, function()
    return private.Core.Cache
end)

DependencyContainer.register("SearchEngine", nil, function()
    return private.Core.Data and private.Core.Data.SearchEngine
end)

return DependencyContainer
