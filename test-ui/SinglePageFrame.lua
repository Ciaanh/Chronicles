local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UITest = {}

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
SinglePageFrameMixin = {}
local Templates = {
	["HEADER"] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	["TEXTCONTENT"] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init},
	["HTMLCONTENT"] = {template = "HtmlPageTemplate", initFunc = HtmlPageMixin.Init},
}

local textToDisplay =
	"The orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses.\n\nNer'zhul's apprehension about the war with the draenei grows. \nKil'jaeden appears to him in the form of Rulkan and tells him of powerful beings who could aid the orcs, and the night after Kil'jaeden appears again as a radiant elemental entity and urges him to push the Horde to victory and exterminate the draenei. \n\nNer'zhul secretly embarks on a journey to Oshu'gun to seek the guidance of the ancestors, but Kil'jaeden is aware of his plans and tells Gul'dan to gather allies to control the Shadowmoon, since Ner'zhul can no longer be relied upon. Gul'dan recruits Teron'gor and several other shaman and begin teaching them fel magic.\n\nAt Oshu'gun, the real Rulkan and the other ancestors tell Ner'zhul that he was being manipulated by Kil'jaeden and condemn the shaman for having been used by the demon lord. \n\nNer'zhul falls into despair and is captured by Gul'dan's followers, who treat him as little more than a slave.\nThe orcs begin launching sporadic attacks against draenei hunting parties. \nThe draenei, assuming that the orcs have simply been agitated by the elemental turmoil, begin organizing and constructing new defenses."

local textToDisplayHTML =
	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

local textToDisplayHTMLlong =
	'<html><body><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/><h1>|cFF0000FF HTML Demo: blue H1|r</h1><img src="Interface\\Icons\\Ability_Ambush" width="32" height="32" align="right"/><p align="center">|cffee4400\'Centered text after an image from the game\'|r</p><br/><p>This is a paragraph,<br/>this is text in the same paragraph after a line break.</p><br/><br/><br/><p>This is an image from the addon, for better compatibility use power of 2 for width/height (16, 32, 64...)</p><img src="Interface\\AddOns\\Chronicles\\Images\\Example-image" width="256" height="256" align="center"/></body></html>'

function SinglePageFrameMixin:GetItemData()
	local returnData = {}

	-- for each chapter
	-- for _, spellGroup in ipairs(self.spellGroups) do
	local dataGroup = {elements = {}}

	dataGroup.header = {
		templateKey = "HEADER",
		text = "Chapter title"
	}

	local texts = {
		textToDisplay,
		textToDisplayHTML,
		textToDisplayHTMLlong
	}

	for key, text in pairs(texts) do
		if (containsHTML(text)) then
			table.insert(
				dataGroup.elements,
				{
					templateKey = "HTMLCONTENT",
					text = cleanHTML(text)
				}
			)
		else
			-- transform text => adjust line to width
			-- then for each line add itemEntry
			local lines = SplitTextToFitWidth(textToDisplay, 400)
			for i, value in ipairs(lines) do
				local line = {
					templateKey = "TEXTCONTENT",
					text = value
				}

				table.insert(dataGroup.elements, line)
			end
		end
	end
	table.insert(returnData, dataGroup)

	return returnData
end

