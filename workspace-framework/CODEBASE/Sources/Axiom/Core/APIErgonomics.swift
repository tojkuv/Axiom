import Foundation
import SwiftUI

// MARK: - Type-Safe Builder Patterns

/// Context builder for ergonomic context creation
@MainActor
public final class ContextBuilder<C: ObservableContext> {
    private var context: C
    private var children: [any Context] = []
    private var memoryOptions: ContextMemoryOptions?
    
    private init(context: C) {
        self.context = context
    }
    
    /// Create a new context builder
    public static func create<T: ObservableContext>(_ contextType: T.Type) -> ContextBuilder<T> where T: ObservableContext {
        let context = T()
        return ContextBuilder(context: context)
    }
    
    /// Add child contexts
    public func children(_ children: any Context...) -> Self {
        self.children.append(contentsOf: children)
        return self
    }
    
    /// Configure memory options
    public func memory(_ options: ContextMemoryOptions) -> Self {
        self.memoryOptions = options
        return self
    }
    
    /// Build and activate the context
    public func build() async throws -> C {
        // Add children
        for child in children {
            context.addChild(child)
        }
        
        // Activate the context
        try await context.activate()
        
        return context
    }
}

/// Client builder for ergonomic client creation
public final class ClientBuilder<State: StateOwnership.State & Equatable, Action> {
    private let initialState: State
    private var performanceMonitor: (any ClientPerformanceMonitor)?
    private var actionProcessor: ((Action) async throws -> State)?
    
    private init(initialState: State) {
        self.initialState = initialState
    }
    
    /// Create a new client builder
    public static func create<S: StateOwnership.State & Equatable, A>(initialState: S) -> ClientBuilder<S, A> {
        return ClientBuilder<S, A>(initialState: initialState)
    }
    
    /// Add performance monitoring
    public func monitor(_ monitor: any ClientPerformanceMonitor) -> Self {
        self.performanceMonitor = monitor
        return self
    }
    
    /// Define action processing logic
    public func process(_ processor: @escaping (Action) async throws -> State) -> Self {
        self.actionProcessor = processor
        return self
    }
    
    /// Build the client
    public func build() -> ErgonomicClient<State, Action> {
        return ErgonomicClient(
            initialState: initialState,
            actionProcessor: actionProcessor
        )
    }
}

/// Navigation builder for ergonomic navigation setup
@MainActor
public final class NavigationBuilder {
    private var routes: [String: () async -> Result<Void, AxiomError>] = [:]
    private var middleware: [(String) async -> Bool] = []
    
    /// Add a route with handler
    public func route(_ path: String, handler: @escaping () async -> Result<Void, AxiomError>) -> Self {
        routes[path] = handler
        return self
    }
    
    /// Add navigation middleware
    public func middleware(_ check: @escaping (String) async -> Bool) -> Self {
        middleware.append(check)
        return self
    }
    
    /// Build the navigation service
    public func build() -> ErgonomicNavigationService {
        return ErgonomicNavigationService(routes: routes, middleware: middleware)
    }
}

/// Error builder for ergonomic error handling
public final class ErrorBuilder {
    private var category: ErrorCategory = .unknown
    private var severity: ErrorSeverity = .error
    private var context: [String: String] = [:]
    private var recoveryStrategy: PropagationRecoveryStrategy = .fail
    
    /// Set error category
    public func category(_ category: ErrorCategory) -> Self {
        self.category = category
        return self
    }
    
    /// Set error severity
    public func severity(_ severity: ErrorSeverity) -> Self {
        self.severity = severity
        return self
    }
    
    /// Add context information
    public func context(_ key: String, _ value: String) -> Self {
        context[key] = value
        return self
    }
    
    /// Set recovery strategy
    public func recovery(_ strategy: PropagationRecoveryStrategy) -> Self {
        self.recoveryStrategy = strategy
        return self
    }
    
    /// Build validation error
    public func validation(_ field: String, _ reason: String) -> AxiomError {
        var error = AxiomError.validationError(.invalidInput(field, reason))
        for (key, value) in context {
            error = error.addingContext(key, value)
        }
        return error
    }
    
    /// Build context error
    public func contextError(_ message: String) -> AxiomError {
        var error = AxiomError.contextError(.lifecycleError(message))
        for (key, value) in context {
            error = error.addingContext(key, value)
        }
        return error
    }
    
    /// Build navigation error
    public func navigationError(_ reason: String) -> AxiomError {
        var error = AxiomError.navigationError(.invalidRoute(reason))
        for (key, value) in context {
            error = error.addingContext(key, value)
        }
        return error
    }
}

// MARK: - Ergonomic Client Implementation

