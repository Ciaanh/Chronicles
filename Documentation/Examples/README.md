# Plugin Development Examples

This directory contains practical examples and code samples for developing plugins that integrate with the Chronicles addon.

## Available Examples

### PluginExample.lua

A comprehensive example plugin demonstrating:

-   **Event System Integration**: How to register custom events and listen to Chronicles core events
-   **State Management**: Working with the Chronicles StateManager
-   **Error Handling**: Best practices for handling errors and validation
-   **Plugin Architecture**: Proper namespace setup and initialization patterns

## Using the Examples

### 1. Plugin Integration

To integrate the example plugin into your Chronicles installation:

1. Copy `PluginExample.lua` to your addon directory
2. Add it to your addon's TOC file or XML manifest
3. Ensure proper initialization order (after Chronicles core systems)

### 2. Testing Features

The example plugin provides console commands for testing:

```
/exampleplugin trigger [type] - Trigger custom event
/exampleplugin state - Demonstrate state management
/exampleplugin error - Demonstrate error handling
/exampleplugin info - Show plugin state
```

## Plugin Development Guidelines

### Event System Usage

-   Always check for system availability before registration
-   Use proper validation schemas for custom events
-   Implement error handling for event registration failures
-   Use descriptive event names following the pattern: `Plugin.PluginName.EVENT_NAME`

### State Management

-   Namespace plugin state under `plugins.yourPluginName`
-   Subscribe to relevant Chronicles state changes
-   Use descriptive state paths and change descriptions
-   Clean up subscriptions when appropriate

### Error Handling

-   Validate input data before processing
-   Provide meaningful error messages
-   Use Chronicles logging system when available
-   Fail gracefully when dependencies are unavailable

### Initialization

-   Wait for Chronicles core systems to load completely
-   Check for dependency availability
-   Initialize in proper order: events → listeners → state
-   Provide user feedback during initialization

## Integration Points

The example demonstrates integration with these Chronicles systems:

### Core Event Manager

-   `private.Core.EventManager.safeRegisterCallback()` - Safe event listening
-   `private.Core.EventManager.PluginEvents` - Custom plugin event system
-   Event validation and error reporting

### State Manager

-   `private.Core.StateManager.setState()` - Setting plugin state
-   `private.Core.StateManager.getState()` - Reading Chronicles state
-   `private.Core.StateManager.subscribe()` - State change notifications

### Timeline Events

-   `private.constants.events.EventSelected` - Timeline event selection
-   `private.constants.events.TimelinePeriodSelected` - Period navigation
-   Timeline data integration

## Best Practices Demonstrated

### 1. Defensive Programming

```lua
if not private.Core.EventManager or not private.Core.EventManager.PluginEvents then
    print("|cFFFF0000[ExamplePlugin]|r EventManager not available")
    return false
end
```

### 2. Proper Event Validation

```lua
validate = function(data)
    if not data then return false, "Event data is nil" end
    if type(data.actionType) ~= "string" then return false, "actionType must be a string" end
    if not data.data then return false, "data field is required" end
    return true, nil
end
```

### 3. State Management

```lua
private.Core.StateManager.setState(
    "plugins.examplePlugin.isActive",
    true,
    "Plugin activated"
)
```

### 4. Event Batching

```lua
private.Core.EventManager.Batcher:addToBatch(
    "period_analysis",
    "Plugin.ExamplePlugin.PERIOD_ANALYZED",
    eventData,
    "ExamplePlugin:OnPeriodSelected"
)
```

## Plugin Architecture

### Namespace Structure

```lua
local FOLDER_NAME, private = ...
local ExamplePlugin = {}
private.ExamplePlugin = ExamplePlugin
```

### Initialization Pattern

```lua
function ExamplePlugin:Initialize()
    -- Wait for Chronicles to be fully loaded
    C_Timer.After(1, function()
        self:RegisterEvents()
        self:SetupEventListeners()
    end)
end
```

### Event Handler Pattern

```lua
function ExamplePlugin:OnEventSelected(eventData)
    -- Process the event
    -- Trigger related actions
    -- Update plugin state
end
```

## Troubleshooting

### Common Issues

1. **EventManager not available**: Chronicles core not loaded yet
2. **Validation failures**: Check event data structure and types
3. **State subscription failures**: Verify StateManager availability
4. **Console command not working**: Check slash command registration

### Debug Commands

Use the provided console commands to test plugin functionality:

-   `/exampleplugin info` - Check current plugin state
-   `/exampleplugin error` - Test error handling
-   `/exampleplugin state` - Test state management

## Further Development

### Extending the Example

-   Add more complex event validation
-   Implement persistent storage
-   Create UI integration
-   Add configuration management
-   Implement plugin-to-plugin communication

### Integration Testing

-   Test with different Chronicles versions
-   Verify compatibility with other plugins
-   Test edge cases and error conditions
-   Performance testing with large datasets

## Related Documentation

-   [Event System Guide](../Development/EVENT_SYSTEM_GUIDE.md)
-   [Implementation Summary](../Development/IMPLEMENTATION_SUMMARY.md)
-   [Timeline Fix Overview](../TIMELINE_FIX_OVERVIEW.md)
