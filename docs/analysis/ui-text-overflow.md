# UI Text Overflow & Positioning Analysis

## Summary

Multiple UI components have text overflow issues caused by conflicting layout directives (`setAllPoints="true"` combined with explicit `<Size>` and anchors), missing truncation/wrapping logic, and an empty-author display bug in the book content pipeline.

## Architecture Context

### Page System

The book uses Blizzard's `PagedCondensedVerticalGridContentFrameTemplate` with `viewsPerPage=2` (left/right pages). Each view is a `StaticGridLayoutFrame` inside a `SharedBookTemplate` (1200×650 frame, 500px `viewWidth`). Content is built as arrays of `{templateKey, ...data}` objects by `BookUtils.TransformEntityToBook()`, then rendered via `CreateDataProvider()` → `SetDataProvider()`.

### Block System

There is no explicit "block" abstraction. Each template instance (EmptyTemplate 25px, ChapterHeaderTemplate 50px, ChapterLineTemplate 25px, HtmlPageTemplate 460px, SimpleTitleTemplate 510px, EventTitleTemplate 550px, CoverPageTemplate 550px, CoverDescriptionTemplate 200px) is an element in the paged grid. The Blizzard template handles flowing elements top-to-bottom per view, then to the next view/page.

Text content is pre-split by `StringUtils.SplitTextToFitWidth()` — each resulting line becomes its own 25px `ChapterLineTemplate` block. Title/cover pages occupy full-page height blocks.

### Content Pipeline

```
DB entity (author, chapters, etc.)
  → BookUtils.TransformEntityToBook()
    → prepends Locale["Author"] ("by ") to author field
    → produces [{templateKey, ...data}] array
  → SharedBookMixin.OnContentReceived()
    → CreateDataProvider() → SetDataProvider()
  → Blizzard PagedGrid creates frames from Templates.lua registry
  → Individual Mixin:Init() sets text, shows/hides elements
```

---

## Issues Identified

### 1. Empty Author Displays "by " with No Name

**Files**: `Core/Utils/BookUtils.lua`, `UI/Templates/BookPages.lua`

**Problem**: In `BookUtils.lua`, the author field is computed as:
```lua
author = entity.author and (Locale["Author"] .. entity.author) or nil
```
When `entity.author == ""` (truthy in Lua), this produces `"by "` — the prefix with no name. The UI mixins check `elementData.author ~= ""` but `"by "` passes that check, so **"by " is displayed with no author name**.

**Confirmed**: `author = ""` is used extensively across DB files (WarwithinFactionsDB, DragonflightCharactersDB, FutureFactionsDB, etc. — dozens of entries).

**Fix**: Add empty string check in `BookUtils.lua`:
```lua
author = (entity.author and entity.author ~= "") and (Locale["Author"] .. entity.author) or nil
```

### 2. Event List Item Titles — Conflicting Layout

**Files**: `UI/Events/List/EventListTemplate.xml`, `UI/Templates/VerticalListTemplate.xml`

**Problem**: The `FontString` for item titles in both `EventListItemTemplate` and `VerticalListItemTemplate` declares `setAllPoints="true"` with an explicit `<Size x="100" y="35"/>` and a single LEFT anchor. In WoW's layout, explicit anchors override `setAllPoints` — but the conflict makes the intended sizing unclear and the `<Size>` tag effectively becomes a no-op since the explicit anchor takes priority.

In `EventListItemMixin:Init()`, the text position is repositioned in Lua (`ClearAllPoints` + `SetPoint`), so the XML anchor is overridden at runtime anyway. The `<Size>` tag is never applied.

**Visible symptom**: Text in bookmark items is not width-constrained — long event names can extend beyond the 150px bookmark button.

**Fix**: Remove `setAllPoints="true"` and the conflicting `<Size>`, use two-point anchoring to constrain text within the bookmark content area. The Lua `Init()` can further adjust positioning per side.

### 3. Book Title FontStrings — No Width Constraint

**Files**: `UI/Templates/BookPages.xml` (`EventTitleTemplate`, `SimpleTitleTemplate`)

**Problem**: Both title templates use `SystemFont_Huge4` (very large font) with `setAllPoints="true"` and a single CENTER anchor. The FontString inherits the parent's full 500×550px area but has no explicit width constraint and no word wrap. Long titles overflow beyond the page boundary.

**Affected templates**:
- `EventTitleTemplate.Title` — CENTER anchor, `SystemFont_Huge4`, no width limit
- `SimpleTitleTemplate.Title` — CENTER anchor, `SystemFont_Huge4`, no width limit

**Fix**: Replace `setAllPoints="true"` + CENTER with two-point anchoring (TOPLEFT+TOPRIGHT or LEFT+RIGHT with offsets) to constrain width to parent, and enable word wrap in Lua via `SetWordWrap(true)`.

### 4. Cover Page Name — Conflicting Size

