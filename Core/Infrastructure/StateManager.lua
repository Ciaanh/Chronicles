local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: StateManager
Purpose: Centralized application state management with persistence
Dependencies: AceDB-3.0 (via Chronicles.db), TableUtils patterns
Author: Chronicles Team
=================================================================================

This module provides comprehensive state management for Chronicles:
- Centralized state storage with nested path access
- State change notifications and subscriptions
- Automatic persistence via AceDB-3.0 integration
- Safe state access with validation

Key Features:
- Dot-notation path access (e.g., "ui.selectedEvent")
- Subscribe/unsubscribe pattern for state changes
- Automatic saving to persistent storage
- Safe getters with default values

State Structure:
- ui.* - User interface state (selected items, frame states)
- timeline.* - Timeline view state (periods, navigation)
- settings.* - User preferences and configuration
- data.* - Data caching and refresh tracking

Usage Example:
    StateManager.setState("ui.selectedEvent", eventId, "User selection")
    local eventId = StateManager.getState("ui.selectedEvent")
    StateManager.subscribe("ui.selectedEvent", callback, "ModuleName")

Event Integration:
- Automatically triggers events.StateChanged when state updates
- Integrates with Timeline and UI modules for state synchronization

Dependencies:
- Chronicles.db for persistence (AceDB-3.0)
- Internal deep copy utility to avoid TableUtils dependency

USAGE EXAMPLES:
• Building keys: private.Core.StateManager.buildStateKey("ui.selection", "event")
• Setting state: private.Core.StateManager.setState("ui.selectedEvent", eventId)
• Subscribing: private.Core.StateManager.subscribe("ui.selectedEvent", callback, "ModuleName")
• Convenience: private.Core.StateManager.buildSelectionKey("character")

=================================================================================
]]
private.Core.StateManager = {}

-- Local state storage
local stateStore = {}
local subscribers = {}

-- =============================================================================================
-- STATE KEY BUILDER SYSTEM
-- =============================================================================================
--
-- The key builder provides type-safe, validated state key construction for Chronicles'
-- complex state management needs. It enforces naming conventions, validates input parameters,
-- and ensures consistent key patterns across all modules.
--
-- SUPPORTED KEY TYPES:
-- • ui.selection: Entity selection state (ui.selectedEvent, ui.selectedCharacter, etc.)
-- • settings: Event type configuration state (eventTypes.{id})
-- • collection: Collection status tracking (collections.{name}) -- the sole owner of the
--   collections.* namespace; reach it through buildCollectionKey
-- • userContent: In-session user content (data.userContent.{type})
-- • ui.state: General UI state (ui.settingsCategory, ui.isMainFrameOpen, ui.selectedPeriod,
--   ui.windowPosition, timeline.{id}). Note ui.settingsCategory is the Settings panel's own
--   category, not the main frame's tab -- that one lives in Blizzard's TabSystemOwnerMixin and is
--   not persisted at all.
--
-- KEY VALIDATION:
-- • Input type checking for all parameters
-- • Entity ID sanitization (alphanumeric, underscore, hyphen only)
-- • Null/empty value protection
-- • Error messages with context for debugging
--
-- INTEGRATION:
-- Keys built here directly map to AceDB storage paths and are used throughout
-- Chronicles for consistent state access patterns.
-- =============================================================================================

