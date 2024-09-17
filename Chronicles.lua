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
            OnClick = function(self, button, down)
                -- if (MainFrame:IsVisible()) then
                --     Chronicles.UI:HideWindow()
                -- else
                --     Chronicles.UI:DisplayWindow()
                -- end

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
    )

    self:RegisterChatCommand(
        "ct",
        function()
            self.UI.DisplayWindow()
        end
    )

    Chronicles.UI.EventFilter:Init()
    Chronicles.DB:Init()
    Chronicles.UI:Init()
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.DB:RegisterEventDB(pluginName, db)
    Chronicles.UI:Init()
end

function get_constants()
    return private.constants
end

function get_locale(value)
    return Locale[value]
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
