# Chronicles test suite

Standalone unit tests for the addon's pure-logic modules. They run under a
plain Lua 5.1 interpreter — no WoW client required — so they can run locally
and in CI. LuaJIT 2.1 implements the same 5.1 language and runs the suite
unchanged.

## Running

From the repo root (or anywhere; paths resolve relative to the runner):

```sh
lua Tests/run_tests.lua
```

Exit code is non-zero if any test fails, so CI can gate on it.

On Windows with LuaJIT:

```powershell
& "$env:LOCALAPPDATA\Programs\LuaJIT\bin\luajit.exe" Tests\run_tests.lua
```

## How it works

Addon modules use the `local FOLDER_NAME, private = ...` vararg bootstrap that
the WoW client provides. The harness reproduces that:

- **`harness.lua`** — `loadModule(relpath, private)` loads a module chunk and
  invokes it with `("Chronicles", private)`, exactly as the client would. Each
  spec supplies its own `private` table pre-populated with stubbed dependencies.
- **`wow_stubs.lua`** — minimal stubs for the WoW globals some modules touch at
  load time or in a tested code path (`CreateFrame`, `strsplit`, `C_Timer`,
  `geterrorhandler`). Only what the tested modules reference is stubbed — this
  is not a full WoW API.
- **`framework.lua`** — a tiny describe/it framework with a handful of
  assertions and a reporter that sets the exit code.
- **`run_tests.lua`** — wires the above together and runs every spec in
  `specs/` in a deterministic order.

## Coverage

Six specs, run in the order listed in `run_tests.lua`:

- `TableUtils` — `Set`, `Length`, `DeepCopy`, `Merge`, `Filter`: main paths plus
  nil/empty edges and copy-vs-alias guarantees.
- `StringUtils` — `ContainsHTML` marker detection, including partial tags.
- `ValidationUtils` — the type predicates, `ValidateTable`'s two `allowEmpty`
  spellings, `IsValidYear` against both the fallback bounds and injected
  `mythos`/`futur` constants, and the event / character / faction / period
  entity validators with one field invalidated at a time.
- `TimelineBusiness` — the timeline math: `calculateTimelineConfig` (including
  the boundary constants `historyStartYear`, `mythos`, `futur`),
  `consolidateTimelinePeriods`, `getStepValueIndex`, and
  `calculateTimelinePagination`.
- `StateManager` — `rehydrate`: subscriber re-emission, unknown and invalid
  keys, and the no-re-persist guarantee.
- `EventManager` — `Validator` required-field enforcement, including dynamic
  indexed timeline label events.

## Adding a spec

1. Create `Tests/specs/MyModule_spec.lua`.
2. Pull the globals the runner injects: `local T, H = _G.T, _G.H`.
3. Build a `private` with `H.newPrivate()`, stub any dependencies, then
   `H.loadModule("Core/.../MyModule.lua", private)`.
4. Register the file name in the `specs` list in `run_tests.lua`.
