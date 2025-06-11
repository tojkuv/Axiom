# REQUIREMENTS-W-02-005-CLIENT-ISOLATION-ENFORCEMENT

## Requirement Overview

**ID**: W-02-005  
**Title**: Client Isolation Rules and Enforcement Framework  
**Type**: WORKER - Concurrency & Actor Safety Domain  
**Priority**: CRITICAL  
**Worker**: WORKER-02  
**Dependencies**: P-001 (Core Protocol Foundation), W-02-001 (Actor Isolation Patterns)  

## Executive Summary

Establish a comprehensive client isolation enforcement framework that guarantees clients cannot directly depend on or communicate with other clients. This requirement provides compile-time validation, runtime enforcement, communication patterns through contexts, and isolation verification tools that ensure architectural integrity and prevent coupling between client components.

## Current State Analysis

**Existing Implementation in AxiomFramework**:
- `ClientIsolationValidator` struct with basic validation
- `ClientDefinition` for dependency tracking
- Circular dependency detection
- Build script generation helpers
- Basic source file validation

**Identified Gaps**:
- Compile-time enforcement not integrated
- Runtime isolation checks missing
- Context-mediated communication patterns undefined
- Performance impact of isolation unmeasured
- Macro-based enforcement not implemented

## Requirement Details

### 1. Compile-Time Isolation Enforcement

**Requirements**:
- Swift compiler plugin for isolation validation
- Import statement analysis and restriction
- Macro-based client boundary enforcement
- Build failure on isolation violations

**Enforcement Rules**:
```swift
public protocol ClientIsolationRules {
    // Clients cannot import other clients
    static var forbiddenImports: [String] { get }
    
    // Clients can only communicate through contexts
    static var allowedCommunicationPatterns: [Pattern] { get }
    
    // Clients must be actor-isolated
    static var requiresActorIsolation: Bool { get }
    
    // Validate isolation at compile time
    static func validate(clientType: Any.Type) throws
}
```

### 2. Runtime Isolation Verification

**Requirements**:
- Dynamic dependency graph validation
- Cross-client call detection
- Isolation breach reporting
- Performance monitoring of checks

**Performance Targets**:
- < 100ns overhead per client method call
- < 1μs for dependency validation
- Zero false positives in detection

### 3. Context-Mediated Communication

**Requirements**:
- Clear patterns for client coordination
- Type-safe message passing through contexts
- Performance-optimized routing
- Debugging support for communication

### 4. Isolation Testing Framework

**Requirements**:
- Automated isolation verification tests
- Dependency graph visualization
- Violation scenario testing
- Performance impact measurement

## API Design

### Enhanced Isolation System

