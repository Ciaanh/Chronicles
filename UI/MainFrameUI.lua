local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.NewUi = {}
function Chronicles.NewUi.DisplayWindow()
	local alreadyShowing = MainFrameUI:IsShown()

	if alreadyShowing then
		HideUIPanel(MainFrameUI)
	else
		ShowUIPanel(MainFrameUI)
	end
end

-----------------------------------------------------------------------------------------
-- Main UI Fonctions --------------------------------------------------------------------
-----------------------------------------------------------------------------------------
MainFrameUIMixin = {}

function MainFrameUIMixin:OnLoad()
end

function MainFrameUIMixin:OnShow()
	self.TabUI:UpdateTabs()

	EventRegistry:TriggerEvent(private.constants.events.MainFrameUIOpenFrame)
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_OPEN_WINDOW)
end

function MainFrameUIMixin:OnHide()
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW)

	EventRegistry:TriggerEvent(private.constants.events.MainFrameUICloseFrame)
end

-----------------------------------------------------------------------------------------
-- Tab UI Fonctions ---------------------------------------------------------------------
-----------------------------------------------------------------------------------------

TabUIMixin = {}

TabUIMixin.FrameTabs = {
	Events = 1,
	Characters = 2,
	Factions = 3,
	Settings = 2
	-- Third = 3
}

function TabUIMixin:OnLoad()
	TabSystemOwnerMixin.OnLoad(self)
	self:SetTabSystem(self.TabSystem)

	self.EventsTabID = self:AddNamedTab("Events", self.Events)
	self.CharactersTabID = self:AddNamedTab("Characters", self.Characters)
	self.FactionsTabID = self:AddNamedTab("Factions", self.Factions)

	self.SettingsTabID = self:AddNamedTab("Settings", self.Settings)

	self.frameTabsToTabID = {
		[TabUIMixin.FrameTabs.Events] = self.EventsTabID,
		[TabUIMixin.FrameTabs.Settings] = self.SettingsTabID
	}
end

function TabUIMixin:UpdateTabs()
	local isEventsTabAvailable = self:IsTabAvailable(self.EventsTabID)
	local isSettingsTabAvailable = self:IsTabAvailable(self.SettingsTabID)

	self.TabSystem:SetTabShown(self.EventsTabID, isEventsTabAvailable)
	self.TabSystem:SetTabShown(self.SettingsTabID, isSettingsTabAvailable)

	local currentTab = self:GetTab()
	if not currentTab or not self:IsTabAvailable(currentTab) then
		self:SetTab(self.EventsTabID)
	end
end

function TabUIMixin:SetTab(tabID)
	TabSystemOwnerMixin.SetTab(self, tabID)

	EventRegistry:TriggerEvent(private.constants.events.TabUITabSet, self, tabID)

	return true -- Don't show the tab as selected yet.
end

-- function TabUIMixin:IsFrameTabActive(frameTab)
-- 	local tabID = self.frameTabsToTabID[frameTab]
-- 	if not tabID then
-- 		return false
-- 	end
-- 	return self:GetTab() == tabID
-- end

-- function TabUIMixin:TrySetTab(frameTab)
-- 	local tabID = self.frameTabsToTabID[frameTab]
-- 	if not tabID then
-- 		return false
-- 	end

-- 	local isTabAvailable = self:IsTabAvailable(tabID)
-- 	if isTabAvailable then
-- 		self:SetTab(tabID)
-- 	end

-- 	return isTabAvailable
-- end

function TabUIMixin:IsTabAvailable(tabID)
	return true
end
