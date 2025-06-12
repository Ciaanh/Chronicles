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
							characterData = self:GetCharacterById(characterId)
						end
					end

					if characterData then
						self:OnCharacterSelected(characterData)
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
	local Chronicles = private.Chronicles

	if Chronicles and Chronicles.Data then
		local characters = Chronicles.Data:SearchCharacters()
		if characters then
			if collectionName then
				for _, character in pairs(characters) do
					if character.id == characterId and character.source == collectionName then
						return character
					end
				end
			end
		end
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
