# Macro System Specification

Technical specification for the Axiom framework's code generation macro system for reduced boilerplate and enhanced developer experience.

## Overview

The Axiom Macro System provides compile-time code generation to reduce boilerplate code, enforce architectural constraints, and enhance developer productivity. The system includes core macros for client, context, and view generation, as well as advanced macros for capabilities, observability, and intelligence integration.

## System Architecture

### Core Components

1. **Macro Infrastructure**: Foundation for macro composition and coordination
2. **Core Macros**: @Client, @Context, @View for primary component generation
3. **Advanced Macros**: @Capabilities, @ObservableState, @Intelligence for enhanced features
4. **Macro Composition**: Framework for combining multiple macros safely
5. **Enhanced Diagnostics**: Context-aware validation and error reporting

## Macro Infrastructure

### Composable Macro Protocol

```swift
protocol ComposableMacro: Macro {
    static var capabilities: Set<MacroCapability> { get }
    static var priority: MacroPriority { get }
    static var dependencies: [MacroIdentifier] { get }
    static var conflicts: [MacroIdentifier] { get }
    
    static func canCompose(with other: any ComposableMacro.Type) -> Bool
    static func compose(with context: MacroSharedContext) throws -> [DeclSyntax]
}

enum MacroCapability {
    case generateActors
    case generateProtocolConformance
    case generateInitializers
    case generateStateManagement
    case generateBindings
    case generateObservability
    case generateCapabilityRegistration
    case generateIntelligenceIntegration
    case generatePerformanceMonitoring
    case generateErrorHandling
}

enum MacroPriority {
    case foundation  // Must execute first
    case core        // Primary functionality
    case enhancement // Additional features
    case integration // Cross-cutting concerns
}
```

### Macro Coordinator

```swift
class MacroCoordinator {
    static func expandMacros(
        _ macros: [any ComposableMacro.Type],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate composition
        try validateMacroComposition(macros)
        
        // Sort by priority and dependencies
        let sortedMacros = try resolveDependencies(macros)
        
        // Create shared context
        let sharedContext = MacroSharedContext()
        
        // Expand macros in order
        var allDeclarations: [DeclSyntax] = []
        
        for macro in sortedMacros {
            let declarations = try macro.compose(with: sharedContext)
            allDeclarations.append(contentsOf: declarations)
        }
        
        return allDeclarations
    }
    
    private static func validateMacroComposition(_ macros: [any ComposableMacro.Type]) throws {
        // Check for conflicts
        for i in 0..<macros.count {
            for j in (i+1)..<macros.count {
                let macro1 = macros[i]
                let macro2 = macros[j]
                
                if macro1.conflicts.contains(MacroIdentifier(macro2)) {
                    throw MacroCompositionError.conflictingMacros(macro1, macro2)
                }
            }
        }
        
        // Validate dependencies
        try validateDependencies(macros)
    }
}

class MacroSharedContext {
    private var sharedState: [String: Any] = [:]
    private var generatedNames: Set<String> = []
    
    func setValue<T>(_ value: T, for key: String) {
        sharedState[key] = value
    }
    
    func getValue<T>(_ type: T.Type, for key: String) -> T? {
        return sharedState[key] as? T
    }
    
    func reserveName(_ name: String) -> String {
        if generatedNames.contains(name) {
            // Generate unique name
            var counter = 1
            var uniqueName = "\(name)\(counter)"
            while generatedNames.contains(uniqueName) {
                counter += 1
                uniqueName = "\(name)\(counter)"
            }
            generatedNames.insert(uniqueName)
            return uniqueName
        } else {
            generatedNames.insert(name)
            return name
        }
    }
}
```

## Core Macros

### @Client Macro

Generates actor-based client implementation with state management.

