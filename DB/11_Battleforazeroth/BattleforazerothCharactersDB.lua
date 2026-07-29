local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.BattleforazerothCharactersDB = {
        [70] = {
            id = 70,
            name = Locale["581_king_rastakhan"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["582_long_ruling_zandalari_king_whose_death_at_dazar'al"]} }},
            timeline = 1,
            factions = {48}
        },
        [71] = {
            id = 71,
            name = Locale["583_talanji"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["584_princess_and_later_queen_of_zandalar_who_secures_h"]} }},
            timeline = 1,
            factions = {48, 1}
        },
        [72] = {
            id = 72,
            name = Locale["585_queen_azshara"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["586_naga_ruler_who_engineers_the_nazjatar_trap_and_hel"]} }},
            timeline = 1,
            factions = {51, 50}
        },
        [73] = {
            id = 73,
            name = Locale["587_n'zoth"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["588_last_free_old_god_of_azeroth__defeated_when_champi"]} }},
            timeline = 1,
            factions = {50}
        }
    }