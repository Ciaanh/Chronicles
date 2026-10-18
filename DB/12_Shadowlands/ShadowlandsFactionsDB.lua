local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.ShadowlandsFactionsDB = {
        [53] = {
            id = 53,
            name = Locale["645_covenants_of_death"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["646_the_major_powers_of_the_shadowlands_that_unite_to_"]} }},
            timeline = 1
        },
        [54] = {
            id = 54,
            name = Locale["647_mawsworn"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["648_domination_forged_armies_serving_the_jailer__centr"]} }},
            timeline = 1
        },
        [55] = {
            id = 55,
            name = Locale["649_brokers_cartels"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["650_interdimensional_traders_and_schemers_whose_knowle"]} }},
            timeline = 1
        },
        [56] = {
            id = 56,
            name = Locale["651_maldraxxus_legions"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["652_necrolord_war_hosts_reorganized_under_the_primus_t"]} }},
            timeline = 1
        }
    }