# Global Integration Review

Date: 2026-04-17
Re-verified: 2026-07-29 against Chronicles `integration/2.0.1-hygiene` and Chronicles-tauri
`feat/edition`. Findings 1, 2 and 3 are resolved; 4, 5 and 6 stand. Resolutions are recorded inline
rather than deleted, so the reasoning stays with the finding.

Scope:
- Chronicles addon repository
- Reference external DB addon in refs/Chronicles-Data
- Chronicles Tauri generator (now at `Chronicles-tauri/` in this workspace, branch `feat/edition`)

## Findings

### 1. ~~Critical~~ RESOLVED: Tauri generator still emits legacy DB registration contract

The generator output still assumes the old `Chronicles.DB.Modules` + `Chronicles.DB:Init()` registration flow, while the current Chronicles integration has moved to manifest-based registration (`ChroniclesPlugins`).

Evidence:
- `I:/Dev/WoW/_Workspace/code_Chronicles-tauri/src/app/addon/services/dbService.ts`
  - `dbHeader` includes `local modules = Chronicles.DB.Modules`
  - `FormatDeclaration` emits `Chronicles.Data:RegisterXDB(...)`
  - `CreateDeclarationFile()` writes legacy-style `DB/DB.lua`
- `refs/Chronicles-Data/DB/DB.lua` now uses `ChroniclesPlugins[...] = { ... }`
- Generated DB content file headers in refs still reference `Chronicles.DB.Modules`

Impact:
- Contract mismatch between generator output and new registration strategy.
- Risk of runtime failures or manual patching needs when using generated addon output.

**Resolved 2026-07-29.** `Chronicles-tauri/src/app/addon/services/dbService.ts` on `feat/edition` has
no `Chronicles.DB.Modules` left. It now writes collection tables into `private.DB` (`dbNamespace =
"private.DB"`, line 60) and emits one of two `DB.lua` forms depending on export mode: embedded output
wraps the registrations in `function private.registerInternalDBs()`, external output builds a
`ChroniclesPlugins["<Name>"] = { ... }` entry. Both read the collections back off `private.DB`, and
`ChroniclesPlugins` is the only global either form declares — by design, since it is the cross-addon
contract. See the workspace `ANALYSIS.md` § A-15 for the full account.

### 2. ~~High~~ RESOLVED: Generator tests validate old behavior and miss migration regressions

Current tests assert legacy output markers and do not enforce manifest output.

Evidence:
- `Chronicles-tauri/src/app/addon/services/dbService.test.ts`
  - Expects `Chronicles.DB.Modules` in generated `DB/DB.lua`

Impact:
- CI can pass while generated files are incompatible with the new integration pattern.

**Resolved 2026-07-29.** The generator suite now asserts the manifest contract, including a test that
a generated collection file declares under `private.DB` and never matches a bare
`/^\s*LoreEventsDB\s*=/m` global. `npx vitest run` passes 57 tests across 9 files. (Installing deps
needs `npm ci --legacy-peer-deps` — pre-existing peer conflict, unrelated.)

### 3. ~~High~~ RESOLVED: Manifest loader reports event registration success without checking return value

In Chronicles core, manifest event registration sets `registered = true` even if `RegisterEventDB` fails.

Evidence:
- `Core/Data.lua`
  - `manifest.events` path sets `registered = true` unconditionally
  - `manifest.characters` and `manifest.factions` paths correctly check return values

Impact:
- False-positive success can trigger `TimelineInit` even when event registration was rejected.

**Resolved.** All three branches now guard on the return value
(`Core/Data.lua:132-140`): `if manifest.events and self:RegisterEventDB(pluginName, manifest.events)
then registered = true end`, and the same for characters and factions. `TimelineInit` fires only when
`registered` is true.

### 4. Medium: ADDON_LOADED auto-scan stops at PLAYER_LOGIN

Chronicles unregisters `ADDON_LOADED` on `PLAYER_LOGIN`.

Evidence:
- `Core/Data.lua`
  - `Chronicles:UnregisterEvent("ADDON_LOADED")` in `PLAYER_LOGIN` callback

Impact:
- Load-on-demand external plugins loaded after login will not be discovered through manifest scanning.
- Such addons must call `Chronicles:RegisterPluginDB(...)` explicitly.

**Still stands, but now decided rather than accidental** (verified 2026-07-29): `PLUGINS.md` § 5
documents this as the contract, so recommended action 4 below has been answered in favour of "keep
current behavior and require the runtime API for LoD plugins".

### 5. Medium: refs folder is git-ignored, reducing visibility of integration drift

Evidence:
- `.gitignore` includes `refs`

Impact:
- Reference addon changes are not visible in normal PR diffs.
- Harder to review migration correctness as contracts evolve.

### 6. Medium: Tauri README export section appears inconsistent with current generator outputs

Evidence:
- `I:/Dev/WoW/_Workspace/code_Chronicles-tauri/README.md` describes `Chronicles_Data.lua` and `Chronicles_Locales.xml` output.
- Generator currently emits structured DB files such as `DB/DB.lua`, `DB/DB.xml`, and locale files in `DB/Locales`.

Impact:
- Documentation mismatch can cause wrong operational expectations for export consumers.

## Cross-Repo Constraint

External DB content files are generated by the Tauri app. That means registration contract changes in Chronicles must be mirrored in:
- Tauri `DBService` generation templates
- Tauri tests asserting generated output
- External addon wrapper expectations

Without synchronized changes, generated addons remain a migration bottleneck.

## Recommended Actions

1. ~~Update Tauri `DBService` to generate manifest-compatible `DB/DB.lua`~~ — done, see finding 1.
2. ~~Update Tauri tests in `dbService.test.ts` to assert the new manifest output contract.~~ — done.
3. ~~Fix `Core/Data.lua` event-registration branch~~ — done, see finding 3.
4. ~~Decide policy for post-login plugin discovery~~ — decided: keep current behaviour, require the
   runtime API for LoD plugins, documented in `PLUGINS.md` § 5.
5. Align Tauri README export documentation with actual generated file structure. **Open.**
6. If refs remains a key integration target, consider tracking a reviewed snapshot outside ignored
   paths. **Open.**

## Assumptions / Open Questions

1. Whether Tauri output is intended to fully replace external addon DB folder content or be merged
   with a hand-maintained wrapper. **Open.**
2. ~~Whether long-term support for the legacy `ChroniclesPluginData` compatibility path should remain
   or be sunset after generator migration.~~ **Answered: sunset.** The global no longer exists on
   either side, and `CHANGELOG.txt` v2.1.0 records the removal as a breaking change. No shim was
   added; a plugin still calling it loads no data and reports nothing.
