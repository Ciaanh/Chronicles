local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.FutureCharactersDB = {
        [87] = {
            id = 87,
            name = Locale["687_magni_bronzebeard__speaker"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["688_still_attuned_to_azeroth's_voice__magni_coordinate"]} }},
            timeline = 1,
            factions = {65}
        },
        [88] = {
            id = 88,
            name = Locale["689_algalon_the_observer__return"],
            author = "",
            chapters = {{
                header = Locale[""],
                pages = {Locale["690_the_observer_returns_to_evaluate_azeroth's_surviva"]} }},
            timeline = 1,
            factions = {65, 47}
        }
    }