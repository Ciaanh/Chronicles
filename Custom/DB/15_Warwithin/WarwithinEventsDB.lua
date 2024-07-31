local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local modules = Chronicles.Custom.Modules
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

WarwithinEventsDB = {
	[101] = {
		id = 101,
		label = Locale["207_the_fall_of_dalaran"],
		description = {Locale["208_the_fall_of_dalaran_caused_by_an_attack_of_xal'ata"]},
		chapters = {
			{
				header = "Chapter 1",
				pages = {
					'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'
				}
			},
			{
				header = "Chapter 2",
				pages = {
					'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>',
					'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'
				}
			}
		},
		yearStart = 42,
		yearEnd = 42,
		eventType = 4,
		timeline = 1,
		order = 0,
		characters = {},
		factions = {}
	}
}

-- local textToDisplayHTML =
-- 	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

-- local textToDisplayHTMLlong =
-- 	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'
