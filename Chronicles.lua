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
            isMainFrameOpen = false,
            windowPosition = nil
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
local DataBroker = LibStub("LibDataBroker-1.1")

local function getAddonVersion()
    if GetAddOnMetadata then
        return GetAddOnMetadata(FOLDER_NAME, "Version") or ""
    end
    return ""
end

local function buildLifecyclePayload(source)
    return {
        version = getAddonVersion(),
        timestamp = time(),
        source = source
    }
end

local function initializeSavedVariables(addonInstance)
    local db = LibStub("AceDB-3.0"):New("ChroniclesDB", defaults, true)
    private.Chronicles.db = db
    addonInstance.db = db
    return db.global.options.minimap
end

local function createLauncher(locale, toggleCallback, tooltipCallback)
    return DataBroker:NewDataObject(
        FOLDER_NAME,
        {
            type = "launcher",
            text = locale["Chronicles"],
            icon = "Interface\\ICONS\\Inv_scroll_04",
            OnClick = function()
                toggleCallback()
            end,
            OnTooltipShow = function(tt)
                tooltipCallback(tt)
            end
        }
    )
end

local function registerSlashCommand(addonInstance)
    addonInstance:RegisterChatCommand(
        "chronicles",
        function()
            addonInstance:ExecuteWhenReady(function()
                addonInstance.UI:DisplayWindow()
            end, "Chronicles/SlashCommand")
        end
    )
end

-- -------------------------
-- Init
-- -------------------------
local Chronicles = private.Chronicles
Chronicles.descName = Locale["Chronicles"]
Chronicles.description = Locale["Description"]
Chronicles.locale = Locale

Chronicles.lifecycle = {
    pendingReadyCallbacks = {},
    isBootstrapComplete = false,
    isStartupComplete = false
}

private.constants = private.constants

function Chronicles:OnInitialize()
    local minimapConfig = initializeSavedVariables(self)

    self.mapIcon =
        createLauncher(
        Locale,
        function()
            self:ExecuteWhenReady(function()
                self.UI:DisplayWindow()
            end, "Chronicles/MinimapToggle")
        end,
        function(tt)
            self:PopulateLauncherTooltip(tt)
        end
    )

    Icon:Register(FOLDER_NAME, self.mapIcon, minimapConfig)

    registerSlashCommand(self)

    self:CompleteBootstrap("Chronicles:OnInitialize")
end

--[[
    Restore saved state at startup after core systems finish loading
]]
function Chronicles:RestoreStartupState()
    local stateManager = private.Core.StateManager

    if stateManager then
        private.Core.triggerEvent(
            private.constants.events.TimelineInit,
            {source = "Chronicles:RestoreStartupState"},
            "Chronicles:OnInitialize"
        )

        local selectedPeriodKey = stateManager.buildUIStateKey("selectedPeriod")
        local existingPeriod = stateManager.getState(selectedPeriodKey)
        if existingPeriod then
            stateManager.setState(
                selectedPeriodKey,
                existingPeriod,
                "Startup state restoration",
                {forceNotify = true, skipIfUnchanged = true}
            )
        end

        local eventSelectionKey = stateManager.buildSelectionKey("event")
        local existingEventSelection = stateManager.getState(eventSelectionKey)
        if existingEventSelection and type(existingEventSelection) == "table" then
            stateManager.setState(
                eventSelectionKey,
                existingEventSelection,
                "Startup state restoration",
                {forceNotify = true, skipIfUnchanged = true}
            )
        end

        local characterSelectionKey = stateManager.buildSelectionKey("character")
        local existingCharacterSelection = stateManager.getState(characterSelectionKey)
        if existingCharacterSelection and type(existingCharacterSelection) == "table" then
            stateManager.setState(
                characterSelectionKey,
                existingCharacterSelection,
                "Startup state restoration",
                {forceNotify = true, skipIfUnchanged = true}
            )
        end

        local factionSelectionKey = stateManager.buildSelectionKey("faction")
        local existingFactionSelection = stateManager.getState(factionSelectionKey)
        if existingFactionSelection and type(existingFactionSelection) == "table" then
            stateManager.setState(
                factionSelectionKey,
                existingFactionSelection,
                "Startup state restoration",
                {forceNotify = true, skipIfUnchanged = true}
            )
        end

        local activeTabKey = stateManager.buildUIStateKey("activeTab")
        local existingActiveTab = stateManager.getState(activeTabKey)
        if existingActiveTab then
            stateManager.setState(
                activeTabKey,
                existingActiveTab,
                "Startup state restoration",
                {forceNotify = true, skipIfUnchanged = true}
            )
        end
    end
