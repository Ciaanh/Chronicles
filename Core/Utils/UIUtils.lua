local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: UIUtils
Purpose: Common UI utility functions for Chronicles addon
Author: Chronicles Team
=================================================================================

This module provides utilities for common UI operations:
- Frame pooling for list-style templates
- Teardown of element arrays

Key Functions:
- AcquirePooledFrame: Fetch (creating on first use) a pooled frame by index
- ReleaseFramesAbove: Hide pool entries past a count, keeping them for reuse
- CleanupElementArray: Hide, unparent and optionally wipe an array of elements

Usage:
    local UIUtils = private.Core.Utils.UIUtils
    local row = UIUtils.AcquirePooledFrame(self.rowPool, "RowTemplate", self, index, "Button")
    UIUtils.ReleaseFramesAbove(self.rowPool, rowCount)
=================================================================================
]]
private.Core.Utils = private.Core.Utils or {}
private.Core.Utils.UIUtils = {}

local UIUtils = private.Core.Utils.UIUtils

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
