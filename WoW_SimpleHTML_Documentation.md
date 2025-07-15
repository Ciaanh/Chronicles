# World of Warcraft SimpleHTML Documentation

## Overview

World of Warcraft's `SimpleHTML` widget is a **very limited** HTML renderer designed for displaying basic formatted text in addon interfaces. It supports only a small subset of HTML elements and has significant restrictions compared to web browsers.

SimpleHTML is commonly used for displaying formatted text, documentation, error messages with links, and anywhere that requires rich text presentation in the game's UI system.

## XML Frame Definition

### Basic SimpleHTML Frame
```xml
<SimpleHTML parentKey="HTML" resizeToFitContents="true" justifyH="LEFT">
    <Size x="500"/>
    <Anchors>
        <Anchor point="TOPLEFT"/>
    </Anchors>
    <FontString inherits="GameFontNormal">
        <Color color="NORMAL_FONT_COLOR"/>
    </FontString>
</SimpleHTML>
```

### Advanced Configuration with Hyperlinks
```xml
<SimpleHTML parentKey="Text" inherits="InlineHyperlinkFrameTemplate" resizeToFitContents="true">
    <Anchors>
        <Anchor point="TOPLEFT"/>
        <Anchor point="TOPRIGHT"/>
    </Anchors>
    <Scripts>
        <OnHyperlinkClick>
            SetItemRef(link, text, button, self);
        </OnHyperlinkClick>
    </Scripts>
    <FontString inherits="GameFontNormal" justifyV="TOP" spacing="2">
        <Color r="1" g="1" b="1"/>
    </FontString>
    <FontStringHeader1 inherits="GameFontNormalLarge" spacing="4"/>
    <FontStringHeader2 inherits="GameFontHighlight" spacing="4"/>
</SimpleHTML>
```

### Common Attributes
- `parentKey="HTML"` - Associates the element with parent frame
- `inherits="InlineHyperlinkFrameTemplate"` - Enables hyperlink support
- `resizeToFitContents="true"` - Automatically adjusts height based on content
- `justifyH="LEFT|CENTER|RIGHT"` - Horizontal text alignment
- `spacing="2"` - Line spacing value

## Supported HTML Elements

### Required Document Structure
SimpleHTML requires proper HTML document structure:
```html
<html>
<body>
  <p>Content goes here</p>
</body>
</html>
```

### WoW HTML Constants
```lua
-- Predefined constants for HTML structure
HTML_START = "<html><body><p>";
HTML_START_CENTERED = "<html><body><p align=\"center\">";
HTML_END = "</p></body></html>";

-- Usage
local content = HTML_START .. "Your content here" .. HTML_END;
```

### Headings
```html
<h1>Main Title</h1>
<h2>Subtitle</h2>
<h3>Section Header</h3>
```
- **Note**: `<h4>`, `<h5>`, `<h6>` are treated as `<h3>`
- Headings automatically use FontStringHeader1 and FontStringHeader2 styling

### Paragraphs
```html
<p>Basic paragraph</p>
<p align="left">Left-aligned text</p>
<p align="center">Centered text</p>
<p align="right">Right-aligned text</p>
```
- **Supported align values**: `left`, `center`, `right`

### Line Breaks
```html
<br/>
<!-- or -->
<br>
```

### Images
```html
<img src="Interface\AddOns\MyAddon\Images\image.tga" width="64" height="64" align="left"/>
<img src="Interface\Icons\Ability_Warrior_Charge" width="32" height="32" align="right"/>
```

