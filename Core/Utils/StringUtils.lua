local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: StringUtils
Purpose: String manipulation and text processing utilities
Dependencies: None (core utility module)
Author: Chronicles Team
=================================================================================

This module provides string utilities including:
- HTML content detection

Usage Example:
    if StringUtils.ContainsHTML(page) then ... end
=================================================================================
]]

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.StringUtils = {}

local StringUtils = private.Core.Utils.StringUtils

--[[
    Check if text contains HTML markup
    @param text [any] Value to check; non-strings are reported as non-HTML rather than raising,
                      because page content can come from plugin-supplied data
    @return [boolean] True if text contains HTML
]]
function StringUtils.ContainsHTML(text)
    return type(text) == "string" and string.lower(text):find("<html>") ~= nil
end
