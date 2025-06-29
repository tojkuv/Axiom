import Foundation
import AxiomCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Context Convenience Extensions

public extension AxiomContext {
    /// Quick context creation with automatic lifecycle
    @MainActor
    static func quick<T: AxiomObservableContext>() async -> T {
        let context = T()
        try? await context.activate()
        return context
    }
    
    /// Context with error boundary
    @MainActor
    static func withErrorBoundary<T: AxiomObservableContext>(
        _ contextType: T.Type,
        errorHandler: @escaping (any Error) -> Void = { _ in }
    ) async -> T where T: AxiomObservableContext {
        let context = T()
        // Error boundary setup would be implemented here
        try? await context.activate()
        return context
    }
    
    /// Context with automatic cleanup
    @MainActor
    static func autoCleanup<T: AxiomObservableContext>(_ contextType: T.Type) async -> T {
        let context = T()
        
        // Set up automatic cleanup on app background/terminate
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { await context.deactivate() }
        }
        #endif
        
        try? await context.activate()
        return context
    }
}

public extension AxiomObservableContext {
    /// Add multiple children at once
    func withChildren(_ children: any AxiomContext...) -> Self {
        for child in children {
            addChild(child)
        }
        return self
    }
    
    /// Quick state update notification
    func update() {
        notifyUpdate()
    }
    
    /// Batch multiple operations
    func batch(_ operations: () async -> Void) async {
        await operations()
        notifyUpdate()
    }
}

// MARK: - Client Convenience Extensions

public extension AxiomClient {
    /// Process action with automatic error handling
    func safeProcess(_ action: ActionType) async -> Result<Void, AxiomError> {
        do {
            try await process(action)
            return .success(())
        } catch let error as AxiomError {
            return .failure(error)
        } catch {
            return .failure(AxiomError.unknownError)
        }
    }
    
    /// Process multiple actions with rollback on failure
    func processWithRollback<S: Sequence>(_ actions: S) async -> Result<Void, AxiomError> where S.Element == ActionType {
        // This would require state snapshots for proper rollback
        for action in actions {
            let result = await safeProcess(action)
            if case .failure(let error) = result {
                return .failure(error)
            }
        }
        return .success(())
    }
    
    /// Get current state snapshot
    func snapshot() async -> StateType? {
        // Would need proper implementation based on client type
        return nil
    }
}

public extension ErgonomicClient {
    /// Quick client creation with basic validation
    static func validated<StateType: AxiomState & Equatable, ActionType>(
        initialState: StateType,
        processor: @escaping @Sendable (ActionType) async throws -> StateType,
        validator: @escaping @Sendable (ActionType) -> Bool
    ) -> ErgonomicClient<StateType, ActionType> {
        return ErgonomicClient<StateType, ActionType>(initialState: initialState) { @Sendable action in
            guard validator(action) else {
                throw AxiomError.validationError(.invalidInput("action", "Failed validation"))
            }
            return try await processor(action)
        }
    }
    
    /// Client with automatic state persistence
    static func persistent<StateType: AxiomState & Equatable & Codable, ActionType>(
        initialState: StateType,
        processor: @escaping @Sendable (ActionType) async throws -> StateType,
        storageKey: String
    ) -> ErgonomicClient<StateType, ActionType> {
        // Load initial state from storage if available
        var state = initialState
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(StateType.self, from: data) {
            state = stored
        }
        
        return ErgonomicClient<StateType, ActionType>(initialState: state) { @Sendable action in
            let newState = try await processor(action)
            
            // Persist new state
            if let data = try? JSONEncoder().encode(newState) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
            
            return newState
        }
    }
}

// MARK: - Navigation Convenience Extensions

public extension NavigationBuilder {
    /// Quick navigation with common routes
    static func standard() -> NavigationBuilder {
        return NavigationBuilder()
            .route("/") { .success(()) }
            .route("/back") { .success(()) }
            .route("/settings") { .success(()) }
    }
    
    /// Navigation with deep linking support
    static func deepLinkable() -> NavigationBuilder {
        return NavigationBuilder()
            .middleware { route in
                // Basic deep link validation
                return route.hasPrefix("/") && !route.contains("../")
            }
    }
    
    /// Navigation with analytics
    static func tracked() -> NavigationBuilder {
        return NavigationBuilder()
            .middleware { route in
                // Analytics tracking would be implemented here
                print("Navigation to: \(route)")
                return true
            }
    }
}

public extension ErgonomicNavigationService {
    /// Quick navigation shortcuts
    func home() async -> Result<Void, AxiomError> {
        return await navigate(to: "/")
    }
    
    func settings() async -> Result<Void, AxiomError> {
        return await navigate(to: "/settings")
    }
    
    func profile() async -> Result<Void, AxiomError> {
        return await navigate(to: "/profile")
    }
    
    /// Navigate with confirmation
    func navigateWithConfirmation(to route: String, message: String = "Navigate?") async -> Result<Void, AxiomError> {
        // In a real implementation, this would show a confirmation dialog
        // For now, just navigate directly
        return await navigate(to: route)
    }
    
