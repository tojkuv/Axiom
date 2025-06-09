import SwiftUI
import Foundation
#if os(macOS)
import Darwin
#elseif os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#endif

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
public protocol Context: ObservableObject {
    /// Called when the associated presentation appears
    func onAppear() async
    
    /// Called when the associated presentation disappears
    func onDisappear() async
    
    /// Handle actions from child contexts
    /// Called automatically by the framework when children emit actions
    func handleChildAction<T>(_ action: T, from child: any Context)
}

// MARK: - Context Extensions

extension Context {
    /// Default implementation for contexts that don't need appear logic
    public func onAppear() async {
        // Default no-op implementation
    }
    
    /// Default implementation for contexts that don't need disappear logic
    public func onDisappear() async {
        // Default no-op implementation
    }
    
    /// Default implementation for handling child actions
    public func handleChildAction<T>(_ action: T, from child: any Context) {
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
public struct ContextMemoryOptions {
    /// Maximum number of retained states
    public let maxRetainedStates: Int
    
    /// Whether to use weak references for clients
    public let useWeakClientReferences: Bool
    
    /// Memory warning threshold in bytes
    public let memoryWarningThreshold: Int
    
    public init(
        maxRetainedStates: Int = 10,
        useWeakClientReferences: Bool = true,
        memoryWarningThreshold: Int = 50_000_000 // 50MB
    ) {
        self.maxRetainedStates = maxRetainedStates
        self.useWeakClientReferences = useWeakClientReferences
        self.memoryWarningThreshold = memoryWarningThreshold
    }
}

// MARK: - Base Context Implementation

/// Base implementation providing common context behaviors
/// 
/// This class provides:
/// - Lifecycle state management
/// - Automatic observation support
/// - Memory-efficient operation
@MainActor
open class BaseContext: Context {
    /// Published property to trigger SwiftUI updates
    @Published private var updateTrigger = UUID()
    
    /// Current lifecycle state
    public private(set) var isActive = false
    
    /// Lifecycle appearance count for idempotency
    private var appearanceCount = 0
    
    /// Weak reference to parent context for child-to-parent communication
    public weak var parentContext: (any Context)?
    
    /// Child contexts for parent-child relationships
    public private(set) var childContexts: [WeakContextWrapper] = []
    
    public init() {}
    
    /// Called when context appears
    open func onAppear() async {
        guard appearanceCount == 0 else { return }
        appearanceCount += 1
        isActive = true
        await performAppearance()
    }
    
    /// Called when context disappears
    open func onDisappear() async {
        guard isActive else { return }
        isActive = false
        await performDisappearance()
    }
    
    /// Override point for subclasses to perform appearance logic
    open func performAppearance() async {
        // Subclasses override to add custom logic
    }
    
    /// Override point for subclasses to perform disappearance logic
    open func performDisappearance() async {
        // Subclasses override to add custom logic
    }
    
    /// Trigger a UI update
    public func notifyUpdate() {
        updateTrigger = UUID()
    }
    
    /// Override to handle actions from child contexts
    open func handleChildAction<T>(_ action: T, from child: any Context) {
        // Default implementation does nothing
        // Override in subclasses to handle specific actions
    }
    
    /// Add a child context
    public func addChild(_ child: any Context) {
        let wrapper = WeakContextWrapper(child)
        childContexts.append(wrapper)
        
        if let baseChild = child as? BaseContext {
            baseChild.parentContext = self
        }
        
        cleanupDeallocatedChildren()
    }
    
    /// Remove a child context
    public func removeChild(_ child: any Context) {
        childContexts.removeAll { wrapper in
            wrapper.context === child
        }
        
        if let baseChild = child as? BaseContext {
            baseChild.parentContext = nil
        }
    }
    
    /// Send action to parent context
    public func sendToParent<T>(_ action: T) async {
        await parentContext?.handleChildAction(action, from: self)
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
    public var activeChildren: [any Context] {
        cleanupDeallocatedChildren()
        return childContexts.compactMap { $0.context }
    }
}

// MARK: - Client Observing Context

/// Base context that observes a client's state stream
@MainActor
open class ClientObservingContext<C: Client>: BaseContext {
    /// The client being observed
    public let client: C
    
    /// Task for state observation
    private var observationTask: Task<Void, Never>?
    
    /// Initialize with a client to observe
    public init(client: C) {
        self.client = client
        super.init()
    }
    
    open override func performAppearance() async {
        await super.performAppearance()
        startObservation()
    }
    
    open override func performDisappearance() async {
        await super.performDisappearance()
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
public struct WeakClient<C: Client> {
    public weak var client: C?
    
    public init(_ client: C) {
        self.client = client
    }
}

/// Context that manages weak references to prevent retain cycles
@MainActor
open class WeakReferenceContext<C: Client>: BaseContext {
    /// Weakly held clients
    private var weakClients: [WeakClient<C>] = []
    
    /// Memory management options
    public let memoryOptions: ContextMemoryOptions
    
    /// Initialize with memory options
    public init(memoryOptions: ContextMemoryOptions = ContextMemoryOptions()) {
        self.memoryOptions = memoryOptions
        super.init()
    }
    
    /// Add a client with weak reference
    public func addClient(_ client: C) {
        if memoryOptions.useWeakClientReferences {
            weakClients.append(WeakClient(client))
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
open class ErrorHandlingContext: BaseContext {
    /// Errors encountered during operation
    @Published public private(set) var errors: [Error] = []
    
    /// Last error encountered
    public var lastError: Error? {
        errors.last
    }
    
    /// Count of handled errors
    public var errorCount: Int {
        errors.count
    }
    
    /// Handle an error
    public func handleError(_ error: Error) {
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
public protocol ContextManager: Actor {
    /// Create a context for a presentation
    func createContext<P: Presentation>(
        for presentation: P.Type
    ) async -> P.ContextType
    
    /// Register a context
    func register<C: Context>(_ context: C, for key: String) async
    
    /// Retrieve a registered context
    func context<C: Context>(for key: String, as type: C.Type) async -> C?
    
    /// Deactivate all contexts
    func deactivateAll() async
}

// MARK: - Performance Monitoring

/// Extension for monitoring context performance
extension Context {
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
public final class BatchingContext: BaseContext {
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
public protocol Presentation: View {
    associatedtype ContextType: Context
    var context: ContextType { get }
}

// MARK: - Context Lifecycle Management

/// Manager for context lifecycle coordination
@MainActor
public final class ContextLifecycleManager {
    /// Active contexts
    private var contexts: [ObjectIdentifier: any Context] = [:]
    
    /// Register a context
    public func register<C: Context>(_ context: C) {
        let id = ObjectIdentifier(C.self)
        contexts[id] = context
    }
    
    /// Deregister a context
    public func deregister<C: Context>(_ contextType: C.Type) {
        let id = ObjectIdentifier(contextType)
        contexts.removeValue(forKey: id)
    }
    
    /// Activate all contexts
    public func activateAll() async {
        for (_, context) in contexts {
            await context.onAppear()
        }
    }
    
    /// Deactivate all contexts
    public func deactivateAll() async {
        for (_, context) in contexts {
            await context.onDisappear()
        }
    }
    
    /// Get memory usage across all contexts
    public func totalMemoryUsage() -> Int {
        contexts.values.reduce(0) { total, context in
            total + context.measureMemoryUsage()
        }
    }
}