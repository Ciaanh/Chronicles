# Chronicles — Improvement Plan (v2, updated 2026-07-03)

Successor to the original improvement plan (`Chronicles-Improvement-Plan-1.md`), re-baselined
after a full project review on 2026-07-03. Items completed in the `cleanup/step1-hygiene`
branch are recorded at the bottom; everything above is remaining work, in suggested order.

> **Re-verified 2026-07-29** against `integration/2.0.1-hygiene`. All of Phase 2 and most of Phases 3
> and 4 have since been delivered; each item below now records what actually happened rather than
> being dropped, because several were resolved by a route the plan did not anticipate.

---

## Phase 2: Testability — **done**

### 2.1 Stand up a standalone Lua test harness — **done**
- Delivered as `Tests/framework.lua`, `Tests/harness.lua`, `Tests/wow_stubs.lua` and
  `Tests/run_tests.lua`. `harness.loadModule` reproduces the
  `local FOLDER_NAME, private = ...` vararg bootstrap exactly as the client does, and
  `wow_stubs.lua` supplies the WoW globals.
- Specs cover `TableUtils`, `StringUtils`, `ValidationUtils`, `TimelineBusiness`, `StateManager`
  and `EventManager` — so the **Done when** criterion (TimelineBusiness plus two utility modules,
  main paths and edge cases) is met and exceeded.
- Two modules the original list named no longer exist: `Core/Business/DateCalculator.lua` and
  `Core/Utils/MathUtils.lua` were both deleted, and `MathUtils_spec.lua` went with the latter.
