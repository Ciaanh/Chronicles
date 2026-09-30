# Code Improvement Guide — Deep Audit Plan

This document outlines the areas to investigate during a comprehensive code quality audit of the Chronicles addon. Each section describes what to check, current findings from the initial survey, and reference patterns from Blizzard's FrameXML source.

> **"Current state" blocks re-verified 2026-07-29.** The "What to check" and "Blizzard reference
> patterns" sections are the durable part of this document and are unchanged. The survey snapshots
> below were taken before the v2.1.0 book rewrite and the correctness pass that followed, so each one
> that has moved now records what changed. Sections 1, 2, 4, 6, 7 and 8 all shifted; sections 5, 9
> and 10 are unverified since the original survey.

---

## 1. Error Handling & Defensive Programming

### What to check
- All data access paths: nil checks before indexing tables
- WoW API return values: verify non-nil before use
- Plugin/external data: validate structure at module boundaries
- Registration functions: provide meaningful error feedback
- Use of `pcall`/`xpcall` around risky operations (plugin callbacks, data parsing)

### Current state (revised 2026-07-29)
- `pcall` now appears in eight files, and failures are forwarded to `geterrorhandler()` rather than
  discarded — in `Chronicles:ExecuteWhenReady`, the asynchronous cache warm queue, and the
  StateManager subscription replay in `MainFrameUI`. No `xpcall` or `securecallfunction` yet.
- `DataRegistry` no longer fails silently: each of `registerEventDB` / `registerCharacterDB` /
  `registerFactionDB` rejects a non-string collection name, a non-table payload, and a duplicate
  name with a coloured `print` naming the collection, and returns `false`.
- `EventManager` enforces each schema's `required` fields at trigger time, so a payload/handler
  mismatch is caught rather than silently producing nil.
- Still open: no `assert` for programming errors, and no input validation at UI entry points.

### Blizzard reference patterns
- Blizzard uses `assert()` for programming errors (wrong arguments)
- `securecallfunction()` for calling untrusted code safely
- `pcall()` wrapping around plugin-like callbacks
- Error messages include context: module name, operation, value

---

## 2. Global Namespace Hygiene

### What to check
- All `FooMixin = {}` declarations — are they polluting `_G`?
- Intentional globals (`Chronicles`, `ChroniclesPlugins`) — are they properly namespaced?
- Variables without `local` keyword in module scope
- String constants used as identifiers without `private.constants`

### Current state (revised 2026-07-29)
- **14 mixin globals**: `MainFrameUIMixin`, `TabUIMixin`, `TimelineMixin`, `TimelineLabelMixin`,
  `TimelinePeriodMixin`, `EventListMixin`, `EventListItemMixin`, `VerticalListMixin`,
  `VerticalListItemMixin`, `BookContainerMixin`, `HTMLContentMixin`, `ScrollFrameMixin`,
  `SettingsMixin`, `CategoryButtonMixin`. The book-page mixins from the old paged layer
  (`EmptyMixin`, `AuthorMixin`, `ChapterHeaderMixin`, `CoverPageMixin`, `EventTitleMixin`,
  `SimpleTitleMixin`, `HtmlPageMixin`, `SharedBookMixin`) and `EventListPagingMixin` are gone with
  the templates that used them.
- These are required by WoW's XML `mixin="FooMixin"` attribute (must be global).
- The two remaining non-mixin globals are `Chronicles` (the public facade) and `ChroniclesPlugins`
  (the cross-addon data contract). `ChroniclesPluginData` was removed in v2.1.0, and the 41
  `<Name>DB` globals the data layer used to declare now live under `private.DB`.
- `UI/Events/TimelineTemplate.xml` no longer leaks the 17 `Label1..9` / `Period1..8` frame globals;
  the period grid is built from frame pools.
- Still no global leak detection tooling. `./tools/harness.ps1 check` gates syntax, not globals; a
  `luacheck` layer is the next step (see the workspace `ANALYSIS.md` § A-10).

### Blizzard reference patterns
- Blizzard mixins are global by design (required for XML `mixin` attribute)
- Blizzard prefixes with feature names: `ClassTalentsMixin`, `ProfessionsMixin`
- Addons can prefix with addon name: `ChroniclesEventListItemMixin`
- Alternative: define mixin in `private` table and assign to `_G` at definition site

### Recommendation
- Prefix all mixin names with `Chronicles` to avoid collisions
- Document which globals are intentional vs which are leaks

---

## 3. State Management Consistency

### What to check
- UI components storing mutable state on `self` instead of StateManager
- Direct frame property assignments that should be state-managed
- State that needs to survive frame recycling (scroll position, selection, filters)
- Subscription cleanup on frame hide/destroy

### Current state
- **StateManager used correctly** for: selected event/character/faction, Settings category
  (`ui.settingsCategory` — note this is *not* the main tab strip, which lives in Blizzard's
  `TabSystemOwnerMixin` and is not persisted), window position, timeline step, collection toggles,
  event type filters
