# Code Improvement Guide — Deep Audit Plan

This document outlines the areas to investigate during a comprehensive code quality audit of the Chronicles addon. Each section describes what to check, current findings from the initial survey, and reference patterns from Blizzard's FrameXML source.

---

## 1. Error Handling & Defensive Programming

### What to check
- All data access paths: nil checks before indexing tables
- WoW API return values: verify non-nil before use
- Plugin/external data: validate structure at module boundaries
- Registration functions: provide meaningful error feedback
- Use of `pcall`/`xpcall` around risky operations (plugin callbacks, data parsing)

### Current state
- **Minimal**: Only one `print()` error in `DB/DB.lua`
- `DataRegistry` functions return `false` silently on failure
- No `assert`, `pcall`, or `xpcall` usage found
- No input validation at UI entry points

### Blizzard reference patterns
- Blizzard uses `assert()` for programming errors (wrong arguments)
- `securecallfunction()` for calling untrusted code safely
- `pcall()` wrapping around plugin-like callbacks
- Error messages include context: module name, operation, value

---

## 2. Global Namespace Hygiene

### What to check
- All `FooMixin = {}` declarations — are they polluting `_G`?
- Intentional globals (`Chronicles`, `ChroniclesPluginData`) — are they properly namespaced?
- Variables without `local` keyword in module scope
- String constants used as identifiers without `private.constants`

### Current state
- **20+ mixin globals**: `EmptyMixin`, `AuthorMixin`, `ChapterHeaderMixin`, `CoverPageMixin`, `EventTitleMixin`, `SimpleTitleMixin`, `HtmlPageMixin`, `SharedBookMixin`, `EventListItemMixin`, `VerticalListItemMixin`, `TabUIMixin`, `TimelineMixin`, `EventListPagingMixin`, etc.
- These are required by WoW's XML `mixin="FooMixin"` attribute (must be global)
- No global leak detection tooling

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
- **StateManager used correctly** for: selected event/character/faction, current tab, timeline step, collection toggles, event type filters
- **Bypassed in**: `VerticalListTemplate` (`self.currentSearchTerm`, `self.selectedItem`), `Settings.lua` (`self.prefix`, `self.categories`, `self.eventTypeId`)
- No subscription cleanup patterns observed

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

### Current state
- **Hardcoded strings found in**:
  - `VerticalListTemplate.lua`: tooltip lines ("Available Content:", "Created by:", "Allegiance:", "Race:"), search placeholder ("Search..."), count format ("%d items")
  - `DB/DB.lua`: error message
- **Properly localized**: Timeline button labels, tab names, settings labels

### Audit process
1. `grep` for `SetText(`, `AddLine(`, `GameTooltip:`, format strings
2. Cross-reference each with `Locales/enUS.lua` — is there a matching key?
3. Flag any raw English string not using `Chronicles.L["KEY"]`

---

## 5. XML Template Patterns

### What to check
- `setAllPoints="true"` combined with explicit `<Size>` (conflicting directives)
- Anchoring consistency across similar templates
- Font inheritance and sizing
- Template reuse vs duplication
- `$parent` references in key values

### Current state
- **Conflicting layout pattern** found in: `EventListItemTemplate`, `VerticalListItemTemplate`, `EventTitleTemplate`, `CoverPageTemplate`
- See `docs/analysis/ui-text-overflow.md` for full details

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

### Current state
- **Consistent**: All addon events use `private.constants.events.*` constants
- **No payload validation** at trigger points
- Callback registration happens in `OnLoad`/`OnShow` — no corresponding cleanup in `OnHide`

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

### Current state
- **Cached**: periods filling, search events, collections names, all characters
- **Not cached**: `getAllFactions()` (frequently called)
- **Invalidation**: strategically placed in `Core/Data.lua` after data mutations
- **No pre-warming**: all caches are lazy (computed on first access)

### Audit process
1. Profile which functions are called most frequently
2. Check if any iterate full datasets without caching
3. Verify every `registerXDB()` path invalidates all relevant caches

---

## 8. Performance Patterns

### What to check
- `OnUpdate` handlers: are any used for polling that could be event-driven?
- Large table iterations in hot paths
- Frame creation/destruction vs pooling
- Texture/font object reuse
- String concatenation in loops (use `table.concat` instead)

### Current state
- **Timeline rendering**: Uses `OnUpdate` for some animation/scrolling (acceptable)
- **Event list**: Creates frames for each visible item (should verify pooling)
- **Search**: Full-text search over all events — check if indexed

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
- Should still verify no deprecated API calls exist
- TOC `Interface` version should target current patch

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
