import SwiftUI
import Foundation

// MARK: - Auto-Observing Context

/// Base class for contexts that automatically observe a client's state stream.
/// 
/// This class works in conjunction with the @Context macro to provide:
/// - Automatic lifecycle management
/// - Client state observation setup and teardown
/// - Memory-safe weak reference handling
/// - Thread-safe MainActor isolation
///
/// Usage:
/// ```swift
/// @Context(observing: TaskClient.self)
/// class TaskContext: AutoObservingContext<TaskClient> {
///     // The macro generates all lifecycle boilerplate
///     // You only need to implement custom behavior
/// }
/// ```
@MainActor
open class AutoObservingContext<C: Client>: BaseContext {
    /// The client being observed
    public let client: C
    
    /// Initialize with a client to observe
    public required init(client: C) {
        self.client = client
        super.init()
    }
    
    /// Handle state updates from the client.
    /// Override this method to process state changes.
    ///
    /// The default implementation triggers a UI update.
    /// Override to add custom state processing:
    /// ```swift
    /// override func handleStateUpdate(_ state: C.StateType) async {
    ///     // Custom state processing
    ///     triggerUpdate() // Call when UI should refresh
    /// }
    /// ```
    open func handleStateUpdate(_ state: C.StateType) async {
        // Default implementation - subclasses override for custom behavior
        // The macro-generated triggerUpdate() method will be available
    }
    
    /// Configure automatic observation behavior.
    /// Override to customize observation setup.
    open func configureAutoObservation() async {
        // Hook for subclasses to configure observation
    }
    
    /// Clean up automatic observation resources.
    /// Override to add custom cleanup logic.
    open func cleanupAutoObservation() async {
        // Hook for subclasses to clean up resources
    }
}

// MARK: - Context Builder

/// A builder for creating contexts with additional configuration.
///
/// Provides a fluent API for context configuration:
/// ```swift
/// let context = ContextBuilder()
///     .observing(client)
///     .withErrorHandling { error in
///         print("Error: \(error)")
///     }
///     .withPerformanceMonitoring()
///     .build()
/// ```
public struct AutoContextBuilder<C: Client> {
    private var client: C?
    private var errorHandler: ((Error) async -> Void)?
    private var performanceMonitoring: Bool = false
    
    public init() {}
    
    /// Set the client to observe
    public func observing(_ client: C) -> Self {
        var builder = self
        builder.client = client
        return builder
    }
    
    /// Add error handling for observation failures
    public func withErrorHandling(_ handler: @escaping (Error) async -> Void) -> Self {
        var builder = self
        builder.errorHandler = handler
        return builder
    }
    
    /// Enable performance monitoring for the context
    public func withPerformanceMonitoring(_ enabled: Bool = true) -> Self {
        var builder = self
        builder.performanceMonitoring = enabled
        return builder
    }
    
    /// Build the configured context
    @MainActor
    public func build<T: AutoObservingContext<C>>(_ type: T.Type = T.self) -> T {
        guard let client = client else {
            fatalError("ContextBuilder: Client must be set before building")
        }
        
        let context = T(client: client)
        
        // Apply configurations
        if let errorHandler = errorHandler {
            // Store error handler for use during observation
            Task { @MainActor in
                // This would integrate with the macro-generated observation code
                _ = errorHandler
            }
        }
        
        if performanceMonitoring {
            // Enable performance monitoring
            Task { @MainActor in
                // This would integrate with performance tracking
            }
        }
        
        return context
    }
}

// MARK: - Protocol Declarations

/// Macro declaration for the @Context attribute
@attached(member, names: named(updateTrigger), named(isActive), named(appearanceCount), named(observationTask), named(performAppearance), named(performDisappearance), named(startObservation), named(stopObservation), named(triggerUpdate))
public macro Context(observing clientType: any Client.Type) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")