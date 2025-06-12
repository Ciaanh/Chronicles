local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.DB.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarwithinCharactersDB = {
        [1] = {
            id = 1,
            name = Locale["209_test_text"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["210_test_bio_text"]} }},
            timeline = 1,
            factions = {}
        }
    }