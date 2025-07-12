# Chronicles Addon - Book Templates Documentation

## Overview

The Chronicles addon uses a sophisticated book-style templating system to display World of Warcraft lore content. This system transforms entity data (events, characters, factions) into a structured format that can be rendered using various UI templates.

## Current Version & Status

- **Version**: v2.0.1 (July 13, 2025)
- **Status**: Active development with ongoing template system enhancements
- **Key Components**: ContentUtils located in `UI/Book/ContentUtils.lua`

## Template Architecture

### Core Components

The book template system consists of three main layers:

1. **Data Layer**: Raw entity data with chapters and descriptions
2. **Transformation Layer**: Converts entity data to unified content structure
3. **Presentation Layer**: UI templates that render the transformed data

### Template Keys and Mappings

The system uses template keys to map data elements to specific UI templates:

| Template Key | XML Template | Lua Mixin | Purpose |
|--------------|-------------|-----------|---------|
| `CHAPTER_HEADER` | `ChapterHeaderTemplate` | `ChapterHeaderMixin` | Chapter titles, section headers, entity names |
| `HTML_CONTENT` | `HtmlPageTemplate` | `HtmlPageMixin` | Rich descriptions, formatted text |
| `TEXT_CONTENT` | `ChapterLineTemplate` | `ChapterLineMixin` | Simple text lines, individual paragraphs |
| `EVENT_TITLE` | `EventTitleTemplate` | `EventTitleMixin` | Event titles with date ranges |
| `SIMPLE_TITLE` | `SimpleTitleTemplate` | `SimpleTitleMixin` | Simple titles for characters and factions |
| `COVER_PAGE` | `CoverPageTemplate` | `CoverPageMixin` | Cover pages with portraits |
| `EMPTY` | `EmptyTemplate` | `EmptyMixin` | Empty placeholder content |
| `UNIFIED_CONTENT` | `UnifiedContentTemplate` | `UnifiedContentMixin` | Modern scrollable HTML content |
| `COVER_WITH_CONTENT` | `CoverWithContentTemplate` | `CoverWithContentMixin` | Enhanced cover with integrated content |
| `PAGE_BREAK` | `PageBreakTemplate` | `PageBreakMixin` | Visual dividers between sections |
| `GENERIC_LIST_ITEM` | `VerticalListItemTemplate` | `VerticalListItemMixin` | Generic list item for vertical lists |

## Data Structures

### Input Entity Structure

