local FOLDER_NAME, private = ...

local Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
private.Core = Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local Icon = LibStub("LibDBIcon-1.0")

-----------------------------------------------------------------------------------------
-- Init ---------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

Chronicles.descName = Locale["Chronicles"]
Chronicles.description = Locale["Description"]

Chronicles.constants = private.constants

function Chronicles:OnInitialize()
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
    self.storage = LibStub("AceDB-3.0"):New("ChroniclesDB", defaults, true)

    self.mapIcon =
        LibStub("LibDataBroker-1.1"):NewDataObject(
        FOLDER_NAME,
        {
            type = "launcher",
            text = Locale["Chronicles"],
            icon = "Interface\\ICONS\\Inv_scroll_04",
            OnClick = function(self, button, down)
                if (MainFrame:IsVisible()) then
                    Chronicles.UI:HideWindow()
                else
                    Chronicles.UI:DisplayWindow()
                end
            end,
            OnTooltipShow = function(tt)
                tt:AddLine(Locale["Chronicles"], 1, 1, 1)
                local yearText = Locale["CurrentYear"] .. Chronicles.constants.config.currentYear .. Locale["AfterDP"]
                tt:AddLine(yearText)
                tt:AddLine(" ")
                tt:AddLine(Locale["Icon tooltip"])
            end
        }
    )
    Icon:Register(FOLDER_NAME, self.mapIcon, self.storage.global.options.minimap)

    self:RegisterChatCommand(
        "chronicles",
        function()
            self.UI:DisplayWindow()
        end
    )

    self:RegisterChatCommand(
        "ct",
        function()
            self.UITest:DisplayWindow()
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
    return Chronicles.constants
end

function get_locale(value)
    return Locale[value]
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
