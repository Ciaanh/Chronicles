local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

private.Core.EventManager = {}

-----------------------------------------------------------------------------------------
-- Global Utility Functions ------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Helper function to safely trigger events with fallback to EventRegistry
function private.Core.triggerEvent(eventName, eventData, source)
    if private.Core.EventManager and private.Core.EventManager.safeTrigger then
        return private.Core.EventManager.safeTrigger(eventName, eventData, source)
    else
        EventRegistry:TriggerEvent(eventName, eventData)
        return true
    end
end

-- Helper function to safely register callbacks with fallback to EventRegistry
function private.Core.registerCallback(eventName, callback, owner)
    if private.Core.EventManager and private.Core.EventManager.safeRegisterCallback then
        private.Core.EventManager.safeRegisterCallback(eventName, callback, owner)
    else
        EventRegistry:RegisterCallback(eventName, callback, owner)
    end
end

-----------------------------------------------------------------------------------------
-- Event Validation & Schema -----------------------------------------------------------
-----------------------------------------------------------------------------------------

local eventSchemas = {
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

-----------------------------------------------------------------------------------------
-- Event Debugger & Logging ------------------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.Debugger = {
    enabled = false,
    logHistory = {},
    maxHistorySize = 100,
    enable = function(self)
        self.enabled = true
        private.Core.Logger.info("EventManager", "Debug mode enabled")
    end,
    disable = function(self)
        self.enabled = false
        private.Core.Logger.info("EventManager", "Debug mode disabled")
    end,
    logEvent = function(self, eventName, data, source, isError)
        if not self.enabled and not isError then
            return
        end

        local timestamp = GetServerTime()
        local logEntry = {
            timestamp = timestamp,
            eventName = eventName,
            data = data,
            source = source or "unknown",
            isError = isError or false
        }

        table.insert(self.logHistory, logEntry)

        -- Maintain history size limit
        if #self.logHistory > self.maxHistorySize then
            table.remove(self.logHistory, 1)
        end -- Print to chat if debug enabled or if error
        if self.enabled or isError then
            local logLevel = isError and "error" or "debug"
            local prefix = isError and "[ERROR]" or "[EVENT]"
            local dataStr = data and tostring(data.id or data.lower or "data") or "nil"
            private.Core.Logger[logLevel](
                "EventManager",
                string.format("%s %s from %s: %s", prefix, eventName, source, dataStr)
            )
        end
    end,
    getHistory = function(self, count)
        count = count or 10
        local history = {}
        local startIndex = math.max(1, #self.logHistory - count + 1)

        for i = startIndex, #self.logHistory do
            table.insert(history, self.logHistory[i])
        end

        return history
    end,
    printHistory = function(self, count)
        local history = self:getHistory(count)
        private.Core.Logger.info("EventManager", "Event History:")

        for _, entry in ipairs(history) do
            local logLevel = entry.isError and "error" or "info"
            local timeStr = date("%H:%M:%S", entry.timestamp)
            private.Core.Logger[logLevel](
                "EventManager",
                string.format("[%s] %s from %s", timeStr, entry.eventName, entry.source)
            )
        end
    end
}

-----------------------------------------------------------------------------------------
-- Event Validator ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.Validator = {
    validate = function(self, eventName, data)
        local schema = eventSchemas[eventName]
        if not schema then
            -- No schema defined, allow event (backward compatibility)
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

-----------------------------------------------------------------------------------------
-- Safe Event Triggering ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.safeTrigger = function(eventName, data, source)
    source = source or debug.getinfo(2, "S").source

    -- Validate event data
    local isValid, error = private.Core.EventManager.Validator:validate(eventName, data)
    if not isValid then
        private.Core.EventManager.Debugger:logEvent(eventName, data, source, true)
        private.Core.Logger.error("EventManager", "Event validation failed for " .. eventName .. ": " .. error)
        return false
    end

    -- Try to trigger event safely
    local success, errorMsg =
        pcall(
        function()
            EventRegistry:TriggerEvent(eventName, data)
        end
    )

    if success then
        private.Core.EventManager.Debugger:logEvent(eventName, data, source, false)
        return true
    else
        private.Core.EventManager.Debugger:logEvent(eventName, data, source, true)
        private.Core.Logger.error(
            "EventManager",
            "Event trigger failed for " .. eventName .. ": " .. tostring(errorMsg)
        )
        return false
    end
end

-----------------------------------------------------------------------------------------
-- Event Batching -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.Batcher = {
    batches = {},
    addToBatch = function(self, batchId, eventName, data, source)
        if not self.batches[batchId] then
            self.batches[batchId] = {}
        end

        table.insert(
            self.batches[batchId],
            {
                eventName = eventName,
                data = data,
                source = source
            }
        )
    end,
    executeBatch = function(self, batchId)
        local batch = self.batches[batchId]
        if not batch then
            return
        end

        for _, event in ipairs(batch) do
            private.Core.EventManager.safeTrigger(event.eventName, event.data, event.source)
        end

        -- Clear the batch
        self.batches[batchId] = nil
    end,
    clearBatch = function(self, batchId)
        self.batches[batchId] = nil
    end
}

-----------------------------------------------------------------------------------------
-- Enhanced Event Registry Wrapper -----------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.safeRegisterCallback = function(eventName, callback, owner)
    local wrappedCallback = function(...)
        local success, errorMsg = pcall(callback, ...)
        if not success then
            private.Core.EventManager.Debugger:logEvent(eventName, nil, tostring(owner), true)
            private.Core.Logger.error("EventManager", "Callback failed for " .. eventName .. ": " .. tostring(errorMsg))
        end
    end

    EventRegistry:RegisterCallback(eventName, wrappedCallback, owner)
end

-----------------------------------------------------------------------------------------
-- Plugin Event System -----------------------------------------------------------------
-----------------------------------------------------------------------------------------

private.Core.EventManager.PluginEvents = {
    registeredEvents = {},
    registerPluginEvent = function(self, pluginName, eventName, schema)
        local fullEventName = "Plugin." .. pluginName .. "." .. eventName
        if self.registeredEvents[fullEventName] then
            private.Core.Logger.warn("EventManager", "Plugin event already registered: " .. fullEventName)
            return false
        end

        self.registeredEvents[fullEventName] = {
            pluginName = pluginName,
            eventName = eventName,
            schema = schema
        } -- Add schema to validator if provided
        if schema then
            private.Core.EventManager.Validator:addSchema(fullEventName, schema)
        end

        private.Core.Logger.info("EventManager", "Plugin event registered: " .. fullEventName)
        return true
    end,
    triggerPluginEvent = function(self, pluginName, eventName, data, source)
        local fullEventName = "Plugin." .. pluginName .. "." .. eventName
        if not self.registeredEvents[fullEventName] then
            private.Core.Logger.warn("EventManager", "Unknown plugin event: " .. fullEventName)
            return false
        end

        return private.Core.EventManager.safeTrigger(fullEventName, data, source)
    end
}

-----------------------------------------------------------------------------------------
-- Console Commands ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Add slash commands for debugging
SLASH_CHRONICLESEVENTDEBUG1 = "/ceventdebug"
SlashCmdList["CHRONICLESEVENTDEBUG"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1]

    if command == "on" then
        private.Core.EventManager.Debugger:enable()
    elseif command == "off" then
        private.Core.EventManager.Debugger:disable()
    elseif command == "history" then
        local count = tonumber(args[2]) or 10
        private.Core.EventManager.Debugger:printHistory(count)
    elseif command == "schemas" then
        private.Core.Logger.info("EventManager", "Available event schemas:")
        for eventName, schema in pairs(eventSchemas) do
            private.Core.Logger.info(
                "EventManager",
                "- " .. eventName .. ": " .. (schema.description or "No description")
            )
        end
    else
        private.Core.Logger.info("EventManager", "Commands:")
        private.Core.Logger.info("EventManager", "  /ceventdebug on - Enable event debugging")
        private.Core.Logger.info("EventManager", "  /ceventdebug off - Disable event debugging")
        private.Core.Logger.info("EventManager", "  /ceventdebug history [count] - Show event history")
        private.Core.Logger.info("EventManager", "  /ceventdebug schemas - List available event schemas")
    end
end
