local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/TableUtils.lua", private)
local TableUtils = private.Core.Utils.TableUtils

T.describe("TableUtils", function()
    T.it("Set converts an array into a value-keyed set", function()
        assert_.deepEquals(TableUtils.Set({"a", "b"}), {a = true, b = true})
    end)

    T.it("Length counts array and hash entries, and treats nil as 0", function()
        assert_.equals(TableUtils.Length(nil), 0)
        assert_.equals(TableUtils.Length({}), 0)
        assert_.equals(TableUtils.Length({1, 2, 3}), 3)
        assert_.equals(TableUtils.Length({x = 1, y = 2}), 2)
    end)

    T.it("DeepCopy copies nested tables without aliasing", function()
        local original = {a = 1, nested = {b = 2}}
        local copy = TableUtils.DeepCopy(original)
        assert_.deepEquals(copy, original)
        copy.nested.b = 99
        assert_.equals(original.nested.b, 2, "mutating the copy must not affect the original")
    end)

    T.it("DeepCopy returns an empty table for nil input", function()
        assert_.deepEquals(TableUtils.DeepCopy(nil), {})
    end)

    T.it("Contains finds present values and rejects absent ones", function()
        assert_.isTrue(TableUtils.Contains({1, 2, 3}, 2))
        assert_.isFalse(TableUtils.Contains({1, 2, 3}, 9))
        assert_.isFalse(TableUtils.Contains(nil, 1))
    end)

    T.it("Merge deep-merges with the second table taking precedence", function()
        local a = {x = 1, nested = {p = 1, q = 1}}
        local b = {y = 2, nested = {q = 9}}
        assert_.deepEquals(TableUtils.Merge(a, b), {x = 1, y = 2, nested = {p = 1, q = 9}})
    end)

    T.it("Merge with a nil second table returns a copy of the first", function()
        local a = {x = 1}
        local result = TableUtils.Merge(a, nil)
        assert_.deepEquals(result, {x = 1})
        result.x = 2
        assert_.equals(a.x, 1, "result must be a copy, not the same reference")
    end)

    T.it("Filter keeps matching values as a contiguous array", function()
        local result = TableUtils.Filter({1, 2, 3, 4}, function(v)
            return v % 2 == 0
        end)
        assert_.deepEquals(result, {2, 4})
    end)

    T.it("Filter returns empty for nil inputs", function()
        assert_.deepEquals(TableUtils.Filter(nil, function() return true end), {})
        assert_.deepEquals(TableUtils.Filter({1}, nil), {})
    end)

    T.it("Map transforms each value keeping keys", function()
        assert_.deepEquals(
            TableUtils.Map({a = 1, b = 2}, function(v) return v * 10 end),
            {a = 10, b = 20}
        )
    end)

    T.it("Map returns empty for nil inputs", function()
        assert_.deepEquals(TableUtils.Map(nil, function(v) return v end), {})
        assert_.deepEquals(TableUtils.Map({1}, nil), {})
    end)
end)
