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
