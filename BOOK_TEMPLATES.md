# Chronicles Addon - Book Templates Documentation

## Overview

The Chronicles addon uses a book-style templating system to display World of Warcraft lore content. As of v2.0.1, the system has transitioned to a unified HTML container approach for book content, deprecating the old multi-template system. Entity data (events, characters, factions) is transformed into a structured format for rendering in the UI.

## Template Keys and Mappings

**Active Templates (v2.0.1+):**
| Template Key         | XML Template           | Lua Mixin           | Purpose                                      |
|---------------------|-----------------------|---------------------|----------------------------------------------|
| `HTML_CONTENT`      | HTMLContentTemplate   | HTMLContentMixin    | Rich descriptions, formatted text (Single HTML Container) |
| `GENERIC_LIST_ITEM` | VerticalListItemTemplate | VerticalListItemMixin | Generic list item for vertical lists         |
| `EVENTLIST_TITLE`   | EventListTitleTemplate | EventListTitleMixin | Event list section titles                    |
| `EVENT_DESCRIPTION` | EventListItemTemplate  | EventListItemMixin  | Event list item content                      |

> **Note:** Only `HTML_CONTENT` is used for book display in the new system. Other keys are used for lists and UI components, not for book content.

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

### Transformed Data Structure (v2.0.1+)

The transformation now produces a single-section array with one element using `HTML_CONTENT`:
```lua
{
    [1] = {
        elements = {
            {
                templateKey = "HTML_CONTENT",
                htmlContent = "<html>...formatted content...</html>",
                title = "Entity Name", -- optional
                entity = {...}         -- optional original entity reference
            }
        }
    }
}
```

## Transformation Flow

1. **Entity Data** (event, character, faction)
2. **ContentUtils.TransformEntityToBook** (or type-specific variant)
3. **Output:** Array of sections, each with an `elements` array
    - For new system: one section, one element, `templateKey = "HTML_CONTENT"`
4. **UI Rendering:**
    - BookContainerTemplate expects pre-transformed content (with `HTML_CONTENT`)
    - Lists and other UI components use their respective template keys

## Template Definitions

### HTMLContentTemplate (Active)
- **Purpose:** Modern scrollable HTML content display (Single HTML Container)
- **Mixin:** `HTMLContentMixin`
- **Data Properties:** 
  - `htmlContent` (string): Pre-formatted HTML content
  - `title` (string): Content title
  - `entity` (table): Optional original entity reference
- **Usage:** Primary content display in book UI

### VerticalListItemTemplate (Active)
- **Purpose:** Generic list item for vertical lists
- **Mixin:** `VerticalListItemMixin`
- **Data Properties:** 
  - `character` or `faction` or `item` (table): Item data
  - `stateManagerKey` (string): State management key
- **Usage:** Items in character lists, faction lists, etc.

### EventListTitleTemplate / EventListItemTemplate (Active)
- **Purpose:** Event list section titles and items
- **Mixin:** `EventListTitleMixin` / `EventListItemMixin`
- **Usage:** Event list display in timeline and search views

---

**Legacy templates and multi-template book display are no longer supported or referenced in the codebase. All book content is rendered using the unified HTML container system.**
