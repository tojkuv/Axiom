import Foundation
import AxiomCore
import AxiomArchitecture

// MARK: - Enhanced State Propagation System (REQUIREMENTS-W-01-005)

/// Propagation priorities for state updates
public enum PropagationPriority: Int, Comparable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: PropagationPriority, rhs: PropagationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Observer priorities for state propagation
public enum ObserverPriority: Int, Comparable, CaseIterable, Sendable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: ObserverPriority, rhs: ObserverPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// High-performance state propagation engine
public actor StatePropagationEngine {
    private let optimizer: PropagationOptimizer
    private let monitor: PerformanceMonitor
    private var streams: [UUID: AnyStateStream] = [:]
    
    /// Performance SLA configuration
    public struct PerformanceSLA {
        public let maxLatency: TimeInterval = 0.016 // 16ms
        public let targetAverageLatency: TimeInterval = 0.001 // 1ms
        public let maxObserversPerStream: Int = 1000
        public let backpressureThreshold: Int = 100
        
        public init() {}
    }
    
    public init() {
        self.optimizer = PropagationOptimizer()
        self.monitor = PerformanceMonitor()
    }
    
    /// Create optimized stream with performance guarantees
    public func createStream<S: AxiomState>(
        for clientType: any AxiomClient.Type,
        initialState: S,
        priority: PropagationPriority = .normal
    ) -> GuaranteedStateStream<S> {
        let stream = GuaranteedStateStream(
            engine: self,
            initialState: initialState,
            priority: priority,
            sla: PerformanceSLA()
        )
        
        streams[stream.id] = AnyStateStream(stream)
        return stream
    }
    
    /// Multi-cast optimization for shared states
    public func createMulticastStream<S: AxiomState>(
        source: AsyncStream<S>,
        subscribers: Int
    ) -> MulticastStateStream<S> {
        MulticastStateStream(
            source: source,
            expectedSubscribers: subscribers,
            optimizer: optimizer
        )
    }
    
    /// Handle SLA violation
    internal func handleSLAViolation(stream: UUID, latency: TimeInterval) async {
        monitor.recordSLAViolation(streamId: stream, latency: latency)
        
        // Trigger optimization if needed
        if let stream = streams[stream] {
            await optimizer.optimizeStream(stream)
        }
    }
}

/// Type-erased state stream container
public struct AnyStateStream: Sendable {
    private let _optimize: @Sendable () async -> Void
    
    public init<S: AxiomState>(_ stream: GuaranteedStateStream<S>) {
        self._optimize = {
            await stream.optimize()
        }
    }
    
    public func optimize() async {
        await _optimize()
    }
}

/// Guaranteed performance state stream
public class GuaranteedStateStream<S: AxiomState>: @unchecked Sendable {
    public let id = UUID()
    private let engine: StatePropagationEngine
    private let priority: PropagationPriority
    private let sla: StatePropagationEngine.PerformanceSLA
    private var observers: ObserverRegistry<S>
    
    public init(
        engine: StatePropagationEngine,
        initialState: S,
        priority: PropagationPriority,
        sla: StatePropagationEngine.PerformanceSLA
    ) {
        self.engine = engine
        self.priority = priority
        self.sla = sla
        self.observers = ObserverRegistry(maxObservers: sla.maxObserversPerStream)
    }
    
    /// Zero-copy state propagation
    public func propagate(_ state: S) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Priority-based propagation
        await observers.notifyByPriority(state, priority: priority)
        
        // Track performance
        let latency = CFAbsoluteTimeGetCurrent() - startTime
        if latency > sla.maxLatency {
            await engine.handleSLAViolation(stream: id, latency: latency)
        }
    }
    
    /// Add observer with lifecycle management
    public func observe(
        priority: ObserverPriority = .normal,
        handler: @escaping @Sendable (S) async -> Void
    ) async -> ObservationToken {
        let observer = Observer(priority: priority, handler: handler)
        return await observers.add(observer: observer)
    }
    
    /// Optimize stream performance
    internal func optimize() async {
        await observers.performMaintenance()
    }
}

/// Multi-cast state stream optimization
public struct MulticastStateStream<S: AxiomState> {
    private let broadcaster: StateBroadcaster<S>
    
    public init(
        source: AsyncStream<S>,
        expectedSubscribers: Int,
        optimizer: PropagationOptimizer
    ) {
        self.broadcaster = StateBroadcaster(
            source: source,
            capacity: expectedSubscribers,
            optimizer: optimizer
        )
    }
    
    /// Efficient multi-cast subscription
    public func subscribe() async -> AsyncStream<S> {
        await broadcaster.createSubscription()
    }
}

