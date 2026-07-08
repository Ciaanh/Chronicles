local T = _G.T
local H = _G.H
local assert_ = T.assert

-- StringUtils creates a measurement frame at load time, so the WoW stubs
-- (already dofile'd by the runner) must be in place before loading it.
local private = H.newPrivate()
H.loadModule("Core/Utils/StringUtils.lua", private)
local StringUtils = private.Core.Utils.StringUtils

T.describe("StringUtils", function()
    T.it("loads into private.Core.Utils.StringUtils", function()
        assert_.isNotNil(StringUtils)
    end)

    T.it("Trim strips leading and trailing whitespace", function()
        assert_.equals(StringUtils.Trim("  hello  "), "hello")
        assert_.equals(StringUtils.Trim("hello"), "hello")
        assert_.equals(StringUtils.Trim("   "), "")
        assert_.equals(StringUtils.Trim(""), "")
    end)

    T.it("CleanHTML collapses escaped pipes and backslashes", function()
        assert_.equals(StringUtils.CleanHTML("a||b"), "a|b")
        assert_.equals(StringUtils.CleanHTML("a\\\\b"), "a\\b")
    end)

    T.it("CleanHTML returns empty string for nil", function()
        assert_.equals(StringUtils.CleanHTML(nil), "")
    end)

    T.it("ContainsHTML detects the <html> marker case-insensitively", function()
        assert_.isTrue(StringUtils.ContainsHTML("<html>content</html>"))
        assert_.isTrue(StringUtils.ContainsHTML("<HTML>content"))
        assert_.isFalse(StringUtils.ContainsHTML("plain text"))
    end)
end)