/// Ergonomic client implementation with reduced boilerplate
public actor ErgonomicClient<S: StateOwnership.State & Equatable, A>: Client {
    public typealias StateType = S
    public typealias ActionType = A
    
    public private(set) var state: S
    private var streamContinuations: [UUID: AsyncStream<S>.Continuation] = [:]
    private let actionProcessor: ((A) async throws -> S)?
    
    init(initialState: S, actionProcessor: ((A) async throws -> S)?) {
        self.state = initialState
        self.actionProcessor = actionProcessor
    }
    
    public var stateStream: AsyncStream<S> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.addContinuation(continuation, id: id)
                
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
                
                continuation.onTermination = { @Sendable _ in
                    Task { @Sendable [weak self, id] in
                        await self?.removeContinuation(id: id)
                    }
                }
            }
        }
    }
    
    private func addContinuation(_ continuation: AsyncStream<S>.Continuation, id: UUID) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    public func process(_ action: A) async throws {
        guard let processor = actionProcessor else { return }
        
        let oldState = state
        let newState = try await processor(action)
        
        await stateWillUpdate(from: oldState, to: newState)
        
        guard state != newState else { return }
        state = newState
        
        for (_, continuation) in streamContinuations {
            continuation.yield(newState)
        }
        
        await stateDidUpdate(from: oldState, to: newState)
    }
}

// MARK: - Ergonomic Navigation Service

/// Ergonomic navigation service with reduced boilerplate
@MainActor
public final class ErgonomicNavigationService: ObservableObject {
    @Published public var currentRoute: String = "/"
    @Published public var navigationStack: [String] = []
    
    private let routes: [String: () async -> Result<Void, AxiomError>]
    private let middleware: [(String) async -> Bool]
    
    init(routes: [String: () async -> Result<Void, AxiomError>], middleware: [(String) async -> Bool]) {
        self.routes = routes
        self.middleware = middleware
    }
    
    public func navigate(to route: String) async -> Result<Void, AxiomError> {
        // Check middleware
        for check in middleware {
            guard await check(route) else {
                return .failure(.navigationError(.unauthorized))
            }
        }
        
        // Execute route handler if available
        if let handler = routes[route] {
            let result = await handler()
            if case .failure = result {
                return result
            }
        }
        
        currentRoute = route
        navigationStack.append(route)
        return .success(())
    }
    
    public func back() async -> Result<Void, AxiomError> {
        guard !navigationStack.isEmpty else {
            return .failure(.navigationError(.invalidRoute("Cannot go back from root")))
        }
        
        navigationStack.removeLast()
        currentRoute = navigationStack.last ?? "/"
        return .success(())
    }
    
    public func root() async -> Result<Void, AxiomError> {
        navigationStack.removeAll()
        currentRoute = "/"
        return .success(())
    }
}

// MARK: - Fluent API Extensions

extension ContextBuilder {
    /// Fluent API for common context patterns
    @discardableResult
    public func withLifecycle(
        onAppear: @escaping () async -> Void = {},
        onDisappear: @escaping () async -> Void = {}
    ) -> Self {
        // This would be implemented with lifecycle callbacks
        return self
    }
    
    @discardableResult
    public func observing<C: Client>(_ client: C) -> Self where C.StateType: Equatable {
        // Add client observation
        return self
    }
}

extension ClientBuilder {
    /// Fluent API for common client patterns
    @discardableResult
    public func withValidation(_ validator: @escaping (Action) -> Result<Void, AxiomError>) -> Self {
        // Add validation layer
        return self
    }
    
    @discardableResult
    public func withPersistence(save: @escaping (State) async -> Void) -> Self {
        // Add persistence layer
        return self
    }
}

extension NavigationBuilder {
    /// Fluent API for common navigation patterns
    @discardableResult
    public func authenticated(_ routes: String...) -> Self {
        for route in routes {
            middleware { path in
                // Add authentication check
                path != route || true // Placeholder
            }
        }
        return self
    }
    
    @discardableResult
    public func withDeepLinking() -> Self {
        // Add deep linking support
        return self
    }
}

// MARK: - Convenience Extensions

public extension Context {
    /// Convenience method to create and activate a context
    static func create<T: ObservableContext>() async throws -> T where T: ObservableContext {
        return try await ContextBuilder.create(T.self).build()
    }
    
    /// Convenience method with children
    static func create<T: ObservableContext>(with children: any Context...) async throws -> T where T: ObservableContext {
        return try await ContextBuilder.create(T.self).children(children).build()
    }
}

public extension Client {
    /// Convenience method to create a client
    static func create<S: StateOwnership.State & Equatable, A>(
        initialState: S,
        processor: @escaping (A) async throws -> S
    ) -> ErgonomicClient<S, A> {
        return ClientBuilder<S, A>.create(initialState: initialState)
            .process(processor)
            .build()
    }
}

public extension NavigationBuilder {
    /// Convenience method to create navigation service
    static func service() -> NavigationBuilder {
        return NavigationBuilder()
    }
}

public extension ErrorBuilder {
    /// Convenience method to create error builder
    static func error() -> ErrorBuilder {
        return ErrorBuilder()
    }
    
    /// Quick validation error
    static func validation(_ field: String, _ reason: String) -> AxiomError {
        return ErrorBuilder().validation(field, reason)
    }
    
    /// Quick context error
    static func context(_ message: String) -> AxiomError {
        return ErrorBuilder().contextError(message)
    }
}
