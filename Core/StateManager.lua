local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

private.Core.StateManager = {}

-----------------------------------------------------------------------------------------
-- Local Utilities ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

-- Local deep copy function (to avoid dependency on TableUtils)
local function deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do
            copy[deepCopy(key)] = deepCopy(value)
        end
        setmetatable(copy, deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-----------------------------------------------------------------------------------------
-- State Management ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

local StateManager = {
    state = {
        ui = {
            selectedEvent = nil, -- Stores event ID (number) instead of full event object
            selectedCharacter = nil, -- Stores character ID (number) instead of full character object
            selectedFaction = nil, -- Stores faction ID (number) instead of full faction object
            selectedPeriod = nil,
            activeTab = nil,
            isMainFrameOpen = false
        },
        timeline = {
            currentStep = nil,
            currentPage = nil,
            selectedYear = nil,
            periodsCache = {}
        },
        settings = {
            eventTypes = {},
            libraries = {},
            debugMode = false
        },
        data = {
            lastRefreshTime = 0,
            isDirty = false
        }
    },
    history = {},
    maxHistorySize = 50,
    listeners = {},
    isLoaded = false -- Track if saved state has been loaded
}

-----------------------------------------------------------------------------------------
-- State History & Undo/Redo ----------------------------------------------------------
-----------------------------------------------------------------------------------------

local function saveStateSnapshot(description)
    local snapshot = {
        timestamp = GetServerTime(),
        description = description or "State change",
        state = deepCopy(StateManager.state)
    }

    table.insert(StateManager.history, snapshot)

    -- Maintain history size
    if #StateManager.history > StateManager.maxHistorySize then
        table.remove(StateManager.history, 1)
    end
end

-----------------------------------------------------------------------------------------
-- State Utilities ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.getState(path)
    if not path then
        return StateManager.state
    end

    local keys = {strsplit(".", path)}
    local current = StateManager.state

    for _, key in ipairs(keys) do
        if type(current) ~= "table" or not current[key] then
            return nil
        end
        current = current[key]
    end

    return current
end

function private.Core.StateManager.isStateLoaded()
    return StateManager.isLoaded
end

function private.Core.StateManager.setState(path, value, description)
    local keys = {strsplit(".", path)}
    local current = StateManager.state

    -- Navigate to parent
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current) ~= "table" then
            return false
        end
        if not current[key] then
            current[key] = {}
        end
        current = current[key]
    end

    -- Save snapshot before change
    saveStateSnapshot(description or ("Set " .. path))

    -- Set the value
    local finalKey = keys[#keys]
    current[finalKey] = value

    -- Notify listeners
    private.Core.StateManager.notifyStateChange(path, value)

    return true
end

function private.Core.StateManager.notifyStateChange(path, newValue)
    local listeners = StateManager.listeners[path] or {}
    for _, listener in ipairs(listeners) do
        local success, error = pcall(listener.callback, newValue, path)
        if not success then
            private.Core.Logger.error("StateManager", "Listener error for path " .. path .. ": " .. tostring(error))
        end
    end

    -- Also notify wildcard listeners (listening to parent paths)
    local pathParts = {strsplit(".", path)}
    for i = 1, #pathParts - 1 do
        local parentPath = table.concat(pathParts, ".", 1, i)
        local parentListeners = StateManager.listeners[parentPath] or {}
        for _, listener in ipairs(parentListeners) do
            if listener.includeChildren then
                local success, error = pcall(listener.callback, newValue, path)
                if not success then
                    private.Core.Logger.error(
                        "StateManager",
                        "Parent listener error for path " .. parentPath .. ": " .. tostring(error)
                    )
                end
            end
        end
    end
end

function private.Core.StateManager.subscribe(path, callback, owner, includeChildren)
    if not StateManager.listeners[path] then
        StateManager.listeners[path] = {}
    end

    table.insert(
        StateManager.listeners[path],
        {
            callback = callback,
            owner = owner or "unknown",
            includeChildren = includeChildren or false
        }
    )
end

function private.Core.StateManager.unsubscribe(path, owner)
    local listeners = StateManager.listeners[path]
    if not listeners then
        return
    end

    for i = #listeners, 1, -1 do
        if listeners[i].owner == owner then
            table.remove(listeners, i)
        end
    end
end

-----------------------------------------------------------------------------------------
-- Event-Driven State Updates ----------------------------------------------------------
-----------------------------------------------------------------------------------------

local function setupEventListeners() -- Use centralized event constants to avoid string duplication errors
    local events = private.constants.events

    -- Application startup event
    private.Core.registerCallback(
        events.AddonStartup,
        function(startupData)
            private.Core.Logger.trace(
                "StateManager",
                "AddonStartup event received - version: " .. tostring(startupData.version)
            )

            -- Load saved state from database
            private.Core.StateManager.loadState()

            -- Initialize state with startup data
            private.Core.StateManager.setState(
                "settings.debugMode",
                startupData.debugMode or false,
                "Debug mode initialized"
            ) -- Initialize Timeline component
            if private.Core.Timeline then
                private.Core.Logger.trace("StateManager", "Initializing Timeline component")
                private.Core.Timeline.Init()
            end

            private.Core.Logger.trace("StateManager", "Application startup initialization completed")
        end,
        "StateManager"
    )

    -- Application shutdown event
    private.Core.registerCallback(
        events.AddonShutdown,
        function()
            private.Core.Logger.trace("StateManager", "Application shutdown event received")

            -- Save current state before shutdown
            private.Core.StateManager.saveState()

            -- Clean up listeners and state
            StateManager.listeners = {}

            private.Core.Logger.trace("StateManager", "Application shutdown cleanup completed")
        end,
        "StateManager"
    )
    -- Event selection
    private.Core.registerCallback(
        events.EventSelected,
        function(eventData)
            -- Store only the event ID instead of the full object
            local eventId = eventData and eventData.id or nil
            private.Core.StateManager.setState("ui.selectedEvent", eventId, "Event selected")
        end,
        "StateManager"
    )
    -- Character selection
    private.Core.registerCallback(
        events.CharacterSelected,
        function(characterData)
            -- Store only the character ID instead of the full object
            local characterId = characterData and characterData.id or nil
            private.Core.StateManager.setState("ui.selectedCharacter", characterId, "Character selected")
        end,
        "StateManager"
    )
    -- Faction selection
    private.Core.registerCallback(
        events.FactionSelected,
        function(factionData)
            -- Store only the faction ID instead of the full object
            local factionId = factionData and factionData.id or nil
            private.Core.StateManager.setState("ui.selectedFaction", factionId, "Faction selected")
        end,
        "StateManager"
    )

    -- Timeline period selection
    private.Core.registerCallback(
        events.TimelinePeriodSelected,
        function(periodData)
            private.Core.StateManager.setState("ui.selectedPeriod", periodData, "Timeline period selected")
        end,
        "StateManager"
    )

    -- Main frame state
    private.Core.registerCallback(
        events.MainFrameUIOpenFrame,
        function()
            private.Core.StateManager.setState("ui.isMainFrameOpen", true, "Main frame opened")
        end,
        "StateManager"
    )

    private.Core.registerCallback(
        events.MainFrameUICloseFrame,
        function()
            private.Core.StateManager.setState("ui.isMainFrameOpen", false, "Main frame closed")
        end,
        "StateManager"
    )
end

-----------------------------------------------------------------------------------------
-- State Persistence -------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.saveState()
    if Chronicles and Chronicles.db then
        Chronicles.db.global.uiState = deepCopy(StateManager.state.ui)
        Chronicles.db.global.timelineState = deepCopy(StateManager.state.timeline)
        Chronicles.db.global.settingsState = deepCopy(StateManager.state.settings)
        Chronicles.db.global.dataState = deepCopy(StateManager.state.data)
    end
end

function private.Core.StateManager.loadState()
    if Chronicles and Chronicles.db then
        -- Load UI state with fallback to defaults
        if Chronicles.db.global.uiState then
            StateManager.state.ui = deepCopy(Chronicles.db.global.uiState)
        end

        -- Load timeline state with fallback to defaults
        if Chronicles.db.global.timelineState then
            StateManager.state.timeline = deepCopy(Chronicles.db.global.timelineState)
        end

        -- Load settings state with fallback to defaults
        if Chronicles.db.global.settingsState then
            StateManager.state.settings = deepCopy(Chronicles.db.global.settingsState)
        end
        -- Load data state with fallback to defaults
        if Chronicles.db.global.dataState then
            StateManager.state.data = deepCopy(Chronicles.db.global.dataState)
        end
    end -- Mark as loaded to prevent library registrations from overriding saved state
    StateManager.isLoaded = true

    -- Trigger notifications for loaded state values that UI components need to react to
    -- This ensures UI components respond to loaded state even if they weren't initialized when state was loaded
    if StateManager.state.ui.selectedPeriod then
        private.Core.Logger.trace("StateManager", "Triggering selectedPeriod notification after state load")
        private.Core.StateManager.notifyStateChange("ui.selectedPeriod", StateManager.state.ui.selectedPeriod)
    end

    if StateManager.state.ui.selectedEvent then
        private.Core.Logger.trace("StateManager", "Triggering selectedEvent notification after state load")
        private.Core.StateManager.notifyStateChange("ui.selectedEvent", StateManager.state.ui.selectedEvent)
    end

    if StateManager.state.ui.selectedCharacter then
        private.Core.Logger.trace("StateManager", "Triggering selectedCharacter notification after state load")
        private.Core.StateManager.notifyStateChange(
            "ui.selectedCharacter",
            StateManager.state.ui.selectedCharacter,
            nil
        )
    end

    if StateManager.state.ui.selectedFaction then
        private.Core.Logger.trace("StateManager", "Triggering selectedFaction notification after state load")
        private.Core.StateManager.notifyStateChange("ui.selectedFaction", StateManager.state.ui.selectedFaction, nil)
    end

    -- Also schedule a delayed notification to catch any UI components that subscribe after initial load
    C_Timer.After(
        0.5,
        function()
            if StateManager.state.ui.selectedPeriod then
                private.Core.Logger.trace("StateManager", "Triggering delayed selectedPeriod notification")
                private.Core.StateManager.notifyStateChange(
                    "ui.selectedPeriod",
                    StateManager.state.ui.selectedPeriod,
                    nil
                )
            end
        end
    )
end

-----------------------------------------------------------------------------------------
-- State Debugging ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.dumpState(path)
    local state = private.Core.StateManager.getState(path)
    private.Core.Logger.trace("StateManager", "State dump" .. (path and (" for " .. path) or "") .. ":")
    private.Core.StateManager.printTable(state, 0)
end

function private.Core.StateManager.printTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    if type(t) ~= "table" then
        private.Core.Logger.trace("StateManager", prefix .. tostring(t))
        return
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            private.Core.Logger.trace("StateManager", prefix .. tostring(k) .. ":")
            private.Core.StateManager.printTable(v, indent + 1)
        else
            private.Core.Logger.trace("StateManager", prefix .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

function private.Core.StateManager.getHistory(count)
    count = count or 10
    local history = {}
    local startIndex = math.max(1, #StateManager.history - count + 1)

    for i = startIndex, #StateManager.history do
        table.insert(history, StateManager.history[i])
    end

    return history
end

-----------------------------------------------------------------------------------------
-- Initialization -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.init()
    -- Set up event listeners first
    setupEventListeners()

    -- Load state from database
    private.Core.StateManager.loadState()

    -- Set up auto-save timer (save every 30 seconds)
    if not StateManager.autoSaveTimer then
        StateManager.autoSaveTimer =
            C_Timer.NewTicker(
            30,
            function()
                private.Core.StateManager.saveState()
            end
        )
    end

    private.Core.Logger.trace("StateManager", "StateManager initialized successfully")
end

-- Console commands for state debugging
SLASH_CHRONICLESSTATEDEBUG1 = "/cstatedebug"
SlashCmdList["CHRONICLESSTATEDEBUG"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1]

    if command == "dump" then
        local path = args[2]
        private.Core.StateManager.dumpState(path)
    elseif command == "history" then
        local count = tonumber(args[2]) or 5
        local history = private.Core.StateManager.getHistory(count)
        private.Core.Logger.trace("StateManager", "State History:")
        for _, entry in ipairs(history) do
            local timeStr = date("%H:%M:%S", entry.timestamp)
            private.Core.Logger.trace("StateManager", string.format("[%s] %s", timeStr, entry.description))
        end
    elseif command == "get" then
        local path = args[2]
        if path then
            local value = private.Core.StateManager.getState(path)
            private.Core.Logger.trace("StateManager", path .. ": " .. tostring(value))
        else
            private.Core.Logger.error("StateManager", "Please specify a state path")
        end
    elseif command == "set" then
        local path = args[2]
        local value = args[3]
        if path and value then
            -- Try to convert value to appropriate type
            local numValue = tonumber(value)
            if numValue then
                value = numValue
            elseif value == "true" then
                value = true
            elseif value == "false" then
                value = false
            elseif value == "nil" then
                value = nil
            end
            private.Core.StateManager.setState(path, value, "Manual state change")
            private.Core.Logger.trace("StateManager", "Set " .. path .. " to " .. tostring(value))
        else
            private.Core.Logger.error("StateManager", "Please specify path and value")
        end
    else
        private.Core.Logger.trace("StateManager", "Commands:")
        private.Core.Logger.trace("StateManager", "  /cstatedebug dump [path] - Dump current state")
        private.Core.Logger.trace("StateManager", "  /cstatedebug history [count] - Show state change history")
        private.Core.Logger.trace("StateManager", "  /cstatedebug get <path> - Get state value")
        private.Core.Logger.trace("StateManager", "  /cstatedebug set <path> <value> - Set state value")
    end
end
