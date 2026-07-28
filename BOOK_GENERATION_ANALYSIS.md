# Chronicles Book Generation System Analysis

Note: For coding standards and enforceable rules (state/events/UI/localization), see .github/copilot-instructions.md.

## Overview

The Chronicles addon converts entity data (events, characters, factions) into complete HTML documents displayed in a book-like interface using WoW's SimpleHTML widget.

## System Architecture

```text
Raw Entity Data → HTML Generation → Content Transformation → Book Display → User Interaction
```

## Detailed Flow

-   Stage 1: Structured entity objects with chapters and metadata
-   Stage 2: `HTMLBuilder.CreateEntityHTML(entity)` creates complete HTML documents + navigation data
-   Stage 3: `ContentUtils.TransformEntityToBook(entity)` wraps documents into template elements (`HTML_CONTENT`) and attaches `navigationData`
-   Stage 4: `BookContainerTemplate` displays sections via `PagedDetails` using registered templates
-   Stage 5: `HTMLContentTemplate` renders HTML and handles hyperlink navigation

## Navigation and Links

-   Custom hyperlinks: `chronicles:chapter:<id>`, `chronicles:event:<id>`, `chronicles:character:<id>`, `chronicles:faction:<id>`, `chronicles:chapter:toc`
-   `BookContainerMixin` stores `navigationData` (chapters map, totalPages) and sets current page on navigation

## Error Handling

-   Validate entity presence and content before generation
-   Fallback: an error/empty page wrapped in `HTML_CONTENT` when data is missing

## Performance

-   Lazy generation of HTML
-   Use scroll frames for long content; avoid unnecessary reflows
-   Cache repeated transformations where measurable

## Extensibility

-   Add new content types by extending `HTMLBuilder` blocks and ensuring output is a complete document
-   Register any new UI templates in `PageTemplatesRegistration.lua`

## Targeted Improvements

1. HTML detection and preservation

    - Preserve pre-authored HTML in chapters when provided
    - Only wrap plain text with paragraph/title helpers

2. Page ordering and navigation

    - Ensure chapter documents are appended in sequence and indices map to `navigationData`

3. Large chapter handling

    - Optionally split very tall content into multiple documents when height estimate exceeds threshold

4. Validation and sanitization

    - Provide a light sanitizer for unsupported SimpleHTML tags (`div`, `span`, `style`, `script`, `table`) with safe replacements

5. BookContainer safeguards

    - Validate `navigationData` vs number of elements; warn if mismatched

These improvements keep the pipeline robust without changing public contracts or file layout.

## Object examples

#### Event Entity Example

```lua
local eventEntity = {
    id = "war_of_the_ancients",
    name = "War of the Ancients",
    label = "The War of the Ancients",
    description = "A catastrophic conflict that reshaped Azeroth...",
    author = "Chronicler Veras",
    yearStart = -10000,
    yearEnd = -9995,
    image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande.tga",
    coverImage = "Interface\\AddOns\\Chronicles\\Art\\Images\\NightElfCrest.tga",
    chapters = {
        {
            id = "chapter_1",
            title = "The Burning Legion Arrives",
            content = "The peaceful world of Azeroth was forever changed..."
        },
        {
            id = "chapter_2",
            title = "Heroes Rise",
            content = "In the darkest hour, heroes emerged..."
        }
    },
    factions = {"night_elves", "burning_legion"},
    characters = {"tyrande", "malfurion", "illidan"}
}
```

#### Character Entity Example

```lua
local characterEntity = {
    id = "tyrande_whisperwind",
    name = "Tyrande Whisperwind",
    description = "High Priestess of Elune and leader of the Night Elves...",
    image = "Interface\\AddOns\\Chronicles\\Art\\Portrait\\Tyrande.tga",
    author = "Lore Master Kael",
    chapters = {
        {
            id = "early_life",
            title = "Early Life",
            content = "Born in the ancient city of Suramar..."
        },
        {
            id = "priestess_role",
            title = "Rise to High Priestess",
            content = "Her devotion to Elune was evident from..."
        }
    },
    faction = "night_elves"
}
```

#### Faction Entity Example

```lua
local factionEntity = {
    id = "night_elves",
    name = "Night Elves",
    description = "An ancient race blessed by the moon goddess Elune...",
    image = "Interface\\AddOns\\Chronicles\\Art\\Images\\NightElfCrest.tga",
    author = "Elder Moonwhisper",
    chapters = {
        {
            id = "origins",
            title = "Ancient Origins",
            content = "Ten thousand years ago, the night elves..."
        },
        {
            id = "culture",
            title = "Culture and Society",
            content = "Night elf society revolves around..."
        }
    }
}
```

#### HTMLBuilder Output

```lua
local htmlBuilderResult = {
    documents = {
        -- Cover Page
        [[<html><body>
            <h1 align="center">War of the Ancients</h1>
            <br/><br/>
            <img src="Interface\AddOns\Chronicles\Art\Portrait\Tyrande.tga" width="200" height="200" align="right"/>
            <p>A catastrophic conflict that reshaped Azeroth...</p>
            <p align="right">|cff9d9d9dChronicler Veras|r</p>
            <p align="right">|cff9d9d9d10,000 - 9,995 years before the Dark Portal|r</p>
        </body></html>]],

        -- Table of Contents
        [[<html><body>
            <h1 align="center">Table of Contents</h1>
            <br/><br/>
            <p><a href="chronicles:chapter:chapter_1">Chapter 1: The Burning Legion Arrives</a></p>
            <p><a href="chronicles:chapter:chapter_2">Chapter 2: Heroes Rise</a></p>
        </body></html>]],

        -- Chapter 1
        [[<html><body>
            <h1>Chapter 1: The Burning Legion Arrives</h1>
            <br/><br/>
            <p>The peaceful world of Azeroth was forever changed...</p>
            <br/><br/>
            <p align="center"><a href="chronicles:chapter:toc">← Back to Contents</a></p>
        </body></html>]],

        -- Chapter 2
        [[<html><body>
            <h1>Chapter 2: Heroes Rise</h1>
            <br/><br/>
            <p>In the darkest hour, heroes emerged...</p>
            <br/><br/>
            <p align="center"><a href="chronicles:chapter:toc">← Back to Contents</a></p>
        </body></html>]]
    }
}
```

#### Data to render

```lua

local providerData = {
    {
        -- Section 1 contains all elements
        elements = {
            [1] = { templateKey = "HTML_CONTENT", htmlContent = "<html><body><p>Complete HTML document</p></body></html>", title = "Cover" },
            [2] = { templateKey = "HTML_CONTENT", htmlContent = "<html><body><p>Complete HTML document</p></body></html>", title = "Contents" },
            [3] = { templateKey = "HTML_CONTENT", htmlContent = "<html><body><p>Complete HTML document</p></body></html>", title = "Chapter 1" },
            [4] = { templateKey = "HTML_CONTENT", htmlContent = "<html><body><p>Complete HTML document</p></body></html>", title = "Chapter 2" }
        }
    }
}
```
