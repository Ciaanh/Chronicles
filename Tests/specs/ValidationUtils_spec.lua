local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/ValidationUtils.lua", private)
local ValidationUtils = private.Core.Utils.ValidationUtils

-- A minimal event/character/faction that passes validation, so each test can
-- invalidate exactly one field and attribute the failure to it.
local function validEvent()
    return {id = 1, label = "The Great Wars", yearStart = 0, yearEnd = 25}
end

T.describe("ValidationUtils basic types", function()
    T.it("loads into private.Core.Utils.ValidationUtils", function()
        assert_.isNotNil(ValidationUtils)
    end)

    T.it("IsValidNumber accepts numbers and rejects other types", function()
        assert_.isTrue(ValidationUtils.IsValidNumber(0))
        assert_.isTrue(ValidationUtils.IsValidNumber(-1.5))
        assert_.isFalse(ValidationUtils.IsValidNumber("5"))
        assert_.isFalse(ValidationUtils.IsValidNumber(nil))
        assert_.isFalse(ValidationUtils.IsValidNumber({}))
    end)

    T.it("IsValidNumber rejects NaN", function()
        assert_.isFalse(ValidationUtils.IsValidNumber(0 / 0))
    end)

    T.it("IsValidString requires a non-empty string", function()
        assert_.isTrue(ValidationUtils.IsValidString("a"))
        assert_.isFalse(ValidationUtils.IsValidString(""))
        assert_.isFalse(ValidationUtils.IsValidString(nil))
        assert_.isFalse(ValidationUtils.IsValidString(5))
    end)

    T.it("IsValidTable requires a non-empty table", function()
        assert_.isTrue(ValidationUtils.IsValidTable({1}))
        assert_.isTrue(ValidationUtils.IsValidTable({key = "value"}))
        assert_.isFalse(ValidationUtils.IsValidTable({}))
        assert_.isFalse(ValidationUtils.IsValidTable(nil))
        assert_.isFalse(ValidationUtils.IsValidTable("not a table"))
    end)

    T.it("ValidateTable admits empty tables only when allowEmpty is set", function()
        assert_.isTrue(ValidationUtils.ValidateTable({}, true))
        assert_.isFalse(ValidationUtils.ValidateTable({}, false))
        assert_.isFalse(ValidationUtils.ValidateTable({}, nil))
    end)

    T.it("ValidateTable accepts allowEmpty as an options table", function()
        assert_.isTrue(ValidationUtils.ValidateTable({}, {allowEmpty = true}))
        assert_.isFalse(ValidationUtils.ValidateTable({}, {allowEmpty = false}))
        assert_.isFalse(ValidationUtils.ValidateTable({}, {}))
    end)

    T.it("ValidateTable rejects non-tables regardless of allowEmpty", function()
        assert_.isFalse(ValidationUtils.ValidateTable(nil, true))
        assert_.isFalse(ValidationUtils.ValidateTable("x", true))
    end)
end)

T.describe("ValidationUtils.IsValidYear", function()
    T.it("accepts years inside the fallback bounds when no constants are loaded", function()
        assert_.isTrue(ValidationUtils.IsValidYear(0))
        assert_.isTrue(ValidationUtils.IsValidYear(-150000))
        assert_.isTrue(ValidationUtils.IsValidYear(999999))
        assert_.isTrue(ValidationUtils.IsValidYear(-999999))
    end)

    T.it("rejects years outside the fallback bounds", function()
        assert_.isFalse(ValidationUtils.IsValidYear(1000000))
        assert_.isFalse(ValidationUtils.IsValidYear(-1000000))
    end)

    T.it("rejects non-numeric years", function()
        assert_.isFalse(ValidationUtils.IsValidYear(nil))
        assert_.isFalse(ValidationUtils.IsValidYear("42"))
    end)

    T.it("honors mythos/futur bounds from constants when they are present", function()
        private.constants.config = {mythos = -10, futur = 10}
        assert_.isTrue(ValidationUtils.IsValidYear(10))
        assert_.isFalse(ValidationUtils.IsValidYear(50))
        assert_.isFalse(ValidationUtils.IsValidYear(-50))
        private.constants.config = nil
    end)
end)

