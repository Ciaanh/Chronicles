local FOLDER_NAME, private = ...
local Chronicles = private.Core

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.EventDescription = {}
Chronicles.UI.EventDescription.CurrentPage = nil
Chronicles.UI.EventDescription.CurrentEvent = nil

function Chronicles.UI.Timeline:Refresh()
    self.CurrentEvent = nil
    self.CurrentPage = nil

    EventTitle:SetText("")
    EventDescriptionHTML:SetText("")
    EventDescriptionBounds:SetText("")

    EventDescriptionPrevious:Hide()
    EventDescriptionNext:Hide()
    EventDescriptionPager:Hide()
end

function Chronicles.UI.EventDescription:DrawEventDescription(event)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Call to DrawEventDescription " .. event.label)
    self.CurrentEvent = event
    self.CurrentPage = 1

    EventTitle:SetText(event.label)
    EventDescriptionHTML:SetText(event.description[1])

    local eventDates = Locale["start"] .. " : " .. event.yearStart .. "    " .. Locale["end"] .. " : " .. event.yearEnd
    if (event.yearStart == event.yearEnd) then
        eventDates = Locale["year"] .. " : " .. event.yearStart
    end
    EventDescriptionBounds:SetText(eventDates)

    self:SetDescriptionPager(1, Chronicles:GetTableLength(event.description))
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Display description " .. event.description[1])
end

function Chronicles.UI.EventDescription:ChangeEventDescriptionPage(page)
    -- DEFAULT_CHAT_FRAME:AddMessage("-- Call to ChangeEventDescriptionPage " .. page)

    local event = self.CurrentEvent
    if (event ~= nil and event.description ~= nil) then
        local numberOfPages = Chronicles:GetTableLength(event.description)

        if (page < 1) then
            page = 1
        end
        if (page > numberOfPages) then
            page = numberOfPages
        end

        if (event.description[page] ~= nil) then
            self.CurrentPage = page
            EventDescriptionHTML:SetText(event.description[page])
            self:SetDescriptionPager(page, numberOfPages)
        end
    end
end

function Chronicles.UI.EventDescription:SetDescriptionPager(currentPage, maxPage)
    EventDescriptionPrevious:Hide()
    EventDescriptionNext:Hide()
    EventDescriptionPager:Hide()

    if (maxPage ~= 1) then
        local text = "" .. currentPage .. " / " .. maxPage
        EventDescriptionPager:SetText(text)

        if (currentPage <= 1) then
            EventDescriptionPrevious:Disable()
        else
            EventDescriptionPrevious:Enable()
        end

        if (currentPage >= maxPage) then
            EventDescriptionNext:Disable()
        else
            EventDescriptionNext:Enable()
        end

        EventDescriptionPager:Show()
        EventDescriptionPrevious:Show()
        EventDescriptionNext:Show()
    end
end

------------------------------------------------------------------------------------------
-- Description Paging --------------------------------------------------------------------
------------------------------------------------------------------------------------------
function EventDescriptionPreviousButton_OnClick(self)
    Chronicles.UI.EventDescription:ChangeEventDescriptionPage(Chronicles.UI.EventDescription.CurrentPage - 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function SetPreviousButtonText()
    EventDescriptionPrevious:SetText("<")
end

function EventDescriptionNextButton_OnClick(self)
    Chronicles.UI.EventDescription:ChangeEventDescriptionPage(Chronicles.UI.EventDescription.CurrentPage + 1)
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end

function SetNextButtonText()
    EventDescriptionNext:SetText(">")
end
