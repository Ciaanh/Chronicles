local FOLDER_NAME, private = ...

--[[
=================================================================================
Module: MainFrameUI
Purpose: Main user interface controller and tab system management
Dependencies: AceLocale-3.0, StateManager, WoW UI API
Author: Chronicles Team
=================================================================================

This module manages the main Chronicles interface including:
- Main frame show/hide functionality
- Tab system coordination
- UI state management integration
- Sound feedback for user interactions

Key UI Event Flow Patterns:

1. Main Frame Lifecycle:
   User Action → UI Panel Toggle → State Update → Sound Feedback
   
2. Tab Navigation Flow:
   Tab Click → Tab Validation → Content Switch → State Persistence → Event Trigger
   
3. State Integration Pattern:
   UI Change → StateManager.setState() → State Subscribers Notified → UI Updates
   
4. Sound Integration:
   UI Actions → Appropriate Sound Playback → Enhanced User Experience

Event Integration Patterns:
- MainFrameUI manages top-level UI state
- TabUI coordinates between different content areas
- State changes trigger automatic UI synchronization
- Events propagate to child components (Events, Characters, Factions)

UI Architecture:
- MainFrameUIMixin: Top-level frame management
- TabUIMixin: Tab system and navigation
- Child mixins: Content-specific UI logic

Dependencies:
- AceLocale-3.0: UI text localization
- StateManager: Centralized state persistence
- WoW UI API: Frame management and sound system
=================================================================================
]]
local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

private.Chronicles.UI = {}

--[[
    Toggle the main Chronicles interface window
    
    Handles showing/hiding the main UI panel with proper WoW UI integration.
    Uses WoW's ShowUIPanel/HideUIPanel for proper panel management and
    integration with the game's UI system.
    
    @example
        Chronicles.UI.DisplayWindow() -- Toggles window visibility
]]
function private.Chronicles.UI.DisplayWindow()
	local alreadyShowing = MainFrameUI:IsShown()

	if alreadyShowing then
		HideUIPanel(MainFrameUI)
	else
		ShowUIPanel(MainFrameUI)
	end
end

-- -------------------------
-- Main UI Functions
-- -------------------------
MainFrameUIMixin = {}

--[[
    Initialize the main frame UI component
    
    Called automatically when the frame is created. Sets up initial state
    and prepares the frame for display.
]]
function MainFrameUIMixin:OnLoad()
	-- =============================================================================================
	-- STATE-BASED BOOK CONTENT SUBSCRIPTION
	-- =============================================================================================
	-- Subscribe to selection state changes and update book content accordingly.
	-- This ensures that SharedBookTemplate always receives already-transformed content.
	
	if private.Core.StateManager then
		-- Event selection subscriber
		local eventSelectionKey = private.Core.StateManager.buildSelectionKey("event")
		private.Core.StateManager.subscribe(
			eventSelectionKey,
			function(newSelection, oldSelection, key)
				self:UpdateEventBookContent(newSelection)
			end,
			"MainFrameUI_EventBook"
		)
		
		-- Character selection subscriber
		local characterSelectionKey = private.Core.StateManager.buildSelectionKey("character")
		private.Core.StateManager.subscribe(
			characterSelectionKey,
			function(newSelection, oldSelection, key)
				self:UpdateCharacterBookContent(newSelection)
			end,
			"MainFrameUI_CharacterBook"
		)
		
		-- Faction selection subscriber
		local factionSelectionKey = private.Core.StateManager.buildSelectionKey("faction")
		private.Core.StateManager.subscribe(
			factionSelectionKey,
			function(newSelection, oldSelection, key)
				self:UpdateFactionBookContent(newSelection)
			end,
			"MainFrameUI_FactionBook"
		)
	end
end

