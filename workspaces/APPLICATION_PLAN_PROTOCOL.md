# APPLICATION_PLAN_PROTOCOL.md

Generate test-driven application requirements as structured checklists for comprehensive Axiom framework validation.

## Protocol Activation

```text
@APPLICATION_PLAN [command] [arguments]
```

## Commands

```text
generate task-manager                    → Generate TDD requirements for offline task management app
generate local-chat                      → Generate TDD requirements for local chat app
update-requirements [id] [framework-doc] → Update requirements based on framework documentation
```

## Process Flow

```text
1. Generate initial requirements with RED-GREEN-REFACTOR structure
2. Update requirements using framework documentation for comprehensive coverage
3. Each requirement tests specific framework components
4. Ready for TDD development
```

## Command Details

### Generate Command

Create TDD-structured requirements with framework coverage:

```bash
@APPLICATION_PLAN generate task-manager
```

Actions:
1. Create basic requirements structure with checklists
2. Generate REQUIREMENTS-XXX-[TYPE]-[TITLE].md
3. Structure each requirement with RED-GREEN-REFACTOR checklists
4. Focus on core application functionality testing

Output:
```
Generating TDD requirements for task-manager...

Application Type: task-manager (offline)
Focus: Local task management with cross-platform features

Created: ApplicationWorkspace/CYCLE-001-TASK-MANAGER-MVP/
└── REQUIREMENTS-001-TASK-MANAGER-MVP.md

Initial Requirements:
- REQ-001: Task Model
- REQ-002: Task Persistence  
- REQ-003: Task List View
- REQ-004: Task Creation
- REQ-005: Task Editing
- REQ-006: Task Deletion
- REQ-007: Task Filtering
- REQ-008: Task Status Management
- REQ-009: Navigation State Management
- REQ-010: Error Handling
- REQ-011: iOS Application Entry Point
- REQ-012: macOS Application Entry Point
- REQ-013: Cross-Platform App Configuration
- REQ-014-022: Platform-Specific Services and Features

Requirements: 22 comprehensive requirements with RED-GREEN-REFACTOR phases
Tests: 100+ test specifications across all platform scenarios

Next: Update with framework documentation for comprehensive testing
@APPLICATION_PLAN update-requirements 001 [framework-doc-path]
```

For local chat generation:
```
Generating TDD requirements for local-chat...

Application Type: local-chat (local network)
Focus: Peer-to-peer messaging with cross-platform features

Created: ApplicationWorkspace/CYCLE-002-LOCAL-CHAT-MVP/
└── REQUIREMENTS-002-LOCAL-CHAT-MVP.md

Initial Requirements:
- REQ-001: Peer Discovery with Network Capability
- REQ-002: Message Sending with Actor Concurrency
- REQ-003: Real-time Message Display
- REQ-004: Connection State Management
- REQ-005: Multi-peer Coordination
- REQ-006: Security with Encryption Capability
- REQ-007: Background Processing
- REQ-008: Message History and Persistence
- REQ-009: Stress Testing and Limits
- REQ-010: iOS Application Entry Point
- REQ-011: macOS Application Entry Point
- REQ-012: Cross-Platform Chat Configuration
- REQ-013-021: Platform-Specific Network Services and Features

Requirements: 21 comprehensive requirements with RED-GREEN-REFACTOR phases
Tests: 100+ test specifications across all platform scenarios

Next: Update with framework documentation for comprehensive testing
@APPLICATION_PLAN update-requirements 002 [framework-doc-path]
```

### Update Requirements Command

Enhance requirements with comprehensive framework testing:

```bash
@APPLICATION_PLAN update-requirements 001 DOCUMENTATION-001.md
```

Actions:
1. Load existing REQUIREMENTS-XXX.md
2. Parse framework DOCUMENTATION-XXX.md
3. Map framework components to test scenarios
4. Update requirements to ensure full API coverage
5. Preserve existing TDD structure

Output:
```
Updating REQUIREMENTS-001-TASK-MANAGER-MVP with DOCUMENTATION-001.md...

Framework: v0.1.0 (6 core components)
Existing Requirements: 10

Framework Component Analysis:
- Data Models: Validation patterns → Enhancing REQ-001
- Repository: Persistence patterns → Enhancing REQ-002
- SwiftUI Views: Binding patterns → Enhancing REQ-003, 004, 005
- State Management: Navigation patterns → Enhancing REQ-007, 008, 009
- Error Handling: Recovery patterns → Enhancing REQ-006, 010
- iOS Entry Point: Platform integration → Creating REQ-011
- macOS Entry Point: Platform integration → Creating REQ-012
- Cross-Platform: Configuration patterns → Creating REQ-013-022

Updated: REQUIREMENTS-001-TASK-MANAGER-MVP.md
- Enhanced 10 existing requirements
- Added 12 new platform-specific requirements
- Total test specifications: 100+ (was 35)
- Framework coverage: 100% including all platform integrations

Next: @APPLICATION_DEVELOP start 001
```

For local chat update:
```
Updating REQUIREMENTS-002-LOCAL-CHAT-MVP with DOCUMENTATION-001.md...

Framework: v0.1.0 (6 core components)
Existing Requirements: 9

Framework Component Analysis:
- Network Services: Discovery patterns → Enhancing REQ-001, 004
- Message Handling: Concurrency patterns → Enhancing REQ-002, 005
- SwiftUI Views: Real-time updates → Enhancing REQ-003
- State Management: Connection states → Enhancing REQ-004
- Error Handling: Network recovery → Enhancing REQ-006
- iOS Entry Point: Network lifecycle → Creating REQ-010
- macOS Entry Point: Multi-window chat → Creating REQ-011
- Cross-Platform: Network configuration → Creating REQ-012-021

Updated: REQUIREMENTS-002-LOCAL-CHAT-MVP.md
- Enhanced 9 existing requirements
- Added 12 new platform-specific requirements
- Total test specifications: 100+ (was 40)
- Framework coverage: 100% including all network platform integrations

Next: @APPLICATION_DEVELOP start 002
```

