import Foundation

// MARK: - Weak Observer Storage

/// A thread-safe weak reference wrapper for storing observers without creating retain cycles
/// This is used internally by AxiomClient implementations to manage observer references
public final class WeakObserver: @unchecked Sendable {
    private let lock = NSLock()
    private weak var _context: (any AxiomContext)?
    
    /// The unique identifier for this observer
    public let id: ObjectIdentifier
    
    /// The weakly held context
    public var context: (any AxiomContext)? {
        lock.lock()
        defer { lock.unlock() }
        return _context
    }
    
    /// Initialize with a context to observe
    public init(context: any AxiomContext) {
        self.id = ObjectIdentifier(context)
        self._context = context
    }
}

// MARK: - Observer Notification Protocol

/// Protocol for types that can receive state change notifications
/// This provides a simplified observer pattern for state management
@MainActor
public protocol StateChangeObserver: AnyObject {
    /// Called when the observed state changes
    func stateDidChange()
}

// MARK: - Thread-Safe Observer Collection

/// A thread-safe collection for managing weak observer references
/// Automatically cleans up deallocated observers during iteration
public actor ObserverCollection {
    private var observers: [WeakObserver] = []
    
    /// Add an observer to the collection
    public func add(_ context: any AxiomContext) {
        // Check if already exists to prevent duplicates
        let exists = observers.contains { $0.id == ObjectIdentifier(context) }
        if !exists {
            observers.append(WeakObserver(context: context))
        }
    }
    
    /// Remove an observer from the collection
    public func remove(_ context: any AxiomContext) {
        let id = ObjectIdentifier(context)
        observers.removeAll { $0.id == id }
    }
    
    /// Remove all observers
    public func removeAll() {
        observers.removeAll()
    }
    
    /// Get the current count of valid observers
    public var count: Int {
        observers.filter { $0.context != nil }.count
    }
    
    /// Notify all valid observers and clean up deallocated ones
    public func notifyAll(_ notification: @Sendable @MainActor (any AxiomContext) async -> Void) async {
        // Clean up nil references
        observers = observers.filter { $0.context != nil }
        
        // Notify remaining observers
        for observer in observers {
            if let context = observer.context {
                await notification(context)
            }
        }
    }
}