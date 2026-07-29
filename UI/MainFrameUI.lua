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

local Chronicles = private.Chronicles
Chronicles.UI = {}

local Spacing = private.Core.Utils.Spacing

--[[
    Toggle the main Chronicles interface window
    
    Handles showing/hiding the main UI panel with proper WoW UI integration.
    Uses WoW's ShowUIPanel/HideUIPanel for proper panel management and
    integration with the game's UI system.
    
    @example
        Chronicles.UI.DisplayWindow() -- Toggles window visibility
]]
function Chronicles.UI.DisplayWindow()
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

function MainFrameUIMixin:SetupStateSubscriptions()
	if not private.Core.StateManager then
		return
	end

	if not self._stateSubscriptionDefs then
		local frameName = self:GetName() or "MainFrameUI"
		self._stateSubscriptionDefs = {
			{
				key = private.Core.StateManager.buildSelectionKey("event"),
				id = frameName .. "_EventBook",
				callback = function(newSelection, oldSelection)
					self:UpdateEventBookContent(newSelection)
				end
			},
			{
				key = private.Core.StateManager.buildSelectionKey("character"),
				id = frameName .. "_CharacterBook",
				callback = function(newSelection, oldSelection)
					self:UpdateCharacterBookContent(newSelection)
				end
			},
			{
				key = private.Core.StateManager.buildSelectionKey("faction"),
				id = frameName .. "_FactionBook",
				callback = function(newSelection, oldSelection)
					self:UpdateFactionBookContent(newSelection)
				end
			}
		}
	end
end

function MainFrameUIMixin:EnableStateSubscriptions()
	if self._stateSubscriptionsActive or not self._stateSubscriptionDefs then
		return
	end

	for _, definition in ipairs(self._stateSubscriptionDefs) do
		private.Core.StateManager.subscribe(definition.key, definition.callback, definition.id)

		if definition.callback then
			local success, currentValue = pcall(private.Core.StateManager.getState, definition.key)
			if success then
				local ok, err = pcall(definition.callback, currentValue, nil)
				if not ok then
					geterrorhandler()(err)
				end
			end
		end
	end

	self._stateSubscriptionsActive = true
end

function MainFrameUIMixin:DisableStateSubscriptions()
	if not self._stateSubscriptionsActive or not self._stateSubscriptionDefs then
		return
	end

	for _, definition in ipairs(self._stateSubscriptionDefs) do
		private.Core.StateManager.unsubscribe(definition.key, definition.id)
	end

	self._stateSubscriptionsActive = false
end

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
	-- This ensures that BookContainerTemplate always receives already-transformed content.

	self:SetupStateSubscriptions()

	-- A data refresh (collection or event-type toggled) has to re-derive each book from the current
	-- selection. This lives here rather than in BookContainerTemplate because this mixin is what owns
	-- the selection-to-book mapping; the book frame itself cannot know what is selected.
	private.Core.registerCallback(private.constants.events.UIRefresh, self.RefreshBookContent, self)

	self:SetClampedToScreen(true)
	if self.DragStrip then
		self.DragStrip:RegisterForDrag("LeftButton")
	end
end

-- =============================================================================================
-- WINDOW DRAGGING AND POSITION PERSISTENCE
-- =============================================================================================
-- The panel has no title bar (DialogBorderNoCenterTemplate draws no center), so DragStrip is an
-- explicit drag surface anchored across the top. Its OnDragStart/OnDragStop forward here.
-- Position is persisted through StateManager under the ui.* namespace, so it survives /reload.

--[[
    Build the state key holding the panel's saved screen position
    @return [string] State key, or nil if StateManager is unavailable
]]
local function getWindowPositionKey()
	if not private.Core.StateManager then
		return nil
	end
	return private.Core.StateManager.buildUIStateKey("windowPosition")
end

function MainFrameUIMixin:StartDragging()
	self:StartMoving()
end

function MainFrameUIMixin:StopDragging()
	self:StopMovingOrSizing()
	self:SaveFramePosition()
end

--[[
    Persist the panel's current anchor so the next OnShow can restore it

    relativePoint is stored alongside point because StartMoving rewrites the frame's anchor to
    whatever corner it settled on; restoring against the wrong relative point misplaces the panel.
]]
function MainFrameUIMixin:SaveFramePosition()
	local positionKey = getWindowPositionKey()
	if not positionKey then
		return
	end

	local point, _, relativePoint, xOffset, yOffset = self:GetPoint(1)
	if not point then
		return
	end

	private.Core.StateManager.setState(
		positionKey,
		{point = point, relativePoint = relativePoint, x = xOffset, y = yOffset},
		"Main frame moved"
	)
end

--[[
    Restore the panel to its saved position, leaving the XML default in place when none was saved
]]
function MainFrameUIMixin:RestoreFramePosition()
	local positionKey = getWindowPositionKey()
	if not positionKey then
		return
	end

	local position = private.Core.StateManager.getState(positionKey)
	if type(position) ~= "table" or type(position.point) ~= "string" then
		return
	end

	self:ClearAllPoints()
	self:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x or 0, position.y or 0)
end

--[[
    Handle main frame becoming visible
    
    Triggers when the main Chronicles window is shown to the user. Updates
    tabs, manages application state, and provides audio feedback.
    
    Event Flow:
    1. Update tab system to reflect current state
    2. Set UI state to indicate frame is open
    3. Play appropriate UI sound for user feedback
]]
function MainFrameUIMixin:OnShow()
	self:RestoreFramePosition()
	self.TabUI:UpdateTabs() -- Update state instead of triggering event - provides single source of truth
	self:SetupStateSubscriptions()
	self:EnableStateSubscriptions()
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
    2. Update UI state to indicate frame is closed
]]
function MainFrameUIMixin:OnHide()
	self:DisableStateSubscriptions()
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW) -- Update state instead of triggering event - provides single source of truth
	if private.Core.StateManager then
		local frameStateKey = private.Core.StateManager.buildUIStateKey("isMainFrameOpen")
		private.Core.StateManager.setState(frameStateKey, false, "Main frame closed")
	end
