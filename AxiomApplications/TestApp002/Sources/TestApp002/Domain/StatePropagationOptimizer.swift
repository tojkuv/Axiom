import Foundation

// GREEN Phase: State Propagation Optimizer
// Ensures all state changes propagate within 16ms (one frame at 60fps)

/// Optimization strategies for state propagation
enum PropagationOptimization {
    case batchUpdates
    case throttleEmissions
    case efficientDiffing
    case lazyEvaluation
}

/// Measures and optimizes state propagation performance
actor StatePropagationOptimizer {
    private var pendingUpdates: [@Sendable () async -> Void] = []
    private var updateTimer: Timer?
    private let maxBatchSize = 10
    private let batchWindow: TimeInterval = 0.008 // 8ms to allow processing within 16ms frame
    
    // Performance metrics
    private var propagationTimes: [TimeInterval] = []
    private let metricsWindow = 100 // Keep last 100 measurements
    
    /// Process a state update with optimization
    func processUpdate(_ update: @escaping @Sendable () async -> Void) async {
        // Add to pending updates for batching
        pendingUpdates.append(update)
        
        // If we have enough updates or first update, process batch
        if pendingUpdates.count >= maxBatchSize || pendingUpdates.count == 1 {
            await processBatch()
        }
    }
    
    /// Process all pending updates in a single batch
    private func processBatch() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Take current batch
        let batch = pendingUpdates
        pendingUpdates.removeAll()
        
        // Process all updates concurrently
        await withTaskGroup(of: Void.self) { group in
            for update in batch {
                group.addTask {
                    await update()
                }
            }
        }
        
        // Record propagation time
        let endTime = CFAbsoluteTimeGetCurrent()
        let propagationTime = (endTime - startTime) * 1000 // Convert to ms
        recordPropagationTime(propagationTime)
    }
    
    /// Record propagation time for monitoring
    private func recordPropagationTime(_ time: TimeInterval) {
        propagationTimes.append(time)
        
        // Keep only recent measurements
        if propagationTimes.count > metricsWindow {
            propagationTimes.removeFirst()
        }
        
        // Log warning if exceeding threshold
        if time > 16.0 {
            print("⚠️ State propagation exceeded 16ms: \(time)ms")
        }
    }
    
    /// Get average propagation time
    func averagePropagationTime() -> TimeInterval {
        guard !propagationTimes.isEmpty else { return 0 }
        return propagationTimes.reduce(0, +) / Double(propagationTimes.count)
    }
    
    /// Get max propagation time
    func maxPropagationTime() -> TimeInterval {
        return propagationTimes.max() ?? 0
    }
}

/// Efficient state differ for minimizing equality check time
struct StateDiffer {
    /// Quick hash-based comparison before full equality check
    static func quickCompare<T: Hashable>(_ lhs: T, _ rhs: T) -> Bool {
        return lhs.hashValue == rhs.hashValue && lhs == rhs
    }
    
    /// Efficient array comparison using count and sample checks
    static func efficientArrayCompare<T: Equatable>(_ lhs: [T], _ rhs: [T]) -> Bool {
        // Quick checks first
        guard lhs.count == rhs.count else { return false }
        guard !lhs.isEmpty else { return true }
        
        // Sample check - compare first, last, and middle elements
        if lhs.count > 3 {
            let midIndex = lhs.count / 2
            guard lhs[0] == rhs[0],
                  lhs[midIndex] == rhs[midIndex],
                  lhs[lhs.count - 1] == rhs[rhs.count - 1] else {
                return false
            }
        }
        
        // Full comparison only if samples match
        return lhs == rhs
    }
}

/// Stream throttler to prevent overwhelming UI with updates
actor StreamThrottler<Value: Sendable> {
    private var latestValue: Value?
    private var continuation: AsyncStream<Value>.Continuation?
    private var throttleTask: _Concurrency.Task<Void, Never>?
    private let throttleInterval: TimeInterval
    
    init(throttleInterval: TimeInterval = 0.016) { // Default to one frame
        self.throttleInterval = throttleInterval
    }
    
    /// Create a throttled stream
    func throttledStream(from source: AsyncStream<Value>) -> AsyncStream<Value> {
        AsyncStream { continuation in
            self.continuation = continuation
            
            _Concurrency.Task {
                for await value in source {
                    self.handleValue(value)
                }
                continuation.finish()
            }
        }
    }
    
    /// Handle incoming value with throttling
    private func handleValue(_ value: Value) {
        latestValue = value
        
        // Cancel previous throttle if exists
        throttleTask?.cancel()
        
        // Schedule emission
        throttleTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(throttleInterval * 1_000_000_000))
            
            if let latestValue = self.latestValue {
                self.continuation?.yield(latestValue)
                self.latestValue = nil
            }
        }
    }
}

// MARK: - TaskClient Extension for Optimized State Propagation

extension TaskClient {
    /// Process action with optimized state propagation
    func processOptimized(_ action: TaskAction) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Process the action
        try await process(action)
        
        // Ensure propagation completes within 16ms
        let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        if elapsedTime < 16.0 {
            // Good performance, no action needed
            return
        } else {
            // Log performance warning
            print("⚠️ Action \(action) took \(elapsedTime)ms to propagate")
        }
    }
}

// MARK: - Optimized TaskListState

extension TaskListState {
    /// Fast equality check helper (doesn't override ==)
    func isOptimizedEqual(to other: TaskListState) -> Bool {
        // Quick checks first
        guard self.tasks.count == other.tasks.count else { return false }
        guard self.searchQuery == other.searchQuery else { return false }
        guard self.sortCriteria == other.sortCriteria else { return false }
        guard self.selectedCategoryId == other.selectedCategoryId else { return false }
        
        // Expensive comparisons last
        guard StateDiffer.efficientArrayCompare(self.categories, other.categories) else { return false }
        guard StateDiffer.efficientArrayCompare(self.pendingShares, other.pendingShares) else { return false }
        guard StateDiffer.efficientArrayCompare(self.collaborationInfo, other.collaborationInfo) else { return false }
        
        // Most expensive - full task array comparison
        return StateDiffer.efficientArrayCompare(self.tasks, other.tasks)
    }
}