local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Chronicles - Eras", "frFR", false)

if not L then
    return
end

if L then
    L["Chronicles"] = "Chroniques"
    L["Description"] = "Explorez l'histoire d'Azeroth"
    L["Icon tooltip"] = "Cliquer pour afficher la frise chronologique."
end
