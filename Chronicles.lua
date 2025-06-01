local FOLDER_NAME, private = ...
private.Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
local defaults = {
    global = {
        options = {
            minimap = {hide = false},
            myjournal = true
        },
        -- StateManager state defaults
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
            selectedYear = nil,
            periodsCache = {}
        },
        settingsState = {
            eventTypes = {},
            libraries = {},
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

-----------------------------------------------------------------------------------------
-- Init ---------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
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
    )    Icon:Register(FOLDER_NAME, self.mapIcon, self.db.global.options.minimap)
    self:RegisterChatCommand(
        "chronicles",
        function()
            self.UI:DisplayWindow()
        end
    )

    -- Initialize state manager BEFORE loading data to ensure saved state is available during library registration
    if private.Core.StateManager then
        private.Core.StateManager.init()
    end

    Chronicles.Data:Load()

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

function Chronicles:OnDisable()
    private.Core.triggerEvent(private.constants.events.AddonShutdown, nil, "Chronicles:OnDisable")
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.Data:RegisterEventDB(pluginName, db)
    -- Use safe event triggering
    private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:RegisterPluginDB")
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
