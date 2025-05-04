local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-----------------------------------------------------------------------------------------
-- CharacterList -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
CharacterListMixin = {}

function CharacterListMixin:OnLoad()
    -- self.Previous:SetScript("OnClick", self.TimelinePrevious)
    -- self.Next:SetScript("OnClick", self.TimelineNext)

    -- EventRegistry:RegisterCallback(private.constants.events.TimelineInit, self.OnTimelineInit, self)

    -- EventRegistry:RegisterCallback(
    --     private.constants.events.TimelinePreviousButtonVisible,
    --     self.OnTimelinePreviousVisible,
    --     self
    -- )
    -- EventRegistry:RegisterCallback(private.constants.events.TimelineNextButtonVisible, self.OnTimelineNextVisible, self)
    -- EventRegistry:RegisterCallback(private.constants.events.TimelineStepChanged, self.OnTimelineStepChanged, self)
end