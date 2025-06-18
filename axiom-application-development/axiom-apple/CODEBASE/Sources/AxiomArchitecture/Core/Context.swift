import SwiftUI
import Foundation
import Darwin
import AxiomCore

// MARK: - Lifecycle Protocol

/// Universal lifecycle protocol for consistent activation/deactivation across all framework components
public protocol AxiomLifecycle {
    /// Activate the component and prepare it for use
    @MainActor func activate() async throws
    
    /// Deactivate the component and clean up resources
    @MainActor func deactivate() async
}

// MARK: - Context Protocol

/// Core protocol for MainActor-bound coordinators with lifecycle and observation.
/// 
/// Contexts coordinate between Presentations and Clients, managing lifecycle
/// and state observation. They run on MainActor for UI safety.
/// 
/// Requirements:
/// - Must be MainActor-bound for UI coordination
/// - Provides lifecycle methods for resource management
/// - Supports observation through ObservableObject
/// - Memory usage must remain stable after processing actions
@MainActor
public protocol AxiomContext: ObservableObject, AxiomLifecycle, Sendable {
    /// Handle actions from child contexts
    /// Called automatically by the framework when children emit actions
    func handleChildAction<T>(_ action: T, from child: any AxiomContext)
}

// MARK: - Context Extensions

extension AxiomContext {
    /// Default implementation for contexts that don't need activation logic
    @MainActor public func activate() async throws {
        // Default no-op implementation
    }
    
    /// Default implementation for contexts that don't need deactivation logic
    @MainActor public func deactivate() async {
        // Default no-op implementation
    }
    
    /// Default implementation for handling child actions
    public func handleChildAction<T>(_ action: T, from child: any AxiomContext) {
        // Default implementation does nothing
        // Override in contexts to handle specific actions
    }
    
    /// Process multiple actions with stable memory usage
    public func processActions<S: Sequence>(_ actions: S) async where S.Element == Any {
        // Process without retaining actions in memory
        for action in actions {
            // Process action without storing reference
            _ = action
        }
    }
}

// MARK: - Memory Management

/// Options for context memory management
public struct AxiomContextMemoryOptions {
    /// Maximum number of retained states
    public let maxRetainedStates: Int
    
    /// Whether to use weak references for clients
    public let shouldUseWeakClientReferences: Bool
    
    /// Memory warning threshold in bytes
    public let memoryWarningThreshold: Int
    
    public init(
        maxRetainedStates: Int = 10,
        shouldUseWeakClientReferences: Bool = true,
        memoryWarningThreshold: Int = 50_000_000 // 50MB
    ) {
        self.maxRetainedStates = maxRetainedStates
        self.shouldUseWeakClientReferences = shouldUseWeakClientReferences
        self.memoryWarningThreshold = memoryWarningThreshold
    }
}

// MARK: - Observable Context Implementation

/// Observable implementation providing common context behaviors
/// 
/// This class provides:
/// - Lifecycle state management
/// - Automatic observation support
/// - Memory-efficient operation
@MainActor
open class AxiomObservableContext: AxiomContext {
    /// Published property to trigger SwiftUI updates
    @Published private var updateTrigger = UUID()
    
    /// Current lifecycle state
    public private(set) var isActive = false
    
    /// Lifecycle appearance count for idempotency
    private var appearanceCount = 0
    
    /// Weak reference to parent context for child-to-parent communication
    public weak var parentContext: (any AxiomContext)?
    
    /// Child contexts for parent-child relationships
    public private(set) var childContexts: [WeakContextWrapper] = []
    
    public required init() {}
    
    /// Activate the context
    open func activate() async throws {
        guard appearanceCount == 0 else { return }
        appearanceCount += 1
        isActive = true
        await appeared()
    }
    
    /// Deactivate the context
    open func deactivate() async {
        guard isActive else { return }
        isActive = false
        await disappeared()
    }
    
    /// Override point for subclasses to perform appearance logic
    open func appeared() async {
        // Subclasses override to add custom logic
    }
    
    /// Override point for subclasses to perform disappearance logic
    open func disappeared() async {
        // Subclasses override to add custom logic
    }
    
    /// Trigger a UI update
    public func notifyUpdate() {
        updateTrigger = UUID()
    }
    
