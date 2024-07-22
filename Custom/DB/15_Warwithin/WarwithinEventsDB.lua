local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.Custom.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarwithinEventsDB = {
        [101] = {
            id=101,
			label=Locale["207_the_fall_of_dalaran"],
			description={Locale["208_the_fall_of_dalaran_caused_by_an_attack_of_xal'ata"]},
            chapters={},
			yearStart=42,
			yearEnd=42,
			eventType=4,
			timeline=1,
			order=0,
			characters={},
            factions={},
		}
    }