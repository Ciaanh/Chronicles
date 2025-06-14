local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Chronicles", "enUS", true, true)

if L then
    L["Chronicles"] = true
    L["Description"] = "Display Azeroth history as a timeline"
    L["Icon tooltip"] = "Click to show the timeline."
    L["CurrentYear"] = "Current year is "
    L["currentstep"] = "Step: "
    L["year"] = " year"
    L["years"] = " years"
    L["AfterDP"] = " after the Dark Portal"
    L["start"] = "Start"
    L["end"] = "End"
    L["year"] = "Year"
    L[":My Characters"] = " : my characters"
    L[":My Factions"] = " : my factions"
    L[":My Events"] = " : my events"
    L["AddPage"] = "Add page"
    L["RemovePage"] = "Remove last page"
    L["Save"] = "Save"
    L["Add"] = "Add"
    L["Delete"] = "Delete"
    L["FactionsCharacters"] = "Factions/Characters"

    L["Id_Field"] = "Id"
    L["Title_Field"] = "Title"
    L["YearStart_Field"] = "Year start"
    L["YearEnd_Field"] = "Year end"
    L["Description_Field"] = "Description"
    L["EventType_Field"] = "Event type"
    L["Timeline_Field"] = "Timeline"
    L["Name_Field"] = "Name"
    L["Biography_Field"] = "Biography"

    L["Factions_List"] = "Factions"
    L["Characters_List"] = "Characters"

    L["ErrorYearAsNumber"] = "A year must be a number"
    L["ErrorYearOrder"] = "Event ends before it's started"

    L["Mythos"] = "Mythos"
    L["Futur"] = "Futur"

    L["mythos"] = "Mythos"
    L["beforedarkportal"] = "Before the Dark Portal"
    L["threewars"] = "The Three Great Wars"
    L["vanilla"] = "Vanilla"
    L["burningcrusade"] = "The Burning Crusade"
    L["lichking"] = "Wrath of the Lich King"
    L["cataclysm"] = "Cataclysm"
    L["pandaria"] = "Mists of Pandaria"
    L["warlords"] = "Warlords of Draenor"
    L["legion"] = "Legion"
    L["battleforazeroth"] = "Battle for Azeroth"
    L["shadowlands"] = "Shadowlands"

    L["Author"] = "by "

    L["event"] = "Event"
    L["era"] = "Era"
    L["war"] = "War"
    L["battle"] = "Battle"
    L["death"] = "Death"
    L["birth"] = "Birth"
    L["other"] = "Other"

    -- Settings UI strings
    L["Configuration"] = "Configuration"
    L["Settings"] = "Settings"
    L["Event types"] = "Event types"
    L["Collections"] = "Collections"
    L["Event Types"] = "Event Types"
    L["Event Collections"] = "Event Collections"

    -- Settings descriptions and content
    L["SettingsHomeDescription"] =
        "Welcome to Chronicles settings. Use the categories on the left to configure your preferences."
    L["SettingsHomeOverviewSectionTitle"] = "Configuration Overview"
    L["SettingsHomeOverviewEventTypesInfo"] = "• Event Types: Configure which event categories appear in your timeline"
    L["SettingsHomeOverviewCollectionsInfo"] =
        "• Collections: Enable or disable content collections from different expansions"

    L["SettingsHomeQuickActionsSectionTitle"] = "Getting Started"
    L["SettingsHomeQuickActionsTip1"] = "1. Start with Event Types to customize which events you want to see"
    L["SettingsHomeQuickActionsTip2"] = "2. Use Collections to enable content from specific expansions or lore sources"

    L["SettingsHomeVersionSectionTitle"] = "About Chronicles"
    L["SettingsHomeVersionVersionInfo"] = "A comprehensive timeline addon for World of Warcraft lore and events."
    L["SettingsHomeVersionConfigNote"] = "Settings are automatically saved and will persist between sessions."

    -- Timeline zoom button text
    L["Zoom Out"] = "-"
    L["Zoom In"] = "+"
    L["EventTypesDescription"] = "Configure which types of events to display in the timeline and event lists."
    L["CollectionsDescription"] = "Enable or disable event collections to customize which content is available."
end
