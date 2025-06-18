import Foundation
import AxiomCore
import AxiomCapabilities

// MARK: - Rate Limit Capability Configuration

/// Configuration for Rate Limit capability
public struct RateLimitCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let globalRateLimit: RateLimit
    public let perEndpointLimits: [String: RateLimit]
    public let perUserLimits: [String: RateLimit]
    public let enableSlidingWindow: Bool
    public let enableTokenBucket: Bool
    public let enableLeakyBucket: Bool
    public let defaultBucketSize: Int
    public let defaultRefillRate: Double
    public let enableDistributedLimiting: Bool
    public let distributedSyncInterval: TimeInterval
    public let enableRateLimitHeaders: Bool
    public let enableQuotaSystem: Bool
    public let enableBurstAllowance: Bool
    public let burstMultiplier: Double
    public let enableAdaptiveRateLimit: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableWarnings: Bool
    public let warningThreshold: Double
    public let enableGracePeriod: Bool
    public let gracePeriodDuration: TimeInterval
    public let enablePrioritization: Bool
    public let enableWhitelist: Bool
    public let whitelistedEndpoints: Set<String>
    
    public init(
        globalRateLimit: RateLimit = RateLimit(requests: 1000, window: .hour),
        perEndpointLimits: [String: RateLimit] = [:],
        perUserLimits: [String: RateLimit] = [:],
        enableSlidingWindow: Bool = true,
        enableTokenBucket: Bool = true,
        enableLeakyBucket: Bool = false,
        defaultBucketSize: Int = 100,
        defaultRefillRate: Double = 10.0, // tokens per second
        enableDistributedLimiting: Bool = false,
        distributedSyncInterval: TimeInterval = 5.0,
        enableRateLimitHeaders: Bool = true,
        enableQuotaSystem: Bool = true,
        enableBurstAllowance: Bool = true,
        burstMultiplier: Double = 2.0,
        enableAdaptiveRateLimit: Bool = false,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableWarnings: Bool = true,
        warningThreshold: Double = 0.8, // 80% of limit
        enableGracePeriod: Bool = true,
        gracePeriodDuration: TimeInterval = 60.0,
        enablePrioritization: Bool = true,
        enableWhitelist: Bool = true,
        whitelistedEndpoints: Set<String> = ["/health", "/ping"]
    ) {
        self.globalRateLimit = globalRateLimit
        self.perEndpointLimits = perEndpointLimits
        self.perUserLimits = perUserLimits
        self.enableSlidingWindow = enableSlidingWindow
        self.enableTokenBucket = enableTokenBucket
        self.enableLeakyBucket = enableLeakyBucket
        self.defaultBucketSize = defaultBucketSize
        self.defaultRefillRate = defaultRefillRate
        self.enableDistributedLimiting = enableDistributedLimiting
        self.distributedSyncInterval = distributedSyncInterval
        self.enableRateLimitHeaders = enableRateLimitHeaders
        self.enableQuotaSystem = enableQuotaSystem
        self.enableBurstAllowance = enableBurstAllowance
        self.burstMultiplier = burstMultiplier
        self.enableAdaptiveRateLimit = enableAdaptiveRateLimit
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableWarnings = enableWarnings
        self.warningThreshold = warningThreshold
        self.enableGracePeriod = enableGracePeriod
        self.gracePeriodDuration = gracePeriodDuration
        self.enablePrioritization = enablePrioritization
        self.enableWhitelist = enableWhitelist
        self.whitelistedEndpoints = whitelistedEndpoints
    }
    
    public var isValid: Bool {
        globalRateLimit.isValid &&
        defaultBucketSize > 0 &&
        defaultRefillRate > 0 &&
        distributedSyncInterval > 0 &&
        burstMultiplier > 0 &&
        warningThreshold > 0 && warningThreshold <= 1.0 &&
        gracePeriodDuration > 0
    }
    
    public func merged(with other: RateLimitCapabilityConfiguration) -> RateLimitCapabilityConfiguration {
        RateLimitCapabilityConfiguration(
            globalRateLimit: other.globalRateLimit,
            perEndpointLimits: perEndpointLimits.merging(other.perEndpointLimits) { _, new in new },
            perUserLimits: perUserLimits.merging(other.perUserLimits) { _, new in new },
            enableSlidingWindow: other.enableSlidingWindow,
            enableTokenBucket: other.enableTokenBucket,
            enableLeakyBucket: other.enableLeakyBucket,
            defaultBucketSize: other.defaultBucketSize,
            defaultRefillRate: other.defaultRefillRate,
            enableDistributedLimiting: other.enableDistributedLimiting,
            distributedSyncInterval: other.distributedSyncInterval,
            enableRateLimitHeaders: other.enableRateLimitHeaders,
            enableQuotaSystem: other.enableQuotaSystem,
            enableBurstAllowance: other.enableBurstAllowance,
            burstMultiplier: other.burstMultiplier,
            enableAdaptiveRateLimit: other.enableAdaptiveRateLimit,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableWarnings: other.enableWarnings,
            warningThreshold: other.warningThreshold,
            enableGracePeriod: other.enableGracePeriod,
            gracePeriodDuration: other.gracePeriodDuration,
            enablePrioritization: other.enablePrioritization,
            enableWhitelist: other.enableWhitelist,
            whitelistedEndpoints: whitelistedEndpoints.union(other.whitelistedEndpoints)
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> RateLimitCapabilityConfiguration {
        var adjustedGlobalLimit = globalRateLimit
        var adjustedBucketSize = defaultBucketSize
        var adjustedRefillRate = defaultRefillRate
        var adjustedLogging = enableLogging
        
        if environment.isLowPowerMode {
            // Reduce limits in low power mode
            adjustedGlobalLimit = RateLimit(
                requests: Int(Double(globalRateLimit.requests) * 0.5),
                window: globalRateLimit.window
            )
            adjustedBucketSize = Int(Double(defaultBucketSize) * 0.5)
            adjustedRefillRate = defaultRefillRate * 0.5
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return RateLimitCapabilityConfiguration(
            globalRateLimit: adjustedGlobalLimit,
            perEndpointLimits: perEndpointLimits,
            perUserLimits: perUserLimits,
            enableSlidingWindow: enableSlidingWindow,
            enableTokenBucket: enableTokenBucket,
            enableLeakyBucket: enableLeakyBucket,
            defaultBucketSize: adjustedBucketSize,
            defaultRefillRate: adjustedRefillRate,
            enableDistributedLimiting: enableDistributedLimiting,
            distributedSyncInterval: distributedSyncInterval,
            enableRateLimitHeaders: enableRateLimitHeaders,
            enableQuotaSystem: enableQuotaSystem,
            enableBurstAllowance: enableBurstAllowance,
            burstMultiplier: burstMultiplier,
            enableAdaptiveRateLimit: enableAdaptiveRateLimit,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableWarnings: enableWarnings,
            warningThreshold: warningThreshold,
            enableGracePeriod: enableGracePeriod,
            gracePeriodDuration: gracePeriodDuration,
            enablePrioritization: enablePrioritization,
            enableWhitelist: enableWhitelist,
            whitelistedEndpoints: whitelistedEndpoints
        )
    }
}

// MARK: - Rate Limit Types

/// Rate limit definition
public struct RateLimit: Sendable, Codable {
    public let requests: Int
    public let window: TimeWindow
    public let algorithm: Algorithm
    
    public enum TimeWindow: Sendable, Codable {
        case second
        case minute
        case hour
        case day
        case custom(TimeInterval)
        
        public var duration: TimeInterval {
            switch self {
            case .second: return 1.0
            case .minute: return 60.0
            case .hour: return 3600.0
            case .day: return 86400.0
            case .custom(let interval): return interval
            }
        }
    }
    
    public enum Algorithm: String, Sendable, Codable, CaseIterable {
        case fixedWindow = "fixed-window"
        case slidingWindow = "sliding-window"
        case tokenBucket = "token-bucket"
        case leakyBucket = "leaky-bucket"
    }
    
    public init(requests: Int, window: TimeWindow, algorithm: Algorithm = .slidingWindow) {
        self.requests = requests
        self.window = window
        self.algorithm = algorithm
    }
    
    public var isValid: Bool {
        requests > 0 && window.duration > 0
    }
    
    public var requestsPerSecond: Double {
        Double(requests) / window.duration
    }
}

/// Rate limit status for a specific key
public struct RateLimitStatus: Sendable {
    public let key: String
    public let limit: Int
    public let remaining: Int
    public let resetTime: Date
    public let retryAfter: TimeInterval?
    public let isExceeded: Bool
    public let currentWindow: TimeInterval
    public let algorithm: RateLimit.Algorithm
    
    public init(
        key: String,
        limit: Int,
        remaining: Int,
        resetTime: Date,
        retryAfter: TimeInterval? = nil,
        currentWindow: TimeInterval,
        algorithm: RateLimit.Algorithm
    ) {
        self.key = key
        self.limit = limit
        self.remaining = remaining
        self.resetTime = resetTime
        self.retryAfter = retryAfter
        self.isExceeded = remaining <= 0
        self.currentWindow = currentWindow
        self.algorithm = algorithm
    }
    
    public var utilizationPercentage: Double {
        let used = Double(limit - remaining)
        return limit > 0 ? (used / Double(limit)) * 100.0 : 0.0
    }
    
    public var isNearLimit: Bool {
        utilizationPercentage >= 80.0
    }
}

/// Request context for rate limiting
public struct RateLimitContext: Sendable {
    public let endpoint: String
    public let userId: String?
    public let clientId: String?
    public let ipAddress: String?
    public let userAgent: String?
    public let priority: RequestPriority
    public let weight: Int
    public let metadata: [String: String]
    
    public enum RequestPriority: Int, Sendable, Codable, CaseIterable, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        case system = 4
        
        public static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public init(
        endpoint: String,
        userId: String? = nil,
        clientId: String? = nil,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        priority: RequestPriority = .normal,
        weight: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.endpoint = endpoint
        self.userId = userId
        self.clientId = clientId
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.priority = priority
        self.weight = weight
        self.metadata = metadata
    }
    
    public var rateLimitKeys: [String] {
        var keys: [String] = []
        
        // Global key
        keys.append("global")
        
        // Endpoint-specific key
        keys.append("endpoint:\(endpoint)")
        
        // User-specific key
        if let userId = userId {
            keys.append("user:\(userId)")
        }
        
        // Client-specific key
        if let clientId = clientId {
            keys.append("client:\(clientId)")
        }
        
        // IP-specific key
        if let ipAddress = ipAddress {
            keys.append("ip:\(ipAddress)")
        }
        
        return keys
    }
}

/// Rate limit violation information
public struct RateLimitViolation: Sendable {
    public let key: String
    public let context: RateLimitContext
    public let limit: RateLimit
    public let actualRequests: Int
    public let timestamp: Date
    public let violationType: ViolationType
    public let severity: Severity
    
    public enum ViolationType: String, Sendable, Codable, CaseIterable {
        case softLimit = "soft-limit"
        case hardLimit = "hard-limit"
        case burstLimit = "burst-limit"
        case quotaExceeded = "quota-exceeded"
    }
    
    public enum Severity: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public init(
        key: String,
        context: RateLimitContext,
        limit: RateLimit,
        actualRequests: Int,
        violationType: ViolationType = .hardLimit,
        severity: Severity = .medium
    ) {
        self.key = key
        self.context = context
        self.limit = limit
        self.actualRequests = actualRequests
        self.timestamp = Date()
        self.violationType = violationType
        self.severity = severity
    }
}

/// Rate limit metrics
public struct RateLimitMetrics: Sendable {
    public let totalRequests: Int
    public let totalRejections: Int
    public let totalViolations: Int
    public let averageResponseTime: TimeInterval
    public let currentThroughput: Double
    public let peakThroughput: Double
    public let bucketOverflows: Int
    public let adaptiveAdjustments: Int
    public let violationsByEndpoint: [String: Int]
    public let violationsByUser: [String: Int]
    public let requestsByPriority: [String: Int]
    public let quotaUtilization: [String: Double]
    
    public init(
        totalRequests: Int = 0,
        totalRejections: Int = 0,
        totalViolations: Int = 0,
        averageResponseTime: TimeInterval = 0,
        currentThroughput: Double = 0,
        peakThroughput: Double = 0,
        bucketOverflows: Int = 0,
        adaptiveAdjustments: Int = 0,
        violationsByEndpoint: [String: Int] = [:],
        violationsByUser: [String: Int] = [:],
        requestsByPriority: [String: Int] = [:],
        quotaUtilization: [String: Double] = [:]
    ) {
        self.totalRequests = totalRequests
        self.totalRejections = totalRejections
        self.totalViolations = totalViolations
        self.averageResponseTime = averageResponseTime
        self.currentThroughput = currentThroughput
        self.peakThroughput = peakThroughput
        self.bucketOverflows = bucketOverflows
        self.adaptiveAdjustments = adaptiveAdjustments
        self.violationsByEndpoint = violationsByEndpoint
        self.violationsByUser = violationsByUser
        self.requestsByPriority = requestsByPriority
        self.quotaUtilization = quotaUtilization
    }
    
    public var rejectionRate: Double {
        totalRequests > 0 ? Double(totalRejections) / Double(totalRequests) : 0
    }
    
    public var violationRate: Double {
        totalRequests > 0 ? Double(totalViolations) / Double(totalRequests) : 0
    }
    
    public var approvalRate: Double {
        1.0 - rejectionRate
    }
}

// MARK: - Rate Limit Resource

/// Rate limit resource management
public actor RateLimitCapabilityResource: AxiomCapabilityResource {
    private let configuration: RateLimitCapabilityConfiguration
    private var tokenBuckets: [String: TokenBucket] = [:]
    private var slidingWindows: [String: SlidingWindow] = [:]
    private var leakyBuckets: [String: LeakyBucket] = [:]
    private var fixedWindows: [String: FixedWindow] = [:]
    private var quotaTracker: [String: QuotaStatus] = [:]
    private var metrics: RateLimitMetrics = RateLimitMetrics()
    private var violationStreamContinuation: AsyncStream<RateLimitViolation>.Continuation?
    private var distributedSyncTimer: Timer?
    
    // Rate limiting algorithms
    private struct TokenBucket {
        let capacity: Int
        let refillRate: Double
        var tokens: Double
        var lastRefill: Date
        
        init(capacity: Int, refillRate: Double) {
            self.capacity = capacity
            self.refillRate = refillRate
            self.tokens = Double(capacity)
            self.lastRefill = Date()
        }
        
        mutating func tryConsume(tokens: Int = 1) -> Bool {
            refill()
            
            if self.tokens >= Double(tokens) {
                self.tokens -= Double(tokens)
                return true
            }
            return false
        }
        
        mutating func refill() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRefill)
            let tokensToAdd = elapsed * refillRate
            
            tokens = min(Double(capacity), tokens + tokensToAdd)
            lastRefill = now
        }
        
        func status(limit: Int, resetTime: Date) -> RateLimitStatus {
            return RateLimitStatus(
                key: "",
                limit: limit,
                remaining: Int(tokens),
                resetTime: resetTime,
                currentWindow: 0,
                algorithm: .tokenBucket
            )
        }
    }
    
    private struct SlidingWindow {
        private var requests: [Date] = []
        private let windowSize: TimeInterval
        
        init(windowSize: TimeInterval) {
            self.windowSize = windowSize
        }
        
        mutating func addRequest(at timestamp: Date = Date()) -> Bool {
            cleanOldRequests(before: timestamp.addingTimeInterval(-windowSize))
            requests.append(timestamp)
            return true
        }
        
        mutating func requestCount(at timestamp: Date = Date()) -> Int {
            cleanOldRequests(before: timestamp.addingTimeInterval(-windowSize))
            return requests.count
        }
        
        private mutating func cleanOldRequests(before cutoff: Date) {
            requests.removeAll { $0 < cutoff }
        }
        
        func status(limit: Int, windowSize: TimeInterval) -> RateLimitStatus {
            let resetTime = Date().addingTimeInterval(windowSize)
            let remaining = max(0, limit - requests.count)
            
            return RateLimitStatus(
                key: "",
                limit: limit,
                remaining: remaining,
                resetTime: resetTime,
                currentWindow: windowSize,
                algorithm: .slidingWindow
            )
        }
    }
    
    private struct LeakyBucket {
        let capacity: Int
        let leakRate: Double
        var level: Double
        var lastLeak: Date
        
        init(capacity: Int, leakRate: Double) {
            self.capacity = capacity
            self.leakRate = leakRate
            self.level = 0.0
            self.lastLeak = Date()
        }
        
        mutating func tryAdd(amount: Double = 1.0) -> Bool {
            leak()
            
            if level + amount <= Double(capacity) {
                level += amount
                return true
            }
            return false
        }
        
        mutating func leak() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastLeak)
            let leakAmount = elapsed * leakRate
            
            level = max(0.0, level - leakAmount)
            lastLeak = now
        }
        
        func status(limit: Int, resetTime: Date) -> RateLimitStatus {
            let remaining = max(0, limit - Int(level))
            
            return RateLimitStatus(
                key: "",
                limit: limit,
                remaining: remaining,
                resetTime: resetTime,
                currentWindow: 0,
                algorithm: .leakyBucket
            )
        }
    }
    
    private struct FixedWindow {
        var count: Int
        var windowStart: Date
        let windowSize: TimeInterval
        
        init(windowSize: TimeInterval) {
            self.count = 0
            self.windowStart = Date()
            self.windowSize = windowSize
        }
        
        mutating func addRequest(at timestamp: Date = Date()) -> Bool {
            if timestamp.timeIntervalSince(windowStart) >= windowSize {
                // Reset window
                count = 0
                windowStart = timestamp
            }
            
            count += 1
            return true
        }
        
        func requestCount(at timestamp: Date = Date()) -> Int {
            if timestamp.timeIntervalSince(windowStart) >= windowSize {
                return 0
            }
            return count
        }
        
        func status(limit: Int, windowSize: TimeInterval) -> RateLimitStatus {
            let resetTime = windowStart.addingTimeInterval(windowSize)
            let remaining = max(0, limit - count)
            
            return RateLimitStatus(
                key: "",
                limit: limit,
                remaining: remaining,
                resetTime: resetTime,
                currentWindow: windowSize,
                algorithm: .fixedWindow
            )
        }
    }
    
    private struct QuotaStatus {
        var used: Int
        var limit: Int
        var resetTime: Date
        
        init(limit: Int, resetTime: Date) {
            self.used = 0
            self.limit = limit
            self.resetTime = resetTime
        }
        
        mutating func consume(amount: Int = 1) -> Bool {
            if Date() > resetTime {
                // Reset quota
                used = 0
                resetTime = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
            }
            
            if used + amount <= limit {
                used += amount
                return true
            }
            return false
        }
        
        var remaining: Int {
            max(0, limit - used)
        }
        
        var utilizationPercentage: Double {
            limit > 0 ? (Double(used) / Double(limit)) * 100.0 : 0.0
        }
    }
    
    public init(configuration: RateLimitCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 1000 * 50_000, // 50KB per rate limit key
            cpu: 2.0, // Rate limit calculations
            bandwidth: 0,
            storage: 100_000 // Storage for persistent limits
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let keyCount = tokenBuckets.count + slidingWindows.count + leakyBuckets.count + fixedWindows.count
            
            return ResourceUsage(
                memory: keyCount * 25_000,
                cpu: keyCount > 0 ? 1.0 : 0.1,
                bandwidth: 0,
                storage: keyCount * 5_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Rate limiting is always available
    }
    
    public func release() async {
        distributedSyncTimer?.invalidate()
        distributedSyncTimer = nil
        
        tokenBuckets.removeAll()
        slidingWindows.removeAll()
        leakyBuckets.removeAll()
        fixedWindows.removeAll()
        quotaTracker.removeAll()
        
        violationStreamContinuation?.finish()
        metrics = RateLimitMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        if configuration.enableDistributedLimiting {
            await startDistributedSync()
        }
    }
    
    internal func updateConfiguration(_ configuration: RateLimitCapabilityConfiguration) async throws {
        // Update distributed sync if settings changed
        if configuration.enableDistributedLimiting && 
           configuration.distributedSyncInterval != self.configuration.distributedSyncInterval {
            await startDistributedSync()
        }
    }
    
    // MARK: - Rate Limiting
    
    public func checkRateLimit(context: RateLimitContext) async -> RateLimitStatus {
        let startTime = Date()
        
        // Check if endpoint is whitelisted
        if configuration.enableWhitelist && configuration.whitelistedEndpoints.contains(context.endpoint) {
            return RateLimitStatus(
                key: "whitelisted",
                limit: Int.max,
                remaining: Int.max,
                resetTime: Date.distantFuture,
                currentWindow: 0,
                algorithm: .fixedWindow
            )
        }
        
        var mostRestrictiveStatus: RateLimitStatus?
        
        // Check all applicable rate limits
        for key in context.rateLimitKeys {
            let limit = await getApplicableLimit(for: key, context: context)
            let status = await checkSpecificLimit(key: key, limit: limit, context: context)
            
            if mostRestrictiveStatus == nil || status.remaining < mostRestrictiveStatus!.remaining {
                mostRestrictiveStatus = status
            }
        }
        
        let finalStatus = mostRestrictiveStatus ?? RateLimitStatus(
            key: "default",
            limit: configuration.globalRateLimit.requests,
            remaining: configuration.globalRateLimit.requests,
            resetTime: Date().addingTimeInterval(configuration.globalRateLimit.window.duration),
            currentWindow: configuration.globalRateLimit.window.duration,
            algorithm: configuration.globalRateLimit.algorithm
        )
        
        await updateMetrics(status: finalStatus, context: context, duration: Date().timeIntervalSince(startTime))
        
        return finalStatus
    }
    
    public func consumeRateLimit(context: RateLimitContext) async -> RateLimitStatus {
        let status = await checkRateLimit(context: context)
        
        if !status.isExceeded {
            // Consume from all applicable limits
            for key in context.rateLimitKeys {
                let limit = await getApplicableLimit(for: key, context: context)
                await consumeSpecificLimit(key: key, limit: limit, context: context)
            }
            
            // Check quota if enabled
            if configuration.enableQuotaSystem {
                await consumeQuota(context: context)
            }
        } else {
            // Record violation
            let violation = RateLimitViolation(
                key: status.key,
                context: context,
                limit: configuration.globalRateLimit,
                actualRequests: status.limit - status.remaining + 1
            )
            
            violationStreamContinuation?.yield(violation)
            await updateViolationMetrics(violation: violation)
            
            if configuration.enableLogging {
                await logViolation(violation)
            }
        }
        
        return status
    }
    
    public func getRateLimitStatus(key: String) async -> RateLimitStatus? {
        if let bucket = tokenBuckets[key] {
            let resetTime = Date().addingTimeInterval(60.0) // Approximate
            return bucket.status(limit: bucket.capacity, resetTime: resetTime)
        }
        
        if let window = slidingWindows[key] {
            return window.status(limit: configuration.globalRateLimit.requests, windowSize: configuration.globalRateLimit.window.duration)
        }
        
        if let bucket = leakyBuckets[key] {
            let resetTime = Date().addingTimeInterval(60.0) // Approximate
            return bucket.status(limit: bucket.capacity, resetTime: resetTime)
        }
        
        if let window = fixedWindows[key] {
            return window.status(limit: configuration.globalRateLimit.requests, windowSize: configuration.globalRateLimit.window.duration)
        }
        
        return nil
    }
    
    public func resetRateLimit(key: String) async {
        tokenBuckets.removeValue(forKey: key)
        slidingWindows.removeValue(forKey: key)
        leakyBuckets.removeValue(forKey: key)
        fixedWindows.removeValue(forKey: key)
        quotaTracker.removeValue(forKey: key)
    }
    
    public func resetAllRateLimits() async {
        tokenBuckets.removeAll()
        slidingWindows.removeAll()
        leakyBuckets.removeAll()
        fixedWindows.removeAll()
        quotaTracker.removeAll()
    }
    
    // MARK: - Violation Monitoring
    
    public var violationStream: AsyncStream<RateLimitViolation> {
        AsyncStream { continuation in
            self.violationStreamContinuation = continuation
        }
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> RateLimitMetrics {
        metrics
    }
    
    public func clearMetrics() async {
        metrics = RateLimitMetrics()
    }
    
    // MARK: - Private Methods
    
    private func getApplicableLimit(for key: String, context: RateLimitContext) async -> RateLimit {
        // Check for specific endpoint limits
        if key.hasPrefix("endpoint:") {
            let endpoint = String(key.dropFirst("endpoint:".count))
            if let limit = configuration.perEndpointLimits[endpoint] {
                return limit
            }
        }
        
        // Check for specific user limits
        if key.hasPrefix("user:") {
            let userId = String(key.dropFirst("user:".count))
            if let limit = configuration.perUserLimits[userId] {
                return limit
            }
        }
        
        // Apply priority-based adjustments
        if configuration.enablePrioritization {
            var adjustedLimit = configuration.globalRateLimit
            
            switch context.priority {
            case .low:
                adjustedLimit = RateLimit(
                    requests: Int(Double(adjustedLimit.requests) * 0.5),
                    window: adjustedLimit.window,
                    algorithm: adjustedLimit.algorithm
                )
            case .normal:
                break // Use default
            case .high:
                adjustedLimit = RateLimit(
                    requests: Int(Double(adjustedLimit.requests) * 1.5),
                    window: adjustedLimit.window,
                    algorithm: adjustedLimit.algorithm
                )
            case .critical, .system:
                adjustedLimit = RateLimit(
                    requests: Int(Double(adjustedLimit.requests) * 2.0),
                    window: adjustedLimit.window,
                    algorithm: adjustedLimit.algorithm
                )
            }
            
            return adjustedLimit
        }
        
        return configuration.globalRateLimit
    }
    
    private func checkSpecificLimit(key: String, limit: RateLimit, context: RateLimitContext) async -> RateLimitStatus {
        switch limit.algorithm {
        case .tokenBucket:
            return await checkTokenBucket(key: key, limit: limit, context: context)
        case .slidingWindow:
            return await checkSlidingWindow(key: key, limit: limit, context: context)
        case .leakyBucket:
            return await checkLeakyBucket(key: key, limit: limit, context: context)
        case .fixedWindow:
            return await checkFixedWindow(key: key, limit: limit, context: context)
        }
    }
    
    private func consumeSpecificLimit(key: String, limit: RateLimit, context: RateLimitContext) async {
        let weight = context.weight
        
        switch limit.algorithm {
        case .tokenBucket:
            await consumeTokenBucket(key: key, limit: limit, weight: weight)
        case .slidingWindow:
            await consumeSlidingWindow(key: key, limit: limit)
        case .leakyBucket:
            await consumeLeakyBucket(key: key, limit: limit, weight: Double(weight))
        case .fixedWindow:
            await consumeFixedWindow(key: key, limit: limit)
        }
    }
    
    private func checkTokenBucket(key: String, limit: RateLimit, context: RateLimitContext) async -> RateLimitStatus {
        if tokenBuckets[key] == nil {
            tokenBuckets[key] = TokenBucket(capacity: configuration.defaultBucketSize, refillRate: configuration.defaultRefillRate)
        }
        
        let bucket = tokenBuckets[key]!
        var status = bucket.status(limit: limit.requests, resetTime: Date().addingTimeInterval(60.0))
        status = RateLimitStatus(
            key: key,
            limit: status.limit,
            remaining: status.remaining,
            resetTime: status.resetTime,
            retryAfter: status.remaining <= 0 ? 60.0 / configuration.defaultRefillRate : nil,
            currentWindow: status.currentWindow,
            algorithm: status.algorithm
        )
        
        return status
    }
    
    private func consumeTokenBucket(key: String, limit: RateLimit, weight: Int) async {
        guard var bucket = tokenBuckets[key] else { return }
        _ = bucket.tryConsume(tokens: weight)
        tokenBuckets[key] = bucket
    }
    
    private func checkSlidingWindow(key: String, limit: RateLimit, context: RateLimitContext) async -> RateLimitStatus {
        if slidingWindows[key] == nil {
            slidingWindows[key] = SlidingWindow(windowSize: limit.window.duration)
        }
        
        let window = slidingWindows[key]!
        let count = window.requestCount()
        let remaining = max(0, limit.requests - count)
        let resetTime = Date().addingTimeInterval(limit.window.duration)
        
        return RateLimitStatus(
            key: key,
            limit: limit.requests,
            remaining: remaining,
            resetTime: resetTime,
            retryAfter: remaining <= 0 ? limit.window.duration : nil,
            currentWindow: limit.window.duration,
            algorithm: .slidingWindow
        )
    }
    
    private func consumeSlidingWindow(key: String, limit: RateLimit) async {
        guard var window = slidingWindows[key] else { return }
        _ = window.addRequest()
        slidingWindows[key] = window
    }
    
    private func checkLeakyBucket(key: String, limit: RateLimit, context: RateLimitContext) async -> RateLimitStatus {
        if leakyBuckets[key] == nil {
            leakyBuckets[key] = LeakyBucket(capacity: configuration.defaultBucketSize, leakRate: configuration.defaultRefillRate)
        }
        
        let bucket = leakyBuckets[key]!
        return bucket.status(limit: limit.requests, resetTime: Date().addingTimeInterval(60.0))
    }
    
    private func consumeLeakyBucket(key: String, limit: RateLimit, weight: Double) async {
        guard var bucket = leakyBuckets[key] else { return }
        _ = bucket.tryAdd(amount: weight)
        leakyBuckets[key] = bucket
    }
    
    private func checkFixedWindow(key: String, limit: RateLimit, context: RateLimitContext) async -> RateLimitStatus {
        if fixedWindows[key] == nil {
            fixedWindows[key] = FixedWindow(windowSize: limit.window.duration)
        }
        
        let window = fixedWindows[key]!
        return window.status(limit: limit.requests, windowSize: limit.window.duration)
    }
    
    private func consumeFixedWindow(key: String, limit: RateLimit) async {
        guard var window = fixedWindows[key] else { return }
        _ = window.addRequest()
        fixedWindows[key] = window
    }
    
    private func consumeQuota(context: RateLimitContext) async {
        let quotaKey = "daily:\(context.userId ?? "anonymous")"
        
        if quotaTracker[quotaKey] == nil {
            let resetTime = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
            quotaTracker[quotaKey] = QuotaStatus(limit: 10000, resetTime: resetTime) // Default daily quota
        }
        
        _ = quotaTracker[quotaKey]?.consume(amount: context.weight)
    }
    
    private func startDistributedSync() async {
        distributedSyncTimer?.invalidate()
        
        distributedSyncTimer = Timer.scheduledTimer(withTimeInterval: configuration.distributedSyncInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performDistributedSync()
            }
        }
    }
    
    private func performDistributedSync() async {
        // Sync rate limit states across distributed instances
        // This would involve network communication in a real implementation
        
        if configuration.enableLogging {
            print("[RateLimit] 🔄 Performing distributed sync")
        }
    }
    
    private func updateMetrics(status: RateLimitStatus, context: RateLimitContext, duration: TimeInterval) async {
        let totalRequests = metrics.totalRequests + 1
        let totalRejections = metrics.totalRejections + (status.isExceeded ? 1 : 0)
        let newAverageTime = ((metrics.averageResponseTime * Double(metrics.totalRequests)) + duration) / Double(totalRequests)
        
        var newRequestsByPriority = metrics.requestsByPriority
        newRequestsByPriority[context.priority.rawValue.description, default: 0] += 1
        
        // Calculate current throughput (requests per second)
        let currentThroughput = 1.0 / duration // Simplified calculation
        let peakThroughput = max(metrics.peakThroughput, currentThroughput)
        
        metrics = RateLimitMetrics(
            totalRequests: totalRequests,
            totalRejections: totalRejections,
            totalViolations: metrics.totalViolations,
            averageResponseTime: newAverageTime,
            currentThroughput: currentThroughput,
            peakThroughput: peakThroughput,
            bucketOverflows: metrics.bucketOverflows,
            adaptiveAdjustments: metrics.adaptiveAdjustments,
            violationsByEndpoint: metrics.violationsByEndpoint,
            violationsByUser: metrics.violationsByUser,
            requestsByPriority: newRequestsByPriority,
            quotaUtilization: metrics.quotaUtilization
        )
    }
    
    private func updateViolationMetrics(violation: RateLimitViolation) async {
        var newViolationsByEndpoint = metrics.violationsByEndpoint
        var newViolationsByUser = metrics.violationsByUser
        
        newViolationsByEndpoint[violation.context.endpoint, default: 0] += 1
        
        if let userId = violation.context.userId {
            newViolationsByUser[userId, default: 0] += 1
        }
        
        metrics = RateLimitMetrics(
            totalRequests: metrics.totalRequests,
            totalRejections: metrics.totalRejections,
            totalViolations: metrics.totalViolations + 1,
            averageResponseTime: metrics.averageResponseTime,
            currentThroughput: metrics.currentThroughput,
            peakThroughput: metrics.peakThroughput,
            bucketOverflows: metrics.bucketOverflows,
            adaptiveAdjustments: metrics.adaptiveAdjustments,
            violationsByEndpoint: newViolationsByEndpoint,
            violationsByUser: newViolationsByUser,
            requestsByPriority: metrics.requestsByPriority,
            quotaUtilization: metrics.quotaUtilization
        )
    }
    
    private func logViolation(_ violation: RateLimitViolation) async {
        print("[RateLimit] 🚫 VIOLATION: \(violation.context.endpoint) - \(violation.violationType.rawValue) (user: \(violation.context.userId ?? "anonymous"))")
    }
}

