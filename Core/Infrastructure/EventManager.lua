local FOLDER_NAME, private = ...

private.Core.EventManager = {}

--[[
Chronicles Event Management System

CONSUMER CONTRACT
    private.Core.registerCallback(eventName, callback, owner) hands the callback to
    EventRegistry, which invokes it as callback(owner, payload): the owner first,
    then the single payload table that triggerEvent was given. A handler declared
    with `:` therefore receives the whole payload table as its first parameter, and
    must read the field it needs off that table -- the table itself is always truthy:

        function TimelineMixin:OnTimelineNextButtonVisible(payload)
            -- payload is {visible = <boolean>}; `if payload then` is always true
            if payload.visible then
                self.Next:Enable()
            else
                self.Next:Disable()
            end
        end

    Payloads are never unpacked into separate arguments. The schemas below constrain
    producers only; nothing validates a consumer's signature, so a handler that
    expects a bare value fails silently.

    The schema table below is the event inventory -- do not restate it here.

SELECTION STATE
    Event / character / faction selection and timeline period selection are not
    events; they live in StateManager. Prefer a state subscription over a new event
    for anything that is really "a value changed".
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

function private.Core.unregisterCallback(eventName, owner)
    if private.Core.EventManager and private.Core.EventManager.safeUnregisterCallback then
        private.Core.EventManager.safeUnregisterCallback(eventName, owner)
    else
        EventRegistry:UnregisterCallback(eventName, owner)
    end
end

-- -------------------------
-- Event Validation & Schema
-- -------------------------

local eventSchemas = {
    [private.constants.events.AddonStartup] = {
        description = "Fired when the addon is starting up and initializing components",
        optional = {"profile"},
        validate = function(data)
            if not data then
                return false, "Startup data is nil"
            end
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

private.constants.eventPayloadSchemas = private.constants.eventPayloadSchemas or {}
for eventName, schema in pairs(eventSchemas) do
    private.constants.eventPayloadSchemas[eventName] = schema
end

-- -------------------------
-- Event Validator
-- -------------------------

--[[
    Escape Lua pattern metacharacters so a literal string can be embedded in a pattern

    @param text [string] Literal text
    @return [string] Text safe to concatenate into a Lua pattern
]]
local function escapePattern(text)
    return (string.gsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- Dynamic display events carry an index suffix ("Timeline.DisplayLabel1"). The event
-- name constants are literals containing pattern metacharacters (a dot at minimum),
-- so they must be escaped or the match silently degrades to "any character".
local dynamicLabelPattern = "^" .. escapePattern(private.constants.events.DisplayTimelineLabel) .. "%d+$"
local dynamicPeriodPattern = "^" .. escapePattern(private.constants.events.DisplayTimelinePeriod) .. "%d+$"

private.Core.EventManager.Validator = {
    validate = function(self, eventName, data)
        local schema = eventSchemas[eventName]

        -- If no direct match, check for dynamic events with suffixes
        if not schema then
            if string.find(eventName, dynamicLabelPattern) then
                schema = eventSchemas[private.constants.events.DisplayTimelineLabel]
            elseif string.find(eventName, dynamicPeriodPattern) then
                schema = eventSchemas[private.constants.events.DisplayTimelinePeriod]
            end
        end

        if not schema then
            return true, nil
        end

        -- Enforce declared required fields generically so the `required` list is
        -- a real contract, not just documentation. Per-schema validate() runs
        -- afterwards for type/value checks.
        if schema.required then
            if type(data) ~= "table" then
                return false,
                    eventName .. ": payload must be a table with required fields: " ..
                        table.concat(schema.required, ", ")
            end
            for _, field in ipairs(schema.required) do
                if data[field] == nil then
                    return false, eventName .. ": missing required field '" .. field .. "'"
                end
            end
        end

        return schema.validate(data)
    end,
    getSchema = function(self, eventName)
        return eventSchemas[eventName]
    end,
    addSchema = function(self, eventName, schema)
        eventSchemas[eventName] = schema
        if private.constants then
            private.constants.eventPayloadSchemas = private.constants.eventPayloadSchemas or {}
            private.constants.eventPayloadSchemas[eventName] = schema
        end
    end,
    getAllSchemas = function(self)
        local copy = {}
        for name, schema in pairs(eventSchemas) do
            copy[name] = schema
        end
        return copy
    end
}

-- -------------------------
-- Safe Event Triggering
-- -------------------------

--[[
    Describe the caller of safeTrigger for a diagnostic message

    Only reached on the failure path: safeTrigger runs 17+ times per timeline
    redraw, and walking the stack on every trigger is not free.

    @param source [string] Explicit source passed by the producer, if any
    @return [string] Caller description
]]
local function describeTriggerSource(source)
    if source then
        return tostring(source)
    end

    local info = debug and debug.getinfo and debug.getinfo(3, "Sl")
    if info then
        return tostring(info.short_src or info.source) .. ":" .. tostring(info.currentline)
    end

    return "unknown"
end

private.Core.EventManager.safeTrigger = function(eventName, data, source)
    local isValid, validationError = private.Core.EventManager.Validator:validate(eventName, data)
    if not isValid then
        -- A schema rejection means a producer is malformed. Surface it the same way
        -- callback errors are surfaced, so it cannot become an invisible no-op.
        geterrorhandler()(
            string.format(
                "Chronicles: event '%s' triggered from %s with an invalid payload: %s",
                tostring(eventName),
                describeTriggerSource(source),
                tostring(validationError)
            )
        )
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
        -- Fail fast: surface the error in-game (WoW's error handler / BugSack)
        -- instead of hiding it, while still isolating the caller from the failure.
        geterrorhandler()(errorMsg)
        return false
    end
end

-- -------------------------
-- Enhanced Event Registry Wrapper
-- -------------------------

private.Core.EventManager.safeRegisterCallback = function(eventName, callback, owner)
    local wrappedCallback = function(...)
        -- pcall isolates one subscriber's failure from the others, but we fail
        -- fast: forward the error to WoW's handler so it stays visible in-game
        -- during testing rather than being silently swallowed.
        local success, errorMsg = pcall(callback, ...)
        if not success then
            geterrorhandler()(errorMsg)
        end
    end

    EventRegistry:RegisterCallback(eventName, wrappedCallback, owner)
end

private.Core.EventManager.safeUnregisterCallback = function(eventName, owner)
    EventRegistry:UnregisterCallback(eventName, owner)
end
