local FOLDER_NAME, private = ...

private.constants.templates = {
	[private.constants.templateKeys.EVENTLIST_TITLE] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init},
	
	-- Generic shared template for the new VerticalListTemplate
	[private.constants.templateKeys.GENERIC_LIST_ITEM] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},
	
	-- Book system templates
	[private.constants.bookTemplateKeys.HTML_CONTENT] = {template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init}
}

