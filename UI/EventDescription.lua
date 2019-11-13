local FOLDER_NAME, private = ...
local Chronicles = private.Core

Chronicles.UI.EventDescription = {}

function Chronicles.UI.EventDescription:DrawEventDescription(event)
    DEFAULT_CHAT_FRAME:AddMessage("-- Call to DrawEventDescription " .. event.label)
end

function NextPage()
end

function PreviousPage()
end
