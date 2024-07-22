local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.MyJournalView = {}

function Chronicles.UI.MyJournalView:Init()
    MyJournalView.Title:SetText(Locale["My Journal"])

    -- print("-- init MyJournalView")

    Chronicles.UI.MyEvents:Init(true)
    Chronicles.UI.MyCharacters:Init(false)
    Chronicles.UI.MyFactions:Init(false)
end

function Chronicles.UI.MyJournalView:HideViews()
    MyEvents:Hide()
    MyCharacters:Hide()
    MyFactions:Hide()
end

function MyJournalView_OnLoad(self)
    self.Tabs = {self.tab1, self.tab2, self.tab3}
    PanelTemplates_SetNumTabs(self, 3)
    PanelTemplates_SetTab(self, 1)

    self.tab1:SetText(Locale["My Events"])
    self.tab2:SetText(Locale["My Characters"])
    self.tab3:SetText(Locale["My Factions"])
end

function MyEventsTabButton_Click()
    Chronicles.UI.MyJournalView:HideViews()
    MyEvents:Show()
    PanelTemplates_SetTab(MyJournalView, 1)
end
function MyCharactersTabButton_Click()
    Chronicles.UI.MyJournalView:HideViews()
    MyCharacters:Show()
    PanelTemplates_SetTab(MyJournalView, 2)
end
function MyFactionsTabButton_Click()
    Chronicles.UI.MyJournalView:HideViews()
    MyFactions:Show()
    PanelTemplates_SetTab(MyJournalView, 3)
end