// MARK: - Rate Limit Capability Implementation

/// Rate Limit capability providing advanced rate limiting and throttling
public actor RateLimitCapability: DomainCapability {
    public typealias ConfigurationType = RateLimitCapabilityConfiguration
    public typealias ResourceType = RateLimitCapabilityResource
    
    private var _configuration: RateLimitCapabilityConfiguration
    private var _resources: RateLimitCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "rate-limit-capability" }
    
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
    
    public var configuration: RateLimitCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: RateLimitCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: RateLimitCapabilityConfiguration = RateLimitCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = RateLimitCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: RateLimitCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Rate Limit configuration")
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
        // Rate limiting is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Rate limiting doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Rate Limiting Operations
    
    /// Check if request is within rate limits
    public func checkRateLimit(context: RateLimitContext) async throws -> RateLimitStatus {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        return await _resources.checkRateLimit(context: context)
    }
    
    /// Consume rate limit for request
    public func consumeRateLimit(context: RateLimitContext) async throws -> RateLimitStatus {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        return await _resources.consumeRateLimit(context: context)
    }
    
    /// Get rate limit status for specific key
    public func getRateLimitStatus(key: String) async throws -> RateLimitStatus? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        return await _resources.getRateLimitStatus(key: key)
    }
    
    /// Reset rate limit for specific key
    public func resetRateLimit(key: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        await _resources.resetRateLimit(key: key)
    }
    
    /// Reset all rate limits
    public func resetAllRateLimits() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        await _resources.resetAllRateLimits()
    }
    
    /// Get violation stream
    public func getViolationStream() async throws -> AsyncStream<RateLimitViolation> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        return await _resources.violationStream
    }
    
    /// Get metrics
    public func getMetrics() async throws -> RateLimitMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Rate Limit capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    // MARK: - Convenience Methods
    
    /// Check rate limit for simple endpoint request
    public func checkEndpointRateLimit(endpoint: String, userId: String? = nil) async throws -> RateLimitStatus {
        let context = RateLimitContext(endpoint: endpoint, userId: userId)
        return try await checkRateLimit(context: context)
    }
    
    /// Consume rate limit for simple endpoint request
    public func consumeEndpointRateLimit(endpoint: String, userId: String? = nil) async throws -> RateLimitStatus {
        let context = RateLimitContext(endpoint: endpoint, userId: userId)
        return try await consumeRateLimit(context: context)
    }
    
    /// Check if request would be rate limited
    public func wouldBeRateLimited(context: RateLimitContext) async throws -> Bool {
        let status = try await checkRateLimit(context: context)
        return status.isExceeded
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Rate Limit specific errors
public enum RateLimitError: Error, LocalizedError {
    case rateLimitExceeded(RateLimitStatus)
    case invalidConfiguration(String)
    case algorithmNotSupported(String)
    case distributedSyncFailed(String)
    case quotaExceeded(String)
    case violationThresholdExceeded(Int)
    
    public var errorDescription: String? {
        switch self {
        case .rateLimitExceeded(let status):
            return "Rate limit exceeded for \(status.key). Retry after \(status.retryAfter ?? 0) seconds"
        case .invalidConfiguration(let reason):
            return "Invalid rate limit configuration: \(reason)"
        case .algorithmNotSupported(let algorithm):
            return "Rate limiting algorithm not supported: \(algorithm)"
        case .distributedSyncFailed(let reason):
            return "Distributed rate limit sync failed: \(reason)"
        case .quotaExceeded(let quotaType):
            return "Quota exceeded for \(quotaType)"
        case .violationThresholdExceeded(let count):
            return "Violation threshold exceeded: \(count) violations"
        }
    }
}