    /// Override to handle actions from child contexts
    open func handleChildAction<T>(_ action: T, from child: any AxiomContext) {
        // Default implementation does nothing
        // Override in subclasses to handle specific actions
    }
    
    /// Add a child context
    public func addChild(_ child: any AxiomContext) {
        let wrapper = WeakContextWrapper(child)
        childContexts.append(wrapper)
        
        if let observableChild = child as? AxiomObservableContext {
            observableChild.parentContext = self
        }
        
        cleanupDeallocatedChildren()
    }
    
    /// Remove a child context
    public func removeChild(_ child: any AxiomContext) {
        childContexts.removeAll { wrapper in
            wrapper.context === child
        }
        
        if let observableChild = child as? AxiomObservableContext {
            observableChild.parentContext = nil
        }
    }
    
    /// Send action to parent context
    public func sendToParent<T>(_ action: T) async {
        parentContext?.handleChildAction(action, from: self)
    }
    
    /// Clean up deallocated child contexts
    private func cleanupDeallocatedChildren() {
        let beforeCount = childContexts.count
        childContexts.removeAll { $0.context == nil }
        
        if childContexts.count < beforeCount {
            notifyUpdate()
        }
    }
    
    /// Get active child contexts
    public var activeChildren: [any AxiomContext] {
        cleanupDeallocatedChildren()
        return childContexts.compactMap { $0.context }
    }
}

// MARK: - Client Observing Context

/// Observable context that observes a client's state stream
@MainActor
open class AxiomClientObservingContext<C: AxiomClient>: AxiomObservableContext {
    /// The client being observed
    public let client: C
    
    /// Task for state observation
    private var observationTask: Task<Void, Never>?
    
    /// Initialize with a client to observe
    public init(client: C) {
        self.client = client
        super.init()
    }
    
    /// Required initializer - not typically used for AxiomClientObservingContext
    public required init() {
        fatalError("AxiomClientObservingContext must be initialized with a client")
    }
    
    open override func appeared() async {
        await super.appeared()
        startObservation()
    }
    
    open override func disappeared() async {
        await super.disappeared()
        stopObservation()
    }
    
    /// Start observing the client's state
    private func startObservation() {
        observationTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await state in await self.client.stateStream {
                await self.handleStateUpdate(state)
            }
        }
    }
    
    /// Stop observing the client's state
    private func stopObservation() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    /// Handle state updates from the client
    /// Override in subclasses to process state changes
    open func handleStateUpdate(_ state: C.StateType) async {
        notifyUpdate()
    }
}

// MARK: - Weak Reference Support

// WeakContextWrapper is defined in ImplicitActionSubscription.swift

/// Wrapper for weak references to clients
public struct AxiomWeakClient<C: AxiomClient> {
    public weak var client: C?
    
    public init(_ client: C) {
        self.client = client
    }
}

/// Context that manages weak references to prevent retain cycles
@MainActor
open class AxiomWeakReferenceContext<C: AxiomClient>: AxiomObservableContext {
    /// Weakly held clients
    private var weakClients: [AxiomWeakClient<C>] = []
    
    /// Memory management options
    public let memoryOptions: AxiomContextMemoryOptions
    
    /// Initialize with memory options
    public init(memoryOptions: AxiomContextMemoryOptions = AxiomContextMemoryOptions()) {
        self.memoryOptions = memoryOptions
        super.init()
    }
    
    /// Required initializer
    public required init() {
        self.memoryOptions = AxiomContextMemoryOptions()
        super.init()
    }
    
    /// Add a client with weak reference
    public func addClient(_ client: C) {
        if memoryOptions.shouldUseWeakClientReferences {
            weakClients.append(AxiomWeakClient(client))
            cleanupDeallocatedClients()
        }
    }
    
    /// Remove deallocated clients
    private func cleanupDeallocatedClients() {
        let beforeCount = weakClients.count
        weakClients.removeAll { $0.client == nil }
        
        if weakClients.count < beforeCount {
            // Clients were cleaned up
            notifyUpdate()
        }
    }
    
    /// Get active clients
    public var activeClients: [C] {
        cleanupDeallocatedClients()
        return weakClients.compactMap { $0.client }
    }
    
    /// Check if any clients are attached
    public var hasActiveClients: Bool {
        !activeClients.isEmpty
    }
    
    /// Periodic cleanup task
    public func startPeriodicCleanup(interval: Duration = .seconds(30)) {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                self?.cleanupDeallocatedClients()
            }
        }
    }
}

