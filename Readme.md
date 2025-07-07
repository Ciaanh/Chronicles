# Chronicles - World of Warcraft Addon

## Overview

Chronicles is a comprehensive World of Warcraft addon that provides an interactive timeline and database of historical events in the Warcraft universe. It allows players to explore events, characters, and factions from the lore through an intuitive, modern interface. The addon is compatible with World of Warcraft interface version 11.2.0 (The War Within expansion) and features a sophisticated state management system with event-driven architecture.

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
2. **External Integration**: Optional integration with roleplay addons (totalRP3, MyRolePlay) for enhanced character information
3. **Localization Ready**: Full localization support with comprehensive string externalization

## Technical Architecture

### Core Systems

1. **State Management System**:
   - Centralized StateManager with automatic persistence via AceDB-3.0
   - Event-driven state synchronization across UI components
   - Subscription patterns for reactive programming
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
   - User content management with versioning and metadata

5. **Modern UI Framework**:
   - XML-based UI with Mixin patterns for code organization
   - Book-style content display with chapter/page navigation
   - Shared template system for consistent UI components
   - Tab system with lazy loading and state persistence

### Libraries & Dependencies

- **AceAddon-3.0**: Framework for addon organization and lifecycle management
- **AceConsole-3.0**: Console commands and chat integration
- **AceDB-3.0**: Database management with profile support
- **AceEvent-3.0**: Event handling and registration
- **AceLocale-3.0**: Localization support with string externalization
- **LibDataBroker-1.1** and **LibDBIcon-1.0**: Minimap button and data broker integration
- **LibStub**: Library loading and dependency resolution system

### Architecture Patterns

1. **Dependency Injection**: DependencyContainer for managing circular dependencies
2. **Mixin Pattern**: UI components use mixins for shared functionality
3. **Template System**: Reusable UI templates with inheritance and composition
4. **State Synchronization**: Automatic UI updates through state change subscriptions
5. **Modular Design**: Clear separation of concerns across Core, UI, and Data modules

### Project Structure

```text
Chronicles/
├── Chronicles.toc                    # Addon metadata and interface version
├── Chronicles.xml                    # Main include file defining load order
├── Chronicles.lua                    # Main addon initialization and lifecycle
├── Constants.lua                     # Global constants and configuration
├── Core/                            # Core systems and business logic
│   ├── Infrastructure/              # Foundational systems
│   │   ├── EventManager.lua         # Event handling with schema validation
│   │   ├── StateManager.lua         # Centralized state management
│   │   ├── DependencyContainer.lua  # Dependency injection system
│   │   └── Cache.lua                # Data caching and performance optimization
│   ├── Domain/                      # Business domain logic
│   │   ├── Timeline.lua             # Timeline navigation and display logic
│   │   ├── Events.lua               # Event data handling and processing
│   │   ├── Characters.lua           # Character data management
│   │   ├── Factions.lua             # Faction data management
│   │   └── Settings.lua             # User settings and configuration
│   ├── Data/                        # Data access and processing
│   │   ├── TimelineBusiness.lua     # Timeline calculation algorithms
│   │   ├── SearchEngine.lua         # Multi-criteria search functionality
│   │   ├── FilterEngine.lua         # Event filtering and categorization
│   │   ├── DataRegistry.lua         # Data source registration and management
│   │   └── Types.lua                # Data type definitions and validation
│   ├── Business/                    # Business logic coordination
│   │   ├── DateCalculator.lua       # Date calculations and formatting
│   │   └── FilterEngine.lua         # Event filtering logic
│   └── Utils/                       # Shared utilities
│       ├── HelperUtils.lua          # General helper functions
│       ├── StringUtils.lua          # String manipulation utilities
│       ├── TableUtils.lua           # Table operation utilities
│       ├── MathUtils.lua            # Mathematical calculations
│       ├── ValidationUtils.lua      # Input validation utilities
│       └── UIUtils.lua              # UI-specific helper functions
├── UI/                              # User interface components
│   ├── MainFrameUI.lua/xml          # Main interface frame (1200x850)
│   ├── Events/                      # Events tab components
│   │   ├── Timeline/                # Timeline visualization
│   │   └── List/                    # Event list and pagination
│   ├── Characters/                  # Characters tab components
│   ├── Factions/                    # Factions tab components
│   ├── Settings/                    # Settings and configuration UI
│   └── Templates/                   # Reusable UI templates
│       ├── VerticalListTemplate.*   # Shared list component
│       ├── SharedBookTemplate.*     # Book-style content display
│       ├── BookPages.xml            # Chapter and page templates
│       └── Templates.lua            # Template registration and utilities
├── DB/                              # Database and content
│   ├── DB.lua                       # Database registration and initialization
│   └── 01_Sample/                   # Sample data sets
│       ├── SampleEventsDB.lua       # Sample event data
│       ├── SampleCharactersDB.lua   # Sample character data
│       └── SampleFactionsDB.lua     # Sample faction data
├── Locales/                         # Localization files
│   ├── enUS.lua                     # English (US) strings
│   └── Locales.xml                  # Locale registration
├── Libs/                            # Third-party libraries
│   ├── AceAddon-3.0/               # Addon framework
│   ├── AceDB-3.0/                  # Database management
│   ├── AceEvent-3.0/               # Event handling
│   ├── AceLocale-3.0/              # Localization
│   ├── LibDataBroker-1.1/          # Data broker interface
│   ├── LibDBIcon-1.0/              # Minimap icon support
│   └── LibStub/                     # Library loading system
└── Art/                             # Visual assets
    ├── Images/                      # UI images and portraits
    ├── Portrait/                    # Character portraits
    └── Raw/                         # Source art files
```

## Integration Features

- **Optional dependencies** on roleplay addons (totalRP3, MyRolePlay)
- **Minimap button** for quick access
- **Saved variables** for persistent user data and preferences
- **Plugin-compatible** architecture for custom content extensions

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
- **Event filtering by type** (war, battle, death, birth, era, other)
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

- **Active Events**: AddonStartup, TimelineInit, UIRefresh, TabUITabSet, Settings changes
- **Legacy Events**: Selection events now handled via StateManager for better consistency
- **Schema Validation**: All events include validation schemas for type safety

### Performance Optimizations

- **Lazy Loading**: UI components and data are loaded on-demand
- **State Persistence**: Automatic saving to AceDB with intelligent caching
- **Event Consolidation**: Timeline periods are consolidated to reduce memory usage
- **Search Indexing**: Pre-computed search indices for fast event lookup

---

This addon serves as a comprehensive lore resource for World of Warcraft players, particularly useful for roleplayers who want to reference canonical events or create characters with historically accurate backgrounds. The modern architecture ensures maintainability and extensibility for future content updates.

## License

MIT

## Author

ciaanh

## Version

v2.0.0 (July 7, 2025)

Compatible with World of Warcraft 11.2.0 (The War Within)