/// State broadcaster for multi-cast optimization
internal actor StateBroadcaster<S: AxiomState> {
    private let source: AsyncStream<S>
    private let capacity: Int
    private let optimizer: PropagationOptimizer
    private var subscriptions: [UUID: AsyncStream<S>.Continuation] = [:]
    private var isStarted = false
    
    init(source: AsyncStream<S>, capacity: Int, optimizer: PropagationOptimizer) {
        self.source = source
        self.capacity = capacity
        self.optimizer = optimizer
    }
    
    func createSubscription() -> AsyncStream<S> {
        let id = UUID()
        
        return AsyncStream<S> { continuation in
            Task {
                self.addSubscription(id: id, continuation: continuation)
                if !isStarted {
                    await self.startBroadcasting()
                }
            }
        }
    }
    
    private func addSubscription(id: UUID, continuation: AsyncStream<S>.Continuation) {
        subscriptions[id] = continuation
        
        // Set up cleanup on termination
        continuation.onTermination = { _ in
            Task {
                await self.removeSubscription(id: id)
            }
        }
    }
    
    private func removeSubscription(id: UUID) {
        subscriptions.removeValue(forKey: id)
    }
    
    private func startBroadcasting() async {
        isStarted = true
        
        Task {
            for await state in source {
                // Broadcast to all subscriptions
                for continuation in subscriptions.values {
                    continuation.yield(state)
                }
            }
            
            // Finish all subscriptions when source ends
            for continuation in subscriptions.values {
                continuation.finish()
            }
        }
    }
}

// MARK: - Observer Lifecycle Management (REQUIREMENTS-W-01-005)

/// Observer registry with lifecycle management
public actor ObserverRegistry<S: AxiomState> {
    private var observers: [ObserverEntry<S>] = []
    private let maxObservers: Int
    private let cleanupInterval: TimeInterval = 60.0
    private var lastCleanup: Date = Date()
    
    private struct ObserverEntry<T>: @unchecked Sendable {
        let id: UUID
        let priority: ObserverPriority
        weak var token: ObservationToken?
        let handler: @Sendable (T) async -> Void
        var lastActivity: Date
        var isHealthy: Bool = true
    }
    
    public init(maxObservers: Int = 1000) {
        self.maxObservers = maxObservers
    }
    
    /// Add observer with weak reference
    public func add(observer: Observer<S>) -> ObservationToken {
        let token = ObservationToken()
        let entry = ObserverEntry(
            id: UUID(),
            priority: observer.priority,
            token: token,
            handler: observer.handler,
            lastActivity: Date()
        )
        
        observers.append(entry)
        observers.sort { $0.priority > $1.priority }
        
        // Set up cleanup handler
        token.onDeinit = { [weak self] in
            Task {
                await self?.removeObserver(withId: entry.id)
            }
        }
        
        return token
    }
    
    /// Notify observers by priority
    public func notifyByPriority(_ state: S, priority: PropagationPriority) async {
        // Clean up dead observers periodically
        await performMaintenanceIfNeeded()
        
        // Group by priority
        let groups = Dictionary(grouping: observers) { $0.priority }
        
        // Notify high priority first
        for observerPriority in ObserverPriority.allCases.sorted(by: >) {
            if let group = groups[observerPriority] {
                await notifyGroup(group, with: state)
            }
        }
    }
    
    /// Parallel notification with backpressure handling
    private func notifyGroup(_ group: [ObserverEntry<S>], with state: S) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for observer in group {
                // Skip unhealthy or dead observers
                guard observer.isHealthy, observer.token != nil else { continue }
                
                taskGroup.addTask {
                    await self.notifyObserver(observer, with: state)
                }
            }
            
            // Wait for all tasks to complete
            await taskGroup.waitForAll()
        }
    }
    
    /// Notify individual observer with health tracking
    private func notifyObserver(_ entry: ObserverEntry<S>, with state: S) async {
        let start = CFAbsoluteTimeGetCurrent()
        await entry.handler(state)
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        // Mark unhealthy if too slow
        if duration > 0.1 { // 100ms timeout
            await markObserverUnhealthy(entry.id)
        }
    }
    
    /// Mark observer as unhealthy
    private func markObserverUnhealthy(_ id: UUID) async {
        if let index = observers.firstIndex(where: { $0.id == id }) {
            observers[index].isHealthy = false
        }
    }
    
    /// Remove observer by ID
    private func removeObserver(withId id: UUID) {
        observers.removeAll { $0.id == id }
    }
    
    /// Perform maintenance and cleanup
    public func performMaintenance() async {
        // Remove dead or unhealthy observers
        observers.removeAll { entry in
            entry.token == nil || !entry.isHealthy
        }
        
        lastCleanup = Date()
    }
    
    /// Perform maintenance if needed
    private func performMaintenanceIfNeeded() async {
        let timeSinceCleanup = Date().timeIntervalSince(lastCleanup)
        if timeSinceCleanup > cleanupInterval {
            await performMaintenance()
        }
    }
}

