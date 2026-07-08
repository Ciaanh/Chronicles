--[[
    Module loader that reproduces the addon's `local FOLDER_NAME, private = ...`
    vararg bootstrap outside the WoW client.

    Addon Lua files are loaded as chunks and invoked with ("Chronicles", private),
    exactly as the client would. Each test supplies its own `private` table
    pre-populated with whatever stubbed dependencies the module needs.
]]

local harness = {}

-- Repo root is the parent of the Tests/ directory that holds this file.
local scriptDir = (arg and arg[0] and arg[0]:match("^(.*[/\\])")) or "./"
harness.repoRoot = scriptDir .. ".." .. package.config:sub(1, 1)

local FOLDER_NAME = "Chronicles"

--[[
    Load an addon module by its repo-relative path (forward slashes).
    @param relpath [string] e.g. "Core/Utils/MathUtils.lua"
    @param private [table] the shared addon `private` table (mutated in place)
    @return the module's return value (if any), and the private table
]]
function harness.loadModule(relpath, private)
    local path = harness.repoRoot .. relpath
    local chunk, err = loadfile(path)
    if not chunk then
        error("Failed to load module '" .. path .. "': " .. tostring(err))
    end
    local ret = chunk(FOLDER_NAME, private)
    return ret, private
end

--[[
    Build a fresh `private` table with the minimal skeleton every module
    expects (Core / Core.Utils / constants). Tests extend it as needed.
]]
function harness.newPrivate()
    return {
        addon_name = FOLDER_NAME,
        Core = {
            Utils = {}
        },
        constants = {}
    }
end

return harness
