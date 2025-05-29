local FOLDER_NAME, private = ...
private.Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
local defaults = {
    global = {
        options = {
            minimap = {hide = false},
            myjournal = true
        },
        EventTypesStatuses = {},
        EventDBStatuses = {},
        FactionDBStatuses = {},
        CharacterDBStatuses = {},
        MyJournalEventDB = {},
        MyJournalFactionDB = {},
        MyJournalCharacterDB = {}
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
                Chronicles.NewUi:DisplayWindow()
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
            self.NewUi:DisplayWindow()
        end
    )    Chronicles.Data:Init()    
    
    -- Initialize event system
    -- Enable debug mode if configured
    if private.Core.EventManager and private.constants.eventSystem.debugMode then
        private.Core.EventManager.Debugger:enable()
    end

    -- Initialize state manager
    if private.Core.StateManager then
        private.Core.StateManager.init()
    end    -- Use safe event triggering
    private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:OnInitialize")
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.Data:RegisterEventDB(pluginName, db)    -- Use safe event triggering
    private.Core.triggerEvent(private.constants.events.TimelineInit, nil, "Chronicles:RegisterPluginDB")
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
