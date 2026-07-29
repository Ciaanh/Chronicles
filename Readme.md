# Chronicles - World of Warcraft Addon

## Overview

Chronicles is a comprehensive World of Warcraft addon that provides an interactive timeline and database of historical events in the Warcraft universe. It allows players to explore events, characters, and factions from the lore through an intuitive, modern interface. The addon targets World of Warcraft Retail interface version 120001 (Midnight) and features a sophisticated state management system with event-driven architecture.

> Contributor quick rules: see .github/copilot-instructions.md for enforceable architecture and coding standards (state, events, UI patterns, localization).

## Key Features

### Core Functionality

1. **Interactive Timeline Navigation**: Multi-scale timeline with zoom levels (1000, 500, 100, 10 years) and smooth period navigation
2. **Event Browsing System**: Events categorized by type (event, era, war, battle, death, birth, other) with advanced filtering capabilities
3. **Character & Faction Database**: Comprehensive database with detailed information and cross-references to related events
4. **Book-Style Content Display**: Rich, chapter-based content presentation with image support and hierarchical organization
5. **Advanced Search & Filtering**: Powerful search engine with multi-criteria filtering and pagination

### Modern UI Architecture

1. **Tab-Based Interface**: Clean, organized interface with dedicated tabs for Events, Characters, Factions, and Settings
2. **State Management**: Centralized state management with automatic persistence and reactive UI updates
3. **Bookmark System**: Consistent bookmark-style visuals and navigation aids throughout the interface
4. **Responsive Design**: Optimized for different screen sizes with scalable UI components

### Advanced Features

1. **Custom Data Support**: Plugin-compatible architecture for custom events, characters, and factions
2. **Localization Ready**: Full localization support with comprehensive string externalization

## Technical Architecture

### Core Systems

1. **State Management System**:
   - Centralized StateManager with automatic persistence via AceDB-3.0
   - Hierarchical state organization (ui.*, timeline.*, settings.*, data.*)

2. **Event-Driven Architecture**:
   - Hybrid state-based + event-driven system for optimal performance
   - EventManager with schema validation and safe event triggering
   - Application lifecycle events (AddonStartup, TimelineInit, UIRefresh)
   - UI interaction events with proper error handling

3. **Timeline System**:
   - Multi-scale timeline calculation (1000, 500, 100, 10 year periods)
   - TimelineBusiness module for pure business logic separation
   - Period consolidation and event aggregation algorithms
   - Year-specific event display with search integration

4. **Data Management**:
   - Modular database architecture with plugin support
   - Data cleaning and localization processing pipeline
   - Search engine with multi-criteria filtering capabilities
   - Derived results (period filling, year bounds, filtered lists, book content) held in a bounded cache

5. **Modern UI Framework**:
   - XML-based UI with Mixin patterns for code organization
   - Book-style content display rendered as HTML documents, one per page
   - Shared template system for consistent UI components
   - Tab system with lazy loading

### Libraries & Dependencies

- **AceAddon-3.0**: Framework for addon organization and lifecycle management
- **AceConsole-3.0**: Console commands and chat integration
- **AceDB-3.0**: Database management with profile support
- **AceEvent-3.0**: Event handling and registration
- **AceLocale-3.0**: Localization support with string externalization
- **LibDataBroker-1.1** and **LibDBIcon-1.0**: Minimap button and data broker integration
- **LibStub**: Library loading and dependency resolution system

### Architecture Patterns

1. **Mixin Pattern**: UI components use mixins for shared functionality
2. **Template System**: Reusable UI templates with inheritance and composition
3. **State Synchronization**: Automatic UI updates through state change subscriptions
4. **Modular Design**: Clear separation of concerns across Core, UI, and Data modules

### Project Structure

`Chronicles.toc` lists exactly one file, `Chronicles.xml`, which pulls in everything else through a
chain of per-directory `_Includes.xml` files. There is no globbing: **a new file has to be registered
in the `_Includes.xml` of its own directory**, and the order matters — locales load before the DB
files that resolve `Locale[...]` at load time.

```
Chronicles.xml            Constants.lua -> Libs -> Locales + DB/Locales -> Chronicles.lua
Core/_Includes.xml        Infrastructure (StateManager, EventManager, Cache) -> Utils -> Data
                          -> Data.lua -> Domain
DB/DB.xml                 DB.lua plus one NN_<Expansion>/ directory per expansion
UI/_Includes.xml          ScrollFrameMixin -> Fonts -> VerticalListTemplate -> Book
                          -> Events -> Settings -> PageTemplatesRegistration -> MainFrameUI
```

## Integration Features

- **Minimap button** for quick access
- **Saved variables** for persistent user data and preferences
- **Plugin-compatible** architecture for custom content extensions — see [PLUGINS.md](PLUGINS.md) to author a content pack

## Installation

1. Download the latest version of the addon from your preferred source
2. Extract the contents to your World of Warcraft `Interface\AddOns` folder
3. Restart World of Warcraft if it's running
4. The addon will be available through the `/chronicles` command or the minimap button

## Usage

- **Use the minimap button** or type `/chronicles` to open the main interface
- **Navigate through events** using the timeline navigation with multiple zoom levels
- **Click on events** to view detailed information in book-style format
- **Browse characters and factions** related to events through dedicated tabs
- **Customize filtering** through the Settings tab to focus on specific content types

## Customization Options

- **Minimap button visibility** toggle
- **Event filtering by type** (event, era, war, battle, death, birth, other)
- **Collection management** for enabling/disabling content sets
- **Timeline zoom preferences** and navigation settings

## Development & Architecture Notes

### State Management

Chronicles implements a sophisticated state management system using the `StateManager` module:

```lua
-- Setting state
private.Core.StateManager.setState("ui.selectedEvent", eventId, "Event selected")

-- Getting state  
local selectedEvent = private.Core.StateManager.getState("ui.selectedEvent")

-- Subscribing to changes
private.Core.StateManager.subscribe("ui.selectedEvent", callback, "ModuleName")
```

### Event System

The addon uses a hybrid event-driven + state-based architecture:

- **Active Events**: AddonStartup, TimelineInit, UIRefresh, DisplayEventsForYear, the timeline's own
  label/period/paging events, and the two Settings change events
- **Legacy Events**: Selection events now handled via StateManager for better consistency
- **Schema Validation**: All events include validation schemas for type safety

### Performance Optimizations

- **Lazy Loading**: UI components and data are loaded on-demand
- **State Persistence**: Automatic saving to AceDB
- **Event Consolidation**: Timeline periods are consolidated to reduce memory usage
- **Derived-Result Cache**: Period filling, year bounds, search results and book content are cached
  and invalidated as a set whenever the underlying data changes

---

This addon serves as a comprehensive lore resource for World of Warcraft players, particularly useful for roleplayers who want to reference canonical events or create characters with historically accurate backgrounds. The modern architecture ensures maintainability and extensibility for future content updates.

## License

MIT

## Author

ciaanh

## Version

v2.2.0 (unreleased) — the last released version was v2.1.0 (July 29, 2026). `CHANGELOG.txt` has the
full history; `./tools/harness.ps1 version -Addon Chronicles` checks that this line, the TOC and the
changelog still agree.

Compatible with World of Warcraft Retail, interface 120001 (Midnight)
