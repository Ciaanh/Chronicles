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

    -- Settings feedback. The Settings landing page and its overview, tips and version blocks are gone:
    -- "Settings" is the panel's header now rather than a category, so the only two categories are the
    -- two that configure something.
    L["SettingsEventTypeCount"] = "%s — %d events"
    L["SettingsTimelineNowEmpty"] = "No events left on the current timeline page."

    -- Search functionality
    L["SearchPlaceholder"] = "Search..."
    L["SearchCharactersPlaceholder"] = "Search Characters..."
    L["SearchFactionsPlaceholder"] = "Search Factions..."
    -- Scoped to the selected period, which is why it does not say "Search Events"
    L["SearchEventsPlaceholder"] = "Search this period..."

    -- Vertical list count labels. Pluralisation is not modelled: every collection large enough to
    -- reach a rail has more than one entry.
    L["ListCountItems"] = "%d items"
    L["ListCountCharacters"] = "%d Characters"
    L["ListCountFactions"] = "%d Factions"
    L["ListCountEvents"] = "%d Events"

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
    L["TimelineYearLabel"] = "Year %d"

    -- Timeline density legend and period tooltips. The legend labels are format strings filled from
    -- config.timeline.densityTiers: the thresholds must never be written out here, or the legend becomes
    -- a second, drifting copy of the ladder the crystals actually use.
    L["TimelineDensityLegendUnder"] = "< %d"
    L["TimelineDensityLegendOver"] = "%d+"
    L["TimelinePeriodTooltipSpan"] = "Years %d to %d"
    L["TimelinePeriodTooltipCount"] = "%d events"
    L["TimelinePeriodTooltipMore"] = "and %d more"
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
    -- Front matter: the left page of the spread, carrying the entity's identity and its cross-references
    L["BOOK_FRONT_FACTIONS"] = "Factions"
    L["BOOK_FRONT_CHARACTERS"] = "Characters"
    -- Joins the metadata parts and the names in each reference list. Also the gap before a contents
    -- row's page number.
    L["BOOK_FRONT_META_SEPARATOR"] = " · "
    L["BOOK_FRONT_MORE"] = "+ %d more"
    L["BOOK_CONTENTS_PAGE_N"] = "%d"
    -- Empty book state, before the reader has selected anything
    L["BOOK_EMPTY_COLLECTIONS"] = "%d collections"
    L["BOOK_EMPTY_ENTITIES"] = "%d entries"
    -- Dates
    L["BOOK_DATE_YEAR"] = "Year %d"
    L["BOOK_DATE_YEARS_RANGE"] = "Years %d - %d"
    L["BOOK_DATE_FROM_YEAR"] = "From Year %d"
    L["BOOK_DATE_UNTIL_YEAR"] = "Until Year %d"
end
