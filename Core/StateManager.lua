local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

private.Core.StateManager = {}

-----------------------------------------------------------------------------------------
-- State Management ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

local StateManager = {
    state = {
        ui = {
            selectedEvent = nil,
            selectedCharacter = nil,
            selectedFaction = nil,
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
    listeners = {}
}

-----------------------------------------------------------------------------------------
-- State History & Undo/Redo ----------------------------------------------------------
-----------------------------------------------------------------------------------------

local function saveStateSnapshot(description)
    local snapshot = {
        timestamp = GetServerTime(),
        description = description or "State change",
        state = private.Core.StateManager.deepCopy(StateManager.state)
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

function private.Core.StateManager.deepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for key, value in next, original, nil do
            copy[private.Core.StateManager.deepCopy(key)] = private.Core.StateManager.deepCopy(value)
        end
        setmetatable(copy, private.Core.StateManager.deepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

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
    local oldValue = current[finalKey]
    current[finalKey] = value

    -- Notify listeners
    private.Core.StateManager.notifyStateChange(path, value, oldValue)

    return true
end

function private.Core.StateManager.notifyStateChange(path, newValue, oldValue)
    local listeners = StateManager.listeners[path] or {}

    for _, listener in ipairs(listeners) do
        local success, error = pcall(listener.callback, newValue, oldValue, path)
        if not success then
            if private.Core.EventManager then
                private.Core.EventManager.Debugger:logEvent(
                    "StateManager.ListenerError",
                    {path = path, error = error},
                    listener.owner,
                    true
                )
            end
        end
    end

    -- Also notify wildcard listeners (listening to parent paths)
    local pathParts = {strsplit(".", path)}
    for i = 1, #pathParts - 1 do
        local parentPath = table.concat(pathParts, ".", 1, i)
        local parentListeners = StateManager.listeners[parentPath] or {}

        for _, listener in ipairs(parentListeners) do
            if listener.includeChildren then
                local success, error = pcall(listener.callback, newValue, oldValue, path)
                if not success and private.Core.EventManager then
                    private.Core.EventManager.Debugger:logEvent(
                        "StateManager.ListenerError",
                        {path = parentPath, error = error},
                        listener.owner,
                        true
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

local function setupEventListeners()
    -- Event selection
    private.Core.registerCallback(
        private.constants.events.EventSelected,
        function(eventData)
            private.Core.StateManager.setState("ui.selectedEvent", eventData, "Event selected")
        end,
        "StateManager"
    )    -- Character selection
    private.Core.registerCallback(
        private.constants.events.CharacterSelected,
        function(characterData)
            private.Core.StateManager.setState("ui.selectedCharacter", characterData, "Character selected")
        end,
        "StateManager"
    )    -- Faction selection
    private.Core.registerCallback(
        private.constants.events.FactionSelected,
        function(factionData)
            private.Core.StateManager.setState("ui.selectedFaction", factionData, "Faction selected")
        end,
        "StateManager"
    )    -- Timeline period selection
    private.Core.registerCallback(
        private.constants.events.TimelinePeriodSelected,
        function(periodData)
            private.Core.StateManager.setState("ui.selectedPeriod", periodData, "Timeline period selected")
        end,
        "StateManager"
    )    -- Timeline step changes
    private.Core.registerCallback(
        private.constants.events.TimelineStepChanged,
        function(stepData)
            private.Core.StateManager.setState("timeline.currentStep", stepData, "Timeline step changed")
        end,
        "StateManager"
    )    -- Main frame state
    private.Core.registerCallback(
        private.constants.events.MainFrameUIOpenFrame,
        function()
            private.Core.StateManager.setState("ui.isMainFrameOpen", true, "Main frame opened")
        end,
        "StateManager"
    )    private.Core.registerCallback(
        private.constants.events.MainFrameUICloseFrame,
        function()
            private.Core.StateManager.setState("ui.isMainFrameOpen", false, "Main frame closed")
        end,
        "StateManager"
    )    -- Settings changes
    private.Core.registerCallback(
        private.constants.events.SettingsEventTypeChecked,
        function(data)
            local path = "settings.eventTypes." .. tostring(data.eventType)
            private.Core.StateManager.setState(path, data.checked, "Event type setting changed")
        end,
        "StateManager"
    )    private.Core.registerCallback(
        private.constants.events.SettingsLibraryChecked,
        function(data)
            local path = "settings.libraries." .. tostring(data.library)
            private.Core.StateManager.setState(path, data.checked, "Library setting changed")
        end,
        "StateManager"
    )
end

-----------------------------------------------------------------------------------------
-- State Persistence -------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.saveState()
    if Chronicles and Chronicles.db then
        Chronicles.db.global.uiState = private.Core.StateManager.deepCopy(StateManager.state.ui)
        Chronicles.db.global.timelineState = private.Core.StateManager.deepCopy(StateManager.state.timeline)
    end
end

function private.Core.StateManager.loadState()
    if Chronicles and Chronicles.db then
        if Chronicles.db.global.uiState then
            StateManager.state.ui = private.Core.StateManager.deepCopy(Chronicles.db.global.uiState)
        end
        if Chronicles.db.global.timelineState then
            StateManager.state.timeline = private.Core.StateManager.deepCopy(Chronicles.db.global.timelineState)
        end
    end
end

-----------------------------------------------------------------------------------------
-- State Debugging ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.StateManager.dumpState(path)
    local state = private.Core.StateManager.getState(path)
    print("|cFF00FF00[Chronicles StateManager]|r State dump" .. (path and (" for " .. path) or "") .. ":")
    private.Core.StateManager.printTable(state, 0)
end

function private.Core.StateManager.printTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    if type(t) ~= "table" then
        print(prefix .. tostring(t))
        return
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            private.Core.StateManager.printTable(v, indent + 1)
        else
            print(prefix .. tostring(k) .. ": " .. tostring(v))
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
    -- Set up event listeners
    C_Timer.After(0.1, setupEventListeners) -- Delay to ensure EventManager is loaded

    -- Load saved state
    private.Core.StateManager.loadState()

    -- Auto-save state periodically
    C_Timer.NewTicker(
        30,
        function()
            private.Core.StateManager.saveState()
        end
    )
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
        print("|cFF00FF00[Chronicles StateManager]|r State History:")
        for _, entry in ipairs(history) do
            local timeStr = date("%H:%M:%S", entry.timestamp)
            print(string.format("[%s] %s", timeStr, entry.description))
        end
    elseif command == "get" then
        local path = args[2]
        if path then
            local value = private.Core.StateManager.getState(path)
            print("|cFF00FF00[Chronicles StateManager]|r " .. path .. ": " .. tostring(value))
        else
            print("|cFFFF0000Error:|r Please specify a state path")
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
            print("|cFF00FF00[Chronicles StateManager]|r Set " .. path .. " to " .. tostring(value))
        else
            print("|cFFFF0000Error:|r Please specify path and value")
        end
    else
        print("|cFF00FF00[Chronicles StateManager]|r Commands:")
        print("  /cstatedebug dump [path] - Dump current state")
        print("  /cstatedebug history [count] - Show state change history")
        print("  /cstatedebug get <path> - Get state value")
        print("  /cstatedebug set <path> <value> - Set state value")
    end
end
