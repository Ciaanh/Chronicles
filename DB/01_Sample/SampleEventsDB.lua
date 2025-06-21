local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.DB.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

    SampleEventsDB = {
        [103] = {
            id=103,
            label=Locale["233_sample_event_for_demo"],
            chapters={{
                header = Locale["234_header_1"],
                pages = {Locale["235_this_is_an_example_event__this_page_uses_only_text"], Locale["236_<html><body><h1>|cff0000ff_html_demo__blue_h1|r<_h"]} }},
            yearStart=0,
            yearEnd=42,
            eventType=2,
            timeline=1,
            order=0,
            characters={},
            factions={},
        }
    }