```swift
// Client isolation boundary marker
@attached(peer, names: arbitrary)
@attached(member, names: named(init))
public macro ClientBoundary() = #externalMacro(
    module: "AxiomMacros",
    type: "ClientBoundaryMacro"
)

// Isolated client protocol with enforcement
public protocol IsolatedClient: Actor {
    associatedtype StateType: Sendable
    associatedtype ActionType
    associatedtype MessageType: ClientMessage
    
    // Unique client identifier
    var clientID: ClientIdentifier { get }
    
    // Isolation validator
    var isolationValidator: ClientIsolationValidator { get }
    
    // Handle messages from contexts only
    func handleMessage(_ message: MessageType) async throws
}

// Client message protocol for type safety
public protocol ClientMessage: Sendable {
    var source: MessageSource { get }
    var timestamp: Date { get }
    var correlationID: UUID { get }
}

// Message source for validation
public enum MessageSource: Sendable {
    case context(ContextIdentifier)
    case system
    case test
}

// Runtime isolation enforcer
public actor IsolationEnforcer {
    private var clientRegistry: [ClientIdentifier: IsolationInfo] = [:]
    private var communicationLog: [CommunicationRecord] = []
    private let validator = DependencyValidator()
    
    struct IsolationInfo {
        let client: any IsolatedClient
        let allowedContexts: Set<ContextIdentifier>
        let createdAt: Date
    }
    
    // Register client with isolation rules
    public func registerClient(
        _ client: any IsolatedClient,
        allowedContexts: Set<ContextIdentifier>
    ) async throws {
        // Validate no existing dependencies
        try await validator.validateNoDependencies(client)
        
        let info = IsolationInfo(
            client: client,
            allowedContexts: allowedContexts,
            createdAt: Date()
        )
        
        clientRegistry[client.clientID] = info
    }
    
    // Validate message routing
    public func validateCommunication(
        from source: MessageSource,
        to client: ClientIdentifier
    ) async throws {
        guard let info = clientRegistry[client] else {
            throw IsolationError.unregisteredClient(client)
        }
        
        switch source {
        case .context(let contextID):
            guard info.allowedContexts.contains(contextID) else {
                throw IsolationError.unauthorizedContext(
                    context: contextID,
                    client: client
                )
            }
        case .system, .test:
            // Always allowed
            break
        }
        
        // Log communication
        let record = CommunicationRecord(
            source: source,
            destination: client,
            timestamp: Date()
        )
        communicationLog.append(record)
    }
    
    // Detect isolation violations
    public func detectViolations() async -> [IsolationViolation] {
        var violations: [IsolationViolation] = []
        
        // Check for direct client references
        for (clientID, info) in clientRegistry {
            let mirrors = await gatherMirrors(for: info.client)
            
            for mirror in mirrors {
                if let violation = checkForClientReferences(
                    in: mirror,
                    from: clientID
                ) {
                    violations.append(violation)
                }
            }
        }
        
        return violations
    }
}

// Context-mediated communication router
@MainActor
public class IsolatedCommunicationRouter {
    private let enforcer: IsolationEnforcer
    private var routingTable: [ClientIdentifier: any IsolatedClient] = [:]
    
    public init(enforcer: IsolationEnforcer) {
        self.enforcer = enforcer
    }
    
    // Route message through context
    public func routeMessage<M: ClientMessage>(
        _ message: M,
        to clientID: ClientIdentifier,
        from context: ContextIdentifier
    ) async throws {
        // Validate routing is allowed
        try await enforcer.validateCommunication(
            from: .context(context),
            to: clientID
        )
        
        // Get client and deliver message
        guard let client = routingTable[clientID] else {
            throw RoutingError.clientNotFound(clientID)
        }
        
        // Type-safe message delivery
        if let typedClient = client as? any IsolatedClient,
           let typedMessage = message as? typedClient.MessageType {
            try await typedClient.handleMessage(typedMessage)
        } else {
            throw RoutingError.typeMismatch(
                expected: String(describing: type(of: client).MessageType),
                actual: String(describing: type(of: message))
            )
        }
    }
}

// Compile-time validation attributes
@propertyWrapper
public struct NoCrossClientDependency<Value> {
    private var value: Value
    
    public init(wrappedValue: Value) {
        // Validate at initialization
        if Value.self is any IsolatedClient.Type {
            fatalError("Client type cannot be used as dependency")
        }
        self.value = wrappedValue
    }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
}

// Dependency graph builder
public actor DependencyGraphBuilder {
    private var nodes: [ClientIdentifier: DependencyNode] = [:]
    
    public struct DependencyNode {
        let clientID: ClientIdentifier
        var dependencies: Set<String> = []
        var contexts: Set<ContextIdentifier> = []
    }
    
    // Build graph from runtime information
    public func buildGraph() async -> DependencyGraph {
        var edges: [(ClientIdentifier, String)] = []
        
        for (clientID, node) in nodes {
            for dependency in node.dependencies {
                edges.append((clientID, dependency))
            }
        }
        
        return DependencyGraph(
            nodes: Set(nodes.keys),
            edges: edges,
            contexts: nodes.values.flatMap { $0.contexts }
        )
    }
    
    // Validate no client-to-client edges
    public func validateIsolation() async throws {
        let graph = await buildGraph()
        
        for edge in graph.edges {
            if graph.nodes.contains(ClientIdentifier(edge.1)) {
                throw IsolationError.clientToClientDependency(
                    from: edge.0,
                    to: ClientIdentifier(edge.1)
                )
            }
        }
    }
}

// Testing support for isolation
public struct IsolationTestContext {
    private let enforcer = IsolationEnforcer()
    private let router = IsolatedCommunicationRouter(enforcer: enforcer)
    
    // Create isolated test environment
    public func createIsolatedEnvironment() async -> TestEnvironment {
        TestEnvironment(
            enforcer: enforcer,
            router: router,
            violationDetector: ViolationDetector()
        )
    }
    
    // Test isolation between clients
    public func testIsolation(
        client1: any IsolatedClient,
        client2: any IsolatedClient
    ) async throws {
        // Register clients
        try await enforcer.registerClient(client1, allowedContexts: [])
        try await enforcer.registerClient(client2, allowedContexts: [])
        
        // Attempt direct communication (should fail)
        do {
            try await attemptDirectCommunication(
                from: client1,
                to: client2
            )
            throw TestError.isolationNotEnforced
        } catch IsolationError.unauthorizedCommunication {
            // Expected - isolation is working
        }
    }
}

// Source file analyzer for build-time validation
public struct SourceFileAnalyzer {
    private let fileURL: URL
    private let clientPattern = #/class\s+(\w+).*?:\s*.*?\bClient\b/#
    private let importPattern = #/import\s+(\w+)/#
    
    public func analyze() throws -> AnalysisResult {
        let content = try String(contentsOf: fileURL)
        
        // Find client declaration
        let clientMatch = content.firstMatch(of: clientPattern)
        let clientName = clientMatch?.output.1
        
        // Find imports
        let imports = content.matches(of: importPattern).map { String($0.output.1) }
        
        // Check for client imports
        var violations: [String] = []
        for imp in imports {
            if imp.hasSuffix("Client") && imp != clientName {
                violations.append(
                    "Client '\(clientName ?? "Unknown")' cannot import '\(imp)'"
                )
            }
        }
        
        return AnalysisResult(
            clientName: clientName.map(String.init),
            imports: imports,
            violations: violations
        )
    }
}
```

