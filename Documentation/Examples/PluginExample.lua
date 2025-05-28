--[[
    Example plugin demonstrating how to use the Chronicles Event System
    This file shows best practices for plugin developers
]]
local FOLDER_NAME, private = ...

-- Example plugin namespace
local ExamplePlugin = {}
private.ExamplePlugin = ExamplePlugin

-----------------------------------------------------------------------------------------
-- Plugin Event Registration -----------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:RegisterEvents()
    if not private.Core.EventManager or not private.Core.EventManager.PluginEvents then
        print("|cFFFF0000[ExamplePlugin]|r EventManager not available")
        return false
    end

    -- Register custom plugin events with schemas
    local success =
        private.Core.EventManager.PluginEvents:registerPluginEvent(
        "ExamplePlugin",
        "CUSTOM_EVENT_TRIGGERED",
        {
            description = "Fired when example plugin performs a custom action",
            required = {"actionType", "data"},
            validate = function(data)
                if not data then
                    return false, "Event data is nil"
                end
                if type(data.actionType) ~= "string" then
                    return false, "actionType must be a string"
                end
                if not data.data then
                    return false, "data field is required"
                end
                return true, nil
            end
        }
    )

    if success then
        print("|cFF00FF00[ExamplePlugin]|r Successfully registered custom events")
    end

    return success
end

-----------------------------------------------------------------------------------------
-- Event Listeners ----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:SetupEventListeners()
    -- Listen to Chronicles core events
    private.Core.registerCallback(
        private.constants.events.EventSelected,
        function(eventData)
            ExamplePlugin:OnEventSelected(eventData)
        end,
        "ExamplePlugin"
    )

    private.Core.registerCallback(
        private.constants.events.TimelinePeriodSelected,
        function(periodData)
            ExamplePlugin:OnPeriodSelected(periodData)
        end,
        "ExamplePlugin"
    )

    -- Subscribe to state changes if StateManager is available
    if private.Core.StateManager then
        private.Core.StateManager.subscribe(
            "ui.selectedEvent",
            function(newEvent, oldEvent, path)
                ExamplePlugin:OnSelectedEventChanged(newEvent, oldEvent)
            end,
            "ExamplePlugin"
        )
    end
end

-----------------------------------------------------------------------------------------
-- Event Handlers -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:OnEventSelected(eventData)
    print("|cFF00FF9A[ExamplePlugin]|r Event selected: " .. (eventData.label or "Unknown"))

    -- Example: Trigger custom plugin event
    self:TriggerCustomEvent(
        "EVENT_INTERACTION",
        {
            eventId = eventData.id,
            timestamp = GetServerTime()
        }
    )
end

function ExamplePlugin:OnPeriodSelected(periodData)
    print("|cFF00FF9A[ExamplePlugin]|r Period selected: " .. periodData.lower .. " - " .. periodData.upper)

    -- Example: Batch multiple events together
    if private.Core.EventManager and private.Core.EventManager.Batcher then
        private.Core.EventManager.Batcher:addToBatch(
            "period_analysis",
            "Plugin.ExamplePlugin.PERIOD_ANALYZED",
            {
                period = periodData,
                analysis = "Sample analysis data"
            },
            "ExamplePlugin:OnPeriodSelected"
        )

        -- Execute batch after a delay
        C_Timer.After(
            0.1,
            function()
                private.Core.EventManager.Batcher:executeBatch("period_analysis")
            end
        )
    end
end

function ExamplePlugin:OnSelectedEventChanged(newEvent, oldEvent)
    if newEvent then
        print("|cFF00FF9A[ExamplePlugin]|r State change detected - New event: " .. newEvent.label)
    else
        print("|cFF00FF9A[ExamplePlugin]|r State change detected - Event deselected")
    end
end

-----------------------------------------------------------------------------------------
-- Custom Event Triggering -------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:TriggerCustomEvent(actionType, data)
    if not private.Core.EventManager or not private.Core.EventManager.PluginEvents then
        return false
    end

    return private.Core.EventManager.PluginEvents:triggerPluginEvent(
        "ExamplePlugin",
        "CUSTOM_EVENT_TRIGGERED",
        {
            actionType = actionType,
            data = data
        },
        "ExamplePlugin:TriggerCustomEvent"
    )
end

-----------------------------------------------------------------------------------------
-- Error Handling Example --------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:DemonstrateErrorHandling()
    -- This will trigger validation error
    local success = self:TriggerCustomEvent(123, nil) -- Invalid data types

    if not success then
        print("|cFFFF0000[ExamplePlugin]|r Failed to trigger custom event - check event log")
    end

    -- This will succeed
    success = self:TriggerCustomEvent("DEMO", {message = "Hello World"})

    if success then
        print("|cFF00FF00[ExamplePlugin]|r Successfully triggered custom event")
    end
end

-----------------------------------------------------------------------------------------
-- State Management Example ------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:DemonstrateStateManagement()
    if not private.Core.StateManager then
        print("|cFFFF0000[ExamplePlugin]|r StateManager not available")
        return
    end

    -- Set plugin-specific state
    private.Core.StateManager.setState("plugins.examplePlugin.isActive", true, "Plugin activated")
    private.Core.StateManager.setState("plugins.examplePlugin.lastAction", GetServerTime(), "Plugin action recorded")

    -- Get current UI state
    local selectedEvent = private.Core.StateManager.getState("ui.selectedEvent")
    if selectedEvent then
        print("|cFF00FF9A[ExamplePlugin]|r Current selected event: " .. selectedEvent.label)
    else
        print("|cFF00FF9A[ExamplePlugin]|r No event currently selected")
    end
end

-----------------------------------------------------------------------------------------
-- Initialization -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------

function ExamplePlugin:Initialize()
    print("|cFF00FF00[ExamplePlugin]|r Initializing...")

    -- Wait for Chronicles to be fully loaded
    C_Timer.After(
        1,
        function()
            self:RegisterEvents()
            self:SetupEventListeners()

            print("|cFF00FF00[ExamplePlugin]|r Initialization complete")

            -- Demo the features
            C_Timer.After(
                2,
                function()
                    self:DemonstrateErrorHandling()
                    self:DemonstrateStateManagement()
                end
            )
        end
    )
end

-- Auto-initialize when loaded
ExamplePlugin:Initialize()

-----------------------------------------------------------------------------------------
-- Console Commands for Testing --------------------------------------------------------
-----------------------------------------------------------------------------------------

SLASH_EXAMPLEPLUGIN1 = "/exampleplugin"
SlashCmdList["EXAMPLEPLUGIN"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1]

    if command == "trigger" then
        local actionType = args[2] or "MANUAL"
        ExamplePlugin:TriggerCustomEvent(actionType, {command = "manual", timestamp = GetServerTime()})
    elseif command == "state" then
        ExamplePlugin:DemonstrateStateManagement()
    elseif command == "error" then
        ExamplePlugin:DemonstrateErrorHandling()
    elseif command == "info" then
        if private.Core.StateManager then
            private.Core.StateManager.dumpState("plugins.examplePlugin")
        end
    else
        print("|cFF00FF00[ExamplePlugin]|r Commands:")
        print("  /exampleplugin trigger [type] - Trigger custom event")
        print("  /exampleplugin state - Demonstrate state management")
        print("  /exampleplugin error - Demonstrate error handling")
        print("  /exampleplugin info - Show plugin state")
    end
end
