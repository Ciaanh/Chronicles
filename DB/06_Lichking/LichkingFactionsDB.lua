local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.LichkingFactionsDB = {
        [32] = {
            id = 32,
            name = Locale["461_argent_crusade"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["462_order_founded_to_unite_anti_scourge_forces_in_nort"]} }},
            timeline = 1
        },
        [33] = {
            id = 33,
            name = Locale["463_knights_of_the_ebon_blade"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["464_former_death_knights_who_rebelled_against_the_lich"]} }},
            timeline = 1
        },
        [34] = {
            id = 34,
            name = Locale["465_titan_forged_of_ulduar"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["466_the_keepers_and_constructs_of_ulduar__central_to_t"]} }},
            timeline = 1
        }
    }