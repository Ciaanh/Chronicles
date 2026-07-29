local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: Spacing
Purpose: Single spacing scale for UI anchor offsets
Author: Chronicles Team
=================================================================================

Every new or touched anchor offset comes from this scale: a token value, its
negative, or a sum of two tokens (prefer a single step).

The scale does NOT cover widths and heights - those are sizes, not offsets. Nor
does it cover offsets that centre or inset one of the art assets (bookmark
textures 45x64 / 105x64, timeline label 130x25, period 130x75); express those as
arithmetic on the texture size instead.

Usage:
    local Spacing = private.Core.Utils.Spacing
    element:SetPoint("TOPLEFT", container, "TOPLEFT", Spacing.md, -Spacing.md)
=================================================================================
]]
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.Spacing = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24,
    xxl = 40
}