**Important Image Guidelines**:
- Use **power-of-2 dimensions** (16, 32, 64, 128, 256, etc.) for best compatibility
- Paths are relative to WoW installation directory
- Common texture locations:
  - `Interface\AddOns\YourAddon\` - Your addon's textures
  - `Interface\Icons\` - Game icons
  - `Interface\Pictures\` - Game artwork
- **Supported align values**: `left`, `center`, `right`

### Hyperlinks
```html
<a href="event:123">View Event Details</a>
<a href="character:Thrall">Learn about Thrall</a>
<a href="item:12345">Item Link</a>
<a href="spell:67890">Spell Link</a>
<a href="url:https://wow.gamepedia.com">External Link</a>
```

## HTML Entities

### Basic Entities (Always Supported)
```html
&amp;   <!-- & -->
&lt;    <!-- < -->
&gt;    <!-- > -->
&quot;  <!-- " -->
```

### Extended Entities (LibMarkdown Required)
```html
&nbsp;   <!-- Non-breaking space -->
&emsp;   <!-- Font-size space -->
&ensp;   <!-- Half font-size space -->
&em13;   <!-- 1/3 font-size space -->
&em14;   <!-- 1/4 font-size space -->
&thinsp; <!-- 1/5 font-size space -->
```

## WoW Color Codes

WoW's color system works **within any text content**:

```html
<h1>|cFFFF0000Red Title|r</h1>
<p>|cFF00FF00Green text|r with |cFF0000FFblue text|r</p>
```

**Color Format**: `|cFFRRGGBB` where:
- `|c` - Start color code
- `FF` - Alpha channel (always FF for opaque)
- `RRGGBB` - Hex color values
- `|r` - Reset to default color

**Common Colors**:
```lua
local COLORS = {
    white = "|cFFFFFFFF",
    red = "|cFFFF0000",
    green = "|cFF00FF00",
    blue = "|cFF0000FF",
    yellow = "|cFFFFFF00",
    orange = "|cFFFF8000",
    purple = "|cFF8000FF",
    gold = "|cFFFFD700",
    gray = "|cFF808080",
    reset = "|r"
}
```

## Hyperlink Implementation

### XML Configuration
Enable hyperlinks in your SimpleHTML frame:
```xml
<SimpleHTML parentKey="HTML" inherits="InlineHyperlinkFrameTemplate">
    <Scripts>
        <OnHyperlinkClick>
            SetItemRef(link, text, button, self);
        </OnHyperlinkClick>
        <OnHyperlinkEnter function="GameTooltip_OnHyperlinkEnter"/>
        <OnHyperlinkLeave function="GameTooltip_OnHyperlinkLeave"/>
    </Scripts>
</SimpleHTML>
```

### Lua Event Handlers
```lua
-- Basic hyperlink handler
frame:SetHyperlinksEnabled(true)
frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local linkType, linkData = link:match("([^:]+):(.+)")
    
    if linkType == "event" then
        local eventId = tonumber(linkData)
        ShowEventDetails(eventId)
    elseif linkType == "character" then
        ShowCharacterInfo(linkData)
    elseif linkType == "item" then
        local itemId = tonumber(linkData)
        ShowItemTooltip(itemId)
    elseif linkType == "spell" then
        local spellId = tonumber(linkData)
        ShowSpellDetails(spellId)
    elseif linkType == "url" then
        -- Copy URL to clipboard (can't open external browsers)
        local url = table.concat({linkData}, ":", 2)
        CopyToClipboard(url)
        print("URL copied to clipboard: " .. url)
    end
end)
```

### Advanced Hyperlink Patterns
```lua
-- Multiple link types with validation
frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local parts = {strsplit(":", link)}
    local linkType = parts[1]
    
    if linkType == "urlIndex" then
        -- Load indexed URLs (used in Store UI)
        local index = tonumber(parts[2])
        if index then LoadURLIndex(index) end
    elseif linkType == "launch" then
        -- Launch external URLs
        LaunchURL(table.concat(parts, ":", 2))
    else
        -- Handle standard item/spell/achievement links
        SetItemRef(link, text, button, self)
    end
end)
```

## NOT SUPPORTED

### CSS and Styling
```html
<!-- ❌ DOES NOT WORK -->
<style>p { color: red; }</style>
<p style="color: red;">Styled text</p>
<div class="container">Content</div>
```

### Complex HTML Elements
```html
<!-- ❌ DOES NOT WORK -->
<div>Container</div>
<span>Inline text</span>
<ul><li>List item</li></ul>
<ol><li>Numbered item</li></ol>
<table><tr><td>Table cell</td></tr></table>
<form><input type="text"/></form>
```

### Advanced Attributes
```html
<!-- ❌ DOES NOT WORK -->
<p id="myid" class="myclass" onclick="doSomething()">Text</p>
<img title="tooltip" alt="alternative text" onload="imageLoaded()"/>
```

## Best Practices

### 1. Use WoW Color Codes Instead of CSS
```html
<!-- ✅ Good -->
<h1>|cFFFFD700Golden Title|r</h1>

