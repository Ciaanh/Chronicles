local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Chronicles", "enUS", true, true)

if L then
    L["Chronicles"] = true
    L["Description"] = "Display Azeroth history as a timeline"
    L["Icon tooltip"] = "Click to show the timeline."

    L["Dark Portal label"] = "Opening of the Dark Portal"
    L["Dark Portal page 1"] = "Medivh, corrupted by Sargeras opened the Dark Portal allowing the orcs to enter Azeroth. page 1"
    L["Dark Portal page 2"] = "The orcs began to invase the Eastern Kingdom, starting the first war. page 2"
end
