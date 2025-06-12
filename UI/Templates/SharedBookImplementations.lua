local FOLDER_NAME, private = ...

-- =============================================================================================
-- EVENT BOOK MIXIN - CONCRETE IMPLEMENTATION
-- =============================================================================================
--
-- Concrete implementation of SharedBookMixin for Events.
-- Provides event-specific behavior including data transformation,
-- date range validation, and integration with event domain logic.
--
-- USAGE EXAMPLE:
-- <Frame name="EventBookTemplate" inherits="SharedBookTemplate" mixin="EventBookMixin" virtual="true"/>
-- =============================================================================================

EventBookMixin = CreateFromMixins(SharedBookMixin)

-- =============================================================================================
-- ABSTRACT METHOD IMPLEMENTATIONS
-- =============================================================================================

function EventBookMixin:GetBookType()
	return "event"
end

function EventBookMixin:GetDataSource()
	return "Events"
end

function EventBookMixin:GetMixinName()
	return "EventBookMixin"
end

function EventBookMixin:TransformItemToBook(data)
	-- Use existing event transformation logic
	return private.Core.Events.TransformEventToBook(data)
end

function EventBookMixin:GetEmptyBook()
	-- Use existing empty event book
	return private.Core.Events.EmptyBook()
end

function EventBookMixin:CheckItemDateRange(itemData, period)
	-- Events use yearStart and yearEnd for date ranges
	if not itemData.yearStart or not itemData.yearEnd then
		return false
	end

	-- Event is in period if: event.yearStart <= period.upper AND event.yearEnd >= period.lower
	return itemData.yearStart <= period.upper and itemData.yearEnd >= period.lower
end

-- =============================================================================================
-- CHARACTER BOOK MIXIN - CONCRETE IMPLEMENTATION
-- =============================================================================================
--
-- Concrete implementation of SharedBookMixin for Characters.
-- Handles character-specific data patterns including birth/death dates
-- and character lifecycle management.
--
-- USAGE EXAMPLE:
-- <Frame name="CharacterBookTemplate" inherits="SharedBookTemplate" mixin="CharacterBookMixin" virtual="true"/>
-- =============================================================================================

CharacterBookMixin = CreateFromMixins(SharedBookMixin)

-- =============================================================================================
-- ABSTRACT METHOD IMPLEMENTATIONS
-- =============================================================================================

function CharacterBookMixin:GetBookType()
	return "character"
end

function CharacterBookMixin:GetDataSource()
	return "Characters"
end

function CharacterBookMixin:GetMixinName()
	return "CharacterBookMixin"
end

function CharacterBookMixin:TransformItemToBook(data)
	-- Use character transformation logic (assuming it exists similar to events)
	-- If this doesn't exist yet, it would need to be created
	if private.Core.Characters and private.Core.Characters.TransformCharacterToBook then
		return private.Core.Characters.TransformCharacterToBook(data)
	else
		-- Fallback: create basic book structure for characters
		return self:CreateBasicCharacterBook(data)
	end
end

function CharacterBookMixin:GetEmptyBook()
	-- Use character empty book (assuming it exists similar to events)
	if private.Core.Characters and private.Core.Characters.EmptyBook then
		return private.Core.Characters.EmptyBook()
	else
		-- Fallback: create empty character book
		return {
			{
				template = private.constants.templateKeys.EMPTY,
				text = "No character selected"
			}
		}
	end
end

function CharacterBookMixin:CheckItemDateRange(itemData, period)
	-- Characters might have birth/death dates or active periods
	-- Support multiple date field formats for compatibility
	local birthYear = itemData.yearBorn or itemData.birthYear or itemData.yearStart
	local deathYear = itemData.yearDied or itemData.deathYear or itemData.yearEnd or period.upper -- Assume still alive if no death date

	if not birthYear then
		return false
	end

	-- Character is in period if their lifespan overlaps with the period
	return birthYear <= period.upper and deathYear >= period.lower
end

function CharacterBookMixin:CreateBasicCharacterBook(data)
	-- Fallback method to create basic character book structure
	local book = {}

	-- Add character title
	if data.name or data.label then
		table.insert(
			book,
			{
				template = private.constants.templateKeys.CHARACTER_TITLE,
				text = data.name or data.label
			}
		)
	end

	-- Add character description if available
	if data.description then
		table.insert(
			book,
			{
				template = private.constants.templateKeys.TEXT_CONTENT,
				text = data.description
			}
		)
	end

	return book
end

-- =============================================================================================
-- FACTION BOOK MIXIN - CONCRETE IMPLEMENTATION
-- =============================================================================================
--
-- Concrete implementation of SharedBookMixin for Factions.
-- Handles faction-specific data patterns including founding/dissolution dates
-- and faction political lifecycle.
--
-- USAGE EXAMPLE:
-- <Frame name="FactionBookTemplate" inherits="SharedBookTemplate" mixin="FactionBookMixin" virtual="true"/>
-- =============================================================================================

FactionBookMixin = CreateFromMixins(SharedBookMixin)

-- =============================================================================================
-- ABSTRACT METHOD IMPLEMENTATIONS
-- =============================================================================================

function FactionBookMixin:GetBookType()
	return "faction"
end

function FactionBookMixin:GetDataSource()
	return "Factions"
end

function FactionBookMixin:GetMixinName()
	return "FactionBookMixin"
end

function FactionBookMixin:TransformItemToBook(data)
	-- Use faction transformation logic (assuming it exists similar to events)
	-- If this doesn't exist yet, it would need to be created
	if private.Core.Factions and private.Core.Factions.TransformFactionToBook then
		return private.Core.Factions.TransformFactionToBook(data)
	else
		-- Fallback: create basic book structure for factions
		return self:CreateBasicFactionBook(data)
	end
end

function FactionBookMixin:GetEmptyBook()
	-- Use faction empty book (assuming it exists similar to events)
	if private.Core.Factions and private.Core.Factions.EmptyBook then
		return private.Core.Factions.EmptyBook()
	else
		-- Fallback: create empty faction book
		return {
			{
				template = private.constants.templateKeys.EMPTY,
				text = "No faction selected"
			}
		}
	end
end

function FactionBookMixin:CheckItemDateRange(itemData, period)
	-- Factions might have founding/dissolution dates
	-- Support multiple date field formats for compatibility
	local foundedYear = itemData.yearFounded or itemData.foundedYear or itemData.yearStart
	local dissolvedYear = itemData.yearDisbanded or itemData.dissolvedYear or itemData.yearEnd or period.upper -- Assume still active if no dissolution date

	if not foundedYear then
		return false
	end

	-- Faction is in period if their existence overlaps with the period
	return foundedYear <= period.upper and dissolvedYear >= period.lower
end

function FactionBookMixin:CreateBasicFactionBook(data)
	-- Fallback method to create basic faction book structure
	local book = {}

	-- Add faction title
	if data.name or data.label then
		table.insert(
			book,
			{
				template = private.constants.templateKeys.FACTION_TITLE,
				text = data.name or data.label
			}
		)
	end

	-- Add faction description if available
	if data.description then
		table.insert(
			book,
			{
				template = private.constants.templateKeys.TEXT_CONTENT,
				text = data.description
			}
		)
	end

	return book
end
