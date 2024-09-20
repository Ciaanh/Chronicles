local FOLDER_NAME, private = ...
local Chronicles = private.Chronicles

local Locale = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)

Chronicles.UI.EventDescription = {}
Chronicles.UI.EventDescription.CurrentPage = nil
Chronicles.UI.EventDescription.CurrentEvent = nil

Chronicles.UI.EventDescription.CurrentFactionsCharactersResults = {}

function Chronicles.UI.EventDescription:Refresh()
    --if (self.CurrentEvent ~= nil and not Chronicles.DB:GetLibraryStatus(self.CurrentEvent.source)) then
    self.CurrentEvent = nil
    self.CurrentPage = nil
    self.CurrentFactionsCharactersResults = {}

    EventTitle:SetText("")
    EventDescriptionHTML:SetText("")
    EventDescriptionBounds:SetText("")

    EventDescriptionPrevious:Hide()
    EventDescriptionNext:Hide()
    EventDescriptionPager:Hide()

    EventDescription.FactionsButton:Hide()
    EventDescription.CharactersButton:Hide()
    --end
end

function Chronicles.UI.EventDescription:DrawEventDescription(event)
    -- print("-- Call to DrawEventDescription " .. event.label)
    self.CurrentEvent = event
    self.CurrentPage = 1
    self.CurrentFactionsCharactersResults = {}

    EventDescription.FactionsButton:Hide()
    EventDescription.CharactersButton:Hide()

    EventTitle:SetText(adjustTextLength(event.label, 45, EventTitleContainer))
    local firstPage = event.description[1]
    if (firstPage ~= nil) then
        EventDescriptionHTML:SetText(firstPage)
    else
        EventDescriptionHTML:SetText("")
    end

    local eventDates = Locale["start"] .. " : " .. event.yearStart .. "    " .. Locale["end"] .. " : " .. event.yearEnd
    if (event.yearStart == event.yearEnd) then
        eventDates = Locale["year"] .. " : " .. event.yearStart
    end
    EventDescriptionBounds:SetText(eventDates)

    self:SetDescriptionPager(1, tablelength(event.description))
    -- print("-- Display description " .. event.description[1])

    if (event.factions ~= nil and tablelength(Chronicles.DB:FindFactions(event.factions)) > 0) then
        EventDescription.FactionsButton:Show()
    end

    if (event.characters ~= nil and tablelength(Chronicles.DB:FindCharacters(event.characters)) > 0) then
        EventDescription.CharactersButton:Show()
    end
end

function Chronicles.UI.EventDescription:ChangeEventDescriptionPage(page)
    -- print("-- ChangeEventDescriptionPage " .. page)

    local event = self.CurrentEvent
    if (event ~= nil and event.description ~= nil) then
        local numberOfPages = tablelength(event.description)

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
end

function SetPreviousButtonText()
    EventDescriptionPrevious:SetText("<")
end

function EventDescriptionNextButton_OnClick(self)
    Chronicles.UI.EventDescription:ChangeEventDescriptionPage(Chronicles.UI.EventDescription.CurrentPage + 1)
end

function SetNextButtonText()
    EventDescriptionNext:SetText(">")
end

function EventFactionsButton_OnClick(self)
    -- print("-- EventFactionsButton_OnClick ")
    local currentEvent = Chronicles.UI.EventDescription.CurrentEvent

    if (currentEvent ~= nil and currentEvent.factions and tablelength(currentEvent.factions) > 0) then
        local factionsList = Chronicles.DB:FindFactions(currentEvent.factions)

        Chronicles.UI.EventDescription.CurrentFactionsCharactersResults = MapFactionsToItems(factionsList)

        EventDescription_FactionsCharactersResults(EventDescription.FactionsCharactersResults, Locale["Factions_List"])
        EventDescription.FactionsCharactersResults:Show()
    else
        EventDescription.FactionsCharactersResults:Hide()
    end
end

function MapFactionsToItems(factions)
    local maxDescriptionLength = 75

    local results = {}

    for index, faction in ipairs(factions) do
        local item = {
            name = faction.name,
            description = ""
        }

        if (not containsHTML(faction.description)) then
            item.description = faction.description:sub(0, maxDescriptionLength)
        end
        -- print("-- MapFactionsToItems " .. item.name .. " " .. item.description)
        table.insert(results, item)
    end

    return results
end

function EventFactionsButton_OnLoad(self)
    self.label:SetText(Locale["Factions_List"])
end

function EventCharactersButton_OnClick(self)
    -- print("-- EventCharactersButton_OnClick ")
    -- local charactersList = Chronicles.DB:FindCharacters(event.characters)

    local currentEvent = Chronicles.UI.EventDescription.CurrentEvent

    if (currentEvent ~= nil and currentEvent.characters and tablelength(currentEvent.characters) > 0) then
        local charactersList = Chronicles.DB:FindCharacters(currentEvent.characters)

        Chronicles.UI.EventDescription.CurrentFactionsCharactersResults = MapCharactersToItems(charactersList)

        EventDescription_FactionsCharactersResults(
            EventDescription.FactionsCharactersResults,
            Locale["Characters_List"]
        )
        EventDescription.FactionsCharactersResults:Show()
    else
        EventDescription.FactionsCharactersResults:Hide()
    end
end

function MapCharactersToItems(characters)
    local maxDescriptionLength = 75

    local results = {}

    for index, character in ipairs(characters) do
        local item = {
            name = character.name,
            description = ""
        }

        if (not containsHTML(character.biography)) then
            item.description = character.biography:sub(0, maxDescriptionLength)
        end

        -- print("-- MapCharactersToItems " .. item.name .. " " .. item.description)
        table.insert(results, item)
    end

    return results
end

function EventCharactersButton_OnLoad(self)
    self.label:SetText(Locale["Characters_List"])
end

function EventDescriptionButton_OnLoad(self)
    local scrollFrame = EventDescription.FactionsCharactersResults.scrollFrame
    scrollFrame.update = EventDescription_FactionsCharactersResults
    scrollFrame.scrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "FullSearchResultsButton", 5, 0)
end

function EventDescription_FactionsCharactersResults(self, title)
    local numResults = tablelength(Chronicles.UI.EventDescription.CurrentFactionsCharactersResults)

    local scrollFrame = EventDescription.FactionsCharactersResults.scrollFrame
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local results = scrollFrame.buttons
    local result, index

    for i = 1, #results do
        result = results[i]
        index = offset + i
        if (index <= numResults) then
            local item = Chronicles.UI.EventDescription.CurrentFactionsCharactersResults[index]

            result.name:SetText(item.name)
            -- result.icon:SetTexture(icon)
            result.description:SetText(item.description)

            result:Show()
        else
            result:Hide()
        end
    end

    local totalHeight = numResults * 49
    HybridScrollFrame_Update(scrollFrame, totalHeight, 270)

    if (title ~= nil) then
        EventDescription.FactionsCharactersResults.titleText:SetText(title)
    else
        EventDescription.FactionsCharactersResults.titleText:SetText("")
    end
end
