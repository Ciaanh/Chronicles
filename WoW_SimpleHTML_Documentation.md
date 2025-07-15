# World of Warcraft SimpleHTML Documentation

## Overview

World of Warcraft's `SimpleHTML` widget is a **very limited** HTML renderer designed for displaying basic formatted text in addon interfaces. It supports only a small subset of HTML elements and has significant restrictions compared to web browsers.

## Supported HTML Elements

### Document Structure
```html
<html>
<body>
  <!-- Content goes here -->
</body>
</html>
```

### Headings
```html
<h1>Main Title</h1>
<h2>Subtitle</h2>
<h3>Section Header</h3>
```
- **Note**: `<h4>`, `<h5>`, `<h6>` are treated as `<h3>`
- Headings automatically have default styling

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

### Hyperlinks (Advanced)
```html
<a href="event:123">View Event Details</a>
<a href="character:Thrall">Learn about Thrall</a>
<a href="external:https://wow.gamepedia.com">WoW Wiki</a>
```

**Hyperlink Implementation**:
```lua
-- On your SimpleHTML frame
frame:SetHyperlinksEnabled(true)
frame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local linkType, linkData = link:match("([^:]+):(.+)")
    
    if linkType == "event" then
        local eventId = tonumber(linkData)
        -- Show event details
        ShowEventDetails(eventId)
    elseif linkType == "character" then
        -- Show character information
        ShowCharacterInfo(linkData)
    elseif linkType == "external" then
        -- Handle external links (copy to clipboard, etc.)
        HandleExternalLink(linkData)
    end
end)
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

## Complete Example

### HTML Generation
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

### Frame Setup
```lua
-- Create SimpleHTML frame
local htmlFrame = CreateFrame("SimpleHTML", "MyHTMLFrame", UIParent)
htmlFrame:SetSize(400, 500)
htmlFrame:SetPoint("CENTER")

-- Enable hyperlinks
htmlFrame:SetHyperlinksEnabled(true)

-- Set hyperlink handler
htmlFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local linkType, linkData = link:match("([^:]+):(.+)")
    
    if linkType == "character" then
        -- Show character details
        ShowCharacterDetails(linkData)
    elseif linkType == "event" then
        -- Show event details
        ShowEventDetails(tonumber(linkData))
    end
end)

-- Set the HTML content
local character = GetCharacterData("Thrall")
htmlFrame:SetText(CreateCharacterHTML(character))
```

### Advanced Hyperlink Patterns
```lua
-- Multiple link types with validation
htmlFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
    local parts = {strsplit(":", link)}
    local linkType = parts[1]
    
    if linkType == "item" and button == "LeftButton" then
        local itemId = tonumber(parts[2])
        if itemId then
            -- Show item tooltip or details
            ShowItemTooltip(itemId)
        end
    elseif linkType == "spell" then
        local spellId = tonumber(parts[2])
        if spellId then
            ShowSpellDetails(spellId)
        end
    elseif linkType == "achievement" then
        local achievementId = tonumber(parts[2])
        if achievementId then
            ShowAchievementDetails(achievementId)
        end
    elseif linkType == "url" then
        -- Copy URL to clipboard (can't open external browsers)
        local url = table.concat(parts, ":", 2)
        CopyToClipboard(url)
        print("URL copied to clipboard: " .. url)
    end
end)
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

3. **Color Codes Not Working**
   - Ensure proper format: `|cFFRRGGBB`
   - Always end with `|r` to reset
   - Check for typos in hex color values

4. **Layout Issues**
   - Remember: no CSS support
   - Use `align` attributes on `<p>` and `<img>`
   - Use `<br/>` for spacing
   - Consider using multiple paragraphs instead of complex layouts

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
TestHTML([[
<html><body>
<h1>|cFFFF0000Test Title|r</h1>
<p>This is a test paragraph with <a href="test:123">a link</a>.</p>
</body></html>
]])
```

This documentation covers all the essential aspects of working with SimpleHTML in World of Warcraft addons, including the hyperlink system with practical examples.
