local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventsView = {}

function EventFilterToggle_SetText(self)
    self:SetText("<")
end

function EventFilterToggle_Click()
    if (Chronicles.UI.EventFilter.Displayed) then
        EventFilter:Hide()
        Chronicles.UI.EventFilter.Displayed = false
        EventFilterToggle:SetText("<")
    else
        EventFilter:Show()
        Chronicles.UI.EventFilter.Displayed = true
        EventFilterToggle:SetText(">")
    end
end
