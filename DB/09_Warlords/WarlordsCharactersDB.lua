local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarlordsCharactersDB = {
        [60] = {
            id = 60,
            name = Locale["529_grommash_hellscream__alternate_timeline"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["530_in_the_alternate_timeline__grommash_leads_the_iron"]} }},
            timeline = 1,
            factions = {44, 1}
        },
        [61] = {
            id = 61,
            name = Locale["531_durotan__alternate_timeline"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["532_alternate_timeline_durotan__who_rebels_against_the"]} }},
            timeline = 1,
            factions = {3, 15}
        },
        [62] = {
            id = 62,
            name = Locale["533_yrel"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["534_draenei_vindicator_and_key_leader_whose_strength_a"]} }},
            timeline = 1,
            factions = {15, 28}
        },
        [63] = {
            id = 63,
            name = Locale["535_archimonde__alternate_timeline"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["536_in_the_alternate_timeline__archimonde_commands_the"]} }},
            timeline = 1,
            factions = {12, 42}
        }
    }