<!-- ❌ Bad -->
<h1 style="color: gold;">Golden Title</h1>
```

### 2. Create Lists with Paragraphs
```html
<!-- ✅ Good -->
<p>• First item</p>
<p>• Second item</p>
<p>• Third item</p>

<!-- ❌ Bad -->
<ul>
  <li>First item</li>
  <li>Second item</li>
</ul>
```

### 3. Use Power-of-2 Image Dimensions
```html
<!-- ✅ Good -->
<img src="Interface\AddOns\MyAddon\icon.tga" width="64" height="64"/>

<!-- ⚠️ May cause issues -->
<img src="Interface\AddOns\MyAddon\icon.tga" width="65" height="65"/>
```

### 4. Handle Missing Images Gracefully
```lua
-- Validate texture paths before using
local function ValidateTexture(path)
    local texture = CreateFrame("Frame"):CreateTexture()
    texture:SetTexture(path)
    local isValid = texture:GetTexture() ~= nil
    texture:GetParent():Hide() -- Clean up
    return isValid
end
```

### 5. Escape User Content
```lua
local function EscapeHTML(text)
    if not text then return "" end
    return text:gsub("&", "&amp;")
              :gsub("<", "&lt;")
              :gsub(">", "&gt;")
              :gsub('"', "&quot;")
end
```

## Complete Implementation Examples

### Character Display with Portrait
```lua
local function CreateCharacterHTML(character)
    local html = string.format([[
<html>
<body>
<h1>|cFFFFD700%s|r</h1>
<img src="Interface\AddOns\Chronicles\Images\%s.tga" width="128" height="128" align="right"/>
<p align="center">|cFF888888Level %d %s %s|r</p>
<br/>
<h2>|cFFD4AF37Background|r</h2>
<p>%s</p>
<br/>
<p><a href="character:%s">View Full Details</a></p>
</body>
</html>
    ]], 
        EscapeHTML(character.name),
        character.portrait or "default",
        character.level or 1,
        character.race or "Unknown",
        character.class or "Unknown",
        EscapeHTML(character.background or "No background available."),
        character.id
    )
    return html
end
```

### Event Timeline Entry
```lua
local function CreateEventHTML(event)
    local dateRange = ""
    if event.yearStart and event.yearEnd then
        if event.yearStart == event.yearEnd then
            dateRange = string.format("|cFFFFD700Year %d|r", event.yearStart)
        else
            dateRange = string.format("|cFFFFD700Years %d - %d|r", event.yearStart, event.yearEnd)
        end
    end
    
    local html = string.format([[
<html>
<body>
<h1>|cFFFFD700%s|r</h1>
<p align="center">%s</p>
<br/>
<p>%s</p>
%s
<p><a href="event:%s">View Details</a> | <a href="timeline:%s">See Timeline</a></p>
</body>
</html>
    ]],
        EscapeHTML(event.name),
        dateRange,
        EscapeHTML(event.description or ""),
        event.image and string.format('<img src="%s" width="64" height="64" align="left"/>', event.image) or "",
        event.id,
        event.timelineId or event.id
    )
    return html
end
```

### Frame Setup with Scroll Support
```lua
-- Create SimpleHTML frame within a scroll frame
local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(400, 500)
scrollFrame:SetPoint("CENTER")

local htmlFrame = CreateFrame("SimpleHTML", nil, scrollFrame)
htmlFrame:SetSize(380, 500)
htmlFrame:SetPoint("TOPLEFT")

-- Configure the HTML frame
htmlFrame:SetHyperlinksEnabled(true)
htmlFrame:SetFontObject("GameFontNormal")

-- Set up scroll child
scrollFrame:SetScrollChild(htmlFrame)

-- Set hyperlink handler
htmlFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local linkType, linkData = link:match("([^:]+):(.+)")
    
    if linkType == "character" then
        ShowCharacterDetails(linkData)
    elseif linkType == "event" then
        ShowEventDetails(tonumber(linkData))
    elseif linkType == "timeline" then
        ShowTimeline(tonumber(linkData))
    end
end)

-- Set content and resize
local content = CreateCharacterHTML(characterData)
htmlFrame:SetText(content)

