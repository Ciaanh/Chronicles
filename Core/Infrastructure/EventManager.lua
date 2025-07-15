local FOLDER_NAME, private = ...

private.Core.EventManager = {}

--[[
Chronicles Event Management System

CURRENT EVENT USAGE:
✅ ACTIVELY TRIGGERED EVENTS (All with validation schemas):
- AddonStartup, AddonShutdown: Application lifecycle
- TimelineInit: Timeline initialization 
- UIRefresh: UI component refresh requests
- TabUITabSet: Tab selection in main UI
- SettingsEventTypeChecked, SettingsCollectionChecked: Settings changes
- TimelinePreviousButtonVisible, TimelineNextButtonVisible: Navigation buttons
- DisplayTimelineLabel, DisplayTimelinePeriod: Dynamic timeline display (with suffix validation)

MIGRATION NOTES:
- Selection events (Event/Character/Faction) moved to StateManager.setState()
- UI components subscribe to state changes instead of listening for events
- This provides single source of truth and better state synchronization
--]]
-- -------------------------
-- Global Utility Functions
-- -------------------------

function private.Core.triggerEvent(eventName, eventData, source)
    if private.Core.EventManager and private.Core.EventManager.safeTrigger then
        return private.Core.EventManager.safeTrigger(eventName, eventData, source)
    else
        EventRegistry:TriggerEvent(eventName, eventData)
        return true
    end
end

function private.Core.registerCallback(eventName, callback, owner)
    if private.Core.EventManager and private.Core.EventManager.safeRegisterCallback then
        private.Core.EventManager.safeRegisterCallback(eventName, callback, owner)
    else
        EventRegistry:RegisterCallback(eventName, callback, owner)
    end
end

-- -------------------------
-- Event Validation & Schema
-- -------------------------

local eventSchemas = {
    [private.constants.events.AddonStartup] = {
        description = "Fired when the addon is starting up and initializing components",
        required = {"version", "timestamp"},
        optional = {"debugMode", "profile"},
        validate = function(data)
            if not data then
                return false, "Startup data is nil"
            end
            return true, nil
        end
    },
    [private.constants.events.AddonShutdown] = {
        description = "Fired when the addon is shutting down",
        required = {"version", "timestamp"},
        optional = {"profile"},
        validate = function(data)
            return true, nil
        end
    },
    [private.constants.events.TimelineInit] = {
        description = "Fired when the timeline is initialized",
        optional = {"data"},
        validate = function(data)
            return true, nil
        end
    },
    [private.constants.events.UIRefresh] = {
        description = "Fired when UI components need to refresh their data",
        optional = {"source", "data"},
        validate = function(data)
            return true, nil
        end
    },
    [private.constants.events.TabUITabSet] = {
        description = "Fired when a tab is selected in the main UI",
        required = {"frame", "tabID"},
        validate = function(data)
            if not data then
                return false, "Tab data is nil"
            end
            if not data.frame then
                return false, "Tab frame is required"
            end
            if type(data.tabID) ~= "number" then
                return false, "Tab ID must be a number"
            end
            return true, nil
        end
    },
    [private.constants.events.SettingsEventTypeChecked] = {
        description = "Fired when an event type setting is toggled",
        required = {"eventTypeId", "isActive"},
        validate = function(data)
            if not data then
                return false, "Event type data is nil"
            end
            if type(data.eventTypeId) ~= "number" then
                return false, "Event type ID must be a number"
            end
            if type(data.isActive) ~= "boolean" then
                return false, "isActive must be a boolean"
            end
            return true, nil
        end
    },
    [private.constants.events.SettingsCollectionChecked] = {
        description = "Fired when a collection setting is toggled",
        required = {"collectionName", "isActive"},
        validate = function(data)
            if not data then
                return false, "Collection data is nil"
            end
            if type(data.collectionName) ~= "string" then
                return false, "Collection name must be a string"
            end
            if type(data.isActive) ~= "boolean" then
                return false, "isActive must be a boolean"
            end
            return true, nil
        end
    },
    [private.constants.events.TimelinePreviousButtonVisible] = {
        description = "Fired when timeline previous button visibility changes",
        required = {"visible"},
        validate = function(data)
            if not data then
                return false, "Visibility data is nil"
            end
            if type(data.visible) ~= "boolean" then
                return false, "visible must be a boolean"
            end
            return true, nil
        end
    },
    [private.constants.events.TimelineNextButtonVisible] = {
        description = "Fired when timeline next button visibility changes",
        required = {"visible"},
        validate = function(data)
            if not data then
                return false, "Visibility data is nil"
            end
            if type(data.visible) ~= "boolean" then
                return false, "visible must be a boolean"
            end
            return true, nil
        end
    },
    -- Dynamic Timeline Display Events (with index suffixes)
    [private.constants.events.DisplayTimelineLabel] = {
        description = "Fired when timeline labels need to be displayed (dynamic with index suffixes)",
        validate = function(data)
            -- Timeline labels can be strings (years) or empty
            if data ~= nil and type(data) ~= "string" then
                return false, "Timeline label must be a string or nil"
            end
            return true, nil
        end
    },
    [private.constants.events.DisplayTimelinePeriod] = {
        description = "Fired when timeline periods need to be displayed (dynamic with index suffixes)",
        validate = function(data)
            -- Period data can be nil (empty period) or a table with period information
            if data ~= nil then
                if type(data) ~= "table" then
                    return false, "Timeline period data must be a table or nil"
                end
                -- If period data exists, it should have the expected structure
                if data.lower and type(data.lower) ~= "number" then
                    return false, "Period lower bound must be a number"
                end
                if data.upper and type(data.upper) ~= "number" then
                    return false, "Period upper bound must be a number"
                end
            end
            return true, nil
        end
    },
    [private.constants.events.DisplayEventsForYear] = {
        description = "Fired when events for a specific year need to be displayed",
        validate = function(data)
            if not data or type(data) ~= "table" then
                return false, "DisplayEventsForYear data must be a table"
            end
            if not data.year or type(data.year) ~= "number" then
                return false, "Year must be a number"
            end
            if not data.events or type(data.events) ~= "table" then
                return false, "Events must be a table"
            end
            return true, nil
        end
    }
}

