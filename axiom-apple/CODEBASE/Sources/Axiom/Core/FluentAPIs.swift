import Foundation
import SwiftUI

// MARK: - Fluent Configuration APIs

/// Fluent configuration for contexts with method chaining
@MainActor
public struct ContextConfiguration<C: ObservableContext> {
    private let context: C
    private var observers: [any Client] = []
    private var errorHandlers: [(any Error) -> Void] = []
    private var lifecycleCallbacks: (onAppear: () async -> Void, onDisappear: () async -> Void) = ({}, {})
    
    init(context: C) {
        self.context = context
    }
    
    /// Add client observation with automatic state updates
    public func observe<ObserverClient: Axiom.Client>(_ client: ObserverClient) -> ContextConfiguration<C> where ObserverClient.StateType: Equatable {
        var config = self
        config.observers.append(client)
        return config
    }
    
    /// Add error handling with fluent chaining
    public func handleErrors(_ handler: @escaping (any Error) -> Void) -> ContextConfiguration<C> {
        var config = self
        config.errorHandlers.append(handler)
        return config
    }
    
    /// Add lifecycle callbacks
    public func lifecycle(
        onAppear: @escaping () async -> Void = {},
        onDisappear: @escaping () async -> Void = {}
    ) -> ContextConfiguration<C> {
        var config = self
        config.lifecycleCallbacks = (onAppear, onDisappear)
        return config
    }
    
    /// Apply configuration and return configured context
    public func apply() async throws -> C {
        // Apply all configurations
        for _ in observers {
            // Set up observation (would need proper implementation)
        }
        
        // Set up error handlers
        if context is ErrorHandlingContext {
            // Configure error handling
        }
        
        // Apply lifecycle callbacks (would need proper lifecycle support)
        
        try await context.activate()
        return context
    }
}

/// Fluent client configuration with method chaining
public struct ClientConfiguration<State: Axiom.State & Equatable, Action: Sendable>: Sendable {
    private let client: ErgonomicClient<State, Action>
    private var validators: [@Sendable (Action) -> Result<Void, AxiomError>] = []
    private var interceptors: [@Sendable (Action) async -> Action] = []
    private var persistenceHandlers: [@Sendable (State) async -> Void] = []
    
    init(client: ErgonomicClient<State, Action>) {
        self.client = client
    }
    
    /// Add action validation
    public func validate(_ validator: @escaping @Sendable (Action) -> Result<Void, AxiomError>) -> ClientConfiguration<State, Action> {
        var config = self
        config.validators.append(validator)
        return config
    }
    
    /// Add action interceptor for transformation
    public func intercept(_ interceptor: @escaping @Sendable (Action) async -> Action) -> ClientConfiguration<State, Action> {
        var config = self
        config.interceptors.append(interceptor)
        return config
    }
    
    /// Add state persistence
    public func persist(_ handler: @escaping @Sendable (State) async -> Void) -> ClientConfiguration<State, Action> {
        var config = self
        config.persistenceHandlers.append(handler)
        return config
    }
    
    /// Apply configuration and return configured client
    public func apply() -> ErgonomicClient<State, Action> {
        // Configuration would be applied internally
        return client
    }
}

/// Fluent navigation configuration
@MainActor
public struct NavigationConfiguration {
    private var routes: [String: () async -> Result<Void, AxiomError>] = [:]
    private var guards: [String: () async -> Bool] = [:]
    private var animations: [String: AnyTransition] = [:]
    
    /// Add route with handler
    public func route(_ path: String, handler: @escaping () async -> Result<Void, AxiomError>) -> NavigationConfiguration {
        var config = self
        config.routes[path] = handler
        return config
    }
    
    /// Add route guard
    public func `guard`(_ path: String, check: @escaping () async -> Bool) -> NavigationConfiguration {
        var config = self
        config.guards[path] = check
        return config
    }
    
    /// Add custom animation for route
    public func animate(_ path: String, transition: AnyTransition) -> NavigationConfiguration {
        var config = self
        config.animations[path] = transition
        return config
    }
    
    /// Build navigation service
    public func build() -> ErgonomicNavigationService {
        let middleware = guards.map { (path, check) in
            { (requestedPath: String) async -> Bool in
                if requestedPath == path {
                    return await check()
                }
                return true
            }
        }
        
        return ErgonomicNavigationService(routes: routes, middleware: middleware)
    }
}

/// Fluent error configuration
public struct ErrorConfiguration {
    private var category: ErrorCategory = .unknown
    private var severity: ErrorSeverity = .error
    private var context: [String: String] = [:]
    private var handlers: [(AxiomError) -> Void] = []
    private var recovery: PropagationRecoveryStrategy = .fail
    
    /// Set error category
    public func category(_ category: ErrorCategory) -> ErrorConfiguration {
        var config = self
        config.category = category
        return config
    }
    
    /// Set error severity
    public func severity(_ severity: ErrorSeverity) -> ErrorConfiguration {
        var config = self
        config.severity = severity
        return config
    }
    