- **Correction to this item's toolchain claim:** there is no Lua at
  `C:\Program Files (x86)\Lua\5.1\` on this machine, and none on PATH. The interpreter actually in
  use is **LuaJIT 2.1** under `%LOCALAPPDATA%\Programs\LuaJIT\bin`. LuaJIT implements the Lua 5.1
  language, which is what WoW runs — so it is the right choice, and plain Lua 5.4 would be the wrong
  one. Run the suite with `./tools/harness.ps1 test -Addon Chronicles` from the workspace root; it
  locates the interpreter itself.

### 2.2 Edge-case coverage for timeline math — **done**
- `TimelineBusiness_spec.lua` covers an overlapping BC→AD range, an all-BC range, the clamped
  mythos/futur extremes, every configured step value and its index, period consolidation, and
  pagination including the last-page clamp.

### 2.3 Wire tests into GitHub Actions — **done**
- `.github/workflows/ci.yml` installs Lua 5.1 via `leafo/gh-actions-lua`, runs `luac -p` over every
  addon Lua file outside `Libs/`, then `lua Tests/run_tests.lua`. Triggers on pushes to `main` and on
  every pull request — so work on this branch has not been exercised by it yet.
- The same two gates run locally through `./tools/harness.ps1 check` and `./tools/harness.ps1 test`.

---

## Phase 3: Robustness (3.2 and 3.3 done; 3.1 partly)

### 3.1 Debug logging helper — **partly done, by a different route**
- `settingsState.debugMode` and the `StateManager.lua` "detailed error logging" doc comment have both
  been **deleted** rather than implemented, so the dead-config half of this finding is gone.
- The valuable half — errors no longer silently discarded — was addressed directly. `EventManager`'s
  per-subscriber `pcall` forwards to `geterrorhandler()` (`Core/Infrastructure/EventManager.lua:344-346`,
  with two further sites at `:308` and `:330`), and so do the cache warm queue,
  `Chronicles:ExecuteWhenReady`, and the StateManager subscription replay in `MainFrameUI`.
- **Still open:** the levelled logger itself. There is no `private.Core.log(level, msg, source)` and no
  gate to turn logging on; decide whether one is still wanted now that every specific leak is plugged.

### 3.3 StateManager rehydrate method — **done**
- `StateManager.rehydrate(key)` exists, re-emits the stored value to subscribers as
  `newValue == oldValue` without re-persisting, and returns false for a key with nothing stored or an
  invalid key. `StateManager_spec.lua` covers all four behaviours.
- `Chronicles:OnAddonStartup` is gone: startup restore is now one path,
  `Chronicles:RestoreStartupState`, which calls `rehydrate` for the five keys.

### 3.x (new) Known plugin-timing gap — **decided, still asymmetric**
- `ADDON_LOADED` manifest scanning is unregistered at `PLAYER_LOGIN` (`Core/Data.lua:89-92`),
  so load-on-demand plugins loaded post-login must call `Chronicles:RegisterPluginDB` directly.
- Policy chosen: keep the behaviour and document it as the contract. `PLUGINS.md` § 5 states it.

---

## Phase 4: Documentation

### 4.1 PLUGINS.md — **done**
- `PLUGINS.md` documents the manifest shape, the two registration doors, the three data shapes, the
  cross-reference format asymmetry, a complete minimal example addon, and the rules and gotchas.
- One gap remains: it does not yet mention that each payload must be a table, or that a manifest whose
  every payload is rejected registers nothing and fires no `TimelineInit`.

### 4.2 Event & state-key catalog — **done, in an existing file**
- Delivered as Appendix A (state keys) and Appendix B (events) of
  `.github/copilot-instructions.md`, alongside the schema examples in its § 3 and § 4, rather than as
  a new document. Both appendices were re-verified against source on 2026-07-29.

### 4.3 Fix event schema definitions — **done (enforced)**
- `EventManager` now enforces `required` at trigger time, and `EventManager_spec.lua` asserts it:
  a payload missing a declared required field is rejected, a non-table payload is rejected when
  fields are required, `AddonStartup` no longer claims required fields it never receives
  (`EventManager_spec.lua:39-43`), and the dynamic `DisplayTimelineLabel<n>` names resolve to the base
  schema.
- Two of the schemas this item was written against no longer need fixing because the events
  themselves are gone: `AddonShutdown` and `TabUITabSet` were deleted outright, constant and schema
  together, having never had a listener. `events.UIRefresh` was renamed from `"Timeline.CLEAN"` to
  `"UI.REFRESH"` in the same pass.

### 4.4 (new) Refresh stale analysis docs — **done**
- `docs/analysis/global-integration-review.md` and `docs/analysis/db-registration-system.md` were both
  brought up to date on 2026-07-29; the latter was rewritten. `docs/notes.md` and
  `docs/analysis/ui-text-overflow.md` were deleted, since both described the deleted paged book layer.

---

## New items adopted from ANALYSIS.md / docs/analysis (not in original plan)

1. **Blizzard Settings API integration** — **still open.** `Settings.RegisterAddOnCategory()` is
   absent and `UI/Settings/Settings.xml:7` still inherits the deprecated
   `InterfaceOptionsCheckButtonTemplate`.
2. ~~**UI text-overflow fix plan**~~ — **withdrawn.** The rendering path it analysed
   (`SharedBookTemplate` + `BookUtils.TransformEntityToBook` + `BookPages.xml`) was deleted wholesale
   by the v2.1.0 HTML book rewrite, taking the empty-string `author` bug with it. The document was
   deleted rather than updated; re-derive against `UI/Book/` if the phase is picked up.
3. ~~**Cross-repo contract mismatch**~~ — **resolved.** `Chronicles-tauri`
   (`src/app/addon/services/dbService.ts`, branch `feat/edition`) emits `private.DB` collections plus
   either `private.registerInternalDBs()` or a `ChroniclesPlugins` entry, with tests asserting it. No
   `Chronicles.DB.Modules` remains.
4. ~~**Full-screen overlay UX**~~ — **resolved.** `MainFrameUI` is a real 1525×875 panel, movable by a
   drag strip, clamped to screen, remembering its position through `ui.windowPosition`. The scrim is
   gone.
5. Only `enUS` locales exist despite full AceLocale scaffolding — **still open**, and still unblocked:
   all UI strings route through `Locale[...]`.

---

## Completed — Phase 1 cleanup (branch `cleanup/step1-hygiene`, 2026-07-03)

- 1.1 Duplicate FilterEngine: was already resolved pre-plan ("Cleanup step 1" commit, Feb 2026).
- 1.2 Removed orphaned `constants.defaults` from Constants.lua.
- 1.3 Removed commented-out `stepValues` history.
- 1.4 Localization: re-keyed collection display names to registered names (Collections settings
  tab showed raw identifiers); added missing `SettingsHomeQuickActionsTip3`; localized 5 tooltip
  strings in VerticalListTemplate.lua + "No content available" in SharedBookTemplate.lua;
  removed duplicate `L["year"]`.
- Deleted dead files `Core/Data/Types.lua` and `UI/Templates/VerticalListTemplate_Examples.lua`.
- Removed unconsumed `_G.FilterEngine` / `_G.DateCalculator` exports; `RPEventsDB` now local.
- 3.2 Plugin registration hardening: verified already done (manifest system, `ADDON_LOADED`
  re-scan, idempotent `RegisterPluginDB`) — no work needed beyond the 3.x gap above.

---

## Completed after this plan was written (2026-07-29 note)

Recorded here so nobody re-derives it from the sections above. `CHANGELOG.txt` is the authority.

- **v2.1.0** replaced the paged book layer with HTML rendering (`SharedBookTemplate`,
  `UI/Templates/BookPages.*` and `Core/Utils/BookUtils.lua` all deleted), made the main panel movable,
  rebuilt the timeline period grid on frame pools, moved the rails to `ScrollBox`, replaced the sample
  database with fifteen real expansion collections, removed the dependency container, and stopped the
  data layer publishing 41 globals.
- The **correctness pass after v2.1.0** fixed the timeline paging arrows, period double-counting, the
  year-0 origin, the book table of contents, and book blanking on refresh; centralized cache
  invalidation; and deleted the `Core/Business/` layer, `Core/Domain/Settings.lua`,
  `Core/Utils/MathUtils.lua`, the RP integration, the `PluginEvents` subsystem and the unused half of
  the `Chronicles.Data` facade.

Consequence for this plan: the dead-code and dead-config volume it was written against has dropped
sharply, so items phrased as "X is never read" should be re-checked before acting — several are now
gone rather than fixed.
