# Chronicles Addon -- Deep Analysis Report

**Date**: 2026-04-17  
**Scope**: Code Quality & Architecture, UI/UX Design, Blizzard UI Standards Compliance, Feature Opportunities

---

## Status banner (added 2026-07-29 -- read before acting on anything below)

This report was written against the codebase as it stood in April 2026. Two large changes have landed
since: the **v2.1.0 HTML book rewrite plus movable panel**, and a **correctness/dead-code pass** after
it. Roughly a third of the specific findings below name files or symbols that no longer exist.

The report has been **annotated, not rewritten** -- the analysis is still good, and its reasoning is
worth keeping next to each item. Every superseded finding is marked inline with what happened.
`CHANGELOG.txt` is the authority on what changed; `WoW Addon Design Analysis/proposal/03-defect-list.md`
is the authority on the UI defects.

**Deleted since this report was written.** Any finding whose subject is on this list is moot:

| Gone | Where it was |
| --- | --- |
| `SharedBookTemplate`, `BookPages.*`, `BookUtils` | the entire paged book layer -- replaced by `UI/Book/BookContainerTemplate` rendering HTML |
| `DependencyContainer` | `Core/Infrastructure/` |
| `Core/Business/` (`FilterEngine`, `DateCalculator`) | the whole layer |
| `Core/Domain/Settings.lua` | Domain |
| `Core/Utils/MathUtils.lua` | Utils |
| the RP integration (`RPEventsDB`, `Chronicles.Data.RP`, `AddRPEvent`, `LoadRolePlayProfile`) | `Core/Data.lua` |
| `UI/Templates/` (whole directory, incl. `VerticalListTemplate_Examples.lua`) | UI |
| `Core/Data/Types.lua` | superseded by `Core/Domain/Types.lua` |
| `ChroniclesPluginData` | the plugin registration hook |
| the full-screen scrim, and the `TabContainer` layer by that name | `UI/MainFrameUI.xml` -- the 1480x825 content area itself survives as the `TabUI` child of a real 1525x875 panel |
| `EventListPagingControls.xml` / `EventListPagingControlsMixin` | the duplicated event-list paging control (`a7d09df`) -- the list scrolls now |
| 11 unused `Chronicles.Data` facade members, `PluginEvents`, mod250/mod50 period buckets | Data layer |

**Also fixed since**: event schema `required` fields are now enforced (C5, C6); the 41 `*DB` globals
now live under `private.DB` (C1); the main frame is a movable 1525x875 panel (UI § top
recommendation); and the timeline paging arrows, book table of contents, and period event counts all
worked incorrectly and now do not.

---

## Executive Summary

| Dimension | Grade | One-Line Verdict |
|-----------|-------|-----------------|
| Architecture & Code | **B** | Solid layered design, needs deduplication and global cleanup |
| UI/UX | **C+** | Good book aesthetic, but full-screen overlay and missing selection feedback hurt badly |
| Blizzard Compliance | **B** | Strong modern patterns, but Settings API integration is completely absent |
| Feature Potential | **A** | Enormous opportunity space; data relationships and APIs are ready to exploit |

The addon has a genuinely impressive engineering foundation -- the architecture, state management, event validation, and plugin API are well above average for a WoW addon. The biggest wins would be: (1) replacing the full-screen overlay with a standard movable frame, (2) integrating with Blizzard's Settings API, and (3) adding cross-entity navigation to transform it from a linear reader into an explorable lore network.

---

## 1. Code Quality & Architecture -- Grade: **B**

### Architecture Overview

```
Chronicles.toc / Chronicles.xml (Entry point)
    |
    v
Constants.lua --> Libs/Ace3 --> Locales --> DB/Locales
    |
    v
Chronicles.lua (AceAddon bootstrap)
    |
    v
Core/_Includes.xml
  ├── Infrastructure/  (Cache, EventManager, StateManager)
  ├── Utils/           (Helper, Spacing, String, Table, Validation, UI)
  ├── Data/            (DataRegistry, SearchEngine, TimelineBusiness) + Data.lua facade
  └── Domain/          (Types*, Characters, Events, Factions, Timeline)
    |
    v
DB/ (15 expansions, 41 data files -- not every expansion has all three entity types)
    |
    v
UI/ (ScrollFrameMixin, Fonts, VerticalList, Book, Timeline, EventList, Settings, MainFrame)
```

*Corrected 2026-07-29: `DependencyContainer`, the whole `Business/` layer, `Utils/MathUtils`,
`Utils/BookUtils` and `Domain/Settings.lua` were all deleted. `Domain/Types.lua` is annotations only
and is deliberately **not** in the load graph -- editor tooling reads it off disk.*

### Strengths

**S1. Well-Defined Layered Architecture**
- Rare for WoW addons. Load order in `Core/_Includes.xml` is disciplined: Infrastructure → Utils → Data → Business → Domain.
- Ensures dependencies are available when needed.

**S2. Centralized State Management**
- `StateManager.lua` provides sophisticated pub/sub with dot-notation keys, automatic AceDB persistence, and subscriber notifications.
- Key-builder pattern (lines 118-178) enforces naming consistency and prevents typos.

**S3. Comprehensive Input Validation**
- `ValidationUtils.lua` provides thorough, dependency-free validation for all entity types.
- Every Domain and Business function uses guard clauses. Exemplary defensive programming.

**S4. Event Schema Validation**
- `EventManager.lua` (lines 68-221) defines formal schemas for every event type with required fields, optional fields, and custom validate functions.
- `safeTrigger` function (line 260) wraps all event dispatching in pcall, preventing cascade failures.

**S5. Clean Module Pattern**
- All modules use `local FOLDER_NAME, private = ...` pattern correctly.
- Globals have been systematically removed (evidenced by "REMOVED: Global exports" comments).
- Modules accessed via `private.Core.Utils.*` or `private.Core.*`.

**S6. Proxy/Facade Pattern in Data.lua**
- `Data.lua` (lines 236-303) uses `createSearchEngineProxy` and `createDataRegistryProxy` pattern.
- Eliminates repetitive guard-and-delegate boilerplate.

**S7. Plugin API**
- Supports external plugins through both `Chronicles:RegisterPluginDB()` and `ChroniclesPlugins` manifest system.
- Manifest approach is fire-and-forget, auto-scanning on ADDON_LOADED.

**S8. Full Localization**
- All user-facing strings in the data layer use `AceLocale-3.0` with locale keys.
- Data files reference `Locale["key"]` throughout, enabling complete translation.

**S9. Cache System with Bounds**
- `Cache.lua` implements a bounded cache with `MAX_CACHE_ENTRIES = 100` (line 63).
- Cache invalidation per key type, dirty tracking, pre-warming, and warm-all strategies.
- Prevents unbounded memory growth.

**S10. LuaLS Type Annotations**
- `Domain/Types.lua` provides `@class` annotations for all domain objects.
- Enables IDE support and documentation. Best practice rarely seen in WoW addons.

### Critical Issues

**C1. Global Namespace Pollution** -- **resolved (2026-07-29)**
- ~~`Core/Data.lua:15`: `RPEventsDB = {}`~~ -- gone with the RP integration.
- ~~`Core/Business/DateCalculator.lua:327` and `FilterEngine.lua:456`: `_G.` exports~~ -- both files
  deleted with the `Business/` layer.
- ~~All DB files use globals: `WorldofwarcraftEventsDB = {...}`, ~45 total.~~ -- all 41 now declare
  `private.DB.<Name>DB`, and `DB/DB.lua` reads them from `private.DB`. **The fix was made in the
  Chronicles-tauri generator first** and the checked-in files rewritten to match its output, because a
  fix applied only here is overwritten by the next data export.
