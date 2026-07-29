# Chronicles WoW Addon – Lean Copilot Guide

Verified against the working branch on 2026-07-29. No tool checks this file, so treat anything it
claims about a specific file or symbol as needing a grep before you rely on it.

Scope: World of Warcraft addon written in Lua/XML. Use StateManager + EventManager, template-based UI, and localization-first content. Keep guidance rule-first and enforceable.

## 0) Golden Rules
1) Never create globals; use the `private`/`Chronicles` namespaces only.
2) Persist and read UI/data state only through `private.Core.StateManager`.
3) Communicate across modules only via `private.Core.triggerEvent` with validated payloads.
4) Localize all user-visible text via AceLocale (`Locale["KEY"]`, see 7). No raw strings.
5) Respect mixin + XML template patterns. Manage frame lifecycle (`OnLoad/OnShow/OnHide`) cleanly.
6) Check for nil before calling WoW API. Fail early with descriptive errors.
7) Prefer maintainability over premature optimization. Optimize only with evidence.
8) Do not invent new folder structures, naming schemes, or cross-layer calls.

## 1) Repository Layout (authoritative)
- Core/Infrastructure: StateManager.lua, EventManager.lua, Cache.lua
- Core/Domain: pure business models/logic (no UI, no WoW API). Types.lua here is LuaLS `@meta`
  annotations only and is deliberately outside the load graph.
- Core/Data: TimelineBusiness.lua, SearchEngine.lua, DataRegistry.lua, plus Core/Data.lua (the
  PascalCase `Chronicles.Data` facade over them)
- Core/Utils: HelperUtils, Spacing, StringUtils, TableUtils, UIUtils, ValidationUtils
- UI/Book (ContentUtils.lua lives here), UI/* per feature
- DB: DB.lua plus one NN_<Expansion>/ directory per expansion, with strings in DB/Locales/NN_*/
- Locales: enUS.lua (and others)
- .github: this file, and workflows/ci.yml

There is no Core/Business layer and no UI/Templates directory; both were removed. Do not add
ContentUtils under Core/Utils — it lives under UI/Book.

Every file must be registered in the `_Includes.xml` of its own directory: there is no globbing, so
an unregistered file is silently never loaded. `./tools/harness.ps1 check` (workspace root) walks the
real chain and reports both directions.

## 2) Naming Conventions
- Namespaces/components: PascalCase (Chronicles, StateManager)
- Functions/vars: camelCase (getCurrentStepValue, eventData)
- Constants: UPPER_SNAKE_CASE (CURRENT_YEAR)
- State keys: dot.notation (see 3)
- Events: PascalCase keys in `private.constants.events`, dotted string values (see 4)
- Localization keys: existing keys are a mix of PascalCase and UPPER_SNAKE_CASE; match the
  neighbouring keys in `Locales/enUS.lua` rather than inventing a third style

## 3) State Management (authoritative contract)
Use only `private.Core.StateManager`.

Allowed key spaces (examples):
- ui.selectedEvent
- ui.settingsCategory
- timeline.currentStep
- eventTypes.{id}
- collections.{name}
- data.userContent.events — **in-session only**: `persistState` deliberately skips `data.userContent.*`,
  so anything stored there is lost on logout

Keys map onto AceDB by their first segment: `ui.*` → `db.global.uiState`, `timeline.*` →
`timelineState`, `eventTypes.*` / `collections.*` → `settingsState`, `data.*` → `dataState`.

Rules:
- Build keys via the helpers, never as string literals — `buildStateKey` validates and `error()`s on
  an unknown key or entity type, so a typo'd literal silently bypasses validation:
  - `buildSelectionKey("event")` → `ui.selectedEvent`
  - `buildTimelineKey("currentStep")` → `timeline.currentStep`
  - `buildSettingsKey("eventType", id)` / `buildCollectionKey(name)`
  - `buildUIStateKey("settingsCategory")` → `ui.settingsCategory`
- Store plain data only (no frames/functions).
- Provide a context string on set for auditability.
- Subscribe with a module name and clean up within lifecycle.
- Use `rehydrate(key)` to re-emit a value restored from SavedVariables; it notifies without
  re-persisting, and is a no-op for a key with nothing saved.
- `setState` with an unchanged value does nothing: no persist, no subscriber fan-out. That is the
  default, so write idempotently without guarding. When you genuinely need subscribers woken by a
  re-set of the same value, pass `{forceNotify = true}` — but prefer `rehydrate`, which is the
  purpose-built primitive for it.
