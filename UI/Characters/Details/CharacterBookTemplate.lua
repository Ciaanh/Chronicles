local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

CharacterDetailPageMixin = {}

function CharacterDetailPageMixin:OnLoad()
	self.PagedCharacterDetails:SetElementTemplateData(private.constants.templates)
	-- Use state-based subscription for character selection
	-- This provides a single source of truth for the selected character
	if private.Core.StateManager then
		private.Core.StateManager.subscribe(
			"ui.selectedCharacter",
			function(newCharacterId, oldCharacterId)
				if newCharacterId then
					-- Fetch the full character object from the ID
					local characterData = self:GetCharacterById(newCharacterId)
					if characterData then
						self:OnCharacterSelected(characterData)
					end
				end
			end,
			"CharacterDetailPageMixin"
		)
	end

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedCharacterDetails.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()
end

function CharacterDetailPageMixin:GetCharacterById(characterId)
	-- Use the Chronicles Data API to find the character by ID
	if Chronicles and Chronicles.Data then
		local characters = Chronicles.Data:SearchCharacters()
		if characters then
			for _, character in pairs(characters) do
				if character.id == characterId then
					return character
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
