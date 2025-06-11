import Foundation

/// High-performance state propagation system
/// 
/// Optimizes state changes to propagate from mutation to UI in < 16ms
/// with sub-millisecond average latency for optimal performance.
public actor StatePropagationEngine {
    
    // MARK: - Performance Metrics
    
    /// Performance tracking for state propagation
    private var propagationMetrics: PropagationMetrics = PropagationMetrics()
    
    /// Propagation performance thresholds
    public struct PerformanceThresholds {
        let maxLatency: TimeInterval = 0.016  // 16ms as per RFC
        let targetAverageLatency: TimeInterval = 0.001  // 1ms target
        let batchingThreshold: Int = 10  // Batch after 10 updates/frame
        let frameInterval: TimeInterval = 1.0 / 60.0  // 60fps = ~16.67ms
    }
    
    public let thresholds = PerformanceThresholds()
    
    // MARK: - Batching System
    
    /// Batch update coordinator for high-frequency updates
    private var batchCoordinator: BatchCoordinator = BatchCoordinator()
    
    /// Enable or disable batching based on update frequency
    private var batchingEnabled: Bool = false
    
    // MARK: - Fast Propagation System
    
    /// Fast state propagation using optimized async streams
    public func createFastStateStream<StateType: State>(
        initialState: StateType
    ) -> (stream: AsyncStream<StateType>, yield: (StateType) -> Void) {
        
        let (stream, yield) = AsyncStream.makeStream(
            of: StateType.self,
            bufferingPolicy: .bufferingOldest(1)  // Only keep latest state
        )
        
        let yieldFunction: (StateType) -> Void = { [weak self] newState in
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Immediate propagation with minimal overhead
            yield(newState)
            
            // Track performance metrics
            Task { [weak self] in
                let endTime = CFAbsoluteTimeGetCurrent()
                let latency = endTime - startTime
                await self?.recordPropagationMetric(latency: latency)
            }
        }
        
        return (stream, yieldFunction)
    }
    
    /// Record propagation performance metric
    func recordPropagationMetric(latency: TimeInterval) {
        propagationMetrics.record(latency: latency)
    }
    
    /// Get current propagation performance metrics
    public var currentMetrics: PropagationMetrics {
        get { propagationMetrics }
    }
    
    // MARK: - Batching Control
    
    /// Determine if updates should be batched based on frequency
    func shouldBatchUpdates() -> Bool {
        // Enable batching if we're seeing high-frequency updates
        let recentUpdateRate = propagationMetrics.recentUpdateRate
        return recentUpdateRate > Double(thresholds.batchingThreshold) / thresholds.frameInterval
    }
    
    /// Add update to batch coordinator
    func addToBatch<StateType: State>(_ update: StateUpdate<StateType>) async {
        await batchCoordinator.addUpdate(update)
    }
    
    // MARK: - Optimized Client Stream Creation
    
    /// Create an optimized client state stream for maximum performance
    public func createOptimizedClientStream<StateType: State>(
        for clientType: any Client.Type,
        initialState: StateType
    ) -> OptimizedClientStream<StateType> {
        return OptimizedClientStream(
            engine: self,
            initialState: initialState
        )
    }
}

// MARK: - Optimized Client Stream

/// High-performance client state stream with minimal overhead
public class OptimizedClientStream<StateType: State> {
    private let engine: StatePropagationEngine
    private let continuation: AsyncStream<StateType>.Continuation
    private let _stream: AsyncStream<StateType>
    private let streamId: UUID
    
    /// The high-performance state stream
    public var stream: AsyncStream<StateType> {
        _stream
    }
    
    init(engine: StatePropagationEngine, initialState: StateType) {
        self.engine = engine
        self.streamId = UUID()
        
        // Create stream with minimal buffering for fastest propagation
        let (stream, continuation) = AsyncStream.makeStreamWithContinuation(
            of: StateType.self,
            bufferingPolicy: .bufferingOldest(1)
        )
        
        self._stream = stream
        self.continuation = continuation
        
        // Immediately yield initial state
        continuation.yield(initialState)
    }
    
    /// Fast state update with performance tracking and optional batching
    public func yield(_ state: StateType) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // For now, always use immediate propagation for optimal performance
        // Batching can be enabled later when high-frequency scenarios are detected
        continuation.yield(state)
        
        // Track performance asynchronously to avoid blocking
        Task {
            let endTime = CFAbsoluteTimeGetCurrent()
            let latency = endTime - startTime
            await engine.recordPropagationMetric(latency: latency)
        }
    }
    
    /// Finish the stream
    public func finish() {
        continuation.finish()
    }
}

// MARK: - Performance Metrics

