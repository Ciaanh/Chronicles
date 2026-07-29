local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.WarwithinFactionsDB = {
        [61] = {
            id = 61,
            name = Locale["673_assembly_of_the_deeps"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["674_coalition_of_khaz_algar's_deep_dwelling_allies_coo"]} }},
            timeline = 1
        },
        [62] = {
            id = 62,
            name = Locale["675_hallowfall_arathi"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["676_the_isolated_arathi_host_of_hallowfall__now_rejoin"]} }},
            timeline = 1
        },
        [63] = {
            id = 63,
            name = Locale["677_nerubian_ascendancy"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["678_militarized_nerubian_forces_pushing_from_subterran"]} }},
            timeline = 1
        },
        [64] = {
            id = 64,
            name = Locale["679_void_lords"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["680_transcendent_entities_of_the_void_whose_long_desig"]} }},
            timeline = 1
        }
    }