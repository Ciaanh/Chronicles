local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.MistsofpandariaCharactersDB = {
        [53] = {
            id = 53,
            name = Locale["515_chen_stormstout"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["516_legendary_brewmaster_and_explorer_whose_wisdom_gui"]} }},
            timeline = 1,
            factions = {39}
        },
        [54] = {
            id = 54,
            name = Locale["517_aysa_cloudsinger"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["518_monk_leader_of_alliance_pandaren_who_champions_bal"]} }},
            timeline = 1,
            factions = {15, 40}
        },
        [55] = {
            id = 55,
            name = Locale["519_emperor_shaohao"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["520_ancient_pandaren_emperor_whose_legacy_and_mysterio"]} }},
            timeline = 1,
            factions = {39, 40}
        },
        [56] = {
            id = 56,
            name = Locale["521_shan_bu"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["522_mantid_leader_whose_strategies_and_swarm_pose_one_"]} }},
            timeline = 1,
            factions = {40}
        },
        [57] = {
            id = 57,
            name = Locale["523_grand_empress_shok"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["524_paramount_mantid_empress_and_ancient_adversary_of_"]} }},
            timeline = 1,
            factions = {40}
        },
        [58] = {
            id = 58,
            name = Locale["525_wrathion"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["526_black_dragon_prince_seeking_to_save_his_race_from_"]} }},
            timeline = 1,
            factions = {37}
        },
        [59] = {
            id = 59,
            name = Locale["527_vol_jin"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["528_troll_warlord_and_leader_of_the_darkspear__who_bec"]} }},
            timeline = 1,
            factions = {1}
        }
    }