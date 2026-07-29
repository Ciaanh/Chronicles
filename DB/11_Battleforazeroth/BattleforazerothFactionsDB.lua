local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.BattleforazerothFactionsDB = {
        [48] = {
            id = 48,
            name = Locale["595_zandalari_empire"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["596_seafaring_troll_kingdom_whose_alliance_decision_be"]} }},
            timeline = 1
        },
        [49] = {
            id = 49,
            name = Locale["597_kul_tiras_admiralty"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["598_naval_command_and_fleets_of_kul_tiras_that_restore"]} }},
            timeline = 1
        },
        [50] = {
            id = 50,
            name = Locale["599_black_empire"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["600_manifest_domain_of_old_god_influence_reborn_throug"]} }},
            timeline = 1
        },
        [51] = {
            id = 51,
            name = Locale["601_nazjatar_naga"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["602_azshara's_naga_legions_controlling_nazjatar_and_ac"]} }},
            timeline = 1
        },
        [52] = {
            id = 52,
            name = Locale["603_fourth_war_coalition"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["604_cross_faction_military_coordination_formed_under_e"]} }},
            timeline = 1
        }
    }