import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Request Queue Capability Configuration

/// Configuration for Request Queue capability
public struct RequestQueueCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let maxQueueSize: Int
    public let maxConcurrentRequests: Int
    public let enableBatching: Bool
    public let maxBatchSize: Int
    public let batchTimeout: TimeInterval
    public let enablePrioritization: Bool
    public let enableDeduplication: Bool
    public let deduplicationWindow: TimeInterval
    public let enableRetries: Bool
    public let maxRetryAttempts: Int
    public let retryBackoffMultiplier: Double
    public let maxRetryDelay: TimeInterval
    public let enableCircuitBreaker: Bool
    public let circuitBreakerThreshold: Int
    public let circuitBreakerTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let requestTimeout: TimeInterval
    public let enableRequestCoalescing: Bool
    public let coalescingWindow: TimeInterval
    public let enableAdaptiveQueueing: Bool
    public let queueThrottlingEnabled: Bool
    public let maxThroughputPerSecond: Int
    
    public init(
        maxQueueSize: Int = 10000,
        maxConcurrentRequests: Int = 10,
        enableBatching: Bool = true,
        maxBatchSize: Int = 20,
        batchTimeout: TimeInterval = 5.0,
        enablePrioritization: Bool = true,
        enableDeduplication: Bool = true,
        deduplicationWindow: TimeInterval = 60.0,
        enableRetries: Bool = true,
        maxRetryAttempts: Int = 3,
        retryBackoffMultiplier: Double = 2.0,
        maxRetryDelay: TimeInterval = 60.0,
        enableCircuitBreaker: Bool = true,
        circuitBreakerThreshold: Int = 5,
        circuitBreakerTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        requestTimeout: TimeInterval = 30.0,
        enableRequestCoalescing: Bool = true,
        coalescingWindow: TimeInterval = 1.0,
        enableAdaptiveQueueing: Bool = true,
        queueThrottlingEnabled: Bool = true,
        maxThroughputPerSecond: Int = 100
    ) {
        self.maxQueueSize = maxQueueSize
        self.maxConcurrentRequests = maxConcurrentRequests
        self.enableBatching = enableBatching
        self.maxBatchSize = maxBatchSize
        self.batchTimeout = batchTimeout
        self.enablePrioritization = enablePrioritization
        self.enableDeduplication = enableDeduplication
        self.deduplicationWindow = deduplicationWindow
        self.enableRetries = enableRetries
        self.maxRetryAttempts = maxRetryAttempts
        self.retryBackoffMultiplier = retryBackoffMultiplier
        self.maxRetryDelay = maxRetryDelay
        self.enableCircuitBreaker = enableCircuitBreaker
        self.circuitBreakerThreshold = circuitBreakerThreshold
        self.circuitBreakerTimeout = circuitBreakerTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.requestTimeout = requestTimeout
        self.enableRequestCoalescing = enableRequestCoalescing
        self.coalescingWindow = coalescingWindow
        self.enableAdaptiveQueueing = enableAdaptiveQueueing
        self.queueThrottlingEnabled = queueThrottlingEnabled
        self.maxThroughputPerSecond = maxThroughputPerSecond
    }
    
    public var isValid: Bool {
        maxQueueSize > 0 && 
        maxConcurrentRequests > 0 && 
        maxBatchSize > 0 && 
        batchTimeout > 0 && 
        deduplicationWindow > 0 && 
        maxRetryAttempts >= 0 && 
        retryBackoffMultiplier > 0 && 
        maxRetryDelay > 0 &&
        circuitBreakerThreshold > 0 &&
        circuitBreakerTimeout > 0 &&
        requestTimeout > 0 &&
        coalescingWindow > 0 &&
        maxThroughputPerSecond > 0
    }
    
    public func merged(with other: RequestQueueCapabilityConfiguration) -> RequestQueueCapabilityConfiguration {
        RequestQueueCapabilityConfiguration(
            maxQueueSize: other.maxQueueSize,
            maxConcurrentRequests: other.maxConcurrentRequests,
            enableBatching: other.enableBatching,
            maxBatchSize: other.maxBatchSize,
            batchTimeout: other.batchTimeout,
            enablePrioritization: other.enablePrioritization,
            enableDeduplication: other.enableDeduplication,
            deduplicationWindow: other.deduplicationWindow,
            enableRetries: other.enableRetries,
            maxRetryAttempts: other.maxRetryAttempts,
            retryBackoffMultiplier: other.retryBackoffMultiplier,
            maxRetryDelay: other.maxRetryDelay,
            enableCircuitBreaker: other.enableCircuitBreaker,
            circuitBreakerThreshold: other.circuitBreakerThreshold,
            circuitBreakerTimeout: other.circuitBreakerTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            requestTimeout: other.requestTimeout,
            enableRequestCoalescing: other.enableRequestCoalescing,
            coalescingWindow: other.coalescingWindow,
            enableAdaptiveQueueing: other.enableAdaptiveQueueing,
            queueThrottlingEnabled: other.queueThrottlingEnabled,
            maxThroughputPerSecond: other.maxThroughputPerSecond
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> RequestQueueCapabilityConfiguration {
        var adjustedConcurrency = maxConcurrentRequests
        var adjustedBatchSize = maxBatchSize
        var adjustedLogging = enableLogging
        var adjustedThroughput = maxThroughputPerSecond
        var adjustedQueueSize = maxQueueSize
        
        if environment.isLowPowerMode {
            adjustedConcurrency = min(maxConcurrentRequests, 3)
            adjustedBatchSize = min(maxBatchSize, 5)
            adjustedThroughput = min(maxThroughputPerSecond, 20)
            adjustedQueueSize = min(maxQueueSize, 1000)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return RequestQueueCapabilityConfiguration(
            maxQueueSize: adjustedQueueSize,
            maxConcurrentRequests: adjustedConcurrency,
            enableBatching: enableBatching,
            maxBatchSize: adjustedBatchSize,
            batchTimeout: batchTimeout,
            enablePrioritization: enablePrioritization,
            enableDeduplication: enableDeduplication,
            deduplicationWindow: deduplicationWindow,
            enableRetries: enableRetries,
            maxRetryAttempts: maxRetryAttempts,
            retryBackoffMultiplier: retryBackoffMultiplier,
            maxRetryDelay: maxRetryDelay,
            enableCircuitBreaker: enableCircuitBreaker,
            circuitBreakerThreshold: circuitBreakerThreshold,
            circuitBreakerTimeout: circuitBreakerTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            requestTimeout: requestTimeout,
            enableRequestCoalescing: enableRequestCoalescing,
            coalescingWindow: coalescingWindow,
            enableAdaptiveQueueing: enableAdaptiveQueueing,
            queueThrottlingEnabled: queueThrottlingEnabled,
            maxThroughputPerSecond: adjustedThroughput
        )
    }
}

// MARK: - Request Queue Types

/// Queued request with metadata
public struct QueuedRequest: Sendable, Identifiable {
    public let id: UUID
    public let request: URLRequest
    public let priority: RequestPriority
    public let tags: Set<String>
    public let maxRetries: Int
    public let timeout: TimeInterval
    public let createdAt: Date
    public let scheduledAt: Date?
    public let batchable: Bool
    public let coalesceable: Bool
    public let retryPolicy: RetryPolicy
    public let metadata: [String: String]
    
    // Internal tracking
    internal let attemptCount: Int
    internal let lastAttemptAt: Date?
    internal let deduplicationKey: String?
    
    public enum RequestPriority: Int, Codable, CaseIterable, Comparable {
        case background = 0
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
        case immediate = 5
        
        public static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public enum RetryPolicy: Codable {
        case none
        case linear(delay: TimeInterval)
        case exponential(baseDelay: TimeInterval, multiplier: Double)
        case fixed(delay: TimeInterval)
        case adaptive
    }
    
    public init(
        request: URLRequest,
        priority: RequestPriority = .normal,
        tags: Set<String> = [],
        maxRetries: Int = 3,
        timeout: TimeInterval = 30.0,
        scheduledAt: Date? = nil,
        batchable: Bool = true,
        coalesceable: Bool = false,
        retryPolicy: RetryPolicy = .exponential(baseDelay: 1.0, multiplier: 2.0),
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.request = request
        self.priority = priority
        self.tags = tags
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.createdAt = Date()
        self.scheduledAt = scheduledAt
        self.batchable = batchable
        self.coalesceable = coalesceable
        self.retryPolicy = retryPolicy
        self.metadata = metadata
        self.attemptCount = 0
        self.lastAttemptAt = nil
        self.deduplicationKey = coalesceable ? generateDeduplicationKey(from: request) : nil
    }
    
    internal init(
        id: UUID = UUID(),
        request: URLRequest,
        priority: RequestPriority,
        tags: Set<String>,
        maxRetries: Int,
        timeout: TimeInterval,
        createdAt: Date,
        scheduledAt: Date?,
        batchable: Bool,
        coalesceable: Bool,
        retryPolicy: RetryPolicy,
        metadata: [String: String],
        attemptCount: Int,
        lastAttemptAt: Date?,
        deduplicationKey: String?
    ) {
        self.id = id
        self.request = request
        self.priority = priority
        self.tags = tags
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.createdAt = createdAt
        self.scheduledAt = scheduledAt
        self.batchable = batchable
        self.coalesceable = coalesceable
        self.retryPolicy = retryPolicy
        self.metadata = metadata
        self.attemptCount = attemptCount
        self.lastAttemptAt = lastAttemptAt
        self.deduplicationKey = deduplicationKey
    }
    
    public var isScheduled: Bool {
        guard let scheduledAt = scheduledAt else { return true }
        return Date() >= scheduledAt
    }
    
    public var canRetry: Bool {
        attemptCount < maxRetries
    }
    
    public func withRetry() -> QueuedRequest {
        let nextDelay = calculateRetryDelay()
        
        return QueuedRequest(
            id: id,
            request: request,
            priority: priority,
            tags: tags,
            maxRetries: maxRetries,
            timeout: timeout,
            createdAt: createdAt,
            scheduledAt: Date().addingTimeInterval(nextDelay),
            batchable: batchable,
            coalesceable: coalesceable,
            retryPolicy: retryPolicy,
            metadata: metadata,
            attemptCount: attemptCount + 1,
            lastAttemptAt: Date(),
            deduplicationKey: deduplicationKey
        )
    }
    
    private func calculateRetryDelay() -> TimeInterval {
        switch retryPolicy {
        case .none:
            return 0
        case .linear(let delay):
            return delay
        case .exponential(let baseDelay, let multiplier):
            return baseDelay * pow(multiplier, Double(attemptCount))
        case .fixed(let delay):
            return delay
        case .adaptive:
            // Adaptive retry based on current network conditions
            return min(1.0 * pow(2.0, Double(attemptCount)), 60.0)
        }
    }
    
    private static func generateDeduplicationKey(from request: URLRequest) -> String {
        let url = request.url?.absoluteString ?? ""
        let method = request.httpMethod ?? "GET"
        let bodyHash = request.httpBody?.hashValue ?? 0
        return "\(method):\(url):\(bodyHash)"
    }
}

/// Request batch for grouped execution
public struct RequestBatch: Sendable {
    public let id: UUID
    public let requests: [QueuedRequest]
    public let createdAt: Date
    public let priority: QueuedRequest.RequestPriority
    public let tags: Set<String>
    
    public init(requests: [QueuedRequest]) {
        self.id = UUID()
        self.requests = requests
        self.createdAt = Date()
        self.priority = requests.map(\.priority).max() ?? .normal
        self.tags = Set(requests.flatMap(\.tags))
    }
    
    public var isEmpty: Bool {
        requests.isEmpty
    }
    
    public var size: Int {
        requests.count
    }
}

/// Request execution result
public struct RequestResult: Sendable {
    public let requestId: UUID
    public let success: Bool
    public let response: HTTPURLResponse?
    public let data: Data?
    public let error: Error?
    public let duration: TimeInterval
    public let attemptCount: Int
    public let fromCache: Bool
    public let circuitBreakerTripped: Bool
    
    public init(
        requestId: UUID,
        success: Bool,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        error: Error? = nil,
        duration: TimeInterval,
        attemptCount: Int = 1,
        fromCache: Bool = false,
        circuitBreakerTripped: Bool = false
    ) {
        self.requestId = requestId
        self.success = success
        self.response = response
        self.data = data
        self.error = error
        self.duration = duration
        self.attemptCount = attemptCount
        self.fromCache = fromCache
        self.circuitBreakerTripped = circuitBreakerTripped
    }
}

/// Circuit breaker state
public enum CircuitBreakerState: Sendable {
    case closed
    case open(openedAt: Date)
    case halfOpen
}

/// Request queue metrics
public struct RequestQueueMetrics: Sendable {
    public let queueSize: Int
    public let totalRequestsQueued: Int
    public let totalRequestsProcessed: Int
    public let totalRequestsFailed: Int
    public let totalBatchesProcessed: Int
    public let averageRequestDuration: TimeInterval
    public let averageBatchSize: Double
    public let concurrentRequestsActive: Int
    public let deduplicationSavings: Int
    public let circuitBreakerTrips: Int
    public let throughputPerSecond: Double
    public let queueWaitTime: TimeInterval
    public let retryRate: Double
    public let errorsByType: [String: Int]
    public let requestsByPriority: [String: Int]
    
    public init(
        queueSize: Int = 0,
        totalRequestsQueued: Int = 0,
        totalRequestsProcessed: Int = 0,
        totalRequestsFailed: Int = 0,
        totalBatchesProcessed: Int = 0,
        averageRequestDuration: TimeInterval = 0,
        averageBatchSize: Double = 0,
        concurrentRequestsActive: Int = 0,
        deduplicationSavings: Int = 0,
        circuitBreakerTrips: Int = 0,
        throughputPerSecond: Double = 0,
        queueWaitTime: TimeInterval = 0,
        retryRate: Double = 0,
        errorsByType: [String: Int] = [:],
        requestsByPriority: [String: Int] = [:]
    ) {
        self.queueSize = queueSize
        self.totalRequestsQueued = totalRequestsQueued
        self.totalRequestsProcessed = totalRequestsProcessed
        self.totalRequestsFailed = totalRequestsFailed
        self.totalBatchesProcessed = totalBatchesProcessed
        self.averageRequestDuration = averageRequestDuration
        self.averageBatchSize = averageBatchSize
        self.concurrentRequestsActive = concurrentRequestsActive
        self.deduplicationSavings = deduplicationSavings
        self.circuitBreakerTrips = circuitBreakerTrips
        self.throughputPerSecond = throughputPerSecond
        self.queueWaitTime = queueWaitTime
        self.retryRate = retryRate
        self.errorsByType = errorsByType
        self.requestsByPriority = requestsByPriority
    }
    
    public var successRate: Double {
        let total = totalRequestsProcessed + totalRequestsFailed
        return total > 0 ? Double(totalRequestsProcessed) / Double(total) : 0
    }
    
    public var queueUtilization: Double {
        queueSize > 0 ? Double(queueSize) / 10000.0 : 0 // Assuming max queue size of 10000
    }
}

// MARK: - Request Queue Resource

/// Request queue resource management
public actor RequestQueueCapabilityResource: AxiomCapabilityResource {
    private let configuration: RequestQueueCapabilityConfiguration
    private var requestQueue: [QueuedRequest] = []
    private var activeRequests: Set<UUID> = []
    private var deduplicationCache: [String: UUID] = [:]
    private var circuitBreakerState: CircuitBreakerState = .closed
    private var circuitBreakerFailureCount: Int = 0
    private var metrics: RequestQueueMetrics = RequestQueueMetrics()
    private var batchTimer: Timer?
    private var currentBatch: [QueuedRequest] = []
    private var throughputTracker: [Date] = []
    private var resultStreamContinuation: AsyncStream<RequestResult>.Continuation?
    
    public init(configuration: RequestQueueCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxQueueSize * 25_000 + configuration.maxConcurrentRequests * 1_000_000,
            cpu: Double(configuration.maxConcurrentRequests * 2), // 2% per concurrent request
            bandwidth: configuration.maxThroughputPerSecond * 10_000, // 10KB per request
            storage: configuration.maxQueueSize * 5_000
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let queueMemory = requestQueue.count * 12_500
            let activeMemory = activeRequests.count * 500_000
            
            return ResourceUsage(
                memory: queueMemory + activeMemory,
                cpu: Double(activeRequests.count),
                bandwidth: activeRequests.count * 5_000,
                storage: requestQueue.count * 2_500
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        circuitBreakerState != .open(openedAt: Date())
    }
    
    public func release() async {
        batchTimer?.invalidate()
        batchTimer = nil
        requestQueue.removeAll()
        activeRequests.removeAll()
        deduplicationCache.removeAll()
        currentBatch.removeAll()
        throughputTracker.removeAll()
        resultStreamContinuation?.finish()
        metrics = RequestQueueMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        if configuration.enableBatching {
            await startBatchTimer()
        }
    }
    
    internal func updateConfiguration(_ configuration: RequestQueueCapabilityConfiguration) async throws {
        // Update batch timer if batching settings changed
        if configuration.enableBatching && configuration.batchTimeout != self.configuration.batchTimeout {
            await startBatchTimer()
        }
        
        // Trim queue if max size reduced
        if configuration.maxQueueSize < requestQueue.count {
            requestQueue = Array(requestQueue.prefix(configuration.maxQueueSize))
        }
    }
    
    // MARK: - Request Queuing
    
    public func enqueue(_ request: QueuedRequest) async throws {
        // Check queue capacity
        guard requestQueue.count < configuration.maxQueueSize else {
            throw RequestQueueError.queueFull(configuration.maxQueueSize)
        }
        
        // Check circuit breaker
        guard await isCircuitBreakerClosed() else {
            throw RequestQueueError.circuitBreakerOpen
        }
        
        // Handle deduplication
        if configuration.enableDeduplication, let dedupKey = request.deduplicationKey {
            if let existingId = deduplicationCache[dedupKey] {
                if requestQueue.contains(where: { $0.id == existingId }) {
                    await updateDeduplicationMetrics()
                    return // Skip duplicate
                }
            }
            deduplicationCache[dedupKey] = request.id
        }
        
        // Insert based on priority if prioritization is enabled
        if configuration.enablePrioritization {
            let insertIndex = requestQueue.firstIndex { $0.priority < request.priority } ?? requestQueue.count
            requestQueue.insert(request, at: insertIndex)
        } else {
            requestQueue.append(request)
        }
        
        await updateQueueMetrics()
        
        if configuration.enableLogging {
            await logQueueOperation("ENQUEUED", request: request)
        }
        
        // Try immediate processing if there's capacity
        await processQueueIfPossible()
    }
    
    public func enqueue(_ urlRequest: URLRequest, priority: QueuedRequest.RequestPriority = .normal) async throws {
        let queuedRequest = QueuedRequest(request: urlRequest, priority: priority)
        try await enqueue(queuedRequest)
    }
    
    public func getQueuedRequests() async -> [QueuedRequest] {
        requestQueue
    }
    
    public func getQueuedRequest(_ id: UUID) async -> QueuedRequest? {
        requestQueue.first { $0.id == id }
    }
    
    public func removeQueuedRequest(_ id: UUID) async {
        requestQueue.removeAll { $0.id == id }
        await updateQueueMetrics()
    }
    
    public func clearQueue() async {
        requestQueue.removeAll()
        deduplicationCache.removeAll()
        await updateQueueMetrics()
    }
    
    // MARK: - Request Processing
    
    public var resultStream: AsyncStream<RequestResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    public func processNext() async -> RequestResult? {
        guard let request = await getNextRequest() else { return nil }
        return await processRequest(request)
    }
    
    public func processBatch() async -> [RequestResult] {
        let batch = await getNextBatch()
        return await processBatch(batch)
    }
    
    public func forceProcess(_ requestId: UUID) async -> RequestResult? {
        guard let index = requestQueue.firstIndex(where: { $0.id == requestId }) else {
            return nil
        }
        
        let request = requestQueue.remove(at: index)
        return await processRequest(request)
    }
    
    // MARK: - Circuit Breaker
    
    public func getCircuitBreakerState() async -> CircuitBreakerState {
        circuitBreakerState
    }
    
    public func resetCircuitBreaker() async {
        circuitBreakerState = .closed
        circuitBreakerFailureCount = 0
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> RequestQueueMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = RequestQueueMetrics()
    }
    
    // MARK: - Private Methods
    
    private func processQueueIfPossible() async {
        while activeRequests.count < configuration.maxConcurrentRequests && !requestQueue.isEmpty {
            if await checkThroughputLimit() {
                break
            }
            
            if configuration.enableBatching && currentBatch.count < configuration.maxBatchSize {
                if let request = await getNextRequest() {
                    if request.batchable {
                        currentBatch.append(request)
                        continue
                    } else {
                        // Process non-batchable request immediately
                        Task {
                            await processRequest(request)
                        }
                    }
                }
            } else {
                if let request = await getNextRequest() {
                    Task {
                        await processRequest(request)
                    }
                }
            }
        }
    }
    
    private func getNextRequest() async -> QueuedRequest? {
        guard !requestQueue.isEmpty else { return nil }
        
        // Find next scheduled request
        let now = Date()
        let availableIndex = requestQueue.firstIndex { request in
            request.isScheduled && (request.scheduledAt == nil || request.scheduledAt! <= now)
        }
        
        guard let index = availableIndex else { return nil }
        
        return requestQueue.remove(at: index)
    }
    
    private func getNextBatch() async -> RequestBatch {
        guard configuration.enableBatching else {
            if let request = await getNextRequest() {
                return RequestBatch(requests: [request])
            }
            return RequestBatch(requests: [])
        }
        
        var batchRequests: [QueuedRequest] = []
        let maxSize = min(configuration.maxBatchSize, requestQueue.count)
        
        for _ in 0..<maxSize {
            guard let request = await getNextRequest() else { break }
            if request.batchable {
                batchRequests.append(request)
            } else {
                // Process non-batchable immediately
                Task {
                    await processRequest(request)
                }
            }
        }
        
        return RequestBatch(requests: batchRequests)
    }
    
    private func processRequest(_ request: QueuedRequest) async -> RequestResult {
        let startTime = Date()
        activeRequests.insert(request.id)
        
        defer {
            activeRequests.remove(request.id)
        }
        
        // Check circuit breaker
        guard await isCircuitBreakerClosed() else {
            return RequestResult(
                requestId: request.id,
                success: false,
                error: RequestQueueError.circuitBreakerOpen,
                duration: Date().timeIntervalSince(startTime),
                attemptCount: request.attemptCount + 1,
                circuitBreakerTripped: true
            )
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request.request)
            let httpResponse = response as? HTTPURLResponse
            let duration = Date().timeIntervalSince(startTime)
            
            let result = RequestResult(
                requestId: request.id,
                success: true,
                response: httpResponse,
                data: data,
                duration: duration,
                attemptCount: request.attemptCount + 1
            )
            
            await handleRequestSuccess()
            await updateSuccessMetrics(duration: duration)
            await updateThroughputTracking()
            
            resultStreamContinuation?.yield(result)
            
            if configuration.enableLogging {
                await logRequestResult(result, request: request)
            }
            
            return result
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            await handleRequestFailure(error: error)
            
            let result = RequestResult(
                requestId: request.id,
                success: false,
                error: error,
                duration: duration,
                attemptCount: request.attemptCount + 1
            )
            
            // Handle retry if applicable
            if request.canRetry && await isRetryable(error: error) {
                let retryRequest = request.withRetry()
                try? await enqueue(retryRequest)
            }
            
            await updateFailureMetrics(error: error)
            
            resultStreamContinuation?.yield(result)
            
            if configuration.enableLogging {
                await logRequestResult(result, request: request)
            }
            
            return result
        }
    }
    
    private func processBatch(_ batch: RequestBatch) async -> [RequestResult] {
        guard !batch.isEmpty else { return [] }
        
        var results: [RequestResult] = []
        
        // Process all requests in batch concurrently
        await withTaskGroup(of: RequestResult.self) { group in
            for request in batch.requests {
                group.addTask {
                    await self.processRequest(request)
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        await updateBatchMetrics(batchSize: batch.size)
        
        if configuration.enableLogging {
            print("[RequestQueue] 📦 Processed batch: \(batch.size) requests")
        }
        
        return results
    }
    
    private func startBatchTimer() async {
        batchTimer?.invalidate()
        
        batchTimer = Timer.scheduledTimer(withTimeInterval: configuration.batchTimeout, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.flushCurrentBatch()
            }
        }
    }
    
    private func flushCurrentBatch() async {
        guard !currentBatch.isEmpty else { return }
        
        let batch = RequestBatch(requests: currentBatch)
        currentBatch.removeAll()
        
        Task {
            await processBatch(batch)
        }
    }
    
    private func isCircuitBreakerClosed() async -> Bool {
        switch circuitBreakerState {
        case .closed:
            return true
        case .open(let openedAt):
            if Date().timeIntervalSince(openedAt) > configuration.circuitBreakerTimeout {
                circuitBreakerState = .halfOpen
                return true
            }
            return false
        case .halfOpen:
            return true
        }
    }
    
    private func handleRequestSuccess() async {
        if case .halfOpen = circuitBreakerState {
            circuitBreakerState = .closed
            circuitBreakerFailureCount = 0
        }
    }
    
    private func handleRequestFailure(error: Error) async {
        guard configuration.enableCircuitBreaker else { return }
        
        circuitBreakerFailureCount += 1
        
        if circuitBreakerFailureCount >= configuration.circuitBreakerThreshold {
            circuitBreakerState = .open(openedAt: Date())
            await updateCircuitBreakerMetrics()
        }
    }
    
    private func isRetryable(error: Error) async -> Bool {
        // Determine if error is retryable based on error type
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func checkThroughputLimit() async -> Bool {
        guard configuration.queueThrottlingEnabled else { return false }
        
        let now = Date()
        let oneSecondAgo = now.addingTimeInterval(-1.0)
        
        // Remove old entries
        throughputTracker.removeAll { $0 < oneSecondAgo }
        
        return throughputTracker.count >= configuration.maxThroughputPerSecond
    }
    
    private func updateThroughputTracking() async {
        throughputTracker.append(Date())
        
        // Keep only last second of data
        let oneSecondAgo = Date().addingTimeInterval(-1.0)
        throughputTracker.removeAll { $0 < oneSecondAgo }
    }
    
    private func updateQueueMetrics() async {
        metrics = RequestQueueMetrics(
            queueSize: requestQueue.count,
            totalRequestsQueued: metrics.totalRequestsQueued + 1,
            totalRequestsProcessed: metrics.totalRequestsProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed,
            totalBatchesProcessed: metrics.totalBatchesProcessed,
            averageRequestDuration: metrics.averageRequestDuration,
            averageBatchSize: metrics.averageBatchSize,
            concurrentRequestsActive: activeRequests.count,
            deduplicationSavings: metrics.deduplicationSavings,
            circuitBreakerTrips: metrics.circuitBreakerTrips,
            throughputPerSecond: Double(throughputTracker.count),
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: metrics.errorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func updateSuccessMetrics(duration: TimeInterval) async {
        let totalProcessed = metrics.totalRequestsProcessed + 1
        let newAverage = ((metrics.averageRequestDuration * Double(metrics.totalRequestsProcessed)) + duration) / Double(totalProcessed)
        
        metrics = RequestQueueMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsProcessed: totalProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed,
            totalBatchesProcessed: metrics.totalBatchesProcessed,
            averageRequestDuration: newAverage,
            averageBatchSize: metrics.averageBatchSize,
            concurrentRequestsActive: metrics.concurrentRequestsActive,
            deduplicationSavings: metrics.deduplicationSavings,
            circuitBreakerTrips: metrics.circuitBreakerTrips,
            throughputPerSecond: metrics.throughputPerSecond,
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: metrics.errorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func updateFailureMetrics(error: Error) async {
        var newErrorsByType = metrics.errorsByType
        let errorType = String(describing: type(of: error))
        newErrorsByType[errorType, default: 0] += 1
        
        metrics = RequestQueueMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsProcessed: metrics.totalRequestsProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed + 1,
            totalBatchesProcessed: metrics.totalBatchesProcessed,
            averageRequestDuration: metrics.averageRequestDuration,
            averageBatchSize: metrics.averageBatchSize,
            concurrentRequestsActive: metrics.concurrentRequestsActive,
            deduplicationSavings: metrics.deduplicationSavings,
            circuitBreakerTrips: metrics.circuitBreakerTrips,
            throughputPerSecond: metrics.throughputPerSecond,
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: newErrorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func updateBatchMetrics(batchSize: Int) async {
        let totalBatches = metrics.totalBatchesProcessed + 1
        let newAverageSize = ((metrics.averageBatchSize * Double(metrics.totalBatchesProcessed)) + Double(batchSize)) / Double(totalBatches)
        
        metrics = RequestQueueMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsProcessed: metrics.totalRequestsProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed,
            totalBatchesProcessed: totalBatches,
            averageRequestDuration: metrics.averageRequestDuration,
            averageBatchSize: newAverageSize,
            concurrentRequestsActive: metrics.concurrentRequestsActive,
            deduplicationSavings: metrics.deduplicationSavings,
            circuitBreakerTrips: metrics.circuitBreakerTrips,
            throughputPerSecond: metrics.throughputPerSecond,
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: metrics.errorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func updateDeduplicationMetrics() async {
        metrics = RequestQueueMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsProcessed: metrics.totalRequestsProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed,
            totalBatchesProcessed: metrics.totalBatchesProcessed,
            averageRequestDuration: metrics.averageRequestDuration,
            averageBatchSize: metrics.averageBatchSize,
            concurrentRequestsActive: metrics.concurrentRequestsActive,
            deduplicationSavings: metrics.deduplicationSavings + 1,
            circuitBreakerTrips: metrics.circuitBreakerTrips,
            throughputPerSecond: metrics.throughputPerSecond,
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: metrics.errorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func updateCircuitBreakerMetrics() async {
        metrics = RequestQueueMetrics(
            queueSize: metrics.queueSize,
            totalRequestsQueued: metrics.totalRequestsQueued,
            totalRequestsProcessed: metrics.totalRequestsProcessed,
            totalRequestsFailed: metrics.totalRequestsFailed,
            totalBatchesProcessed: metrics.totalBatchesProcessed,
            averageRequestDuration: metrics.averageRequestDuration,
            averageBatchSize: metrics.averageBatchSize,
            concurrentRequestsActive: metrics.concurrentRequestsActive,
            deduplicationSavings: metrics.deduplicationSavings,
            circuitBreakerTrips: metrics.circuitBreakerTrips + 1,
            throughputPerSecond: metrics.throughputPerSecond,
            queueWaitTime: metrics.queueWaitTime,
            retryRate: metrics.retryRate,
            errorsByType: metrics.errorsByType,
            requestsByPriority: metrics.requestsByPriority
        )
    }
    
    private func logQueueOperation(_ operation: String, request: QueuedRequest) async {
        print("[RequestQueue] 📝 \(operation): \(request.request.httpMethod ?? "GET") \(request.request.url?.absoluteString ?? "unknown") (priority: \(request.priority))")
    }
    
    private func logRequestResult(_ result: RequestResult, request: QueuedRequest) async {
        let status = result.success ? "✅ SUCCESS" : "❌ FAILED"
        print("[RequestQueue] \(status): \(request.request.httpMethod ?? "GET") \(request.request.url?.absoluteString ?? "unknown") (\(String(format: "%.2f", result.duration))s)")
        
        if let error = result.error {
            print("[RequestQueue] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Request Queue Capability Implementation

/// Request Queue capability providing advanced request queuing and batching
public actor RequestQueueCapability: DomainCapability {
    public typealias ConfigurationType = RequestQueueCapabilityConfiguration
    public typealias ResourceType = RequestQueueCapabilityResource
    
    private var _configuration: RequestQueueCapabilityConfiguration
    private var _resources: RequestQueueCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "request-queue-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: RequestQueueCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: RequestQueueCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: RequestQueueCapabilityConfiguration = RequestQueueCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = RequestQueueCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: RequestQueueCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Request Queue configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // Request queuing is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Request queue doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Request Queue Operations
    
    /// Enqueue a request for processing
    public func enqueue(_ request: QueuedRequest) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        try await _resources.enqueue(request)
    }
    
    /// Enqueue a URL request for processing
    public func enqueue(_ urlRequest: URLRequest, priority: QueuedRequest.RequestPriority = .normal) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        try await _resources.enqueue(urlRequest, priority: priority)
    }
    
    /// Get queued requests
    public func getQueuedRequests() async throws -> [QueuedRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.getQueuedRequests()
    }
    
    /// Get specific queued request
    public func getQueuedRequest(_ id: UUID) async throws -> QueuedRequest? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.getQueuedRequest(id)
    }
    
    /// Remove queued request
    public func removeQueuedRequest(_ id: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        await _resources.removeQueuedRequest(id)
    }
    
    /// Clear all queued requests
    public func clearQueue() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        await _resources.clearQueue()
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<RequestResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Process next request in queue
    public func processNext() async throws -> RequestResult? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.processNext()
    }
    
    /// Process next batch of requests
    public func processBatch() async throws -> [RequestResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.processBatch()
    }
    
    /// Force process specific request
    public func forceProcess(_ requestId: UUID) async throws -> RequestResult? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.forceProcess(requestId)
    }
    
    /// Get circuit breaker state
    public func getCircuitBreakerState() async throws -> CircuitBreakerState {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.getCircuitBreakerState()
    }
    
    /// Reset circuit breaker
    public func resetCircuitBreaker() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        await _resources.resetCircuitBreaker()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> RequestQueueMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Request Queue capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Enqueue GET request
    public func get(_ url: URL, priority: QueuedRequest.RequestPriority = .normal) async throws {
        let request = URLRequest(url: url)
        try await enqueue(request, priority: priority)
    }
    
    /// Enqueue POST request
    public func post(_ url: URL, body: Data? = nil, priority: QueuedRequest.RequestPriority = .normal) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        try await enqueue(request, priority: priority)
    }
    
    /// Enqueue multiple requests with same priority
    public func enqueueMultiple(_ requests: [URLRequest], priority: QueuedRequest.RequestPriority = .normal) async throws {
        for request in requests {
            try await enqueue(request, priority: priority)
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Request Queue specific errors
public enum RequestQueueError: Error, LocalizedError {
    case queueFull(Int)
    case circuitBreakerOpen
    case invalidRequest(String)
    case processingFailed(String)
    case batchingError(String)
    case deduplicationError(String)
    case retryLimitExceeded(Int)
    
    public var errorDescription: String? {
        switch self {
        case .queueFull(let maxSize):
            return "Request queue is full (max: \(maxSize))"
        case .circuitBreakerOpen:
            return "Circuit breaker is open, requests are being rejected"
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .processingFailed(let reason):
            return "Request processing failed: \(reason)"
        case .batchingError(let reason):
            return "Batching error: \(reason)"
        case .deduplicationError(let reason):
            return "Deduplication error: \(reason)"
        case .retryLimitExceeded(let maxRetries):
            return "Retry limit exceeded (max: \(maxRetries))"
        }
    }
}