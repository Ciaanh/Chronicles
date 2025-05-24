local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.Custom.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    FutureEventsDB = {
        [102] = {
            id=102,
            label=Locale["226_oh_mon_bateau"],
            chapters={{
                header = Locale["223_header"],
                pages = {Locale["224_page_1"], Locale["225_2_page"]} }},
            yearStart=46,
            yearEnd=47,
            eventType=3,
            timeline=2,
            order=0,
            characters={},
            factions={},
        }
    }