```swift
@attached(member, names: named(init), named(stateSnapshot), named(capabilities), named(updateState))
@attached(conformance, names: AxiomClient)
public macro Client() = #externalMacro(module: "AxiomMacros", type: "ClientMacro")

// Usage
@Client
struct UserState {
    var name: String = ""
    var email: String = ""
    var lastLogin: Date?
}

// Generated code:
actor UserClient: AxiomClient {
    typealias State = UserState
    
    private(set) var stateSnapshot = UserState()
    let capabilities: CapabilityManager
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
    }
    
    func updateState(_ update: @Sendable (inout State) -> Void) async {
        update(&stateSnapshot)
        await notifyStateChange()
    }
    
    private func notifyStateChange() async {
        // Implementation for state change notification
    }
}
```

### @Context Macro

Generates context orchestration with client coordination and SwiftUI integration.

```swift
@attached(member, names: arbitrary)
@attached(conformance, names: AxiomContext, ObservableObject)
public macro Context(client: Any.Type) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")

// Usage
@Context(client: UserClient)
class UserContext {
    // Additional custom methods can be added
}

// Generated code:
@MainActor
class UserContext: AxiomContext, ObservableObject {
    let client: UserClient
    let intelligence: AxiomIntelligence
    let performanceMonitor: PerformanceMonitor
    
    init(client: UserClient, intelligence: AxiomIntelligence, performanceMonitor: PerformanceMonitor) {
        self.client = client
        self.intelligence = intelligence
        self.performanceMonitor = performanceMonitor
        
        // Register for component analysis
        intelligence.registerComponent(self)
        intelligence.startMonitoring(self)
        
        // Start observing client state changes
        Task {
            await observeStateChanges()
        }
    }
    
    func bind<T>(_ keyPath: KeyPath<UserClient.State, T>) -> Binding<T> {
        return Binding(
            get: { [weak self] in
                guard let self = self else { return T.self as! T }
                return self.client.stateSnapshot[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                Task {
                    await self.client.updateState { state in
                        state[keyPath: keyPath as! WritableKeyPath<UserClient.State, T>] = newValue
                    }
                }
            }
        )
    }
    
    func observeStateChanges() async {
        // Implementation for state change observation
    }
}
```

### @View Macro

Generates SwiftUI view with 1:1 context relationship and reactive binding.

```swift
@attached(member, names: arbitrary)
@attached(conformance, names: AxiomView)
public macro View(context: Any.Type) = #externalMacro(module: "AxiomMacros", type: "ViewMacro")

// Usage
@View(context: UserContext)
struct UserView {
    var body: some View {
        VStack {
            Text(context.bind(\.name).wrappedValue)
            // Custom view implementation
        }
    }
}

// Generated code:
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    init(context: UserContext) {
        self.context = context
    }
    
    func handleStateChange() {
        // Handle reactive state updates
        objectWillChange.send()
    }
    
    func validateArchitecturalConstraints() -> Bool {
        // Validate 1:1 view-context relationship
        return true
    }
    
    // Custom body implementation provided by user
}
```

## Advanced Macros

### @Capabilities Macro

Generates capability registration and compile-time optimization.

```swift
@attached(member, names: arbitrary)
public macro Capabilities(_ capabilities: [CapabilityType]) = #externalMacro(module: "AxiomMacros", type: "CapabilitiesMacro")

// Usage
@Capabilities([.network, .storage, .analytics])
actor UserClient: AxiomClient {
    // Implementation
}

// Generated code:
extension UserClient {
    static let compiletimeCapabilities: Set<String> = [
        "network",
        "storage", 
        "analytics"
    ]
    
    func registerCapabilities() {
        capabilities.register(NetworkCapability.self)
        capabilities.register(StorageCapability.self)
        capabilities.register(AnalyticsCapability.self)
    }
    
    func hasCapability(_ identifier: String) -> Bool {
        return Self.compiletimeCapabilities.contains(identifier)
    }
    
    func validateCapability<C: Capability>(_ capability: C.Type) async -> Bool {
        let identifier = C.identifier
        if hasCapability(identifier) {
            return await capabilities.validateWithOptimization(capability)
        } else {
            return await capabilities.validate(capability)
        }
    }
}
```