- Retiring a key needs an explicit purge. `StateManager.init()` copies every stored `uiState` /
  `timelineState` key back into memory on login, so deleting the writer leaves the old value being
  reloaded forever; add the key to the retired-state list in `Chronicles.lua` as well.

Examples:
```lua
local key = private.Core.StateManager.buildSelectionKey("event")   -- "ui.selectedEvent"
private.Core.StateManager.setState(key, eventId, "Event selected from timeline")
local selected = private.Core.StateManager.getState(key)

private.Core.StateManager.subscribe(key, function(newV, oldV)
    self:UpdateEventDisplay(newV)
end, "EventDisplayMixin")
```

## 4) Event System (schema-first)
Declare events in `Constants.lua` under `constants.events`, never as an inline string. Every event
needs a matching schema in `Core/Infrastructure/EventManager.lua` — `required` fields are enforced,
so a handler and its trigger cannot silently disagree about the payload shape.

Rules:
- Payloads must be tables with documented fields. A handler receives `(owner, payload)` — one table,
  not unpacked arguments. Declaring `function Mixin:OnThing(value)` when the payload is
  `{visible = true}` is the exact shape of bug the schema exists to catch.
- Include a context/source string on trigger.
- No hidden coupling; listeners must not mutate payload in-place.
- Prefer a StateManager subscription over a new event when what you mean is "a value changed".

Examples:
```lua
-- Declaration (Constants.lua)
constants.events = {
    SettingsCollectionChecked = "Settings.COLLECTION_CHECKED",
}

-- Trigger
private.Core.triggerEvent(
    private.constants.events.SettingsCollectionChecked,
    { collectionName = name, isActive = true },
    "Settings:OnCollectionClick"
)

-- Register
private.Core.registerCallback(
    private.constants.events.SettingsCollectionChecked,
    self.OnSettingsCollectionChecked,
    self
)
```

Required payload schema examples (from `eventSchemas`):
- `Settings.COLLECTION_CHECKED`: { collectionName: string, isActive: boolean }
- `Settings.EVENT_TYPE_CHECKED`: { eventTypeId: number, isActive: boolean }
- `Timeline.PREVIOUS_VISIBLE` / `Timeline.NEXT_VISIBLE`: { visible: boolean }
- `Timeline.INIT`, `UI.REFRESH` (`events.UIRefresh`): payload optional

## 5) UI Patterns (XML + Mixin)
Rules:
- Create frames via XML templates; implement behavior in mixins.
- Implement `OnLoad`, `OnShow`, `OnHide` and persist UI state in these.
- Lazy-load heavy content on first show.
- Wire UI to state via subscriptions; unsubscribe or guard in `OnHide`.

Example (condensed, as `MainFrameUIMixin:OnShow` actually does it):
```lua
function MainFrameUIMixin:OnShow()
    self:RestoreFramePosition()
    self.TabUI:UpdateTabs()
    self:SetupStateSubscriptions()
    self:EnableStateSubscriptions()
    private.Core.StateManager.setState(
        private.Core.StateManager.buildUIStateKey("isMainFrameOpen"),
        true,
        "Main frame opened"
    )
end
```

Note that `ui.settingsCategory` is the **Settings** panel's own category selection, not the main tab
strip. The main tab strip is not persisted: it lives in Blizzard's `TabSystemOwnerMixin`, and
`TabUIMixin:UpdateTabs` simply falls back to the Events tab when no tab is set.

## 6) ContentUtils (single source of truth)
Location: UI/Book/ContentUtils.lua
Namespace: `private.Core.Utils.ContentUtils`

Contract (do not rename):
- TransformEntityToBook(entity) — the only exported function

It returns an array of section objects plus a `navigationData` field carrying the chapter-id →
page-index map. Both halves matter: drop `navigationData` and the table of contents stops linking.
HTML generation itself lives in `UI/Book/HTMLBuilder.lua`.

Usage:
```lua
local CU = private.Core.Utils.ContentUtils
local bookContent = CU.TransformEntityToBook(entity)
```

## 7) Localization (no raw strings)
Rules:
- All user-facing text via AceLocale. Each file takes its own handle at the top:
  `local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)`, then `Locale["KEY"]`.
  There is no `Chronicles.L`; the public alias is `Chronicles.locale`.
- Add new keys to `Locales/enUS.lua` with translator comments.
- Prefer descriptive keys: `BookEmptyPromptEvent`, `BOOK_ERROR_NO_HTML`.

Example:
```lua
frame:SetText(Locale["Characters_List"])
```

