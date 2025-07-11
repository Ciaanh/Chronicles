local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    SampleCharactersDB = {
        [1] = {
            id = 1,
            name = Locale["237_a_sample_character"],
            author = "Ciaanh",
            chapters = {{
                header = Locale["238_chapter_1"],
                pages = {Locale["239_page_1"]} }},
            timeline = 1,
            description = Locale["243_this_is_a_character_description"],
            image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande",
            factions = {1}
        },
        [2] = {
            id = 2,
            name = Locale["237_a_sample_character"],
            author = "Ciaanh 2",
            chapters = {{
                header = Locale["238_chapter_1"],
                pages = {Locale["239_page_1"]} }},
            timeline = 1,
            description = Locale["244_this_is_a_character_description"],
            image = "",
            factions = {1}
        }
    }