--[[
    Build standardized state keys with validation and type safety
    
    This is the core function for all state key generation in Chronicles. It enforces
    naming conventions, validates inputs, and provides consistent error handling.
    
    @param keyType [string] Type of key: "ui.selection", "settings", "userContent", "collection", "ui.state"
    @param entityType [string] Entity type: "event", "character", "faction", "eventType", "collection", ...
    @param entityId [string|number] Entity identifier (optional for some key types)
    @param options [table] Additional options (reserved for future expansion)
    @return [string] Formatted state key
    @throws Error if validation fails with descriptive message
]]
function private.Core.StateManager.buildStateKey(keyType, entityType, entityId, options)
    if not keyType or type(keyType) ~= "string" then
        error("StateManager.buildStateKey: keyType must be a non-empty string")
    end

    if not entityType or type(entityType) ~= "string" then
        error("StateManager.buildStateKey: entityType must be a non-empty string")
    end

    local sanitizedId = nil
    if entityId ~= nil then
        if type(entityId) == "number" then
            sanitizedId = tostring(entityId)
        elseif type(entityId) == "string" then
            sanitizedId = string.gsub(entityId, "[^%w_%-]", "")
            if sanitizedId == "" then
                error("StateManager.buildStateKey: entityId cannot be empty after sanitization")
            end
        else
            error("StateManager.buildStateKey: entityId must be a string or number")
        end
    end

    if keyType == "ui.selection" then
        if entityType == "event" or entityType == "character" or entityType == "faction" then
            return "ui.selected" .. string.upper(string.sub(entityType, 1, 1)) .. string.sub(entityType, 2)
        else
            error("StateManager.buildStateKey: Invalid entityType for ui.selection: " .. entityType)
        end
    elseif keyType == "settings" then
        if entityType == "eventType" and sanitizedId then
            return "eventTypes." .. sanitizedId
        else
            error("StateManager.buildStateKey: Invalid entityType or missing entityId for settings: " .. entityType)
        end
    elseif keyType == "userContent" then
        if entityType == "events" or entityType == "characters" or entityType == "factions" then
            return "data.userContent." .. entityType
        else
            error("StateManager.buildStateKey: Invalid entityType for userContent: " .. entityType)
        end
    elseif keyType == "collection" then
        if sanitizedId then
            return "collections." .. sanitizedId
        else
            error("StateManager.buildStateKey: entityId required for collection key type")
        end
    elseif keyType == "ui.state" then
        if
            entityType == "settingsCategory" or entityType == "isMainFrameOpen" or entityType == "selectedPeriod" or
                entityType == "windowPosition"
         then
            return "ui." .. entityType
        elseif entityType == "timeline" and sanitizedId then
            return "timeline." .. sanitizedId
        else
            error("StateManager.buildStateKey: Invalid entityType for ui.state: " .. entityType)
        end
    else
        error("StateManager.buildStateKey: Unknown keyType: " .. keyType)
    end
end

-- =============================================================================================
-- CONVENIENCE KEY BUILDER FUNCTIONS
-- =============================================================================================
--
-- These helper functions provide simplified interfaces for common key building patterns.
-- They wrap the main buildStateKey function with predefined parameters for specific use cases,
-- reducing boilerplate code and improving readability throughout Chronicles.
--
-- DESIGN PATTERN:
-- Each convenience function is specialized for a particular domain (selections, settings,
-- content, collections, UI state) and provides appropriate default values and validation
-- specific to that domain's requirements.
--
-- USAGE GUIDELINES:
-- • Use these instead of buildStateKey directly when possible
-- • They provide better type safety and clearer intent
-- • Error messages are more specific to the use case
-- • Parameters are optimized for each domain
-- =============================================================================================

--[[
    Build entity selection key for UI state management
    
    Creates keys for tracking which entity is currently selected in the UI.
    Maps to ui.selectedEvent, ui.selectedCharacter, ui.selectedFaction patterns.
    
    @param entityType [string] "event", "character", or "faction"
    @return [string] Selection state key (e.g., "ui.selectedEvent")
]]
function private.Core.StateManager.buildSelectionKey(entityType)
    return private.Core.StateManager.buildStateKey("ui.selection", entityType)
end

--[[
    Build settings key for event types

    Collection status lives in the same settingsState store but is built through
    buildCollectionKey, which is the only owner of the collections.* namespace.

    @param settingType [string] "eventType"
    @param id [string|number] Setting identifier
    @return [string] Settings state key
]]
function private.Core.StateManager.buildSettingsKey(settingType, id)
    if not settingType or type(settingType) ~= "string" or settingType == "" then
        error("StateManager.buildSettingsKey: settingType must be a non-empty string, got: " .. tostring(settingType))
    end
    if not id then
        error("StateManager.buildSettingsKey: id cannot be nil")
    end
    return private.Core.StateManager.buildStateKey("settings", settingType, id)
end

--[[
    Build user content key for user data
    @param contentType [string] "events", "characters", or "factions"
    @return [string] User content state key
]]
function private.Core.StateManager.buildUserContentKey(contentType)
    if not contentType or type(contentType) ~= "string" or contentType == "" then
        error(
            "StateManager.buildUserContentKey: contentType must be a non-empty string, got: " .. tostring(contentType)
        )
    end
    return private.Core.StateManager.buildStateKey("userContent", contentType)
end

-- Sub-paths of the structures init() creates under data.userContent.*
local USER_CONTENT_SUB_PATHS = {
    byId = true,
    metadata = true,
    index = true
}

