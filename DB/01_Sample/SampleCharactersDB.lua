local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.DB.Modules
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
            description = nil,
            image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande",
            factions = {1}
        }
    }