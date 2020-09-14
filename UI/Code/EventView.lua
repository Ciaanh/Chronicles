local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventView = {}

function Chronicles.UI.EventView:Show()
    OtherView:Hide()
    EventView:Show()
end