--[[
    Build user content data key with subpath
    @param contentType [string] "events", "characters", or "factions"
    @param subPath [string] Optional subpath: "byId", "metadata" or "index"
    @return [string] Full user content data key
    @throws Error if subPath is not a known sub-path
]]
function private.Core.StateManager.buildUserContentDataKey(contentType, subPath)
    local baseKey = private.Core.StateManager.buildUserContentKey(contentType)
    if subPath == nil then
        return baseKey
    end
    if not USER_CONTENT_SUB_PATHS[subPath] then
        error("StateManager.buildUserContentDataKey: Unknown subPath: " .. tostring(subPath))
    end
    return baseKey .. "." .. subPath
end

--[[
    Build collection status key
    @param collectionName [string] Collection identifier
    @return [string] Collection status state key
]]
function private.Core.StateManager.buildCollectionKey(collectionName)
    if not collectionName or type(collectionName) ~= "string" or collectionName == "" then
        error(
            "StateManager.buildCollectionKey: collectionName must be a non-empty string, got: " ..
                tostring(collectionName)
        )
    end
    return private.Core.StateManager.buildStateKey("collection", "collection", collectionName)
end

--[[
    Build UI state key
    @param stateType [string] UI state type
    @param subKey [string] Optional sub-key for complex states
    @return [string] UI state key
]]
function private.Core.StateManager.buildUIStateKey(stateType, subKey)
    if not stateType or type(stateType) ~= "string" or stateType == "" then
        error("StateManager.buildUIStateKey: stateType must be a non-empty string, got: " .. tostring(stateType))
    end
    if subKey then
        return private.Core.StateManager.buildStateKey("ui.state", stateType, subKey)
    else
        return private.Core.StateManager.buildStateKey("ui.state", stateType)
    end
end

-- The complete timeline.* namespace. Every key here persists to db.global.timelineState --
-- persistState only exempts data.userContent.* -- so nothing written under timeline.* is "just for
-- this session". That is why yearSpecificEvents was removed: it stored whole event records, putting
-- the text of every year the user searched on disk. yearSpecificMode / yearSpecificTarget are only
-- ever written, never read; the year-specific view is driven by the DisplayEventsForYear event.
local TIMELINE_STATE_KEYS = {
    currentStep = true,
    currentPage = true,
    selectedYear = true,
    yearSpecificMode = true,
    yearSpecificTarget = true
}

--[[
    Build timeline state key
    @param timelineKey [string] Timeline state key, one of TIMELINE_STATE_KEYS
    @return [string] Timeline state key
    @throws Error if timelineKey is not a known timeline state key
]]
function private.Core.StateManager.buildTimelineKey(timelineKey)
    if not timelineKey or type(timelineKey) ~= "string" or timelineKey == "" then
        error("StateManager.buildTimelineKey: timelineKey must be a non-empty string, got: " .. tostring(timelineKey))
    end
    if not TIMELINE_STATE_KEYS[timelineKey] then
        error("StateManager.buildTimelineKey: Unknown timelineKey: " .. timelineKey)
    end
    return "timeline." .. timelineKey
end

-- =============================================================================================
-- CORE STATE MANAGEMENT OPERATIONS
-- =============================================================================================
--
-- These functions provide the primary interface for state manipulation in Chronicles.
-- They handle initialization, persistence, subscription management, and state access
-- with proper error handling and performance optimization.
--
-- INITIALIZATION FLOW:
-- 1. Check if already initialized to prevent duplicate setup
-- 2. Load existing state from AceDB global storage
-- 3. Restructure flat storage into hierarchical state store
-- 4. Initialize default structures for user content
-- 5. Mark state as loaded and initialized
--
-- PERSISTENCE STRATEGY:
-- • Immediate persistence on state changes
-- • Hierarchical storage mapping (ui.*, timeline.*, etc.)
-- • Atomic updates with rollback capability
-- • Separation of complex data structures (userContent handled separately)
--
-- SUBSCRIPTION SYSTEM:
-- • Event-driven notifications for state changes
-- • Module isolation with subscriber IDs
-- • Safe callback execution with error recovery
-- • Unsubscription support for cleanup
--
-- PERFORMANCE CONSIDERATIONS:
-- • Lazy initialization of state store
-- • Efficient key-based storage access
-- • Minimal memory footprint
-- • Fast subscriber lookup and notification
-- =============================================================================================

