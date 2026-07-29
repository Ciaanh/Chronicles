local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.CataclysmFactionsDB = {
        [35] = {
            id = 35,
            name = Locale["487_twilight's_hammer"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["488_doomsday_cult_serving_the_old_gods__active_across_"]} }},
            timeline = 1
        },
        [36] = {
            id = 36,
            name = Locale["489_earthen_ring"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["490_shamanic_order_led_by_thrall_in_the_effort_to_heal"]} }},
            timeline = 1
        },
        [37] = {
            id = 37,
            name = Locale["491_dragon_aspects_united"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["492_the_combined_strength_of_azeroth's_dragon_aspects_"]} }},
            timeline = 1
        },
        [38] = {
            id = 38,
            name = Locale["493_elemental_lords"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["494_primal_rulers_of_elemental_planes__whose_upheaval_"]} }},
            timeline = 1
        }
    }