- **Bypassed in**: `VerticalListTemplate` (`self.currentSearchTerm`, `self.selectedItem`), `Settings.lua` (`self.prefix`, `self.categories`, `self.eventTypeId`)
- Subscription cleanup: `MainFrameUI` now enables its state subscriptions in `OnShow` and disables
  them in `OnHide`, and `TimelineMixin` unregisters its event callbacks from a declarative list. The
  per-item templates still have no cleanup path.

### Blizzard reference patterns
- Blizzard uses `FramePool` pattern — frames are recycled, so state must be external
- `DataProvider` pattern separates data from display
- `ScrollBox` + `DataProvider` model keeps state in data layer

### What to audit
- List all `self.` assignments in UI code
- Classify each as: transient (OK on self) vs persistent (should use StateManager)
- Ensure subscribers are unregistered when frames are hidden/recycled

---

## 4. Localization Compliance

### What to check
- All user-facing strings in Lua files
- All `SetText()`, `AddLine()`, tooltip strings
- Placeholder text, format strings, error messages
- XML `text=` attributes on FontStrings and Buttons

### Current state (revised 2026-07-29)
- The `VerticalListTemplate.lua` strings named in the original survey are now localized:
  `SearchPlaceholder` / `SearchCharactersPlaceholder` / `SearchFactionsPlaceholder` and
  `ListCountItems` / `ListCountCharacters` / `ListCountFactions`. The book's error strings and empty
  prompts moved to `BOOK_ERROR_*` / `BookEmptyPrompt*` in the same pass.
- **Not localized, deliberately**: the registration failure messages in `Core/Data/DataRegistry.lua`
  and `Chronicles.lua` — they are developer diagnostics for plugin authors, not player-facing text.
- **Properly localized**: Timeline button labels, tab names, settings labels.
- Only `Locales/enUS.lua` exists. The AceLocale scaffolding is complete, so translations are
  unblocked; nobody has contributed one.

### Audit process
1. `grep` for `SetText(`, `AddLine(`, `GameTooltip:`, format strings
2. Cross-reference each with `Locales/enUS.lua` — is there a matching key?
3. Flag any raw English string not resolved through the file's AceLocale handle
   (`local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)`; there is no
   `Chronicles.L`)

---

## 5. XML Template Patterns

### What to check
- `setAllPoints="true"` combined with explicit `<Size>` (conflicting directives)
- Anchoring consistency across similar templates
- Font inheritance and sizing
- Template reuse vs duplication
- `$parent` references in key values

### Current state (revised 2026-07-29)
- The original finding named `EventListItemTemplate`, `VerticalListItemTemplate`, `EventTitleTemplate`
  and `CoverPageTemplate`. The last two no longer exist — the paged book layer they belonged to was
  replaced by `UI/Book/BookContainerTemplate` rendering HTML. The first two survive and have **not**
  been re-checked for the `setAllPoints` + explicit `<Size>` conflict.
- The companion document `docs/analysis/ui-text-overflow.md` was deleted rather than updated: it was
  a detailed analysis of the deleted rendering path (`SharedBookTemplate` + `BookUtils` +
  `BookPages.xml`) and would have been read as a live bug report. Re-derive against the current
  templates if this phase is picked up.

### Blizzard reference patterns
- Blizzard uses two-point anchoring for width-constrained text (TOPLEFT + TOPRIGHT)
- `setAllPoints` is used only when the child should match the parent exactly
- `SetWordWrap(true)` and `SetMaxLines(n)` for text overflow control
- `SetNonSpaceWrap(false)` to allow breaking on spaces only

### Audit process
1. List all `setAllPoints="true"` usages in XML
2. Check if each has conflicting Size or anchor declarations
3. Verify text elements have appropriate overflow handling

---

## 6. Event System Usage

### What to check
- Consistent use of `private.constants.events.*` for event names (no raw strings)
- Event payload schemas: are they documented and validated?
- Callback registration/unregistration lifecycle
- Event ordering dependencies

### Current state (revised 2026-07-29)
- **Consistent**: All addon events use `private.constants.events.*` constants
- **Payloads are now validated.** `EventManager`'s `eventSchemas` `required` arrays are enforced at
  trigger time instead of being documentation, and the dynamic `DisplayTimelineLabel<n>` /
  `DisplayTimelinePeriod<n>` names resolve to their base schema. This caught a real bug: the timeline
  paging handlers took `(isVisible)` while the trigger sent `{visible = true}`, so both arrows stayed
  permanently disabled.
- ~~Two declared events are dead: `AddonShutdown` and `TabUITabSet` have a constant and a schema but
  no trigger and no listener.~~ **Both deleted** — constant, schema, and `TabUITabSet`'s single
  producer. `constants.events` (`Constants.lua:53-65`) now declares ten events, all of which are
  triggered and consumed.
- `events.UIRefresh` was also renamed from the string `"Timeline.CLEAN"` to `"UI.REFRESH"`. It was
  never timeline-scoped: Settings produces it, and the event list, the book and the vertical list
  consume it.
