local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.DB.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    SampleFactionsDB = {
        [1] = {
            id = 1,
            name = Locale["240_the_sample_faction"],
            author = "Ciaanh",
            chapters = {{
                header = Locale["241_chapter_1"],
                pages = {Locale["242_page_1"]} }},
            timeline = 1,
            description = nil,
            image = nil
        }
    }