- The remaining intentional globals are `Chronicles` (public facade), `ChroniclesPlugins` (the
  cross-addon data contract), and the XML mixin tables the loader resolves by global name.
- `UI/Events/TimelineTemplate.xml` also used to leak `Label1..9` / `Period1..8`; the period grid now
  uses frame pools.

**C2. Inconsistent Faction Reference Format Between Events and Characters** -- **still live, now
documented as a quirk rather than fixed.**
- **Events** reference factions as: `{["greatwars"] = {15, 1}, ["worldofwarcraft"] = {22}}`
- **Characters** reference factions as: `{23}` (flat array)
- ~~`SearchEngine.findFactions(ids)` expects event-style format~~ -- `findFactions` was removed
  entirely (it had no callers), so that particular silent-failure route is closed. The **data model
  asymmetry is unchanged**, and `PLUGINS.md` § "Cross-references (note the format asymmetry)" now
  instructs plugin authors to reproduce it. Normalizing it is a data migration, not a code change.

**C3. Silenced Errors in Event Callbacks** -- **resolved.** `EventManager` now forwards to
`geterrorhandler()` at three points, including the per-subscriber `pcall` (`EventManager.lua:344-346`).
The same treatment was applied to the asynchronous cache warm queue, `Chronicles:ExecuteWhenReady`, and
the StateManager subscription replay in `MainFrameUI`.

**C4. StateManager Initialization Race Condition** -- **resolved by deletion of the dead half.** The
unused `initStateManagerDependencies` lazy-init system is gone; `init()` still calls
`HelperUtils.getChronicles()` directly, which is now the only path rather than one of two.

**C5. EventManager Schema Validation Mismatch** -- **resolved.** `AddonStartup` no longer declares
required fields it never receives, and the schemas are now enforced (see C6).

**C6. Event Schema `required` Fields are Never Enforced** -- **resolved.** `required` is checked at
trigger time, including for the dynamic `DisplayTimelineLabel<n>` / `DisplayTimelinePeriod<n>` names,
which resolve to their base schema. `Tests/specs/EventManager_spec.lua` covers it.
This mattered more than the report implied: the timeline's paging handlers took `(isVisible)` while
the trigger sent `{visible = true}`, so both arrows were permanently disabled. Enforcement is what
makes that class of mismatch visible.

**C7. Duplicate Comment Block in EventManager** -- resolved; the header was rewritten.

**C8. Missing `nil` Check in `hasEventsInDB`** -- **moot.** `hasEventsInDB` and `hasEvents` were both
removed from `SearchEngine` and from the `Chronicles.Data` facade; nothing called them.

**C9. `table.maxn` is Deprecated** -- **moot.** The only call site was `AddRPEvent`, deleted with the
RP integration.

### Weaknesses

**W1. Confused Layer Naming and Placement** -- **half resolved.**
- ~~"Business" layer (DateCalculator, FilterEngine) loads before "Data"~~ -- the layer was deleted, so
  the ordering confusion is gone. Load order is now Infrastructure → Utils → Data → Data.lua → Domain.
- **Still live**: "Domain" loads last but contains UI orchestration (`Timeline.lua`:
  `DisplayTimelineWindow`, `DistributeTimelineLabels`), so the inversion the report describes remains.

**W2. Duplicated Search/Filter Logic** -- **largely resolved by deletion.**
- ~~`FilterEngine.lua`~~ and ~~`DateCalculator.lua`~~ are gone, removing two of the four copies of the
  year-range overlap check. What remains is `SearchEngine.isEventInRange` plus the per-entity methods in
  `Domain/Events.lua`, `Domain/Characters.lua` and `Domain/Factions.lua`. Worth re-checking whether the
  Domain copies are still reachable before consolidating further.

**W3. Inconsistent Naming Conventions**
- Function casing varies: `PascalCase` in Business/Domain, `camelCase` in Infrastructure/Data.
- Key naming inconsistent: `buildSelectionKey` vs `buildUIStateKey` vs `buildTimelineKey`.

**W4. DependencyContainer is Underutilized** -- **resolved: deleted.** The container is gone (v2.1.0,
"remove dependency container"). Load-order cycles are now handled by ordering the `_Includes.xml` chain
and by lazy field lookups at call time. Do not reintroduce it without a cycle that ordering genuinely
cannot fix.

**W5. Repetitive Code in TimelineBusiness.lua** -- **still live**, and the chains are now shorter: the
250 and 50 branches were removed with the mod250/mod50 buckets, leaving 1000/500/100/10 in both
`getDateCurrentStepIndex` and `getCurrentStepPeriodsFilling`. The suggested lookup table would still be
an improvement, and would keep the two functions in step with `constants.config.stepValues`.

**W6. `generateTimelinePeriods` / `generateDefaultPeriods` Code Duplication** -- **still live.**
`generateTimelinePeriods` now reads its bounds from the cache and falls through to
`generateDefaultPeriods` when either bound is nil, which is a cleaner boundary than before but does not
remove the duplication.

**W7. Settings.lua is Partially Dead Code** -- **resolved by deletion.** `Core/Domain/Settings.lua`
(the 221-line `DEFAULT_SETTINGS` structure and the `ApplyFontSize` no-op) was deleted, along with the
unread `settingsState.debugMode` default. `UI/Settings/Settings.lua` -- the panel that is actually
wired up -- is unaffected and remains live.

### Data Layer Analysis

**Data Structure Design**
- Well-structured with three entity types (Events, Characters, Factions).
- Each has consistent core fields. Events use `yearStart/yearEnd` ranges for temporal queries. Good design.
- Collection-based organization by expansion is logical and extensible.

**Normalization Issues**
- **C2 above**: Faction references inconsistent between Events (collection-keyed) and Characters (flat array).
- Character-to-faction relationships use bare IDs without collection context. Makes cross-collection lookups ambiguous.
- Events reference characters in collection-keyed format, but characters don't back-reference events.

**Extensibility**
- Plugin API is well-designed. External addons can register via `ChroniclesPlugins` global table or call `Chronicles:RegisterPluginDB()`.
- Collection system is open for extension.

**Locale Separation**
- Excellent. All display strings use `AceLocale-3.0`. Data files use locale keys for labels, chapter headers, page content.
- Locale files loaded before DB files in `Chronicles.xml` (lines 8-9).

### Utils Layer Analysis

**Focus and Scope**
- Each util module is focused and single-purpose.
*Revised 2026-07-29 -- `MathUtils` and `BookUtils` were deleted, `Spacing` was added, and the surviving
modules were trimmed to their reachable functions.*

- **HelperUtils**: Minimal (just `getChronicles()`).
- **Spacing**: The shared spacing scale the reworked UI lays out against.
- **StringUtils**: HTML detection and cleaning.
- **TableUtils**: Functional operations (Set, Length, Filter, Map, DeepCopy, Merge, Contains).
- **ValidationUtils**: Type checking and entity validation.
- **UIUtils**: Frame manipulation helpers, including the frame-pool acquire used by the timeline grid.
- Entity-to-book transformation now lives in `UI/Book/ContentUtils.lua` (one exported function,
  `TransformEntityToBook`) with HTML generation in `UI/Book/HTMLBuilder.lua`.

**No Duplication Between Utils**
- Clean with no overlapping responsibilities. `TableUtils.Filter` reused throughout.

**Properly Scoped**
- All use `private.Core.Utils.*` namespace. Global exports removed. No circular dependencies.

### Summary Table

Ratings as of 2026-04-17, with a re-assessment after the July work in the third column.

