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
	EventDetails = 1,
	Options = 2
	-- Third = 3
}

function TabUIMixin:OnLoad()
	TabSystemOwnerMixin.OnLoad(self)
	self:SetTabSystem(self.TabSystem)
	self.EventDetailsTabID = self:AddNamedTab("Events Details", self.EventDetails)
	self.OptionsTabID = self:AddNamedTab("Options", self.Options)

	self.frameTabsToTabID = {
		[TabUIMixin.FrameTabs.EventDetails] = self.EventDetailsTabID,
		[TabUIMixin.FrameTabs.Options] = self.OptionsTabID
	}
end

function TabUIMixin:UpdateTabs()
	local isEventDetailsTabAvailable = self:IsTabAvailable(self.EventDetailsTabID)
	local isOptionsTabAvailable = self:IsTabAvailable(self.OptionsTabID)

	self.TabSystem:SetTabShown(self.EventDetailsTabID, isEventDetailsTabAvailable)
	self.TabSystem:SetTabShown(self.OptionsTabID, isOptionsTabAvailable)

	local currentTab = self:GetTab()
	if not currentTab or not self:IsTabAvailable(currentTab) then
		self:SetTab(self.EventDetailsTabID)
	end
end

function TabUIMixin:SetTab(tabID)
	TabSystemOwnerMixin.SetTab(self, tabID)

	EventRegistry:TriggerEvent(private.constants.events.TabUITabSet, self, tabID)

	return true -- Don't show the tab as selected yet.
end

function TabUIMixin:IsFrameTabActive(frameTab)
	local tabID = self.frameTabsToTabID[frameTab]
	if not tabID then
		return false
	end
	return self:GetTab() == tabID
end

function TabUIMixin:TrySetTab(frameTab)
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

function TabUIMixin:IsTabAvailable(tabID)
	return true
end
