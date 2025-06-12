local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.DB.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    FutureFactionsDB = {
        [1] = {
            id = 1,
            name = Locale["230_this_is_a_label"],
            author = "Ciaanh",
            chapters = {{
                header = Locale["231_h1"],
                pages = {Locale["232_p@"]} }},
            timeline = 1
        }
    }