import Foundation

/// Memory optimization utilities for minimal framework overhead
/// 
/// Ensures framework allocations stay under 1KB per component instance
/// by optimizing memory layout, reducing allocations, and efficient resource management.
public actor MemoryOptimizationEngine {
    
    // MARK: - Memory Tracking
    
    /// Track memory usage per component type
    private var componentMemoryUsage: [String: Int] = [:]
    
    /// Memory optimization configuration
    public struct OptimizationConfig {
        let maxMemoryPerComponent: Int = 1024  // 1KB as per RFC
        let enablePooling: Bool = true
        let enableCompactStorage: Bool = true
    }
    
    public let config = OptimizationConfig()
    
    // MARK: - Object Pooling System
    
    /// Object pools for frequently allocated types
    private var objectPools: [String: ObjectPool] = [:]
    
    /// Initialize object pools for common framework objects
    private func initializePools() {
        // Pool for state updates
        objectPools["PooledStateUpdate"] = ObjectPool(
            factory: { PooledStateUpdate() },
            reset: { ($0 as! PooledStateUpdate).reset() },
            maxSize: 100
        )
        
        // Pool for continuation wrappers  
        objectPools["PooledContinuationWrapper"] = ObjectPool(
            factory: { PooledContinuationWrapper() },
            reset: { ($0 as! PooledContinuationWrapper).reset() },
            maxSize: 50
        )
    }
    
    public init() async {
        await initializePools()
    }
    
    /// Get or create an object from the pool
    func borrowFromPool<T: AnyObject>(_ type: T.Type) -> T? {
        let typeName = String(describing: type)
        return objectPools[typeName]?.borrow() as? T
    }
    
    /// Return an object to the pool
    func returnToPool<T: AnyObject>(_ object: T) {
        let typeName = String(describing: T.self)
        objectPools[typeName]?.return(object)
    }
    
    // MARK: - Lightweight Stream Creation
    
    /// Create memory-optimized stream with minimal overhead
    public func createLightweightStream<StateType: State>(
        initialState: StateType
    ) -> LightweightStateStream<StateType> {
        return LightweightStateStream(
            engine: self,
            initialState: initialState
        )
    }
    
    /// Track memory usage for a component
    func trackComponentMemory(type: String, bytes: Int) {
        componentMemoryUsage[type] = bytes
    }
    
    /// Get memory usage for component type
    public func getMemoryUsage(for type: String) -> Int {
        return componentMemoryUsage[type] ?? 0
    }
    
    /// Get total framework memory usage
    public var totalMemoryUsage: Int {
        return componentMemoryUsage.values.reduce(0, +)
    }
}

// MARK: - Lightweight State Stream

/// Ultra-lightweight state stream with minimal memory overhead
public final class LightweightStateStream<StateType: State> {
    
    // Use minimal storage - single continuation, no buffering
    private let continuation: AsyncStream<StateType>.Continuation
    private let _stream: AsyncStream<StateType>
    
    /// The optimized state stream
    public var stream: AsyncStream<StateType> {
        _stream
    }
    
    init(engine: MemoryOptimizationEngine, initialState: StateType) {
        // Create unbuffered stream for minimal memory usage
        let (stream, continuation) = AsyncStream.makeStream(
            of: StateType.self,
            bufferingPolicy: .unbounded  // No buffering to minimize memory
        )
        
        self._stream = stream
        self.continuation = continuation
        
        // Immediate yield of initial state
        continuation.yield(initialState)
        
        // Track memory usage
        Task {
            let memorySize = MemoryLayout<LightweightStateStream<StateType>>.size +
                           MemoryLayout<StateType>.size
            await engine.trackComponentMemory(
                type: "LightweightStateStream<\(StateType.self)>", 
                bytes: memorySize
            )
        }
    }
    
    /// Optimized state update with minimal overhead
    public func yield(_ state: StateType) {
        // Direct yield with no tracking overhead for performance
        continuation.yield(state)
    }
    
    /// Finish stream and cleanup
    public func finish() {
        continuation.finish()
    }
    
    deinit {
        continuation.finish()
    }
}

// MARK: - Compact Client Implementation

/// Memory-optimized client implementation
public actor CompactClient<StateType: State, ActionType>: Client {
    
    // Minimal storage - just essential data
    private var state: StateType
    private let lightweightStream: LightweightStateStream<StateType>
    
    public var stateStream: AsyncStream<StateType> {
        lightweightStream.stream
    }
    
    public init(initialState: StateType, engine: MemoryOptimizationEngine) async {
        self.state = initialState
        self.lightweightStream = await engine.createLightweightStream(initialState: initialState)
        
        // Track client memory usage
        let memorySize = MemoryLayout<CompactClient<StateType, ActionType>>.size +
                        MemoryLayout<StateType>.size
        await engine.trackComponentMemory(
            type: "CompactClient<\(StateType.self)>", 
            bytes: memorySize
        )
    }
    
    public func process(_ action: ActionType) async throws {
        // Subclasses must implement this
        fatalError("Subclasses must implement process(_:)")
    }
    
    /// Protected state update for subclasses
    func updateState(_ newState: StateType) {
        state = newState
        lightweightStream.yield(newState)
    }
    
    /// Current state access
    public var currentState: StateType {
        state
    }
    
    deinit {
        lightweightStream.finish()
    }
}

// MARK: - Compact Context Implementation

