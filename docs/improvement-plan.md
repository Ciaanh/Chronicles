# Chronicles — Improvement Plan (v2, updated 2026-07-03)

Successor to the original improvement plan (`Chronicles-Improvement-Plan-1.md`), re-baselined
after a full project review on 2026-07-03. Items completed in the `cleanup/step1-hygiene`
branch are recorded at the bottom; everything above is remaining work, in suggested order.

---

## Next up — Phase 3: Robustness (reduced scope — 3.2 is done)

### 3.1 Fail-fast error surfacing (REPLACES the original "debug logging helper")
Decision (2026-07-08): No debug-mode / verbose-logging toggle. Chronicles is debugged in-game
with a fail-fast principle — errors must be visible during testing, never suppressed or gated.
See memory `fail-fast-debugging`.
- **Remove** dead `settingsState.debugMode` config (`Chronicles.lua` defaults; schema label in
  `EventManager.lua`). Do NOT wire it up.
- **Surface swallowed errors** instead of hiding them:
  - `EventManager.safeRegisterCallback` (EventManager.lua:285-292) catches callback errors and
    silently discards them ("Silently ignore callback failures to prevent cascade errors").
  - `EventManager.safeTrigger` (EventManager.lua:268-278) discards `errorMsg` on dispatch failure.
  - Fix: keep `pcall` isolation between subscribers, but forward the captured error to
    `geterrorhandler()(errorMsg)` so it shows in-game. Or drop the `pcall` where cascade
    isolation isn't needed and let it propagate to WoW's built-in handler.
- `StateManager.lua:442` doc comment promises "detailed error logging" that was never
  implemented; update the comment to match reality (validation uses `error(...)`, which already
  fails fast).

### 3.3 StateManager rehydrate method — DONE (commit ca407d9, 2026-07-08)
- Added `StateManager.rehydrate(key)`: re-emits the stored value to subscribers
  (newValue == oldValue) without mutating or persisting it; no-op when unset.
- `Chronicles:OnAddonStartup` now calls rehydrate for the five restored keys instead of the
  `getState`/`setState` round-trips (which also re-persisted redundantly).
- Also fixed the silent-swallow in `notifySubscribers` (forwards to `geterrorhandler()`).
- Covered by `Tests/specs/StateManager_spec.lua`.

### 3.x (new) Known plugin-timing gap
- `ADDON_LOADED` manifest scanning is unregistered at `PLAYER_LOGIN` (`Core/Data.lua:37-40`),
  so load-on-demand plugins loaded post-login must call `Chronicles:RegisterPluginDB` directly.
  Decide policy: keep + document as the contract, or keep listening after login.

---

## Phase 4: Documentation — DONE (commits 6757ccc, 9701323; 2026-07-08)

- 4.1 `PLUGINS.md` (repo root, tracked): manifest + `RegisterPluginDB` API, data shapes,
  a minimal working plugin, rules/gotchas. Linked from `Readme.md`.
- 4.2 `docs/event-state-catalog.md`: every event's payload/producers/consumers, the state-key
  builders, and the AceDB persistence buckets.
- 4.3 `EventManager.Validator` now enforces `required` generically (fail-fast on missing/non-table
  payload); removed the bogus `required={version,timestamp}` from AddonStartup/AddonShutdown and
  the duplicated comment block. Covered by `Tests/specs/EventManager_spec.lua`.
- 4.4 Annotated the two stale `docs/analysis` files with 2026-07-08 update notes.

---

## New items adopted from ANALYSIS.md / docs/analysis (not in original plan)

1. **Blizzard Settings API integration** (compliance grade F in ANALYSIS.md):
   `Settings.RegisterAddOnCategory()` is absent and `Settings.xml:7` inherits the deprecated
   `InterfaceOptionsCheckButtonTemplate`.
2. **UI text-overflow fix plan** (`docs/analysis/ui-text-overflow.md`, status: analyzed, pending
   implementation) — includes the empty-string `author` bug in `BookUtils.lua` ("by " with no name).
3. **Cross-repo contract mismatch**: the Tauri generator still emits the legacy
   `Chronicles.DB.Modules` contract while the addon expects `ChroniclesPlugins` manifests
   (see `docs/analysis/global-integration-review.md`). Highest-risk open item for the data pipeline.
4. **Full-screen overlay UX** — replace with a standard movable frame (top UX recommendation).
5. Only `enUS` locales exist despite full AceLocale scaffolding — translations are unblocked
   now that all UI strings route through `Locale[...]`.

---

## Completed — Phase 2 testability (branch `cleanup/step1-hygiene`, 2026-07-08)

- 2.1 Standalone Lua test harness in `Tests/`: vararg-bootstrap module loader,
  WoW-global stubs, minimal describe/it framework, deterministic runner.
  Run with `lua Tests/run_tests.lua` (local Lua 5.1 at `C:\Program Files (x86)\Lua\5.1\`).
- 2.1/2.2 Specs: MathUtils, TableUtils, StringUtils (main paths + nil/empty edges) and
  TimelineBusiness (calculateTimelineConfig with boundary years -150000/-999999/999999,
  consolidateTimelinePeriods, getStepValueIndex, calculateTimelinePagination). 36 tests, green.
- 2.3 GitHub Actions workflow `.github/workflows/ci.yml`: `luac -p` syntax gate over all
  addon Lua + test run on push/PR. Required a `.gitignore` tweak to track `.github/workflows`
  only (rest of `.github` stays local). NOTE: not yet verified green on GitHub — needs a push.

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
