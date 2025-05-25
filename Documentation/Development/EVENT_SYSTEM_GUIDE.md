# Chronicles Event System Guide

## Overview

The Chronicles addon now features an enhanced event system with validation, error handling, debugging tools, state management, and performance monitoring.

## Key Components

### 1. EventManager (`Core/EventManager.lua`)

-   **Safe Event Triggering**: `private.Core.EventManager.safeTrigger(eventName, data, context)`
-   **Safe Event Registration**: `private.Core.EventManager.safeRegisterCallback(eventName, callback, owner)`
-   **Event Validation**: Automatic schema validation for known events
-   **Error Handling**: Safe event execution with error boundaries
-   **Event Debugging**: Event history tracking and console commands

### 2. StateManager (`Core/StateManager.lua`)

-   **Centralized State**: Manage application state with event-driven mutations
-   **State Persistence**: Automatic saving/loading to savedvariables
-   **Change Notifications**: Listen for state changes with callbacks
-   **State Debugging**: Console commands for state inspection

### 3. EventPerformance (`Core/EventPerformance.lua`)

-   **Performance Monitoring**: Track event execution times
-   **Slow Event Detection**: Automatic reporting of performance issues
-   **Performance Analytics**: Detailed timing analysis and reporting

## Console Commands

### Event Debugging

-   `/ceventdebug on|off` - Toggle event debugging
-   `/ceventdebug history [count]` - Show recent event history
-   `/ceventdebug stats` - Show event statistics
-   `/ceventdebug clear` - Clear event history

### State Management

-   `/cstatedebug get <path>` - Get state value (e.g., "ui.selectedEvent")
-   `/cstatedebug set <path> <value>` - Set state value
-   `/cstatedebug history` - Show state change history
-   `/cstatedebug listeners` - Show active state listeners

### Performance Monitoring

-   `/ceventperf on|off` - Toggle performance monitoring
-   `/ceventperf report` - Generate performance report
-   `/ceventperf slow [threshold]` - Show slow events (default 10ms)
-   `/ceventperf clear` - Clear performance data

## Usage Examples

### Triggering Events Safely

```lua
-- Old way (direct EventRegistry)
EventRegistry:TriggerEvent(private.constants.events.EventSelected, eventData)

-- New way (with error handling and validation)
private.Core.EventManager.safeTrigger(
    private.constants.events.EventSelected,
    {eventId = 123, eventName = "Battle of Stormwind"},
    "EventList:OnClick"
)
```

### Registering Event Callbacks

```lua
-- Old way
EventRegistry:RegisterCallback(eventName, self.OnEvent, self)

-- New way (with error handling)
private.Core.EventManager.safeRegisterCallback(eventName, self.OnEvent, self)
```

### State Management

```lua
-- Get current state
local selectedEvent = private.Core.StateManager.get("ui.selectedEvent")

-- Set state (triggers notifications)
private.Core.StateManager.set("timeline.currentStep", 5)

-- Listen for state changes
private.Core.StateManager.addListener("ui.selectedEvent", function(newValue, oldValue)
    print("Selected event changed:", newValue)
end)
```

## Plugin Development

### Custom Event Registration

```lua
-- Register custom events with schemas
private.Core.EventManager.registerPluginEvent("MyPlugin.CustomEvent", {
    eventId = "number",
    customData = "string"
})

-- Trigger custom events
private.Core.EventManager.safeTrigger(
    "MyPlugin.CustomEvent",
    {eventId = 1, customData = "test"},
    "MyPlugin:SomeFunction"
)
```

### State Integration

```lua
-- Use plugin-specific state paths
private.Core.StateManager.set("plugins.MyPlugin.config", {
    enabled = true,
    setting1 = "value"
})
```

## Backward Compatibility

The system maintains full backward compatibility. All existing EventRegistry calls continue to work, but new code should use the enhanced EventManager for better error handling and debugging capabilities.

## Performance Considerations

-   Event validation adds minimal overhead (~0.1ms per event)
-   Performance monitoring can be disabled in production
-   State persistence happens asynchronously
-   Event history is limited to prevent memory leaks

## Configuration

Event system behavior can be configured in `Constants.lua`:

```lua
config = {
    eventSystem = {
        enableValidation = true,
        enableDebugMode = false,
        enablePerformanceMonitoring = true,
        maxEventHistory = 100,
        slowEventThreshold = 10 -- milliseconds
    }
}
```
