local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

-----------------------------------------------------------------------------------------
-- Templates ----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

CharacterListItemMixin = {}
function CharacterListItemMixin:Init(characterData)
	self.Text:SetText(characterData.character.name)
	self.Character = characterData.character
end

function CharacterListItemMixin:OnClick()
	-- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		private.Core.StateManager.setState("ui.selectedCharacter", self.Character, "Character selected from list")
	end
end

-----------------------------------------------------------------------------------------
-- CharacterList ------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
CharacterListMixin = {}

function CharacterListMixin:OnLoad()
	-- Set element template data first
	self.PagedCharacterList:SetElementTemplateData(private.constants.templates)

	-- Register for timeline clean events to refresh character data
	private.Core.registerCallback(private.constants.events.TimelineClean, self.OnTimelineClean, self)

	-- Wait a frame to ensure the ViewFrames are properly initialized
	C_Timer.After(
		0,
		function()
			self:LoadCharacters()
		end
	)
end

function CharacterListMixin:LoadCharacters()
	if not self.PagedCharacterList then
		private.Core.Logger.error("CharacterList", "PagedCharacterList frame not found")
		return
	end

	-- Safety check: Ensure ViewFrames is initialized before proceeding
	if not self.PagedCharacterList.ViewFrames then
		private.Core.Logger.warn("CharacterList", "ViewFrames not initialized for PagedCharacterList, attempting retry...")
		-- Retry after a short delay to allow for proper initialization
		C_Timer.After(
			0.1,
			function()
				if self.PagedCharacterList.ViewFrames then
					self:LoadCharacters()
				else
					private.Core.Logger.error("CharacterList", "ViewFrames still not initialized after retry")
				end
			end
		)
		return
	end
	-- Get all characters using the data search function
	local characters = Chronicles.Data:SearchCharacters()
	if not characters then
		private.Core.Logger.warn("CharacterList", "No character data available")
		return
	end

	-- Ensure characters is a table
	if type(characters) ~= "table" then
		private.Core.Logger.error("CharacterList", "SearchCharacters returned invalid data type: " .. type(characters))
		return
	end

	local content = {
		elements = {}
	}

	-- Create list items for each character
	for key, character in pairs(characters) do
		if character and character.name then
			local characterSummary = {
				templateKey = private.constants.templateKeys.CHARACTER_LIST_ITEM,
				name = character.name,
				character = character
			}
			table.insert(content.elements, characterSummary)
		else
			private.Core.Logger.warn("CharacterList", "Invalid character data at key: " .. tostring(key))
		end
	end -- Ensure content.elements is valid before calling CreateDataProvider
	if not content.elements or type(content.elements) ~= "table" then
		private.Core.Logger.error("CharacterList", "content.elements is invalid: " .. type(content.elements))
		return
	end

	-- Additional validation for elements table
	if #content.elements == 0 then
		private.Core.Logger.info("CharacterList", "No characters to display")
		-- Create empty data provider to clear the list
		local success, errorMsg =
			pcall(
			function()
				local dataProvider = CreateDataProvider({})
				local retainScrollPosition = false
				self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
			end
		)
		if not success then
			private.Core.Logger.error("CharacterList", "Error setting empty data provider - " .. tostring(errorMsg))
		end
		return
	end

	-- Validate each element in the table
	for i, element in ipairs(content.elements) do
		if not element or type(element) ~= "table" then
			private.Core.Logger.error("CharacterList", "Invalid element at index " .. i .. ": " .. type(element))
			return
		end
	end

	-- Protected call to SetDataProvider to catch any remaining errors
	local success, errorMsg =
		pcall(
		function()
			local dataProvider = CreateDataProvider(content.elements)
			if not dataProvider then
				error("CreateDataProvider returned nil")
			end
			local retainScrollPosition = false
			self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)
	if not success then
		private.Core.Logger.error("CharacterList", "Error setting data provider - " .. tostring(errorMsg))
	else
		private.Core.Logger.info("CharacterList", "Successfully loaded " .. #content.elements .. " characters")
	end
end

function CharacterListMixin:OnTimelineClean()
	-- Clear the character list data when timeline is cleaned
	local data = {}
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false
	-- Protected call to SetDataProvider to ensure safety
	local success, errorMsg =
		pcall(
		function()
			if self.PagedCharacterList and self.PagedCharacterList.ViewFrames then
				self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
			end
		end
	)
	if not success then
		private.Core.Logger.error("CharacterList", "Error clearing character list data - " .. tostring(errorMsg))
	else
		private.Core.Logger.info("CharacterList", "Character list data cleared for timeline clean")
	end
end
