local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventFilter = {}
Chronicles.UI.EventFilter.Displayed = false

function Chronicles.UI.EventFilter:Init()
    EventTypeBlockEra:SetChecked(get_EventType_Checked(get_constants().eventType.era))
    EventTypeBlockWar:SetChecked(get_EventType_Checked(get_constants().eventType.war))
    EventTypeBlockBattle:SetChecked(get_EventType_Checked(get_constants().eventType.battle))
    EventTypeBlockDeath:SetChecked(get_EventType_Checked(get_constants().eventType.death))
    EventTypeBlockBirth:SetChecked(get_EventType_Checked(get_constants().eventType.birth))
    EventTypeBlockOther:SetChecked(get_EventType_Checked(get_constants().eventType.other))
end

------------------------------------------------------------------------------------------
-- Event type Filter ---------------------------------------------------------------------
------------------------------------------------------------------------------------------
function change_EventType(eventType, checked)
    Chronicles.DB:SetEventTypeStatus(eventType, checked)

    Chronicles.UI.EventList:Refresh()
    Chronicles.UI.Timeline:Refresh()
    Chronicles.UI.EventDescription:Refresh()
end

function get_EventType_Checked(eventType)
    return Chronicles.DB:GetEventTypeStatus(eventType)
end