```lua
-- Raw entity data (events, characters, factions)
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

### Transformed Data Structure

The `CreateUnifiedContent` function transforms input entities into this structure:

```lua
-- Output structure for PagedCondensedVerticalGridContentFrameTemplate
{
    [1] = {  -- Title section
        elements = {
            {
                templateKey = "CHAPTER_HEADER",
                text = "Entity Name"
            }
        }
    },
    [2] = {  -- Description section (if exists)
        elements = {
            {
                templateKey = "HTML_CONTENT", 
                content = "Entity description..."
            }
        }
    },
    [3] = {  -- First chapter
        header = {  -- Chapter header (if exists)
            templateKey = "CHAPTER_HEADER",
            text = "Chapter Title"
        },
        elements = {
            {
                templateKey = "TEXT_CONTENT",
                text = "First line of chapter content"
            },
            {
                templateKey = "TEXT_CONTENT", 
                text = "Second line of chapter content"
            },
            -- Additional content elements...
        }
    },
    -- Additional chapters...
}
```

## Template Definitions

### Core Content Templates

#### ChapterHeaderTemplate
- **Purpose**: Display chapter titles with visual separation
- **Mixin**: `ChapterHeaderMixin`
- **Data Properties**: 
  - `text` (string): The chapter title text
- **Rendering**: Large centered text with separator line
- **Usage**: Section headers, entity names, chapter beginnings

#### HtmlPageTemplate
- **Purpose**: Display rich formatted HTML content
- **Mixin**: `HtmlPageMixin`
- **Data Properties**: 
  - `content` (string): HTML formatted content
- **Rendering**: Scrollable HTML content with proper formatting
- **Usage**: Entity descriptions, formatted text, rich content

#### ChapterLineTemplate
- **Purpose**: Display single lines of plain text
- **Mixin**: `ChapterLineMixin`
- **Data Properties**: 
  - `text` (string): Plain text line
- **Rendering**: Single line of formatted text
- **Usage**: Individual paragraphs, simple text content

### Modern Content Templates

#### UnifiedContentTemplate
- **Purpose**: Modern scrollable HTML content display
- **Mixin**: `UnifiedContentMixin`
- **Data Properties**: 
  - `htmlContent` (string): Pre-formatted HTML content
  - `text` (string): Plain text (converted to HTML)
  - `portraitPath` (string): Optional portrait image path
- **Features**: Automatic HTML conversion, portrait integration
- **Usage**: Primary content display in newer UI components

#### CoverWithContentTemplate
- **Purpose**: Enhanced cover page with integrated content
- **Mixin**: `CoverWithContentMixin`
- **Data Properties**: 
  - `entity` (table): Complete entity object
  - `portraitPath` (string): Portrait image path
- **Features**: Name/label display, author attribution, scrollable content
- **Usage**: Main entity display pages

#### PageBreakTemplate
- **Purpose**: Visual divider between content sections
- **Mixin**: `PageBreakMixin`
- **Data Properties**: None (purely visual)
- **Usage**: Pagination between content sections

### Additional Template Definitions

#### EventTitleTemplate
- **Purpose**: Display event titles with date ranges and author attribution
- **Mixin**: `EventTitleMixin`
- **Data Properties**: 
  - `text` (string): Event title text
  - `yearStart` (number): Event start year
  - `yearEnd` (number): Event end year
  - `author` (string): Author attribution
- **Rendering**: Large title with dates and separator
- **Usage**: Event book headers with temporal information

#### SimpleTitleTemplate
- **Purpose**: Display simple titles for characters and factions
- **Mixin**: `SimpleTitleMixin`
- **Data Properties**: 
  - `text` (string): Title text
  - `author` (string): Author attribution (optional)
- **Rendering**: Large title with optional author
- **Usage**: Character and faction book headers

#### CoverPageTemplate
- **Purpose**: Display cover pages with portraits and descriptions
- **Mixin**: `CoverPageMixin`
- **Data Properties**: 
  - `name` (string): Entity name
  - `image` (string): Portrait image path
  - `text` (string): Description text
  - `author` (string): Author attribution (optional)
- **Rendering**: Portrait with name and scrollable description
- **Usage**: Main entity introduction pages

#### EmptyTemplate
- **Purpose**: Placeholder for empty content states
- **Mixin**: `EmptyMixin`
- **Data Properties**: None
- **Rendering**: Empty placeholder
- **Usage**: Fallback when no content is available

#### VerticalListItemTemplate
- **Purpose**: Generic list item for vertical list displays
- **Mixin**: `VerticalListItemMixin`
- **Data Properties**: 
  - `character` or `faction` or `item` (table): Item data
  - `stateManagerKey` (string): State management key
- **Rendering**: Bookmark-style list item with selection state
- **Usage**: Items in character lists, faction lists, etc.

### Container Templates

#### BookContainerTemplate
- **Purpose**: Main book container with page-flipping animation
- **Mixin**: `BookContainerMixin`
- **Features**: Page navigation, background textures, animation
- **Usage**: Primary book display container for all content types

#### VerticalListTemplate
- **Purpose**: Configurable vertical list component
- **Mixin**: `VerticalListMixin`
- **Features**: Search functionality, item count, state management integration
- **Configuration**: Via KeyValues for different item types
- **Usage**: Character lists, faction lists, and other vertical item displays

## Content Processing

### Content Utilities

The `ContentUtils` namespace provides utility functions for content processing:

#### HTML Conversion
```lua
-- Convert plain text to formatted HTML
ContentUtils.ConvertTextToHTML(content, portraitPath)

-- Inject portrait into existing HTML
ContentUtils.InjectPortraitIntoHTML(htmlContent, portraitPath)

-- Create complete chapter HTML
ContentUtils.CreateChapterHTML(chapter)
```

#### Content Layout
```lua
-- Calculate optimal content dimensions
ContentUtils.CalculateContentLayout(content, maxWidth, maxHeight, portraitPath)

