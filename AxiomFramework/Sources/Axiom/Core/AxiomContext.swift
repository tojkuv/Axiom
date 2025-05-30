import Foundation
import SwiftUI
import Combine

// MARK: - AxiomContext Protocol

/// The core protocol for contexts that orchestrate clients and provide SwiftUI integration
@MainActor
public protocol AxiomContext: ObservableObject {
    associatedtype View: AxiomView where View.Context == Self
    associatedtype Clients: ClientDependencies
    
    /// The clients managed by this context
    var clients: Clients { get }
    
    /// The intelligence system for this context
    var intelligence: AxiomIntelligence { get }
    
    // MARK: Resource Access
    
    /// Gets the capability manager for this context
    func capabilityManager() async throws -> CapabilityManager
    
    /// Gets the performance monitor for this context
    func performanceMonitor() async throws -> PerformanceMonitor
    
    // MARK: Lifecycle
    
    /// Called when the associated view appears
    func onAppear() async
    
    /// Called when the associated view disappears
    func onDisappear() async
    
    /// Called when a client's state changes
    func onClientStateChange<T: AxiomClient>(_ client: T) async
    
    // MARK: Error Handling
    
    /// Handles errors that occur within the context
    func handleError(_ error: any AxiomError) async
    
    // MARK: Analytics
    
    /// Tracks an analytics event
    func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async
}

// MARK: - Default Context State

/// Default implementation of context state
@MainActor
public class DefaultContextState: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var lastError: (any AxiomError)?
    
    public init() {}
}

// MARK: - AxiomContext Extensions

extension AxiomContext {
    /// Configures error handling for the context
    public func configureErrorHandling(_ handler: @escaping (any AxiomError) async -> Void) async {
        // Configure automatic error handling
        // In a full implementation, this would set up error observation
    }
}

// MARK: - Default Resource Access Implementation

/// ENHANCED: Default implementations for resource access methods
/// Eliminates verbose global singleton access in every context
extension AxiomContext {
    
    /// Default implementation using global capability manager
    /// Contexts can override this if they need custom capability management
    public func capabilityManager() async throws -> CapabilityManager {
        return await GlobalCapabilityManager.shared.getManager()
    }
    
    /// Default implementation using global performance monitor
    /// Contexts can override this if they need custom performance monitoring
    public func performanceMonitor() async throws -> PerformanceMonitor {
        return await GlobalPerformanceMonitor.shared.getMonitor()
    }
}

// MARK: - Additional Context Convenience Methods

/// ENHANCED: Additional convenience methods for common context operations
extension AxiomContext {
    
    /// Quick capability validation without exposing manager details
    public func validateCapability(_ capability: Capability) async throws {
        let manager = try await capabilityManager()
        try await manager.validate(capability)
    }
    
    /// Validate multiple capabilities at once
    public func validateCapabilities(_ capabilities: [Capability]) async throws {
        let manager = try await capabilityManager()
        try await manager.validateAll(capabilities)
    }
    
    /// Record a performance metric without exposing monitor details
    public func recordPerformanceMetric(_ metric: PerformanceMetric) async {
        do {
            let monitor = try await performanceMonitor()
            await monitor.recordMetric(metric)
        } catch {
            // Gracefully handle performance monitoring failures
            print("⚠️ Performance monitoring unavailable: \(error)")
        }
    }
    
    /// Start a performance operation with automatic cleanup
    public func withPerformanceTracking<T>(
        operation: String,
        category: PerformanceCategory,
        work: () async throws -> T
    ) async rethrows -> T {
        do {
            let monitor = try await performanceMonitor()
            let token = await monitor.startOperation(operation, category: category)
            defer {
                Task {
                    await monitor.endOperation(token)
                }
            }
            return try await work()
        } catch {
            // If performance monitoring fails, still execute the work
            return try await work()
        }
    }
}

// MARK: - Client Container Convenience Methods

/// ENHANCED: Convenience methods for working with generic client containers
/// Eliminates the need to access clients.client1, clients.client2, etc.
/// 
/// Note: Due to Swift's limitations with associated types in extensions,
/// these convenience methods are implemented as protocol extensions on the container types themselves

extension AxiomContext where Clients == NamedClientContainer {
    /// Get a client by name with type safety
    public func client<T: AxiomClient>(_ name: String, as type: T.Type) -> T? {
        return clients.get(name, as: type)
    }
}

// MARK: - Automatic Analytics Tracking

