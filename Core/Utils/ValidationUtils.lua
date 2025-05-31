local FOLDER_NAME, private = ...

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.ValidationUtils = {}

local ValidationUtils = private.Core.Utils.ValidationUtils

--[[
    Check if a value is nil or empty
    @param value [any] Value to check
    @return [boolean] True if value is nil or empty
]]
function ValidationUtils.IsNilOrEmpty(value)
    if value == nil then
        return true
    end

    if type(value) == "string" then
        return value == ""
    end

    if type(value) == "table" then
        return next(value) == nil
    end

    return false
end

--[[
    Check if a value is a valid number
    @param value [any] Value to check
    @return [boolean] True if value is a valid number
]]
function ValidationUtils.IsValidNumber(value)
    return type(value) == "number" and not (value ~= value) -- NaN check
end

--[[
    Check if a value is a valid string
    @param value [any] Value to check
    @return [boolean] True if value is a valid non-empty string
]]
function ValidationUtils.IsValidString(value)
    return type(value) == "string" and value ~= ""
end

--[[
    Check if a value is a valid table
    @param value [any] Value to check
    @return [boolean] True if value is a valid non-empty table
]]
function ValidationUtils.IsValidTable(value)
    return type(value) == "table" and next(value) ~= nil
end

--[[
    Check if a year is within a valid range
    @param year [number] Year to validate
    @return [boolean] True if year is valid
]]
function ValidationUtils.IsValidYear(year)
    if not ValidationUtils.IsValidNumber(year) then
        return false
    end

    -- Assuming WoW timeline spans from ancient times to future
    return year >= -25000 and year <= 100
end

--[[
    Check if an event object has all required fields
    @param event [table] Event object to validate
    @return [boolean] True if event is valid
]]
function ValidationUtils.IsValidEvent(event)
    if not ValidationUtils.IsValidTable(event) then
        return false
    end

    -- Check required fields
    if not ValidationUtils.IsValidNumber(event.id) then
        return false
    end

    if not ValidationUtils.IsValidString(event.label) then
        return false
    end

    if not ValidationUtils.IsValidYear(event.yearStart) then
        return false
    end

    if not ValidationUtils.IsValidYear(event.yearEnd) then
        return false
    end

    if event.yearStart > event.yearEnd then
        return false
    end

    return true
end

--[[
    Check if a character object has all required fields
    @param character [table] Character object to validate
    @return [boolean] True if character is valid
]]
function ValidationUtils.IsValidCharacter(character)
    if not ValidationUtils.IsValidTable(character) then
        return false
    end

    -- Check required fields
    if not ValidationUtils.IsValidNumber(character.id) then
        return false
    end

    if not ValidationUtils.IsValidString(character.name) then
        return false
    end

    return true
end

--[[
    Check if a faction object has all required fields
    @param faction [table] Faction object to validate
    @return [boolean] True if faction is valid
]]
function ValidationUtils.IsValidFaction(faction)
    if not ValidationUtils.IsValidTable(faction) then
        return false
    end

    -- Check required fields
    if not ValidationUtils.IsValidNumber(faction.id) then
        return false
    end

    if not ValidationUtils.IsValidString(faction.name) then
        return false
    end

    return true
end

--[[
    Validate a timeline period
    @param period [table] Period object to validate
    @return [boolean] True if period is valid
]]
function ValidationUtils.IsValidPeriod(period)
    if not ValidationUtils.IsValidTable(period) then
        return false
    end

    if not ValidationUtils.IsValidNumber(period.id) then
        return false
    end

    if not ValidationUtils.IsValidYear(period.yearStart) then
        return false
    end

    if not ValidationUtils.IsValidYear(period.yearEnd) then
        return false
    end

    if period.yearStart > period.yearEnd then
        return false
    end

    return true
end

-- Export ValidationUtils globally for access by business modules
_G.ValidationUtils = ValidationUtils