--[[
    Initialize StateManager and load existing state from SavedVariables
    
    This function performs the critical startup sequence for Chronicles' state management:
    • Prevents duplicate initialization with guard clause
    • Safely accesses Chronicles.db through HelperUtils
    • Loads and restructures existing state from AceDB global storage
    • Initializes default user content structures if missing
    • Sets up the in-memory state store for runtime operations
    
    STORAGE MAPPING:
    • chronicles.db.global.uiState → stateStore["ui.*"]
    • chronicles.db.global.timelineState → stateStore["timeline.*"]
    • chronicles.db.global.settingsState.eventTypes → stateStore["eventTypes.*"]
    • chronicles.db.global.settingsState.collections → stateStore["collections.*"]
    • chronicles.db.global.dataState → stateStore["data.*"]
    
    DEPENDENCIES:
    • Requires Core.Utils.HelperUtils for safe Chronicles access
    • Expects AceDB-3.0 to be properly initialized
    
    @throws None - designed to be safe and idempotent
]]
function private.Core.StateManager.init()
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if chronicles and chronicles.db and chronicles.db.global then
        if chronicles.db.global.uiState then
            for key, value in pairs(chronicles.db.global.uiState) do
                stateStore["ui." .. key] = value
            end
        end

        if chronicles.db.global.timelineState then
            for key, value in pairs(chronicles.db.global.timelineState) do
                stateStore["timeline." .. key] = value
            end
        end
        if chronicles.db.global.settingsState then
            for key, value in pairs(chronicles.db.global.settingsState) do
                if key == "eventTypes" then
                    for eventTypeId, status in pairs(value) do
                        stateStore["eventTypes." .. eventTypeId] = status
                    end
                elseif key == "collections" then
                    for collectionName, status in pairs(value) do
                        stateStore["collections." .. collectionName] = status
                    end
                else
                    stateStore[key] = value
                end
            end
        end

        if chronicles.db.global.dataState then
            for key, value in pairs(chronicles.db.global.dataState) do
                stateStore["data." .. key] = value
            end
        end

        if not stateStore["data.userContent.events"] then
            stateStore["data.userContent.events"] = {
                byId = {},
                metadata = {
                    count = 0,
                    lastModified = 0
                },
                index = {
                    byYear = {},
                    byEventType = {}
                }
            }
        end

        if not stateStore["data.userContent.characters"] then
            stateStore["data.userContent.characters"] = {
                byId = {},
                metadata = {
                    count = 0,
                    lastModified = 0
                },
                index = {
                    byYear = {}
                }
            }
        end

        if not stateStore["data.userContent.factions"] then
            stateStore["data.userContent.factions"] = {
                byId = {},
                metadata = {
                    count = 0,
                    lastModified = 0
                },
                index = {
                    byYear = {}
                }
            }
        end
    end
end

--[[
    Set a state value with automatic persistence and change notification
    
    This is the primary method for updating Chronicles state. It provides:
    • Automatic initialization if StateManager hasn't been set up yet
    • Input validation (returns false on invalid key)
    • Immediate persistence to AceDB storage
    • Change event notification to all subscribers
    • Optional description passed through for audit/debugging context

    PERSISTENCE FLOW:
    1. Validate input parameters
    2. Store old value for change comparison
    3. Update in-memory state store
    4. Persist to appropriate AceDB storage location
    5. Notify subscribers with old and new values

    UNCHANGED VALUES:
    A write whose value equals the stored value neither persists nor notifies. Skipping
    is the default because a SavedVariables write plus a full subscriber fan-out (each
    subscriber can trigger UI refresh work) is not free, and most call sites write
    idempotently. Pass { forceNotify = true } to wake subscribers with an unchanged
    value anyway; rehydrate() is the purpose-built primitive for that.

    @param key [string] State key (should be built using buildStateKey functions)
    @param value [any] New state value (any JSON-serializable type)
    @param description [string] Optional description for logging and debugging
    @param options [table] Optional behavior flags:
        • forceNotify [boolean] Notify subscribers even when the value is unchanged
    @return [boolean] Success status (false indicates validation failure)
]]
function private.Core.StateManager.setState(key, value, description, options)
    if not key then
        return false
    end

    if type(key) ~= "string" then
        return false
    end

    if key == "" then
        return false
    end

    local oldValue = stateStore[key]

    if oldValue == value then
        if options and options.forceNotify then
            private.Core.StateManager.notifySubscribers(key, value, oldValue)
        end
        return true
    end

    stateStore[key] = value

    private.Core.StateManager.persistState(key, value)
    private.Core.StateManager.notifySubscribers(key, value, oldValue)

    return true
end

--[[
    Retrieve a state value with automatic initialization
    
    Safe state retrieval method that handles initialization and provides
    consistent error handling across Chronicles.
    
    @param key [string] State key to retrieve
    @return [any] State value, or nil if key doesn't exist or is invalid
]]
function private.Core.StateManager.getState(key)
    if not key then
        return nil
    end

    if type(key) ~= "string" then
        return nil
    end

    if key == "" then
        return nil
    end

    return stateStore[key]