## Framework-Driven Requirements

### Task Manager Requirements (Offline Cross-Platform Application)

The Task Manager is a completely offline application demonstrating local data management, persistence, and platform integration without any network dependencies.

Generated requirements provide test checklists for:

#### REQ-001: Task Model
**Framework Components**: Data modeling, Validation, Codable protocol
- **RED**: 
  - [ ] Test Task initialization with required fields
  - [ ] Test Task validation rules
  - [ ] Test Task property mutations
  - [ ] Test Task equality comparison
- **GREEN**: 
  - [ ] Implement Task struct with required properties
  - [ ] Implement validation logic for constraints
  - [ ] Implement status and priority enums
  - [ ] Implement timestamp generation
- **REFACTOR**: 
  - [ ] Extract validation constants to configuration
  - [ ] Optimize property storage
  - [ ] Add computed properties for display values
  - [ ] Ensure Codable conformance for persistence

#### REQ-002: Task Persistence
**Framework Components**: Repository pattern, Data storage, CRUD operations
- **RED**: 
  - [ ] Test saving a single task
  - [ ] Test loading all tasks
  - [ ] Test updating existing task
  - [ ] Test deleting task
  - [ ] Test batch operations
  - [ ] Test persistence error scenarios
- **GREEN**: 
  - [ ] Implement TaskRepository protocol
  - [ ] Implement storage adapter (CoreData/UserDefaults)
  - [ ] Implement CRUD operations with error handling
  - [ ] Implement batch operations with transactions
- **REFACTOR**: 
  - [ ] Abstract storage mechanism behind protocol
  - [ ] Optimize fetch performance with indexes
  - [ ] Add caching layer for frequent queries
  - [ ] Implement data versioning strategy

#### REQ-003: Task List View
**Framework Components**: SwiftUI views, List performance, State binding
- **RED**: 
  - [ ] Test view with empty task list
  - [ ] Test view with multiple tasks
  - [ ] Test task cell display properties
  - [ ] Test pull-to-refresh behavior
  - [ ] Test task selection
- **GREEN**: 
  - [ ] Implement TaskListView with List component
  - [ ] Implement TaskRowView for individual tasks
  - [ ] Implement empty state view
  - [ ] Implement refresh control
  - [ ] Implement selection handling
- **REFACTOR**: 
  - [ ] Extract reusable view components
  - [ ] Optimize list performance with lazy loading
  - [ ] Add accessibility labels and hints
  - [ ] Implement view configuration options

#### REQ-004: Task Creation
**Framework Components**: Form validation, Input handling, State management
- **RED**: 
  - [ ] Test form presentation
  - [ ] Test title field validation
  - [ ] Test form submission with valid/invalid data
  - [ ] Test form cancellation
  - [ ] Test keyboard behavior
- **GREEN**: 
  - [ ] Implement CreateTaskView with form fields
  - [ ] Implement form validation logic
  - [ ] Implement submission and cancellation handlers
  - [ ] Implement keyboard toolbar and focus management
- **REFACTOR**: 
  - [ ] Extract form validation to reusable component
  - [ ] Optimize keyboard responsiveness
  - [ ] Add form field animations
  - [ ] Implement auto-save draft functionality

#### REQ-005: Task Editing
**Framework Components**: Change tracking, State updates, Undo management
- **RED**: 
  - [ ] Test loading task data into form
  - [ ] Test change detection
  - [ ] Test save button state management
  - [ ] Test discard changes confirmation
  - [ ] Test timestamp updates
- **GREEN**: 
  - [ ] Implement EditTaskView with pre-population
  - [ ] Implement change tracking logic
  - [ ] Implement save button state binding
  - [ ] Implement discard confirmation alert
  - [ ] Implement undo manager integration
- **REFACTOR**: 
  - [ ] Share form components with creation view
  - [ ] Optimize change detection algorithm
  - [ ] Add field-level validation feedback
  - [ ] Implement optimistic updates

#### REQ-006: Task Deletion
**Framework Components**: User confirmation, Gesture handling, Undo support
- **RED**: 
  - [ ] Test deletion confirmation
  - [ ] Test swipe gesture handling
  - [ ] Test undo functionality
  - [ ] Test batch deletion
  - [ ] Test cascading deletion
- **GREEN**: 
  - [ ] Implement deletion confirmation alert
  - [ ] Implement swipe action handler
  - [ ] Implement undo manager for deletion
  - [ ] Implement batch deletion logic
  - [ ] Implement data cleanup on deletion
- **REFACTOR**: 
  - [ ] Extract deletion logic to service
  - [ ] Add deletion animations
  - [ ] Implement soft delete for recovery
  - [ ] Add deletion audit logging

#### REQ-007: Task Filtering
**Framework Components**: Search algorithms, Filter logic, State persistence
- **RED**: 
  - [ ] Test status filtering
  - [ ] Test priority filtering
  - [ ] Test text search
  - [ ] Test combined filters
  - [ ] Test filter persistence
- **GREEN**: 
  - [ ] Implement FilterOptions model
  - [ ] Implement status and priority filter logic
  - [ ] Implement search algorithm
  - [ ] Implement filter combination logic
  - [ ] Implement filter persistence
- **REFACTOR**: 
  - [ ] Optimize filter performance with indexes
  - [ ] Add filter presets
  - [ ] Implement smart filters
  - [ ] Add filter animation transitions

#### REQ-008: Task Status Management
**Framework Components**: State machines, Transition validation, History tracking
- **RED**: 
  - [ ] Test valid status transitions
  - [ ] Test invalid status transitions
  - [ ] Test timestamp updates
  - [ ] Test bulk updates
  - [ ] Test status history tracking
- **GREEN**: 
  - [ ] Implement status transition rules
  - [ ] Implement transition validation
  - [ ] Implement timestamp update logic
  - [ ] Implement bulk update operations
  - [ ] Implement status history model
