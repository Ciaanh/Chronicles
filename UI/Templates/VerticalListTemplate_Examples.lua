--[[
    SHARED VERTICAL LIST TEMPLATE - USAGE EXAMPLES
    
    This document demonstrates how to use the new VerticalListTemplate
    for both characters and factions, as well as custom implementations.
    
    The template provides a flexible, configuration-driven approach
    that maintains consistency with Chronicles addon design patterns.
    
    IMPORTANT: State Management Protection
    
    The template includes protection against invalid stateManagerKey values.
    All state management operations (item clicks, state subscriptions, 
    selection synchronization) will only execute when the stateManagerKey
    is properly configured (not "generic"). This prevents runtime errors
    during initialization and ensures robust operation.
--]]
--[[
    EXAMPLE 1: Using Pre-configured Character List
    
    In your XML:
    <Frame parentKey="MyCharacterList" inherits="VerticalCharacterListSharedTemplate">
        <Size x="150" y="650"/>
        <Anchors>
            <Anchor point="BOTTOMLEFT" x="0" y="0" />
        </Anchors>
    </Frame>
    
    The VerticalCharacterListSharedTemplate is pre-configured with:
    - itemType = "character"
    - searchPlaceholder = "Search Characters..."    - countLabelFormat = "%d Characters"
    - stateManagerKey = "character"
    - dataSourceMethod = "getAllCharacters"
    - templateKey = "GENERIC_LIST_ITEM"
--]]
--[[
    EXAMPLE 2: Using Pre-configured Faction List
    
    In your XML:
    <Frame parentKey="MyFactionList" inherits="VerticalFactionListSharedTemplate">
        <Size x="150" y="650"/>
        <Anchors>
            <Anchor point="BOTTOMLEFT" x="0" y="0" />
        </Anchors>
    </Frame>
    
    The VerticalFactionListSharedTemplate is pre-configured with:
    - itemType = "faction"
    - searchPlaceholder = "Search Factions..."
    - countLabelFormat = "%d Factions"
    - stateManagerKey = "faction"
    - dataSourceMethod = "SearchFactions"
    - templateKey = "GENERIC_LIST_ITEM"
--]]
--[[
    EXAMPLE 3: Custom Configuration
    
    You can create your own specialized template by inheriting from VerticalListTemplate
    and setting custom KeyValues:
    
    <Frame name="MyCustomVerticalListTemplate" inherits="VerticalListTemplate" virtual="true">
        <KeyValues>
            <KeyValue key="itemType" value="event" type="string" />
            <KeyValue key="searchPlaceholder" value="Search Events..." type="string" />
            <KeyValue key="countLabelFormat" value="%d Events Found" type="string" />
            <KeyValue key="stateManagerKey" value="event" type="string" />
            <KeyValue key="dataSourceMethod" value="getAllEvents" type="string" />
            <KeyValue key="templateKey" value="EVENT_LIST_ITEM" type="string" />
        </KeyValues>
    </Frame>
--]]
--[[
    EXAMPLE 4: Runtime Configuration
    
    You can also configure the template at runtime:
    
    function ConfigureMyList(listFrame)
        listFrame:ConfigureForCharacters()  -- Built-in character configuration
        -- or
        listFrame:ConfigureForFactions()    -- Built-in faction configuration
        -- or custom configuration:
        listFrame.itemType = "myCustomType"
        listFrame.searchPlaceholder = "Search My Items..."
        listFrame.countLabelFormat = "%d My Items"
        listFrame.stateManagerKey = "myCustom"
        listFrame.dataSourceMethod = "getAllMyItems"
        listFrame.templateKey = "MY_CUSTOM_LIST_ITEM"
        listFrame:RefreshItemList()
    end
--]]
--[[
    IMPLEMENTATION NOTES:
    
    The shared template avoids the GetKeyValue error by using a different approach:
    
    1. The base VerticalListMixin sets defaults in OnLoad()
    2. Specialized mixins (VerticalCharacterListSharedMixin, VerticalFactionListSharedMixin) 
       override these defaults using configuration methods
    3. Configuration can also be done at runtime using the provided methods
    4. This approach is more compatible with WoW's addon framework
    
    Error that was fixed:
    - GetKeyValue is not a standard WoW API method
    - KeyValues in XML are not accessible via GetKeyValue()
    - The solution uses mixin inheritance and configuration methods instead
--]]
--[[
    EXAMPLE 5: Integration with Existing Code
    
    The new template can be used alongside existing templates without modification:
    
    -- In MainFrameUI.xml, you could add:
    <Frame parentKey="Characters" frameLevel="100" hidden="true">
        <Frames>
            <!-- New shared template for factions in character tab -->
            <Frame parentKey="RelatedFactions" inherits="VerticalFactionListSharedTemplate">
                <Size x="150" y="300"/>
                <Anchors>
                    <Anchor point="BOTTOMRIGHT" x="-10" y="0" />
                </Anchors>
            </Frame>
            
            <Frame parentKey="Book" inherits="CharacterBookTemplate">
                <Size x="1200" y="650"/>
                <Anchors>
                    <Anchor point="BOTTOM" />
                </Anchors>
            </Frame>
        </Frames>
    </Frame>
--]]
--[[
    BENEFITS OF THE SHARED TEMPLATE:
    
    1. CONSISTENCY: All vertical lists use the same bookmark visual style
    2. MAINTAINABILITY: Single template to update for visual changes
    3. FLEXIBILITY: Configuration-driven approach for different item types
    4. REUSABILITY: Can be used for any item type with minimal setup
    5. STATE MANAGEMENT: Integrated with Chronicles state management system
    6. SEARCH: Built-in search functionality with customizable placeholders
    7. PERFORMANCE: Optimized data handling and rendering
    8. ACCESSIBILITY: Consistent tooltip and interaction patterns
    
    BACKWARDS COMPATIBILITY:
    
    - New shared template can be used alongside existing templates
    - No modifications to existing code are required
    - Gradual migration possible if desired
--]]