-- Split HTML content into pages
ContentUtils.SplitHTMLContent(content, maxWidth, maxHeight, portraitPath)
```

#### Structure Creation
```lua
-- Transform entity to unified content structure
ContentUtils.CreateUnifiedContent(entity)

-- Create chapter in old format for compatibility
ContentUtils.CreateChapterInOldFormat(chapter)
```

### Localization Support

The system supports localization through the following mechanism:

- Chapter headers and page content can be localization keys
- If content matches a key in `private.Locale`, it gets replaced with localized text
- Falls back to original content if localization key not found

```lua
-- Localization lookup example
local localizedText = private.Locale[contentKey] or contentKey
```

## Template Compatibility

### Backward Compatibility

The system maintains backward compatibility with the old BookUtils system:

- Each section has an `elements` array containing individual UI elements
- Template keys map directly to XML template definitions and Lua mixins
- Nested structure allows iteration through sections and elements
- Property names match mixin expectations (`text` vs `content`)

### Migration Notes

When migrating from old templates:

1. Old templates (`ChapterHeaderTemplate`, `ChapterLineTemplate`, `HtmlPageTemplate`) are restored
2. Data structure maintains the same nested format
3. Template registration system remains unchanged
4. Content transformation preserves existing functionality

## Usage Examples

### Basic Entity Display

```lua
-- Input entity
local character = {
    name = "Tyrande Whisperwind",
    description = "High Priestess of Elune...",
    image = "Interface/AddOns/Chronicles/Art/Portrait/Tyrande.tga",
    chapters = {
        {
            header = "Early Life",
            pages = {
                "Born in the ancient city of Suramar...",
                "Trained as a priestess of Elune..."
            }
        }
    }
}

-- Transform for display
local bookContent = ContentUtils.CreateUnifiedContent(character)
```

### Custom Template Integration

```lua
-- Register custom template
Templates.RegisterTemplate("CUSTOM_CONTENT", function(frame, data)
    -- Custom rendering logic
    frame:SetText(data.customProperty)
end)

-- Use in content structure
local customElement = {
    templateKey = "CUSTOM_CONTENT",
    customProperty = "Custom content value"
}
```

## File Locations

### Core Files
- **ContentDisplayTemplate.lua**: Main content utilities and modern mixins
- **ContentDisplayTemplate.xml**: Modern template definitions
- **BookPages.xml**: Traditional book page templates
- **BookPages.lua**: Traditional template mixins

### Supporting Files
- **Templates.lua**: Template registration system
- **BookUtils.lua**: Legacy book transformation utilities
- **StringUtils.lua**: Text processing utilities

## Best Practices

### Template Usage

1. **Use appropriate template keys**: Choose the right template type for your content
2. **Maintain data structure**: Follow the expected nested format
3. **Handle localization**: Support both direct text and localization keys
4. **Consider performance**: Use HTML templates for complex formatting, text templates for simple content

### Content Creation

1. **Structure chapters logically**: Organize content into meaningful sections
2. **Use descriptive headers**: Provide clear chapter titles
3. **Balance content length**: Avoid overly long single pages
4. **Include portraits**: Enhance visual appeal with appropriate images

### Development Guidelines

1. **Test compatibility**: Ensure new templates work with existing data
2. **Document changes**: Update this documentation for new template types
3. **Follow naming conventions**: Use consistent template key naming
4. **Validate data structures**: Check input data before transformation

## Troubleshooting

### Common Issues

1. **Missing template keys**: Ensure template keys are registered in the template system
2. **Incorrect data properties**: Verify property names match mixin expectations
3. **Localization failures**: Check localization key availability
4. **Layout problems**: Validate content dimensions and scrolling

### Debug Tips

1. **Log data structures**: Print transformed data to verify correctness
2. **Check template registration**: Ensure all templates are properly registered
3. **Validate mixin initialization**: Verify mixins receive expected data
4. **Test edge cases**: Handle empty content, missing images, etc.

---

*This documentation covers the book template system as of Chronicles addon version X.X. For the latest updates, refer to the code comments in ContentDisplayTemplate.lua.*
