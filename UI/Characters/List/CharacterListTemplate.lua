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
	private.Core.registerCallback(private.constants.events.UIRefresh, self.OnUIRefresh, self)

	-- Load initial data
	self:LoadCharacters()
end

function CharacterListMixin:LoadCharacters()
	-- Get all characters using the data search function
	local characters = Chronicles.Data:SearchCharacters()
	if not characters then
		private.Core.Logger.warn("CharacterList", "No character data available")
		return
	end

	local content = {
		elements = {}
	}
	-- Create list items for each character
	for key, character in pairs(characters) do
		if character and type(character) == "table" and character.name then
			local characterSummary = {
				templateKey = private.constants.templateKeys.CHARACTER_LIST_ITEM,
				name = character.name,
				character = character
			}
			table.insert(content.elements, characterSummary)
		else
			private.Core.Logger.warn("CharacterList", "Invalid character data at key: " .. tostring(key))
		end
	end

	local data = {}
	table.insert(data, content)
	local dataProvider = CreateDataProvider(data)
	local retainScrollPosition = false

	-- Protected call to SetDataProvider to ensure safety
	local success, errorMsg =
		pcall(
		function()
			self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)

	if not success then
		private.Core.Logger.error("CharacterList", "Error setting character list data - " .. tostring(errorMsg))
	else
		private.Core.Logger.trace(
			"CharacterList",
			"Character list loaded successfully with " .. #content.elements .. " characters"
		)
	end
end

function CharacterListMixin:OnUIRefresh()
	self:LoadCharacters()
end
