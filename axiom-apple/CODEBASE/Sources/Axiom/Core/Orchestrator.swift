import Foundation
import SwiftUI

// MARK: - Orchestrator Protocol

/// Core protocol for application-level coordination.
/// 
/// Orchestrators manage context creation, dependency resolution, capability
/// monitoring, and navigation. They are the top-level coordinators in Axiom.
/// 
/// Requirements:
/// - Must be actor-based for thread safety
/// - Creates contexts with dependency injection
/// - Monitors capability availability
/// - Manages navigation state
public protocol Orchestrator: Actor {
    /// Create a context for a presentation type
    func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType
    
    /// Navigate to a route
    func navigate(to route: any TypeSafeRoute) async
}

// MARK: - Extended Orchestrator Protocol

/// Extended orchestrator with additional capabilities
public protocol ExtendedOrchestrator: Orchestrator {
    /// Create a context with explicit type and configuration
    func createContext<T: Context & Sendable>(
        type: T.Type,
        identifier: String?,
        dependencies: [String]
    ) async throws -> T
    
    /// Register a client for dependency injection
    func registerClient<C: Client>(_ client: C, for key: String) async
    
    /// Register a capability for monitoring
    func registerCapability<C: Capability>(_ capability: C, for key: String) async
    
    /// Check if a capability is available
    func isCapabilityAvailable(_ key: String) async -> Bool
    
    /// Get a context builder for fluent configuration
    func contextBuilder<T: Context>(for type: T.Type) async -> OrchestratorContextBuilder<T>
}


// MARK: - Standard Orchestrator Implementation

/// Standard implementation providing common orchestrator behaviors
public actor StandardOrchestrator: ExtendedOrchestrator {
    /// Registered contexts
    private var contexts: [String: any Context] = [:]
    
    /// Registered clients for dependency injection
    private var clients: [String: any Client] = [:]
    
    /// Registered capabilities
    private var capabilities: [String: any Capability] = [:]
    
    /// Current navigation route
    public private(set) var currentRoute: (any TypeSafeRoute)?
    
    /// Navigation history
    public private(set) var navigationHistory: [any TypeSafeRoute] = []
    
    /// Route handlers
    private var routeHandlers: [AnyHashable: (any TypeSafeRoute) async -> any Context] = [:]
    
    public init() {}
    
    /// Create context for presentation
    public func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType {
        // Default implementation - this should be overridden by subclasses
        // For now, create a basic context (this may not work for all cases)
        fatalError("Context creation not configured for \(presentation). Override this method in your orchestrator.")
    }
    
    /// Create context with configuration
    public func createContext<T: Context & Sendable>(
        type: T.Type,
        identifier: String? = nil,
        dependencies: [String] = []
    ) async throws -> T {
        let id = identifier ?? UUID().uuidString
        
        // Create context with dependencies
        if let existingContext = contexts[id] as? T {
            return existingContext
        }
        
        // Throw error instead of fatal crash
        throw AxiomError.contextError(.initializationFailed("Context factory not configured for \(type)"))
    }
    
    /// Register a client
    public func registerClient<C: Client>(_ client: C, for key: String) async {
        clients[key] = client
    }
    
    /// Get a registered client
    public func client<C: Client>(for key: String, as type: C.Type) async -> C? {
        clients[key] as? C
    }
    
    /// Register a capability
    public func registerCapability<C: Capability>(_ capability: C, for key: String) async {
        capabilities[key] = capability
    }
    
    /// Check capability availability
    public func isCapabilityAvailable(_ key: String) async -> Bool {
        guard let capability = capabilities[key] else { return false }
        return await capability.isAvailable
    }
    
    /// Get context builder
    public func contextBuilder<T: Context>(for type: T.Type) async -> OrchestratorContextBuilder<T> {
        OrchestratorContextBuilder(orchestrator: self, contextType: type)
    }
    
    /// Navigate to route
    public func navigate(to route: any TypeSafeRoute) async {
        currentRoute = route
        navigationHistory.append(route)
        
        // Execute route handler if registered
        if let handler = routeHandlers[AnyHashable(route)] {
            let context = await handler(route)
            contexts[route.routeIdentifier] = context
        }
    }
    
    /// Register route handler
    public func registerRoute<R: TypeSafeRoute>(
        _ route: R,
        handler: @escaping (R) async -> any Context
    ) async {
        routeHandlers[AnyHashable(route)] = { anyRoute in
            if let typedRoute = anyRoute as? R {
                return await handler(typedRoute)
            }
            fatalError("Route type mismatch")
        }
    }
    
    /// Activate all contexts
    public func activateAllContexts() async {
        let contextArray = Array(contexts.values)
        await withTaskGroup(of: Void.self) { group in
            for context in contextArray {
                group.addTask {
                    try? await context.activate()
                }
            }
        }
    }
    
    /// Deactivate all contexts
    public func deactivateAllContexts() async {
        let contextArray = Array(contexts.values)
        await withTaskGroup(of: Void.self) { group in
            for context in contextArray {
                group.addTask {
                    await context.deactivate()
                }
            }
        }
    }
    
    /// Store a context
    public func storeContext(_ context: any Context, for identifier: String) async {
        contexts[identifier] = context
    }
}

