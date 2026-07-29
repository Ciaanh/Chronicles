# DB Registration System

Rewritten 2026-07-29 against the working branch. The previous version of this document described the
`ChroniclesPluginData.Register()` global and the `DB/01_Sample` collection; both were deleted, and the
redesign it recommended (Option C, a declarative manifest) is what shipped. What follows is the
system as it exists, plus the issues that are still open.

## Two doors, deliberately separate

Internal (bundled) data and external (plugin) data no longer share a registration path. That
separation was the point of the redesign.

```
File load phase
  DB/NN_<Expansion>/*.lua   assign into private.DB.<Name>DB  (41 files, no globals)
  DB/DB.lua                 define private.registerInternalDBs()
  <plugin addon>/*.lua      assign into the ChroniclesPlugins global

Runtime — Chronicles.Data:Load()   (Core/Data.lua:69)
  seedEventTypeDefaults()                 persist a default status per configured event type
  private.registerInternalDBs()           15 bundled collections  (DB/DB.lua:3)
  Chronicles.Data:LoadPluginManifests()   plugins already present  (Core/Data.lua:116)
  RegisterEvent("ADDON_LOADED")           re-scan for later addons
  RegisterEvent("PLAYER_LOGIN")           stop scanning
  private.Core.Cache.init()
```

`DB/DB.xml` lists every collection file *before* `DB.lua`, which is what lets `DB.lua` bind
`local DB = private.DB or {}` and read the tables back without a load-order guess.

### Internal: `private.registerInternalDBs()`

One explicit, guarded call per collection and record type:

```lua
if DB.GreatwarsEventsDB then Data:RegisterEventDB("Greatwars", DB.GreatwarsEventsDB) end
if DB.GreatwarsFactionsDB then Data:RegisterFactionDB("Greatwars", DB.GreatwarsFactionsDB) end
if DB.GreatwarsCharactersDB then Data:RegisterCharacterDB("Greatwars", DB.GreatwarsCharactersDB) end
```

The file is verbose on purpose. It is machine-written by the Chronicles-tauri authoring tool, and
naming each collection explicitly means the collection name cannot be mis-derived from the table
identifier. **Change the shape of these files in that generator first**
(`src/app/addon/services/dbService.ts`), then mirror the result here — editing only the checked-in
files means the next export reverts you.

### External: the `ChroniclesPlugins` manifest

`ChroniclesPlugins` is the one global the data layer keeps, because it is the cross-addon contract:

```lua
ChroniclesPlugins = ChroniclesPlugins or {}
ChroniclesPlugins["MyPlugin"] = {
    events     = myEventsDB,      -- all three optional, at least one required
    characters = myCharactersDB,
    factions   = myFactionsDB,
}
```

`LoadPluginManifests` iterates it, tracks processed names in a module-local `processedPlugins` table
so repeat scans are idempotent, refuses a collection name already present in any of the three
registries, and returns whether anything new registered — the caller fires `TimelineInit` only when
it did.

The runtime equivalent is `Chronicles:RegisterPluginDB(name, manifest)` (`Chronicles.lua:263`). It
takes the same manifest shape, validates the name, requires at least one of the three keys, checks
the same collection-name conflict, and warns if no registrar succeeded. `PLUGINS.md` is the
authoring-facing version of all this.

## What the redesign fixed

| Old issue | Now |
| --- | --- |
| Internal and external loading mixed in `DB.lua` | Separate: `registerInternalDBs` vs `LoadPluginManifests` |
| Single-slot `ChroniclesPluginData.Register()` — one plugin only | Table keyed by plugin name; any number |
| No discovery; plugins had to load after Chronicles | `ChroniclesPlugins` is scanned at load and on `ADDON_LOADED`, so order does not matter |
| Silent registration failures | Every rejection prints a coloured reason naming the collection |
| `RegisterPluginDB` supported events only | Manifest covers events, characters and factions |

Registration failures are now reported in three places: a non-string or empty collection name, a
payload that is not a table (added 2026-07-29 — `pairs()` over a non-table would otherwise have
failed much later, inside the asynchronous cache warm), and a duplicate collection name.

## Still open

1. **Case asymmetry across the three layers is unchanged**, and is a navigation trap rather than a
   bug: `DataRegistry.registerEventDB` (camelCase, dot-called) ← `Chronicles.Data.RegisterEventDB`
   (PascalCase proxy, colon-called) ← `Chronicles:RegisterPluginDB`. A call site written as
   `Chronicles.Data:RegisterEventDB(...)` will not grep to its implementation; search for the
   camelCase name in `Core/Data/DataRegistry.lua`.
2. **Load-on-demand plugins after login.** `Core/Data.lua:89-92` unregisters `ADDON_LOADED` at
   `PLAYER_LOGIN`, so an addon loaded on demand later must call `Chronicles:RegisterPluginDB`
   itself. This is now documented as the contract in `PLUGINS.md` § 5 rather than treated as a gap,
   but it is still a real asymmetry between the two doors.
3. **No backwards-compatibility shim.** The old events-only signature
   (`RegisterPluginDB(name, eventsTable)`) is rejected by the "requires events, characters, or
   factions" guard. `CHANGELOG.txt` documents the break; nothing restores it.
4. **`PLUGINS.md` does not yet mention the payload type check.** A manifest whose every payload is
   rejected registers nothing and fires no `TimelineInit`; the authoring guide's rules section
   should say so.
