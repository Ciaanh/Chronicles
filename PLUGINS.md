# Writing a Chronicles content plugin

Chronicles can load lore data (events, characters, factions) from external
addons — no changes to Chronicles itself required. This document describes the
plugin contract so you can ship your own content pack.

A plugin is just a normal WoW addon that hands Chronicles one or more
collections of data. You can register that data two ways:

1. **Declarative manifest** (recommended) — populate a global `ChroniclesPlugins`
   table during your addon's load. Chronicles scans it automatically. Order-
   independent: it works whether your addon loads before or after Chronicles.
2. **Runtime API** — call `Chronicles:RegisterPluginDB(name, manifest)` yourself,
   e.g. from a load-on-demand addon or after generating data at runtime.

Both take the same manifest shape and enforce the same rules.

---

## 1. The manifest

```lua
{
    events     = <eventsDB>,      -- optional
    characters = <charactersDB>,  -- optional
    factions   = <factionsDB>,    -- optional
}
```

At least one of `events`, `characters`, or `factions` must be present. Each is
an **id-keyed table** of entries (`[id] = { ... }`), described below.

Everything registered under one manifest belongs to a single **collection**,
named by the key you register it under. The collection name must be unique
across all loaded data (Chronicles' own collections are `Expansions`,
`Worldofwarcraft`, `Legion`, … — see `DB/DB.lua`). A duplicate name is skipped
with a warning, so pick something distinctive (e.g. your addon name).

The collection appears in **Settings → Collections**, where players can toggle
it on/off. Its label is resolved through AceLocale as `Locale[collectionName]`,
falling back to the raw name if no locale entry exists. To show a friendly
name, register an AceLocale entry for the locale `"Chronicles"` keyed by your
collection name (see the example).

---

## 2. Data shapes

IDs are per-collection: they only need to be unique within your own tables.

### Event

```lua
[131] = {
    id        = 131,          -- number, matches the table key
    label     = "…",          -- string, event title
    yearStart = 25,           -- number, first year (negative = before the Dark Portal)
    yearEnd   = 25,           -- number, last year (== yearStart for a point event)
    eventType = 2,            -- number, see Event types below
    timeline  = 1,            -- number, see Timelines below
    order     = 0,            -- number, display order within a period (optional)
    chapters  = { … },        -- see Chapters below
    characters = {},          -- optional, see Cross-references below
    factions   = {},          -- optional, see Cross-references below
    author    = "…",          -- string, optional
}
```

### Character

```lua
[32] = {
    id       = 32,
    name     = "…",
    timeline = 1,
    chapters = { … },
    factions = { 23, 24 },    -- optional, flat array of faction ids (see note below)
    author   = "…",           -- optional
    description = "…",        -- optional
    image    = "…",           -- optional, texture path for the portrait
}
```

### Faction

```lua
[22] = {
    id       = 22,
    name     = "…",
    timeline = 1,
    chapters = { … },         -- optional
    author   = "…",           -- optional
    description = "…",        -- optional
    image    = "…",           -- optional, texture path for the crest
}
```

### Chapters

`chapters` is an array of chapter objects. Each has a `header` and an array of
`pages`. A page is a plain string, or an HTML string wrapped in `<html>…</html>`
(Chronicles auto-detects and renders HTML pages in a scroll frame).

```lua
chapters = {
    {
        header = "Chapter one",
        pages  = { "First page of text.", "Second page." },
    },
}
```

### Event types

`eventType` maps to `constants.eventType` (`Constants.lua`):

| value | meaning   |
|-------|-----------|
| 1     | event     |
| 2     | era       |
| 3     | war       |
| 4     | battle    |
| 5     | death     |
| 6     | birth     |
| 7     | other     |

### Timelines

`timeline` maps to `constants.timelines`: `1` = main, `2` = draenor,
`3` = end of time, `4` = war of the ancients. Use `1` unless your content
belongs to an alternate timeline.

### Cross-references (note the format asymmetry)

- On an **event**, `characters` and `factions` are **collection-keyed maps**:
  `{ ["worldofwarcraft"] = {32, 33}, ["greatwars"] = {15} }` — the key is the
  source collection name, the value is an array of ids in that collection.
- On a **character**, `factions` is a **flat array of ids**: `{ 23, 24 }`.

This asymmetry is a known quirk of the current data model; match it so your
data behaves like the bundled collections.

---

## 3. Localization (optional but recommended)

The bundled collections store all display text in AceLocale
(`Locale["<key>"]`) rather than inline. You don't have to — inline strings work
fine — but if you want to support translations, register a locale for
`"Chronicles"` and reference keys in your data:

```lua
local L = LibStub("AceLocale-3.0"):NewLocale("Chronicles", "enUS", true, true)
if L then
    L["MyPlugin"] = "My Lore Pack"          -- the collection's display name
    L["evt_1_title"] = "The Founding"
end
```

---

## 4. Minimal working plugin

A complete second addon that adds one event. File layout:

```
MyChroniclesPack/
    MyChroniclesPack.toc
    Data.lua
```

**`MyChroniclesPack.toc`**

```
## Interface: 120001
## Title: My Chronicles Pack
## Notes: Sample content pack for Chronicles
## OptionalDeps: Chronicles

Data.lua
```

> `OptionalDeps: Chronicles` only influences load order; because the manifest
> path is order-independent, it is not strictly required.

**`Data.lua`**

```lua
local MyEvents = {
    [1] = {
        id        = 1,
        label     = "The Founding of Example City",
        yearStart = -20,
        yearEnd   = -20,
        eventType = 1,   -- event
        timeline  = 1,   -- main
        order     = 0,
        chapters  = {
            {
                header = "Origins",
                pages  = { "Long ago, the city was founded on the coast." },
            },
        },
        characters = {},
        factions   = {},
        author     = "You",
    },
}

-- Declarative registration: order-independent, auto-scanned by Chronicles.
ChroniclesPlugins = ChroniclesPlugins or {}
ChroniclesPlugins["MyChroniclesPack"] = {
    events = MyEvents,
}
```

That's it. When Chronicles loads (or on the next `ADDON_LOADED` if your addon
loads later), the collection "MyChroniclesPack" appears in Settings, and the
event shows on the timeline at year -20.

### Runtime alternative

If you generate data at runtime or load on demand, register directly instead of
using the global table:

```lua
if Chronicles then
    Chronicles:RegisterPluginDB("MyChroniclesPack", { events = MyEvents })
end
```

`RegisterPluginDB` validates its input, skips duplicate collection names, and
refreshes the timeline on success. It is safe to call at any time after
Chronicles has initialized.

---

## 5. Rules & gotchas

- **Unique collection name.** Duplicates (including clashing with a bundled
  collection) are skipped with a chat warning.
- **At least one data type.** A manifest with none of events/characters/factions
  is rejected.
- **Timeline refresh is automatic.** Both registration paths re-fire the
  timeline init so your data appears without extra work.
- **Load-on-demand after login.** Chronicles stops auto-scanning the
  `ChroniclesPlugins` table after `PLAYER_LOGIN`. If your addon is loaded on
  demand *after* the player logs in, it must call
  `Chronicles:RegisterPluginDB(...)` explicitly — the declarative table won't be
  re-scanned for it.
- **Collection toggle persists.** Once registered, a collection's on/off state
  is saved per account in `ChroniclesDB`; re-registering does not reset it.
