local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UITest = {}

local function GenerateClosureInternal(generatorArray, f, ...)
	local count = select("#", ...);
	local generator = generatorArray[count + 1];
	if generator then
		return generator(f, ...);
	end

	assertsafe("Closure generation does not support more than " .. (#generatorArray - 1) .. " parameters");
	return nil;
end

-- Syntactic sugar for function(...) return f(a, b, c, ...); end
function GenerateClosure(f, ...)
	return GenerateClosureInternal(s_passThroughClosureGenerators, f, ...);
end

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
BookFrameMixin = {}

function BookFrameMixin:OnLoad()
	-- TabSystemOwnerMixin.OnLoad(self);
	-- self:SetTabSystem(self.CategoryTabSystem);

	-- self.categoryMixins = {
	-- 	CreateAndInitFromMixin(SpellBookClassCategoryMixin, self);
	-- 	CreateAndInitFromMixin(SpellBookGeneralCategoryMixin, self);
	-- 	CreateAndInitFromMixin(SpellBookPetCategoryMixin, self);
	-- };

	-- for _, categoryMixin in ipairs(self.categoryMixins) do
	-- 	categoryMixin:SetTabID(self:AddNamedTab(categoryMixin:GetName()));
	-- end

	-- self.PagedBookFrame:SetElementTemplateData(Templates);
	-- self.PagedBookFrame:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.OnPagedSpellsUpdate, self);

	-- local initialHidePassives = GetCVarBool("spellBookHidePassives");
	-- local isUserInput = false;
	-- self.HidePassivesCheckButton:SetControlChecked(initialHidePassives, isUserInput);
	-- self.HidePassivesCheckButton:SetCallback(GenerateClosure(self.OnHidePassivesToggled, self));

	-- FrameUtil.RegisterFrameForEvents(self, SpellBookLifetimeEvents);
	-- EventRegistry:RegisterCallback("ClickBindingFrame.UpdateFrames", self.OnClickBindingUpdate, self);

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedBookFrame.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	-- Start the page corner flipbook to sit on its first frame while not playing
	self.BookCornerFlipbook.Anim:Play()
	self.BookCornerFlipbook.Anim:Pause()

	-- SpellBookFrameTutorialsMixin.OnLoad(self);
	-- self:InitializeSearch();

		self.PagedSpellsFrame.ViewFrames[2]:Show();
		self.PagedSpellsFrame.ViewFrames[1]:SetPoint("TOPLEFT", self.view1MaximizedXOffset, self.view1YOffset);
		self.PagedSpellsFrame:SetViewsPerPage(2, true);

end

function BookFrameMixin:OnShow()
	-- self:UpdateAllSpellData();
	-- if not self:GetTab() and not self:IsInSearchResultsMode() then
	-- 	self:ResetToFirstAvailableTab();
	-- end
	-- FrameUtil.RegisterFrameForEvents(self, SpellBookWhileVisibleEvents);
	-- FrameUtil.RegisterFrameForUnitEvents(self, SpellBookWhileVisibleUnitEvents, "player");
	-- EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Show");
	-- if InClickBindingMode() then
	-- 	ClickBindingFrame:SetFocusedFrame(self:GetParent());
	-- end
end

function BookFrameMixin:OnHide()
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleEvents);
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleUnitEvents);
	-- EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide");
	-- if InClickBindingMode() then
	-- 	ClickBindingFrame:ClearFocusedFrame();
	-- end
	-- SpellBookFrameTutorialsMixin.OnHide(self);
end

function BookFrameMixin:OnEvent(event, ...)
	-- if event == "SPELLS_CHANGED" then
	-- 	self:UpdateAllSpellData();
	-- elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
	-- 	local resetCurrentPage = true;
	-- 	self:UpdateAllSpellData(resetCurrentPage);
	-- elseif event == "LEARNED_SPELL_IN_SKILL_LINE" then
	-- 	local spellID, skillLineIndex, isGuildSpell = ...;
	-- 	self:UpdateAllSpellData();
	-- 	for _, categoryMixin in ipairs(self.categoryMixins) do
	-- 		if categoryMixin:IsAvailable() and categoryMixin:ContainsSkillLine(skillLineIndex) then
	-- 			self.CategoryTabSystem:GetTabButton(categoryMixin:GetTabID()):EnableNewSpellsGlow();
	-- 		end
	-- 	end
	-- elseif event == "USE_GLYPH" then
	-- 	-- Player has used a glyph or remover and is choosing what spell to use it on
	-- 	-- Time for "pending glyph" visuals
	-- 	local spellID = ...;
	-- 	local isGlyphActivation = false;
	-- 	self:GoToSpellForGlyph(spellID, isGlyphActivation);
	-- elseif event == "ACTIVATE_GLYPH" then
	-- 	-- Player has selected a spell to use a glyph or remover on
	-- 	-- Time for "glyph activated" visuals
	-- 	local spellID = ...;
	-- 	local isGlyphActivation = true;
	-- 	self:GoToSpellForGlyph(spellID, isGlyphActivation);
	-- elseif event == "CANCEL_GLYPH_CAST" then
	-- 	-- Player has canceled the use of a glyph or remover
	-- 	-- Clear any pending/activated glyph states
	-- 	self:ForEachDisplayedSpell(function(spellBookItemFrame)
	-- 		spellBookItemFrame:UpdateGlyphState();
	-- 	end);
	-- elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
	-- 	self:UpdateTutorialsForFrameSize();
	-- end
end

function BookFrameMixin:OnPagingButtonEnter()
	self.BookCornerFlipbook.Anim:Play()
end

function BookFrameMixin:OnPagingButtonLeave()
	local reverse = true
	self.BookCornerFlipbook.Anim:Play(reverse)
end
