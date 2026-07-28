# Chronicles Addon - Book Templates Documentation

## Overview

The Chronicles addon uses a templating system to display lore content. As of v2.0.1, the primary path is HTML-based content via `HTMLContentTemplate`. Template registration is centralized in `UI/PageTemplatesRegistration.lua`.

## Template Keys and Mappings

### Book Content Templates (Primary)

| Template Key   | XML Template        | Lua Mixin        | Purpose                                      | Status |
| -------------- | ------------------- | ---------------- | -------------------------------------------- | ------ |
| `HTML_CONTENT` | HTMLContentTemplate | HTMLContentMixin | Complete HTML documents for all book content | Active |

### List and UI Component Templates

| Template Key        | XML Template             | Lua Mixin             | Purpose                              | Status |
| ------------------- | ------------------------ | --------------------- | ------------------------------------ | ------ |
| `GENERIC_LIST_ITEM` | VerticalListItemTemplate | VerticalListItemMixin | Generic list item for vertical lists | Active |
| `EVENTLIST_TITLE`   | EventListTitleTemplate   | EventListTitleMixin   | Event list section titles            | Active |
| `EVENT_DESCRIPTION` | EventListItemTemplate    | EventListItemMixin    | Event list item content              | Active |

Architecture note: `HTML_CONTENT` is the single source of truth for book display.

## Data Structures

### Input Entity Structure

```lua
{
  name = "Entity Name",
  label = "Fallback Label",
  description = "Entity description...",
  image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande.tga",
  author = "Author Name",
  yearStart = -10000,
  yearEnd = -9995,
  chapters = {
    { header = "Chapter Title", pages = { "Text or HTML..." } },
    -- ...
  }
}
```

### Transformed Structure (Modern HTML System)

```lua
{
  [1] = {
    elements = {
      {
        templateKey = "HTML_CONTENT",
        htmlContent = "<html><body>...complete HTML document...</body></html>",
        title = "Entity Name",
        entity = { ... }
      }
    }
  },
  navigationData = { totalPages = 1, chapters = { } }
}
```

## Registration

Templates are registered in `UI/PageTemplatesRegistration.lua`:

```lua
private.constants.templates = {
  [private.constants.bookTemplateKeys.HTML_CONTENT] = { template = "HTMLContentTemplate", initFunc = HTMLContentMixin.Init },
  [private.constants.templateKeys.GENERIC_LIST_ITEM] = { template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init },
  [private.constants.templateKeys.EVENTLIST_TITLE] = { template = "EventListTitleTemplate", initFunc = EventListTitleMixin.Init },
  [private.constants.templateKeys.EVENT_DESCRIPTION] = { template = "EventListItemTemplate", initFunc = EventListItemMixin.Init },
}
```

## Flow (Modern HTML)

1. Entity data (event/character/faction)
2. `ContentUtils.TransformEntityToBook(entity)`
3. `HTMLBuilder.CreateEntityHTML(entity)` generates complete HTML documents
4. Output: single section with `HTML_CONTENT` elements
5. UI: `BookContainerTemplate` → `HTMLContentTemplate`

## Template Definitions

### HTMLContentTemplate

-   Purpose: Scrollable SimpleHTML-based renderer for complete HTML documents
-   Mixin: `HTMLContentMixin`
-   Files: `UI/Book/HTMLContentTemplate.xml`, `UI/Book/HTMLContentTemplate.lua`
-   Data: `htmlContent` (required), optional `title`, `entity`

### VerticalListItemTemplate

-   Purpose: Generic list item for vertical lists
-   Mixin: `VerticalListItemMixin`
-   Files: `UI/VerticalListTemplate.xml`, `UI/VerticalListTemplate.lua`

### EventListTitleTemplate / EventListItemTemplate

-   Purpose: Specialized event list components
-   Mixins: `EventListTitleMixin` / `EventListItemMixin`
-   Files: `UI/Events/EventListTemplate.xml`, `UI/Events/EventListTemplate.lua`

## Best Practices

1. Use `HTML_CONTENT` for all book content
2. Register templates only in `PageTemplatesRegistration.lua`
3. Keep payloads small; generate heavy HTML on demand
4. Validate element data before Init
5. Localize all user-visible strings
