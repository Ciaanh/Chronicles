local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: StringUtils
Purpose: String manipulation and text processing utilities
Dependencies: WoW UI API for text measurement
Author: Chronicles Team
=================================================================================

This module provides string utilities including:
- Text trimming and cleaning
- HTML content detection and removal
- Text width measurement and wrapping
- Tooltip text adjustment for UI display

Key Features:
- Smart text wrapping based on UI frame width
- HTML tag removal for plain text display
- Text length adjustment with ellipsis
- Tooltip integration for truncated text

Usage Example:
    local trimmed = StringUtils.Trim("  text  ")
    local lines = StringUtils.SplitTextToFitWidth(text, 300)
    local clean = StringUtils.CleanHTML(htmlContent)

Global Exports (Backwards Compatibility):
This module intentionally exports functions to global namespace for backwards
compatibility with existing code and external integrations. This pattern allows
both modern module-style access and legacy global function calls.

Dependencies:
- WoW UI API for CreateFrame and FontString measurement
=================================================================================
]]

private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.StringUtils = {}

local StringUtils = private.Core.Utils.StringUtils

-- Create a hidden frame for measuring text width
local measureFrame = CreateFrame("Frame", nil, UIParent)
measureFrame:Hide()
local measureText = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
measureText:SetPoint("LEFT")

--[[
    Trim whitespace from the beginning and end of a string
    @param s [string] String to trim
    @return [string] Trimmed string
]]
function StringUtils.Trim(s)
    return s:match("^%s*(.-)%s*$")
end

--[[
    Split text into lines that fit within a given frame width
    @param textToSplit [string] Text to split
    @param width [number] Maximum width for each line
    @return [table] Array of lines that fit within the width
]]
function StringUtils.SplitTextToFitWidth(textToSplit, width)
    local text = textToSplit:gsub("\n", " \n ")
    text = text:gsub("  ", " ")

    local words = {strsplit(" ", text)}
    local lines = {}
    local line = "<tab>"

    for i, word in ipairs(words) do
        if word == "\n" then
            line = StringUtils.Trim(line):gsub("<tab>", "  ")
            table.insert(lines, line)
            line = "<tab>"
        else
            measureText:SetText(line .. " " .. word)

            if measureText:GetStringWidth() > width then
                line = StringUtils.Trim(line):gsub("<tab>", "  ")
                table.insert(lines, line)
                line = word
            else
                line = line .. " " .. word
            end
        end
        line = StringUtils.Trim(line):gsub("<tab>", "  ")
    end

    table.insert(lines, line)
    return lines
end

--[[
    Clean HTML markup from text
    @param text [string] Text containing HTML
    @return [string] Cleaned text
]]
function StringUtils.CleanHTML(text)
    if (text ~= nil) then
        text = string.gsub(text, "||", "|")
        text = string.gsub(text, "\\\\", "\\")
    else
        text = ""
    end
    return text
end

--[[
    Check if text contains HTML markup
    @param text [string] Text to check
    @return [boolean] True if text contains HTML
]]
function StringUtils.ContainsHTML(text)
    if (string.lower(text):find("<html>") == nil) then
        return false
    else
        return true
    end
end

--[[
    Adjust text length for display and add tooltip if truncated
    @param text [string] Original text
    @param size [number] Maximum length
    @param frame [frame] UI frame for tooltip attachment
    @return [string] Adjusted text
]]
function StringUtils.AdjustTextLength(text, size, frame)
    local adjustedText = text
    if (text:len() > size) then
        adjustedText = text:sub(0, size)

        frame:SetScript(
            "OnEnter",
            function()
                GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT", -5, 30)
                GameTooltip:SetText(text, nil, nil, nil, nil, true)
            end
        )
        frame:SetScript(
            "OnLeave",
            function()
                GameTooltip:Hide()
            end
        )
    else
        frame:SetScript(
            "OnEnter",
            function()
            end
        )
        frame:SetScript(
            "OnLeave",
            function()
            end
        )
    end    return adjustedText
end

-- Module export
return StringUtils
