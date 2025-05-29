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
	-- Safety check: Ensure PagedCharacterList exists and is properly initialized
	if not self.PagedCharacterList then
		print("Chronicles: Error - PagedCharacterList frame not found")
		return
	end

	-- Safety check: Ensure ViewFrames is initialized before proceeding
	if not self.PagedCharacterList.ViewFrames then
		print("Chronicles: Warning - ViewFrames not initialized for PagedCharacterList, attempting retry...")
		-- Retry after a short delay to allow for proper initialization
		C_Timer.After(
			0.1,
			function()
				if self.PagedCharacterList.ViewFrames then
					self:LoadCharacters()
				else
					print("Chronicles: Error - ViewFrames still not initialized after retry")
				end
			end
		)
		return
	end

	-- Get all characters using the data search function
	local characters = Chronicles.Data:SearchCharacters()
	if not characters then
		print("Chronicles: Warning - No character data available")
		return
	end

	local content = {
		elements = {}
	}

	-- Create list items for each character
	for key, character in pairs(characters) do
		local characterSummary = {
			templateKey = private.constants.templateKeys.CHARACTER_LIST_ITEM,
			name = character.name,
			character = character
		}
		table.insert(content.elements, characterSummary)
	end

	-- Protected call to SetDataProvider to catch any remaining errors
	local success, errorMsg =
		pcall(
		function()
			local dataProvider = CreateDataProvider(content.elements)
			local retainScrollPosition = false
			self.PagedCharacterList:SetDataProvider(dataProvider, retainScrollPosition)
		end
	)

	if not success then
		print("Chronicles: Error setting data provider - " .. tostring(errorMsg))
	else
		print("Chronicles: Successfully loaded " .. #content.elements .. " characters")
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
		print("Chronicles: Error clearing character list data - " .. tostring(errorMsg))
	else
		print("Chronicles: Character list data cleared for timeline clean")
	end
end
