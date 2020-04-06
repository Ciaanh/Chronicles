local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventFilter = {}
Chronicles.UI.EventFilter.Displayed = false

function EventFilter_InitToggle(self)
    self:SetText("<")
end

function EventFilter_Toggle()
     -- DEFAULT_CHAT_FRAME:AddMessage("-- Toggle EventFilter " .. tostring(Chronicles.UI.EventFilter.Displayed))

    if(Chronicles.UI.EventFilter.Displayed) then
        FilterContent:Hide()
        Chronicles.UI.EventFilter.Displayed = false
    else
        FilterContent:Show()
        Chronicles.UI.EventFilter.Displayed = true
    end
end


function Chronicles.UI.EventFilter:DisplayEventFilter(page)
    
end