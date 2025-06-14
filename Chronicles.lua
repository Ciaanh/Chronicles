local FOLDER_NAME, private = ...
private.Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
local defaults = {
    global = {
        options = {
            minimap = {hide = false}
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

    if private.Core.StateManager then
        private.Core.StateManager.init()
    end

    Chronicles.Data:Load()

    private.Core.registerCallback(private.constants.events.AddonStartup, self.OnAddonStartup, self)
    C_Timer.After(
        0.2,
        function()
            local startupData = {}
            private.Core.triggerEvent(private.constants.events.AddonStartup, startupData, "Chronicles:OnInitialize")
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
    if not private.Core.StateManager then
        return
    end

    private.Core.triggerEvent(private.constants.events.TimelineInit, {}, "Chronicles:OnInitialize")
    local selectedPeriodKey = private.Core.StateManager.buildUIStateKey("selectedPeriod")
    local existingPeriod = private.Core.StateManager.getState(selectedPeriodKey)
    if existingPeriod then
        private.Core.StateManager.setState(selectedPeriodKey, existingPeriod, "AddonStartup state restoration")
    end

    local eventSelectionKey = private.Core.StateManager.buildSelectionKey("event")
    local existingEventSelection = private.Core.StateManager.getState(eventSelectionKey)
    if existingEventSelection and type(existingEventSelection) == "table" then
        private.Core.StateManager.setState(eventSelectionKey, existingEventSelection, "AddonStartup state restoration")
    end

    local characterSelectionKey = private.Core.StateManager.buildSelectionKey("character")
    local existingCharacterSelection = private.Core.StateManager.getState(characterSelectionKey)
    if existingCharacterSelection and type(existingCharacterSelection) == "table" then
        private.Core.StateManager.setState(
            characterSelectionKey,
            existingCharacterSelection,
            "AddonStartup state restoration"
        )
    end

    local factionSelectionKey = private.Core.StateManager.buildSelectionKey("faction")
    local existingFactionSelection = private.Core.StateManager.getState(factionSelectionKey)
    if existingFactionSelection and type(existingFactionSelection) == "table" then
        private.Core.StateManager.setState(
            factionSelectionKey,
            existingFactionSelection,
            "AddonStartup state restoration"
        )
    end

    local activeTabKey = private.Core.StateManager.buildUIStateKey("activeTab")
    local existingActiveTab = private.Core.StateManager.getState(activeTabKey)
    if existingActiveTab then
        private.Core.StateManager.setState(activeTabKey, existingActiveTab, "AddonStartup state restoration")
    end
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