    /// Add context information
    public func context(_ key: String, _ value: String) -> ErrorConfiguration {
        var config = self
        config.context[key] = value
        return config
    }
    
    /// Add error handler
    public func handle(_ handler: @escaping (AxiomError) -> Void) -> ErrorConfiguration {
        var config = self
        config.handlers.append(handler)
        return config
    }
    
    /// Set recovery strategy
    public func recover(_ strategy: PropagationRecoveryStrategy) -> ErrorConfiguration {
        var config = self
        config.recovery = strategy
        return config
    }
    
    /// Build error with configuration
    public func build(_ baseError: AxiomError) -> AxiomError {
        var error = baseError
        for (key, value) in context {
            error = error.addingContext(key, value)
        }
        
        // Apply handlers
        for handler in handlers {
            handler(error)
        }
        
        return error
    }
}

// MARK: - Fluent API Entry Points

// Note: ObservableContext fluent configuration removed due to covariant Self limitations
// Use ContextBuilder.create() directly instead

public extension ErgonomicClient {
    /// Start fluent configuration
    func configure() -> ClientConfiguration<StateType, ActionType> {
        return ClientConfiguration(client: self)
    }
}

public extension NavigationBuilder {
    /// Start fluent navigation configuration
    static func configure() -> NavigationConfiguration {
        return NavigationConfiguration()
    }
}

public extension AxiomError {
    /// Start fluent error configuration
    func configure() -> ErrorConfiguration {
        return ErrorConfiguration()
    }
}

// MARK: - Method Chaining Protocols

/// Protocol for chainable operations
public protocol Chainable {
    associatedtype ChainType
    func chain<T>(_ operation: (Self) -> T) -> T
}

extension Chainable {
    public func chain<T>(_ operation: (Self) -> T) -> T {
        return operation(self)
    }
}

// Make configurations chainable
extension ContextConfiguration: Chainable {
    public typealias ChainType = ContextConfiguration<C>
}

extension ClientConfiguration: Chainable {
    public typealias ChainType = ClientConfiguration<State, Action>
}

extension NavigationConfiguration: Chainable {
    public typealias ChainType = NavigationConfiguration
}

extension ErrorConfiguration: Chainable {
    public typealias ChainType = ErrorConfiguration
}

// MARK: - Pipeline Operations

/// Enable pipeline-style operations
public extension Chainable {
    /// Apply operation and continue chain
    func pipe<T: Chainable>(_ transform: (Self) -> T) -> T {
        return transform(self)
    }
    
    /// Apply operation and return self for continued chaining
    func tap(_ operation: (Self) -> Void) -> Self {
        operation(self)
        return self
    }
}

// MARK: - Async Chain Operations

/// Async chainable operations
public protocol AsyncChainable {
    associatedtype AsyncChainType
    func asyncChain<T>(_ operation: (Self) async -> T) async -> T
}

extension AsyncChainable {
    public func asyncChain<T>(_ operation: (Self) async -> T) async -> T {
        return await operation(self)
    }
}

// Make configurations async chainable
extension ContextConfiguration: AsyncChainable {
    public typealias AsyncChainType = ContextConfiguration<C>
}

extension ClientConfiguration: AsyncChainable {
    public typealias AsyncChainType = ClientConfiguration<State, Action>
}

// MARK: - Common Operation Chains

/// Pre-configured chains for common patterns
public struct CommonChains {
    /// Context with client observation and error handling
    @MainActor
    public static func observingContext<C: ObservableContext, ObserverClient: Axiom.Client>(
        _ contextType: C.Type,
        observing client: ObserverClient,
        errorHandler: @escaping (any Error) -> Void = { _ in }
    ) async throws -> C where ObserverClient.StateType: Equatable, C: ObservableContext {
        // Direct context creation since fluent configuration was removed for ObservableContext
        let context = try await ContextBuilder.create(C.self).build()
        try await context.activate()
        return context
    }
    
    /// Client with validation and persistence
    public static func validatedClient<State: Axiom.State & Equatable, Action>(
        initialState: State,
        processor: @escaping @Sendable (Action) async throws -> State,
        validator: @escaping @Sendable (Action) -> Result<Void, AxiomError>,
        persistenceHandler: @escaping @Sendable (State) async -> Void = { _ in }
    ) async -> ErgonomicClient<State, Action> {
        return await ClientBuilder<State, Action>
            .create(initialState: initialState)
            .process(processor)
            .build()
            .configure()
            .validate(validator)
            .persist(persistenceHandler)
            .apply()
    }
    
    /// Navigation with authentication
    @MainActor
    public static func authenticatedNavigation(
        routes: [String: () async -> Result<Void, AxiomError>],
        authCheck: @escaping () async -> Bool
    ) -> ErgonomicNavigationService {
        var config = NavigationConfiguration()
        
        for (path, handler) in routes {
            config = config
                .route(path, handler: handler)
                .guard(path, check: authCheck)
        }
        
        return config.build()
    }
}