// MARK: - Context Builder

/// Fluent builder for context configuration with enhanced features
public final class OrchestratorContextBuilder<T: Context>: @unchecked Sendable {
    private let orchestrator: any ExtendedOrchestrator
    private let contextType: T.Type
    private var identifier: String?
    private var dependencies: [String] = []
    private var configurations: [(T) async -> Void] = []
    private var errorHandlers: [(any Error) async -> Void] = []
    private var lifecycleHooks: [(hook: LifecycleHook, action: (T) async -> Void)] = []
    
    public init(orchestrator: any ExtendedOrchestrator, contextType: T.Type) {
        self.orchestrator = orchestrator
        self.contextType = contextType
    }
    
    /// Set context identifier
    public func withIdentifier(_ id: String) -> Self {
        identifier = id
        return self
    }
    
    /// Add a dependency
    public func withDependency(_ key: String) -> Self {
        dependencies.append(key)
        return self
    }
    
    /// Add multiple dependencies
    public func withDependencies(_ keys: [String]) -> Self {
        dependencies.append(contentsOf: keys)
        return self
    }
    
    /// Add configuration closure
    public func withConfiguration(_ config: @escaping (T) async -> Void) -> Self {
        configurations.append(config)
        return self
    }
    
    /// Add error handler
    public func withErrorHandler(_ handler: @escaping (any Error) async -> Void) -> Self {
        errorHandlers.append(handler)
        return self
    }
    
    /// Add lifecycle hook
    public func withLifecycleHook(_ hook: LifecycleHook, action: @escaping (T) async -> Void) -> Self {
        lifecycleHooks.append((hook, action))
        return self
    }
    
    /// Build the context
    public func build() async throws -> T {
        do {
            let context = try await orchestrator.createContext(
                type: contextType,
                identifier: identifier,
                dependencies: dependencies
            )
            
            // Apply configurations
            for config in configurations {
                await config(context)
            }
            
            // Apply lifecycle hooks
            for (hook, action) in lifecycleHooks where hook == .afterCreation {
                await action(context)
            }
            
            return context
        } catch {
            // Handle errors
            for handler in errorHandlers {
                await handler(error)
            }
            throw error
        }
    }
}

/// Lifecycle hooks for context creation
public enum LifecycleHook {
    case afterCreation
    case beforeConfiguration
    case afterConfiguration
}


// MARK: - Navigation Manager

/// Dedicated navigation management
public actor NavigationManager {
    /// Current route stack
    private var routeStack: [any TypeSafeRoute] = []
    
    /// Navigation handlers
    private var handlers: [AnyHashable: () async -> Void] = [:]
    
    /// Push a route
    public func push(_ route: any TypeSafeRoute) async {
        routeStack.append(route)
        if let handler = handlers[AnyHashable(route)] {
            await handler()
        }
    }
    
    /// Pop current route
    @discardableResult
    public func pop() async -> Route? {
        guard !routeStack.isEmpty else { return nil }
        return routeStack.removeLast()
    }
    
    /// Pop to root
    public func popToRoot() async {
        routeStack = routeStack.isEmpty ? [] : [routeStack[0]]
    }
    
    /// Register navigation handler
    public func registerHandler(for route: any TypeSafeRoute, handler: @escaping () async -> Void) {
        handlers[AnyHashable(route)] = handler
    }
    
    /// Current route
    public var currentRoute: (any TypeSafeRoute)? {
        routeStack.last
    }
    
    /// Full navigation stack
    public var stack: [Route] {
        routeStack
    }
}

// MARK: - Dependency Resolution

/// Protocol for dependency resolution
public protocol DependencyResolver: Actor {
    /// Resolve a dependency by key
    func resolve<T>(_ key: String, as type: T.Type) async -> T?
    
    /// Register a dependency
    func register<T>(_ dependency: T, for key: String) async
    