--[[
    Handle main frame becoming visible
    
    Triggers when the main Chronicles window is shown to the user. Updates
    tabs, manages application state, and provides audio feedback.
    
    Event Flow:
    1. Update tab system to reflect current state
    2. Set global UI state to indicate frame is open
    3. Play appropriate UI sound for user feedback
]]
function MainFrameUIMixin:OnShow()
	self.TabUI:UpdateTabs() -- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		local frameStateKey = private.Core.StateManager.buildUIStateKey("isMainFrameOpen")
		private.Core.StateManager.setState(frameStateKey, true, "Main frame opened")
	end
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_OPEN_WINDOW)
end

--[[
    Handle main frame becoming hidden
    
    Triggers when the main Chronicles window is closed. Updates application
    state and provides audio feedback.
    
    Event Flow:
    1. Play appropriate UI sound for user feedback
    2. Update global UI state to indicate frame is closed
]]
function MainFrameUIMixin:OnHide()
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW) -- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		local frameStateKey = private.Core.StateManager.buildUIStateKey("isMainFrameOpen")
		private.Core.StateManager.setState(frameStateKey, false, "Main frame closed")
	end
end

-- =============================================================================================
-- BOOK CONTENT UPDATE METHODS
-- =============================================================================================
-- These methods handle the transformation and display of content in SharedBookTemplate instances.
-- They ensure that content is always transformed before being passed to OnContentReceived.

function MainFrameUIMixin:UpdateEventBookContent(eventSelection)
	local eventBook = self.TabUI.Events.Book
	if not eventBook then return end
	
	if eventSelection and eventSelection.eventId and eventSelection.collectionName then
		-- Fetch the event data
		local event = Chronicles.DB:FindEventByIdAndCollection(eventSelection.eventId, eventSelection.collectionName)
		if event then
			-- Transform to book format and display
			local bookContent = private.Core.Events.TransformEventToBook(event)
			eventBook:OnContentReceived(bookContent)
		else
			-- Show empty state if event not found
			eventBook:ShowEmptyBook()
		end
	else
		-- Show empty state if no selection
		eventBook:ShowEmptyBook()
	end
end

function MainFrameUIMixin:UpdateCharacterBookContent(characterSelection)
	local characterBook = self.TabUI.Characters.Book
	if not characterBook then return end
	
	if characterSelection and characterSelection.characterId and characterSelection.collectionName then
		-- Fetch the character data
		local character = Chronicles.DB:FindCharacterByIdAndCollection(characterSelection.characterId, characterSelection.collectionName)
		if character then
			-- Transform to book format and display
			local bookContent = private.Core.Characters.TransformCharacterToBook(character)
			characterBook:OnContentReceived(bookContent)
		else
			-- Show empty state if character not found
			characterBook:ShowEmptyBook()
		end
	else
		-- Show empty state if no selection
		characterBook:ShowEmptyBook()
	end
end

function MainFrameUIMixin:UpdateFactionBookContent(factionSelection)
	local factionBook = self.TabUI.Factions.Book
	if not factionBook then return end
	
	if factionSelection and factionSelection.factionId and factionSelection.collectionName then
		-- Fetch the faction data
		local faction = Chronicles.DB:FindFactionByIdAndCollection(factionSelection.factionId, factionSelection.collectionName)
		if faction then
			-- Transform to book format and display
			local bookContent = private.Core.Factions.TransformFactionToBook(faction)
			factionBook:OnContentReceived(bookContent)
		else
			-- Show empty state if faction not found
			factionBook:ShowEmptyBook()
		end
	else
		-- Show empty state if no selection
		factionBook:ShowEmptyBook()
	end
end

-- -------------------------
-- Tab UI Functions
-- -------------------------

TabUIMixin = {}

TabUIMixin.FrameTabs = {
	Events = 1,
	Characters = 2,
	Factions = 3,
	Settings = 4
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
	-- Use safe event triggering with fallback
	private.Core.triggerEvent(private.constants.events.TabUITabSet, {frame = self, tabID = tabID}, "MainFrameUI:SetTab")

	return true -- Don't show the tab as selected yet.
end

function TabUIMixin:IsTabAvailable(tabID)
	return true
end