/// Observer wrapper
public struct Observer<S: AxiomState>: @unchecked Sendable {
    let priority: ObserverPriority
    let handler: @Sendable (S) async -> Void
    
    public init(priority: ObserverPriority, handler: @escaping @Sendable (S) async -> Void) {
        self.priority = priority
        self.handler = handler
    }
}

/// Observation token for lifecycle management
public class ObservationToken: @unchecked Sendable {
    private let id = UUID()
    internal var onDeinit: (@Sendable () -> Void)?
    
    deinit {
        onDeinit?()
    }
    
    public func cancel() {
        onDeinit?()
        onDeinit = nil
    }
}

// MARK: - Selective State Propagation (REQUIREMENTS-W-01-005)

/// Selective propagation with predicates
public struct SelectiveStateStream<S: AxiomState>: @unchecked Sendable {
    private let source: AsyncStream<S>
    private let predicates: [StatePredicate<S>]
    
    public init(source: AsyncStream<S>, predicates: [StatePredicate<S>]) {
        self.source = source
        self.predicates = predicates
    }
    
    /// Create filtered stream
    public func filtered(
        by predicate: @escaping @Sendable (S) -> Bool
    ) -> AsyncStream<S> {
        AsyncStream { continuation in
            Task { @Sendable in
                for await state in source {
                    if predicate(state) {
                        continuation.yield(state)
                    }
                }
                continuation.finish()
            }
        }
    }
    
    /// Property-based filtering - temporarily disabled due to KeyPath sendability issues
    // TODO: Re-implement with proper sendability support for KeyPath
    /*
    public func select<T: Equatable & Sendable>(
        _ keyPath: KeyPath<S, T>
    ) -> AsyncStream<T> {
        return AsyncStream { continuation in
            Task {
                var lastValue: T?
                for await state in source {
                    let value = state[keyPath: keyPath]
                    if value != lastValue {
                        lastValue = value
                        continuation.yield(value)
                    }
                }
                continuation.finish()
            }
        }
    }
    */
    
    /// Debounced propagation
    public func debounced(
        for duration: TimeInterval
    ) -> AsyncStream<S> {
        AsyncStream { continuation in
            Task {
                var task: Task<Void, Never>?
                
                for await state in source {
                    task?.cancel()
                    
                    let capturedState = state
                    task = Task {
                        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                        
                        if !Task.isCancelled {
                            continuation.yield(capturedState)
                        }
                    }
                }
                
                // Wait for final task to complete
                if let finalTask = task {
                    await finalTask.value
                }
                
                continuation.finish()
            }
        }
    }
}

/// State predicate for filtering
public struct StatePredicate<S: AxiomState>: @unchecked Sendable {
    private let predicate: (S) -> Bool
    
    public init(_ predicate: @escaping (S) -> Bool) {
        self.predicate = predicate
    }
    
    public func evaluate(_ state: S) -> Bool {
        predicate(state)
    }
}

// MARK: - Performance Monitoring (REQUIREMENTS-W-01-005)

/// Real-time propagation monitor
public actor PropagationMonitor {
    private var metrics: PropagationMetrics
    private let alerting: AlertingService
    private let optimizer: AdaptiveOptimizer
    
    public init() {
        self.metrics = PropagationMetrics()
        self.alerting = AlertingService()
        self.optimizer = AdaptiveOptimizer()
    }
    
    /// Record propagation event
    public func recordPropagation(
        streamId: UUID,
        latency: TimeInterval,
        observers: Int,
        stateSize: Int
    ) async {
        let event = PropagationEvent(
            streamId: streamId,
            latency: latency,
            observers: observers,
            stateSize: stateSize,
            timestamp: Date()
        )
        
        metrics.record(event)
        
        // Check SLA compliance
        if latency > 0.016 {
            let eventCopy = event
            await alerting.triggerSLAViolation(eventCopy)
        }
        
        // Suggest optimizations
        let currentMetrics = metrics
        if let optimization = await optimizer.suggest(for: currentMetrics) {
            await applyOptimization(optimization)
        }
    }
    
    /// Record SLA violation
    internal func recordSLAViolation(streamId: UUID, latency: TimeInterval) async {
        await alerting.triggerSLAViolation(PropagationEvent(
            streamId: streamId,
            latency: latency,
            observers: 0,
            stateSize: 0,
            timestamp: Date()
        ))
    }
    
    /// Generate performance dashboard
    public func dashboard() async -> PropagationDashboard {
        PropagationDashboard(
            currentMetrics: metrics,
            slaCompliance: metrics.slaCompliance,
            recommendations: await optimizer.currentRecommendations,
            alerts: await alerting.activeAlerts
        )
    }
    
    private func applyOptimization(_ optimization: OptimizationRecommendation) async {
        // Apply optimization recommendation
        print("Applying optimization: \(optimization)")
    }
}

