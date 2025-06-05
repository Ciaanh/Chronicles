local FOLDER_NAME, private = ...

-- Initialize HelperUtils module with proper namespace creation
if not private.Core then
    private.Core = {}
end
if not private.Core.Utils then
    private.Core.Utils = {}
end
private.Core.Utils.HelperUtils = {}

local HelperUtils = private.Core.Utils.HelperUtils

-- -------------------------
-- Chronicles Access Helpers
-- -------------------------

--[[
    Safely access the Chronicles object
    @return [table|nil] Chronicles object if available, nil otherwise
]]
function HelperUtils.getChronicles()
    return private.Chronicles
end

-- -------------------------
-- Module Initialization
-- -------------------------

function HelperUtils.init()
    private.Core.Logger.trace("HelperUtils", "HelperUtils module initialized")
end

-- Auto-initialize when module is loaded
HelperUtils.init()
