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
    self.db = LibStub("AceDB-3.0"):New("ChroniclesDB", {
        global = {options = {version = "", minimap = {hide = false}}}
    }, true)

    self.mapIcon = LibStub("LibDataBroker-1.1"):NewDataObject(FOLDER_NAME, {
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
    })
    Icon:Register(FOLDER_NAME, self.mapIcon, self.db.global.options.minimap)

    self:RegisterChatCommand("chronicles", function() self.UI:DisplayWindow() end)

    Chronicles.DB:InitDB()
    Chronicles.UI.Timeline:LoadSetDates()
    Chronicles.UI.Timeline:DisplayTimeline(1)
    Chronicles.UI.EventList:DisplayEventList(1)
end

function Chronicles:RegisterPluginDB(pluginName, db)
    Chronicles.DB:RegisterEventDB(pluginName, db)
end

function Chronicles:GetTableLength(T)
    local count = 0
    if (T ~= nil) then
        for _ in pairs(T) do
            count = count + 1
        end
    end
    return count
end
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