    /// Breadcrumb navigation
    func breadcrumb() -> [String] {
        return navigationStack
    }
    
    /// Clear navigation history
    func clearHistory() async -> Result<Void, AxiomError> {
        navigationStack.removeAll()
        return .success(())
    }
}

// MARK: - Error Handling Convenience Extensions

public extension AxiomError {
    /// Quick error creation shortcuts
    static func validation(_ message: String) -> AxiomError {
        return .validationError(.invalidInput("field", message))
    }
    
    static func navigation(_ message: String) -> AxiomError {
        return .navigationError(.invalidRoute(message))
    }
    
    static func context(_ message: String) -> AxiomError {
        return .contextError(.lifecycleError(message))
    }
    
    static func client(_ message: String) -> AxiomError {
        return .clientError(.invalidAction(message))
    }
    
    /// Chain multiple errors
    func then(_ nextError: AxiomError) -> AxiomError {
        return nextError.chainedWith(self)
    }
    
    /// Add operation context
    func during(_ operation: String) -> AxiomError {
        return addingContext("operation", operation)
    }
    
    /// Add timestamp
    func timestamped() -> AxiomError {
        return addingContext("timestamp", ISO8601DateFormatter().string(from: Date()))
    }
}

public extension Result where Failure == AxiomError {
    /// Quick success result for Void
    static var ok: Result<Void, AxiomError> {
        return .success(())
    }
    
    /// Chain results with error context
    func thenRun<T>(_ operation: () async throws -> T) async -> Result<T, AxiomError> {
        switch self {
        case .success:
            do {
                let result = try await operation()
                return .success(result)
            } catch let error as AxiomError {
                return .failure(error)
            } catch {
                return .failure(AxiomError.unknownError)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Transform success value
    func transform<T>(_ transformer: (Success) -> T) -> Result<T, AxiomError> {
        return map(transformer)
    }
    
    /// Handle errors with recovery
    func recover(_ recovery: (AxiomError) -> Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            return recovery(error)
        }
    }
}

// MARK: - SwiftUI Integration Convenience

public extension View {
    /// Bind context to view with automatic lifecycle
    @MainActor
    func context<C: AxiomObservableContext>(_ context: C) -> some View {
        self
            .environmentObject(context)
            .onAppear {
                Task { try? await context.activate() }
            }
            .onDisappear {
                Task { await context.deactivate() }
            }
    }
    
    /// Handle errors with alert
    func errorAlert(_ error: Binding<AxiomError?>) -> some View {
        self.alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") { error.wrappedValue = nil }
        } message: {
            Text(error.wrappedValue?.localizedDescription ?? "")
        }
    }
    
    /// Navigation wrapper
    @MainActor
    func navigation(_ service: ErgonomicNavigationService) -> some View {
        self.environmentObject(service)
    }
}

// MARK: - Testing Convenience Extensions

public extension ErgonomicClient {
    /// Create mock client for testing
    static func mock<StateType: AxiomState & Equatable & Sendable, ActionType: Sendable>(
        initialState: StateType,
        responses: [ActionType: StateType] = [:]
    ) -> ErgonomicClient<StateType, ActionType> {
        return ErgonomicClient<StateType, ActionType>(initialState: initialState) { @Sendable action in
            return responses[action] ?? initialState
        }
    }
}

public extension AxiomObservableContext {
    /// Create test context
    @MainActor
    static func test<T: AxiomObservableContext>() -> T where T: AxiomObservableContext {
        let context = T()
        // Skip activation for testing
        return context
    }
}

public extension ErgonomicNavigationService {
    /// Create test navigation service
    @MainActor
    static func test() -> ErgonomicNavigationService {
        return ErgonomicNavigationService(routes: [:], middleware: [])
    }
}

// MARK: - Performance Optimization Extensions

public extension AxiomObservableContext {
    /// Debounced update notifications
    func debouncedUpdate(delay: TimeInterval = 0.1) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            notifyUpdate()
        }
    }
    
    /// Batched updates
    private static var batchedUpdates: [ObjectIdentifier: [() -> Void]] = [:]
    
    func batchUpdate(_ operation: @escaping () -> Void) {
        let id = ObjectIdentifier(self)
        Self.batchedUpdates[id, default: []].append(operation)
        
        Task {
            try? await Task.sleep(nanoseconds: 16_000_000) // One frame
            let operations = Self.batchedUpdates[id] ?? []
            Self.batchedUpdates[id] = nil
            
            for op in operations {
                op()
            }
            notifyUpdate()
        }
    }
}

// MARK: - Memory Management Extensions

public extension AxiomContext {
    /// Check memory usage
    func memoryFootprint() -> Int {
        return measureMemoryUsage()
    }
    
    /// Clean up resources
    @MainActor
    func cleanup() async {
        if let observableContext = self as? AxiomObservableContext {
            await observableContext.deactivate()
        }
    }
}

public extension ErgonomicClient {
    /// Cleanup client resources
    func cleanup() {
        // Client cleanup implementation would go here
        // terminateStreams() // This method doesn't exist yet
    }
}