    /// Check if dependency exists
    func contains(_ key: String) async -> Bool
}

// MARK: - Orchestrator Factory

/// Factory for creating orchestrators with builder pattern
public struct OrchestratorFactory {
    /// Create a default orchestrator
    public static func createDefault() -> any Orchestrator {
        StandardOrchestrator()
    }
    
    /// Create an orchestrator with custom configuration
    public static func create(
        with configuration: OrchestratorConfiguration
    ) -> any Orchestrator {
        // In production, this would create configured orchestrators
        StandardOrchestrator()
    }
    
    /// Create orchestrator with builder
    public static func builder() -> OrchestratorBuilder {
        OrchestratorBuilder()
    }
}

// MARK: - Orchestrator Builder

/// Builder for creating configured orchestrators
public final class OrchestratorBuilder {
    private var navigationEnabled = true
    private var capabilityMonitoringEnabled = true
    private var maxContextCount = 100
    private var preregisteredClients: [(String, any Client)] = []
    private var preregisteredCapabilities: [(String, any Capability)] = []
    
    /// Enable or disable navigation
    public func withNavigation(_ enabled: Bool) -> Self {
        navigationEnabled = enabled
        return self
    }
    
    /// Enable or disable capability monitoring
    public func withCapabilityMonitoring(_ enabled: Bool) -> Self {
        capabilityMonitoringEnabled = enabled
        return self
    }
    
    /// Set maximum context count
    public func withMaxContextCount(_ count: Int) -> Self {
        maxContextCount = count
        return self
    }
    
    /// Pre-register a client
    public func withClient<C: Client>(_ client: C, for key: String) -> Self {
        preregisteredClients.append((key, client))
        return self
    }
    
    /// Pre-register a capability
    public func withCapability<C: Capability>(_ capability: C, for key: String) -> Self {
        preregisteredCapabilities.append((key, capability))
        return self
    }
    
    /// Build the orchestrator
    public func build() async -> any ExtendedOrchestrator {
        _ = OrchestratorConfiguration(
            navigationEnabled: navigationEnabled,
            capabilityMonitoringEnabled: capabilityMonitoringEnabled,
            maxContextCount: maxContextCount
        )
        
        let orchestrator = StandardOrchestrator()
        
        // Register pre-configured items
        for (key, client) in preregisteredClients {
            await orchestrator.registerClient(client, for: key)
        }
        
        for (key, capability) in preregisteredCapabilities {
            await orchestrator.registerCapability(capability, for: key)
        }
        
        return orchestrator
    }
}

/// Configuration for orchestrator creation
public struct OrchestratorConfiguration {
    /// Enable navigation support
    public let navigationEnabled: Bool
    
    /// Enable capability monitoring
    public let capabilityMonitoringEnabled: Bool
    
    /// Maximum context count
    public let maxContextCount: Int
    
    /// Context creation timeout
    public let contextCreationTimeout: Duration
    
    /// Enable performance monitoring
    public let performanceMonitoringEnabled: Bool
    
    /// Memory warning threshold in MB
    public let memoryWarningThreshold: Int
    
    public init(
        navigationEnabled: Bool = true,
        capabilityMonitoringEnabled: Bool = true,
        maxContextCount: Int = 100,
        contextCreationTimeout: Duration = .milliseconds(500),
        performanceMonitoringEnabled: Bool = false,
        memoryWarningThreshold: Int = 100
    ) {
        self.navigationEnabled = navigationEnabled
        self.capabilityMonitoringEnabled = capabilityMonitoringEnabled
        self.maxContextCount = maxContextCount
        self.contextCreationTimeout = contextCreationTimeout
        self.performanceMonitoringEnabled = performanceMonitoringEnabled
        self.memoryWarningThreshold = memoryWarningThreshold
    }
}

// MARK: - Performance Monitoring

/// Performance metrics for orchestrator operations
public struct OrchestratorPerformanceMetrics {
    public let averageContextCreationTime: Duration
    public let totalContextsCreated: Int
    public let totalNavigations: Int
    public let memoryUsage: Int
    public let activeContextCount: Int
    
    public init(
        averageContextCreationTime: Duration,
        totalContextsCreated: Int,
        totalNavigations: Int,
        memoryUsage: Int,
        activeContextCount: Int
    ) {
        self.averageContextCreationTime = averageContextCreationTime
        self.totalContextsCreated = totalContextsCreated
        self.totalNavigations = totalNavigations
        self.memoryUsage = memoryUsage
        self.activeContextCount = activeContextCount
    }
}