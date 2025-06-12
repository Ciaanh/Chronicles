local FOLDER_NAME, private = ...

private.Core.EventManager = {}

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
    [private.constants.events.EventSelected] = {
        description = "Fired when an event is selected in the timeline or list",
        required = {"id", "label", "yearStart", "yearEnd"},
        optional = {"chapters", "eventType", "factions", "characters", "source", "order"},
        validate = function(data)
            if not data then
                return false, "Event data is nil"
            end
            if type(data.id) ~= "number" then
                return false, "Event ID must be a number"
            end
            if type(data.label) ~= "string" then
                return false, "Event label must be a string"
            end
            if type(data.yearStart) ~= "number" then
                return false, "Event yearStart must be a number"
            end
            if type(data.yearEnd) ~= "number" then
                return false, "Event yearEnd must be a number"
            end
            return true, nil
        end
    },
    [private.constants.events.TimelinePeriodSelected] = {
        description = "Fired when a timeline period is selected",
        required = {"lower", "upper"},
        validate = function(data)
            if not data then
                return false, "Period data is nil"
            end
            if type(data.lower) ~= "number" then
                return false, "Period lower bound must be a number"
            end
            if type(data.upper) ~= "number" then
                return false, "Period upper bound must be a number"
            end
            if data.lower > data.upper then
                return false, "Period lower bound cannot be greater than upper bound"
            end
            return true, nil
        end
    },
    [private.constants.events.CharacterSelected] = {
        description = "Fired when a character is selected",
        required = {"id", "name"},
        optional = {"description", "factions", "events"},
        validate = function(data)
            if not data then
                return false, "Character data is nil"
            end
            if type(data.id) ~= "number" then
                return false, "Character ID must be a number"
            end
            if type(data.name) ~= "string" then
                return false, "Character name must be a string"
            end
            return true, nil
        end
    },
    [private.constants.events.FactionSelected] = {
        description = "Fired when a faction is selected",
        required = {"id", "name"},
        optional = {"description", "characters", "events"},
        validate = function(data)
            if not data then
                return false, "Faction data is nil"
            end
            if type(data.id) ~= "number" then
                return false, "Faction ID must be a number"
            end
            if type(data.name) ~= "string" then
                return false, "Faction name must be a string"
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
