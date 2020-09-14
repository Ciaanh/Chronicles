local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.OtherView = {}
Chronicles.UI.OtherView.Displayed = false

function Chronicles.UI.EventView:Show()
    EventView:Hide()
    OtherView:Show()
end

function OtherViewToggle_Click()
    if (Chronicles.UI.OtherView.Displayed) then
        OtherView:Hide()
        EventView:Show()
        Chronicles.UI.OtherView.Displayed = false
        OtherViewToggle:SetText("Other")
    else
        EventView:Hide()
        OtherView:Show()
        Chronicles.UI.OtherView.Displayed = true
        OtherViewToggle:SetText("Events")
    end
end

function OtherViewToggle_SetText(self)
    self:SetText("Other")
end
