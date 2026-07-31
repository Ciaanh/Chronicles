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
| `GENERIC_LIST_ITEM` | VerticalListItemTemplate | VerticalListItemMixin | Rail row on Characters and Factions | Active |
| `EVENT_DESCRIPTION` | VerticalListItemTemplate | VerticalListItemMixin | Rail row on Events                   | Active |

Both list keys resolve to the **same** row template as of v2.3.0. The keys stay distinct because the two
list mixins are distinct — `EventListMixin` is period-driven, `VerticalListMixin` is search-driven, and
each resolves its own key — but the row is one thing. The Events tab's own `EventListItemTemplate` was
the same bookmark art at a different height with no hover and no selected state, and is gone.

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
  [private.constants.templateKeys.EVENT_DESCRIPTION] = { template = "VerticalListItemTemplate", initFunc = VerticalListItemMixin.Init },
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

-   Purpose: The one rail row, used by Events, Characters and Factions alike
-   Mixin: `VerticalListItemMixin`
-   Files: `UI/VerticalListTemplate.xml`, `UI/VerticalListTemplate.lua`
-   88 high, declared both as the template's `<Size y>` and as `SetElementExtent(88)` in each list
    mixin: a linear scroll view sizes rows from the extent and never reads the template's size, so the
    numbers must move together.
-   `Init` needs `item.name`. It returns early without it, so a row renders blank rather than raising —
    which is why the Events producer copies `event.label` to `name`.
-   `OnClick` writes the selection state, and the field name is per type: `eventId`, `characterId` or
    `factionId`. Each book consumer in `MainFrameUI` reads exactly one of them and ignores anything
    else, so a row type with no branch looks like it does nothing when clicked.

## Best Practices

1. Use `HTML_CONTENT` for all book content
2. Register templates only in `PageTemplatesRegistration.lua`
3. Keep payloads small; generate heavy HTML on demand
4. Validate element data before Init
5. Localize all user-visible strings
