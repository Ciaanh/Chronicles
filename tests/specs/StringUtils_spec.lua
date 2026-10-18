local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/StringUtils.lua", private)
local StringUtils = private.Core.Utils.StringUtils

T.describe("StringUtils", function()
    T.it("loads into private.Core.Utils.StringUtils", function()
        assert_.isNotNil(StringUtils)
    end)

    T.it("ContainsHTML detects the <html> marker case-insensitively", function()
        assert_.isTrue(StringUtils.ContainsHTML("<html>content</html>"))
        assert_.isTrue(StringUtils.ContainsHTML("<HTML>content"))
        assert_.isFalse(StringUtils.ContainsHTML("plain text"))
    end)

    T.it("ContainsHTML finds the marker anywhere in the text, not just at the start", function()
        assert_.isTrue(StringUtils.ContainsHTML("  leading space <html>body</html>"))
    end)

    T.it("ContainsHTML rejects a partial or unclosed tag", function()
        assert_.isFalse(StringUtils.ContainsHTML("<htm"))
        assert_.isFalse(StringUtils.ContainsHTML("<p>not a document</p>"))
    end)

    T.it("ContainsHTML treats an empty string as plain text", function()
        assert_.isFalse(StringUtils.ContainsHTML(""))
    end)
end)