## 8) Error Handling
Rules:
- Guard WoW API calls with nil checks.
- Use descriptive error messages; include context keys/ids.
- Prefer returning early over nested conditionals.
- No silent failures in core paths.

Example:
```lua
if not eventData or not eventData.chapters then
    error("DisplayEventContent: missing eventData.chapters")
end
```

## 9) Performance
- Avoid allocations in hot paths and OnUpdate.
- Debounce expensive UI work (>= 0.1s) via C_Timer.After.
- Batch related state updates.
- Add caching only with measured impact.

Helpers:
```lua
local function debounce(fn, delay)
    local timer
    return function(...)
        local args = {...}
        if timer then timer:Cancel() end
        timer = C_Timer.NewTimer(delay or 0.1, function() fn(unpack(args)) end)
    end
end
```

## 10) Contributor Checklist (enforced)
Before opening a PR:
- [ ] `./tools/harness.ps1 check -Addon Chronicles` passes (load graph, XML, Lua syntax).
- [ ] `./tools/harness.ps1 test -Addon Chronicles` passes (`Tests/run_tests.lua`).
- [ ] `./tools/harness.ps1 version -Addon Chronicles` agrees across TOC, CHANGELOG and Readme.
- [ ] No new globals. XML mixin tables are the only exception, since the loader resolves them by
      global name.
- [ ] New files registered in the `_Includes.xml` of their directory.
- [ ] All user-facing text localized.
- [ ] New events/state keys follow schemas above.
- [ ] UI changes respect XML+Mixin and lifecycle rules.
- [ ] Added/updated docstrings and inline comments where non-obvious.

`.github/workflows/ci.yml` runs the same two Lua gates on Lua 5.1 for pushes to `main` and for every
pull request: `luac -p` over every addon file outside `Libs/`, then `lua Tests/run_tests.lua`.

## 11) Versioning & Maintenance
- Update interface version in `Chronicles.toc` for new WoW patches.
- The version string lives in three places — `Chronicles.toc`, `CHANGELOG.txt` and `Readme.md`
  (shipped in the release zip). Bump all three together.
- Keep ContentUtils under UI/Book (not Core/Utils).
- Content under `DB/` is generated by the Chronicles-tauri authoring tool. Changing the *shape* of
  those files means changing that generator first, then mirroring here — otherwise the next export
  reverts you.

## 12) Pair Programming Workflow
1) Explore related files; summarize structure and patterns.
2) Propose a small action plan with explicit acceptance criteria.
3) Ask clarifying questions only when blocking.
4) Implement incrementally; wire state/events; add minimal tests/checks.

Appendix A: Canonical State Keys
- `ui.selectedEvent`: { eventId: number, collectionName: string } — build with
  `buildSelectionKey("event")`; `ui.selectedCharacter` / `ui.selectedFaction` take the same shape
  with `characterId` / `factionId`
- `ui.settingsCategory`: string — the Settings panel's category name, not the main tab strip
- `ui.isMainFrameOpen`: boolean
- `ui.windowPosition`: table
- `timeline.currentStep`: number, one of `constants.config.stepValues`
- `eventTypes.{id}` / `collections.{name}`: boolean, via `buildSettingsKey`

Appendix B: Canonical Events
- `Timeline.INIT`: optional payload; `{source = "plugin", pluginName = ...}` when a plugin registers
- `UI.REFRESH` (`events.UIRefresh`): optional payload. Produced by Settings when a collection or an
  event type is toggled; consumed by the event list, the book and the vertical list. It is **not**
  timeline-scoped — it was called `Timeline.CLEAN` until the correctness pass renamed the string to
  match what it does.
- `Settings.COLLECTION_CHECKED`: { collectionName: string, isActive: boolean }
- `Settings.EVENT_TYPE_CHECKED`: { eventTypeId: number, isActive: boolean }
- `Timeline.DisplayEventsForYear`: { year: number, events: table }
- `Addon.STARTUP` (`events.AddonStartup`): optional payload
- `Timeline.PREVIOUS_VISIBLE` / `Timeline.NEXT_VISIBLE`, `Timeline.DisplayLabel` /
  `Timeline.DisplayPeriod` — the last two are suffixed with an index at trigger time
  (`Timeline.DisplayLabel3`) and resolve to the base schema

That is the whole of `constants.events` (`Constants.lua:53-65`). The previously documented
`AddonShutdown` and `TabUITabSet` were **deleted** — constant, schema and, in `TabUITabSet`'s case,
its single producer. Neither had a listener, so nothing to rewire; do not reintroduce them.
