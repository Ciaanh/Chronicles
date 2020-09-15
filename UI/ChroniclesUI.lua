local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI = {}

-----------------------------------------------------------------------------------------
-- UI Fonctions -------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function Chronicles.UI:Init()
    MainFrame:SetBackdrop(
        {
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tileEdge = false,
            edgeSize = 26
        }
    )
    Chronicles.UI.Timeline:Init()
    Chronicles.UI.EventList:Init()
end

function Chronicles.UI:DisplayWindow()
    Chronicles.DB:LoadRolePlayProfile()
    MainFrame:Show()
end

function Chronicles.UI:HideWindow()
    MainFrame:Hide()
end

function Chronicles.UI:HideViews()
    EventsView:Hide()
    FactionsView:Hide()
    CharactersView:Hide()
    OptionsView:Hide()
end

function EventsViewShow_Click()
    Chronicles.UI:HideViews()
    EventsView:Show()
    PanelTemplates_SetTab(MainFrame, 1)
end

function CharactersViewShow_Click()
    Chronicles.UI:HideViews()
    CharactersView:Show()
    PanelTemplates_SetTab(MainFrame, 2)
end

function FactionsViewShow_Click()
    Chronicles.UI:HideViews()
    FactionsView:Show()
    PanelTemplates_SetTab(MainFrame, 3)
end

function OptionsViewShow_Click()
    Chronicles.UI:HideViews()
    OptionsView:Show()
    PanelTemplates_SetTab(MainFrame, 4)
end

function MainFrame_OnLoad(self)
    self.Tabs = {self.tab1, self.tab2, self.tab3, self.tab4};
    PanelTemplates_SetNumTabs(self, 4);
    PanelTemplates_SetTab(self, 1)
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