- **REFACTOR**: 
  - [ ] Extract status machine to separate component
  - [ ] Add transition animations
  - [ ] Implement status analytics
  - [ ] Add status change notifications

#### REQ-009: Navigation State Management
**Framework Components**: Navigation patterns, State persistence, Deep linking
- **RED**: 
  - [ ] Test navigation state persistence
  - [ ] Test deep link handling
  - [ ] Test navigation stack management
  - [ ] Test gesture navigation
  - [ ] Test navigation history
- **GREEN**: 
  - [ ] Implement NavigationState model
  - [ ] Implement state persistence layer
  - [ ] Implement deep link parser
  - [ ] Implement navigation stack logic
  - [ ] Implement gesture recognizers
- **REFACTOR**: 
  - [ ] Optimize navigation performance
  - [ ] Add navigation animations
  - [ ] Implement navigation shortcuts
  - [ ] Add navigation analytics

#### REQ-010: Error Handling
**Framework Components**: Error presentation, Logging, Recovery mechanisms
- **RED**: 
  - [ ] Test error message display
  - [ ] Test error logging
  - [ ] Test recovery actions
  - [ ] Test network error handling
  - [ ] Test retry logic
- **GREEN**: 
  - [ ] Implement error presentation system
  - [ ] Implement error logging service
  - [ ] Implement recovery action handlers
  - [ ] Implement network error detection
  - [ ] Implement exponential backoff retry
- **REFACTOR**: 
  - [ ] Centralize error handling logic
  - [ ] Add error categorization
  - [ ] Implement error analytics
  - [ ] Add contextual error help

#### REQ-011: iOS Application Entry Point
**Framework Components**: SwiftUI App protocol, Scene lifecycle, Platform integration
- **RED**: 
  - [ ] Test app launch initialization
  - [ ] Test scene configuration
  - [ ] Test app state transition handling
  - [ ] Test deep link URL processing
  - [ ] Test framework integration
- **GREEN**: 
  - [ ] Implement TaskManagerApp struct with @main
  - [ ] Implement WindowGroup scene configuration
  - [ ] Implement scenePhase change handlers
  - [ ] Implement URL scheme registration
  - [ ] Implement framework context initialization
- **REFACTOR**: 
  - [ ] Extract app configuration to separate module
  - [ ] Optimize startup performance
  - [ ] Add app lifecycle analytics
  - [ ] Implement crash recovery mechanisms

#### REQ-012: macOS Application Entry Point
**Framework Components**: NSApplicationDelegate, Window management, Platform services
- **RED**: 
  - [ ] Test app delegate initialization
  - [ ] Test window creation and management
  - [ ] Test menu configuration
  - [ ] Test window restoration
  - [ ] Test app termination handling
- **GREEN**: 
  - [ ] Implement AppDelegate class with lifecycle methods
  - [ ] Implement window controller with restoration
  - [ ] Implement main menu structure
  - [ ] Implement multi-window support
  - [ ] Implement graceful termination
- **REFACTOR**: 
  - [ ] Extract window management to service
  - [ ] Optimize window creation performance
  - [ ] Add window state persistence
  - [ ] Implement keyboard shortcuts

#### REQ-013: Cross-Platform App Configuration
**Framework Components**: Platform detection, Feature flags, Dependency injection
- **RED**: 
  - [ ] Test platform detection
  - [ ] Test feature flag evaluation
  - [ ] Test dependency injection setup
  - [ ] Test resource loading by platform
  - [ ] Test conditional UI elements
- **GREEN**: 
  - [ ] Implement AppConfiguration protocol
  - [ ] Implement PlatformDetector utility
  - [ ] Implement DependencyContainer setup
  - [ ] Implement ResourceLoader with platform variants
  - [ ] Implement unified theme system
- **REFACTOR**: 
  - [ ] Optimize platform-specific code paths
  - [ ] Add configuration validation
  - [ ] Implement hot-reload for development
  - [ ] Add platform capability detection

#### REQ-014: Platform-Specific Service Initialization
**Framework Components**: Service registry, Capability detection, Platform APIs
- **RED**: 
  - [ ] Test notification service initialization (local only)
  - [ ] Test permission request handling
  - [ ] Test URL scheme registration (for task import)
  - [ ] Test hardware capability detection
  - [ ] Test service availability checking
  - [ ] Test fallback behavior for missing services
- **GREEN**: 
  - [ ] Implement NotificationService for local notifications
  - [ ] Implement PermissionManager for each platform
  - [ ] Implement URLSchemeRegistrar for task data
  - [ ] Implement CapabilityDetector utility
  - [ ] Implement ServiceRegistry with conditional registration
  - [ ] Implement FallbackHandler for missing services
- **REFACTOR**: 
  - [ ] Abstract service interfaces for testability
  - [ ] Optimize service startup order
  - [ ] Add service health monitoring
  - [ ] Implement service dependency injection
  - [ ] Add service initialization analytics

#### REQ-015: iOS Scene Management and Lifecycle
**Framework Components**: SceneDelegate, State restoration, Multitasking
- **RED**: 
  - [ ] Test scene delegate initialization
  - [ ] Test scene configuration handling
  - [ ] Test scene state restoration
  - [ ] Test multitasking support
  - [ ] Test background/foreground transitions
  - [ ] Test system UI integration (status bar, safe areas)
- **GREEN**: 
  - [ ] Implement SceneDelegate with lifecycle methods
  - [ ] Implement scene configuration manager
  - [ ] Implement state restoration coordinator
  - [ ] Implement multitasking window support
  - [ ] Implement transition handlers
  - [ ] Implement system UI integration
- **REFACTOR**: 
  - [ ] Extract scene management to service layer
  - [ ] Optimize scene transition performance
  - [ ] Add scene analytics and monitoring
  - [ ] Implement scene-specific error handling
  - [ ] Add scene debugging tools

