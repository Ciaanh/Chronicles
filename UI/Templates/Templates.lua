local FOLDER_NAME, private = ...

private.constants.templates = {
	[private.constants.templateKeys.EVENTLIST_TITLE] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init},
	
	-- Book content templates
	[private.constants.bookTemplateKeys.EVENT_TITLE] = {template = "EventTitleTemplate", initFunc = EventTitleMixin.Init},	
	[private.constants.bookTemplateKeys.SIMPLE_TITLE] = {template = "SimpleTitleTemplate", initFunc = SimpleTitleMixin.Init},
	
	-- Generic shared template for the new VerticalListTemplate
	[private.constants.templateKeys.GENERIC_LIST_ITEM] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},
		-- Book page content templates
	[private.constants.bookTemplateKeys.EMPTY] = {template = "EmptyTemplate", initFunc = EmptyMixin.Init},
	[private.constants.bookTemplateKeys.COVER_PAGE] = {template = "CoverPageTemplate", initFunc = CoverPageMixin.Init},
	[private.constants.bookTemplateKeys.AUTHOR] = {template = "AuthorTemplate", initFunc = AuthorMixin.Init},
	[private.constants.bookTemplateKeys.CHAPTER_HEADER] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	[private.constants.bookTemplateKeys.TEXT_CONTENT] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init},
	[private.constants.bookTemplateKeys.HTML_CONTENT] = {template = "HtmlPageTemplate", initFunc = HtmlPageMixin.Init}
}