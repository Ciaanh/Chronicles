local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.LegionCharactersDB = {
        [64] = {
            id = 64,
            name = Locale["569_varian_wrynn"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["570_high_king_of_the_alliance_whose_final_stand_at_the"]} }},
            timeline = 1,
            factions = {15}
        },
        [65] = {
            id = 65,
            name = Locale["571_anduin_wrynn"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["572_successor_to_varian_and_king_of_stormwind__anduin_"]} }},
            timeline = 1,
            factions = {15, 52}
        },
        [66] = {
            id = 66,
            name = Locale["573_sylvanas_windrunner"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["574_former_banshee_queen_who_becomes_warchief_after_vo"]} }},
            timeline = 1,
            factions = {1}
        },
        [67] = {
            id = 67,
            name = Locale["575_illidan_stormrage"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["576_leader_of_the_illidari_whose_campaign_against_the_"]} }},
            timeline = 1,
            factions = {45, 47}
        },
        [68] = {
            id = 68,
            name = Locale["577_kil'jaeden"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["578_demonic_commander_of_the_burning_legion_defeated_d"]} }},
            timeline = 1,
            factions = {12}
        },
        [69] = {
            id = 69,
            name = Locale["579_sargeras"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["580_fallen_titan_and_master_of_the_legion__finally_bou"]} }},
            timeline = 1,
            factions = {12}
        }
    }