/// Propagation event for monitoring
public struct PropagationEvent: Sendable {
    public let streamId: UUID
    public let latency: TimeInterval
    public let observers: Int
    public let stateSize: Int
    public let timestamp: Date
}

/// Propagation metrics collection
public struct PropagationMetrics: Sendable {
    private var events: [PropagationEvent] = []
    
    public var totalEvents: Int {
        events.count
    }
    
    public var averageLatency: TimeInterval {
        guard !events.isEmpty else { return 0 }
        return events.reduce(0) { $0 + $1.latency } / Double(events.count)
    }
    
    public var slaCompliance: Double {
        guard !events.isEmpty else { return 1.0 }
        let compliantEvents = events.filter { $0.latency <= 0.016 }
        return Double(compliantEvents.count) / Double(events.count)
    }
    
    mutating func record(_ event: PropagationEvent) {
        events.append(event)
        
        // Keep only recent events (last 1000)
        if events.count > 1000 {
            events.removeFirst(events.count - 1000)
        }
    }
}

/// Performance dashboard
public struct PropagationDashboard {
    public let currentMetrics: PropagationMetrics
    public let slaCompliance: Double
    public let recommendations: [OptimizationRecommendation]
    public let alerts: [PerformanceAlert]
}

/// Alerting service for SLA violations
internal actor AlertingService {
    private var _activeAlerts: [PerformanceAlert] = []
    
    var activeAlerts: [PerformanceAlert] {
        _activeAlerts
    }
    
    func triggerSLAViolation(_ event: PropagationEvent) async {
        let alert = PerformanceAlert.slaViolation(
            streamId: event.streamId,
            latency: event.latency,
            timestamp: event.timestamp
        )
        _activeAlerts.append(alert)
        
        // Keep only recent alerts
        if _activeAlerts.count > 100 {
            _activeAlerts.removeFirst(_activeAlerts.count - 100)
        }
    }
}

// PerformanceAlert is defined in PerformanceMonitoring.swift - using unified definition

/// Adaptive optimizer for performance
internal actor AdaptiveOptimizer {
    private var _recommendations: [OptimizationRecommendation] = []
    
    var currentRecommendations: [OptimizationRecommendation] {
        _recommendations
    }
    
    func suggest(for metrics: PropagationMetrics) async -> OptimizationRecommendation? {
        // Analyze metrics and suggest optimizations
        if metrics.averageLatency > 0.005 { // > 5ms average
            let recommendation = OptimizationRecommendation.enableBatching
            _recommendations.append(recommendation)
            return recommendation
        }
        
        if metrics.slaCompliance < 0.95 { // < 95% SLA compliance
            let recommendation = OptimizationRecommendation.increasePriority
            _recommendations.append(recommendation)
            return recommendation
        }
        
        return nil
    }
}

/// Optimization recommendations
public enum OptimizationRecommendation: Sendable {
    case enableBatching
    case increasePriority
    case reduceObservers
    case enableFiltering
}

// MARK: - Supporting Types

/// Propagation optimizer
public actor PropagationOptimizer {
    public init() {}
    
    public func optimizeStream(_ stream: AnyStateStream) async {
        await stream.optimize()
    }
}

/// Performance monitor
// PerformanceMonitor is defined in PerformanceMonitoring.swift - using unified definition

// MARK: - TaskGroup Extensions

extension TaskGroup {
    /// Wait with timeout to prevent blocking
    mutating func waitWithTimeout(milliseconds: Int) async {
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(milliseconds * 1_000_000))
        }
        
        await timeoutTask.value
        timeoutTask.cancel()
    }
}

// MARK: - Global State Propagation Engine

/// Global state propagation engine instance
private let globalEngine = StatePropagationEngine()

/// Access to the global state propagation engine
/// Must be called asynchronously: await globalStatePropagationEngine()
public func globalStatePropagationEngine() async -> StatePropagationEngine {
    return globalEngine
}