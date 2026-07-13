# Open Investigation Tracks

This file tracks active analysis and investigation threads.

## Active

### UI: Event List & Book Title Overflow
- **Status**: Implemented (commit 28d170e + color-bug fix 2026-07-08). All 3 phases of the fix plan are in code: BookUtils empty-author guard, book-page title/cover wrapping + two-point anchoring, list-item wordWrap + two-point anchoring. The EventListTitleTemplate BlackBG color bug (0/125/0 → 0/0/0) is also fixed.
- **Location**: `UI/Events/List/`, `UI/Templates/BookPages.xml`
- **See**: `docs/analysis/ui-text-overflow.md`

### DB Registration System Redesign
- **Status**: Implemented — manifest pattern active, legacy compat removed
- **Location**: `DB/DB.lua`, `Core/Data.lua`, `Core/Data/DataRegistry.lua`
- **See**: `docs/analysis/db-registration-system.md`

### Global Code Quality Audit
- **Status**: Survey complete, deep audit planned
- **See**: `docs/analysis/code-improvement-guide.md`
