local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarlordsFactionsDB = {
        [41] = {
            id = 41,
            name = Locale["541_iron_horde"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["542_alternate_timeline_orcish_empire_unified_under_gro"]} }},
            timeline = 1
        },
        [42] = {
            id = 42,
            name = Locale["543_shadowmoon_clan__alternate"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["544_alternate_timeline_shadowmoon_clan__corrupted_and_"]} }},
            timeline = 1
        },
        [43] = {
            id = 43,
            name = Locale["545_draenei_of_draenor__alternate"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["546_alternate_timeline_draenei_survivors__caught_betwe"]} }},
            timeline = 1
        },
        [44] = {
            id = 44,
            name = Locale["547_blackrock_clan__alternate"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["548_alternate_timeline_blackrock_clan__primary_threat_"]} }},
            timeline = 1
        }
    }