function SinglePageFrameMixin:OnLoad()
	print("OnLoad")
	self.PagedSinglePageFrame:SetElementTemplateData(Templates)

	local data = self.GetItemData()

	local categoryDataProvider = CreateDataProvider(data)
	self.PagedSinglePageFrame:SetDataProvider(categoryDataProvider, not resetCurrentPage)
	-- self.PagedSinglePageFrame:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.OnPagedSpellsUpdate, self);

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

	-- self.PagedSinglePageFrame:SetElementTemplateData(Templates);
	-- self.PagedSinglePageFrame:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.OnPagedSpellsUpdate, self);

	-- local initialHidePassives = GetCVarBool("spellBookHidePassives");
	-- local isUserInput = false;
	-- self.HidePassivesCheckButton:SetControlChecked(initialHidePassives, isUserInput);
	-- self.HidePassivesCheckButton:SetCallback(GenerateClosure(self.OnHidePassivesToggled, self));

	-- FrameUtil.RegisterFrameForEvents(self, SpellBookLifetimeEvents);
	-- EventRegistry:RegisterCallback("ClickBindingFrame.UpdateFrames", self.OnClickBindingUpdate, self);

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedSinglePageFrame.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	-- Start the page corner flipbook to sit on its first frame while not playing
	self.SinglePageBookCornerFlipbook.Anim:Play()
	self.SinglePageBookCornerFlipbook.Anim:Pause()

	-- SpellBookFrameTutorialsMixin.OnLoad(self);
	-- self:InitializeSearch();

	--self.PagedSinglePageFrame.ViewFrames[1]:SetPoint("TOPLEFT", self.view1MinimizedXOffset, self.view1YOffset)
	self.PagedSinglePageFrame:SetViewsPerPage(1, true)

	-- self.SearchBox:ClearAllPoints()
	-- self.SearchBox:SetPoint("RIGHT", self.HidePassivesCheckButton, "LEFT", -15, 0)
	-- self.SearchBox:SetPoint("LEFT", self.CategoryTabSystem, "RIGHT", 10, 10)

	-- self:SetWidth(self.minimizedWidth)
end

function SinglePageFrameMixin:OnShow()
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

function SinglePageFrameMixin:OnHide()
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleEvents);
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleUnitEvents);
	-- EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellBookFrame.Hide");
	-- if InClickBindingMode() then
	-- 	ClickBindingFrame:ClearFocusedFrame();
	-- end
	-- SpellBookFrameTutorialsMixin.OnHide(self);
end

function SinglePageFrameMixin:OnEvent(event, ...)
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

-- function SpellBookFrameMixin:SetMinimized(shouldBeMinimized)
-- 	local minimizedChanged = self.isMinimized ~= shouldBeMinimized;
-- 	if not self.isMinimized and shouldBeMinimized then
-- 		self.isMinimized = true;
-- 		-- Collapse down to one paged view (ie left half of book)
-- 		self.PagedSpellsFrame.ViewFrames[1]:SetPoint("TOPLEFT", self.view1MinimizedXOffset, self.view1YOffset);
-- 		self.PagedSpellsFrame:SetViewsPerPage(1, true);
-- 		self.PagedSpellsFrame.ViewFrames[2]:Hide();

-- 		self.SearchBox:ClearAllPoints();
-- 		self.SearchBox:SetPoint("RIGHT", self.HidePassivesCheckButton, "LEFT", -15, 0);
-- 		self.SearchBox:SetPoint("LEFT", self.CategoryTabSystem, "RIGHT", 10, 10);

-- 		self:SetWidth(self.minimizedWidth);
-- 	elseif self.isMinimized and not shouldBeMinimized then
-- 		self.isMinimized = false;
-- 		self:SetWidth(self.maximizedWidth);
-- 		-- Expand back up to two paged views (ie whole book)
-- 		self.PagedSpellsFrame.ViewFrames[2]:Show();
-- 		self.PagedSpellsFrame.ViewFrames[1]:SetPoint("TOPLEFT", self.view1MaximizedXOffset, self.view1YOffset);
-- 		self.PagedSpellsFrame:SetViewsPerPage(2, true);

-- 		self.SearchBox:ClearAllPoints();
-- 		self.SearchBox:SetPoint("RIGHT", self.HidePassivesCheckButton, "LEFT", -30, 0);
-- 	end

-- 	if minimizedChanged then
-- 		for _, minimizedPiece in ipairs(self.minimizedArt) do
-- 			minimizedPiece:SetShown(self.isMinimized);
-- 		end
-- 		for _, maximizedPiece in ipairs(self.maximizedArt) do
-- 			maximizedPiece:SetShown(not self.isMinimized);
-- 		end

-- 		self:UpdateTutorialsForFrameSize();
-- 	end
-- end

function SinglePageFrameMixin:OnPagingButtonEnter()
	self.SinglePageBookCornerFlipbook.Anim:Play()
end

function SinglePageFrameMixin:OnPagingButtonLeave()
	local reverse = true
	self.SinglePageBookCornerFlipbook.Anim:Play(reverse)
end
