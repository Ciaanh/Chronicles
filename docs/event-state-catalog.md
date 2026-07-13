# Event & state-key catalog

The addon's runtime communication runs on two systems:

- **Events** (`EventManager` / Blizzard `EventRegistry`) — fire-and-forget
  notifications, validated against schemas. Fired with
  `private.Core.triggerEvent(name, payload, source)`, consumed with
  `private.Core.registerCallback(name, handler, owner)`.
- **State** (`StateManager`) — a persisted key/value store with subscriptions.
  Set with `setState(key, value, reason)`, read with `getState(key)`, observed
  with `subscribe(key, cb, subscriberId)`. Values under mapped keys persist to
  `ChroniclesDB` automatically.

Selection and timeline navigation moved from events to **state** (single source
of truth); the remaining events are lifecycle, settings toggles, and timeline
rendering fan-out.

---

## Events

Names are defined in `constants.events` (`Constants.lua`); schemas in
`Core/Infrastructure/EventManager.lua`. `required` fields are enforced generically
by the Validator before the per-schema `validate()` runs.

| Event (constant) | Value | Payload | Fired by | Consumed by |
|---|---|---|---|---|
| `AddonStartup` | `Addon.STARTUP` | `{}` (optional `profile`) | `Chronicles:OnInitialize` (0.2s after load) | `Chronicles:OnAddonStartup`; `VerticalListTemplate` |
| `AddonShutdown` | `Addon.SHUTDOWN` | `nil` | `Chronicles:OnDisable` | (none currently) |
| `TimelineInit` | `Timeline.INIT` | `{}` / `nil` | `OnAddonStartup`, `RegisterPluginDB`, `Data` ADDON_LOADED rescan, `Timeline:Init` | `TimelineTemplate:OnTimelineInit` |
| `UIRefresh` | `Timeline.CLEAN` | `nil` (optional `source`, `data`) | `Settings` (type/collection toggles) | `SharedBookTemplate`, `VerticalListTemplate`, `EventListTemplate` |
| `TabUITabSet` | `TabUI.TabSet` | `{frame, tabID:number}` **(required)** | `MainFrameUI:SetTab` | (tab UI internals) |
| `SettingsEventTypeChecked` | `Settings.EVENT_TYPE_CHECKED` | `{eventTypeId:number, isActive:boolean}` **(required)** | `Settings` checkboxes | `Settings:OnSettingsEventTypeChecked` |
| `SettingsCollectionChecked` | `Settings.COLLECTION_CHECKED` | `{collectionName:string, isActive:boolean}` **(required)** | `Settings` checkboxes | `Settings:OnSettingsCollectionChecked` |
| `TimelinePreviousButtonVisible` | `Timeline.PREVIOUS_VISIBLE` | `{visible:boolean}` **(required)** | `Domain/Timeline` | `TimelineTemplate` |
| `TimelineNextButtonVisible` | `Timeline.NEXT_VISIBLE` | `{visible:boolean}` **(required)** | `Domain/Timeline` | `TimelineTemplate` |
| `DisplayTimelineLabel` | `Timeline.DisplayLabel` | string or `nil`; **dynamic**: index suffix (`…Label1`) | `Domain/Timeline`, `TimelineTemplate` | timeline label frames |
| `DisplayTimelinePeriod` | `Timeline.DisplayPeriod` | table or `nil`; **dynamic**: index suffix (`…Period1`) | `Domain/Timeline`, `TimelineTemplate` | timeline period frames |
| `DisplayEventsForYear` | `Timeline.DisplayEventsForYear` | `{year:number, events:table}` | `Domain/Timeline` | `TimelineTemplate:OnDisplayEventsForYear` |

**Dynamic events:** `DisplayTimelineLabel`/`DisplayTimelinePeriod` are fired with a
numeric index appended (`Timeline.DisplayLabel3`). The Validator matches these via
a suffix pattern back to the base schema, so each indexed frame subscribes to its
own event name.

---

## State keys

Built through `StateManager` helpers (never hand-concatenate). Keys are
dot-namespaced; the first segment selects the AceDB persistence bucket.

### Key builders

| Builder | Produces | Example |
|---|---|---|
| `buildSelectionKey(entityType)` | `ui.selected<Entity>` | `ui.selectedEvent` |
| `buildUIStateKey(stateType)` | `ui.<stateType>` | `ui.activeTab`, `ui.selectedPeriod` |
| `buildTimelineKey(key)` | `timeline.<key>` | `timeline.currentStep` |
| `buildSettingsKey("eventType", id)` | `eventTypes.<id>` | `eventTypes.3` |
| `buildCollectionKey(name)` | `collections.<name>` | `collections.Legion` |
| `buildUserContentKey(type)` | `data.userContent.<type>` | `data.userContent.events` |

### Persistence buckets (`persistState` / `init`)

| Key prefix | AceDB location (`db.global`) |
|---|---|
| `ui.*` | `uiState` |
| `timeline.*` | `timelineState` |
| `eventTypes.*` | `settingsState.eventTypes` |
| `collections.*` | `settingsState.collections` |
| `data.*` (except `data.userContent`) | `dataState` |

### Keys in use

| Key | Type | Set by | Observed by |
|---|---|---|---|
| `ui.selectedEvent` | selection table | `VerticalListTemplate`, `EventListTemplate` | `MainFrameUI` (event book) |
| `ui.selectedCharacter` | selection table | `VerticalListTemplate` | `MainFrameUI` (character book) |
| `ui.selectedFaction` | selection table | `VerticalListTemplate` | `MainFrameUI` (faction book) |
| `ui.selectedPeriod` | table | `TimelineTemplate` | `TimelineTemplate` |
| `ui.activeTab` | number/string | `MainFrameUI` | tab UI |
| `timeline.currentStep` | number (a `stepValues` entry) | `Domain/Timeline`, `TimelineBusiness` | `TimelineBusiness`, `TimelineTemplate` |
| `timeline.currentPage` | number | `Domain/Timeline`, `TimelineBusiness` | `TimelineBusiness` |
| `timeline.selectedYear` | number | `Domain/Timeline` | timeline navigation |
| `eventTypes.<id>` | boolean | `Settings`, `Data` | timeline filtering |
| `collections.<name>` | boolean | `DataRegistry` (default on register), `Settings` | data filtering |
| `data.userContent.*` | structured table | runtime user content | data layer |

**Startup rehydration:** on `AddonStartup`, `OnAddonStartup` calls
`StateManager.rehydrate(key)` for `selectedPeriod`, the three selections, and
`activeTab` — re-emitting values restored from SavedVariables to their subscribers
without re-persisting them.
