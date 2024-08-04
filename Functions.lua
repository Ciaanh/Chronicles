function Trim(s)
	return s:match("^%s*(.-)%s*$")
end

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

-- Create a hidden frame for measuring text width
local measureFrame = CreateFrame("Frame", nil, UIParent)
measureFrame:Hide()
local measureText = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
measureText:SetPoint("LEFT")

-- Function to split text into lines that fit within a given frame width
function SplitTextToFitWidth(textToSplit, width)
	local text = textToSplit:gsub("\n", " \n ")
	text = text:gsub("  ", " ")

	local words = { strsplit(" ", text) }
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
		line = Trim(line):gsub("<tab>", "  ")
	end

	table.insert(lines, line)

	return lines
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

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
