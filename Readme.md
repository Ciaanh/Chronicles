# Chronicles - World of Warcraft Addon

## Overview
Chronicles is a World of Warcraft addon that provides a timeline of historical events in the Warcraft universe. It allows players to browse through various events, characters, and factions from the lore, organized chronologically. The addon is designed to work with World of Warcraft interface version 110002 (11.0.2).

## Key Features
1. **Timeline Navigation**: Users can navigate through a timeline of events with different scaling options (1000, 500, 250, 100, 50, 10 years).
2. **Event Browsing**: Events are categorized by type (undefined, event, era, war, battle, death) and organized by expansion.
3. **Character and Faction Information**: The addon includes data about characters and factions involved in the events.
4. **Custom Journal**: Users can create their own journal entries for events, factions, and characters.
5. **User Interface**: The addon has a modern UI framework with tabs and panels for navigating different sections.

## Technical Architecture

### Core Components
1. **Data Structure**: 
   - Events with start and end years, description as book chapters, characters, and factions involved
   - Chapters within events for detailed storytelling
   - Factions and characters data

2. **Timeline System**: 
   - Different time scales (1000, 500, 250, 100, 50, 10 years)
   - Period markers to divide the timeline
   - Date calculation and formatting system

3. **Database Organization**:
   - Events organized by expansion/timeline modules
   - Categorized into sections like Origins, Great Wars, and specific WoW expansions (up to War Within)

4. **User Interface**:
   - Modern UI framework with tab system
   - Main frame for displaying content
   - Templates for various UI elements
   - Bookmarks and navigation elements

### Libraries Used
- AceAddon-3.0: Framework for addon organization
- AceConsole-3.0: Console commands
- AceDB-3.0: Database management
- AceEvent-3.0: Event handling
- AceLocale-3.0: Localization support
- LibDataBroker-1.1 and LibDBIcon-1.0: Minimap button and data broker
- LibStub: Library loading system

### File Organization
1. **Root Files**:
   - Chronicles.lua: Main addon initialization
   - Constants.lua: Defines constants and default settings
   - Functions.lua: Utility functions

2. **Core Modules**:
   - Timeline.lua: Timeline navigation and display logic
   - Events.lua: Event handling and format
   - Characters.lua: Character data handling
   - Factions.lua: Faction data handling
   - Data.lua: Data management and registration
   - Settings.lua: User settings

3. **UI Components**:
   - MainFrameUI.lua/xml: Main interface frame
   - Templates for characters, events, factions, etc.
   - Various UI elements and textures

4. **Custom Data**:
   - ChroniclesDB.lua: Database registration
   - Expansion-specific event databases
   - Localization files

## Integration Features
- Optional dependencies on roleplay addons (totalRP3, MyRolePlay)
- Minimap button for access
- Saved variables for persistent user data

## Installation
1. Download the latest version of the addon
2. Extract the contents to your World of Warcraft `Interface\AddOns` folder
3. Restart World of Warcraft if it's running
4. The addon will be available through the `/chronicles` command or the minimap button

## Usage
- Use the minimap button or type `/chronicles` to open the main interface
- Navigate through events using the timeline navigation
- Click on events to view detailed information
- Browse characters and factions related to events
- Create custom journal entries for your own lore

## Customization Options
- Minimap button visibility
- Event filtering by type
- Custom journal entries
- Settings for display preferences

---

This addon serves as a lore resource for players interested in the Warcraft universe's timeline and history, particularly useful for roleplayers who want to reference canonical events or create characters with historically accurate backgrounds.

## License
MIT

## Author
ciaanh

## Version
v2.0.0