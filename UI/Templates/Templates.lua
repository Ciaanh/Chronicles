local FOLDER_NAME, private = ...

private.constants.templates = {
	[private.constants.templateKeys.EVENTLIST_TITLE] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init},
	[private.constants.templateKeys.EVENT_TITLE] = {template = "EventTitleTemplate", initFunc = EventTitleMixin.Init},
	
	[private.constants.templateKeys.CHARACTER_TITLE] = {template = "CharacterTitleTemplate", initFunc = CharacterTitleMixin.Init},
	[private.constants.templateKeys.VERTICAL_CHARACTER_LIST_ITEM] = {template = "VerticalCharacterListItemTemplate", initFunc = VerticalCharacterListItemMixin.Init},
	
	[private.constants.templateKeys.FACTION_TITLE] = {template = "FactionTitleTemplate", initFunc = FactionTitleMixin.Init},
	[private.constants.templateKeys.FACTION_LIST_ITEM] = {template = "FactionListItemTemplate", initFunc = FactionListItemMixin.Init},

	[private.constants.templateKeys.EMPTY] = {template = "EmptyTemplate", initFunc = EmptyMixin.Init},
	[private.constants.templateKeys.AUTHOR] = {template = "AuthorTemplate", initFunc = AuthorMixin.Init},
	[private.constants.templateKeys.HEADER] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	[private.constants.templateKeys.TEXT_CONTENT] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init},
	[private.constants.templateKeys.HTML_CONTENT] = {template = "HtmlPageTemplate", initFunc = HtmlPageMixin.Init}
}