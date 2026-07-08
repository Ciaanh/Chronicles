--[[
    Minimal stubs for the WoW client globals that some addon modules touch at
    load time or in the code paths under test. Only what the tested modules
    actually reference is stubbed — this is intentionally not a full WoW API.

    dofile this before loading any addon module that needs the client API
    (e.g. StringUtils creates a measurement frame at load time).
]]

local function makeFontString()
    local fs = {}
    function fs:SetPoint() end
    function fs:SetText(text)
        self._text = text
    end
    function fs:GetStringWidth()
        -- Rough proxy: ~6px per character. Enough for width-based branching.
        return self._text and (#self._text * 6) or 0
    end
    return fs
end

local function makeFrame()
    local frame = {}
    function frame:Hide() end
    function frame:Show() end
    function frame:SetPoint() end
    function frame:SetScript() end
    function frame:CreateFontString()
        return makeFontString()
    end
    return frame
end

_G.CreateFrame = function()
    return makeFrame()
end

_G.UIParent = makeFrame()

_G.GameTooltip = {
    SetOwner = function() end,
    SetText = function() end,
    Hide = function() end
}

-- WoW's global string split helper (returns multiple values). A minimal
-- single-separator implementation is enough for the tested code paths.
_G.strsplit = function(sep, str)
    local parts = {}
    local pattern = "([^" .. sep .. "]*)"
    for part in string.gmatch(str, pattern) do
        table.insert(parts, part)
    end
    return unpack(parts)
end

-- Fail-fast error surfacing routes through geterrorhandler(). Under test,
-- return a handler that re-raises so a swallowed error would fail the test
-- loudly rather than pass silently.
_G.geterrorhandler = function()
    return function(err)
        error("geterrorhandler received: " .. tostring(err), 0)
    end
end

-- Some modules reference C_Timer.After; make it a no-op scheduler.
_G.C_Timer = {
    After = function(_, callback)
        if type(callback) == "function" then
            callback()
        end
    end
}