### Isolation Patterns

```swift
// Pattern: Client coordination through context
@MainActor
public class CoordinatingContext: ObservableObject {
    private let client1: Client1
    private let client2: Client2
    private let router: IsolatedCommunicationRouter
    
    // Coordinate without direct client communication
    public func coordinateAction() async throws {
        // Get state from client1
        let state1 = await client1.currentState
        
        // Make decision in context
        let decision = makeCoordinationDecision(basedOn: state1)
        
        // Send message to client2
        let message = CoordinationMessage(
            source: .context(self.contextID),
            decision: decision
        )
        
        try await router.routeMessage(
            message,
            to: client2.clientID,
            from: self.contextID
        )
    }
}

// Pattern: Event aggregation without coupling
public actor EventAggregator {
    private var clientStreams: [ClientIdentifier: AsyncStream<ClientEvent>] = [:]
    
    // Aggregate events from multiple clients
    public func aggregateEvents() -> AsyncStream<AggregatedEvent> {
        AsyncStream { continuation in
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for (clientID, stream) in clientStreams {
                        group.addTask {
                            for await event in stream {
                                let aggregated = AggregatedEvent(
                                    clientID: clientID,
                                    event: event,
                                    timestamp: Date()
                                )
                                continuation.yield(aggregated)
                            }
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}
```

## Technical Design

### Architecture Components

1. **Compile-Time Layer**
   - Swift compiler plugin
   - Macro-based enforcement
   - Import restriction
   - Build integration

2. **Runtime Layer**
   - Isolation enforcer actor
   - Communication validator
   - Violation detector
   - Performance monitor

3. **Communication Layer**
   - Context-based routing
   - Type-safe messaging
   - Event aggregation
   - Debugging support

4. **Testing Layer**
   - Isolation test framework
   - Violation scenarios
   - Graph visualization
   - Performance benchmarks

### Enforcement Strategies

1. **Static Analysis**
   - AST traversal for dependencies
   - Import statement validation
   - Type reference checking
   - Build failure on violations

2. **Runtime Validation**
   - Dynamic proxy injection
   - Method call interception
   - Dependency tracking
   - Violation reporting

3. **Communication Patterns**
   - Message-based coordination
   - Event aggregation
   - State synchronization
   - Action coordination

## Success Criteria

### Functional Validation

- [ ] **Compile-Time Enforcement**: Build fails on client imports
- [ ] **Runtime Detection**: All violations detected and reported
- [ ] **Context Routing**: Messages properly routed through contexts
- [ ] **Type Safety**: Type-safe message delivery verified
- [ ] **Graph Accuracy**: Dependency graph correctly constructed

### Integration Validation

- [ ] **Framework Adoption**: All clients use isolation patterns
- [ ] **Build Integration**: Validation in build pipeline
- [ ] **Testing Coverage**: Isolation tests for all clients
- [ ] **Documentation**: Clear patterns documented
- [ ] **Migration Support**: Tools for existing code

### Performance Validation

- [ ] **Call Overhead**: < 100ns per isolated call
- [ ] **Validation Speed**: < 1μs for dependency check
- [ ] **Routing Latency**: < 1μs for message routing
- [ ] **Memory Overhead**: < 1KB per client
- [ ] **Build Impact**: < 5% increase in build time

## Implementation Priority

1. **Phase 1**: Basic isolation enforcement and validation
2. **Phase 2**: Context-based communication patterns
3. **Phase 3**: Compile-time enforcement with macros
4. **Phase 4**: Testing framework and tooling

This requirement provides the comprehensive client isolation enforcement framework that ensures architectural integrity and prevents coupling between client components across the entire AxiomFramework.