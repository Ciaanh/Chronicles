local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    LegionFactionsDB = {
        [45] = {
            id = 45,
            name = Locale["589_illidari_reforged"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["590_demon_hunter_forces_reorganized_under_illidan_to_w"]} }},
            timeline = 1
        },
        [46] = {
            id = 46,
            name = Locale["591_armies_of_legionfall"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["592_coalition_of_class_orders_and_allies_assembled_to_"]} }},
            timeline = 1
        },
        [47] = {
            id = 47,
            name = Locale["593_army_of_the_light"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["594_ancient_resistance_forged_by_the_naaru_and_their_a"]} }},
            timeline = 1
        }
    }