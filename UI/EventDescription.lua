local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventDescription = {}

function Chronicles.UI.EventDescription:DrawEventDescription(event)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to DrawEventDescription " .. event.label)
end

function Chronicles.UI.EventDescription:DisplayEventDescription()
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to DisplayEventDescription ")
end

------------------------------------------------------------------------------------------
-- Description Paging --------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventDescriptionPreviousButton_OnClick(self)
    Chronicles.SelectedValues.currentEventDescriptionPage =
        Chronicles.SelectedValues.currentEventDescriptionPage - 1

    Chronicles.UI.EventDescription:DisplayEventDescription()
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function EventDescriptionNextButton_OnClick(self)
    Chronicles.SelectedValues.currentEventDescriptionPage =
        Chronicles.SelectedValues.currentEventDescriptionPage + 1

    Chronicles.UI.EventDescription:DisplayEventDescription()
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end
