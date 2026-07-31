local FOLDER_NAME, private = ...

private.constants.templates = {
	-- Both rails render the same row. EVENT_DESCRIPTION and GENERIC_LIST_ITEM stay distinct keys
	-- because the two list mixins are distinct (period-driven vs search-driven) and each resolves its
	-- own key, but the row template they resolve to is one thing: VerticalListItemTemplate. The Events
	-- tab's own EventListItemTemplate was the same bookmark art at a different height with no hover
	-- and no selected state, and is gone.
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},

	[private.constants.templateKeys.GENERIC_LIST_ITEM] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},
	
	-- Book system templates
	[private.constants.bookTemplateKeys.HTML_CONTENT] = {template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init}
}

