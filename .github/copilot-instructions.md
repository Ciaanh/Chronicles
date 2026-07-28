# Chronicles WoW Addon – Lean Copilot Guide (v2.0.1)

Scope: World of Warcraft addon written in Lua/XML. Use StateManager + EventManager, template-based UI, and localization-first content. Keep guidance rule-first and enforceable.

## 0) Golden Rules
1) Never create globals; use the `private`/`Chronicles` namespaces only.
2) Persist and read UI/data state only through `private.Core.StateManager`.
3) Communicate across modules only via `private.Core.triggerEvent` with validated payloads.
4) Localize all user-visible text via `Chronicles.L["KEY"]`. No raw strings.
5) Respect mixin + XML template patterns. Manage frame lifecycle (`OnLoad/OnShow/OnHide`) cleanly.
6) Check for nil before calling WoW API. Fail early with descriptive errors.
7) Prefer maintainability over premature optimization. Optimize only with evidence.
8) Do not invent new folder structures, naming schemes, or cross-layer calls.

## 1) Repository Layout (authoritative)
- Core/Infrastructure: StateManager.lua, EventManager.lua, Cache.lua
- Core/Domain: pure business models/logic (no UI, no WoW API)
- Core/Data: TimelineBusiness.lua, SearchEngine.lua, DataRegistry.lua
- Core/Business: cross-layer coordination (e.g., FilterEngine.lua)
- UI/Templates, UI/Book (ContentUtils.lua lives here), UI/* per feature
- DB/01_Sample: data sources
- Locales: enUS.lua (and others)
- .github: this file

Do not add ContentUtils under Core/Utils (removed in v2.0.1).

## 2) Naming Conventions
- Namespaces/components: PascalCase (Chronicles, StateManager)
- Functions/vars: camelCase (getCurrentStepValue, eventData)
- Constants: UPPER_SNAKE_CASE (CURRENT_YEAR)
- State keys: dot.notation (see 3)
- Events: UPPER_SNAKE_CASE in `private.constants.events` (see 4)
- Localization keys: UPPER_SNAKE_CASE with descriptive names

## 3) State Management (authoritative contract)
Use only `private.Core.StateManager`.

Allowed key spaces (examples):
- ui.selectedEvent
- ui.activeTab
- timeline.currentStep
- eventTypes.{id}
- collections.{name}
- data.userContent.events

Rules:
- Build keys via helpers when available:
  - `buildSelectionKey("event")`
  - `buildTimelineKey("currentStep")`
  - `buildSettingsKey(type, id)`
  - `buildUIStateKey("activeTab")`
- Store plain data only (no frames/functions).
- Provide a context string on set for auditability.
- Subscribe with a module name and clean up within lifecycle.

Examples:
```lua
private.Core.StateManager.setState("ui.selectedEvent", eventId, "Event selected from timeline")
local selected = private.Core.StateManager.getState("ui.selectedEvent")

private.Core.StateManager.subscribe("ui.selectedEvent", function(newV, oldV)
    self:UpdateEventDisplay(newV)
end, "EventDisplayMixin")
```

## 4) Event System (schema-first)
Declare events in `private.constants.events` (UPPER_SNAKE_CASE). Always validate payloads.

Rules:
- Payloads must be tables with documented fields.
- Include a context/source string on trigger.
- No hidden coupling; listeners must not mutate payload in-place.

Examples:
```lua
-- Declaration (centralized constants)
private.constants.events = private.constants.events or {}
private.constants.events.TabUITabSet = "TAB_UI_TAB_SET"

-- Trigger
private.Core.triggerEvent(
    private.constants.events.TabUITabSet,
    { frame = self, tabID = tabID },
    "TabUIMixin:SetTab"
)

-- Register
private.Core.registerCallback(
    private.constants.events.TabUITabSet,
    self.OnTabChanged,
    self
)
```

Required payload schema examples:
- TAB_UI_TAB_SET: { frame: Frame, tabID: number }
- TIMELINE_INIT: { stepValue: number, source: "user"|"system"|"plugin" }

## 5) UI Patterns (XML + Mixin)
Rules:
- Create frames via XML templates; implement behavior in mixins.
- Implement `OnLoad`, `OnShow`, `OnHide` and persist UI state in these.
- Lazy-load heavy content on first show.
- Wire UI to state via subscriptions; unsubscribe or guard in `OnHide`.

Example (condensed):
```lua
function MainFrameUIMixin:OnShow()
    self.TabUI:UpdateTabs()
    local k = private.Core.StateManager.buildUIStateKey("activeTab")
    local saved = private.Core.StateManager.getState(k)
    if saved then self.TabUI:SetTab(saved) end
    private.Core.StateManager.setState(
        private.Core.StateManager.buildUIStateKey("isMainFrameOpen"),
        true,
        "Main frame opened"
    )
end
```

## 6) ContentUtils (single source of truth)
Location: UI/Book/ContentUtils.lua
Namespace: `private.Core.Utils.ContentUtils`

Contract (do not rename):
- ConvertTextToHTML(content, portraitPath)
- InjectPortraitIntoHTML(htmlContent, portraitPath)
- TransformEntityToBook(entity)
- IsChapterHeader(line)
- CreateChapterHTML(chapter)
- CalculateContentLayout(content, maxWidth, maxHeight, portraitPath)

Usage:
```lua
local CU = private.Core.Utils.ContentUtils
local html = CU.ConvertTextToHTML(entity.description, portraitPath)
```

## 7) Localization (no raw strings)
Rules:
- All user-facing text via `Chronicles.L["KEY"]`.
- Add new keys to `Locales/enUS.lua` with translator comments.
- Prefer descriptive keys: `EVENT_COVER_TITLE_WAR_OF_THE_ANCIENTS`.

Example:
```lua
frame:SetText(Chronicles.L["EVENTS_TAB_TITLE"])
```

## 8) Error Handling
Rules:
- Guard WoW API calls with nil checks.
- Use descriptive error messages; include context keys/ids.
- Prefer returning early over nested conditionals.
- No silent failures in core paths.

Example:
```lua
if not eventData or not eventData.chapters then
    error("DisplayEventContent: missing eventData.chapters")
end
```

## 9) Performance
- Avoid allocations in hot paths and OnUpdate.
- Debounce expensive UI work (>= 0.1s) via C_Timer.After.
- Batch related state updates.
- Add caching only with measured impact.

Helpers:
```lua
local function debounce(fn, delay)
    local timer
    return function(...)
        local args = {...}
        if timer then timer:Cancel() end
        timer = C_Timer.NewTimer(delay or 0.1, function() fn(unpack(args)) end)
    end
end
```

## 10) Contributor Checklist (enforced)
Before opening a PR:
- [ ] No globals; passes Luacheck (add `.luacheckrc` if missing).
- [ ] All user-facing text localized.
- [ ] New events/state keys follow schemas above.
- [ ] UI changes respect XML+Mixin and lifecycle rules.
- [ ] Added/updated docstrings and inline comments where non-obvious.
- [ ] Version/toc updated if interface compatibility changed.

## 11) Versioning & Maintenance
- Update interface version in `Chronicles.toc` for new WoW patches.
- Keep ContentUtils under UI/Book (not Core/Utils).
- Test with and without optional RP integrations; degrade gracefully.

## 12) Pair Programming Workflow
1) Explore related files; summarize structure and patterns.
2) Propose a small action plan with explicit acceptance criteria.
3) Ask clarifying questions only when blocking.
4) Implement incrementally; wire state/events; add minimal tests/checks.

Appendix A: Canonical State Keys
- ui.selectedEvent: number | { id: number, type: "event" }
- ui.activeTab: number
- timeline.currentStep: number

Appendix B: Canonical Events
- TAB_UI_TAB_SET: { frame: Frame, tabID: number }
- TIMELINE_INIT: { stepValue: number, source: string }