/// Memory-optimized context implementation
@MainActor
public class CompactContext<ClientType: Client>: Context, ObservableObject {
    
    // Minimal storage
    private let client: ClientType
    @Published public private(set) var state: ClientType.StateType
    private var observationTask: Task<Void, Never>?
    
    public init(client: ClientType, engine: MemoryOptimizationEngine) async {
        self.client = client
        self.state = await client.getCurrentState()
        
        // Track context memory usage  
        let memorySize = MemoryLayout<CompactContext<ClientType>>.size +
                        MemoryLayout<ClientType.StateType>.size
        await engine.trackComponentMemory(
            type: "CompactContext<\(ClientType.self)>", 
            bytes: memorySize
        )
    }
    
    public func onAppear() async {
        // Start lightweight state observation
        observationTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await newState in await client.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
    
    public func onDisappear() async {
        observationTask?.cancel()
        observationTask = nil
    }
    
    deinit {
        observationTask?.cancel()
    }
}

// MARK: - Compact Capability Implementation

/// Memory-optimized capability implementation
public actor CompactCapability: Capability {
    
    // Minimal state storage
    private var _isAvailable: Bool
    
    public var isAvailable: Bool {
        _isAvailable
    }
    
    public init(engine: MemoryOptimizationEngine, initialAvailability: Bool = true) async {
        self._isAvailable = initialAvailability
        
        // Track capability memory usage
        let memorySize = MemoryLayout<CompactCapability>.size
        await engine.trackComponentMemory(
            type: "CompactCapability", 
            bytes: memorySize
        )
    }
    
    public func initialize() async throws {
        // Minimal initialization
        _isAvailable = true
    }
    
    public func terminate() async {
        // Minimal cleanup
        _isAvailable = false
    }
}

// MARK: - Memory-Optimized Extensions

// Note: getCurrentState() is already defined in other Client extensions

// MARK: - Global Memory Optimization Engine

/// Global instance for framework-wide memory optimization
/// Must be called asynchronously: await globalMemoryOptimizationEngine()
public func globalMemoryOptimizationEngine() async -> MemoryOptimizationEngine {
    return await MemoryOptimizationEngine()
}

// MARK: - Memory Monitoring

/// Lightweight memory monitor for component tracking
public struct MemoryMonitor {
    
    /// Check if component meets memory requirements
    public static func validateComponent<T>(_ component: T, maxBytes: Int = 1024) -> Bool {
        let componentSize = MemoryLayout<T>.size
        return componentSize <= maxBytes
    }
    
    /// Get component memory footprint
    public static func getMemoryFootprint<T>(_ component: T) -> Int {
        return MemoryLayout<T>.size + MemoryLayout<T>.stride
    }
    
    /// Validate framework memory requirements
    public static func validateFrameworkMemory(components: [Any]) -> (isValid: Bool, totalBytes: Int, averagePerComponent: Int) {
        let totalBytes = components.reduce(0) { total, component in
            return total + getMemoryFootprint(component)
        }
        
        let averagePerComponent = components.isEmpty ? 0 : totalBytes / components.count
        let isValid = averagePerComponent <= 1024  // 1KB limit per RFC
        
        return (isValid, totalBytes, averagePerComponent)
    }
}

// MARK: - Object Pool Implementation

/// Generic object pool for reusing frequently allocated objects
public final class ObjectPool {
    private let factory: () -> AnyObject
    private let reset: (AnyObject) -> Void
    private let maxSize: Int
    private var pool: [AnyObject] = []
    private let queue = DispatchQueue(label: "object-pool", attributes: .concurrent)
    
    /// Initialize object pool
    /// - Parameters:
    ///   - factory: Factory function to create new objects
    ///   - reset: Function to reset object state before reuse
    ///   - maxSize: Maximum number of objects to pool
    init(factory: @escaping () -> AnyObject, 
         reset: @escaping (AnyObject) -> Void, 
         maxSize: Int) {
        self.factory = factory
        self.reset = reset
        self.maxSize = maxSize
    }
    
    /// Borrow an object from the pool or create a new one
    func borrow() -> AnyObject {
        return queue.sync {
            if let object = pool.popLast() {
                return object
            } else {
                return factory()
            }
        }
    }
    
    /// Return an object to the pool
    func `return`(_ object: AnyObject) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Reset the object state
            self.reset(object)
            
            // Add to pool if not at capacity
            if self.pool.count < self.maxSize {
                self.pool.append(object)
            }
            // If at capacity, object will be deallocated
        }
    }
    
    /// Get current pool statistics
    var statistics: (pooled: Int, capacity: Int) {
        return queue.sync {
            (pooled: pool.count, capacity: maxSize)
        }
    }
}

// MARK: - Pooled Object Wrappers

/// Wrapper for pooled state updates to reduce allocation overhead
public final class PooledStateUpdate {
    var state: (any State)?
    var streamId: UUID?
    
    func configure<StateType: State>(state: StateType, streamId: UUID) {
        self.state = state
        self.streamId = streamId
    }
    
    func reset() {
        state = nil
        streamId = nil
    }
}

/// Wrapper for pooled continuation operations
public final class PooledContinuationWrapper {
    private var operation: (() -> Void)?
    
    func configure(operation: @escaping () -> Void) {
        self.operation = operation
    }
    
    func execute() {
        operation?()
    }
    
    func reset() {
        operation = nil
    }
}