**Files**: `UI/Templates/BookPages.xml` (`CoverPageTemplate`)

**Problem**: `.Name` FontString has `setAllPoints="true"` with `<Size x="400" y="60"/>` and a TOP anchor relative to Portrait. The `setAllPoints` is overridden by the explicit anchor, but the `<Size>` is also ignored because single-point anchoring doesn't apply both dimensions consistently. Long entity names can overflow.

**Fix**: Remove `setAllPoints="true"`, keep the `<Size>` tag or use two-point anchoring, and add word wrap.

### 5. Dates FontString — Missing Size

**Files**: `UI/Templates/BookPages.xml` (`EventTitleTemplate`)

**Problem**: `.Dates` FontString has `setAllPoints="true"` with a single TOP anchor relative to Separator. No explicit size. Since only one anchor is set, the FontString has no defined dimensions beyond its text content — it will expand freely.

**Fix**: Remove `setAllPoints="true"`, add explicit width constraint or two-point horizontal anchoring.

### 6. ChapterHeader/ChapterLine — Minor Inconsistency

**Files**: `UI/Templates/BookPages.xml`

**Problem**: Both use `setAllPoints="true"` but also have two explicit anchors (TOPLEFT + TOPRIGHT), which properly define width. The `setAllPoints` is redundant and overridden by the explicit anchors. Not a bug, but adds confusion.

**Fix**: Remove `setAllPoints="true"` for clarity — the two-point anchoring already constrains width correctly.

---

## Full FontString Audit

### BookPages.xml

| Template | FontString | `setAllPoints` | Explicit `<Size>` | Anchoring | Word Wrap | Status |
|----------|-----------|:-:|---|---|:-:|---|
| ChapterHeaderTemplate | `.Text` | Yes | No | TOPLEFT+TOPRIGHT | No | OK (redundant setAllPoints) |
| ChapterLineTemplate | `.Text` | Yes | No | TOPLEFT+TOPRIGHT | No | OK (redundant setAllPoints) |
| HtmlPageTemplate | `.HTML` | No | x=500 | TOPLEFT | Yes (resize) | OK |
| SimpleTitleTemplate | `.Title` | Yes | No | CENTER only | No | **OVERFLOW** |
| SimpleTitleTemplate | `.Author` | Yes | x=viewWidth, y=25 | BOTTOMRIGHT | No | OK (width-constrained) |
| EventTitleTemplate | `.Title` | Yes | No | CENTER only | No | **OVERFLOW** |
| EventTitleTemplate | `.Dates` | Yes | No | TOP only | No | **No width** |
| EventTitleTemplate | `.Author` | Yes | x=viewWidth, y=25 | BOTTOMRIGHT | No | OK |
| CoverPageTemplate | `.Name` | Yes | x=400, y=60 | TOP only | No | **Conflicted** |
| CoverPageTemplate | `.Description` | No | x=400, y=200 | TOP | justifyV | OK |
| CoverPageTemplate | `.Author` | Yes | x=viewWidth, y=25 | BOTTOMRIGHT | No | OK |
| CoverDescriptionTemplate | `.Description` | No | x=400, y=180 | TOP | justifyV | OK |

### EventListTemplate.xml

| Template | FontString | `setAllPoints` | Explicit `<Size>` | Anchoring | Status |
|----------|-----------|:-:|---|---|---|
| EventListTitleTemplate | `.Text` | Yes | No | CENTER only | Redundant, but title is short |
| EventListItemTemplate | `.Text` | Yes | x=100, y=35 | LEFT only | **Conflicted — no width constraint** |

### VerticalListTemplate.xml

| Template | FontString | `setAllPoints` | Explicit `<Size>` | Anchoring | Status |
|----------|-----------|:-:|---|---|---|
| VerticalListItemTemplate | `.ItemName` | Yes | x=100, y=35 | LEFT only | **Conflicted — no width constraint** |

---

## Fix Plan

### Phase 1 — Data Pipeline (Bug Fix)
1. **BookUtils.lua**: Add empty-string check for author to prevent displaying "by " alone

### Phase 2 — Book Page Templates (Overflow Fixes)
2. **EventTitleTemplate.Title**: Remove `setAllPoints`, add LEFT+RIGHT anchoring with padding, enable word wrap in Lua
3. **SimpleTitleTemplate.Title**: Same as above
4. **EventTitleTemplate.Dates**: Remove `setAllPoints`, add width constraint
5. **CoverPageTemplate.Name**: Remove `setAllPoints`, keep `<Size>` or use two-point anchoring
6. **ChapterHeaderTemplate.Text** / **ChapterLineTemplate.Text**: Remove redundant `setAllPoints`

### Phase 3 — List Item Templates (Cleanup)
7. **EventListItemTemplate.Text**: Remove `setAllPoints` and `<Size>`, let Lua Init handle positioning (it already does ClearAllPoints+SetPoint)
8. **VerticalListItemTemplate.ItemName**: Same as above