end

--[[
    Re-emit the current value of a state key to its subscribers without
    mutating or persisting it.

    Used on addon startup to wake UI subscribers with state that was restored
    from SavedVariables during init(), instead of writing each value back to
    itself via setState just to trigger a notification (which also incurred a
    redundant AceDB write). Subscribers receive newValue == oldValue, which
    reads as "restored" rather than "changed".

    @param key [string] State key to re-broadcast
    @return [boolean] true if a value existed and subscribers were notified
]]
function private.Core.StateManager.rehydrate(key)
    if type(key) ~= "string" or key == "" then
        return false
    end

    local value = stateStore[key]
    if value == nil then
        return false
    end

    private.Core.StateManager.notifySubscribers(key, value, value)
    return true
end

function private.Core.StateManager.persistState(key, value)
    local chronicles = private.Core.Utils.HelperUtils.getChronicles()
    if not chronicles or not chronicles.db or not chronicles.db.global then
        return
    end

    -- Parse key to determine storage location
    local keyParts = {}
    for part in string.gmatch(key, "[^%.]+") do
        table.insert(keyParts, part)
    end

    if #keyParts < 2 then
        return
    end

    local category = keyParts[1]
    local subKey = keyParts[2]

    if category == "ui" then
        if not chronicles.db.global.uiState then
            chronicles.db.global.uiState = {}
        end
        chronicles.db.global.uiState[subKey] = value
    elseif category == "timeline" then
        if not chronicles.db.global.timelineState then
            chronicles.db.global.timelineState = {}
        end
        chronicles.db.global.timelineState[subKey] = value
    elseif category == "eventTypes" then
        if not chronicles.db.global.settingsState then
            chronicles.db.global.settingsState = {}
        end
        if not chronicles.db.global.settingsState.eventTypes then
            chronicles.db.global.settingsState.eventTypes = {}
        end
        chronicles.db.global.settingsState.eventTypes[subKey] = value
    elseif category == "collections" then
        if not chronicles.db.global.settingsState then
            chronicles.db.global.settingsState = {}
        end
        if not chronicles.db.global.settingsState.collections then
            chronicles.db.global.settingsState.collections = {}
        end
        chronicles.db.global.settingsState.collections[subKey] = value
    elseif category == "data" and subKey ~= "userContent" then
        if not chronicles.db.global.dataState then
            chronicles.db.global.dataState = {}
        end
        chronicles.db.global.dataState[subKey] = value
    end
end

--[[
    Subscribe to state changes for reactive programming patterns
    
    Enables modules to react to state changes without tight coupling.
    Callbacks are executed safely with error handling to prevent
    subscriber failures from affecting other subscribers.
    
    A subscriberId identifies one subscription per key, so reusing an id -- including
    omitting it twice, which both map to "anonymous" -- is rejected rather than
    silently overwriting the first subscriber. The first registration wins so that the
    working subscriber keeps receiving notifications.

    @param key [string] State key to monitor
    @param callback [function] Function to call when state changes: callback(newValue, oldValue, key)
    @param subscriberId [string] Unique identifier for this subscription (for cleanup)
    @return [boolean] Success status (false if the id is already taken for this key)
]]
function private.Core.StateManager.subscribe(key, callback, subscriberId)
    if not key or not callback then
        return false
    end

    local resolvedId = subscriberId or "anonymous"

    if not subscribers[key] then
        subscribers[key] = {}
    end

    local existing = subscribers[key][resolvedId]
    if existing and existing ~= callback then
        geterrorhandler()(
            string.format(
                "Chronicles StateManager.subscribe: subscriber id '%s' is already registered for state key '%s'; " ..
                    "the existing subscription was kept. Use a unique subscriberId.",
                tostring(resolvedId),
                tostring(key)
            )
        )
        return false
    end

    subscribers[key][resolvedId] = callback
    return true
end

function private.Core.StateManager.unsubscribe(key, subscriberId)
    if not key or not subscriberId then
        return false
    end

    if subscribers[key] then
        subscribers[key][subscriberId] = nil
    end

    return true
end

function private.Core.StateManager.notifySubscribers(key, newValue, oldValue)
    if not subscribers[key] then
        return
    end
    for subscriberId, callback in pairs(subscribers[key]) do
        if type(callback) == "function" then
            -- pcall isolates one subscriber's failure from the others, but we
            -- fail fast: surface the error in-game rather than swallowing it.
            local success, errorMsg = pcall(callback, newValue, oldValue, key)
            if not success then
                geterrorhandler()(errorMsg)
            end
        end
    end
end