- Callback registration happens in `OnLoad`/`OnShow`; `TimelineMixin` unregisters from a declarative
  list, other mixins still have no cleanup in `OnHide`.

### Blizzard reference patterns
- Blizzard uses `EventRegistry` with typed callbacks
- Events have documented payload structures
- `Frame:UnregisterEvent()` in hide/destroy paths

---

## 7. Cache Strategy

### What to check
- All computations that iterate over full datasets
- Cache key naming conventions
- Invalidation triggers: are all mutation paths covered?
- Cache warming strategy (pre-compute on load vs lazy)
- Memory pressure from cached data

### Current state (revised 2026-07-29)
- **Cached**: periods filling, min/max event year, search events, collections names, all characters,
  filtered characters, book content. Capped at 100 entries.
- **Invalidation is centralized.** `Cache.invalidateForDataChange(kind)` owns the full key set per
  kind of change (`"events"`, `"characters"`, `"factions"`, `"all"`) and `error()`s on an unknown
  kind. Every registrar and both Settings toggles route through it. The previous state — each call
  site hand-picking keys, and each picking a different incomplete set — was the bug: toggling a
  collection off left the character rail listing its entries.
- **Warm-up exists but is asynchronous and lazy-first**: `processWarmQueue` pre-computes in the
  background, and a failure inside it is now reported to `geterrorhandler()` instead of being filed
  in `Cache._lastWarmError` and forgotten.
- `getAllFactions()` no longer exists, so the "not cached" finding is moot.

### Audit process
1. Profile which functions are called most frequently
2. Check if any iterate full datasets without caching
3. Verify every `registerXDB()` path calls `invalidateForDataChange` with the right kind, and that
   `DATA_CHANGE_KEYS` still lists every cache derived from that kind

---

## 8. Performance Patterns

### What to check
- `OnUpdate` handlers: are any used for polling that could be event-driven?
- Large table iterations in hot paths
- Frame creation/destruction vs pooling
- Texture/font object reuse
- String concatenation in loops (use `table.concat` instead)

### Current state (revised 2026-07-29)
- **Timeline rendering**: labels and periods now come from frame pools sized from the configured page
  size (`TimelineMixin:RefreshTimelinePools`), replacing nine labels and eight periods hand-chained
  in XML.
- **Event list and rails**: both moved to `CreateScrollBoxListLinearView` +
  `ScrollUtil.InitScrollBoxListWithScrollBar`, so only visible items have frames. The Blizzard
  `ScrollBox`/`DataProvider` recommendation below is now adopted rather than aspirational.
- **Search**: still a full scan over all events, with results memoized per `yearStart_yearEnd` key.
  No index.

### Blizzard reference patterns
- `FramePool` / `ObjectPoolMixin` for frame recycling
- `ScrollBox` for virtualized scrolling (only visible items have frames)
- `CreateAndInitFromMixin()` for one-time mixin setup
- Avoid `pairs()` in hot paths; prefer indexed arrays with `ipairs()`

---

## 9. Data Processing Pipeline

### What to check
- `CleanEvent()` / `CleanCharacter()` / `CleanFaction()` — input validation
- Localization key resolution: what happens with missing keys?
- Chapter/page content processing: edge cases (empty chapters, missing pages)
- Cross-reference integrity: do referenced IDs exist?

### Audit process
1. Trace a sample event from raw DB through cleaning to UI display
2. Intentionally break inputs (nil fields, wrong types) and observe behavior
3. Check cross-references resolve correctly

---

## 10. WoW API Compatibility (12.0.0)

### What to check
- No usage of removed APIs (GetSpellInfo, combat log events, etc.)
- No reliance on addon messaging in instances
- No branching on potentially secret values
- TOC version number matches target patch

### Current state
- Chronicles is a lore/data addon — unlikely to use combat APIs
- Should still verify no deprecated API calls exist. One known offender: `UI/Settings/Settings.xml:7`
  still inherits the deprecated `InterfaceOptionsCheckButtonTemplate`, and
  `Settings.RegisterAddOnCategory()` is never called.
- TOC `Interface` is `120001`, which matches the target patch.

### Audit process
1. Cross-reference all WoW API calls against the 12.0.0 removed list
2. Verify TOC `Interface` value

---

## Audit Execution Plan

| Phase | Scope | Priority |
|-------|-------|----------|
| 1 | XML template audit (setAllPoints conflicts) | High |
| 2 | Localization string audit | High |
| 3 | Error handling improvements | High |
| 4 | Global namespace cleanup (mixin prefixing) | Medium |
| 5 | State management audit | Medium |
| 6 | Cache coverage expansion | Medium |
| 7 | Performance profiling | Low |
| 8 | Data pipeline edge cases | Low |
| 9 | WoW 12.0.0 API compatibility | Low (addon is non-combat) |

Each phase should produce:
- List of specific issues found
- Proposed fix for each issue
- Priority classification (must-fix, should-fix, nice-to-have)
