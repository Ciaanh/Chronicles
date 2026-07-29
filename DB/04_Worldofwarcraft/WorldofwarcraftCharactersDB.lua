local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.WorldofwarcraftCharactersDB = {
        [32] = {
            id = 32,
            name = Locale["385_dagran_thaurissan"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["386_emperor_of_the_dark_iron_dwarves_in_blackrock_dept"]} }},
            timeline = 1,
            factions = {23}
        },
        [33] = {
            id = 33,
            name = Locale["387_moira_bronzebeard"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["388_daughter_of_magni_bronzebeard__drawn_into_the_poli"]} }},
            timeline = 1,
            factions = {15, 23}
        },
        [34] = {
            id = 34,
            name = Locale["389_baron_rivendare"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["390_a_death_knight_who_rules_over_part_of_ruined_strat"]} }},
            timeline = 1,
            factions = {13}
        },
        [35] = {
            id = 35,
            name = Locale["391_nefarian"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["392_son_of_deathwing_and_lord_of_blackwing_lair__obses"]} }},
            timeline = 1,
            factions = {25}
        },
        [36] = {
            id = 36,
            name = Locale["393_hakkar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["394_the_soulflayer__a_blood_god_worshipped_by_troll_cu"]} }},
            timeline = 1,
            factions = {26, 22}
        },
        [37] = {
            id = 37,
            name = Locale["395_c'thun"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["396_an_old_god_imprisoned_beneath_ahn'qiraj_whose_awak"]} }},
            timeline = 1,
            factions = {22, 27}
        }
    }