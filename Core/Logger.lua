local FOLDER_NAME, private = ...

private.Core.Logger = {}

-----------------------------------------------------------------------------------------
-- Logger Constants and Configuration --------------------------------------------------
-----------------------------------------------------------------------------------------

-- Log levels
private.Core.Logger.LOG_LEVELS = {
    TRACE = 1,
    WARN = 2,
    ERROR = 3,
}

-- Color codes for log levels
private.Core.Logger.LOG_COLORS = {
    TRACE = "|cFF00FFFF", -- Cyan
    WARN = "|cFFFFFF00", -- Yellow
    ERROR = "|cFFFF0000", -- Red
    RESET = "|r"
}

-- Simple configuration
local config = {
    enabled = true,
    logLevel = "WARN", -- Only show warnings, errors by default
    maxLogHistory = 500
}

-- Log history storage
local logHistory = {}

-----------------------------------------------------------------------------------------
-- Core Logging Functions --------------------------------------------------------------
-----------------------------------------------------------------------------------------

local function shouldLog(level)
    return config.enabled and private.Core.Logger.LOG_LEVELS[level] >= private.Core.Logger.LOG_LEVELS[config.logLevel]
end

local function formatMessage(level, module, message)
    local color = private.Core.Logger.LOG_COLORS[level]
    local reset = private.Core.Logger.LOG_COLORS.RESET
    local modulePrefix = module and string.format("[%s] ", module) or ""

    return string.format("%s[Chronicles] %s%s%s", color, modulePrefix, message, reset)
end

-- Main logging function
function private.Core.Logger.log(level, module, message)
    if not shouldLog(level) then
        return
    end

    local formattedMessage = formatMessage(level, module, message)

    -- Add to history
    table.insert(
        logHistory,
        {
            timestamp = GetServerTime(),
            level = level,
            module = module,
            message = message,
            formattedMessage = formattedMessage
        }
    ) -- Maintain history size
    if #logHistory > config.maxLogHistory then
        table.remove(logHistory, 1)
    end

    -- Output to default chat frame instead of print
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(formattedMessage)
    end
end

-- Convenience logging functions
function private.Core.Logger.trace(module, message)
    private.Core.Logger.log("TRACE", module, message)
end

function private.Core.Logger.warn(module, message)
    private.Core.Logger.log("WARN", module, message)
end

function private.Core.Logger.error(module, message)
    private.Core.Logger.log("ERROR", module, message)
    --error(message) -- Use error to throw an error in Lua
end

-----------------------------------------------------------------------------------------
-- Simple Configuration Functions ------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.Logger.setEnabled(enabled)
    config.enabled = enabled
    local status = enabled and "enabled" or "disabled"
    local message =
        string.format(
        "%s[Chronicles Logger]%s Debug logging %s",
        private.Core.Logger.LOG_COLORS.INFO,
        private.Core.Logger.LOG_COLORS.RESET,
        status
    )
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

function private.Core.Logger.setLogLevel(level)
    level = string.upper(level)
    if private.Core.Logger.LOG_LEVELS[level] then
        config.logLevel = level
        local message =
            string.format(
            "%s[Chronicles Logger]%s Log level set to %s",
            private.Core.Logger.LOG_COLORS.INFO,
            private.Core.Logger.LOG_COLORS.RESET,
            level
        )
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        end
    else
        local message =
            string.format(
            "%s[Chronicles Logger]%s Invalid log level: %s",
            private.Core.Logger.LOG_COLORS.ERROR,
            private.Core.Logger.LOG_COLORS.RESET,
            tostring(level)
        )
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        end
    end
end

function private.Core.Logger.isEnabled()
    return config.enabled
end

function private.Core.Logger.getLogLevel()
    return config.logLevel
end

-----------------------------------------------------------------------------------------
-- Log History Management ---------------------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.Logger.getLogHistory(count, level, module)
    count = count or 50
    local filteredHistory = {}

    for i = #logHistory, 1, -1 do
        local entry = logHistory[i]

        -- Apply filters
        if (not level or entry.level == level) and (not module or entry.module == module) then
            table.insert(filteredHistory, entry)

            if #filteredHistory >= count then
                break
            end
        end
    end

    return filteredHistory
end

function private.Core.Logger.printLogHistory(count, level, module)
    local history = private.Core.Logger.getLogHistory(count, level, module)

    local filterDesc = ""
    if level or module then
        local parts = {}
        if level then
            table.insert(parts, "level=" .. level)
        end
        if module then
            table.insert(parts, "module=" .. module)
        end
        filterDesc = " (" .. table.concat(parts, ", ") .. ")"
    end
    local headerMessage =
        string.format(
        "%s[Chronicles Logger]%s Log History%s:",
        private.Core.Logger.LOG_COLORS.INFO,
        private.Core.Logger.LOG_COLORS.RESET,
        filterDesc
    )
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(headerMessage)
    end

    for i = #history, 1, -1 do
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(history[i].formattedMessage)
        end
    end
end

function private.Core.Logger.clearLogHistory()
    logHistory = {}
    private.Core.Logger.trace("Logger", "Log history cleared")
end

-----------------------------------------------------------------------------------------
-- Stack Traces and Error Handling -----------------------------------------------------
-----------------------------------------------------------------------------------------

function private.Core.Logger.getStackTrace(skipLevels)
    skipLevels = (skipLevels or 0) + 2 -- Skip this function and the caller

    local trace = {}
    local level = skipLevels

    while true do
        local info = debuginfo and debuginfo(level, "Sln") or nil
        if not info then
            break
        end

        local funcName = info.name or "anonymous"
        local source = info.short_src or "unknown"
        local line = info.currentline or 0

        table.insert(trace, string.format("%s:%d in %s", source, line, funcName))
        level = level + 1

        if level > 10 then -- Limit stack depth
            table.insert(trace, "...")
            break
        end
    end

    return trace
end

function private.Core.Logger.logError(module, message, err)
    -- Log the main error
    private.Core.Logger.error(module, message)

    -- If an error object is provided, log additional details
    if err then
        private.Core.Logger.error(module, "Error details: " .. tostring(err))
    end

    -- Get and log stack trace
    local trace = private.Core.Logger.getStackTrace(1)
    if #trace > 0 then
        private.Core.Logger.error(module, "Stack trace:")
        for i, line in ipairs(trace) do
            private.Core.Logger.error(module, "  " .. i .. ": " .. line)
        end
    end
end

-- Wrapper for pcall that automatically logs errors
function private.Core.Logger.safecall(func, module, description, ...)
    local success, result = pcall(func, ...)

    if not success then
        local errorMsg = description and (description .. ": " .. tostring(result)) or tostring(result)
        private.Core.Logger.logError(module or "Unknown", errorMsg, result)
        return false, result
    end

    return true, result
end
