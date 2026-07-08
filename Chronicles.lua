local FOLDER_NAME, private = ...
private.Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0", "AceEvent-3.0")
_G.Chronicles = private.Chronicles

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
            collections = {}
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
    local StateManager = private.Core.StateManager
    if not StateManager then
        return
    end

    private.Core.triggerEvent(private.constants.events.TimelineInit, {}, "Chronicles:OnInitialize")

    -- Re-notify subscribers of state restored from SavedVariables during
    -- StateManager.init(). rehydrate re-emits the stored value without changing
    -- or re-persisting it (no set-value-to-itself round-trip). rehydrate is a
    -- no-op for keys with no saved value.
    StateManager.rehydrate(StateManager.buildUIStateKey("selectedPeriod"))
    StateManager.rehydrate(StateManager.buildSelectionKey("event"))
    StateManager.rehydrate(StateManager.buildSelectionKey("character"))
    StateManager.rehydrate(StateManager.buildSelectionKey("faction"))
    StateManager.rehydrate(StateManager.buildUIStateKey("activeTab"))
end

function Chronicles:OnDisable()
    private.Core.triggerEvent(private.constants.events.AddonShutdown, nil, "Chronicles:OnDisable")
end

--[[
    Register an external plugin's databases at runtime.

    @param pluginName [string] Unique name for the plugin
    @param pluginData [table] Manifest table: { events = {...}, characters = {...}, factions = {...} }
]]
function Chronicles:RegisterPluginDB(pluginName, pluginData)
    if type(pluginName) ~= "string" or pluginName == "" then
        print("|cffff0000Error:|r Chronicles:RegisterPluginDB called with invalid pluginName")
        return
    end

    if type(pluginData) ~= "table" then
        return
    end

    if not (pluginData.events or pluginData.characters or pluginData.factions) then
        print("|cffff0000Error:|r Chronicles:RegisterPluginDB requires events, characters, or factions key")
        return
    end

    local hasNameConflict = (Chronicles.Data.Events[pluginName] ~= nil) or (Chronicles.Data.Factions[pluginName] ~= nil) or
        (Chronicles.Data.Characters[pluginName] ~= nil)
    if hasNameConflict then
        print(
            "|cffff9900Warning:|r Chronicles:RegisterPluginDB skipped duplicate collection name: " .. tostring(pluginName)
        )
        return
    end

    local registered = false

    if pluginData.events then
        if Chronicles.Data:RegisterEventDB(pluginName, pluginData.events) then
            registered = true
        end
    end
    if pluginData.characters then
        if Chronicles.Data:RegisterCharacterDB(pluginName, pluginData.characters) then
            registered = true
        end
    end
    if pluginData.factions then
        if Chronicles.Data:RegisterFactionDB(pluginName, pluginData.factions) then
            registered = true
        end
    end

    if not registered then
        print(
            "|cffff9900Warning:|r Chronicles:RegisterPluginDB did not register data for collection: " ..
            tostring(pluginName)
        )
        return
    end

    private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:RegisterPluginDB")
end

-- -------------------------
