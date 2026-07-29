local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: UIUtils
Purpose: Common UI utility functions for Chronicles addon
Author: Chronicles Team
=================================================================================

This module provides utilities for common UI operations:
- Simplifying repetitive null-checking patterns
- Centralizing block management for UI components
- Providing safe element manipulation functions
- Standardizing UI behavior patterns

Key Functions:
- WipeBlocks: Clear properties from multiple UI blocks efficiently
- SafeHide/SafeShow: Safely manipulate UI element visibility
- GetStandardBlocks: Retrieve common UI block collections

Usage:
    local UIUtils = private.Core.Utils.UIUtils
    UIUtils.WipeBlocks(blockArray, "character")
    UIUtils.SafeHideElements({block1, block2, block3})
=================================================================================
]]
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.UIUtils = {}

local UIUtils = private.Core.Utils.UIUtils

--[[
    Wipe a specific property from multiple UI blocks
    @param blocks [table] Array of UI blocks to process
    @param property [string] Property name to clear (default: "data")
]]
function UIUtils.WipeBlocks(blocks, property)
    if not blocks or type(blocks) ~= "table" then
        return
    end

    property = property or "data"

    for _, block in ipairs(blocks) do
        if block and block[property] ~= nil then
            block[property] = nil
        end
    end
end

--[[
    Safely hide UI elements
    @param elements [table] Array of UI elements to hide
]]
function UIUtils.SafeHideElements(elements)
    if not elements or type(elements) ~= "table" then
        return
    end

    for _, element in ipairs(elements) do
        if element and element.Hide then
            element:Hide()
        end
    end
end

--[[
    Safely show UI elements
    @param elements [table] Array of UI elements to show
]]
function UIUtils.SafeShowElements(elements)
    if not elements or type(elements) ~= "table" then
        return
    end

    for _, element in ipairs(elements) do
        if element and element.Show then
            element:Show()
        end
    end
end

--[[
    Check if all elements in an array exist and are valid frames
    @param elements [table] Array of elements to check
    @return [boolean] True if all elements are valid frames
]]
function UIUtils.AreValidFrames(elements)
    if not elements or type(elements) ~= "table" then
        return false
    end

    for _, element in ipairs(elements) do
        if not element or type(element) ~= "table" then
            return false
        end
    end

    return true
end

--[[
    Clear multiple properties from a single object
    @param object [table] Object to clear properties from
    @param properties [table] Array of property names to clear
]]
function UIUtils.ClearProperties(object, properties)
    if not object or type(object) ~= "table" or not properties or type(properties) ~= "table" then
        return
    end

    for _, property in ipairs(properties) do
        if object[property] ~= nil then
            object[property] = nil
        end
    end
end

--[[
    Clear all points and set a new point for a UI element
    @param element [Frame] The UI element to reposition
    @param point [string] Anchor point (e.g., "LEFT", "RIGHT", "TOP")
    @param relativeTo [Frame] Frame to position relative to (nil for parent)
    @param relativePoint [string] Relative anchor point (nil to use same as point)
    @param xOffset [number] X offset (default: 0)
    @param yOffset [number] Y offset (default: 0)
]]
function UIUtils.ClearAndPosition(element, point, relativeTo, relativePoint, xOffset, yOffset)
    if not element or not element.ClearAllPoints or not element.SetPoint then
        return
    end

    element:ClearAllPoints()
    element:SetPoint(point, relativeTo, relativePoint, xOffset or 0, yOffset or 0)
end

--[[
    Batch positioning operation for multiple elements
    @param operations [table] Array of positioning operations, each containing:
        {element, point, relativeTo, relativePoint, xOffset, yOffset}
]]
function UIUtils.BatchPosition(operations)
    if not operations or type(operations) ~= "table" then
        return
    end

    for _, op in ipairs(operations) do
        if op and type(op) == "table" and #op >= 2 then
            UIUtils.ClearAndPosition(op[1], op[2], op[3], op[4], op[5], op[6])
        end
    end
end

--[[
    Configure texture coordinates for multiple elements
    @param elements [table] Array of {element, left, right, top, bottom} entries
]]
function UIUtils.SetTextureCoords(elements)
    if not elements or type(elements) ~= "table" then
        return
    end

    for _, entry in ipairs(elements) do
        if entry and type(entry) == "table" and #entry >= 5 then
            local element = entry[1]
            if element and element.SetTexCoord then
                element:SetTexCoord(entry[2], entry[3], entry[4], entry[5])
            end
        end
    end
end

--[[
    Position elements in a vertical list pattern
    @param container [Frame] Parent container for the elements
    @param elements [table] Array of elements to position
    @param spacing [number] Vertical spacing between elements (default: -5)
    @param initialYOffset [number] Initial Y offset from container top (default: -15)
]]
function UIUtils.PositionVerticalList(container, elements, spacing, initialYOffset)
    if not container or not elements or type(elements) ~= "table" then
        return
    end

    spacing = spacing or -5
    initialYOffset = initialYOffset or -15

    local previousElement = nil

    for _, element in ipairs(elements) do
        if element then
            if previousElement then
                element:SetPoint("TOP", previousElement, "BOTTOM", 0, spacing)
            else
                element:SetPoint("TOPLEFT", container, "TOPLEFT", 0, initialYOffset)
            end
            previousElement = element
        end
    end
end

--[[
    Clean up an array of UI elements by hiding them and clearing their parent
    @param elementArray [table] Array of UI elements to clean up
    @param clearArray [boolean] Whether to clear the array after cleanup (default: true)
]]
function UIUtils.CleanupElementArray(elementArray, clearArray)
    if not elementArray or type(elementArray) ~= "table" then
        return
    end

    for i = #elementArray, 1, -1 do
        if elementArray[i] then
            if elementArray[i].Hide then
                elementArray[i]:Hide()
            end
            if elementArray[i].SetParent then
                elementArray[i]:SetParent(nil)
            end
        end
    end

    if clearArray ~= false then -- Default to true
        for k in pairs(elementArray) do
            elementArray[k] = nil
        end
    end
end

--[[
    Fetch the pool entry for an index, creating it on first use

    Passing nil as the frame name is deliberate and load-bearing: a named CreateFrame publishes the
    frame as a global, which is exactly what pooling here is meant to stop. Callers own layout —
    this only guarantees a shown frame of the right type exists at that index.

    @param pool [table] Array-like store of frames, keyed by index; created by the caller
    @param template [string] Virtual template name to inherit
    @param parent [Frame] Parent for newly created frames
    @param index [number] Position in the pool
    @param frameType [string] Intrinsic type to create (default: "Frame")
    @return [Frame] The pooled frame, shown
]]
function UIUtils.AcquirePooledFrame(pool, template, parent, index, frameType)
    if type(pool) ~= "table" or not template or not parent or not index then
        return nil
    end

    if not pool[index] then
        pool[index] = CreateFrame(frameType or "Frame", nil, parent, template)
    end

    pool[index]:Show()

    return pool[index]
end

--[[
    Hide every pool entry past a count, keeping the frames for reuse

    @param pool [table] Array-like store of frames
    @param count [number] Number of entries to keep visible
]]
function UIUtils.ReleaseFramesAbove(pool, count)
    if type(pool) ~= "table" then
        return
    end

    for index = (count or 0) + 1, #pool do
        if pool[index] then
            pool[index]:Hide()
        end
    end
end

-- REMOVED: Global export for UIUtils
-- This module is now accessed via: private.Core.Utils.UIUtils.*
-- External plugins should update to use the module pattern instead of globals
