# Chronicles — Improvement Plan (v2, updated 2026-07-03)

Successor to the original improvement plan (`Chronicles-Improvement-Plan-1.md`), re-baselined
after a full project review on 2026-07-03. Items completed in the `cleanup/step1-hygiene`
branch are recorded at the bottom; everything above is remaining work, in suggested order.

---

## Next up — Phase 2: Testability (unchanged, still highest leverage)

Nothing has been started here. Do this before larger refactors.

### 2.1 Stand up a standalone Lua test harness
- Pure-logic modules (`Core/Data/TimelineBusiness.lua`, `Core/Business/DateCalculator.lua`,
  `Core/Utils/StringUtils.lua`, `MathUtils.lua`, `TableUtils.lua`) run without the WoW client.
- Harness must fake the `local FOLDER_NAME, private = ...` vararg pattern and stub WoW globals
  (`C_Timer`, etc.).
- A local Lua 5.1 toolchain exists at `C:\Program Files (x86)\Lua\5.1\` (lua.exe + luac.exe) —
  matches WoW's Lua version.
- **Done when:** `TimelineBusiness` plus two utility modules have tests covering main paths and
  edge cases (empty input, single event, boundary years).

### 2.2 Edge-case coverage for timeline math
- Test against the extreme constants: `historyStartYear = -150000`, `mythos = -999999`,
  `futur = 999999`, and zoom transitions across `stepValues = {1000, 500, 100, 10}`.

### 2.3 Wire tests into GitHub Actions
- `.github/workflows/` does not exist yet. Minimal workflow: install Lua 5.1 + runner, run suite
  on push. Could also run `luac -p` over all addon Lua files as a cheap syntax gate.

---

## Phase 3: Robustness (reduced scope — 3.2 is done)

### 3.1 Debug logging helper
- `settingsState.debugMode` (defined in `Chronicles.lua` defaults) is dead config — never read.
- `StateManager.lua:442` doc comment promises "detailed error logging" that was never implemented;
  `EventManager`'s pcall wrapper captures callback errors and silently discards them.
- Build `private.Core.log(level, msg, source)` gated on `debugMode`; use it in StateManager,
  EventManager (surface swallowed pcall errors), and data loading.

### 3.3 StateManager rehydrate method
- `Chronicles:OnAddonStartup` still re-notifies subscribers by `setState(key, existingValue)`
  round-trips. `setState` never short-circuits on equal values and always re-persists to AceDB.
- Add `StateManager.rehydrate(key)` (re-emit current value to subscribers without persisting)
  and use it in `OnAddonStartup`.

### 3.x (new) Known plugin-timing gap
- `ADDON_LOADED` manifest scanning is unregistered at `PLAYER_LOGIN` (`Core/Data.lua:37-40`),
  so load-on-demand plugins loaded post-login must call `Chronicles:RegisterPluginDB` directly.
  Decide policy: keep + document as the contract, or keep listening after login.

---

## Phase 4: Documentation

### 4.1 PLUGINS.md
- The plugin API is complete and totally undocumented: `Chronicles:RegisterPluginDB(name, manifest)`
  and the `ChroniclesPlugins` global manifest table (`Core/Data.lua:47-93`).
- Document expected DB shape (events/characters/factions) + a minimal working example addon.

### 4.2 Event & state-key catalog
- Reference doc for `constants.events` (Constants.lua) and state-key conventions
  (`buildUIStateKey`, `buildSelectionKey`, `buildSettingsKey`), mapping each to payload schema
  and producers/consumers.

### 4.3 Fix event schema definitions
- `EventManager` schema `required` arrays are never enforced (documentation-only), and the
  `AddonStartup` schema claims `{version, timestamp}` while the real payload is `{}`.
  Either enforce or align the declarations.

### 4.4 (new) Refresh stale analysis docs
- `docs/analysis/global-integration-review.md` flags a manifest bug already fixed in
  `Core/Data.lua:80`; `docs/analysis/db-registration-system.md` still references the removed
  `ChroniclesPluginData.Register()` path.

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
