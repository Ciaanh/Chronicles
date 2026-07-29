local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Chronicles", "enUS", true, true)

if L then
    L["Chronicles"] = true
    L["Description"] = "Display Azeroth history as a timeline"
    L["Icon tooltip"] = "Click to show the timeline."
    L["CurrentYear"] = "Current year is "
    L["years"] = " years"
    L["AfterDP"] = " after the Dark Portal"

    -- Date Search Localization
    L["Enter year..."] = "Enter year..."
    L["Go"] = "Go"
    L["Invalid year format. Please enter a number (e.g., -10000, 25, 2024)"] =
        "Invalid year format. Please enter a number (e.g., -10000, 25, 2024)"
    L["Year must be between %d and %d"] = "Year must be between %d and %d"
    L["Found %d events for year %d"] = "Found %d events for year %d"
    L["No events found for year %d"] = "No events found for year %d"

    L["Mythos"] = "Mythos"
    L["Futur"] = "Futur"

    -- Collection display names. Resolved dynamically as Locale[collectionName]
    -- (UI/Settings/Settings.lua), so no literal lookup exists for these keys -- a
    -- search for unreferenced strings will wrongly flag every one of them. Keys must
    -- match the names registered in DB\DB.lua.
    L["Expansions"] = "Expansions"
    L["Origins"] = "Origins"
    L["Greatwars"] = "The Great Wars"
    L["Worldofwarcraft"] = "World of Warcraft"
    L["Burningcrusade"] = "The Burning Crusade"
    L["Lichking"] = "Wrath of the Lich King"
    L["Cataclysm"] = "Cataclysm"
    L["Mistsofpandaria"] = "Mists of Pandaria"
    L["Warlords"] = "Warlords of Draenor"
    L["Legion"] = "Legion"
    L["Battleforazeroth"] = "Battle for Azeroth"
    L["Shadowlands"] = "Shadowlands"
    L["Dragonflight"] = "Dragonflight"
    L["Future"] = "Future"
    L["Warwithin"] = "The War Within"

    -- Event type display names, likewise resolved dynamically as Locale[eventTypeName]
    -- from private.constants.eventType. Adding a type there needs a key here.
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
    L["SettingsHomeQuickActionsTip3"] = "3. Open the timeline with /chronicles or the minimap button to explore events"
    L["SettingsHomeVersionSectionTitle"] = "About Chronicles"
    L["SettingsHomeVersionVersionInfo"] = "A comprehensive timeline addon for World of Warcraft lore and events."
    L["SettingsHomeVersionConfigNote"] = "Settings are automatically saved and will persist between sessions."

    -- Search functionality
    L["SearchPlaceholder"] = "Search..."
    L["SearchCharactersPlaceholder"] = "Search Characters..."
    L["SearchFactionsPlaceholder"] = "Search Factions..."

    -- Vertical list count labels. Pluralisation is not modelled: every collection large enough to
    -- reach a rail has more than one entry.
    L["ListCountItems"] = "%d items"
    L["ListCountCharacters"] = "%d Characters"
    L["ListCountFactions"] = "%d Factions"

    -- List item tooltips
    L["TooltipDefaultItemName"] = "Item"
    L["TooltipChapterCount"] = "Available Content: %d chapters"
    L["TooltipCreatedBy"] = "Created by: %s"
    L["TooltipAllegiance"] = "Allegiance: %s"
    L["TooltipRace"] = "Race: %s"

    -- Book view
    L["NoContentAvailable"] = "No content available"
    L["BookEmptyPromptEvent"] = "Select an event from the timeline or the list to read its chronicle."
    L["BookEmptyPromptCharacter"] = "Select a character from the list to read their chronicle."
    L["BookEmptyPromptFaction"] = "Select a faction from the list to read its chronicle."

    -- Timeline toolbar button glyphs, and the separator in the visible-range readout
    L["Zoom Out"] = "-"
    L["Zoom In"] = "+"
    L["Previous Page"] = "<"
    L["Next Page"] = ">"
    L["RangeSeparator"] = " to "
    L["EventTypesDescription"] = "Configure which types of events to display in the timeline and event lists."
    L["CollectionsDescription"] = "Enable or disable event collections to customize which content is available."

    -- Book / HTMLBuilder localization
    -- Title and structure
    L["BOOK_CONTENTS_TITLE"] = "Contents"
    L["BOOK_CHAPTER_N"] = "Chapter %d"
    L["BOOK_CHAPTER_HEADER"] = "Chapter %d: %s"
    L["BOOK_UNTITLED"] = "Untitled"
    -- Errors
    L["BOOK_ERROR_TITLE"] = "Error"
    L["BOOK_ERROR_NO_ENTITY"] = "No entity data provided"
    L["BOOK_ERROR_UNKNOWN"] = "Unknown error occurred"
    L["BOOK_ERROR_NO_CONTENT_DATA"] = "No content data provided"
    L["BOOK_ERROR_NO_HTML"] = "No HTML content provided"
    L["BOOK_ERROR_NO_DISPLAY"] = "HTML display component not found"
    L["BOOK_NO_CONTENT"] = "No content available."
    -- Dates
    L["BOOK_DATE_YEAR"] = "Year %d"
    L["BOOK_DATE_YEARS_RANGE"] = "Years %d - %d"
    L["BOOK_DATE_FROM_YEAR"] = "From Year %d"
    L["BOOK_DATE_UNTIL_YEAR"] = "Until Year %d"
end
