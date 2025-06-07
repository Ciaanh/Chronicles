local FOLDER_NAME, private = ...

local Chronicles = private.Chronicles

CharacterDetailPageMixin = {}

function CharacterDetailPageMixin:OnLoad()
	self.PagedCharacterDetails:SetElementTemplateData(private.constants.templates) -- Use state-based subscription for character selection
	-- This provides a single source of truth for the selected character
	if private.Core.StateManager then
		local selectedCharacterKey = private.Core.StateManager.buildSelectionKey("character")
		private.Core.StateManager.subscribe(
			selectedCharacterKey,
			function(newCharacterSelection, oldCharacterSelection)
				if newCharacterSelection then
					local characterData = nil

					-- Handle both new format {characterId, collectionName} and legacy format (just ID)
					if
						type(newCharacterSelection) == "table" and newCharacterSelection.characterId and
							newCharacterSelection.collectionName
					 then
						-- New format with collection-specific lookup
						local characterId = newCharacterSelection.characterId
						local collectionName = newCharacterSelection.collectionName
						private.Core.Logger.trace(
							"CharacterBook",
							"Character selection received - ID: " .. tostring(characterId) .. ", Collection: " .. tostring(collectionName)
						)
						characterData = self:GetCharacterById(characterId, collectionName)
					else
						-- Legacy format or fallback - treat as just character ID
						local characterId = nil
						if type(newCharacterSelection) == "table" then
							-- Table format but missing collectionName - extract characterId if available
							characterId = newCharacterSelection.characterId
						else
							-- Primitive value - use directly as character ID
							characterId = newCharacterSelection
						end

						if characterId then
							private.Core.Logger.trace(
								"CharacterBook",
								"Character selection received (legacy format) - ID: " .. tostring(characterId)
							)
							characterData = self:GetCharacterById(characterId)
						else
							private.Core.Logger.warn(
								"CharacterBook",
								"Invalid character selection format - neither new format nor valid legacy format"
							)
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

		private.Core.Logger.trace(
			"CharacterDetailPageMixin",
			"OnLoad completed - subscribed to state changes, state restoration will happen during AddonStartup"
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedCharacterDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function CharacterDetailPageMixin:GetCharacterById(characterId, collectionName)
	local Chronicles = private.Chronicles

	-- Use the Chronicles Data API to find the character by ID
	if Chronicles and Chronicles.Data then
		local characters = Chronicles.Data:SearchCharacters()
		if characters then
			-- If collection name is provided, try direct lookup first for performance
			if collectionName then
				private.Core.Logger.trace(
					"CharacterBook",
					"Attempting direct collection lookup for character ID: " ..
						tostring(characterId) .. " in collection: " .. tostring(collectionName)
				)

				for _, character in pairs(characters) do
					if character.id == characterId and character.source == collectionName then
						private.Core.Logger.trace("CharacterBook", "Found character via direct collection lookup")
						return character
					end
				end

				private.Core.Logger.warn(
					"CharacterBook",
					"Character not found in specified collection, falling back to general search"
				)
			end

			-- Fallback: search through all characters (maintains backward compatibility)
			for _, character in pairs(characters) do
				if character.id == characterId then
					if collectionName then
						private.Core.Logger.trace(
							"CharacterBook",
							"Found character via fallback search (different collection than expected)"
						)
					end
					return character
				end
			end
		end
	end

	if collectionName then
		private.Core.Logger.error(
			"CharacterBook",
			"Character not found - ID: " .. tostring(characterId) .. ", Collection: " .. tostring(collectionName)
		)
	else
		private.Core.Logger.error("CharacterBook", "Character not found - ID: " .. tostring(characterId))
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
