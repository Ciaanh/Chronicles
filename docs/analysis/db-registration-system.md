# DB Registration System Analysis

## Summary

The current registration system mixes internal (sample) DB loading with external plugin registration through a single `ChroniclesPluginData.Register()` global function. This creates coupling, limits extensibility, and makes the external plugin pattern fragile.

## Current Architecture

### Registration Flow

```
File Load Phase:
  DB/01_Sample/*.lua → create globals (SampleEventsDB, etc.)
  DB/DB.lua → define ChroniclesPluginData.Register()

Runtime (OnInitialize):
  Chronicles.Data:Load()
    → ChroniclesPluginData.Register()
      → DataRegistry:RegisterEventDB("Sample", SampleEventsDB)
      → DataRegistry:RegisterFactionDB("Sample", SampleFactionsDB)
      → DataRegistry:RegisterCharacterDB("Sample", SampleCharactersDB)
```

### External Plugin Pattern (current)

```lua
-- Option 1: Override ChroniclesPluginData.Register (only supports ONE plugin)
function ChroniclesPluginData.Register()
    DataRegistry:RegisterEventDB("MyPlugin", myData)
end

-- Option 2: Use public API (must run AFTER Chronicles loads)
Chronicles:RegisterPluginDB("PluginName", pluginDatabase)
```

## Issues

### 1. Internal/External DB Loading Mixed in DB.lua

`DB.lua` serves two purposes:
- Defines the global `ChroniclesPluginData` registration hook
- Registers the bundled Sample databases

These should be separated. Internal (bundled) data should be loaded by `Core/Data.lua` directly. The plugin hook should only serve external addons.

### 2. Single-Slot Plugin Hook

`ChroniclesPluginData.Register()` is a single function — if two external plugins both set it, the second overwrites the first. Only one external plugin can use this pattern.

### 3. No Plugin Discovery

Chronicles has no way to discover plugins. External addons must:
- Know the exact API name
- Check `_G.Chronicles` existence
- Handle timing (must load after Chronicles)
- Get no feedback on success/failure

### 4. Silent Failures

All `DataRegistry.registerEventDB()` failures return `false` with no error message:
- Missing Chronicles reference → silent fail
- Invalid collection name → silent fail  
- Duplicate collection name → silent fail

### 5. API Naming Inconsistency

| Layer | Method | Case |
|-------|--------|------|
| DataRegistry (internal) | `registerEventDB()` | camelCase |
| Chronicles.Data (proxy) | `RegisterEventDB()` | PascalCase |
| Chronicles (public) | `RegisterPluginDB()` | PascalCase |

### 6. RegisterPluginDB Only Supports Events

```lua
function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.Data:RegisterEventDB(pluginName, db)  -- events only!
end
```

External plugins cannot register Characters or Factions through the public API.

## Design Directions

### Option A: Callback Queue Pattern

```lua
-- Chronicles exposes a registration queue
Chronicles.RegisterPlugin = function(pluginName, pluginData)
    -- pluginData = { events = {}, characters = {}, factions = {} }
    -- Registers all three data types at once
    -- Returns success/failure with reason
end
```

### Option B: Event-Driven Registration

```lua
-- Chronicles fires an event when ready for plugin registration
-- Plugins listen and register when called
private.Core.triggerEvent("CHRONICLES_READY")

-- External plugins register a callback
Chronicles:OnReady(function()
    Chronicles:RegisterPlugin("MyPlugin", { events = myEvents })
end)
```

### Option C: Declarative Plugin Manifest

```lua
-- Plugin defines a manifest table; Chronicles discovers and loads it
ChroniclesPlugins = ChroniclesPlugins or {}
ChroniclesPlugins["MyPlugin"] = {
    events = myEventsDB,
    characters = myCharactersDB,
    factions = myFactionsDB,
}
-- Chronicles iterates ChroniclesPlugins during Load()
```

### Recommendation

Option C (declarative manifest) is simplest and most robust:
- Supports multiple plugins naturally (table keys)
- No timing issues (table populated during file load)  
- No function overwriting
- Chronicles controls when/how to process registrations
- Easy to validate and report errors

Combined with separating internal DB loading from the plugin system.

## Implemented Design

**Status**: Implemented

The following changes were made:

1. **`DB/DB.lua`** — Now internal-only. Defines `private.registerInternalDBs()` to register bundled Sample databases. No longer creates `ChroniclesPluginData` global.

2. **`Core/Data.lua:Load()`** — Multi-phase loading:
   - Calls `private.registerInternalDBs()` for bundled data
   - Calls `Chronicles.Data:LoadPluginManifests()` to process any early `ChroniclesPlugins` entries
   - Legacy compat: still calls `ChroniclesPluginData.Register()` if it exists (deprecated)
   - Registers `ADDON_LOADED` listener to re-scan `ChroniclesPlugins` when later addons load

3. **`Chronicles:RegisterPluginDB()`** — Now supports manifest-style registration:
   - `{ events = {...}, characters = {...}, factions = {...} }` — registers all data types
   - Raw events table still works for backward compatibility

4. **`ChroniclesPlugins` global table** — Declarative external plugin pattern:
   ```lua
   ChroniclesPlugins = ChroniclesPlugins or {}
   ChroniclesPlugins["MyPlugin"] = {
       events     = myEventsDB,
       characters = myCharactersDB,
       factions   = myFactionsDB,
   }
   ```
   Safe regardless of load order: Chronicles re-scans the table on each `ADDON_LOADED` event.
   Already-registered collections are skipped (idempotent).
