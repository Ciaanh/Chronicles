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
        frame.TabUI.Tabs["SettingsHome"] = {
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