| Aspect | Rating (Apr) | Notes → status 2026-07-29 |
|--------|--------|-------|
| Architecture Design | B | Solid layered approach, but layer names/placement are inverted → Business layer removed; Domain still holds UI orchestration |
| Naming Consistency | C+ | Mixed camelCase/PascalCase across layers → unchanged, and now documented as a navigation trap (the facade is PascalCase over camelCase internals) |
| Error Handling | B- | Good pcall usage, but silenced errors in EventManager → **fixed**: four swallow points now reach `geterrorhandler()` |
| Memory Management | B+ | Bounded cache, proper cleanup, no obvious leaks → unchanged; rails and event list now virtualize through `ScrollBox` |
| Globals Discipline | C | 45+ DB globals, RPEventsDB, DateCalculator, FilterEngine in _G → **fixed**: collections under `private.DB`, only `Chronicles` / `ChroniclesPlugins` / mixins remain |
| Code Duplication | C | Search/filter logic repeated 3-4 times across layers → two of four copies deleted |
| Documentation | A- | Excellent LuaDoc comments, type annotations, module headers → the in-repo *markdown* was the weak part, not the code comments; that is what this banner is about |
| Data Model | B | Well-structured but inconsistent faction reference formats → unchanged; now documented in `PLUGINS.md` |
| Extensibility | A | Plugin API is well-designed with two registration paths → unchanged; payloads are now type-checked and rejections reported |
| Validation | A | Comprehensive ValidationUtils used consistently → unchanged |
| Utils Quality | A | Clean, focused, no duplication, properly scoped → unchanged, two modules lighter |
| Dead Code | C+ | Unused DI container, partial Settings, unused schema `required` fields → **all three resolved**; roughly 2,100 net lines removed across two passes |

---

## 2. UI/UX Design -- Grade: **C+** (April) -- **most of this section is superseded**

> This whole section describes the pre-v2.1.0 window. `MainFrameUI` is now a real
> **1525x875** panel anchored `CENTER y=50`, with no scrim, movable by a drag strip, clamped to screen,
> and remembering its position in `ui.windowPosition`. The `TabContainer` layer is gone. The findings
> below are kept for the reasoning; each is annotated with its outcome. See
> `WoW Addon Design Analysis/proposal/03-defect-list.md` and `04-migration-plan.md` for the tracked
> versions.

### Layout & Structure

**Main Frame Composition** -- **superseded**
- ~~Full-screen overlay anchoring to TOPLEFT and BOTTOMRIGHT of UIParent, covering entire screen.~~
- ~~Semi-transparent black background (alpha 0.5).~~
- ~~Creates a "modal" experience.~~
- Now: `MainFrameUI` is `<Size x="1525" y="875"/>` anchored `CENTER` with `y=50` on `UIParent`
  (`UI/MainFrameUI.xml:111-115`), no scrim anywhere in the file, and the game world is visible and
  clickable around it. The 1480x825 tab container survives as the `TabUI` child frame
  (`:157-162`), anchored below the new drag strip rather than centred in an overlay.

