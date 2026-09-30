local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.DB = private.DB or {}
private.DB.FutureEventsDB = {
        [188] = {
            id=188,
            label=Locale["681_azeroth's_worldsoul_resonance"],
            chapters={{
                header = Locale[""],
                pages = {Locale["682_worldsoul_pulses_intensify_across_azeroth__forcing"]} }},
            yearStart=43,
            yearEnd=43,
            eventType=2,
            timeline=1,
            order=0,
            characters={["legion"] = {65}, ["future"] = {87}},
            factions={["legion"] = {47}, ["future"] = {65}, ["warwithin"] = {61}},
        },
        [189] = {
            id=189,
            label=Locale["683_void_rift_campaigns"],
            chapters={{
                header = Locale[""],
                pages = {Locale["684_coordinated_void_breaches_erupt_across_key_strongh"]} }},
            yearStart=43,
            yearEnd=43,
            eventType=3,
            timeline=1,
            order=1,
            characters={["future"] = {87}, ["warwithin"] = {85, 84}},
            factions={["legion"] = {47}, ["future"] = {66}, ["warwithin"] = {64}},
        },
        [190] = {
            id=190,
            label=Locale["685_council_of_the_last_dawn"],
            chapters={{
                header = Locale[""],
                pages = {Locale["686_a_final_war_council_forms_between_rival_factions_a"]} }},
            yearStart=44,
            yearEnd=44,
            eventType=1,
            timeline=1,
            order=2,
            characters={["legion"] = {65}, ["future"] = {88}, ["warwithin"] = {85}},
            factions={["greatwars"] = {15, 1}, ["legion"] = {47}, ["future"] = {65, 66}},
        }
    }