T.describe("ValidationUtils.IsValidEvent", function()
    T.it("accepts an event with all required fields", function()
        assert_.isTrue(ValidationUtils.IsValidEvent(validEvent()))
    end)

    T.it("accepts an instantaneous event where start and end are the same year", function()
        local event = validEvent()
        event.yearStart, event.yearEnd = 25, 25
        assert_.isTrue(ValidationUtils.IsValidEvent(event))
    end)

    T.it("rejects an event whose start year is after its end year", function()
        local event = validEvent()
        event.yearStart, event.yearEnd = 30, 25
        assert_.isFalse(ValidationUtils.IsValidEvent(event))
    end)

    T.it("rejects an event missing a required field", function()
        local missingId = validEvent()
        missingId.id = nil
        assert_.isFalse(ValidationUtils.IsValidEvent(missingId))

        local missingLabel = validEvent()
        missingLabel.label = nil
        assert_.isFalse(ValidationUtils.IsValidEvent(missingLabel))

        local missingYearEnd = validEvent()
        missingYearEnd.yearEnd = nil
        assert_.isFalse(ValidationUtils.IsValidEvent(missingYearEnd))
    end)

    T.it("rejects an event with an empty label", function()
        local event = validEvent()
        event.label = ""
        assert_.isFalse(ValidationUtils.IsValidEvent(event))
    end)

    T.it("rejects nil, an empty table, and non-tables", function()
        assert_.isFalse(ValidationUtils.IsValidEvent(nil))
        assert_.isFalse(ValidationUtils.IsValidEvent({}))
        assert_.isFalse(ValidationUtils.IsValidEvent("event"))
    end)
end)

T.describe("ValidationUtils entity validation", function()
    T.it("IsValidCharacter requires a numeric id and a non-empty name", function()
        assert_.isTrue(ValidationUtils.IsValidCharacter({id = 1, name = "Thrall"}))
        assert_.isFalse(ValidationUtils.IsValidCharacter({id = 1, name = ""}))
        assert_.isFalse(ValidationUtils.IsValidCharacter({name = "Thrall"}))
        assert_.isFalse(ValidationUtils.IsValidCharacter({id = "1", name = "Thrall"}))
    end)

    T.it("IsValidCharacter rejects nil and empty tables", function()
        assert_.isFalse(ValidationUtils.IsValidCharacter(nil))
        assert_.isFalse(ValidationUtils.IsValidCharacter({}))
    end)

    T.it("IsValidFaction requires a numeric id and a non-empty name", function()
        assert_.isTrue(ValidationUtils.IsValidFaction({id = 2, name = "Horde"}))
        assert_.isFalse(ValidationUtils.IsValidFaction({id = 2, name = ""}))
        assert_.isFalse(ValidationUtils.IsValidFaction({name = "Horde"}))
    end)

    T.it("IsValidFaction rejects nil and empty tables", function()
        assert_.isFalse(ValidationUtils.IsValidFaction(nil))
        assert_.isFalse(ValidationUtils.IsValidFaction({}))
    end)

    T.it("entity validators ignore extra fields", function()
        assert_.isTrue(ValidationUtils.IsValidFaction({id = 2, name = "Horde", unexpected = true}))
    end)
end)

T.describe("ValidationUtils.IsValidPeriod", function()
    T.it("accepts the lower/upper period shape", function()
        assert_.isTrue(ValidationUtils.IsValidPeriod({lower = 0, upper = 10}))
    end)

    T.it("accepts the legacy yearStart/yearEnd period shape", function()
        assert_.isTrue(ValidationUtils.IsValidPeriod({yearStart = -100, yearEnd = -50}))
    end)

    T.it("accepts a zero bound rather than treating it as absent", function()
        assert_.isTrue(ValidationUtils.IsValidPeriod({lower = 0, upper = 0}))
    end)

    T.it("rejects an inverted period", function()
        assert_.isFalse(ValidationUtils.IsValidPeriod({lower = 10, upper = 0}))
    end)

    T.it("rejects a period missing one bound", function()
        assert_.isFalse(ValidationUtils.IsValidPeriod({lower = 0}))
        assert_.isFalse(ValidationUtils.IsValidPeriod({upper = 10}))
    end)

    T.it("rejects nil, an empty table, and non-numeric bounds", function()
        assert_.isFalse(ValidationUtils.IsValidPeriod(nil))
        assert_.isFalse(ValidationUtils.IsValidPeriod({}))
        assert_.isFalse(ValidationUtils.IsValidPeriod({lower = "0", upper = "10"}))
    end)
end)