### @ObservableState Macro

Generates observable state management with change notification.

```swift
@attached(member, names: arbitrary)
public macro ObservableState() = #externalMacro(module: "AxiomMacros", type: "ObservableStateMacro")

// Usage
@ObservableState
struct UserState {
    var name: String = ""
    var email: String = ""
    private var internalData: String = ""  // Skipped (private)
    let immutableData: String = ""         // Skipped (let)
}

// Generated code:
extension UserState {
    @Published private var _stateVersion = 0
    
    mutating func setName(_ newValue: String) {
        guard name != newValue else { return }
        name = newValue
        notifyStateChange()
    }
    
    mutating func setEmail(_ newValue: String) {
        guard email != newValue else { return }
        email = newValue
        notifyStateChange()
    }
    
    private mutating func notifyStateChange() {
        _stateVersion += 1
    }
}
```

### @Intelligence Macro

Generates intelligence integration with feature configuration.

```swift
@attached(member, names: arbitrary)
public macro Intelligence(features: [String]) = #externalMacro(module: "AxiomMacros", type: "IntelligenceMacro")

// Usage
@Intelligence(features: ["component_analysis", "pattern_detection", "performance_monitoring"])
class ApplicationContext: AxiomContext {
    // Implementation
}

// Generated code:
extension ApplicationContext {
    private let intelligenceFeatures: Set<String> = [
        "component_analysis",
        "pattern_detection", 
        "performance_monitoring"
    ]
    
    func enableIntelligenceFeatures() {
        for feature in intelligenceFeatures {
            intelligence.enableFeature(feature)
        }
    }
    
    func queryComponentAnalysis(_ query: String) async -> ComponentAnalysisResult {
        guard intelligenceFeatures.contains("component_analysis") else {
            throw IntelligenceError.featureNotEnabled("component_analysis")
        }
        return await intelligence.queryComponentAnalysis(query)
    }
    
    func queryPatternDetection(_ query: String) async -> PatternDetectionResult {
        guard intelligenceFeatures.contains("pattern_detection") else {
            throw IntelligenceError.featureNotEnabled("pattern_detection")
        }
        return await intelligence.queryPatternDetection(query)
    }
    
    func queryPerformanceMonitoring(_ query: String) async -> PerformanceMonitoringResult {
        guard intelligenceFeatures.contains("performance_monitoring") else {
            throw IntelligenceError.featureNotEnabled("performance_monitoring")
        }
        return await intelligence.queryPerformanceMonitoring(query)
    }
    
    func getIntelligenceStatus() -> IntelligenceStatus {
        return IntelligenceStatus(
            enabledFeatures: intelligenceFeatures,
            isComponentAnalysisEnabled: intelligenceFeatures.contains("component_analysis"),
            isPatternDetectionEnabled: intelligenceFeatures.contains("pattern_detection"),
            isPerformanceMonitoringEnabled: intelligenceFeatures.contains("performance_monitoring")
        )
    }
}
```

## Macro Composition Framework

### Safe Macro Combination

```swift
// Multiple macros can be composed safely
@Client
@Capabilities([.network, .storage])
@ObservableState
struct UserState {
    var name: String = ""
    var email: String = ""
}

// Generated combined code:
actor UserClient: AxiomClient {
    typealias State = UserState
    
    // From @Client macro
    private(set) var stateSnapshot = UserState()
    let capabilities: CapabilityManager
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
        registerCapabilities()  // From @Capabilities macro
    }
    
    // From @Client macro
    func updateState(_ update: @Sendable (inout State) -> Void) async {
        update(&stateSnapshot)
        await notifyStateChange()
    }
    
    // From @Capabilities macro
    static let compiletimeCapabilities: Set<String> = ["network", "storage"]
    
    func registerCapabilities() {
        capabilities.register(NetworkCapability.self)
        capabilities.register(StorageCapability.self)
    }
}

// UserState gets @ObservableState extensions
extension UserState {
    @Published private var _stateVersion = 0
    
    mutating func setName(_ newValue: String) {
        guard name != newValue else { return }
        name = newValue
        notifyStateChange()
    }
    
    mutating func setEmail(_ newValue: String) {
        guard email != newValue else { return }
        email = newValue
        notifyStateChange()
    }
    
    private mutating func notifyStateChange() {
        _stateVersion += 1
    }
}
```

