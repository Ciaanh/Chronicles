local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UITest = {}
function Chronicles.UITest:DisplayWindow()
	-- if DISALLOW_FRAME_TOGGLING then
	-- 	return
	-- end

	-- CheckLoadPlayerSpellsFrame()

	local alreadyShowing = MainFrameTest:IsShown()

	if alreadyShowing then
		HideUIPanel(MainFrameTest)
	else
		-- SetOrClearInspectUnit(inspectUnit)

		-- if MainFrameTest:TrySetTab(PlayerSpellsUtil.FrameTabs.SpellBook) then
		-- 	if not spellBookCategory or PlayerSpellsFrame.SpellBookFrame:TrySetCategory(spellBookCategory) then
		-- 		ShowUIPanel(PlayerSpellsFrame)
		-- 	end
		-- end

		ShowUIPanel(MainFrameTest)
	end
end

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
MainFrameTestMixin = {}

MainFrameTestUtil = {}

MainFrameTestUtil.FrameTabs = {
	First = 1,
	Second = 2,
	Third = 3
}

function MainFrameTestMixin:OnLoad()
	TabSystemOwnerMixin.OnLoad(self)
	self:SetTabSystem(self.TabSystem)
	self.firstTabID = self:AddNamedTab("FirstTab", self.TestFrame)
	self.secondTabID = self:AddNamedTab("SecondTab", self.BookFrame)
	self.thirdTabID = self:AddNamedTab("ThirdTab", self.SinglePageFrame)

	self.frameTabsToTabID = {
		[MainFrameTestUtil.FrameTabs.First] = self.firstTabID,
		[MainFrameTestUtil.FrameTabs.Second] = self.secondTabID,
		[MainFrameTestUtil.FrameTabs.Third] = self.thirdTabID
	}

	--self:SetFrameLevelsFromBaseLevel(5000)
end

function MainFrameTestMixin:OnShow()
	self:UpdateTabs()

	EventRegistry:TriggerEvent("MainFrameTest.OpenFrame")
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_OPEN_WINDOW)
end

function MainFrameTestMixin:OnHide()
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW)

	EventRegistry:TriggerEvent("MainFrameTest.CloseFrame")
end

function MainFrameTestMixin:OnEvent(event)
	-- if event == "PLAYER_SPECIALIZATION_CHANGED" then
	-- 	self:UpdateTabs();
	-- end
end

function MainFrameTestMixin:UpdateTabs()
	local firstTabAvailable = self:IsTabAvailable(self.firstTabID)
	local secondTabAvailable = self:IsTabAvailable(self.secondTabID)
	local thirdTabAvailable = self:IsTabAvailable(self.thirdTabID)

	self.TabSystem:SetTabShown(self.firstTabID, firstTabAvailable)
	self.TabSystem:SetTabShown(self.secondTabID, secondTabAvailable)
	self.TabSystem:SetTabShown(self.thirdTabID, thirdTabAvailable)

	local currentTab = self:GetTab()
	if not currentTab or not self:IsTabAvailable(currentTab) then
		self:SetToDefaultAvailableTab()
	end
end

function MainFrameTestMixin:SetToDefaultAvailableTab()
	if (self:IsTabAvailable(self.firstTabID)) then
		self:SetTab(self.firstTabID)
	elseif (self:IsTabAvailable(self.secondTabID)) then
		self:SetTab(self.secondTabID)
	elseif (self:IsTabAvailable(self.thirdTabID)) then
		self:SetTab(self.thirdTabID)
	else
		self:SetTab(self.firstTabID)
	end
end

function MainFrameTestMixin:UpdateFrameTitle()
	local tabID = self:GetTab()

	if tabID == self.firstTabID then
		self:SetTitle("First Tab")
	elseif tabID == self.secondTabID then
		self:SetTitle("Second Tab")
	elseif tabID == self.thirdTabID then
		self:SetTitle("Third Tab")
	else --if tabID == self.spellBookTabID
		self:SetTitle("Unknown Tab")
	end
end

function MainFrameTestMixin:SetTab(tabID)
	TabSystemOwnerMixin.SetTab(self, tabID)

	self:UpdateFrameTitle()
	EventRegistry:TriggerEvent("MainFrameTest.TabSet", MainFrameTest, tabID)

	return true -- Don't show the tab as selected yet.
end

-- Expects a PlayerSpellsUtil.FrameTabs value
function MainFrameTestMixin:IsFrameTabActive(frameTab)
	local tabID = self.frameTabsToTabID[frameTab]
	if not tabID then
		return false
	end
	return self:GetTab() == tabID
end

-- Expects a PlayerSpellsUtil.FrameTabs value
function MainFrameTestMixin:TrySetTab(frameTab)
	local tabID = self.frameTabsToTabID[frameTab]
	if not tabID then
		return false
	end

	local isTabAvailable = self:IsTabAvailable(tabID)
	if isTabAvailable then
		self:SetTab(tabID)
	end

	return isTabAvailable
end

function MainFrameTestMixin:IsTabAvailable(tabID)
	return true
	-- local canUseTalentSpecUI = C_SpecializationInfo.CanPlayerUseTalentSpecUI();
	-- local isInspecting = self:IsInspecting();

	-- if tabID == self.specTabID then
	-- 	return not isInspecting and canUseTalentSpecUI;
	-- elseif tabID == self.talentTabID then
	-- 	return isInspecting or (PlayerUtil.CanUseClassTalents() and canUseTalentSpecUI);
	-- elseif tabID == self.spellBookTabID then
	-- 	return not isInspecting;
	-- end

	-- return false;
end
