local T = _G.T
local H = _G.H
local assert_ = T.assert

local private = H.newPrivate()
H.loadModule("Core/Utils/UIUtils.lua", private)
H.loadModule("UI/Settings/Settings.lua", private)

local SettingsMixin = _G.SettingsMixin

T.describe("SettingsMixin", function()
    T.it("loads without crashing when the tab scroll frame has no scrollbar object", function()
        local frame = {
            TabUI = {
                Tabs = {},
                currentTab = "EventTypes"
            },
            Buttons = {},
            prefix = "Entry"
        }
        frame.TabUI = frame.TabUI or {}
        frame.TabUI.Tabs = frame.TabUI.Tabs or {}

        local tabFrame = {}
        local scrollFrame = {
            Content = {
                checkboxes = {}
            }
        }
        tabFrame.ScrollFrame = scrollFrame
        function tabFrame:SetShown() end

        local tab = {
            Load = function() end,
            TabFrame = tabFrame,
            IsLoaded = false
        }

        frame.TabUI.Tabs["EventTypes"] = tab
        -- A second tab, so the loop has one to deselect: the panel has two categories, Event types and
        -- Collections, and selecting either must hide the other.
        frame.TabUI.Tabs["Collections"] = {
            Load = function() end,
            TabFrame = {},
            IsLoaded = false
        }

        local ok, err = pcall(function()
            SettingsMixin:OnSettingsTabSelected("EventTypes")
        end)

        assert_.isTrue(ok, err)
    end)

    T.it("loads the event-type list without calling old Slider methods on a modern scroll bar", function()
        -- Regression for the in-game crash: ScrollFrameMixin builds a modern ScrollBox-style scroll
        -- bar (SetScrollPercentage / OnScrollRangeChanged), which has no SetMinMaxValues/SetValue, so
        -- LoadEventTypes must not reach for the old Slider API on it. An empty eventType list keeps
        -- the checkbox loop out of the way so the test exercises only the scroll-reset path.
        private.constants = private.constants or {}
        private.constants.eventType = {}

        local content = {checkboxes = {}}
        function content:SetSize() end
        function content:Show() end

        -- Deliberately omits SetMinMaxValues/SetValue: the old code called them here and crashed.
        local scrollBar = {}
        function scrollBar:Show() end
        function scrollBar:SetShown() end

        local scrollFrame = {
            Content = content,
            ScrollBar = scrollBar,
            scrollBarHideIfUnscrollable = true
        }
        function scrollFrame:GetWidth() return 400 end
        function scrollFrame:GetVerticalScrollRange() return 0 end
        function scrollFrame:SetVerticalScroll() end
        function scrollFrame:Show() end

        local ok, err = pcall(function()
            SettingsMixin:LoadEventTypes({ScrollFrame = scrollFrame})
        end)

        assert_.isTrue(ok, err)
    end)
end)

T.describe("SettingsMixin checkbox columns", function()
    -- Two columns, and the scroll-child height has to agree with them. The height was computed in three
    -- separate places against a one-column layout; a height that disagrees with the content hides the
    -- scroll bar while the content is still clipped, which is a silent failure.
    T.it("computes the height for two columns, not one", function()
        -- 7 event types fill 4 rows: 4 * 33 + 30 = 162, under the 200 floor
        assert_.equals(SettingsMixin.ComputeCheckboxContentHeight(7), 200)

        -- 15 collections fill 8 rows: 8 * 33 + 30 = 294, which is the point of the change -- one column
        -- would have needed 15 * 33 + 30 = 525 and scrolled
        assert_.equals(SettingsMixin.ComputeCheckboxContentHeight(15), 294)
    end)

    T.it("rounds an odd count up to a whole row", function()
        assert_.equals(SettingsMixin.ComputeCheckboxContentHeight(15), SettingsMixin.ComputeCheckboxContentHeight(16))
    end)

    T.it("never returns less than the minimum page height", function()
        assert_.equals(SettingsMixin.ComputeCheckboxContentHeight(0), 200)
        assert_.equals(SettingsMixin.ComputeCheckboxContentHeight(nil), 200)
    end)
end)

T.describe("SettingsMixin categories", function()
    T.it("presents two flat categories, not three across two levels", function()
        -- "Settings" is the panel header now, so the only categories are the two that configure
        -- something, and GetVisibleCategories has no submenu to flatten.
        local frame = {}
        local configured = {
            {text = "Event types", TabName = "EventTypes", TabFrame = {}},
            {text = "Collections", TabName = "Collections", TabFrame = {}}
        }

        local visible = SettingsMixin.GetVisibleCategories(frame, configured)

        assert_.equals(#visible, 2)
        assert_.equals(visible[1].TabName, "EventTypes", "and Event types is the default tab")
        assert_.equals(visible[1].level, 1, "both sit at the top level")
        assert_.equals(visible[2].level, 1)
    end)
end)