#### REQ-016: macOS Window and Menu Management
**Framework Components**: WindowController, Menu bar, Dock integration
- **RED**: 
  - [ ] Test window controller creation
  - [ ] Test menu bar configuration
  - [ ] Test window state persistence
  - [ ] Test window operations (minimize, zoom, close)
  - [ ] Test dock integration with badges
  - [ ] Test keyboard shortcuts
- **GREEN**: 
  - [ ] Implement WindowController with lifecycle
  - [ ] Implement MenuBarManager with native menus
  - [ ] Implement WindowStateManager for persistence
  - [ ] Implement window operation handlers
  - [ ] Implement DockManager for task count badges
  - [ ] Implement KeyboardShortcutManager
- **REFACTOR**: 
  - [ ] Extract window management patterns
  - [ ] Optimize window creation performance
  - [ ] Add window management analytics
  - [ ] Implement advanced window features
  - [ ] Add accessibility for window operations

#### REQ-017: Platform-Specific Resource Management
**Framework Components**: Asset loading, Font management, Color schemes
- **RED**: 
  - [ ] Test platform asset loading
  - [ ] Test conditional font handling
  - [ ] Test color scheme adaptation
  - [ ] Test layout adaptation for screen sizes
  - [ ] Test localization switching
  - [ ] Test feature flag evaluation
- **GREEN**: 
  - [ ] Implement PlatformResourceLoader
  - [ ] Implement FontManager with platform variants
  - [ ] Implement ColorSchemeManager
  - [ ] Implement AdaptiveLayoutManager
  - [ ] Implement LocalizationManager
  - [ ] Implement FeatureFlagManager
- **REFACTOR**: 
  - [ ] Optimize resource loading performance
  - [ ] Add resource caching strategies
  - [ ] Implement hot-reload for development
  - [ ] Add resource usage analytics
  - [ ] Extract common resource patterns

#### REQ-018: iOS Background Task Handling
**Framework Components**: Background refresh, Task processing, Local operations
- **RED**: 
  - [ ] Test background app refresh registration
  - [ ] Test background task lifecycle
  - [ ] Test local data maintenance tasks
  - [ ] Test background processing limits
  - [ ] Test battery usage optimization
  - [ ] Test task completion handling
- **GREEN**: 
  - [ ] Implement BackgroundTaskManager
  - [ ] Implement background refresh handlers
  - [ ] Implement local data cleanup tasks
  - [ ] Implement processing time management
  - [ ] Implement battery optimization strategies
  - [ ] Implement task completion callbacks
- **REFACTOR**: 
  - [ ] Optimize background operation efficiency
  - [ ] Add background task monitoring
  - [ ] Implement smart scheduling algorithms
  - [ ] Add background operation analytics
  - [ ] Extract reusable background patterns

#### REQ-019: macOS File Associations and URL Schemes
**Framework Components**: File type registration, Import/export, Drag-and-drop
- **RED**: 
  - [ ] Test file type registration (.task files)
  - [ ] Test file opening from Finder
  - [ ] Test custom URL scheme for task data
  - [ ] Test drag-and-drop file operations
  - [ ] Test import/export workflows
  - [ ] Test file permission handling
- **GREEN**: 
  - [ ] Implement FileTypeManager for .task files
  - [ ] Implement file opening delegate methods
  - [ ] Implement URLSchemeHandler for task:// URLs
  - [ ] Implement DragDropManager
  - [ ] Implement FileWorkflowManager
  - [ ] Implement FilePermissionManager
- **REFACTOR**: 
  - [ ] Extract file handling patterns
  - [ ] Optimize file operation performance
  - [ ] Add file operation analytics
  - [ ] Implement advanced file features
  - [ ] Add error recovery for file operations

#### REQ-020: Cross-Platform Gesture and Input Handling
**Framework Components**: Gesture recognition, Input abstraction, Accessibility
- **RED**: 
  - [ ] Test iOS touch gestures (tap, swipe, long press)
  - [ ] Test macOS mouse and trackpad gestures
  - [ ] Test context menu presentation
  - [ ] Test keyboard input consistency
  - [ ] Test accessibility input methods
  - [ ] Test haptic feedback for iOS
- **GREEN**: 
  - [ ] Implement GestureManager with platform detection
  - [ ] Implement touch gesture recognizers
  - [ ] Implement mouse/trackpad handlers
  - [ ] Implement ContextMenuManager
  - [ ] Implement KeyboardInputManager
  - [ ] Implement HapticFeedbackManager
- **REFACTOR**: 
  - [ ] Extract common gesture patterns
  - [ ] Optimize gesture recognition performance
  - [ ] Add gesture customization options
  - [ ] Implement gesture analytics
  - [ ] Add gesture debugging tools

#### REQ-021: Platform-Specific Build Configuration
**Framework Components**: Build settings, Code signing, Conditional compilation
- **RED**: 
  - [ ] Test build configuration validation
  - [ ] Test entitlement verification
  - [ ] Test conditional compilation flags
  - [ ] Test code signing verification
  - [ ] Test dependency resolution
  - [ ] Test environment configuration
- **GREEN**: 
  - [ ] Implement BuildConfigurationManager
  - [ ] Configure platform-specific entitlements
  - [ ] Implement conditional compilation macros
  - [ ] Set up code signing configurations
  - [ ] Configure dependency management
  - [ ] Implement environment detection
- **REFACTOR**: 
  - [ ] Optimize build time performance
  - [ ] Add build validation scripts
  - [ ] Implement build analytics
  - [ ] Extract common build patterns
  - [ ] Add build troubleshooting tools

#### REQ-022: iOS App Store and macOS Notarization Compliance
**Framework Components**: Compliance validation, Privacy, Security requirements
- **RED**: 
  - [ ] Test App Store compliance validation
  - [ ] Test notarization requirement checking
  - [ ] Test privacy permission handling
  - [ ] Test data privacy compliance (local only)
  - [ ] Test app transport security (no network)
  - [ ] Test Gatekeeper compatibility