-- -------------------------
-- Event Validator
-- -------------------------

private.Core.EventManager.Validator = {
    validate = function(self, eventName, data)
        local schema = eventSchemas[eventName]

        -- If no direct match, check for dynamic events with suffixes
        if not schema then
            -- Check for DisplayTimelineLabel events (e.g., "Timeline.DisplayLabel1")
            if string.find(eventName, "^" .. private.constants.events.DisplayTimelineLabel .. "%d+$") then
                -- Check for DisplayTimelinePeriod events (e.g., "Timeline.DisplayPeriod1")
                schema = eventSchemas[private.constants.events.DisplayTimelineLabel]
            elseif string.find(eventName, "^" .. private.constants.events.DisplayTimelinePeriod .. "%d+$") then
                schema = eventSchemas[private.constants.events.DisplayTimelinePeriod]
            end
        end

        if not schema then
            return true, nil
        end

        return schema.validate(data)
    end,
    getSchema = function(self, eventName)
        return eventSchemas[eventName]
    end,
    addSchema = function(self, eventName, schema)
        eventSchemas[eventName] = schema
    end
}

-- -------------------------
-- Safe Event Triggering
-- -------------------------

private.Core.EventManager.safeTrigger = function(eventName, data, source)
    source = source or debug.getinfo(2, "S").source

    local isValid, error = private.Core.EventManager.Validator:validate(eventName, data)
    if not isValid then
        return false
    end

    local success, errorMsg =
        pcall(
        function()
            EventRegistry:TriggerEvent(eventName, data)
        end
    )
    if success then
        return true
    else
        return false
    end
end

-- -------------------------
-- Enhanced Event Registry Wrapper
-- -------------------------

private.Core.EventManager.safeRegisterCallback = function(eventName, callback, owner)
    local wrappedCallback = function(...)
        local success, errorMsg = pcall(callback, ...)
        -- Silently ignore callback failures to prevent cascade errors
    end

    EventRegistry:RegisterCallback(eventName, wrappedCallback, owner)
end

-- -------------------------
-- Plugin Event System
-- -------------------------

private.Core.EventManager.PluginEvents = {
    registeredEvents = {},
    registerPluginEvent = function(self, pluginName, eventName, schema)
        local fullEventName = "Plugin." .. pluginName .. "." .. eventName
        if self.registeredEvents[fullEventName] then
            return false
        end

        self.registeredEvents[fullEventName] = {
            pluginName = pluginName,
            eventName = eventName,
            schema = schema
        }

        if schema then
            private.Core.EventManager.Validator:addSchema(fullEventName, schema)
        end

        return true
    end,
    triggerPluginEvent = function(self, pluginName, eventName, data, source)
        local fullEventName = "Plugin." .. pluginName .. "." .. eventName
        if not self.registeredEvents[fullEventName] then
            return false
        end

        return private.Core.EventManager.safeTrigger(fullEventName, data, source)
    end
}
