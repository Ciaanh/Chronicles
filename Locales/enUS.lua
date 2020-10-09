local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Chronicles", "enUS", true, true)

if L then
    L["Chronicles"] = true
    L["Description"] = "Display Azeroth history as a timeline"
    L["Icon tooltip"] = "Click to show the timeline."
    L["start"] = "Start"
    L["end"] = "End"
    L["year"] = "Year"
    L[":My Characters"] = " : my characters"
    L[":My Factions"] = " : my factions"
    L[":My Events"] = " : my events"
    L["AddPage"] = "Add page"
    L["RemovePage"] = "Remove last page"
    L["Save"] = "Save"

    L["AddEvent"] = "Add event"
    L["RemoveEvent"] = "Remove event"

    L["Id_Field"] = "Id"
    L["Title_Field"] = "Title"
    L["YearStart_Field"] = "Year start"
    L["YearEnd_Field"] = "Year end"
    L["Description_Field"] = "Description"
    L["EventType_Field"] = "Event type"
    L["Timeline_Field"] = "Timeline"
    L["Name_Field"] = "Name"
    L["Biography_Field"] = "Biography"

    L["ErrorYearAsNumber"] = "A year must be a number"
    L["ErrorYearOrder"] = "Event ends before it's started"
end