- **GREEN**: 
  - [ ] Implement AppStoreComplianceChecker
  - [ ] Implement NotarizationValidator
  - [ ] Implement PrivacyPermissionManager
  - [ ] Implement DataPrivacyManager (local storage)
  - [ ] Implement security compliance checks
  - [ ] Implement GatekeeperCompatibilityManager
- **REFACTOR**: 
  - [ ] Automate compliance checking
  - [ ] Add compliance monitoring
  - [ ] Implement compliance reporting
  - [ ] Extract compliance patterns
  - [ ] Add compliance documentation

### Local Chat Requirements (Local Network Cross-Platform Application)

The Local Chat is a peer-to-peer messaging application using local network discovery and communication, demonstrating real-time messaging, multi-peer coordination, and platform integration for iOS and macOS.

Generated requirements provide test checklists for:

#### REQ-001: Peer Discovery with Network Capability
**Framework Components**: NetworkCapability, Client composition
- **RED**: 
  - [ ] Test capability availability checks
  - [ ] Test network discovery integration
  - [ ] Test timeout handling
- **GREEN**: 
  - [ ] Create discovery capability
  - [ ] Integrate with client
  - [ ] Add peer management
- **REFACTOR**: 
  - [ ] Add connection pooling
  - [ ] Improve reliability
  - [ ] Optimize discovery

#### REQ-002: Message Sending with Actor Concurrency
**Framework Components**: Actor isolation, Client-to-Client communication
- **RED**: 
  - [ ] Test concurrent send safety
  - [ ] Test message ordering preservation
  - [ ] Test delivery confirmation
- **GREEN**: 
  - [ ] Create message queue structure
  - [ ] Add delivery tracking
  - [ ] Implement actor isolation
- **REFACTOR**: 
  - [ ] Add message batching
  - [ ] Optimize network usage
  - [ ] Improve throughput

#### REQ-003: Real-time Message Display
**Framework Components**: AsyncStream, Context aggregation
- **RED**: 
  - [ ] Test immediate message appearance
  - [ ] Test scroll position maintenance
  - [ ] Test timestamp accuracy
- **GREEN**: 
  - [ ] Create streaming update system
  - [ ] Add UI synchronization
  - [ ] Implement real-time display
- **REFACTOR**: 
  - [ ] Add virtualization
  - [ ] Optimize rendering
  - [ ] Improve performance

#### REQ-004: Connection State Management
**Framework Components**: Capability lifecycle, State modeling
- **RED**: 
  - [ ] Test connection state tracking
  - [ ] Test automatic reconnection
  - [ ] Test offline mode functionality
- **GREEN**: 
  - [ ] Create state machine structure
  - [ ] Add retry logic
  - [ ] Implement state transitions
- **REFACTOR**: 
  - [ ] Add exponential backoff
  - [ ] Add quality metrics
  - [ ] Optimize reconnection

#### REQ-005: Multi-peer Coordination
**Framework Components**: Client composition, Orchestrator patterns
- **RED**: 
  - [ ] Test multi-peer management
  - [ ] Test state synchronization
  - [ ] Test conflict resolution
- **GREEN**: 
  - [ ] Create peer registry
  - [ ] Add sync protocol
  - [ ] Implement coordination
- **REFACTOR**: 
  - [ ] Add peer prioritization
  - [ ] Implement load balancing
  - [ ] Optimize coordination

#### REQ-006: Security with Encryption Capability
**Framework Components**: Capability abstraction, async operations
- **RED**: 
  - [ ] Test end-to-end encryption
  - [ ] Test key exchange protocol
  - [ ] Test message integrity
- **GREEN**: 
  - [ ] Create encryption capability
  - [ ] Integrate with messaging
  - [ ] Add security layers
- **REFACTOR**: 
  - [ ] Add forward secrecy
  - [ ] Implement audit logging
  - [ ] Enhance security

#### REQ-007: Background Processing
**Framework Components**: Task management, Capability background states
- **RED**: 
  - [ ] Test background message processing
  - [ ] Test state persistence
  - [ ] Test notification delivery
- **GREEN**: 
  - [ ] Create background task system
  - [ ] Add state persistence
  - [ ] Implement notifications
- **REFACTOR**: 
  - [ ] Optimize battery usage
  - [ ] Add sync strategies
  - [ ] Improve efficiency

#### REQ-008: Message History and Persistence
**Framework Components**: Local storage, Message caching, History management
- **RED**: 
  - [ ] Test message history storage per peer
  - [ ] Test message persistence across app launches
  - [ ] Test history search functionality
  - [ ] Test storage size limits
  - [ ] Test message cleanup policies
  - [ ] Test offline message queue
- **GREEN**: 
  - [ ] Implement MessageHistoryManager
  - [ ] Implement local storage adapter
  - [ ] Implement message search indexing
  - [ ] Implement storage quota management
  - [ ] Implement message retention policies
  - [ ] Implement offline message queue
- **REFACTOR**: 
  - [ ] Optimize storage performance
  - [ ] Add message compression
  - [ ] Implement smart caching
  - [ ] Add history export feature
  - [ ] Optimize search performance

#### REQ-009: Stress Testing and Limits
**Framework Components**: Performance boundaries, resource management
- **RED**: 
  - [ ] Test 1000+ message performance
  - [ ] Test 50+ peer support
  - [ ] Test memory boundaries
- **GREEN**: 
  - [ ] Add pagination support
  - [ ] Implement resource limits
  - [ ] Create boundary checks
- **REFACTOR**: 
  - [ ] Add adaptive quality
  - [ ] Implement graceful degradation
  - [ ] Optimize resource usage

#### REQ-010: iOS Application Entry Point
**Framework Components**: SwiftUI App protocol, Scene lifecycle, Network initialization
- **RED**: 
  - [ ] Test app launch with network service initialization
  - [ ] Test scene configuration for chat windows
  - [ ] Test app state transitions with active connections
  - [ ] Test deep link URL processing for peer invites
  - [ ] Test framework integration with network stack
  - [ ] Test background networking permissions
