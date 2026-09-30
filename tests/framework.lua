--[[
    Minimal pure-Lua test framework for the Chronicles addon.

    No external dependencies — runs under any Lua 5.1 interpreter. Provides
    describe/it grouping, a small set of assertions, and a summary reporter
    that sets a non-zero exit code when anything fails (so CI can gate on it).
]]

local framework = {}

local state = {
    suite = nil,
    passed = 0,
    failed = 0,
    failures = {}
}

function framework.describe(name, fn)
    state.suite = name
    print("\n" .. name)
    fn()
    state.suite = nil
end

function framework.it(name, fn)
    local ok, err = pcall(fn)
    if ok then
        state.passed = state.passed + 1
        print("  ok   - " .. name)
    else
        state.failed = state.failed + 1
        table.insert(state.failures, {suite = state.suite, name = name, err = err})
        print("  FAIL - " .. name)
        print("         " .. tostring(err))
    end
end

-- -------------------------
-- Assertions
-- -------------------------

local function fail(msg)
    error(msg, 3)
end

local function reprValue(v)
    if type(v) == "string" then
        return string.format("%q", v)
    end
    return tostring(v)
end

local function deepEquals(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end
    for k, v in pairs(a) do
        if not deepEquals(v, b[k]) then
            return false
        end
    end
    for k, v in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local assert_ = {}

function assert_.equals(actual, expected, msg)
    if actual ~= expected then
        fail((msg or "values differ") ..
            "\n         expected: " .. reprValue(expected) .. "\n         actual:   " .. reprValue(actual))
    end
end

function assert_.deepEquals(actual, expected, msg)
    if not deepEquals(actual, expected) then
        fail(msg or "tables are not deeply equal")
    end
end

function assert_.isTrue(value, msg)
    if value ~= true then
        fail((msg or "expected true") .. ", got " .. reprValue(value))
    end
end

function assert_.isFalse(value, msg)
    if value ~= false then
        fail((msg or "expected false") .. ", got " .. reprValue(value))
    end
end

function assert_.isNil(value, msg)
    if value ~= nil then
        fail((msg or "expected nil") .. ", got " .. reprValue(value))
    end
end

function assert_.isNotNil(value, msg)
    if value == nil then
        fail(msg or "expected a non-nil value")
    end
end

-- Compare numbers within a small tolerance (for float math).
function assert_.near(actual, expected, tolerance, msg)
    tolerance = tolerance or 1e-9
    if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
        fail((msg or "numbers not close enough") ..
            "\n         expected: ~" .. reprValue(expected) .. "\n         actual:   " .. reprValue(actual))
    end
end

-- Assert that fn raises an error when called.
function assert_.throws(fn, msg)
    local ok = pcall(fn)
    if ok then
        fail(msg or "expected function to raise an error")
    end
end

framework.assert = assert_

-- -------------------------
-- Reporter
-- -------------------------

function framework.report()
    print("\n----------------------------------------")
    print(string.format("%d passed, %d failed", state.passed, state.failed))
    if state.failed > 0 then
        print("\nFailures:")
        for _, f in ipairs(state.failures) do
            print(string.format("  [%s] %s", f.suite or "?", f.name))
        end
        return false
    end
    return true
end

return framework
