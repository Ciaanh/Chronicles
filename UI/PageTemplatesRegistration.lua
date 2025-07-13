local FOLDER_NAME, private = ...

private.constants.templates = {
	[private.constants.templateKeys.EVENTLIST_TITLE] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init},
	
	-- Generic shared template for the new VerticalListTemplate
	[private.constants.templateKeys.GENERIC_LIST_ITEM] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},
	
	-- Book content templates - unified system
	[private.constants.bookTemplateKeys.EVENT_TITLE] = {template = "EventTitleTemplate", initFunc = EventTitleMixin.Init},	
	[private.constants.bookTemplateKeys.SIMPLE_TITLE] = {template = "SimpleTitleTemplate", initFunc = SimpleTitleMixin.Init},
	[private.constants.bookTemplateKeys.EMPTY] = {template = "EmptyTemplate", initFunc = EmptyMixin.Init},
	[private.constants.bookTemplateKeys.COVER_PAGE] = {template = "CoverPageTemplate", initFunc = CoverPageMixin.Init},
	
	-- Old format templates (for compatibility)
	[private.constants.bookTemplateKeys.CHAPTER_HEADER] = {template = "ChapterHeaderTemplate", initFunc = ChapterHeaderMixin.Init},
	[private.constants.bookTemplateKeys.TEXT_CONTENT] = {template = "ChapterLineTemplate", initFunc = ChapterLineMixin.Init},
	[private.constants.bookTemplateKeys.HTML_CONTENT] = {template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init},
	
	-- HTML content templates - primary content system
	[private.constants.bookTemplateKeys.UNIFIED_CONTENT] = {template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init},
	[private.constants.bookTemplateKeys.COVER_WITH_CONTENT] = {template = "CoverWithContentTemplate", initFunc = CoverWithContentMixin.Init},
	[private.constants.bookTemplateKeys.PAGE_BREAK] = {template = "PageBreakTemplate", initFunc = PageBreakMixin.Init}
}