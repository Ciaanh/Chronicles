local FOLDER_NAME, private = ...

-- Init libs ---------------------------------------------------------------------------
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local Icon = LibStub("LibDBIcon-1.0")

local Chronicles = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceConsole-3.0")
private.Core = Chronicles

-----------------------------------------------------------------------------------------
-- Init ---------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

Chronicles.descName = Locale["Chronicles"]
Chronicles.description = Locale["Description"]

Chronicles.constants = private.constants

function Chronicles:OnInitialize()
    --https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial
    local defaults = {
        global = {
            options = {
                minimap = {hide = false},
                myjournal = true
            },
            EventTypes = {},
            EventDBStatuses = {},
            FactionDBStatuses = {},
            CharacterDBStatuses = {},

            MyJournalEventDB = {
                [1] = {
                    id = 1,
                    label = Locale["MyJournal Event"],
                    description = {Locale["An event from my journal"]},
                    yearStart = -1,
                    yearEnd = -1,
                    eventType = Chronicles.constants.eventType.war,
                    timeline = 1
                },
            },
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

    Chronicles.UI.EventFilter:Init()
    Chronicles.DB:Init()
    Chronicles.UI:Init()
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.DB:RegisterEventDB(pluginName, db)
end

function get_constants()
    return Chronicles.constants
end

function get_locale(value)
    return Locale[value]
end

function adjust_value(value, step)
    local valueFloor = math.floor(value)
    local valueMiddle = valueFloor + (step / 2)
    --DEFAULT_CHAT_FRAME:AddMessage("-- adjust_value " .. value .. " " .. step .. " " .. valueFloor .. " " .. valueMiddle)

    if (value < valueMiddle) then
        return valueFloor
    end
    return valueFloor + step
end

function tablelength(T)
    if (T == nil) then
        return 0
    end

    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function copyTable(tableToCopy)
    local orig_type = type(tableToCopy)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in pairs(tableToCopy) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = tableToCopy
    end
    return copy
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