### Dependency Resolution

```swift
// Macros with dependencies are resolved in correct order
@Context(client: UserClient)     // Depends on UserClient existing
@Intelligence(features: ["monitoring"])  // Can be combined safely
class UserContext {
    // Custom implementation
}

// MacroCoordinator ensures proper expansion order:
// 1. @Client (foundation priority)
// 2. @Context (core priority) 
// 3. @Intelligence (integration priority)
```

## Enhanced Diagnostics

### Context-aware Validation

```swift
class EnhancedDiagnosticSystem {
    func validateMacroUsage(
        _ syntax: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> [DiagnosticMessage] {
        var diagnostics: [DiagnosticMessage] = []
        
        // Validate declaration type
        let declarationType = context.declarationType
        if !isSupportedDeclaration(declarationType, for: syntax) {
            diagnostics.append(
                DiagnosticMessage(
                    severity: .error,
                    message: "Macro \(syntax.attributeName) cannot be applied to \(declarationType)",
                    suggestions: getSuggestedAlternatives(for: declarationType)
                )
            )
        }
        
        // Validate architectural constraints
        let constraintViolations = validateArchitecturalConstraints(syntax, context)
        diagnostics.append(contentsOf: constraintViolations)
        
        // Validate capability requirements
        let capabilityIssues = validateCapabilityRequirements(syntax, context)
        diagnostics.append(contentsOf: capabilityIssues)
        
        return diagnostics
    }
    
    private func validateArchitecturalConstraints(
        _ syntax: AttributeSyntax,
        _ context: some MacroExpansionContext
    ) -> [DiagnosticMessage] {
        var diagnostics: [DiagnosticMessage] = []
        
        // Example: Validate @View macro has 1:1 context relationship
        if syntax.attributeName.text == "View" {
            if let contextType = extractContextType(from: syntax) {
                if isContextShared(contextType, in: context) {
                    diagnostics.append(
                        DiagnosticMessage(
                            severity: .warning,
                            message: "Context \(contextType) is shared between multiple views, violating 1:1 constraint",
                            suggestions: ["Create separate context for each view", "Use context composition instead"]
                        )
                    )
                }
            }
        }
        
        return diagnostics
    }
}

struct DiagnosticMessage {
    let severity: DiagnosticSeverity
    let message: String
    let suggestions: [String]
    let fixItActions: [FixItAction]
    
    init(severity: DiagnosticSeverity, message: String, suggestions: [String] = [], fixItActions: [FixItAction] = []) {
        self.severity = severity
        self.message = message
        self.suggestions = suggestions
        self.fixItActions = fixItActions
    }
}

enum DiagnosticSeverity {
    case error
    case warning
    case note
}
```

## Performance Considerations

### Compilation Performance

- **Macro Expansion Time**: <10ms for complex compositions
- **Generated Code Size**: Minimal overhead with targeted generation
- **Build Impact**: <5% increase in compilation time
- **Incremental Builds**: Only affected files are re-expanded

### Runtime Performance

- **Generated Code Efficiency**: Equivalent to hand-written code
- **Memory Overhead**: No runtime overhead for macro-generated code
- **Performance Monitoring**: Integrated monitoring for generated components

## Error Handling

### Macro Expansion Errors

