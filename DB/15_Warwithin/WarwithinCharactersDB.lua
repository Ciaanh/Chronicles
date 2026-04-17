local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarwithinCharactersDB = {
        [1] = {
            id = 1,
            name = Locale["209_test_text"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["210_test_bio_text"]} }},
            timeline = 1,
            factions = {}
        },
        [84] = {
            id = 84,
            name = Locale["667_xal'atath"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["668_the_harbinger_and_architect_of_void_plots_in_khaz_"]} }},
            timeline = 1,
            factions = {64}
        },
        [85] = {
            id = 85,
            name = Locale["669_alleria_windrunner"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["670_void_touched_ranger_whose_insight_and_discipline_a"]} }},
            timeline = 1,
            factions = {47, 62}
        },
        [86] = {
            id = 86,
            name = Locale["671_faerin_lothar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["672_arathi_champion_of_hallowfall_who_rallies_local_re"]} }},
            timeline = 1,
            factions = {62, 61}
        }
    }