local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.LichkingCharactersDB = {
        [43] = {
            id = 43,
            name = Locale["443_bolvar_fordragon"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["444_alliance_commander_at_wrathgate_who_ultimately_bec"]} }},
            timeline = 1,
            factions = {15, 32}
        },
        [44] = {
            id = 44,
            name = Locale["445_darion_mograine"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["446_leader_of_the_knights_of_the_ebon_blade_and_a_majo"]} }},
            timeline = 1,
            factions = {33, 32}
        },
        [45] = {
            id = 45,
            name = Locale["447_tirion_fordring"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["448_highlord_of_the_argent_crusade_who_unites_azeroth'"]} }},
            timeline = 1,
            factions = {32, 15}
        },
        [46] = {
            id = 46,
            name = Locale["449_brann_bronzebeard"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["450_explorer_and_loremaster_whose_discoveries_in_north"]} }},
            timeline = 1,
            factions = {15, 34}
        },
        [47] = {
            id = 47,
            name = Locale["451_yogg_saron"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["452_an_old_god_imprisoned_beneath_ulduar__whose_whispe"]} }},
            timeline = 1,
            factions = {34, 13}
        }
    }