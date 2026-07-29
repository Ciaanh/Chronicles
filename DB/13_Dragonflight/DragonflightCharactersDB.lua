local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.DragonflightCharactersDB = {
        [79] = {
            id = 79,
            name = Locale["635_alexstrasza"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["636_life_binder_of_the_red_flight_who_leads_the_united"]} }},
            timeline = 1,
            factions = {57}
        },
        [80] = {
            id = 80,
            name = Locale["637_raszageth"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["638_storm_incarnate_whose_release_triggers_the_first_p"]} }},
            timeline = 1,
            factions = {58}
        },
        [81] = {
            id = 81,
            name = Locale["639_iridikron"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["640_cunning_earth_incarnate_who_pursues_long_term_plan"]} }},
            timeline = 1,
            factions = {58}
        },
        [82] = {
            id = 82,
            name = Locale["641_vyranoth"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["642_frost_incarnate_whose_stance_shifts_over_the_campa"]} }},
            timeline = 1,
            factions = {58, 57}
        },
        [83] = {
            id = 83,
            name = Locale["643_fyrakk"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["644_flame_incarnate_empowered_by_shadowflame__ultimate"]} }},
            timeline = 1,
            factions = {58}
        }
    }