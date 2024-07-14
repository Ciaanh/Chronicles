local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UITest2 = {}
function Chronicles.UITest2:DisplayWindow()
	local alreadyShowing = TestBookFrame:IsShown()

	if alreadyShowing then
		HideUIPanel(TestBookFrame)
	else
		ShowUIPanel(TestBookFrame)
	end
end

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
TestBookFrameMixin = {}
local Templates = {
	["HEADER"] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	["CONTENT"] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init}
}

function TestBookFrameMixin:OnLoad()
	self.PagedBookFrame:SetElementTemplateData(Templates)

	local data = {}
	data.header = {
		templateKey = "HEADER",
		text = "Toto"
	}

	data.elements = {}

	table.insert(
		data.elements,
		{
			templateKey = "CONTENT",
			text = "Content of the page ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
		}
	)
	local categoryDataProvider = CreateDataProvider(data)
	self.PagedBookFrame:SetDataProvider(categoryDataProvider, not resetCurrentPage)
	-- self.PagedBookFrame:RegisterCallback(PagedContentFrameBaseMixin.Event.OnUpdate, self.OnPagedSpellsUpdate, self);

	local onPagingButtonEnter = GenerateClosure(self.OnPagingButtonEnter, self)
	local onPagingButtonLeave = GenerateClosure(self.OnPagingButtonLeave, self)
	self.PagedBookFrame.PagingControls:SetButtonHoverCallbacks(onPagingButtonEnter, onPagingButtonLeave)

	-- Start the page corner flipbook to sit on its first frame while not playing
	self.BookCornerFlipbook.Anim:Play()
	self.BookCornerFlipbook.Anim:Pause()

	-- SpellTestBookFrameTutorialsMixin.OnLoad(self);
	-- self:InitializeSearch();

	self.PagedBookFrame.ViewFrames[2]:Show()
	self.PagedBookFrame.ViewFrames[1]:SetPoint("TOPLEFT", self.view1MaximizedXOffset, self.view1YOffset)
	self.PagedBookFrame:SetViewsPerPage(2, true)
end

function TestBookFrameMixin:OnShow()
	-- self:UpdateAllSpellData();
	-- if not self:GetTab() and not self:IsInSearchResultsMode() then
	-- 	self:ResetToFirstAvailableTab();
	-- end
	-- FrameUtil.RegisterFrameForEvents(self, SpellBookWhileVisibleEvents);
	-- FrameUtil.RegisterFrameForUnitEvents(self, SpellBookWhileVisibleUnitEvents, "player");
	-- EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellTestBookFrame.Show");
	-- if InClickBindingMode() then
	-- 	ClickBindingFrame:SetFocusedFrame(self:GetParent());
	-- end
end

function TestBookFrameMixin:OnHide()
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleEvents);
	-- FrameUtil.UnregisterFrameForEvents(self, SpellBookWhileVisibleUnitEvents);
	-- EventRegistry:TriggerEvent("PlayerSpellsFrame.SpellTestBookFrame.Hide");
	-- if InClickBindingMode() then
	-- 	ClickBindingFrame:ClearFocusedFrame();
	-- end
	-- SpellTestBookFrameTutorialsMixin.OnHide(self);
end

function TestBookFrameMixin:OnEvent(event, ...)
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

function TestBookFrameMixin:OnPagingButtonEnter()
	self.BookCornerFlipbook.Anim:Play()
end

function TestBookFrameMixin:OnPagingButtonLeave()
	local reverse = true
	self.BookCornerFlipbook.Anim:Play(reverse)
end

-- -- Create a hidden frame for measuring text width
-- local measureFrame = CreateFrame("Frame", nil, UIParent)
-- measureFrame:Hide()
-- local measureText = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
-- measureText:SetPoint("LEFT")

-- -- Function to split text into lines that fit within a given width
-- local function SplitTextToFitWidth(text, width)
--     local words = {strsplit(" ", text)}
--     local lines = {}
--     local line = ""

--     for i, word in ipairs(words) do
--         measureText:SetText(line .. " " .. word)

--         if measureText:GetStringWidth() > width then
--             table.insert(lines, line)
--             line = word
--         else
--             line = line .. " " .. word
--         end
--     end

--     table.insert(lines, line)

--     return lines
-- end

-- -- Function to split lines into pages that fit within a given height
-- local function splitLinesToFitHeight(lines, lineHeight, height)
--     local pages = {}
--     local page = {}
--     local pageHeight = 0

--     for i, line in ipairs(lines) do
--         if pageHeight + lineHeight > height then
--             table.insert(pages, page)
--             page = {line}
--             pageHeight = lineHeight
--         else
--             table.insert(page, line)
--             pageHeight = pageHeight + lineHeight
--         end
--     end

--     table.insert(pages, page)

--     return pages
-- end

-- -- Your long text
-- local longText = "This is some very long text that you want to split into multiple lines to fit within a certain width."

-- -- Split the text into lines
-- local lines = SplitTextToFitWidth(longText, 200)  -- Replace 200 with the width of your frame

-- -- Estimate the line height based on the font size
-- local lineHeight = measureText:GetStringHeight()

-- -- Split the lines into pages
-- local pages = splitLinesToFitHeight(lines, lineHeight, 200)  -- Replace 200 with the height of your frame

-- -- Now 'pages' is a table where each element is a page of text that fits within the specified width and height
-- -- You can use this table to populate your frame as before
