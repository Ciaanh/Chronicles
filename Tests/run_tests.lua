--[[
    Test runner for the Chronicles addon test suite.

    Usage (from anywhere; paths resolve relative to this script):
        lua Tests/run_tests.lua

    Loads the framework and WoW stubs, then executes every spec under
    Tests/specs/. Exits non-zero if any test fails so CI can gate on it.
]]

local scriptDir = (arg and arg[0] and arg[0]:match("^(.*[/\\])")) or "./"
local sep = package.config:sub(1, 1)

-- Make Tests/ requireable and expose framework + harness to specs as globals.
local framework = dofile(scriptDir .. "framework.lua")
local harness = dofile(scriptDir .. "harness.lua")
dofile(scriptDir .. "wow_stubs.lua")

_G.T = framework
_G.H = harness

-- Specs are listed explicitly so the run order is deterministic and a missing
-- file is an obvious error rather than a silently skipped test.
local specs = {
    "MathUtils_spec.lua",
    "TableUtils_spec.lua",
    "StringUtils_spec.lua",
    "TimelineBusiness_spec.lua",
    "StateManager_spec.lua",
    "EventManager_spec.lua"
}

for _, spec in ipairs(specs) do
    dofile(scriptDir .. "specs" .. sep .. spec)
end

local ok = framework.report()
os.exit(ok and 0 or 1)
