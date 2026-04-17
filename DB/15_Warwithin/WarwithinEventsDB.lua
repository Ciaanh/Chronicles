local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    WarwithinEventsDB = {
        [101] = {
            id=101,
            label=Locale["207_the_fall_of_dalaran"],
            chapters={{
                header = Locale[""],
                pages = {Locale["208_the_fall_of_dalaran_caused_by_an_attack_of_xal'ata"]} }},
            yearStart=42,
            yearEnd=42,
            eventType=4,
            timeline=1,
            order=0,
            characters={},
            factions={},
        },
        [185] = {
            id=185,
            label=Locale["661_earthen_unrest_in_khaz_algar"],
            chapters={{
                header = Locale[""],
                pages = {Locale["662_as_tensions_erupt_beneath_azeroth__earthen_powers_"]} }},
            yearStart=42,
            yearEnd=42,
            eventType=2,
            timeline=1,
            order=1,
            characters={["greatwars"] = {7}, ["legion"] = {65}, ["warwithin"] = {86}},
            factions={["warwithin"] = {61, 62, 63}},
        },
        [186] = {
            id=186,
            label=Locale["663_xal'atath_reveals_her_design"],
            chapters={{
                header = Locale[""],
                pages = {Locale["664_xal'atath_steps_into_the_open_and_binds_void_align"]} }},
            yearStart=42,
            yearEnd=42,
            eventType=3,
            timeline=1,
            order=2,
            characters={["legion"] = {65}, ["warwithin"] = {84, 85}},
            factions={["warwithin"] = {64, 63, 61}},
        },
        [187] = {
            id=187,
            label=Locale["665_counterstrike_at_beledar"],
            chapters={{
                header = Locale[""],
                pages = {Locale["666_allied_champions_launch_a_counteroffensive_around_"]} }},
            yearStart=42,
            yearEnd=42,
            eventType=4,
            timeline=1,
            order=3,
            characters={["legion"] = {65}, ["warwithin"] = {85, 84}},
            factions={["legion"] = {47}, ["warwithin"] = {62, 61, 64}},
        }
    }