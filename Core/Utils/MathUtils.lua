local FOLDER_NAME, private = ...

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.MathUtils = {}

local MathUtils = private.Core.Utils.MathUtils

--[[
    Adjust a value to the nearest step boundary
    @param value [number] Value to adjust
    @param step [number] Step size for adjustment
    @return [number] Adjusted value
]]
function MathUtils.AdjustValue(value, step)
    local valueFloor = math.floor(value)
    local valueMiddle = valueFloor + (step / 2)

    if (value < valueMiddle) then
        return valueFloor
    end
    return valueFloor + step
end

--[[
    Clamp a value between min and max bounds
    @param value [number] Value to clamp
    @param min [number] Minimum allowed value
    @param max [number] Maximum allowed value
    @return [number] Clamped value
]]
function MathUtils.Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

--[[
    Linear interpolation between two values
    @param a [number] Start value
    @param b [number] End value
    @param t [number] Interpolation factor (0-1)
    @return [number] Interpolated value
]]
function MathUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

--[[
    Round a number to the nearest integer
    @param num [number] Number to round
    @return [number] Rounded number
]]
function MathUtils.Round(num)
    return math.floor(num + 0.5)
end

--[[
    Round a number to a specific number of decimal places
    @param num [number] Number to round
    @param decimals [number] Number of decimal places
    @return [number] Rounded number
]]
function MathUtils.RoundToDecimals(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

--[[
    Check if a number is within a range (inclusive)
    @param value [number] Value to check
    @param min [number] Minimum bound
    @param max [number] Maximum bound
    @return [boolean] True if value is within range
]]
function MathUtils.InRange(value, min, max)
    return value >= min and value <= max
end

-- Export utility functions globally for backwards compatibility
_G.adjust_value = MathUtils.AdjustValue
_G.MathUtils = MathUtils
