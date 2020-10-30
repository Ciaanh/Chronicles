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
    Chronicles.UI:Init()
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
            local orig_value_type = type(orig_value)
            if (orig_value_type == "table") then
                copy[orig_key] = copyTable(orig_value)
            else
                copy[orig_key] = orig_value
            end
        end
    else -- number, string, boolean, etc
        copy = tableToCopy
    end
    return copy
end

function adjustTextLength(text, size, frame)
    local adjustedText = text
    if (text:len() > size) then
        adjustedText = text:sub(0, size)

        frame:SetScript(
            "OnEnter",
            function()
                GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT", -5, 30)
                GameTooltip:SetText(text, nil, nil, nil, nil, true)
            end
        )
        frame:SetScript(
            "OnLeave",
            function()
                GameTooltip:Hide()
            end
        )
    else
        frame:SetScript(
            "OnEnter",
            function()
            end
        )
        frame:SetScript(
            "OnLeave",
            function()
            end
        )
    end
    return adjustedText
end

function cleanHTML(text)
    if (text ~= nil) then
        text = string.gsub(text, "||", "|")
        text = string.gsub(text, "\\\\", "\\")
    else
        text = ""
    end
    return text
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
