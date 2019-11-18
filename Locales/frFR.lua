local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local L = AceLocale:NewLocale("Chronicles - Eras", "frFR", false);

if not L then return end

if L then
    L["Chronicles"] = "Chroniques"
    L["Display Azeroth history as a timeline"] = "Explorez l'histoire d'Azeroth"
    L["Click to show the timeline."] = "Cliquer pour afficher la frise chronologique."
end
