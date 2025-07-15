# Chronicles Addon - Book Templates Documentation

## Overview

The Chronicles addon uses a sophisticated templating system to display World of Warcraft lore content. As of v2.0.1, the system features modern HTML-based content display. The primary book content uses a unified HTML container approach via `HTMLContentTemplate`, along with specialized list components for UI elements.

The template registration is managed through `UI/PageTemplatesRegistration.lua`, which maps template keys to their corresponding XML templates and Lua mixins.

## Template Keys and Mappings

### Book Content Templates (Primary System)

| Template Key         | XML Template           | Lua Mixin           | Purpose                                      | Status |
|---------------------|-----------------------|---------------------|----------------------------------------------|--------|
| `HTML_CONTENT`      | HTMLContentTemplate   | HTMLContentMixin    | **Primary**: Complete HTML documents for all content types | **Active** |

### List and UI Component Templates

| Template Key         | XML Template           | Lua Mixin           | Purpose                                      | Status |
|---------------------|-----------------------|---------------------|----------------------------------------------|--------|
| `GENERIC_LIST_ITEM` | VerticalListItemTemplate | VerticalListItemMixin | Generic list item for vertical lists (characters, factions) | **Active** |
| `EVENTLIST_TITLE`   | EventListTitleTemplate | EventListTitleMixin | Event list section titles                    | **Active** |
| `EVENT_DESCRIPTION` | EventListItemTemplate  | EventListItemMixin  | Event list item content                      | **Active** |

> **Architecture Note:** The system uses `HTML_CONTENT` for all book display, which provides rich formatting and unified content handling.

## Data Structures

### Input Entity Structure

```lua
{
    name = "Entity Name",                    -- Display name
    label = "Alternative Label",             -- Fallback if name is missing
    description = "Entity description...",   -- Text or HTML description
    image = "path/to/image.tga",            -- Portrait/image path
    author = "Author Name",                  -- Creator attribution
    yearStart = 25,                         -- For events: start year (optional)
    yearEnd = 30,                           -- For events: end year (optional)
    chapters = {                            -- Content chapters
        {
            header = "Chapter Title",        -- Chapter title text or localization key
            pages = {                       -- Array of page content
                "Text content or localization key",
                "More content...",
                -- Additional pages...
            }
        },
        -- Additional chapters...
    }
}
```

### Transformed Data Structure (Modern HTML System)

The modern transformation produces a single-section array with one HTML element:

```lua
{
    [1] = {
        elements = {
            {
                templateKey = "HTML_CONTENT",
                htmlContent = "<html><body>...complete HTML document...</body></html>",
                title = "Entity Name",       -- optional
                entity = {...}              -- optional original entity reference
            }
        }
    }
}
```

## Architecture and Template Registration

### Template Registration System

Templates are registered in `UI/PageTemplatesRegistration.lua`:

```lua
private.constants.templates = {
    -- Modern HTML system
    [private.constants.bookTemplateKeys.HTML_CONTENT] = {
        template = "HTMLContentTemplate", 
        initFunc = HTMLContentMixin.Init
    },
    
    -- List components
    [private.constants.templateKeys.GENERIC_LIST_ITEM] = {
        template = "VerticalListItemTemplate", 
        initFunc = VerticalListItemMixin.Init
    },
    
    -- Event list components
    [private.constants.templateKeys.EVENTLIST_TITLE] = {
        template = "EventListTitleTemplate", 
        initFunc = EventListTitleMixin.Init
    },
    [private.constants.templateKeys.EVENT_DESCRIPTION] = {
        template = "EventListItemTemplate", 
        initFunc = EventListItemMixin.Init
    }
}
```

### Book Container System

The main book display uses `BookContainerTemplate` which supports modern HTML content:

- **Modern Path**: `ContentUtils.TransformEntityToBook()` → `HTML_CONTENT` → `HTMLContentTemplate`

## Transformation Flow

### Modern HTML Flow

1. **Entity Data** (event, character, faction)
2. **ContentUtils.TransformEntityToBook()** - Transforms entity to book format
3. **HTMLBuilder.CreateEntityHTML()** - Generates complete HTML document
4. **Output**: Single section with `HTML_CONTENT` element
5. **UI Rendering**: `BookContainerTemplate` → `HTMLContentTemplate` → Rich HTML display

## Template Definitions

### HTMLContentTemplate (Primary Content System)

- **Purpose:** Modern scrollable HTML content display using WoW's SimpleHTML widget
- **Mixin:** `HTMLContentMixin`
- **File Location:** `UI/Book/HTMLContentTemplate.xml`
- **Data Properties:**
  - `htmlContent` (string): Complete HTML document generated by HTMLBuilder
  - `title` (string): Content title for reference
  - `entity` (table): Optional original entity reference for debugging
- **Usage:** Primary template for all book content in the modern system
- **Features:**
  - Complete HTML document rendering
  - Automatic height adjustment
  - Scroll support for long content
  - Error handling and fallback display
  - WoW color code support within HTML

### VerticalListItemTemplate (List Components)

- **Purpose:** Generic list item for vertical lists (characters, factions, events)
- **Mixin:** `VerticalListItemMixin`
- **File Location:** `UI/VerticalListTemplate.xml`
- **Data Properties:**
  - `character`, `faction`, or `item` (table): Item data
  - `stateManagerKey` (string): State management integration key
- **Usage:** Items in character lists, faction lists, and other vertical collections
- **Features:**
  - Consistent bookmark-style visual treatment
  - Integrated state management
  - Tooltip support
  - Click handling with sound effects

### EventListTitleTemplate / EventListItemTemplate (Event Lists)

- **Purpose:** Specialized templates for event list section titles and items
- **Mixins:** `EventListTitleMixin` / `EventListItemMixin`
- **File Location:** `UI/Events/EventListTemplate.xml`
- **Usage:** Event list display in timeline and search views
- **Features:**
  - Event-specific styling and layout
  - Timeline integration
  - Period-based organization

## Development Guidelines

### For New Content

```lua
-- Use the modern HTML transformation
local bookContent = ContentUtils.TransformEntityToBook(entity, options)
bookFrame:OnContentReceived(bookContent)
```

### HTML Content Creation

```lua
-- Generate complete HTML documents
local htmlContent = HTMLBuilder.CreateEntityHTML(entity, options)
local bookContent = {
    {
        elements = {
            {
                templateKey = private.constants.bookTemplateKeys.HTML_CONTENT,
                htmlContent = htmlContent,
                title = entity.name,
                entity = entity
            }
        }
    }
}
```

### Template Registration

Add new templates to `UI/PageTemplatesRegistration.lua`:

```lua
private.constants.templates = {
    [constants.templateKeys.YOUR_NEW_TEMPLATE] = {
        template = "YourTemplateXMLName", 
        initFunc = YourTemplateMixin.Init
    }
}
```

## Best Practices

1. **Use HTML System**: Use `HTML_CONTENT` for all book content
2. **Consistent Registration**: Register templates in `PageTemplatesRegistration.lua`
3. **State Management**: Use proper `stateManagerKey` values for list components
4. **Error Handling**: Implement proper fallbacks in template mixins
5. **Performance**: Cache transformed content when possible

---

**Note:** This documentation reflects the modern system in Chronicles v2.0.1+ which uses HTML-based content for all book display.
