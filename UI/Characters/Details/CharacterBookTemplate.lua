local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

CharacterDetailPageMixin = {}

function CharacterDetailPageMixin:OnLoad()
	self.PagedCharacterDetails:SetElementTemplateData(private.constants.templates)	-- Use state-based subscription for character selection
	-- This provides a single source of truth for the selected character
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedCharacter",
			function(newCharacterSelection, oldCharacterSelection)
				if newCharacterSelection then
					local characterData = nil
					
					-- Handle both new format {characterId, collectionName} and legacy format (just ID)
					if type(newCharacterSelection) == "table" and newCharacterSelection.characterId and newCharacterSelection.collectionName then
						-- New format with collection-specific lookup
						local characterId = newCharacterSelection.characterId
						local collectionName = newCharacterSelection.collectionName
						private.Core.Logger.debug("CharacterBook", "Character selection received - ID: " .. characterId .. ", Collection: " .. collectionName)
						characterData = self:GetCharacterById(characterId, collectionName)
					else
						-- Legacy format or fallback - treat as just character ID
						local characterId = type(newCharacterSelection) == "table" and newCharacterSelection.characterId or newCharacterSelection
						if characterId then
							private.Core.Logger.debug("CharacterBook", "Character selection received (legacy format) - ID: " .. characterId)
							characterData = self:GetCharacterById(characterId)
						end
					end
					
					if characterData then
						self:OnCharacterSelected(characterData)
					else
						private.Core.Logger.warn("CharacterBook", "Could not find character data for selection")
					end
				end
			end
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedCharacterDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function CharacterDetailPageMixin:GetCharacterById(characterId, collectionName)
	-- Use the Chronicles Data API to find the character by ID
	if Chronicles and Chronicles.Data then
		local characters = Chronicles.Data:SearchCharacters()
		if characters then
			-- If collection name is provided, try direct lookup first for performance
			if collectionName then
				private.Core.Logger.debug("CharacterBook", "Attempting direct collection lookup for character ID: " .. characterId .. " in collection: " .. collectionName)
				
				for _, character in pairs(characters) do
					if character.id == characterId and character.source == collectionName then
						private.Core.Logger.debug("CharacterBook", "Found character via direct collection lookup")
						return character
					end
				end
				
				private.Core.Logger.warn("CharacterBook", "Character not found in specified collection, falling back to general search")
			end
			
			-- Fallback: search through all characters (maintains backward compatibility)
			for _, character in pairs(characters) do
				if character.id == characterId then
					if collectionName then
						private.Core.Logger.debug("CharacterBook", "Found character via fallback search (different collection than expected)")
					end
					return character
				end
			end
		end
	end
	
	if collectionName then
		private.Core.Logger.error("CharacterBook", "Character not found - ID: " .. characterId .. ", Collection: " .. collectionName)
	else
		private.Core.Logger.error("CharacterBook", "Character not found - ID: " .. characterId)
	end
	return nil
end

function CharacterDetailPageMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function CharacterDetailPageMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end

function CharacterDetailPageMixin:OnCharacterSelected(data)
	local content = private.Core.Characters.TransformCharacterToBook(data)

	local dataProvider = CreateDataProvider(content)
	local retainScrollPosition = false
	self.PagedCharacterDetails:SetDataProvider(dataProvider, retainScrollPosition)
end
