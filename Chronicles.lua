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
            settingsCategory = nil,
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

-- Keys this addon persisted in an earlier version and no longer reads. AceDB keeps whatever is in
-- the file and StateManager.init() copies every timelineState/uiState key straight into memory, so a
-- retired key is reloaded on every login unless it is dropped explicitly. `yearSpecificEvents` held
-- whole event records -- labels and HTML chapters for every year the user had ever searched -- so
-- upgrading without this would carry that payload in SavedVariables permanently.
local retiredState = {
    timelineState = {"yearSpecificEvents"},
    uiState = {"activeTab"}
}

local function dropRetiredState(global)
    for section, keys in pairs(retiredState) do
        local stored = global[section]
        if stored then
            for _, key in ipairs(keys) do
                stored[key] = nil
            end
        end
    end
end

local function initializeSavedVariables(addonInstance)
    local db = LibStub("AceDB-3.0"):New("ChroniclesDB", defaults, true)
    dropRetiredState(db.global)
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
            icon = private.constants.minimapIcon,
            OnClick = function()
                toggleCallback()
            end,
            OnTooltipShow = function(tt)
                tooltipCallback(tt)
            end
        }
    )
end

local function runReadyCallback(callback, context)
    local success, err = pcall(callback)
    if success then
        return
    end

    local handler = geterrorhandler()
    if handler then
        handler(string.format("Chronicles:ExecuteWhenReady callback failed [%s]: %s", context or "unknown", err))
    end
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
    isBootstrapComplete = false
}

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

    This is the single startup restore path. Subscribers register during UI load, so
    the values StateManager.init() read back from SavedVariables have to be re-emitted
    for anything to react to them. rehydrate re-notifies without mutating or
    re-persisting the value, and is a no-op for keys with no saved value.
]]
function Chronicles:RestoreStartupState()
    local stateManager = private.Core.StateManager
    if not stateManager then
        return
    end

    private.Core.triggerEvent(
        private.constants.events.TimelineInit,
        {source = "Chronicles:RestoreStartupState"},
        "Chronicles:RestoreStartupState"
    )

    stateManager.rehydrate(stateManager.buildUIStateKey("selectedPeriod"))
    stateManager.rehydrate(stateManager.buildSelectionKey("event"))
    stateManager.rehydrate(stateManager.buildSelectionKey("character"))
    stateManager.rehydrate(stateManager.buildSelectionKey("faction"))
    stateManager.rehydrate(stateManager.buildUIStateKey("settingsCategory"))
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

    self:FlushReadyCallbacks()
end

--[[
    Run a callback that needs Chronicles' core systems in place

    Callbacks arriving before CompleteBootstrap are queued and flushed by it, in
    arrival order; everything after it runs immediately.

    @param callback [function] Work to run
    @param context [string] Caller name, reported if the callback errors
]]
function Chronicles:ExecuteWhenReady(callback, context)
    if type(callback) ~= "function" then
        return
    end

    if self.lifecycle.isBootstrapComplete then
        runReadyCallback(callback, context)
        return
    end

    table.insert(self.lifecycle.pendingReadyCallbacks, {callback = callback, context = context})
end

function Chronicles:FlushReadyCallbacks()
    local pending = self.lifecycle.pendingReadyCallbacks
    if #pending == 0 then
        return
    end

    for index = 1, #pending do
        local entry = pending[index]
        if entry and type(entry.callback) == "function" then
            runReadyCallback(entry.callback, entry.context)
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
        print(
            "|cffff0000Error:|r Chronicles:RegisterPluginDB called with invalid pluginData for collection: " ..
                tostring(pluginName)
        )
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

