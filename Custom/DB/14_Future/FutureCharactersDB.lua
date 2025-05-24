local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.Custom.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    FutureCharactersDB = {
        [2] = {
            id = 2,
            name = Locale["228_lc2"],
            chapters = {{
                header = Locale[""],
                pages = {Locale["229_bc2"]} }},
            timeline = 1,
            factions = {}
        }
    }