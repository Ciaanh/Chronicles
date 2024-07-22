local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

Chronicles.UI.EventFilter = {}
Chronicles.UI.EventFilter.Displayed = false

function Chronicles.UI.EventFilter:Init()
    EventTypeBlockEra:SetChecked(get_EventType_Checked(1))
    EventTypeBlockWar:SetChecked(get_EventType_Checked(2))
    EventTypeBlockBattle:SetChecked(get_EventType_Checked(3))
    EventTypeBlockDeath:SetChecked(get_EventType_Checked(4))
    EventTypeBlockBirth:SetChecked(get_EventType_Checked(5))
    EventTypeBlockOther:SetChecked(get_EventType_Checked(6))
end

------------------------------------------------------------------------------------------
-- Event type Filter ---------------------------------------------------------------------
------------------------------------------------------------------------------------------
function change_EventType(eventType, checked)
    Chronicles.DB:SetEventTypeStatus(eventType, checked)
    Chronicles.UI:Refresh()
end

function get_EventType_Checked(eventType)
    return Chronicles.DB:GetEventTypeStatus(eventType)
end