/// ENHANCED: Automatic analytics tracking for common context actions
/// Eliminates the need to manually call trackAnalyticsEvent in every action method
extension AxiomContext {
    
    /// Execute an action with automatic analytics tracking
    /// Tracks the action name and result automatically
    public func withAnalytics<T>(
        action: String,
        parameters: [String: Any] = [:],
        work: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        
        do {
            let result = try await work()
            
            // Track successful action
            let duration = Date().timeIntervalSince(startTime)
            var finalParameters = parameters
            finalParameters["duration_ms"] = Int(duration * 1000)
            finalParameters["success"] = true
            
            await trackAnalyticsEvent(action, parameters: finalParameters)
            return result
        } catch {
            // Track failed action
            let duration = Date().timeIntervalSince(startTime)
            var finalParameters = parameters
            finalParameters["duration_ms"] = Int(duration * 1000)
            finalParameters["success"] = false
            finalParameters["error"] = String(describing: error)
            
            await trackAnalyticsEvent("\(action)_failed", parameters: finalParameters)
            throw error
        }
    }
    
    /// Execute an action with automatic analytics tracking and state capture
    /// Automatically includes before/after state values in analytics
    public func withAnalyticsAndState<T, State>(
        action: String,
        stateKeyPath: KeyPath<Self, State>,
        parameters: [String: Any] = [:],
        work: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let stateBefore = self[keyPath: stateKeyPath]
        
        do {
            let result = try await work()
            
            // Track successful action with state changes
            let stateAfter = self[keyPath: stateKeyPath]
            let duration = Date().timeIntervalSince(startTime)
            
            var finalParameters = parameters
            finalParameters["duration_ms"] = Int(duration * 1000)
            finalParameters["success"] = true
            finalParameters["state_before"] = String(describing: stateBefore)
            finalParameters["state_after"] = String(describing: stateAfter)
            
            await trackAnalyticsEvent(action, parameters: finalParameters)
            return result
        } catch {
            // Track failed action
            let duration = Date().timeIntervalSince(startTime)
            var finalParameters = parameters
            finalParameters["duration_ms"] = Int(duration * 1000)
            finalParameters["success"] = false
            finalParameters["error"] = String(describing: error)
            finalParameters["state_before"] = String(describing: stateBefore)
            
            await trackAnalyticsEvent("\(action)_failed", parameters: finalParameters)
            throw error
        }
    }
    
    /// Track a simple user action without return value
    public func trackAction(
        _ action: String,
        parameters: [String: Any] = [:]
    ) async {
        await withAnalytics(action: action, parameters: parameters) {
            // No-op - just tracking the action
        }
    }
    
    /// Track a user interaction with automatic UI element identification
    public func trackInteraction(
        element: String,
        action: String = "tap",
        parameters: [String: Any] = [:]
    ) async {
        var finalParameters = parameters
        finalParameters["element"] = element
        await trackAction("\(element)_\(action)", parameters: finalParameters)
    }
    
    /// Track a business event with automatic context information
    public func trackBusinessEvent(
        event: String,
        value: Double? = nil,
        parameters: [String: Any] = [:]
    ) async {
        var finalParameters = parameters
        finalParameters["context_type"] = String(describing: type(of: self))
        if let value = value {
            finalParameters["value"] = value
        }
        await trackAction("business_\(event)", parameters: finalParameters)
    }
}

// MARK: - Analytics Convenience Macros

/// Common analytics event patterns that can be used directly
extension AxiomContext {
    
    /// Track view lifecycle events automatically
    public func trackViewAppeared() async {
        await trackAction("view_appeared", parameters: [
            "view_type": String(describing: type(of: self))
        ])
    }
    
    public func trackViewDisappeared() async {
        await trackAction("view_disappeared", parameters: [
            "view_type": String(describing: type(of: self))
        ])
    }
    
    /// Track error events with automatic context
    public func trackError(
        _ error: any AxiomError,
        context: String? = nil
    ) async {
        await trackAction("error_occurred", parameters: [
            "error_category": error.category.rawValue,
            "error_severity": error.severity.rawValue,
            "error_message": error.userMessage,
            "context": context ?? String(describing: type(of: self))
        ])
    }
    
    /// Track performance milestones
    public func trackPerformanceMilestone(
        _ milestone: String,
        duration: TimeInterval? = nil,
        parameters: [String: Any] = [:]
    ) async {
        var finalParameters = parameters
        if let duration = duration {
            finalParameters["duration_ms"] = Int(duration * 1000)
        }
        await trackAction("performance_\(milestone)", parameters: finalParameters)
    }
}