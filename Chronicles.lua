local FOLDER_NAME, private = ...
private.Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
local defaults = {
    global = {
        options = {
            minimap = {hide = false},
            myjournal = true
        },
        uiState = {
            selectedEvent = nil,
            selectedCharacter = nil,
            selectedFaction = nil,
            selectedPeriod = nil,
            activeTab = nil,
            isMainFrameOpen = false
        },
        timelineState = {
            currentStep = nil,
            currentPage = nil,
            selectedYear = nil
        },
        settingsState = {
            eventTypes = {},
            collections = {},
            debugMode = false
        },
        dataState = {
            lastRefreshTime = 0,
            isDirty = false
        }
    }
}

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local Icon = LibStub("LibDBIcon-1.0")

-- -------------------------
-- Init
-- -------------------------
local Chronicles = private.Chronicles
Chronicles.descName = Locale["Chronicles"]
Chronicles.description = Locale["Description"]

private.constants = private.constants

function Chronicles:OnInitialize()
    private.Chronicles.db = LibStub("AceDB-3.0"):New("ChroniclesDB", defaults, true)

    self.mapIcon =
        LibStub("LibDataBroker-1.1"):NewDataObject(
        FOLDER_NAME,
        {
            type = "launcher",
            text = Locale["Chronicles"],
            icon = "Interface\\ICONS\\Inv_scroll_04",
            OnClick = function(self, button)
                Chronicles.UI:DisplayWindow()
            end,
            OnTooltipShow = function(tt)
                tt:AddLine(Locale["Chronicles"], 1, 1, 1)
                local yearText = Locale["CurrentYear"] .. private.constants.config.currentYear .. Locale["AfterDP"]
                tt:AddLine(yearText)
                tt:AddLine(" ")
                tt:AddLine(Locale["Icon tooltip"])
            end
        }
    )
    Icon:Register(FOLDER_NAME, self.mapIcon, self.db.global.options.minimap)
    self:RegisterChatCommand(
        "chronicles",
        function()
            self.UI:DisplayWindow()
        end
    )

    -- Initialize state manager BEFORE loading data to ensure saved state is available during collection registration
    if private.Core.StateManager then
        private.Core.StateManager.init()
    end

    Chronicles.Data:Load() -- Register AddonStartup event handler to check saved state after all systems are initialized
    private.Core.registerCallback(private.constants.events.AddonStartup, self.OnAddonStartup, self)

    -- Delay the startup event to ensure all event listeners are registered
    C_Timer.After(
        0.2,
        function()
            local startupData = {
                debugMode = private.constants.eventSystem.debugMode or false
            }
            private.Core.Logger.trace("Chronicles", "Triggering AddonStartup event")
            private.Core.triggerEvent(private.constants.events.AddonStartup, startupData, "Chronicles:OnInitialize")

            -- Explicitly trigger TimelineInit event after startup
            private.Core.triggerEvent(private.constants.events.TimelineInit, {}, "Chronicles:OnInitialize")
        end
    )
end

--[[
    AddonStartup event handler - checks for existing saved state and restores it
    
    This centralizes all state checking logic that was previously done in individual
    UI component OnLoad methods. By handling this during AddonStartup, we ensure
    all core systems are fully initialized before checking saved state.
]]
function Chronicles:OnAddonStartup(eventData)
    private.Core.Logger.trace("Chronicles", "OnAddonStartup - checking for existing saved state")

    if not private.Core.StateManager then
        private.Core.Logger.error("Chronicles", "StateManager not available during AddonStartup")
        return
    end

    -- Check for existing selectedPeriod and trigger state update if found
    local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
    local existingPeriod = private.Core.StateManager.getState(selectedPeriodKey)
    if existingPeriod then
        private.Core.Logger.trace(
            "Chronicles",
            "Found existing selectedPeriod in saved state - restoring: " ..
                tostring(existingPeriod.lower) .. "-" .. tostring(existingPeriod.upper)
        )
        -- Re-trigger state update to notify all subscribed UI components
        private.Core.StateManager.setState(selectedPeriodKey, existingPeriod, "AddonStartup state restoration")
    else
        private.Core.Logger.trace("Chronicles", "No existing selectedPeriod found in saved state")
    end

    -- Check for existing selectedEvent and trigger state update if found
    local eventSelectionKey = private.Core.StateManager.buildSelectionKey("event")
    local existingEventSelection = private.Core.StateManager.getState(eventSelectionKey)
    if existingEventSelection then
        private.Core.Logger.trace(
            "Chronicles",
            "Found existing selectedEvent in saved state - restoring: " ..
                tostring(existingEventSelection.eventId) .. " from " .. tostring(existingEventSelection.collectionName)
        )
        -- Re-trigger state update to notify all subscribed UI components
        private.Core.StateManager.setState(eventSelectionKey, existingEventSelection, "AddonStartup state restoration")
    else
        private.Core.Logger.trace("Chronicles", "No existing selectedEvent found in saved state")
    end

    -- Check for existing selectedCharacter and trigger state update if found
    local characterSelectionKey = private.Core.StateManager.buildSelectionKey("character")
    local existingCharacterSelection = private.Core.StateManager.getState(characterSelectionKey)
    if existingCharacterSelection then
        private.Core.Logger.trace(
            "Chronicles",
            "Found existing selectedCharacter in saved state - restoring: " ..
                tostring(existingCharacterSelection.characterId or existingCharacterSelection) ..
                    " from " .. tostring(existingCharacterSelection.collectionName or "unknown")
        )
        -- Re-trigger state update to notify all subscribed UI components
        private.Core.StateManager.setState(
            characterSelectionKey,
            existingCharacterSelection,
            "AddonStartup state restoration"
        )
    else
        private.Core.Logger.trace("Chronicles", "No existing selectedCharacter found in saved state")
    end
    -- Check for existing selectedFaction and trigger state update if found
    local factionSelectionKey = private.Core.StateManager.buildSelectionKey("faction")
    local existingFactionSelection = private.Core.StateManager.getState(factionSelectionKey)
    if existingFactionSelection then
        private.Core.Logger.trace(
            "Chronicles",
            "Found existing selectedFaction in saved state - restoring: " ..
                tostring(existingFactionSelection.factionId or existingFactionSelection) ..
                    " from " .. tostring(existingFactionSelection.collectionName or "unknown")
        )
        -- Re-trigger state update to notify all subscribed UI components
        private.Core.StateManager.setState(
            factionSelectionKey,
            existingFactionSelection,
            "AddonStartup state restoration"
        )
    else
        private.Core.Logger.trace("Chronicles", "No existing selectedFaction found in saved state")
    end

    -- Check for existing activeTab and trigger state update if found
    local activeTabKey = private.Core.StateManager.buildUIStateKey("activeTab")
    local existingActiveTab = private.Core.StateManager.getState(activeTabKey)
    if existingActiveTab then
        private.Core.Logger.trace(
            "Chronicles",
            "Found existing activeTab in saved state - restoring: " .. tostring(existingActiveTab)
        )
        -- Re-trigger state update to notify all subscribed UI components
        private.Core.StateManager.setState(activeTabKey, existingActiveTab, "AddonStartup state restoration")
    else
        private.Core.Logger.trace("Chronicles", "No existing activeTab found in saved state")
    end

    private.Core.Logger.trace("Chronicles", "OnAddonStartup state restoration completed")
end

function Chronicles:OnDisable()
    private.Core.triggerEvent(private.constants.events.AddonShutdown, nil, "Chronicles:OnDisable")
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.Data:RegisterEventDB(pluginName, db)
    -- Use safe event triggering
    private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:RegisterPluginDB")
end

-- -------------------------
