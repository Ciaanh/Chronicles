local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventDescription = {}


function Chronicles.UI.EventDescription:DrawEventDescription(event)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to DrawEventDescription " .. event.label)

    EventDescriptionHTML.text = event.Description[1]
end


function Chronicles.UI.EventDescription:ChangeEventDescriptionPage(page)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to ChangeEventDescriptionPage ")
end

------------------------------------------------------------------------------------------
-- Description Paging --------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventDescriptionPreviousButton_OnClick(self)
    Chronicles.UI.EventDescription:ChangeEventDescriptionPage(Chronicles.SelectedValues.currentEventDescriptionPage - 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventDescriptionNextButton_OnClick(self)
    Chronicles.UI.EventDescription:ChangeEventDescriptionPage(Chronicles.SelectedValues.currentEventDescriptionPage + 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

