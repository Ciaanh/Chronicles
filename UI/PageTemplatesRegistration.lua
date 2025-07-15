local FOLDER_NAME, private = ...

private.constants.templates = {
	[private.constants.templateKeys.EVENTLIST_TITLE] = {template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init},
	[private.constants.templateKeys.EVENT_DESCRIPTION] = {template = "EventListItemTemplate", initFunc = EventListItemMixin.Init},
	
	-- Generic shared template for the new VerticalListTemplate
	[private.constants.templateKeys.GENERIC_LIST_ITEM] = {template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init},
	
	-- Book system templates
	[private.constants.bookTemplateKeys.HTML_CONTENT] = {template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init}
}

-- Debug template registration
-- print("PageTemplatesRegistration: Templates being registered:")
-- for key, data in pairs(private.constants.templates) do
--     print("  - " .. tostring(key) .. " -> " .. tostring(data.template) .. " (mixin: " .. tostring(data.initFunc) .. ")")
-- end

-- Additional debug for HTML_CONTENT template specifically
-- local htmlTemplate = private.constants.templates[private.constants.bookTemplateKeys.HTML_CONTENT]
-- if htmlTemplate then
--     print("PageTemplatesRegistration: HTML_CONTENT template registered successfully:")
--     print("  Template: " .. tostring(htmlTemplate.template))
--     print("  InitFunc: " .. tostring(htmlTemplate.initFunc))
--     print("  HTMLContentMixin exists: " .. tostring(HTMLContentMixin ~= nil))
-- else
--     print("PageTemplatesRegistration: ERROR - HTML_CONTENT template not found!")
-- end