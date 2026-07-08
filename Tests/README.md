# Chronicles test suite

Standalone unit tests for the addon's pure-logic modules. They run under a
plain Lua 5.1 interpreter — no WoW client required — so they can run locally
and in CI.

## Running

From the repo root (or anywhere; paths resolve relative to the runner):

```sh
lua Tests/run_tests.lua
```

Exit code is non-zero if any test fails, so CI can gate on it.

On Windows with the bundled interpreter:

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" Tests\run_tests.lua
```

## How it works

Addon modules use the `local FOLDER_NAME, private = ...` vararg bootstrap that
the WoW client provides. The harness reproduces that:

- **`harness.lua`** — `loadModule(relpath, private)` loads a module chunk and
  invokes it with `("Chronicles", private)`, exactly as the client would. Each
  spec supplies its own `private` table pre-populated with stubbed dependencies.
- **`wow_stubs.lua`** — minimal stubs for the WoW globals some modules touch at
  load time (e.g. `CreateFrame` for StringUtils' measurement frame). Only what
  the tested modules reference is stubbed — this is not a full WoW API.
- **`framework.lua`** — a tiny describe/it framework with a handful of
  assertions and a reporter that sets the exit code.
- **`run_tests.lua`** — wires the above together and runs every spec in
  `specs/` in a deterministic order.

## Coverage

- `MathUtils`, `TableUtils`, `StringUtils` — main paths plus nil/empty edges.
- `TimelineBusiness` — the timeline math: `calculateTimelineConfig` (including
  the boundary constants `historyStartYear`, `mythos`, `futur`),
  `consolidateTimelinePeriods`, `getStepValueIndex`, and
  `calculateTimelinePagination`.

## Adding a spec

1. Create `Tests/specs/MyModule_spec.lua`.
2. Pull the globals the runner injects: `local T, H = _G.T, _G.H`.
3. Build a `private` with `H.newPrivate()`, stub any dependencies, then
   `H.loadModule("Core/.../MyModule.lua", private)`.
4. Register the file name in the `specs` list in `run_tests.lua`.