-- Auto-resize frame height based on content
local contentHeight = htmlFrame:GetContentHeight()
if contentHeight then
    htmlFrame:SetHeight(math.max(contentHeight, 500))
end
```

## Common Use Cases in WoW UI

### 1. Guild Message of the Day
```xml
<SimpleHTML parentKey="MOTD">
    <Size x="246" y="46"/>
    <Scripts>
        <OnHyperlinkClick>
            SetItemRef(link, text, button, self);
        </OnHyperlinkClick>
    </Scripts>
    <FontString inherits="GameFontNormalSmall" justifyH="LEFT" justifyV="TOP" spacing="2">
        <Color r="1" g="1" b="1"/>
    </FontString>
</SimpleHTML>
```

### 2. Item Text Display
```xml
<SimpleHTML name="ItemTextPageText">
    <Size x="270" y="304"/>
    <FontString inherits="QuestFont" justifyH="LEFT"/>
</SimpleHTML>
```

### 3. Store UI with URL Links
```xml
<SimpleHTML parentKey="Notice">
    <Size x="260" y="240"/>
    <Scripts>
        <OnHyperlinkClick function="GetURLIndexAndLoadURL" />
    </Scripts>
    <FontString inherits="GameFontBlackMedium" justifyH="LEFT" />
</SimpleHTML>
```

## Troubleshooting

### Common Issues

1. **Images Not Showing**
   - Check file path spelling and case sensitivity
   - Ensure texture files are in TGA format
   - Use power-of-2 dimensions
   - Verify the texture exists in the game files

2. **Hyperlinks Not Working**
   - Ensure `SetHyperlinksEnabled(true)` is called
   - Check that `OnHyperlinkClick` script is set
   - Verify href format matches your handler logic
   - Use `InlineHyperlinkFrameTemplate` for automatic setup

3. **Color Codes Not Working**
   - Ensure proper format: `|cFFRRGGBB`
   - Always end with `|r` to reset
   - Check for typos in hex color values

4. **Layout Issues**
   - Remember: no CSS support
   - Use `align` attributes on `<p>` and `<img>`
   - Use `<br/>` for spacing
   - Consider using multiple SimpleHTML frames for complex layouts

5. **Content Not Displaying**
   - Check HTML structure: must have `<html><body><p>` tags
   - Use HTML constants: `HTML_START` and `HTML_END`
   - Ensure frame size is adequate for content

### Testing Your HTML
```lua
-- Quick test function
local function TestHTML(htmlString)
    local testFrame = CreateFrame("SimpleHTML", nil, UIParent)
    testFrame:SetSize(400, 300)
    testFrame:SetPoint("CENTER")
    testFrame:SetText(htmlString)
    testFrame:Show()
    
    -- Auto-hide after 5 seconds
    C_Timer.After(5, function()
        testFrame:Hide()
    end)
end

-- Usage
TestHTML(HTML_START .. "|cFFFF0000Test Title|r<br/>This is a test paragraph with <a href=\"test:123\">a link</a>." .. HTML_END)
```

### Content Validation
```lua
-- Check if content is HTML formatted
local function IsHTMLContent(text)
    return text and strfind(strlower(text), "<html><body><p>") ~= nil
end

-- Auto-wrap non-HTML content
local function EnsureHTMLFormat(text)
    if IsHTMLContent(text) then
        return text
    else
        return HTML_START .. EscapeHTML(text) .. HTML_END
    end
end
```

## Performance Considerations

1. **Content Size**: SimpleHTML performance can degrade with very large amounts of content
2. **Resize Behavior**: Use `resizeToFitContents="true"` carefully as it can impact performance
3. **Scrolling**: For large content, always use within scroll frames
4. **Width Setting**: Set frame width before calling SetText for proper resizing
5. **Image Loading**: Preload textures when possible to avoid UI stuttering

## Integration Tips

- **Localization**: Use localization strings in your HTML content
- **Theming**: Leverage font inheritance for consistent styling
- **Accessibility**: Provide alternative text methods for screen readers
- **Memory**: Cache frequently used HTML content to reduce string operations
- **Updates**: Use events to refresh HTML content when underlying data changes

This documentation provides comprehensive coverage of SimpleHTML usage in World of Warcraft addons, from basic implementation to advanced integration patterns.
