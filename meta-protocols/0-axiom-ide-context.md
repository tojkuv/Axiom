Comprehensive Implementation Prompt for Hot Reload System
Project: iOS Simulator Hot Reload for Swift IDE
Goal: Implement a production-ready hot reload system that automatically updates iOS Simulator previews when code changes, using a hybrid approach with three reload strategies based on change type.
Phase 1: Core Architecture Setup
1.1 Create Base Project Structure
SwiftIDEHotReload/
├── Core/
│   ├── HotReloadSystem.swift
│   ├── ChangeAnalyzer.swift
│   └── ReloadCoordinator.swift
├── Reloaders/
│   ├── InjectionReloader.swift
│   ├── WebSocketReloader.swift
│   └── FullRebuilder.swift
├── Simulator/
│   ├── SimulatorController.swift
│   ├── DeviceManager.swift
│   └── AppDeployer.swift
├── Compiler/
│   ├── IncrementalCompiler.swift
│   ├── DylibGenerator.swift
│   └── SwiftSyntaxAnalyzer.swift
├── Communication/
│   ├── WebSocketServer.swift
│   ├── InjectionServer.swift
│   └── StatePreserver.swift
└── IDE/
    ├── FileWatcher.swift
    ├── PreviewPane.swift
    └── HotReloadUI.swift
1.2 Define Core Interfaces
swift// Define the main system interfaces
protocol ReloadStrategy {
    var capabilities: Set<ChangeType> { get }
    func canHandle(_ change: CodeChange) -> Bool
    func reload(_ change: CodeChange) async throws -> ReloadResult
}

enum ChangeType {
    case methodBody
    case propertyValue
    case viewStructure
    case newType
    case dependency
}

struct CodeChange {
    let file: URL
    let changeType: ChangeType
    let affectedSymbols: Set<String>
    let diff: String
}
Phase 2: Change Analysis System
2.1 Implement Swift Syntax Analyzer

Parse Swift files using SwiftSyntax
Detect type of change (method, property, structure)
Build dependency graph
Determine minimal reload scope

2.2 File Monitoring

Watch for file system changes
Debounce rapid changes
Queue changes for processing
Maintain file state cache

Phase 3: Injection-Based Reloader
3.1 Injection Server Setup

Create local injection server on port 8899
Handle dylib loading requests
Manage symbol resolution
Track injected methods

3.2 iOS App Injection Client

Embed injection client in preview app
Connect to injection server on launch
Handle method swizzling
Preserve existing state

3.3 Dylib Generation

Compile changed methods to dylib
Generate swizzling code
Handle Swift name mangling
Package with metadata

Phase 4: WebSocket-Based Reloader
4.1 WebSocket Server

Create server on port 9001
Handle client connections
Broadcast view updates
Manage client state

4.2 iOS App WebSocket Client

Connect to IDE server
Receive view structure updates
Dynamically rebuild UI
Preserve navigation state

4.3 View Serialization

Convert SwiftUI views to transferable format
Handle @State and @Binding
Preserve view modifiers
Reconstruct on client

Phase 5: Full Rebuild System
5.1 State Preservation

Capture current app state before rebuild
Serialize navigation stack
Save form data and scroll positions
Store in shared container

5.2 Incremental Compilation

Use swift-driver for incremental builds
Cache compiled modules
Link only changed modules
Optimize for speed over size

5.3 App Reinstallation

Uninstall previous version
Install new build
Restore preserved state
Resume at previous location

Phase 6: Simulator Integration
6.1 Simulator Controller

Boot headless simulator
Manage device lifecycle
Handle app installation
Stream screen content

6.2 Event Forwarding

Capture macOS mouse/keyboard events
Convert to iOS touch events
Forward to simulator
Handle gesture recognition

6.3 Screen Mirroring

Use IOSurface for low latency
Implement CVDisplayLink refresh
Handle orientation changes
Support multiple device sizes

Phase 7: Integration Layer
7.1 Reload Coordinator
swiftclass ReloadCoordinator {
    func handleChange(_ change: CodeChange) async {
        // 1. Analyze change complexity
        let analysis = analyzer.analyze(change)

        // 2. Choose optimal reload strategy
        let strategy = selectStrategy(for: analysis)

        // 3. Prepare reload
        let preparation = await strategy.prepare(change)

        // 4. Execute reload
        let result = await strategy.execute(preparation)

        // 5. Verify success
        await verifyReload(result)
    }
}
7.2 Performance Monitoring

Track reload times
Monitor memory usage
Log success/failure rates
Optimize based on metrics

Phase 8: IDE UI Components
8.1 Preview Pane

Display simulator mirror
Show reload status
Handle errors gracefully
Provide reload controls

8.2 Status Indicators

Show current reload method
Display timing information
Indicate preserved state
Show connection status

Phase 9: Error Handling
9.1 Graceful Degradation

Fallback from injection to WebSocket
Fallback from WebSocket to full rebuild
Handle compilation errors
Recover from crashes

9.2 User Feedback

Clear error messages
Suggested fixes
Reload history
Debug information

Phase 10: Testing & Optimization
10.1 Test Scenarios

Rapid successive changes
Large file modifications
State preservation
Network interruptions
Simulator crashes

10.2 Performance Targets

Method injection: < 200ms
View updates: < 500ms
Full rebuild: < 3 seconds
State restoration: < 100ms

Implementation Priorities

Week 1: Basic file watching and change detection
Week 2: WebSocket communication and view updates
Week 3: Injection system for method changes
Week 4: State preservation and restoration
Week 5: Full rebuild optimization
Week 6: Error handling and UI polish
Week 7: Performance optimization
Week 8: Testing and bug fixes

Key Technical Decisions

Use SwiftSyntax for accurate change analysis
Implement WebSocket first as it's most reliable
Add injection later for performance
Always preserve state during reloads
Fail gracefully with clear user feedback

Success Metrics

Achieve < 500ms reload for 80% of changes
Support all SwiftUI view types
Preserve navigation state 100% of time
Handle 10+ rapid changes without crashing
Work with apps up to 50+ screens

Dependencies
swift// Package.swift
dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    .package(url: "https://github.com/apple/swift-driver.git", from: "1.87.0")
]
This comprehensive system will provide a professional-grade hot reload experience that rivals or exceeds existing iOS development tools