```swift
enum MacroExpansionError: Error {
    case unsupportedDeclaration(String)
    case missingRequiredParameter(String)
    case conflictingMacros([String])
    case dependencyNotMet(String, required: String)
    case architecturalConstraintViolation(String)
    
    var diagnosticMessage: String {
        switch self {
        case .unsupportedDeclaration(let type):
            return "Macro cannot be applied to \(type) declaration"
        case .missingRequiredParameter(let param):
            return "Required parameter '\(param)' is missing"
        case .conflictingMacros(let macros):
            return "Conflicting macros detected: \(macros.joined(separator: ", "))"
        case .dependencyNotMet(let macro, let required):
            return "Macro '\(macro)' requires '\(required)' to be present"
        case .architecturalConstraintViolation(let constraint):
            return "Generated code violates architectural constraint: \(constraint)"
        }
    }
}
```

### Graceful Degradation

```swift
// If macro expansion fails, provide helpful fallback
extension ClientMacro {
    static func handleExpansionFailure(
        _ error: MacroExpansionError,
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        // Generate minimal implementation with clear error indication
        return [
            """
            // MACRO EXPANSION FAILED: \(error.diagnosticMessage)
            // Please implement AxiomClient manually or fix the macro usage
            
            // Minimal implementation template:
            actor GeneratedClient: AxiomClient {
                typealias State = YourStateType
                private(set) var stateSnapshot = YourStateType()
                let capabilities: CapabilityManager
                
                init(capabilities: CapabilityManager) {
                    self.capabilities = capabilities
                }
                
                func updateState(_ update: @Sendable (inout State) -> Void) async {
                    update(&stateSnapshot)
                }
            }
            """
        ]
    }
}
```

## Testing Support

### Macro Testing Framework

```swift
class MacroTestCase: XCTestCase {
    func testClientMacroExpansion() throws {
        let input = """
            @Client
            struct UserState {
                var name: String = ""
            }
            """
        
        let expectedOutput = """
            actor UserClient: AxiomClient {
                typealias State = UserState
                private(set) var stateSnapshot = UserState()
                let capabilities: CapabilityManager
                
                init(capabilities: CapabilityManager) {
                    self.capabilities = capabilities
                }
                
                func updateState(_ update: @Sendable (inout State) -> Void) async {
                    update(&stateSnapshot)
                    await notifyStateChange()
                }
                
                private func notifyStateChange() async {
                    // Implementation
                }
            }
            """
        
        assertMacroExpansion(input, produces: expectedOutput, using: ClientMacro.self)
    }
    
    func testMacroComposition() throws {
        let input = """
            @Client
            @Capabilities([.network])
            struct UserState {
                var name: String = ""
            }
            """
        
        // Test that both macros expand correctly together
        let result = try expandMacros(input, using: [ClientMacro.self, CapabilitiesMacro.self])
        
        XCTAssertTrue(result.contains("actor UserClient: AxiomClient"))
        XCTAssertTrue(result.contains("static let compiletimeCapabilities"))
        XCTAssertTrue(result.contains("NetworkCapability"))
    }
}
```

## Best Practices

### Macro Design Guidelines

1. **Single Responsibility**: Each macro should have a clear, focused purpose
2. **Composability**: Design macros to work well with others
3. **Error Handling**: Provide clear diagnostic messages
4. **Performance**: Generate efficient code with minimal overhead
5. **Testing**: Comprehensive test coverage for all expansion scenarios

### Usage Recommendations

1. **Start Simple**: Begin with basic @Client, @Context, @View macros
2. **Add Features Gradually**: Introduce @Capabilities and @Intelligence as needed
3. **Validate Composition**: Test macro combinations thoroughly
4. **Monitor Performance**: Use generated performance monitoring
5. **Follow Constraints**: Ensure generated code follows architectural constraints

---

**Macro System Specification** - Complete technical specification for code generation macro system with composition framework, enhanced diagnostics, and performance optimization