end

function Chronicles:OnDisable()
    private.Core.triggerEvent(
        private.constants.events.AddonShutdown,
        buildLifecyclePayload("Chronicles:OnDisable"),
        "Chronicles:OnDisable"
    )
end

-- -------------------------

function Chronicles:CompleteBootstrap(source)
    if self.lifecycle.isBootstrapComplete then
        return
    end

    self.lifecycle.isBootstrapComplete = true

    if private.Core.StateManager then
        private.Core.StateManager.init()
    end

    if Chronicles.Data and Chronicles.Data.Load then
        Chronicles.Data:Load()
    end

    C_Timer.After(
        0.2,
        function()
            private.Core.triggerEvent(
                private.constants.events.AddonStartup,
                buildLifecyclePayload(source or "Chronicles:CompleteBootstrap"),
                "Chronicles:CompleteBootstrap"
            )
        end
    )

    self:RestoreStartupState()

    if not self.lifecycle.isStartupComplete then
        self.lifecycle.isStartupComplete = true
    end

    self:FlushReadyCallbacks()
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

function Chronicles:ExecuteWhenReady(callback, context)
    if type(callback) ~= "function" then
        return
    end

    if not self.lifecycle.isStartupComplete and self.lifecycle.isBootstrapComplete then
        self.lifecycle.isStartupComplete = true
        if self.lifecycle.pendingReadyCallbacks and #self.lifecycle.pendingReadyCallbacks > 0 then
            self:FlushReadyCallbacks()
        end
    end

    if self.lifecycle.isStartupComplete then
        local success, err = pcall(callback)
        if not success then
            local handler = geterrorhandler()
            if handler then
                handler(string.format("Chronicles:ExecuteWhenReady immediate callback failed [%s]: %s", context or "unknown", err))
            end
        end
        return
    end

    if not self.lifecycle.pendingReadyCallbacks then
        self.lifecycle.pendingReadyCallbacks = {}
    end

    table.insert(self.lifecycle.pendingReadyCallbacks, {callback = callback, context = context})
end

function Chronicles:FlushReadyCallbacks()
    local pending = self.lifecycle.pendingReadyCallbacks
    if not pending or #pending == 0 then
        return
    end

    self.lifecycle.isStartupComplete = true

    for index = 1, #pending do
        local entry = pending[index]
        if entry and type(entry.callback) == "function" then
            local success, err = pcall(entry.callback)
            if not success then
                local handler = geterrorhandler()
                if handler then
                    handler(string.format("Chronicles:ExecuteWhenReady deferred callback failed [%s]: %s", entry.context or "unknown", err))
                end
            end
        end
    end

    wipe(pending)
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

    private.Core.triggerEvent(
        private.constants.events.TimelineInit,
        {source = "plugin", pluginName = pluginName},
        "Chronicles:RegisterPluginDB"
    )
end

function Chronicles:PopulateLauncherTooltip(tt)
    if not tt then
        return
    end

    local locale = self.locale or Locale
    tt:AddLine(locale["Chronicles"], 1, 1, 1)

    local config = private.constants and private.constants.config
    if config and config.currentYear then
        local yearText = (locale["CurrentYear"] or "") .. tostring(config.currentYear) .. (locale["AfterDP"] or "")
        tt:AddLine(yearText)
    end

    tt:AddLine(" ")
    tt:AddLine(locale["Icon tooltip"] or "")
end

