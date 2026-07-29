local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.GreatwarsCharactersDB = {
        [2] = {
            id = 2,
            name = Locale["223_khadgar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["224_a_gifted_human_mage_who_becomes_medivh's_apprentic"]} }},
            timeline = 1,
            factions = {}
        },
        [3] = {
            id = 3,
            name = Locale["225_medivh"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["226_the_last_guardian_of_tirisfal__possessed_by_sarger"]} }},
            timeline = 1,
            factions = {}
        },
        [4] = {
            id = 4,
            name = Locale["227_garona_halforcen"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["228_a_half_orc_assassin_used_by_the_horde_and_the_shad"]} }},
            timeline = 1,
            factions = {1}
        },
        [5] = {
            id = 5,
            name = Locale["229_durotan"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["230_chieftain_of_the_frostwolf_clan_who_resists_gul'da"]} }},
            timeline = 1,
            factions = {1, 3}
        },
        [6] = {
            id = 6,
            name = Locale["231_draka"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["232_mate_of_durotan_and_mother_of_thrall__killed_along"]} }},
            timeline = 1,
            factions = {3}
        },
        [7] = {
            id = 7,
            name = Locale["233_thrall"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["234_born_during_the_first_war__thrall_survives_the_mur"]} }},
            timeline = 1,
            factions = {3}
        },
        [8] = {
            id = 8,
            name = Locale["235_orgrim_doomhammer"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["236_a_legendary_orc_warrior_who_kills_blackhand_and_be"]} }},
            timeline = 1,
            factions = {1}
        },
        [9] = {
            id = 9,
            name = Locale["237_blackhand"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["238_the_first_warchief_of_the_horde_on_azeroth__ruled_"]} }},
            timeline = 1,
            factions = {1}
        },
        [10] = {
            id = 10,
            name = Locale["239_llane_wrynn"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["240_king_of_stormwind_during_the_first_war__assassinat"]} }},
            timeline = 1,
            factions = {2}
        },
        [11] = {
            id = 11,
            name = Locale["271_anduin_lothar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["272_champion_of_stormwind_and_supreme_commander_of_the"]} }},
            timeline = 1,
            factions = {5, 6}
        },
        [12] = {
            id = 12,
            name = Locale["273_uther_lightbringer"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["274_one_of_the_first_paladins_and_founder_of_the_order"]} }},
            timeline = 1,
            factions = {7, 5}
        },
        [13] = {
            id = 13,
            name = Locale["275_gul'dan"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["276_the_most_infamous_orc_warlock__founder_of_the_shad"]} }},
            timeline = 1,
            factions = {4, 1}
        },
        [14] = {
            id = 14,
            name = Locale["277_alexstrasza"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["278_the_red_dragon_aspect_of_life__enslaved_by_the_dra"]} }},
            timeline = 1,
            factions = {8}
        },
        [15] = {
            id = 15,
            name = Locale["279_deathwing"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["280_formerly_neltharion_the_earth_warder__deathwing_ma"]} }},
            timeline = 1,
            factions = {8}
        },
        [16] = {
            id = 16,
            name = Locale["281_terenas_menethil_ii"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["282_king_of_lordaeron_and_one_of_the_principal_leaders"]} }},
            timeline = 1,
            factions = {5, 6}
        },
        [17] = {
            id = 17,
            name = Locale["283_zul'jin"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["284_warlord_of_the_amani_trolls_who_allies_with_the_ho"]} }},
            timeline = 1,
            factions = {10}
        },
        [18] = {
            id = 18,
            name = Locale["285_ner'zhul"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["286_former_elder_shaman_of_the_shadowmoon_clan_who_lat"]} }},
            timeline = 1,
            factions = {11, 12}
        },
        [19] = {
            id = 19,
            name = Locale["323_arthas_menethil"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["324_prince_of_lordaeron_who_falls_to_darkness_during_t"]} }},
            timeline = 1,
            factions = {13, 5}
        },
        [20] = {
            id = 20,
            name = Locale["325_jaina_proudmoore"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["326_powerful_archmage_and_leader_of_the_human_survivor"]} }},
            timeline = 1,
            factions = {15}
        },
        [21] = {
            id = 21,
            name = Locale["327_sylvanas_windrunner"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["328_ranger_general_of_silvermoon__slain_by_arthas_and_"]} }},
            timeline = 1,
            factions = {14, 19}
        },
        [22] = {
            id = 22,
            name = Locale["329_kel'thuzad"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["330_former_mage_of_dalaran_turned_lich__one_of_the_chi"]} }},
            timeline = 1,
            factions = {13}
        },
        [23] = {
            id = 23,
            name = Locale["331_mal'ganis"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["332_a_dreadlord_of_the_burning_legion_who_lures_arthas"]} }},
            timeline = 1,
            factions = {13, 12}
        },
        [24] = {
            id = 24,
            name = Locale["333_illidan_stormrage"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["334_night_elf_sorcerer_and_demon_hunter_whose_pursuit_"]} }},
            timeline = 1,
            factions = {17, 16}
        },
        [25] = {
            id = 25,
            name = Locale["335_kael'thas_sunstrider"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["336_prince_of_quel'thalas_who_leads_the_blood_elves_af"]} }},
            timeline = 1,
            factions = {18, 17}
        },
        [26] = {
            id = 26,
            name = Locale["337_rexxar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["338_champion_of_the_horde_who_aids_thrall_in_securing_"]} }},
            timeline = 1,
            factions = {1}
        },
        [27] = {
            id = 27,
            name = Locale["339_archimonde"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["340_one_of_the_burning_legion's_greatest_commanders__d"]} }},
            timeline = 1,
            factions = {12}
        },
        [28] = {
            id = 28,
            name = Locale["377_korialstrasz"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["378_consort_of_alexstrasza__known_in_mortal_guise_as_k"]} }},
            timeline = 1,
            factions = {20}
        },
        [29] = {
            id = 29,
            name = Locale["379_rhonin"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["380_a_mage_whose_daring_mission_to_grim_batol_becomes_"]} }},
            timeline = 1,
            factions = {15}
        },
        [30] = {
            id = 30,
            name = Locale["381_vereesa_windrunner"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["382_high_elf_ranger_and_sister_of_sylvanas__who_joins_"]} }},
            timeline = 1,
            factions = {15, 14}
        },
        [31] = {
            id = 31,
            name = Locale["383_the_lich_king"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["384_the_frozen_ruler_of_the_undead__first_born_from_ne"]} }},
            timeline = 1,
            factions = {13}
        }
    }