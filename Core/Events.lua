local FOLDER_NAME, private = ...
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Core.Events = {}

--  Event
--  id = [integer]					-- Id of the event
-- 	label = [string]				--
-- 	description = { [string] }		-- descriptions
-- 	chapters = { [chapter] }		--
-- 	yearStart = [integer]			--
-- 	yearEnd = [integer]				--
-- 	eventType = [integer]			--
-- 	timeline = [integer]			-- id of the timeline
-- 	order = [integer]				--
-- 	characters = { [character] }	--
-- 	factions = { [faction] }		--
--  author = [string]				-- Author of the event

--  Chapter
--  header = [integer]				-- Title of the chapter
-- 	pages = { [string] }			-- Content of the chapter, either text or HTML
-----------------------------------------------------------------------------------------
-- Events Details -----------------------------------------------------------------------
-----------------------------------------------------------------------------------------
local function CreateChapter(title, pages)
	local chapter = {elements = {}}

	if (title ~= nil) then
		-- print(title)
		chapter.header = {
			templateKey = "HEADER",
			text = title
		}
	end

	for key, text in pairs(pages) do
		--print(text)
		if (containsHTML(text)) then
			table.insert(
				chapter.elements,
				{
					templateKey = "HTMLCONTENT",
					text = cleanHTML(text)
				}
			)
		else
			-- transform text => adjust line to width
			-- then for each line add itemEntry
			local lines = SplitTextToFitWidth(text, private.constants.viewWidth)
			for i, value in ipairs(lines) do
				local line = {
					templateKey = "TEXTCONTENT",
					text = value
				}

				table.insert(chapter.elements, line)
			end
		end
	end

	return chapter
end

function private.Core.Events.TransformEventToBook(event)
	if (event ~= nil) then
		local data = {}

		local title = {
			header = {
				templateKey = "TITLE",
				text = event.label,
				yearStart = event.yearStart,
				yearEnd = event.yearEnd
			},
			elements = {}
		}

		local author = ""
		if (event.author ~= nil) then
			author = Locale["Author"] .. event.author
		end

		table.insert(
			title.elements,
			{
				templateKey = "AUTHOR",
				text = author
			}
		)
		table.insert(data, title)

		-- local descriptionLength = #event.description
		local chaptersLength = #event.chapters
		if chaptersLength <= 0 then
			for key, description in pairs(event.description) do
				local chapter = CreateChapter(nil, {description})
				table.insert(data, chapter)
			end
		else
			for key, chapter in pairs(event.chapters) do
				local bookChapter = CreateChapter(chapter.header, chapter.pages)
				table.insert(data, bookChapter)
			end
		end

		return data
	end
end

-- local textToDisplay =
-- 	"The orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses.\n\nNer'zhul's apprehension about the war with the draenei grows. \nKil'jaeden appears to him in the form of Rulkan and tells him of powerful beings who could aid the orcs, and the night after Kil'jaeden appears again as a radiant elemental entity and urges him to push the Horde to victory and exterminate the draenei. \n\nNer'zhul secretly embarks on a journey to Oshu'gun to seek the guidance of the ancestors, but Kil'jaeden is aware of his plans and tells Gul'dan to gather allies to control the Shadowmoon, since Ner'zhul can no longer be relied upon. Gul'dan recruits Teron'gor and several other shaman and begin teaching them fel magic.\n\nAt Oshu'gun, the real Rulkan and the other ancestors tell Ner'zhul that he was being manipulated by Kil'jaeden and condemn the shaman for having been used by the demon lord. \n\nNer'zhul falls into despair and is captured by Gul'dan's followers, who treat him as little more than a slave.\nThe orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses."

-- local textToDisplayHTML =
-- 	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

-- local textToDisplayHTMLlong =
-- 	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

function private.Core.Events.FilterEvents(events)
	local foundEvents = {}
	for eventIndex in pairs(events) do
		local event = events[eventIndex]

		local eventGroupStatus = private.Chronicles.DB:GetGroupStatus(event.source)
		local eventTypeStatus = private.Chronicles.DB:GetEventTypeStatus(event.eventType)

		if eventGroupStatus and eventTypeStatus then
			table.insert(foundEvents, event)
		end
	end

	table.sort(
		foundEvents,
		function(a, b)
			if (a.yearStart == b.yearStart) then
				return a.order < b.order
			end
			return a.yearStart < b.yearStart
		end
	)
	return foundEvents
end