end

-- =============================================================================================
-- BOOK CONTENT UPDATE METHODS
-- =============================================================================================
-- These methods handle the transformation and display of content in BookContainerTemplate instances.
-- They ensure that content is always transformed before being passed to OnContentReceived.

function MainFrameUIMixin:UpdateEventBookContent(eventSelection)
	local eventBook = self.TabUI.Events.Book
	if not eventBook then
		return
	end

	if eventSelection and eventSelection.eventId and eventSelection.collectionName then
		-- Fetch the event data
		local event = Chronicles.Data:FindEventByIdAndCollection(eventSelection.eventId, eventSelection.collectionName)
		if event then
			-- Transform to book format and display
			local success, bookContent = pcall(private.Core.Events.TransformEventToBook, event)
			if success and bookContent then
				eventBook:OnContentReceived(bookContent)
				return
			end
		end
	end

	eventBook:ShowEmptyBook(Locale["BookEmptyPromptEvent"])
end

function MainFrameUIMixin:UpdateCharacterBookContent(characterSelection)
	local characterBook = self.TabUI.Characters.Book
	if not characterBook then
		return
	end

	if characterSelection and characterSelection.characterId and characterSelection.collectionName then
		-- Check if Chronicles.Data is available
		if not Chronicles.Data then
			characterBook:ShowEmptyBook(Locale["BookEmptyPromptCharacter"])
			return
		end

		-- Fetch the character data
		local character =
			Chronicles.Data:FindCharacterByIdAndCollection(characterSelection.characterId, characterSelection.collectionName)
		if character then
			-- Transform to book format and display
			local success, bookContent = pcall(private.Core.Characters.TransformCharacterToBook, character)
			if success and bookContent then
				characterBook:OnContentReceived(bookContent)
				return
			end
		end
	end

	characterBook:ShowEmptyBook(Locale["BookEmptyPromptCharacter"])
end

function MainFrameUIMixin:UpdateFactionBookContent(factionSelection)
	local factionBook = self.TabUI.Factions.Book
	if not factionBook then
		return
	end

	if factionSelection and factionSelection.factionId and factionSelection.collectionName then
		-- Fetch the faction data
		local faction =
			Chronicles.Data:FindFactionByIdAndCollection(factionSelection.factionId, factionSelection.collectionName)
		if faction then
			-- Transform to book format and display
			local success, bookContent = pcall(private.Core.Factions.TransformFactionToBook, faction)
			if success and bookContent then
				factionBook:OnContentReceived(bookContent)
				return
			end
		end
	end

	factionBook:ShowEmptyBook(Locale["BookEmptyPromptFaction"])
end

--[[
    Re-render every book from the current selection state.

    Called on UIRefresh. Where a selection is still valid the reader keeps their page, because
    ContentUtils returns the cached content table for an unchanged entity and OnContentReceived
    retains the scroll position when the table is identical.
]]
function MainFrameUIMixin:RefreshBookContent()
	if not private.Core.StateManager then
		return
	end

	local getState = private.Core.StateManager.getState
	local buildSelectionKey = private.Core.StateManager.buildSelectionKey

	self:UpdateEventBookContent(getState(buildSelectionKey("event")))
	self:UpdateCharacterBookContent(getState(buildSelectionKey("character")))
	self:UpdateFactionBookContent(getState(buildSelectionKey("faction")))
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
	self:MoveTabSystemToDragStrip()

	self.EventsTabID = self:AddNamedTab("Events", self.Events)
	self.CharactersTabID = self:AddNamedTab("Characters", self.Characters)
	self.FactionsTabID = self:AddNamedTab("Factions", self.Factions)

	self.SettingsTabID = self:AddNamedTab("Settings", self.Settings)

	self.frameTabsToTabID = {
		[TabUIMixin.FrameTabs.Events] = self.EventsTabID,
		[TabUIMixin.FrameTabs.Characters] = self.CharactersTabID,
		[TabUIMixin.FrameTabs.Factions] = self.FactionsTabID,
		[TabUIMixin.FrameTabs.Settings] = self.SettingsTabID
	}
end

--[[
    Re-parent the tab strip from this container into the panel's DragStrip

    The TabSystem frame is declared inside TabUITemplate so parentKey resolution keeps working for
    TabSystemOwnerMixin, but a window's tabs belong at the top of the window, not at the bottom of
    its content area. Re-parenting (rather than anchoring across the two frame trees) keeps frame
    levels and mouse handling coherent: the tabs sit above the strip and eat their own clicks,
    while the strip stays draggable everywhere the tabs do not cover.
]]
function TabUIMixin:MoveTabSystemToDragStrip()
	local panel = self:GetParent()
	local dragStrip = panel and panel.DragStrip
	if not dragStrip or not self.TabSystem then
		return
	end

	self.TabSystem:SetParent(dragStrip)
	self.TabSystem:SetFrameLevel(dragStrip:GetFrameLevel() + 10)
	self.TabSystem:ClearAllPoints()
	self.TabSystem:SetPoint("LEFT", dragStrip, "LEFT", Spacing.md, 0)
end

function TabUIMixin:UpdateTabs()
	if not self:GetTab() then
		self:SetTab(self.EventsTabID)
	end
end

function TabUIMixin:SetTab(tabID)
	TabSystemOwnerMixin.SetTab(self, tabID)

	return true -- Don't show the tab as selected yet.
end

-- =============================================================================================