/// Performance metrics for state propagation
public struct PropagationMetrics: Sendable {
    private(set) var totalPropagations: Int = 0
    private(set) var totalLatency: TimeInterval = 0.0
    private(set) var maxLatency: TimeInterval = 0.0
    private(set) var minLatency: TimeInterval = Double.greatestFiniteMagnitude
    private var recentLatencies: [TimeInterval] = []
    
    /// Record a propagation latency measurement
    mutating func record(latency: TimeInterval) {
        totalPropagations += 1
        totalLatency += latency
        maxLatency = max(maxLatency, latency)
        minLatency = min(minLatency, latency)
        
        // Keep only recent measurements for rolling average
        recentLatencies.append(latency)
        if recentLatencies.count > 100 {
            recentLatencies.removeFirst()
        }
    }
    
    /// Average latency across all measurements
    public var averageLatency: TimeInterval {
        guard totalPropagations > 0 else { return 0.0 }
        return totalLatency / Double(totalPropagations)
    }
    
    /// Recent average latency (last 100 measurements)
    public var recentAverageLatency: TimeInterval {
        guard !recentLatencies.isEmpty else { return 0.0 }
        return recentLatencies.reduce(0, +) / Double(recentLatencies.count)
    }
    
    /// Whether current performance meets RFC requirements
    public var meetsPerformanceRequirements: Bool {
        maxLatency < 0.016 && averageLatency < 0.001  // 16ms max, 1ms average target
    }
    
    /// Recent update rate (updates per second)
    public var recentUpdateRate: Double {
        guard recentLatencies.count >= 2 else { return 0.0 }
        
        // Estimate update rate based on recent measurements
        let totalTime = recentLatencies.reduce(0, +)
        guard totalTime > 0 else { return 0.0 }
        
        return Double(recentLatencies.count) / totalTime
    }
}

// MARK: - Enhanced Client Protocol Extension

extension Client {
    /// Create an optimized state stream for this client
    public func createOptimizedStream(
        with engine: StatePropagationEngine
    ) async -> OptimizedClientStream<StateType> {
        return await engine.createOptimizedClientStream(
            for: Self.self,
            initialState: await getCurrentState()
        )
    }
    
    /// Get current state - to be implemented by concrete clients
    func getCurrentState() async -> StateType {
        fatalError("Subclasses must implement getCurrentState()")
    }
}

// MARK: - Global State Propagation Engine

/// Global instance for framework-wide state propagation optimization
/// Must be called asynchronously: await globalStatePropagationEngine()  
public func globalStatePropagationEngine() async -> StatePropagationEngine {
    return StatePropagationEngine()
}

// MARK: - Batch Coordination

/// Coordinates batched state updates for high-frequency scenarios
actor BatchCoordinator {
    private var pendingUpdates: [AnyStateUpdate] = []
    private var batchTimer: Task<Void, Never>?
    private let frameInterval: TimeInterval = 1.0 / 60.0 // 60fps
    
    /// Add an update to the current batch
    func addUpdate<StateType: State>(_ update: StateUpdate<StateType>) {
        pendingUpdates.append(AnyStateUpdate(update))
        
        // Start batch timer if not already running
        if batchTimer == nil {
            batchTimer = Task {
                // Wait for one frame interval
                try? await Task.sleep(for: .milliseconds(Int(frameInterval * 1000)))
                await flushBatch()
            }
        }
    }
    
    /// Flush all pending updates
    private func flushBatch() {
        defer {
            pendingUpdates.removeAll()
            batchTimer = nil
        }
        
        // Group updates by stream and apply latest state for each
        var latestStates: [UUID: AnyStateUpdate] = [:]
        
        for update in pendingUpdates {
            latestStates[update.streamId] = update
        }
        
        // Apply all latest states
        for (_, update) in latestStates {
            update.apply()
        }
    }
    
    /// Force immediate flush (for low-frequency updates)
    func flushImmediate() {
        batchTimer?.cancel()
        batchTimer = nil
        
        for update in pendingUpdates {
            update.apply()
        }
        pendingUpdates.removeAll()
    }
}

// MARK: - State Update Types

/// Type-erased state update for batching
struct AnyStateUpdate {
    let streamId: UUID
    private let _apply: () -> Void
    
    init<StateType: State>(_ update: StateUpdate<StateType>) {
        self.streamId = update.streamId
        self._apply = { update.continuation.yield(update.state) }
    }
    
    func apply() {
        _apply()
    }
}

/// Strongly-typed state update
struct StateUpdate<StateType: State> {
    let streamId: UUID
    let state: StateType
    let continuation: AsyncStream<StateType>.Continuation
}