// MARK: - Error Handling Context

/// Context that provides error handling capabilities
@MainActor
open class AxiomErrorHandlingContext: AxiomObservableContext {
    /// Errors encountered during operation
    @Published public private(set) var errors: [any Error] = []
    
    /// Last error encountered
    public var lastError: (any Error)? {
        errors.last
    }
    
    /// Count of handled errors
    public var errorCount: Int {
        errors.count
    }
    
    /// Handle an error
    public func handleError(_ error: any Error) {
        errors.append(error)
        notifyUpdate()
    }
    
    /// Clear all errors
    public func clearErrors() {
        errors.removeAll()
        notifyUpdate()
    }
}

// MARK: - Context Manager Protocol

/// Protocol for managing multiple contexts
public protocol AxiomContextManager: Actor {
    /// Create a context for a presentation
    func createContext<P: AxiomPresentation>(
        for presentation: P.Type
    ) async -> P.ContextType
    
    /// Register a context
    func register<C: AxiomContext>(_ context: C, for key: String) async
    
    /// Retrieve a registered context
    func context<C: AxiomContext>(for key: String, as type: C.Type) async -> C?
    
    /// Deactivate all contexts
    func deactivateAll() async
}

// MARK: - Performance Monitoring

/// Extension for monitoring context performance
extension AxiomContext {
    /// Measure memory usage for the context
    public func measureMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    /// Check if memory usage is within acceptable bounds
    public func isMemoryStable(baseline: Int, tolerance: Double = 0.1) -> Bool {
        let current = measureMemoryUsage()
        let percentageChange = abs(Double(current - baseline)) / Double(baseline)
        return percentageChange <= tolerance
    }
}

// MARK: - Observation Optimization

/// Optimized observation with batching support
@MainActor
public final class AxiomBatchingContext: AxiomObservableContext {
    /// Batch size for updates
    public let batchSize: Int
    
    /// Pending updates
    private var pendingUpdates: [Any] = []
    
    /// Batch processing timer
    private var batchTimer: Task<Void, Never>?
    
    public init(batchSize: Int = 10) {
        self.batchSize = batchSize
        super.init()
    }
    
    /// Required initializer
    public required init() {
        self.batchSize = 10
        super.init()
    }
    
    /// Queue an update for batching
    public func queueUpdate(_ update: Any) {
        pendingUpdates.append(update)
        
        if pendingUpdates.count >= batchSize {
            processBatch()
        } else if batchTimer == nil {
            startBatchTimer()
        }
    }
    
    private func startBatchTimer() {
        batchTimer = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(16)) // One frame
            self?.processBatch()
        }
    }
    
    private func processBatch() {
        batchTimer?.cancel()
        batchTimer = nil
        
        guard !pendingUpdates.isEmpty else { return }
        
        // Process all pending updates
        _ = pendingUpdates
        pendingUpdates.removeAll()
        
        // Notify once for all updates
        notifyUpdate()
    }
}

// MARK: - Presentation Protocol (Referenced)

/// Protocol for presentations (will be defined separately)
public protocol AxiomPresentation: View {
    associatedtype ContextType: AxiomContext
    var context: ContextType { get }
}

// MARK: - Context Lifecycle Management

/// Manager for context lifecycle coordination
@MainActor
public final class AxiomContextLifecycleManager {
    /// Active contexts
    private var contexts: [ObjectIdentifier: any AxiomContext] = [:]
    
    /// Register a context
    public func register<C: AxiomContext>(_ context: C) {
        let id = ObjectIdentifier(C.self)
        contexts[id] = context
    }
    
    /// Deregister a context
    public func deregister<C: AxiomContext>(_ contextType: C.Type) {
        let id = ObjectIdentifier(contextType)
        contexts.removeValue(forKey: id)
    }
    
    /// Activate all contexts
    public func activateAll() async {
        for (_, context) in contexts {
            try? await context.activate()
        }
    }
    
    /// Deactivate all contexts
    public func deactivateAll() async {
        for (_, context) in contexts {
            await context.deactivate()
        }
    }
    
    /// Get memory usage across all contexts
    public func totalMemoryUsage() -> Int {
        contexts.values.reduce(0) { total, context in
            total + context.measureMemoryUsage()
        }
    }
}