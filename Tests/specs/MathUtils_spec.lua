local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/MathUtils.lua", private)
local MathUtils = private.Core.Utils.MathUtils

T.describe("MathUtils", function()
    T.it("loads into private.Core.Utils.MathUtils", function()
        assert_.isNotNil(MathUtils)
    end)

    T.it("AdjustValue snaps down when below the step midpoint", function()
        -- floor 10, midpoint 10.5, 10.4 < 10.5 -> 10
        assert_.equals(MathUtils.AdjustValue(10.4, 1), 10)
    end)

    T.it("AdjustValue snaps up when at/above the step midpoint", function()
        -- floor 10, midpoint 10.5, 10.6 >= 10.5 -> 11
        assert_.equals(MathUtils.AdjustValue(10.6, 1), 11)
    end)

    T.it("Clamp returns min/value/max across the three branches", function()
        assert_.equals(MathUtils.Clamp(-5, 0, 10), 0)
        assert_.equals(MathUtils.Clamp(5, 0, 10), 5)
        assert_.equals(MathUtils.Clamp(15, 0, 10), 10)
    end)

    T.it("Lerp interpolates at the endpoints and midpoint", function()
        assert_.equals(MathUtils.Lerp(0, 10, 0), 0)
        assert_.equals(MathUtils.Lerp(0, 10, 1), 10)
        assert_.equals(MathUtils.Lerp(0, 10, 0.5), 5)
    end)

    T.it("Round rounds half up, including negatives", function()
        assert_.equals(MathUtils.Round(2.4), 2)
        assert_.equals(MathUtils.Round(2.5), 3)
        assert_.equals(MathUtils.Round(-2.5), -2) -- floor(-2.0)
    end)

    T.it("RoundToDecimals honors the decimal count and defaults to 0", function()
        assert_.near(MathUtils.RoundToDecimals(3.14159, 2), 3.14)
        assert_.equals(MathUtils.RoundToDecimals(3.6), 4)
    end)

    T.it("InRange is inclusive of both bounds", function()
        assert_.isTrue(MathUtils.InRange(0, 0, 10))
        assert_.isTrue(MathUtils.InRange(10, 0, 10))
        assert_.isTrue(MathUtils.InRange(5, 0, 10))
        assert_.isFalse(MathUtils.InRange(-1, 0, 10))
        assert_.isFalse(MathUtils.InRange(11, 0, 10))
    end)
end)
