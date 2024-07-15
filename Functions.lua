function Trim(s)
	return s:match("^%s*(.-)%s*$")
end

-- Create a hidden frame for measuring text width
local measureFrame = CreateFrame("Frame", nil, UIParent)
measureFrame:Hide()
local measureText = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
measureText:SetPoint("LEFT")

-- Function to split text into lines that fit within a given width
function SplitTextToFitWidth(textToSplit, width)
	local text = textToSplit:gsub("\n", " \n ")
	text = text:gsub("  ", " ")

	local words = {strsplit(" ", text)}
	local lines = {}
	local line = "<tab>"

	for i, word in ipairs(words) do
		if word == "\n" then
			line = Trim(line):gsub("<tab>", "  ")
			table.insert(lines, line)
			line = "<tab>"
		else
			measureText:SetText(line .. " " .. word)

			if measureText:GetStringWidth() > width then
				line = Trim(line):gsub("<tab>", "  ")
				table.insert(lines, line)
				line = word
			else
				line = line .. " " .. word
			end
		end
	end

	table.insert(lines, line)

	return lines
end

local s_passThroughClosureGenerators = {
	function(f)
		return function(...)
			return f(...)
		end
	end,
	function(f, a)
		return function(...)
			return f(a, ...)
		end
	end,
	function(f, a, b)
		return function(...)
			return f(a, b, ...)
		end
	end,
	function(f, a, b, c)
		return function(...)
			return f(a, b, c, ...)
		end
	end,
	function(f, a, b, c, d)
		return function(...)
			return f(a, b, c, d, ...)
		end
	end,
	function(f, a, b, c, d, e)
		return function(...)
			return f(a, b, c, d, e, ...)
		end
	end
}
function GenerateClosureInternal(generatorArray, f, ...)
	local count = select("#", ...)
	local generator = generatorArray[count + 1]
	if generator then
		return generator(f, ...)
	end

	assertsafe("Closure generation does not support more than " .. (#generatorArray - 1) .. " parameters")
	return nil
end

-- Syntactic sugar for function(...) return f(a, b, c, ...); end
function GenerateClosure(f, ...)
	return GenerateClosureInternal(s_passThroughClosureGenerators, f, ...)
end

function cleanHTML(text)
	if (text ~= nil) then
		text = string.gsub(text, "||", "|")
		text = string.gsub(text, "\\\\", "\\")
	else
		text = ""
	end
	return text
end

function containsHTML(text)
	if (string.lower(text):find("<html>") == nil) then
		return false
	else
		return true
	end
end

function adjust_value(value, step)
	local valueFloor = math.floor(value)
	local valueMiddle = valueFloor + (step / 2)

	if (value < valueMiddle) then
		return valueFloor
	end
	return valueFloor + step
end

function tablelength(T)
	if (T == nil) then
		return 0
	end

	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

function copyTable(tableToCopy)
	if (tableToCopy == nil) then
		return {}
	end

	local orig_type = type(tableToCopy)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in pairs(tableToCopy) do
			local orig_value_type = type(orig_value)
			if (orig_value_type == "table") then
				copy[orig_key] = copyTable(orig_value)
			else
				copy[orig_key] = orig_value
			end
		end
	else -- number, string, boolean, etc
		copy = tableToCopy
	end
	return copy
end

function adjustTextLength(text, size, frame)
	local adjustedText = text
	if (text:len() > size) then
		adjustedText = text:sub(0, size)

		frame:SetScript(
			"OnEnter",
			function()
				GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT", -5, 30)
				GameTooltip:SetText(text, nil, nil, nil, nil, true)
			end
		)
		frame:SetScript(
			"OnLeave",
			function()
				GameTooltip:Hide()
			end
		)
	else
		frame:SetScript(
			"OnEnter",
			function()
			end
		)
		frame:SetScript(
			"OnLeave",
			function()
			end
		)
	end
	return adjustedText
end

local textToDisplay =
	"The orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses.\n\nNer'zhul's apprehension about the war with the draenei grows. \nKil'jaeden appears to him in the form of Rulkan and tells him of powerful beings who could aid the orcs, and the night after Kil'jaeden appears again as a radiant elemental entity and urges him to push the Horde to victory and exterminate the draenei. \n\nNer'zhul secretly embarks on a journey to Oshu'gun to seek the guidance of the ancestors, but Kil'jaeden is aware of his plans and tells Gul'dan to gather allies to control the Shadowmoon, since Ner'zhul can no longer be relied upon. Gul'dan recruits Teron'gor and several other shaman and begin teaching them fel magic.\n\nAt Oshu'gun, the real Rulkan and the other ancestors tell Ner'zhul that he was being manipulated by Kil'jaeden and condemn the shaman for having been used by the demon lord. \n\nNer'zhul falls into despair and is captured by Gul'dan's followers, who treat him as little more than a slave.\nThe orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses."

local textToDisplayHTML =
	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

local textToDisplayHTMLlong =
	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

function TransformEventToBook(event)
	if (event ~= nil) then
		local data = {}

		local title = {
			header = {
				templateKey = "TITLE",
				text = event.label
			},
			elements = {}
		}
		table.insert(
			title.elements,
			{
				templateKey = "TEXTCONTENT",
				text = ""
			}
		)
		table.insert(data, title)

		for key, description in pairs(event.description) do
			local chapter = CreateChapter(nil, {description})
			table.insert(data, chapter)
		end

		return data
	end
end

function CreateChapter(title, content)
	local chapter = {elements = {}}

	if (title ~= nil) then
		print(title)
		chapter.header = {
			templateKey = "HEADER",
			text = title
		}
	end

	for key, text in pairs(content) do
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
			local lines = SplitTextToFitWidth(text, 400)
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

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

-- function GetItemData()
-- 	local returnData = {}

-- 	local texts = {
-- 		textToDisplay,
-- 		textToDisplayHTML,
-- 		textToDisplayHTMLlong
-- 	}

-- 	local data = CreateChapter("Chapter title", texts)
-- 	table.insert(returnData, data)

-- 	-- local dataGroup = {elements = {}}
-- 	-- dataGroup.header = {
-- 	-- 	templateKey = "HEADER",
-- 	-- 	text = "Chapter title"
-- 	-- }
-- 	-- table.insert(returnData, dataGroup)

-- 	-- local dataGroup2 = {elements = {}}
-- 	-- local texts = {
-- 	-- 	textToDisplay,
-- 	-- 	textToDisplayHTML,
-- 	-- 	textToDisplayHTMLlong
-- 	-- }

-- 	-- for key, text in pairs(texts) do
-- 	-- 	if (containsHTML(text)) then
-- 	-- 		table.insert(
-- 	-- 			dataGroup2.elements,
-- 	-- 			{
-- 	-- 				templateKey = "HTMLCONTENT",
-- 	-- 				text = cleanHTML(text)
-- 	-- 			}
-- 	-- 		)
-- 	-- 	else
-- 	-- 		-- transform text => adjust line to width
-- 	-- 		-- then for each line add itemEntry
-- 	-- 		local lines = SplitTextToFitWidth(text, 400)
-- 	-- 		for i, value in ipairs(lines) do
-- 	-- 			local line = {
-- 	-- 				templateKey = "TEXTCONTENT",
-- 	-- 				text = value
-- 	-- 			}

-- 	-- 			table.insert(dataGroup2.elements, line)
-- 	-- 		end
-- 	-- 	end
-- 	-- end
-- 	-- table.insert(returnData, dataGroup2)

-- 	return returnData
-- end