**Tab System** (`MainFrameUI.xml`)
- Four content areas, re-anchored in v2.1.0. Current sizes:
  - **Events**: Timeline (1200x175, TOP) + EventList rail (268x650, BOTTOMLEFT) + Book (1200x650,
    anchored off the rail's BOTTOMRIGHT with a 12px gutter)
  - **Characters**: VerticalList rail (left, 268x650) + Book (1200x650)
  - **Factions**: VerticalList rail (left, 268x650) + Book (1200x650)
  - **Settings**: Full settings panel (1200x650)
- The rails were widened from 150 to 268 and now sit *beside* the book. They used to share the same
  BOTTOM anchor as the book, so opening a book hid the list behind it (comment at `:13-20`).

**Navigation Patterns**
- Tab system for top-level categories
- Timeline period buttons for temporal navigation
- Vertical sidebar lists for character/faction browsing
- ~~Paging controls within book and event lists~~ -- the rails and the event list now scroll; the
  hand-rolled paging control was deleted. The book still pages.

**Tab Placement Issue** -- **resolved.** The tab strip moved into the new drag strip along the top of
the panel, which also fixed the tabs overflowing the frame's top edge.

**Close Button Issue** -- **resolved.** `CloseButton` is now anchored to the frame itself,
`CENTER` on the panel's `TOPRIGHT` at `x="-8" y="-8"` (`UI/MainFrameUI.xml:165-169`), i.e. the
expected corner, at a frame level above the drag strip so the strip cannot swallow its clicks.

### Visual Design

**Font Choices** (`Fonts.xml`)
- Thorough multi-alphabet system supporting Roman, Korean, Simplified/Traditional Chinese, Russian.
- `FRIZQT__` (12-27px) for body text -- WoW's standard UI font.
- `MORPHEUS` (12-16px) for decorative/brand elements -- classic WoW quest/lore font.
- Font sizes range from 12px (small shadow) to 27px (huge headings).
- ~~Many font definitions commented out~~ -- two unused font families were removed in v2.1.0.

**Color Usage**
- Gold `r=1, g=0.82, b=0` for selected states and branded elements.
- White `0.9, 0.9, 0.9` for default text.
- `SPELLBOOK_FONT_COLOR` (dark brown/sepia) used for book aesthetic.
- Timeline period indicators: three density tiers (low/medium/high events) with -selected variants.
- Overall palette consistent with WoW's dark UI chrome + golden highlights.

**Spacing & Consistency**
- ~~Book template uses consistent 50px insets (`SharedBookTemplate.xml:74-75`), 500px view width.~~
  `SharedBookTemplate` is deleted; the current book is `UI/Book/BookContainerTemplate.xml`, which keeps
  a 500px `viewWidth` KeyValue. A shared spacing scale (`Core/Utils/Spacing.lua`) was added in v2.1.0
  and is what the reworked panels lay out against.
- 15px x-padding between pages.
- Settings panel uses Auction House atlas textures for category navigation (polished Blizzard visual system).

### Interaction Patterns

**Filtering**
- Event filtering via checkboxes for event types (war, battle, death, birth, etc.) -- `Settings.lua:391-493`.
- Collection toggling enables/disables entire expansion datasets -- `Settings.lua:495-567`.
- Character/faction filtering uses real-time search with 300ms debounce -- `VerticalListTemplate.lua:406-421`.

**Search**
- **Timeline search**: EditBox with placeholder "Enter year...", "Go" button. Supports negative years.
- Validates range against `historyStartYear` and `futur` (`UI/Events/TimelineTemplate.lua:392` after
  the timeline rebuild). The `futur` typo is **still live** -- `Constants.lua:37` -- and now has 10
  read sites across `TimelineBusiness.lua` and `Domain/Timeline.lua`, so renaming it is a small
  mechanical sweep rather than a one-line fix.
- **Vertical list search**: Real-time text filtering by name.

**Pagination**
- **Book pages**: Standard WoW paging controls with page turn sounds -- still there
  (`UI/Book/BookContainerTemplate.xml:105-106`).
- ~~**Event list**: Custom `EventListPagingControlsMixin` supports Shift+Click (10 pages) and
  Ctrl+Click (100 pages).~~ **Gone.** The event list and both rails scroll instead of paging
  (`fa98066`, `5432787`), and the duplicated paging control was deleted (`a7d09df`). No
  `IsShiftKeyDown` / `IsControlKeyDown` remains anywhere under `UI/`, so those power-user shortcuts
  were lost with it -- worth noting as a regression if anyone missed them.
- Mouse wheel scrolling supported on both timeline and paging controls.

**Sound Feedback**
- Window open/close: talent tree sounds.
- Tab switching: tab sounds.
- Page turning: ability page turn sounds.
- List item clicks: checkbox click sound.
- List item hover: menu option sound.

**Tooltips**
- Vertical list items show contextual tooltips (item name, chapter count, author, type-specific info).
- Event list items have **NO tooltips** -- only `OnClick` handler, no `OnEnter`/`OnLeave`.

**Book Corner Animation**
- Flipbook animation plays on book corner when hovering paging buttons. Survived the book rewrite:
  it is now `SinglePageBookCornerFlipbook` in `UI/Book/BookContainerTemplate.xml:48-56`, driven from
  `BookContainerTemplate.lua:49-68`.
- Nice polish touch using spellbook corner atlas.

### Accessibility

**Text Readability**
- Body text at 14px FRIZQT is readable but small for extended reading.
- Chapter headers use `SystemFont_Huge2` -- good contrast.
- `SPELLBOOK_FONT_COLOR` on parchment provides adequate but not exceptional contrast.
- White text on dark backgrounds has good readability.

**Screen Real-Estate** -- **largely resolved**
- ~~Addon takes over ENTIRE screen (full-screen overlay).~~ It is a 1525x875 panel; the world stays
  visible and clickable around it.
- Content area is still 1480x825, now as the `TabUI` child of that panel.
- **Still open:** the panel is a fixed size, so smaller resolutions struggle and larger ones waste
  space. `SetResizable` appears nowhere in the addon.
- ~~Character/faction sidebar lists are only 150px wide.~~ Widened to 268px in v2.1.0.

**Keyboard Navigation**
- Date search input handles Enter (submit) and Escape (clear/dismiss) -- `TimelineTemplate.lua:158-168`.
- Search boxes handle focus gain/loss.
- **NO keyboard shortcuts** for tab switching.
- **NO keyboard navigation** between list items.
- Close button inherits `UIPanelCloseButton` which supports Escape key.

### Book/Pages System -- **rewritten, this subsection describes the deleted layer**

> v2.1.0 replaced the paged book wholesale. `SharedBookTemplate`, `UI/Templates/BookPages.*` and
> `Core/Utils/BookUtils.lua` are all deleted. The current layer is `UI/Book/`:
> `BookContainerTemplate` (frame + paging + corner flipbook), `HTMLContentTemplate` (one
> `SimpleHTML` page), `HTMLBuilder.lua` (record -> HTML document) and `ContentUtils.lua`. The seven
> per-row content templates below no longer exist -- one HTML document is rendered per page, which is
> also why eleven of the twelve `constants.bookTemplateKeys` were dropped and only `HTML_CONTENT`
> remains.

**Architecture** -- ~~`SharedBookMixin` (`SharedBookTemplate.lua`) is well-designed and agnostic.~~
- ~~Content arrives pre-transformed. Transformation happens in `MainFrameUI.lua:167-239`.~~
  Still true in shape: `MainFrameUI` derives the book content and hands it to
  `BookContainerMixin:OnContentReceived` (`UI/Book/BookContainerTemplate.lua:80`).
- ~~Displays as dual-page spread using spellbook atlas textures.~~ Single page.
- ~~Content rendered via `PagedCondensedVerticalGridContentFrameTemplate` with 2 views per page.~~

**Content Templates** -- all seven deleted (`CoverPageTemplate`, `EventTitleTemplate`,
`SimpleTitleTemplate`, `ChapterHeaderTemplate`, `ChapterLineTemplate`, `HtmlPageTemplate`,
`EmptyTemplate`). Title, dates, author and chapter headers are now markup emitted by `HTMLBuilder`.

**HTML Handling**
- ~~`CoverPageMixin` dynamically detects HTML content and switches between FontString and
  ScrollFrame+SimpleHTML (`BookPages.lua:186-218`).~~ No longer needed: every page is HTML, so the
  branch disappeared along with the mixin.

**Empty State** -- **resolved**
- ~~`ShowEmptyBook()` displays "No content available" ... hardcoded in English.~~
  `BookContainerMixin:ShowEmptyBook(promptText)` (`UI/Book/BookContainerTemplate.lua:110`) takes the
  text from the caller, and `MainFrameUI` passes `Locale["BookEmptyPromptEvent"]` /
  `...Character` / `...Faction` (`UI/MainFrameUI.lua:309,321,338,361`). The event prompt reads
  "Select an event from the timeline or the list to read its chronicle."

### Settings Panel

**Organization**
- Left-sidebar category navigation (200px wide, `Settings.xml:120-149`).
- Auction House-styled visual treatment.
- Categories:
  1. Settings (home/welcome page)
     - Event Types (sub-category)
     - Collections (sub-category)

**Home Page**
- Configuration Overview, Getting Started tips, About Chronicles (`Settings.xml:207-339`).
- All text properly localized.

**Event Types Tab**
- Dynamically generates checkboxes for each event type using `ChroniclesSettingsCheckboxTemplate` (`Settings.lua:391-493`).
- Changes immediately trigger cache invalidation and timeline refresh.

**Collections Tab**
- Dynamic checkbox generation for expansions (`Settings.lua:495-567`).
- Toggling immediately refreshes timeline and event data.

**What's Missing**
- No font size or scale settings.
- No layout customization.
- No color theme options.
- No "reset to defaults" button.
- No keybinding configuration.
- Logs category mentioned in comments not implemented.

### Strengths

1. **Excellent font internationalization** -- full CJK and Cyrillic support with per-alphabet families.
2. **Thorough sound design** -- every major interaction has appropriate audio feedback using Blizzard's sound kit.
3. **Sophisticated state management architecture** -- StateManager subscription pattern provides clean unidirectional data flow.
4. **Book visual design** -- using spellbook atlas textures creates authentic lore-reading experience.
5. **Search with debounce** -- 300ms throttling prevents excessive re-rendering during type-ahead.
6. **Settings onboarding** -- welcome page with configuration overview and getting-started tips.
7. **Timeline density visualization** -- three visual tiers (low/medium/high) give heat-map overview.
8. **Power-user pagination shortcuts** -- Shift+Click for 10 pages, Ctrl+Click for 100 pages.
9. **Tooltip system** -- contextual information in tooltips (chapter count, author, race/allegiance).
10. **Reusable template system** -- configuration-driven vertical list, specialized per content type
    via `CreateFromMixins`. (The `VerticalListTemplate_Examples.lua` file that served as its
    documentation was deleted as dead code; the template itself stands.)

### Weaknesses

1. ~~**Full-screen modal overlay blocks gameplay.**~~ **Resolved** in v2.1.0 -- movable 1525x875 panel.
2. **No visual selection feedback** on event list items after clicking. **Still live**:
   `EventListItemMixin` (`UI/Events/EventListTemplate.lua:9-51`) has `Init` and `OnClick` and nothing
   that marks the selected row.
3. **Event list items lack hover states and tooltips** -- unlike vertical list items. **Still live**:
   `EventListTemplate.xml:48` declares only `<OnClick>`.
4. ~~**Close button mispositioned** at `x=-140, y=-175`.~~ **Resolved** -- see Close Button above.
5. ~~**Tabs at bottom.**~~ **Resolved** -- the tab strip moved into the drag strip along the top.
6. ~~**Sidebar lists too narrow at 150px.**~~ **Resolved** -- 268px.
7. **No breadcrumb or back-navigation** in book view. **Still live.**
8. ~~**Hardcoded English strings** bypass localization (`SharedBookTemplate.lua:87`).~~ **Resolved** --
   the book's prompts and error messages are localized.
9. **No empty-state guidance** for characters/factions tabs. **Resolved** --
   `Locale["BookEmptyPromptCharacter"]` / `...Faction` are shown by `MainFrameUI`.
10. **Settings panel has no Apply/Reset controls** -- all changes immediate. **Still live** (by design).

### Missing WoW-Standard Patterns

> Items 1 and 2 were wrong when written, not since fixed -- both features predate this analysis.

1. ~~**Minimap button** -- referenced in locale but not implemented.~~ **Incorrect.** It is
   implemented: `Chronicles.lua:36` takes `LibDBIcon-1.0`, `:67` builds the LDB object from
   `constants.minimapIcon`, `:130` registers it, and `db.global.options.minimap` persists the
   hide flag.
2. ~~**Slash command feedback** -- no `/chronicles` command visible.~~ **Incorrect.**
   `Chronicles.lua:91` calls `RegisterChatCommand`.
3. **Resizable/movable frame** -- **half done.** Movable and clamped to screen since v2.1.0
   (`movable="true"` at `MainFrameUI.xml:111`, `SetClampedToScreen` at `MainFrameUI.lua:167`, drag
   strip at `:169-192`, position persisted in `ui.windowPosition`). Not resizable: `SetResizable`
   appears nowhere.
4. **Favorite/bookmark system** -- no way to bookmark entries. **Still live.**
5. **History/recent list** -- no "recently viewed" tracking. **Still live.**
6. **Scale slider in settings** -- no UI scale option. **Still live.**
7. **Right-click context menus** -- no copy/link/favorite actions. **Still live.**
8. **Text search across ALL content** -- only filters list items by name. **Still live.**
9. **Keyboard shortcuts** -- no Ctrl+1/2/3/4 for tab navigation. **Still live.**
10. **Cross-references between entities** -- no hyperlinks within book content. **Still live, and now
    deliberately so.** Handlers for `chronicles:event:<id>` and its siblings existed but nothing ever
    generated such a link, and they wrote a bare id where every consumer expects a
    collection-qualified selection; they were removed rather than fixed. Re-adding this means
    generating the links in `HTMLBuilder` and writing a proper selection.

---

## 3. Blizzard UI Standards Compliance -- Grade: **B**

### TOC File Analysis

**File:** `Chronicles.toc`

| Field | Value | Assessment |
|-------|-------|------------|
| Interface | `120001` | COMPLIANT -- Matches Patch 12.0.0 (Midnight) |
| Interface-Retail | `120001` | COMPLIANT -- Dual-field declaration correct |
| SavedVariables | `ChroniclesDB` | COMPLIANT -- Properly declared |
| OptionalDeps | `totalRP3, MyRolePlay` | **NOW STALE** -- the RP integration was deleted after v2.1.0. The field still declares the dependency but nothing reads either addon. It should be removed from the TOC. |
| DefaultState | `enabled` | COMPLIANT |
| Version | `v2.1.0` | See `CHANGELOG.txt`: a v2.2.0 section is open and unreleased, so this field is due a bump. |

### Modern Widget Usage

**Compliant Patterns**
- **EventFrame usage** (now `UI/ScrollFrameMixin.lua:18`, moved out of the deleted `BookPages.lua`):
  `CreateFrame("EventFrame", nil, self, scrollBarTemplate)` -- correct modern type.
- **CreateFrame with templates**: All calls pass template strings (e.g., `"CategoryButtonTemplate"`).
- **Mixin-based architecture**: Proper mixin tables assigned via `mixin=""` in XML.
- **ShowUIPanel/HideUIPanel**: `MainFrameUI.lua:66-68` uses Blizzard's panel management system.
- **DataProvider pattern**: `CreateDataProvider()` used throughout -- modern Blizzard data binding.

**Non-Compliant Patterns**
- **No FramePool/ObjectPool usage in Settings**: **still live.** Checkboxes are created with
  `CreateFrame` inside loops (`Settings.lua:423-429` and `:526-532`) and manually cleaned up via
  `UIUtils.CleanupElementArray` (`:406`, `:510`) rather than recycled through pools.
- ~~**Global frame names in XML**: `TimelineTemplate.xml` declares `Label1`-`Label9`,
  `Period1`-`Period8` as globals.~~ **Resolved** in v2.1.0 (`eeec0ef`): the period grid was rebuilt on
  frame pools sized from the configured page size, and the seventeen frame globals went with the
  hand-chained XML. `grep 'name="Label\|name="Period'` over `TimelineTemplate.xml` now returns
  nothing. This is `proposal/03-defect-list.md` § C-5.

### Mixin & Template Patterns

**Compliant Patterns**
- **Mixin() pattern**: All mixins assigned via XML `mixin=""` attribute.
- **Virtual templates**: All reusable templates use `virtual="true"` correctly.
- **Template inheritance**: Proper use of `inherits=""` throughout.
- **KeyValues**: Extensive and correct use with proper `type` attributes.
- **parentKey usage**: Good use for child frame access.
- **parentArray**: Correct use for view collections.
- **GenerateClosure**: Used in paging controls and book templates.

**Non-Compliant Patterns**
- **Global mixin declarations**: Mixins like `MainFrameUIMixin`, `TabUIMixin` declared as globals. Namespacing under addon table would be cleaner.
- **Inline Lua in scripts**: **partly resolved.** Two of the four sites are gone:
  - ~~`TimelineTemplate.xml:77-91` and `:100-103`~~ -- the timeline rebuild left the file with only
    `<OnClick method="OnClick"/>` (`:50`) and `<OnLoad method="OnLoad"/>` (`:187`); it has no inline
    script bodies at all now.
  - `UI/VerticalListTemplate.xml:81-104` -- OnTextChanged/OnEditFocusGained/OnEditFocusLost/OnLoad.
    **Still live** (plus two further inline `<OnLoad>` at `:151` and `:161`).
  - `Settings.xml:16-22` -- OnEnter/OnLeave. **Still live.**
  - Modern Blizzard practice moves script logic into mixin methods.

### Settings System

### **CRITICAL NON-COMPLIANCE**

The addon does **NOT** use Blizzard's modern Settings API.

- **No `Settings.RegisterAddOnCategory()`** found anywhere.
- **No integration with game's Settings panel** (Escape > Options > AddOns).
- Builds custom settings UI using `SettingsMixin` with custom tab system.
- `Settings.xml:7` inherits from `InterfaceOptionsCheckButtonTemplate` -- **deprecated legacy template**.
- May be removed in future patches.

**Impact**: Players cannot find Chronicles settings through the standard game Settings panel. Violates user expectations and Blizzard's addon settings integration pattern.

### Event Handling

**Compliant Patterns**
- **EventRegistry**: Uses `EventRegistry:TriggerEvent()` and `EventRegistry:RegisterCallback()` via wrappers in `EventManager.lua:48-62`.
- Modern Blizzard custom event pattern.
- **Hybrid State+Event architecture**: Migrated selection events to `StateManager` with subscribe/publish.
- **Event validation schemas**: `EventManager.lua:68-221` implements validation for all custom events.
- **pcall wrapping**: Both triggers and callbacks wrapped in `pcall`.
- **WoW native events**: Uses AceEvent for `ADDON_LOADED`, `PLAYER_LOGIN`.

**Minor Concerns**
- **C_Timer.After for initialization**: `TimelineTemplate.lua:51-56` uses workaround for timing. Fragile.
- **Dynamic event names**: `TimelineTemplate.lua:302-303` concatenates event names. Makes system harder to trace.

### Secure Frame Considerations

**COMPLIANT -- Low Risk**

- **No combat-related functionality**: Lore/history viewer only. No combat interaction.
- **No protected functions**: Does not modify Blizzard frames.
- **No taint-prone patterns**: Only `RegisterForClicks("anyUp")` in bundled LibDBIcon (well-tested library).
- **ShowUIPanel/HideUIPanel**: Called appropriately from user-initiated actions, not combat events.

### XML Patterns

**Compliant Patterns**
- **Proper namespace declaration**: `xmlns="http://www.blizzard.com/wow/ui/"`.
- **KeyValues**: Used correctly throughout with proper `type` attributes.
- **Atlas textures**: Uses atlas references (preferred over file-path).
- **Script handler methods**: Uses `method=""` attribute (clean modern pattern).
- **Layer organization**: Proper use of `level="BACKGROUND"`, `"ARTWORK"`, `"OVERLAY"` with `textureSubLevel`.

**Non-Compliant Patterns**
- **Inline Lua in scripts**: (See Mixin & Template Patterns above -- two of four sites resolved).
- ~~**Global frame names**: `Label1`-`Label9`, `Period1`-`Period8` in `TimelineTemplate.xml`.~~
  **Resolved** -- pooled, see above.
- ~~**File-path texture references**: `EventListPagingControls.xml:8-20` uses
  `Interface\Buttons\UI-SpellbookIcon-*`.~~ **Resolved** -- `EventListPagingControls.xml` was deleted
  with the duplicated paging control (`a7d09df`), and `UI-SpellbookIcon` appears nowhere in `UI/`.
  Remaining `file="Interface\..."` references are the addon's own `Art\` files plus Blizzard's
  `UI-Background-Rock`, both low-risk.
- ~~**Color value bug**: `EventListTemplate.xml:16` has `<Color r="0.0" g="125.0" b="0.0"/>`.~~
  **Resolved** -- the row's font colour is now `<Color color="WHITE_FONT_COLOR" />`
  (`EventListTemplate.xml:43`); no `125.0` remains anywhere under `UI/`.

### Midnight/TWW Compatibility

**COMPLIANT -- No Deprecated APIs Detected**

- **No removed 12.0 APIs**: Does not use any of the 138 APIs removed in Patch 12.0.0.
- **No combat log parsing**: No `COMBAT_LOG_EVENT_UNFILTERED` usage.
- **No secret value concerns**: Does not query `UnitHealth`, `UnitPower`, or other combat-sensitive APIs.
- **No addon messaging in instances**: Does not use `SendAddonMessage`.
- **TOC version is current**: `120001` matches Midnight.

**Potential Future Risks**
- **InterfaceOptionsCheckButtonTemplate** (`Settings.xml:7`): Legacy template may be removed. Should
  migrate to custom or modern template. **Still live** -- unchanged.
- ~~**Hardcoded file-path textures** (`EventListPagingControls.xml:8-20`).~~ **Resolved** -- file deleted.

### Compliance Scorecard

| Category | Rating (Apr) | Notes -> status 2026-07-29 |
|----------|--------------|----------------------------|
| Modern Widget Usage | B+ | Good mixin/template architecture, DataProvider usage, EventFrame. Missing FramePool -> the *timeline* now pools; Settings checkboxes still do not. |
| Mixin & Template Patterns | A- | Excellent use of virtual templates, KeyValues, inherits, parentKey. Minor global namespace issues -> the seventeen timeline frame globals are gone; only the XML mixin tables remain global, which WoW's loader requires. |
| Settings System | F | Does not use Blizzard's Settings API at all. Uses deprecated InterfaceOptionsCheckButtonTemplate -> unchanged, still F. |
| Event Handling | A | EventRegistry with validation, hybrid state+event pattern, pcall safety -> `required` fields are now enforced at trigger time rather than merely declared. |
| Secure Frame Considerations | A | No taint issues, no combat interaction. Clean -> unchanged. |
| TOC File | A- | Current Interface version, proper SavedVariables. Missing IconTexture and AddonCompartmentFunc -> both still missing, and `OptionalDeps` is now stale. |
| XML Patterns | B | Good atlas/KeyValues/method usage. Inline Lua, global names, and a color bug -> global names and the colour bug fixed; two inline-Lua sites remain. |
| Midnight Compatibility | A | No deprecated API usage. Ready for 12.0 -> unchanged. |

### Modernization Priorities

1. **Settings API integration** -- Register category in game's Settings panel or add redirect entry.
   **Still open.**
2. **Replace InterfaceOptionsCheckButtonTemplate** -- Use custom or modern template. **Still open.**
3. **Adopt FramePool** for settings checkboxes. **Still open** (the timeline was converted; Settings
   was not).
4. ~~**Eliminate global frame names** in TimelineTemplate.xml.~~ **Done** (`eeec0ef`).
5. **Move inline Lua to mixin methods.** **Partly done** -- `TimelineTemplate.xml` is clean;
   `VerticalListTemplate.xml` and `Settings.xml` are not.
6. ~~**Fix color bug** -- Correct `EventListTemplate.xml:16` from `g="125.0"`.~~ **Done.**
7. **Add AddonCompartmentFunc** -- Register with addon compartment button system. **Still open.**
8. ~~**Replace file-path textures** with atlas references.~~ **Done for the case cited** -- the
   paging-control file was deleted. The addon's own `Art\` files are necessarily file paths.
9. **(new) Remove the stale `OptionalDeps: totalRP3, MyRolePlay`** from the TOC -- the integration it
   declares no longer exists.

---

## 4. Feature Opportunities -- Prioritized Roadmap

### Current State Summary

Chronicles is a lore/timeline browser (v2.0.1 when analysed; **v2.1.0 released, v2.2.0 open**)
covering WoW's history from mythological origins through The War Within. Features:

- **Data model**: Events, Characters, and Factions across 15 collections with full localization.
- **Timeline UI**: Paginated timeline with zoom levels (1000/500/100/10 years --
  `Constants.lua:50`), period blocks, year-based search.
- **Book reader**: Event/character/faction details rendered as one HTML document per page.
- **Settings**: Toggle event types and collections.
- **Plugin API**: `Chronicles:RegisterPluginDB(name, manifest)` plus the `ChroniclesPlugins` global
  table. The bare-events-table signature this section was written against no longer exists.
- **Companion project**: now the Tauri app at `Chronicles-tauri/` in this workspace (the Electron
  editor is gone). Its JSON still includes `link` fields **not currently used**.
- ~~**RP addon integration**: Optional deps on totalRP3 and MyRolePlay.~~ **Removed** after v2.1.0 --
  `Chronicles.Data.RP`, `AddRPEvent` and `LoadRolePlayProfile` are all deleted. Only the now-stale
  `OptionalDeps` line in the TOC remembers it.

### Gaps Identified

1. **JSON database has `link` fields** (warcraft.wiki.gg URLs) that are stripped during export to Lua.
2. **No location/map data** -- events have no geographic association.
3. **No cross-entity navigation** -- clicking a character in an event doesn't navigate to their page.
   Still true, and the half-built hyperlink handlers that existed for it were deleted rather than
   completed (see Missing WoW-Standard Patterns § 10). Any implementation starts from
   `UI/Book/HTMLBuilder.lua`.
4. **Search is label-only** -- does not search chapter content, descriptions, character names.
5. **No bookmarks, favorites, or reading history**.
6. **No keyboard shortcuts** beyond `/chronicles` slash command.
7. **Characters lack death/birth years** -- no temporal positioning.
8. **No "related events" system** -- events sharing characters/factions not linked.
9. **TODO file confirms interest in**: timeline bookmarks, multi-criteria search, custom events, image galleries, map integration, achievement connections, themes, animations.

### Feature Proposals by Category

> **Feasibility ratings that cited `Core/Business/` are now optimistic.** The whole Business layer
> (`DateCalculator.lua`, `FilterEngine.lua`) was deleted after v2.1.0 as unreachable code:
> `IsEventActiveInYear`, `GetContemporaneousEvents` and `FilterBySearch` appear nowhere in the addon.
> Anything below that said "logic already exists" now means "logic existed and was removed; the
> algorithm is recoverable from git history, but it is new code either way." The surviving
> year-overlap primitive is `SearchEngine.isEventInRange(event, yearStart, yearEnd)`
> (`Core/Data/SearchEngine.lua:97`), and search itself is
> `SearchEngine.searchEvents` / `searchCharacters` / `searchFactions`.

#### 1. Content & Data Enrichment

**1a. Wowpedia/Wiki Links in Book Pages**
- **Description**: Add clickable wiki links to event, character, and faction book pages.
- **Feasibility**: **Easy** -- data already exists in ChroniclesDB JSON; export to Lua DB and render button.
- **Impact**: **High** -- connects addon to broader knowledge base.
- **Implementation**: Add `link` field to Lua DB tables. In book templates, add button that copies URL or uses `SetHyperlink`.

**1b. Cross-Entity Navigation (Clickable Characters/Factions in Events)**
- **Description**: Listed characters and factions in events should be clickable links to their pages.
- **Feasibility**: **Medium** -- data relationships exist; needs UI hyperlinks and state management.
- **Impact**: **High** -- transforms addon from flat browser to connected wiki.
- **Implementation**: Use `OnHyperlinkClick` or create clickable FontStrings in book pages. On click, set selection state and switch tabs.

**1c. Character Timeline Integration (Birth/Death Years)**
- **Description**: Add `yearStart`/`yearEnd` to characters, allowing them on timeline.
- **Feasibility**: **Medium** -- requires DB schema additions and data entry.
- **Impact**: **Medium** -- adds temporal context to characters.
- **Implementation**: Extend character DB schema. ~~Reuse `DateCalculator.IsEventActiveInYear()`~~ --
  deleted; use `SearchEngine.isEventInRange` (`Core/Data/SearchEngine.lua:97`), which does the same
  overlap test against a range.

**1d. Location/Map Data for Events**
- **Description**: Add map zone associations to events (e.g., "Battle of Mount Hyjal" -> Hyjal mapID).
- **Feasibility**: **Medium** -- requires data enrichment in ChroniclesDB.
- **Impact**: **Medium** -- geographic context enriches understanding.
- **Implementation**: Add `mapID` or `zoneName` fields. Use `C_Map.GetMapInfo()` for display.

#### 2. Interactive Features

**2a. Related Events Panel**
- **Description**: When viewing an event, show sidebar of related events (shared characters/factions/time periods).
- **Feasibility**: ~~**Easy** -- `DateCalculator.GetContemporaneousEvents()` already exists.~~
  **Now Medium** -- that function was deleted with the Business layer.
- **Impact**: **High** -- enables lore discovery through connections.
- **Implementation**: After event selection, query `Chronicles.Data:SearchEvents(yearStart, yearEnd)`
  for the selected event's span and exclude the event itself, then display in a collapsible panel.

**2b. Full-Text Search Across All Content**
- **Description**: Expand search to include chapter text, character names, faction names, descriptions.
- **Feasibility**: **Medium** -- ~~`FilterEngine.FilterBySearch` needs extension for chapter
  content~~; that function is gone, so this starts from `SearchEngine.matchesCharacterSearch` /
  `matchesFactionSearch` (`Core/Data/SearchEngine.lua:252,364`), neither of which looks at chapters.
- **Impact**: **High** -- currently users can only find events by exact title.
- **Implementation**: Extend filter to iterate `event.chapters[].pages[]`. Add search results in tabbed panel. Consider search index at load time.

**2c. Bookmarks & Reading History**
- **Description**: Let users bookmark favorites and track recently viewed items. Persist in SavedVariables.
- **Feasibility**: **Easy** -- store arrays in SavedVariables; render star icon on book pages.
- **Impact**: **Medium** -- QoL for repeat users.
- **Implementation**: Add `bookmarks = {}` and `history = {}` to SavedVariables. Add star icon. Create Bookmarks tab.

#### 3. Social & Community

**3a. Plugin Data Packs for Community Content**
- **Description**: Formalize `RegisterPluginDB()` API with versioning so community publishes standalone data packs.
- **Feasibility**: **Easy** -- API already exists; **documentation now exists too** (`PLUGINS.md`
  covers the manifest shape, both registration doors, the three data shapes and a complete example
  addon), so what is left is version checking and a Plugins section in Settings.
- **Impact**: **Medium** -- enables community growth without burdening addon author.
- **Implementation**: Add version validation. Publish template addon on GitHub. Add Plugins section in Settings.

**3b. Shareable Timeline Snapshots**
- **Description**: Generate string representing filtered view (e.g., "all Arthas events") for sharing in chat.
- **Feasibility**: **Medium** -- encode filter state as compact string or addon message.
- **Impact**: **Low** -- niche but enables social lore discussions.
- **Implementation**: Serialize filter config to base64. Use `C_ChatInfo.SendAddonMessage()` or chat hyperlink.

#### 4. Integration with WoW Systems

**4a. Achievement Cross-References**
- **Description**: Link lore events to related in-game achievements. Show completion status.
- **Feasibility**: **Medium** -- requires manual achievement ID mapping; use `GetAchievementInfo()` to check completion.
- **Impact**: **High** -- bridges lore to gameplay; "you were there" feeling.
- **Implementation**: Add `achievementIds = {}` field to events. Use `C_AchievementInfo.GetAchievementInfo()`. Display badge on completed achievements.

**4b. Dungeon Journal Cross-References**
- **Description**: Link events to Encounter Journal entries. Show related raid encounters.
- **Feasibility**: **Medium** -- use `C_EncounterJournal` API; requires encounter ID mapping.
- **Impact**: **Medium** -- useful for players preparing for content or exploring lore context.
- **Implementation**: Add `encounterIds = {}` field. Use `C_EncounterJournal.GetEncounterInfo()`. Add button in event pages.

**4c. RP Addon Deep Integration** -- **withdrawn**
- ~~Expand TRP3/MRP integration. Show RP character ages relative to timeline, import backstory dates.~~
- The shallow integration this would have built on was **deleted** after v2.1.0, deliberately:
  `Chronicles.Data:AddRPEvent`, `LoadRolePlayProfile` and the `Chronicles.Data.RP` table are gone,
  along with the empty "Roleplay" collection they created. Reviving this is a green-field feature, not
  an expansion, and it would also mean re-adding user-content write paths to the data layer.

#### 5. Visualization Improvements

**5a. Event Type Icons on Timeline Periods**
- **Description**: Display small icons representing dominant event types (war, death, era) in each period block.
- **Feasibility**: **Easy** -- event type data already available per period.
- **Impact**: **Medium** -- provides at-a-glance information.
- **Implementation**: In `TimelinePeriodMixin:OnDisplayTimelinePeriod()`, aggregate event types and show 1-3 small icons.

**5b. Expansion-Themed UI Skins**
- **Description**: Allow main frame to adopt visual themes matching each expansion.
- **Feasibility**: **Medium** -- requires art assets and frame background swapping.
- **Impact**: **Low** -- cosmetic but appreciated by lore enthusiasts.
- **Implementation**: Create theme definitions mapping to textures, borders, and colors. Use `SetTexture()` and `SetVertexColor()`.

**5c. Animated Timeline Transitions**
- **Description**: Smooth animations when zooming in/out or changing pages on timeline.
- **Feasibility**: **Medium** -- WoW supports `AnimationGroup` on frames.
- **Impact**: **Low** -- polish feature.
- **Implementation**: Use `AnimationGroup` with `Alpha` and `Translation` animations.

#### 6. Data Management

**6a. Export/Import User Data**
- **Description**: Allow exporting bookmarks, custom notes, and settings for sharing/backup.
- **Feasibility**: **Easy** -- serialize SavedVariables subset to encoded string.
- **Impact**: **Low** -- useful for multi-character players.
- **Implementation**: Use `LibSerialize` + `LibDeflate` to compress/encode. Show in copyable editbox.

#### 7. Accessibility & QoL

**7a. Keyboard Navigation**
- **Description**: Add keyboard shortcuts: Escape to close, arrow keys for timeline, Tab for tabs, Ctrl+F for search.
- **Feasibility**: **Easy** -- use `SetPropagateKeyboardInput()` and `OnKeyDown` scripts.
- **Impact**: **Medium** -- accessibility and power-user convenience.
- **Implementation**: Add `OnKeyDown` handler to `MainFrameUI`. Map keys to timeline/tab navigation.

**7b. Enhanced Tooltips**
- **Description**: Show rich tooltips on timeline periods (event names), event list items (date, type, characters), and entities.
- **Feasibility**: **Easy** -- WoW tooltip API is straightforward.
- **Impact**: **Medium** -- reduces clicks needed to explore.
- **Implementation**: Use `GameTooltip` on `OnEnter` handlers. Show top 3-5 event names for timeline periods.

**7c. Minimap Button Tooltip Enhancement**
- **Description**: Enhance minimap tooltip with stats (total events, characters, recently viewed).
- **Feasibility**: **Easy** -- extend existing `OnTooltipShow` callback.
- **Impact**: **Low** -- minor polish.
- **Implementation**: Count entries from `Chronicles.Data.Events`. Add lines to tooltip handler.

### Top 10 Prioritized Features

| # | Feature | Feasibility | Impact | Rationale |
|---|---------|-------------|--------|-----------|
| **1** | **Cross-Entity Navigation** | Medium | **High** | Transforms addon from flat reader to interconnected lore wiki. Characters/factions in events become clickable links. Single most impactful UX improvement. |
| **2** | **Related Events Panel** | ~~Easy~~ Medium | **High** | ~~Logic already exists in `DateCalculator.GetContemporaneousEvents()`.~~ That function was deleted with the Business layer; rebuild on `Chronicles.Data:SearchEvents`. Still enables organic lore discovery. |
| **3** | **Full-Text Search** | Medium | **High** | Currently search only matches event labels. Expanding to chapter content, character names, faction names makes entire database discoverable. |
| **4** | **Wowpedia/Wiki Links** | Easy | **High** | ChroniclesDB JSON already has `link` fields for every event. Exposing in addon connects users to broader ecosystem with minimal work. |
| **5** | **Bookmarks & Reading History** | Easy | Medium | Simple SavedVariables addition with star icon UI. Crucial for repeat users exploring lore over multiple sessions. |
| **6** | **Achievement Cross-References** | Medium | **High** | Bridges lore to gameplay with "you were there" indicators. Uses `C_AchievementInfo` API. Requires achievement ID mapping but extremely compelling. |
| **7** | **Enhanced Tooltips** | Easy | Medium | Low-hanging fruit that significantly reduces clicks needed to explore. Preview event names on timeline periods and character info on hover. |
| **8** | **Keyboard Navigation** | Easy | Medium | Arrow keys for timeline, Tab for tabs, Ctrl+F for search. Improves accessibility and power-user experience with minimal code. |
| **9** | **Event Type Icons on Timeline** | Easy | Medium | Visual enrichment of timeline periods. At-a-glance war/death/birth indicators make timeline more informative without clicking. |
| **10** | ~~**Plugin System Documentation**~~ | Easy | Medium | **Done** -- `PLUGINS.md` documents the manifest contract and ships a complete example addon. What remains from this row is version checking and a Plugins list in Settings. |

### Implementation Strategy

> The phasing below is unchanged, but item 10 is done and item 2 is no longer a Phase-1-sized job.

**Phase 1 -- Quick Wins (1-2 weeks)**
- Items 2, 5, 7, 8, 9 -- all Easy feasibility. Immediate core experience improvement with minimal risk.

**Phase 2 -- Core Interconnectivity (2-4 weeks)**
- Items 1, 3, 4 -- cross-entity navigation and search improvements that transform Chronicles into explorable lore network.

**Phase 3 -- Game Integration (4-6 weeks)**
- Item 6 (achievements) -- requires DB enrichment with achievement IDs but creates most differentiated feature.

**Phase 4 -- Community (ongoing)**
- Item 10 -- documenting plugin API and publishing template enables community to scale content independently.

### Key WoW API References

- **Achievements**: `C_AchievementInfo.GetAchievementInfo(id)`, `GetAchievementInfo(id)` for completion status
- **Encounter Journal**: `C_EncounterJournal.GetEncounterInfo(id)`, `C_EncounterJournal.GetSectionInfo(id)`
- **Maps**: `C_Map.GetMapInfo(mapID)`, `C_Map.GetBestMapForUnit("player")`
- **Tooltips**: `GameTooltip:SetOwner()`, `GameTooltip:AddLine()`, `GameTooltip:Show()`
- **Keyboard**: `frame:SetPropagateKeyboardInput(false)`, `frame:SetScript("OnKeyDown", handler)`
- **Hyperlinks in text**: `|H<linktype>:<data>|h[<display>]|h` format with `OnHyperlinkClick` on `SimpleHTML` frames
- **Animations**: `frame:CreateAnimationGroup()`, `animGroup:CreateAnimation("Alpha")`
- **Chat URL display**: `StaticPopup_Show()` with copyable editbox for wiki URLs

---

## Final Recommendations

### Immediate Actions (High Impact)

1. ~~**Fix UI/UX**: Replace full-screen overlay with standard movable frame.~~ **Done** in v2.1.0.
2. **Settings API**: Implement `Settings.RegisterAddOnCategory()` for compliance. **Still open** --
   the highest-value item left in this list.
3. **Cross-entity navigation**: Add clickable character/faction names in events. **Still open.**
4. ~~**Related events**: Surface `DateCalculator.GetContemporaneousEvents()` in UI.~~ **Still open, but
   restated**: that function no longer exists; build on `Chronicles.Data:SearchEvents`.

### Short-term Cleanup -- **all done, mostly by deletion**

5. ~~**Eliminate global namespace pollution** in Data.lua, DateCalculator.lua, FilterEngine.lua.~~
   Done: `_G.FilterEngine` / `_G.DateCalculator` were unexported and then both files deleted, and the
   41 `DB/` collection files stopped publishing globals (v2.1.0, `a342886`). `ChroniclesPlugins` is the
   only data-layer global left, by design.
6. **Fix faction data inconsistency** between Events and Characters. **Still live** -- see § 1 C2. The
   asymmetry is now documented in `PLUGINS.md` as the contract rather than changed, because changing it
   means re-exporting all fifteen collections.
7. ~~**Remove dead code**: commented font definitions, unused DI container, partial Settings methods.~~
   Done: two font families deleted (`966670f`), the dependency container deleted, `Core/Domain/Settings.lua`
   deleted, and roughly 2,100 net lines removed across the correctness pass.
8. ~~**Fix critical bugs**: silenced errors in EventManager, race condition in StateManager.~~
   Done -- see § 1 C3 and C4. `EventManager`'s per-subscriber `pcall` forwards to
   `geterrorhandler()` (`Core/Infrastructure/EventManager.lua:344-346`), as do the cache warm queue,
   `Chronicles:ExecuteWhenReady` and the StateManager subscription replay; the dead half of the
   StateManager lazy-init that caused the race was deleted.

### Medium-term Enhancements

9. **Full-text search** across all content. **Still open.**
10. **Wowpedia links** from existing JSON data. **Still open** -- needs a generator change first, so
    it starts in `Chronicles-tauri/src/app/addon/services/dbService.ts`, not here.
11. **Achievement integration** for "you were there" moments. **Still open.**
12. ~~**Plugin system documentation** to enable community contributions.~~ **Done** -- `PLUGINS.md`.

---

**Analysis Date**: 2026-04-17  
**Addon Version Analyzed**: 2.0.1  
**WoW Patch**: Midnight (12.0.0)

**Re-verified**: 2026-07-29 against `integration/2.0.1-hygiene` (v2.1.0 released, v2.2.0 open in
`CHANGELOG.txt`). Annotations added throughout; nothing was deleted, so the April reasoning stays
readable next to its outcome. Where an item is marked resolved, the evidence is the file and line
cited beside it.
