local FOLDER_NAME, private = ...

private.Core.Settings = {}

-- Import utilities
local StringUtils = private.Core.Utils.StringUtils
local TableUtils = private.Core.Utils.TableUtils
local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Settings Data Structure:
    display = {
        showTooltips = [boolean]        -- Show tooltips on hover
        fontSize = [string]             -- Font size: "small", "medium", "large"
        theme = [string]                -- UI theme
        animationSpeed = [number]       -- Animation speed multiplier
    }
    timeline = {
        defaultView = [string]          -- Default timeline view
        periodsPerPage = [number]       -- Number of periods to show per page
        autoAdvance = [boolean]         -- Auto-advance timeline
        highlightCurrentPeriod = [boolean] -- Highlight current period
    }
    events = {
        showEventTypes = { [number] }   -- Enabled event type IDs
        showLibraries = { [string] }    -- Enabled library names
        sortBy = [string]               -- Default sort method
        filterByTimeline = [boolean]    -- Filter events by current timeline
    }
    characters = {
        showRelationships = [boolean]   -- Show character relationships
        groupByFaction = [boolean]      -- Group characters by faction
        sortBy = [string]               -- Default sort method
    }
    factions = {
        showRelationships = [boolean]   -- Show faction relationships
        groupByAlignment = [boolean]    -- Group factions by alignment
        sortBy = [string]               -- Default sort method
    }
    minimap = {
        enabled = [boolean]             -- Show minimap icon
        position = [number]             -- Minimap icon position
    }
    advanced = {
        debugMode = [boolean]           -- Enable debug logging
        cacheEnabled = [boolean]        -- Enable data caching
        preloadData = [boolean]         -- Preload all data on startup
    }
]]
-- Default settings configuration
local DEFAULT_SETTINGS = {
    display = {
        showTooltips = true,
        fontSize = "medium",
        theme = "default",
        animationSpeed = 1.0
    },
    timeline = {
        defaultView = "periods",
        periodsPerPage = 10,
        autoAdvance = false,
        highlightCurrentPeriod = true
    },
    events = {
        showEventTypes = {},
        showLibraries = {},
        sortBy = "year",
        filterByTimeline = true
    },
    characters = {
        showRelationships = true,
        groupByFaction = false,
        sortBy = "name"
    },
    factions = {
        showRelationships = true,
        groupByAlignment = false,
        sortBy = "name"
    },
    minimap = {
        enabled = true,
        position = 0
    },
    advanced = {
        debugMode = false,
        cacheEnabled = true,
        preloadData = false
    }
}

--[[
    Initialize settings system
    @param savedVariables [table] Saved variables from addon
    @return [table] Initialized settings
]]
function private.Core.Settings.Initialize(savedVariables)
    local settings = TableUtils.DeepCopy(DEFAULT_SETTINGS)

    if ValidationUtils.IsValidTable(savedVariables) and ValidationUtils.IsValidTable(savedVariables.settings) then
        settings = TableUtils.Merge(settings, savedVariables.settings)
    end

    return settings
end

--[[
    Get a setting value by path
    @param settings [table] Settings object
    @param path [string] Dot-separated path to setting (e.g., "display.fontSize")
    @return [any] Setting value or nil if not found
]]
function private.Core.Settings.GetSetting(settings, path)
    if not ValidationUtils.IsValidTable(settings) or not ValidationUtils.IsValidString(path) then
        return nil
    end

    local parts = {strsplit(".", path)}
    local current = settings

    for _, part in ipairs(parts) do
        if type(current) ~= "table" or current[part] == nil then
            return nil
        end
        current = current[part]
    end

    return current
end

--[[
    Set a setting value by path
    @param settings [table] Settings object
    @param path [string] Dot-separated path to setting
    @param value [any] Value to set
    @return [boolean] True if setting was set successfully
]]
function private.Core.Settings.SetSetting(settings, path, value)
    if not ValidationUtils.IsValidTable(settings) or not ValidationUtils.IsValidString(path) then
        return false
    end

    local parts = {strsplit(".", path)}
    local current = settings

    -- Navigate to the parent of the target setting
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end

    -- Set the final value
    current[parts[#parts]] = value
    return true
end

--[[
    Reset settings to defaults
    @param settings [table] Settings object to reset
    @param category [string] Optional: specific category to reset (e.g., "display")
    @return [table] Reset settings
]]
function private.Core.Settings.ResetToDefaults(settings, category)
    if not ValidationUtils.IsValidTable(settings) then
        return TableUtils.DeepCopy(DEFAULT_SETTINGS)
    end

    if ValidationUtils.IsValidString(category) then
        if DEFAULT_SETTINGS[category] then
            settings[category] = TableUtils.DeepCopy(DEFAULT_SETTINGS[category])
        end
    else
        settings = TableUtils.DeepCopy(DEFAULT_SETTINGS)
    end

    return settings
end

--[[
    Apply settings to the addon
    @param settings [table] Settings to apply
]]
function private.Core.Settings.ApplySettings(settings)
    if not ValidationUtils.IsValidTable(settings) then
        return
    end

    -- Apply display settings
    local displaySettings = private.Core.Settings.GetComponentSettings(settings, "display")
    if displaySettings.fontSize then
        -- Apply font size changes to UI
        private.Core.Settings.ApplyFontSize(displaySettings.fontSize)
    end

    -- Apply timeline settings
    local timelineSettings = private.Core.Settings.GetComponentSettings(settings, "timeline")
    if timelineSettings.highlightCurrentPeriod ~= nil then
        -- Update timeline highlighting
        if private.Core.StateManager and private.Core.StateManager.SetTimelineHighlighting then
            private.Core.StateManager.SetTimelineHighlighting(timelineSettings.highlightCurrentPeriod)
        end
    end
end

--[[
    Get settings for a specific UI component
    @param settings [table] Full settings object
    @param component [string] Component name
    @return [table] Component-specific settings
]]
function private.Core.Settings.GetComponentSettings(settings, component)
    if not ValidationUtils.IsValidTable(settings) or not ValidationUtils.IsValidString(component) then
        return {}
    end

    return settings[component] or {}
end

--[[
    Apply font size to UI elements
    @param fontSize [string] Font size setting
]]
function private.Core.Settings.ApplyFontSize(fontSize)
    -- Implementation would update font sizes across the UI
    -- This is a placeholder for the actual font application logic
end
