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

-- Every selection change lands in the navigation history, whatever made it: a rail row, a book link,
-- a timeline jump. See Core/Domain/Navigation.lua.
local function recordNavigation(kind, selection)
	if private.Core.Navigation then
		private.Core.Navigation.Record(kind, selection)
	end
end

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
					recordNavigation("event", newSelection)
				end
			},
			{
				key = private.Core.StateManager.buildSelectionKey("character"),
				id = frameName .. "_CharacterBook",
				callback = function(newSelection, oldSelection)
					self:UpdateCharacterBookContent(newSelection)
					recordNavigation("character", newSelection)
				end
			},
			{
				key = private.Core.StateManager.buildSelectionKey("faction"),
				id = frameName .. "_FactionBook",
				callback = function(newSelection, oldSelection)
					self:UpdateFactionBookContent(newSelection)
					recordNavigation("faction", newSelection)
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

	self:RegisterForEscape()

	self:InitializeNavigationBar()
	self:DockRailSearches()
end

-- The Characters and Factions rails keep their search box in the panel above them
function MainFrameUIMixin:DockRailSearches()
	local docks = {
		{tab = self.TabUI.Characters, rail = "MyCharacterList", label = "FindCharacterLabel"},
		{tab = self.TabUI.Factions, rail = "MyFactionList", label = "FindFactionLabel"}
	}

	for _, dock in ipairs(docks) do
		local panel = dock.tab and dock.tab.FindPanel
		local rail = dock.tab and dock.tab[dock.rail]
		if panel and rail and rail.DockSearchInto then
			panel.Label:SetText(Locale[dock.label])
			rail:DockSearchInto(panel)
		end
	end
end

-- =============================================================================================
-- NAVIGATION BAR (back, forward, breadcrumb)
-- =============================================================================================

-- How many entries the breadcrumb names, the current one included
local BREADCRUMB_LENGTH = 3

function MainFrameUIMixin:InitializeNavigationBar()
	local bar = self.NavigationBar
	local navigation = private.Core.Navigation
	if not bar or not navigation then
		return
	end

	-- Right of the tabs, now that TabUI has moved its tab system into the drag strip
	local tabSystem = self.TabUI and self.TabUI.TabSystem
	if tabSystem then
		bar:ClearAllPoints()
		bar:SetPoint("TOP", self.DragStrip, "TOP")
		bar:SetPoint("BOTTOM", self.DragStrip, "BOTTOM")
		bar:SetPoint("LEFT", tabSystem, "RIGHT", Spacing.xl, 0)
		bar:SetPoint("RIGHT", self.DragStrip, "RIGHT", -Spacing.xxl, 0)
	end

	bar.BackButton:SetScript(
		"OnClick",
		function()
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			navigation.Back()
		end
	)
	bar.ForwardButton:SetScript(
		"OnClick",
		function()
			PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
			navigation.Forward()
		end
	)

	for _, button in ipairs({bar.BackButton, bar.ForwardButton}) do
		button:SetScript(
			"OnEnter",
			function(owner)
				GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
				GameTooltip:SetText(owner == bar.BackButton and Locale["NavigationBack"] or Locale["NavigationForward"])
				GameTooltip:Show()
			end
		)
		button:SetScript("OnLeave", GameTooltip_Hide)
		-- Disabled buttons still show their tooltip, which says why nothing happens
		button:SetMotionScriptsWhileDisabled(true)
	end

	navigation.SetTabSwitcher(
		function(kind)
			self.TabUI:ShowTabForKind(kind)
		end
	)
	navigation.SetRevealer(
		function(entry)
			self:RevealEntry(entry)
		end
	)
	navigation.AddListener(
		function()
			self:UpdateNavigationBar()
		end
	)

	self:UpdateNavigationBar()
end

--[[
    The display name of a navigation entry: an event's label, a character's or faction's name
]]
local function entryName(entry)
	if not entry or not Chronicles.Data then
		return nil
	end

	local record
	if entry.kind == "event" then
		record = Chronicles.Data:FindEventByIdAndCollection(entry.id, entry.collection)
	elseif entry.kind == "character" then
		record = Chronicles.Data:FindCharacterByIdAndCollection(entry.id, entry.collection)
	elseif entry.kind == "faction" then
		record = Chronicles.Data:FindFactionByIdAndCollection(entry.id, entry.collection)
	end

	return record and (record.label or record.name) or nil
end

--[[
    Bring a record opened by a link or by Back/Forward into view beyond its book

    An event may sit in a period the timeline is not showing; the timeline moves to the period holding
    its first year, unless the selected period already overlaps the event (moving would be a jump for
    nothing). The rails then scroll to the row on the next frame, once the scroll box has laid out the
    period's rows.
]]
function MainFrameUIMixin:RevealEntry(entry)
	if not entry or not Chronicles.Data then
		return
	end

	local tabs = self.TabUI
	local rail = (entry.kind == "event" and tabs.Events.EventList) or
		(entry.kind == "character" and tabs.Characters.MyCharacterList) or
		(entry.kind == "faction" and tabs.Factions.MyFactionList)

	if entry.kind == "event" then
		local event = Chronicles.Data:FindEventByIdAndCollection(entry.id, entry.collection)
		local stateManager = private.Core.StateManager
		if event and stateManager and private.Core.Timeline and private.Core.Timeline.NavigateToYear then
			local period = stateManager.getState(stateManager.buildUIStateKey("selectedPeriod"))
			local yearEnd = event.yearEnd or event.yearStart
			local periodHoldsEvent = period and period.lower and period.upper and event.yearStart <= period.upper and
				yearEnd >= period.lower
			if not periodHoldsEvent then
				private.Core.Timeline.NavigateToYear(event.yearStart)
			end
		end
	end

	if rail and rail.RevealSelection then
		C_Timer.After(
			0,
			function()
				rail:RevealSelection()
			end
		)
	end
end

function MainFrameUIMixin:UpdateNavigationBar()
	local bar = self.NavigationBar
	local navigation = private.Core.Navigation
	if not bar or not navigation then
		return
	end

	bar.BackButton:SetEnabled(navigation.CanGoBack())
	bar.ForwardButton:SetEnabled(navigation.CanGoForward())

	-- Earlier entries grey, the open one white. A record that no longer resolves (its collection was
	-- disabled since) is left out rather than shown as a gap.
	local parts = {}
	local trail = navigation.GetTrail(BREADCRUMB_LENGTH)
	for index, entry in ipairs(trail) do
		local name = entryName(entry)
		if name then
			if index == #trail then
				table.insert(parts, WHITE_FONT_COLOR:WrapTextInColorCode(name))
			else
				table.insert(parts, GRAY_FONT_COLOR:WrapTextInColorCode(name))
			end
		end
	end

	bar.Breadcrumb:SetText(table.concat(parts, GRAY_FONT_COLOR:WrapTextInColorCode(Locale["NavigationSeparator"])))
end

--[[
    Let Escape close the window, the way every other panel in the game does.

    UISpecialFrames is the whole of the panel-management convention this frame adopts, and deliberately
    so. The rest of it -- a UIPanelWindows entry with a UIPanelLayout area -- is incompatible with what
    this window is: `area="center"` hands position to UIParent's panel manager, which re-anchors the frame
    every time it is shown. This frame is movable and persists where the reader put it under
    ui.windowPosition, so registering an area would make the window jump back on every open, and the
    reader's own choice is worth more than the convention. toplevel and frameStrata="DIALOG" are already
    set in XML, which covers the rest of what an area entry would have bought.

    Guarded against double registration: OnLoad runs once per frame, but the table is global and shared.
]]
function MainFrameUIMixin:RegisterForEscape()
	local frameName = self:GetName()
	if not frameName or type(UISpecialFrames) ~= "table" then
		return
	end

	for _, registered in pairs(UISpecialFrames) do
		if registered == frameName then
			return
		end
	end

	table.insert(UISpecialFrames, frameName)
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
	-- The book already open when the window opens is where Back must return to after the first link;
	-- it was never a selection *change*, so record it here.
	self.TabUI:RecordCurrentTabSelection()
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

--[[
    The left page of an empty book: what this tab holds, so the spread is balanced before the reader has
    selected anything.

    Formatted here rather than in BookContainerMixin because the book frame is handed content and knows
    nothing about the rail beside it, while this mixin already owns the selection-to-book mapping. Every
    count is best-effort: a nil from the cache means the line simply carries less, never that the empty
    book fails to draw.

    @param entityCount [number|nil] How many entries this tab lists
    @return [string|nil] Front-matter line, or nil to keep the old single-prompt behaviour
]]
local function formatEmptyBookFrontMatter(entityCount)
	local parts = {}

	local collections = private.Core.Cache and private.Core.Cache.getCollectionsNames()
	if type(collections) == "table" and #collections > 0 then
		table.insert(parts, string.format(Locale["BOOK_EMPTY_COLLECTIONS"], #collections))
	end

	if type(entityCount) == "number" and entityCount > 0 then
		table.insert(parts, string.format(Locale["BOOK_EMPTY_ENTITIES"], entityCount))
	end

	if #parts == 0 then
		return nil
	end

	return table.concat(parts, Locale["BOOK_FRONT_META_SEPARATOR"])
end

--[[
    How many entries a tab's rail is showing, for the empty book's front matter.

    Reads the rail's own cached array rather than re-querying the data layer: the rail has already
    flattened, sorted and filtered it, and this number should agree with the count label the reader can
    see beside it.

    @param listFrame [table|nil] The tab's rail frame
    @return [number|nil]
]]
local function railEntryCount(listFrame)
	if not listFrame then
		return nil
	end

	-- allItems on the Characters and Factions rail, periodEvents on the Events rail: the first holds a
	-- whole collection, the second only the selected period, and each is what its own count label shows.
	local items = listFrame.allItems or listFrame.periodEvents
	if type(items) ~= "table" then
		return nil
	end

	return #items
end

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
				self:UpdateEventFooterLinks(eventBook, event)
				return
			end
		end
	end

	eventBook:ShowEmptyBook(
		Locale["BookEmptyPromptEvent"],
		formatEmptyBookFrontMatter(railEntryCount(self.TabUI.Events.EventList))
	)
end

--[[
    Fill the previous/next links at the foot of an event's left page

    The neighbours in reading order: the same ordered list the rail and the timeline are built from. A
    click opens the neighbour through Navigation, so it lands in the history and moves the timeline when
    the neighbour sits in another period.
]]
function MainFrameUIMixin:UpdateEventFooterLinks(eventBook, event)
	local HTMLBuilder = private.Core.Utils.HTMLBuilder
	local FrontMatter = private.Core.Utils.FrontMatter
	if not eventBook.SetFooterLinks or not HTMLBuilder or not FrontMatter then
		return
	end

	local previous, nextEvent = FrontMatter.FindEventNeighbours(HTMLBuilder.GetOrderedEvents(), event)

	local function toLink(neighbour, formatKey)
		if not neighbour then
			return nil
		end
		return {
			title = string.format(Locale[formatKey], neighbour.label or ""),
			subtitle = HTMLBuilder.GetDateRangeText(neighbour.yearStart, neighbour.yearEnd),
			onClick = function()
				private.Core.Navigation.Open("event", neighbour.id, neighbour.source)
			end
		}
	end

	eventBook:SetFooterLinks(toLink(previous, "BOOK_FRONT_PREVIOUS"), toLink(nextEvent, "BOOK_FRONT_NEXT"))
end

function MainFrameUIMixin:UpdateCharacterBookContent(characterSelection)
	local characterBook = self.TabUI.Characters.Book
	if not characterBook then
		return
	end

	if characterSelection and characterSelection.characterId and characterSelection.collectionName then
		-- Check if Chronicles.Data is available
		if not Chronicles.Data then
			characterBook:ShowEmptyBook(
				Locale["BookEmptyPromptCharacter"],
				formatEmptyBookFrontMatter(railEntryCount(self.TabUI.Characters.MyCharacterList))
			)
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

	characterBook:ShowEmptyBook(
		Locale["BookEmptyPromptCharacter"],
		formatEmptyBookFrontMatter(railEntryCount(self.TabUI.Characters.MyCharacterList))
	)
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

	factionBook:ShowEmptyBook(
		Locale["BookEmptyPromptFaction"],
		formatEmptyBookFrontMatter(railEntryCount(self.TabUI.Factions.MyFactionList))
	)
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

	-- After the window's name when there is one
	if dragStrip.Brand then
		dragStrip.Brand:SetText(string.upper(Locale["Chronicles"] == true and "Chronicles" or Locale["Chronicles"]))
		self.TabSystem:SetPoint("LEFT", dragStrip.Brand, "RIGHT", Spacing.lg, 0)
	else
		self.TabSystem:SetPoint("LEFT", dragStrip, "LEFT", Spacing.md, 0)
	end
end

function TabUIMixin:UpdateTabs()
	if not self:GetTab() then
		self:SetTab(self.EventsTabID)
	end
end

function TabUIMixin:SetTab(tabID)
	TabSystemOwnerMixin.SetTab(self, tabID)

	-- Switching tabs by hand changes which book the reader is looking at, so it counts as a step in
	-- the history like any selection does. Navigation ignores this while it switches tabs itself.
	self:RecordCurrentTabSelection()

	return true -- Don't show the tab as selected yet.
end

-- The kind of record each content tab shows; Settings shows none
function TabUIMixin:GetKindForTab(tabID)
	if tabID == self.EventsTabID then
		return "event"
	elseif tabID == self.CharactersTabID then
		return "character"
	elseif tabID == self.FactionsTabID then
		return "faction"
	end
	return nil
end

function TabUIMixin:ShowTabForKind(kind)
	local tabID = (kind == "event" and self.EventsTabID) or (kind == "character" and self.CharactersTabID) or
		(kind == "faction" and self.FactionsTabID)
	if tabID and self:GetTab() ~= tabID then
		self:SetTab(tabID)
	end
end

function TabUIMixin:RecordCurrentTabSelection()
	local kind = self:GetKindForTab(self:GetTab())
	local stateManager = private.Core.StateManager
	if not kind or not stateManager then
		return
	end

	recordNavigation(kind, stateManager.getState(stateManager.buildSelectionKey(kind)))
end

-- =============================================================================================