- **GREEN**: 
  - [ ] Implement LocalChatApp struct with @main
  - [ ] Implement WindowGroup for chat scenes
  - [ ] Implement scenePhase handlers for connection state
  - [ ] Implement URL scheme for peer discovery (localchat://)
  - [ ] Implement network service initialization
  - [ ] Configure background networking entitlements
- **REFACTOR**: 
  - [ ] Extract network configuration to module
  - [ ] Optimize connection startup time
  - [ ] Add connection state analytics
  - [ ] Implement reconnection mechanisms
  - [ ] Add network quality monitoring

#### REQ-011: macOS Application Entry Point
**Framework Components**: NSApplicationDelegate, Window management, Network services
- **RED**: 
  - [ ] Test app delegate with network initialization
  - [ ] Test multi-window chat support
  - [ ] Test menu bar with connection status
  - [ ] Test window restoration with peer state
  - [ ] Test app termination with active connections
  - [ ] Test network service integration
- **GREEN**: 
  - [ ] Implement AppDelegate with network lifecycle
  - [ ] Implement chat window controllers
  - [ ] Implement connection status menu
  - [ ] Implement multi-peer window management
  - [ ] Implement graceful connection shutdown
  - [ ] Configure local network permissions
- **REFACTOR**: 
  - [ ] Extract peer window management
  - [ ] Optimize multi-window performance
  - [ ] Add connection state persistence
  - [ ] Implement keyboard shortcuts for chat
  - [ ] Add network status indicators

#### REQ-012: Cross-Platform Chat Configuration
**Framework Components**: Platform detection, Network features, Local discovery
- **RED**: 
  - [ ] Test platform network capability detection
  - [ ] Test local network permission handling
  - [ ] Test peer discovery configuration
  - [ ] Test message protocol compatibility
  - [ ] Test UI adaptation for platforms
  - [ ] Test network interface selection
- **GREEN**: 
  - [ ] Implement ChatConfiguration protocol
  - [ ] Implement NetworkCapabilityDetector
  - [ ] Implement PeerDiscoveryService
  - [ ] Implement MessageProtocolHandler
  - [ ] Implement platform-specific UI variants
  - [ ] Implement NetworkInterfaceManager
- **REFACTOR**: 
  - [ ] Optimize discovery performance
  - [ ] Add network fallback strategies
  - [ ] Implement protocol versioning
  - [ ] Add platform capability reporting
  - [ ] Extract common network patterns

#### REQ-013: Platform-Specific Network Services
**Framework Components**: Service registry, Network permissions, Local protocols
- **RED**: 
  - [ ] Test Bonjour/mDNS service initialization
  - [ ] Test local network permission requests
  - [ ] Test peer advertisement and discovery
  - [ ] Test connection establishment protocols
  - [ ] Test service availability detection
  - [ ] Test network interface changes
- **GREEN**: 
  - [ ] Implement BonjourService for discovery
  - [ ] Implement NetworkPermissionManager
  - [ ] Implement PeerAdvertiser and Scanner
  - [ ] Implement ConnectionProtocolHandler
  - [ ] Implement ServiceAvailabilityMonitor
  - [ ] Implement NetworkChangeHandler
- **REFACTOR**: 
  - [ ] Abstract discovery protocols
  - [ ] Optimize service broadcast intervals
  - [ ] Add connection health monitoring
  - [ ] Implement service dependency injection
  - [ ] Add network diagnostics

#### REQ-014: iOS Scene Management for Chat
**Framework Components**: SceneDelegate, Multi-peer UI, Connection state
- **RED**: 
  - [ ] Test scene creation per chat conversation
  - [ ] Test scene state with active connections
  - [ ] Test background scene connection handling
  - [ ] Test scene restoration with peer data
  - [ ] Test multitasking with multiple chats
  - [ ] Test connection handoff between scenes
- **GREEN**: 
  - [ ] Implement ChatSceneDelegate
  - [ ] Implement per-peer scene configuration
  - [ ] Implement background connection manager
  - [ ] Implement scene state restoration
  - [ ] Implement multi-chat window support
  - [ ] Implement connection state coordinator
- **REFACTOR**: 
  - [ ] Extract scene connection patterns
  - [ ] Optimize scene memory usage
  - [ ] Add scene-specific analytics
  - [ ] Implement scene error recovery
  - [ ] Add connection debugging tools

#### REQ-015: macOS Window and Connection Management
**Framework Components**: WindowController, Peer windows, Connection UI
- **RED**: 
  - [ ] Test window per peer conversation
  - [ ] Test connection status in window chrome
  - [ ] Test window close with active connection
  - [ ] Test dock badge for unread messages
  - [ ] Test window restoration with peer state
  - [ ] Test multi-window coordination
- **GREEN**: 
  - [ ] Implement ChatWindowController
  - [ ] Implement connection status indicators
  - [ ] Implement connection cleanup on close
  - [ ] Implement UnreadMessageManager
  - [ ] Implement window state persistence
  - [ ] Implement WindowCoordinator
- **REFACTOR**: 
  - [ ] Extract window connection patterns
  - [ ] Optimize multi-window updates
  - [ ] Add window-specific metrics
  - [ ] Implement advanced window features
  - [ ] Add peer management UI

#### REQ-016: Platform-Specific Chat Resources
**Framework Components**: Message UI assets, Sound alerts, Notification styles
- **RED**: 
  - [ ] Test platform message bubble styles
  - [ ] Test notification sound loading
  - [ ] Test emoji and attachment rendering
  - [ ] Test platform-specific animations
  - [ ] Test localized message formats
  - [ ] Test adaptive message layouts
- **GREEN**: 
  - [ ] Implement MessageBubbleRenderer
  - [ ] Implement NotificationSoundManager
  - [ ] Implement AttachmentRenderer
  - [ ] Implement MessageAnimationManager
  - [ ] Implement MessageLocalizationManager
  - [ ] Implement AdaptiveMessageLayout
- **REFACTOR**: 
  - [ ] Optimize message rendering performance
  - [ ] Add custom notification sounds
  - [ ] Implement message theming
  - [ ] Add rendering analytics
  - [ ] Extract UI components

#### REQ-017: iOS Background Networking
**Framework Components**: Background sessions, Message sync, Connection maintenance
- **RED**: 
  - [ ] Test background message reception
  - [ ] Test connection keepalive in background
  - [ ] Test notification delivery for messages
  - [ ] Test background peer discovery
  - [ ] Test battery impact of background networking
  - [ ] Test background task completion
- **GREEN**: 
  - [ ] Implement BackgroundNetworkManager
  - [ ] Implement connection keepalive protocol
  - [ ] Implement message notification handler
  - [ ] Implement background discovery service
  - [ ] Implement power-efficient protocols
  - [ ] Implement background task coordinator
- **REFACTOR**: 
  - [ ] Optimize background battery usage
  - [ ] Add intelligent scheduling
  - [ ] Implement message coalescing
  - [ ] Add background analytics
  - [ ] Extract background patterns

#### REQ-018: macOS Network File Sharing
**Framework Components**: File transfer, Drag-and-drop, Protocol handlers
- **RED**: 
  - [ ] Test file drag to chat window
  - [ ] Test file transfer protocol
  - [ ] Test transfer progress indication
  - [ ] Test file type restrictions
  - [ ] Test concurrent file transfers
  - [ ] Test transfer cancellation
- **GREEN**: 
  - [ ] Implement FileDragHandler
  - [ ] Implement FileTransferProtocol
  - [ ] Implement TransferProgressManager
  - [ ] Implement FileTypeValidator
  - [ ] Implement ConcurrentTransferQueue
  - [ ] Implement TransferCancellationHandler
- **REFACTOR**: 
  - [ ] Extract file transfer patterns
  - [ ] Optimize transfer performance
  - [ ] Add transfer analytics
  - [ ] Implement resume capability
  - [ ] Add security validation

#### REQ-019: Cross-Platform Message Input
**Framework Components**: Text input, Emoji picker, Attachment handling
- **RED**: 
  - [ ] Test iOS keyboard with message field
  - [ ] Test macOS text input with shortcuts
  - [ ] Test emoji picker integration
  - [ ] Test attachment button functionality
  - [ ] Test message formatting options
  - [ ] Test accessibility input methods
- **GREEN**: 
  - [ ] Implement MessageInputField
  - [ ] Implement platform keyboard handlers
  - [ ] Implement EmojiPickerManager
  - [ ] Implement AttachmentManager
  - [ ] Implement MessageFormatter
  - [ ] Implement AccessibilityInputHandler
- **REFACTOR**: 
  - [ ] Extract input components
  - [ ] Optimize keyboard responsiveness
  - [ ] Add input customization
  - [ ] Implement input analytics
  - [ ] Add gesture shortcuts

#### REQ-020: Platform-Specific Network Configuration
**Framework Components**: Network settings, Protocol options, Security config
- **RED**: 
  - [ ] Test network interface selection
  - [ ] Test port configuration options
  - [ ] Test encryption settings
  - [ ] Test discovery timeout settings
  - [ ] Test connection limit configuration
  - [ ] Test protocol version selection
- **GREEN**: 
  - [ ] Implement NetworkConfigurationManager
  - [ ] Implement PortConfigurationHandler
  - [ ] Implement EncryptionSettingsManager
  - [ ] Implement DiscoveryTimeoutManager
  - [ ] Implement ConnectionLimitEnforcer
  - [ ] Implement ProtocolVersionManager
- **REFACTOR**: 
  - [ ] Optimize configuration storage
  - [ ] Add configuration validation
  - [ ] Implement configuration migration
  - [ ] Extract configuration patterns
  - [ ] Add configuration UI

#### REQ-021: Local Network Compliance
**Framework Components**: Privacy compliance, Local network permissions, Security
- **RED**: 
  - [ ] Test local network permission prompts
  - [ ] Test privacy disclosure compliance
  - [ ] Test encryption requirement validation
  - [ ] Test data retention policies
  - [ ] Test cross-platform protocol security
  - [ ] Test privacy settings persistence
- **GREEN**: 
  - [ ] Implement LocalNetworkPermissionManager
  - [ ] Implement PrivacyDisclosureHandler
  - [ ] Implement EncryptionValidator
  - [ ] Implement DataRetentionManager
  - [ ] Implement SecurityProtocolValidator
  - [ ] Implement PrivacySettingsManager
- **REFACTOR**: 
  - [ ] Automate compliance validation
  - [ ] Add privacy monitoring
  - [ ] Implement security reporting
  - [ ] Extract compliance patterns
  - [ ] Add compliance documentation

## Framework Testing Matrix

### Component Coverage by Application

| Framework Component | Task Manager | Local Chat |
|-------------------|--------------|------------|
| Data Models | REQ-001 | REQ-001, 002, 008 |
| Network Services | N/A | REQ-001, 004, 013 |
| SwiftUI Views | REQ-003, 004, 005 | REQ-003, 016, 019 |
| State Management | REQ-007, 008, 009 | REQ-003, 004, 005, 008 |
| Error Handling | REQ-006, 010 | REQ-004, 006 |
| iOS Entry Point | REQ-011 | REQ-010 |
| macOS Entry Point | REQ-012 | REQ-011 |
| Cross-Platform Config | REQ-013 | REQ-012 |
| Platform Services | REQ-014, 018, 019 | REQ-013, 017, 018 |
| Resource Management | REQ-017 | REQ-016 |
| Input Handling | REQ-020 | REQ-019 |
| Build Configuration | REQ-021 | REQ-020 |
| Store Compliance | REQ-022 | REQ-021 |

### Pattern Coverage

| Pattern | Task Manager | Local Chat |
|---------|--------------|------------|
| iOS Application Entry | REQ-011 | REQ-010 |
| macOS Application Entry | REQ-012 | REQ-011 |
| Cross-Platform Design | REQ-013, 017, 020 | REQ-012, 016, 019 |
| Local Storage | REQ-002, 004, 005, 006 | REQ-008 |
| Network Communication | N/A | REQ-001, 002, 004 |
| Real-time Messaging | N/A | REQ-003, 005, 017 |
| Multi-Window/Scene | REQ-015, 016 | REQ-014, 015 |
| Background Processing | REQ-018 | REQ-017 |
| Platform Services | REQ-014, 019 | REQ-013, 018 |
| Performance Optimization | REQ-007 | REQ-009 |
| Compliance & Security | REQ-021, 022 | REQ-020, 021 |

## TDD Enforcement for Framework

Each requirement follows strict structure ensuring framework testing:

### RED Phase - Framework-Focused Tests
- [ ] Test framework component behavior
- [ ] Verify architectural constraints  
- [ ] Check concurrency safety
- [ ] Validate performance requirements

### GREEN Phase - Minimal Framework Integration
- [ ] Use only required framework APIs
- [ ] Follow framework patterns exactly
- [ ] Implement actor isolation correctly
- [ ] Meet timing constraints

### REFACTOR Phase - Framework Best Practices
- [ ] Apply framework optimization patterns
- [ ] Improve error handling per framework
- [ ] Enhance concurrency patterns
- [ ] Maintain architectural boundaries

## Technical Details

### Paths

```
ApplicationWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/ApplicationWorkspace
FrameworkWorkspace: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/FrameworkWorkspace
Templates: /Users/tojkuv/Documents/GitHub/axiom-apple/workspace-meta-workspace/workspaces/templates/
```

### Generated Structure

```
ApplicationWorkspace/
└── CYCLE-XXX-[TYPE]-[TITLE]/
    └── REQUIREMENTS-XXX-[TYPE]-[TITLE].md
        ├── Framework version and components tested
        ├── TDD cycles for each requirement
        ├── Framework API usage mapping
        └── Performance and concurrency tests
```

## Integration Points

### Inputs
- APPLICATION_REQUIREMENTS_TEMPLATE.md (for generate)
- Existing REQUIREMENTS-XXX.md (for update-requirements)
- Framework DOCUMENTATION-XXX.md (for update-requirements only)

### Outputs
- TDD requirements testing all framework aspects
- Ready for APPLICATION_DEVELOP protocol

## Workflow Example

```bash
# 1. Generate initial requirements for offline task manager
@APPLICATION_PLAN generate task-manager

# 2. Update with framework documentation for comprehensive testing
@APPLICATION_PLAN update-requirements 001 ../../FrameworkWorkspace/CYCLE-001/DOCUMENTATION-001.md

# 3. Review enhanced requirements (22 requirements with platform integration)
cat ApplicationWorkspace/CYCLE-001-TASK-MANAGER-MVP/REQUIREMENTS-001-TASK-MANAGER-MVP.md

# 4. Generate complementary local network chat app
@APPLICATION_PLAN generate local-chat

# 5. Update for framework coverage with network platform features
@APPLICATION_PLAN update-requirements 002 ../../FrameworkWorkspace/CYCLE-001/DOCUMENTATION-001.md

# 6. Review enhanced requirements (21 requirements with network platform integration)
cat ApplicationWorkspace/CYCLE-002-LOCAL-CHAT-MVP/REQUIREMENTS-002-LOCAL-CHAT-MVP.md
```

## Error Handling

### Missing Requirements File
```
Error: REQUIREMENTS-001 not found
Required: Generate requirements first
Recovery: Run @APPLICATION_PLAN generate task-manager
```

### Invalid Documentation Path
```
Error: Framework documentation not found at path
Provided: DOCUMENTATION-001.md
Recovery: Provide full path to framework documentation
```

### Documentation Parse Error
```
Error: Cannot parse framework documentation
Issue: Invalid format or structure
Recovery: Ensure documentation follows standard format
```

## Best Practices

1. **Test every framework component** - Ensure both apps together cover all APIs

2. **Follow architectural constraints** - Requirements should validate framework rules

3. **Test concurrency thoroughly** - Actor isolation and AsyncStream patterns

4. **Validate performance** - Each requirement should check timing constraints

5. **Cover error paths** - Test capability failures and recovery patterns

6. **Include comprehensive platform integration** - Every application must include iOS and macOS entry points plus platform-specific services (Task Manager: REQ-011-022, Local Chat: REQ-010-021)

## Platform Integration Requirements

### Task Manager - Core Features (REQ-001 to REQ-010)
- Data models with validation and local persistence
- Offline CRUD operations with error handling
- SwiftUI views with cross-platform compatibility
- Local state management and navigation
- Comprehensive error handling and recovery (offline)

### Task Manager - Platform Integration (REQ-011 to REQ-022)
- **iOS** (REQ-011, 014, 015, 018): SwiftUI App protocol, scene lifecycle, background tasks, local notifications
- **macOS** (REQ-012, 016, 019): NSApplicationDelegate, window management, file associations (.task files)
- **Cross-Platform** (REQ-013, 017, 020-022): Unified configuration, resource management, input handling, compliance

### Local Chat - Core Features (REQ-001 to REQ-009)
- Peer discovery and network capability management
- Real-time message sending and display
- Connection state management and multi-peer coordination
- Local network security with encryption
- Background processing for active connections
- Message history and local persistence
- Performance optimization for large message volumes

### Local Chat - Platform Integration (REQ-010 to REQ-021)
- **iOS** (REQ-010, 013, 014, 017): SwiftUI App protocol, network services, scene management, background networking
- **macOS** (REQ-011, 015, 018): NSApplicationDelegate, multi-window chat, network file sharing
- **Cross-Platform** (REQ-012, 016, 019-021): Network configuration, chat resources, message input, compliance

### Required Platform Tests
- Platform detection and feature flag evaluation
- Platform-specific service initialization
- Cross-platform UI consistency validation
- Build and deployment compliance verification
