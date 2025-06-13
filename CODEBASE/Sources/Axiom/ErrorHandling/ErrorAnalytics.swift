import Foundation

// MARK: - Error Event

/// Comprehensive error event for analytics tracking
public struct ErrorEvent: Sendable {
    public let id: String
    public let error: AxiomError
    public let context: ErrorAnalyticsContext
    public let timestamp: Date
    public let recoveryAttempted: Bool
    public let recoverySuccessful: Bool
    public let recoveryOption: String?
    public let sessionId: String
    public let userId: String?
    
    public init(
        error: AxiomError,
        context: ErrorAnalyticsContext,
        recoveryAttempted: Bool,
        recoverySuccessful: Bool,
        recoveryOption: String? = nil,
        sessionId: String = UUID().uuidString,
        userId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.error = error
        self.context = context
        self.timestamp = Date()
        self.recoveryAttempted = recoveryAttempted
        self.recoverySuccessful = recoverySuccessful
        self.recoveryOption = recoveryOption
        self.sessionId = sessionId
        self.userId = userId
    }
}

// MARK: - Error Analytics Context

/// Context information for error analytics
public struct ErrorAnalyticsContext: Sendable {
    public let source: String
    public let feature: String?
    public let userAction: String?
    public let deviceInfo: DeviceInfo?
    public let appVersion: String?
    public let metadata: [String: String]
    
    public init(
        source: String,
        feature: String? = nil,
        userAction: String? = nil,
        deviceInfo: DeviceInfo? = nil,
        appVersion: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.source = source
        self.feature = feature
        self.userAction = userAction
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.metadata = metadata
    }
}

// MARK: - Device Info

/// Device information for error context
public struct DeviceInfo: Sendable {
    public let platform: String
    public let osVersion: String
    public let deviceModel: String
    public let appVersion: String
    public let buildNumber: String
    
    public init(
        platform: String,
        osVersion: String,
        deviceModel: String,
        appVersion: String,
        buildNumber: String
    ) {
        self.platform = platform
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.appVersion = appVersion
        self.buildNumber = buildNumber
    }
    
    public static var current: DeviceInfo {
        #if os(iOS)
        return DeviceInfo(
            platform: "iOS",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: UIDevice.current.model,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        )
        #elseif os(macOS)
        return DeviceInfo(
            platform: "macOS",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: "Mac",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        )
        #else
        return DeviceInfo(
            platform: "Unknown",
            osVersion: "Unknown",
            deviceModel: "Unknown",
            appVersion: "Unknown",
            buildNumber: "Unknown"
        )
        #endif
    }
}

// MARK: - Error Pattern

/// Detected error pattern from analytics
public struct ErrorPattern: Sendable {
    public let errorType: String
    public let frequency: Int
    public let timeWindow: TimeInterval
    public let severity: PatternSeverity
    public let affectedFeatures: [String]
    public let correlatedErrors: [String]
    public let detectionTime: Date
    
    public init(
        errorType: String,
        frequency: Int,
        timeWindow: TimeInterval,
        severity: PatternSeverity,
        affectedFeatures: [String] = [],
        correlatedErrors: [String] = [],
        detectionTime: Date = Date()
    ) {
        self.errorType = errorType
        self.frequency = frequency
        self.timeWindow = timeWindow
        self.severity = severity
        self.affectedFeatures = affectedFeatures
        self.correlatedErrors = correlatedErrors
        self.detectionTime = detectionTime
    }
}

// MARK: - Pattern Severity

/// Severity levels for detected error patterns
public enum PatternSeverity: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var alertThreshold: Int {
        switch self {
        case .low: return 5
        case .medium: return 10
        case .high: return 20
        case .critical: return 50
        }
    }
}

// MARK: - Recovery Metrics

/// Metrics for recovery success tracking
public struct RecoveryMetrics: Sendable {
    public let totalAttempts: Int
    public let successfulAttempts: Int
    public let failedAttempts: Int
    public let averageRecoveryTime: TimeInterval
    public let successRate: Double
    public let mostUsedOptions: [String]
    public let timeWindow: TimeInterval
    
    public init(
        totalAttempts: Int,
        successfulAttempts: Int,
        failedAttempts: Int,
        averageRecoveryTime: TimeInterval,
        mostUsedOptions: [String],
        timeWindow: TimeInterval
    ) {
        self.totalAttempts = totalAttempts
        self.successfulAttempts = successfulAttempts
        self.failedAttempts = failedAttempts
        self.averageRecoveryTime = averageRecoveryTime
        self.successRate = totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) : 0
        self.mostUsedOptions = mostUsedOptions
        self.timeWindow = timeWindow
    }
}

// MARK: - Analytics Reporter

/// Protocol for external analytics reporting
public protocol AnalyticsReporter: Sendable {
    func reportError(_ event: ErrorEvent) async
    func reportPattern(_ pattern: ErrorPattern) async
    func reportRecoveryMetrics(_ metrics: RecoveryMetrics) async
}

/// Default implementation that logs to console
public final class ConsoleAnalyticsReporter: AnalyticsReporter {
    public init() {}
    
    public func reportError(_ event: ErrorEvent) async {
        print("📊 Error Analytics: \(event.error) from \(event.context.source)")
    }
    
    public func reportPattern(_ pattern: ErrorPattern) async {
        print("🔍 Pattern Detected: \(pattern.errorType) - \(pattern.frequency) occurrences (\(pattern.severity))")
    }
    
    public func reportRecoveryMetrics(_ metrics: RecoveryMetrics) async {
        print("📈 Recovery Metrics: Success rate \(metrics.successRate * 100)% over \(metrics.totalAttempts) attempts")
    }
}

// MARK: - Error Analytics Report

/// Comprehensive analytics report
public struct ErrorAnalyticsReport {
    public let totalErrors: Int
    public let recoverySuccessRate: Double
    public let topErrorTypes: [String]
    public let errorTrends: [ErrorTrend]
    public let recommendations: [String]
    public let generationTime: Date
    
    public init(
        totalErrors: Int,
        recoverySuccessRate: Double,
        topErrorTypes: [String],
        errorTrends: [ErrorTrend],
        recommendations: [String]
    ) {
        self.totalErrors = totalErrors
        self.recoverySuccessRate = recoverySuccessRate
        self.topErrorTypes = topErrorTypes
        self.errorTrends = errorTrends
        self.recommendations = recommendations
        self.generationTime = Date()
    }
}

// MARK: - Error Trend

/// Trend analysis data for errors over time
public struct ErrorTrend {
    public let errorType: String
    public let timePoints: [(Date, Int)]
    public let trend: TrendDirection
    public let changePercentage: Double
    
    public init(errorType: String, timePoints: [(Date, Int)], trend: TrendDirection, changePercentage: Double) {
        self.errorType = errorType
        self.timePoints = timePoints
        self.trend = trend
        self.changePercentage = changePercentage
    }
}

// MARK: - Trend Direction

/// Direction of error trend
public enum TrendDirection {
    case increasing
    case decreasing
    case stable
    case volatile
}

// MARK: - Error Analytics Service

/// Comprehensive error analytics tracking and analysis service
public actor ErrorAnalyticsService {
    private var errorHistory: [ErrorEvent] = []
    private var errorPatterns: [ErrorPattern] = []
    private let analyticsReporter: any AnalyticsReporter
    private var alertThresholds: [String: Int] = [
        "NetworkError": 10,
        "ValidationError": 15,
        "PersistenceError": 5,
        "CapabilityError": 8,
        "ContextError": 3,
        "ActorError": 3
    ]
    private var lastPatternCheck: Date = Date()
    private let maxHistorySize = 10000
    
    // Performance optimization
    private var errorTypeCache: [String: [ErrorEvent]] = [:]
    private var featureCache: [String: [ErrorEvent]] = [:]
    private var lastCacheUpdate: Date = Date()
    private let cacheInvalidationInterval: TimeInterval = 300 // 5 minutes
    
    public init(analyticsReporter: any AnalyticsReporter = ConsoleAnalyticsReporter()) {
        self.analyticsReporter = analyticsReporter
    }
    
    // MARK: - Public Interface
    
    /// Records an error event for analytics
    public func recordError(
        error: AxiomError,
        context: ErrorAnalyticsContext,
        recoveryAttempted: Bool,
        recoverySuccessful: Bool,
        recoveryOption: String? = nil
    ) async {
        let event = ErrorEvent(
            error: error,
            context: context,
            recoveryAttempted: recoveryAttempted,
            recoverySuccessful: recoverySuccessful,
            recoveryOption: recoveryOption
        )
        
        // Add to history
        errorHistory.append(event)
        
        // Maintain history size
        if errorHistory.count > maxHistorySize {
            let removeCount = errorHistory.count - maxHistorySize
            errorHistory.removeFirst(removeCount)
            invalidateCache()
        }
        
        // Update caches incrementally
        updateCachesIncremental(with: event)
        
        // Report to external analytics
        await analyticsReporter.reportError(event)
        
        // Check for patterns periodically
        await checkForPatternsIfNeeded()
        
        // Check for critical error rates
        await checkCriticalErrorRates()
    }
    
    /// Gets comprehensive analytics report
    public func getErrorReport() async -> ErrorAnalyticsReport {
        updateCachesIfNeeded()
        
        let totalErrors = errorHistory.count
        let recoveryEvents = errorHistory.filter { $0.recoveryAttempted }
        let successfulRecoveries = recoveryEvents.filter { $0.recoverySuccessful }
        
        let recoverySuccessRate = recoveryEvents.isEmpty 
            ? 0 
            : Double(successfulRecoveries.count) / Double(recoveryEvents.count)
        
        let topErrorTypes = getTopErrorTypes()
        let errorTrends = getErrorTrends()
        let recommendations = generateRecommendations()
        
        return ErrorAnalyticsReport(
            totalErrors: totalErrors,
            recoverySuccessRate: recoverySuccessRate,
            topErrorTypes: topErrorTypes,
            errorTrends: errorTrends,
            recommendations: recommendations
        )
    }
    
    /// Gets recovery metrics for a specific time window
    public func getRecoveryMetrics(timeWindow: TimeInterval = 3600) async -> RecoveryMetrics {
        let cutoffDate = Date().addingTimeInterval(-timeWindow)
        let recentEvents = errorHistory.filter { $0.timestamp > cutoffDate && $0.recoveryAttempted }
        
        let totalAttempts = recentEvents.count
        let successfulAttempts = recentEvents.filter { $0.recoverySuccessful }.count
        let failedAttempts = totalAttempts - successfulAttempts
        
        // Calculate average recovery time (simulated for this implementation)
        let averageRecoveryTime: TimeInterval = 2.5
        
        // Get most used recovery options
        let optionCounts = recentEvents.compactMap { $0.recoveryOption }
            .reduce(into: [String: Int]()) { result, option in
                result[option, default: 0] += 1
            }
        
        let mostUsedOptions = optionCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return RecoveryMetrics(
            totalAttempts: totalAttempts,
            successfulAttempts: successfulAttempts,
            failedAttempts: failedAttempts,
            averageRecoveryTime: averageRecoveryTime,
            mostUsedOptions: Array(mostUsedOptions),
            timeWindow: timeWindow
        )
    }
    
    /// Detects error patterns and correlations
    public func detectErrorPatterns() async -> [ErrorPattern] {
        updateCachesIfNeeded()
        
        var detectedPatterns: [ErrorPattern] = []
        
        // Analyze patterns by error type
        for (errorType, events) in errorTypeCache {
            if events.count >= 3 {
                let pattern = analyzeErrorTypePattern(errorType: errorType, events: events)
                if let pattern = pattern {
                    detectedPatterns.append(pattern)
                }
            }
        }
        
        // Analyze feature-based correlations
        let featurePatterns = analyzeFeatureCorrelations()
        detectedPatterns.append(contentsOf: featurePatterns)
        
        // Store detected patterns
        errorPatterns = detectedPatterns
        
        // Report critical patterns
        for pattern in detectedPatterns.filter({ $0.severity == .critical || $0.severity == .high }) {
            await analyticsReporter.reportPattern(pattern)
        }
        
        return detectedPatterns
    }
    
    /// Gets error correlation analysis
    public func getErrorCorrelations(timeWindow: TimeInterval = 1800) -> [ErrorCorrelation] {
        updateCachesIfNeeded()
        
        var correlations: [ErrorCorrelation] = []
        let cutoffDate = Date().addingTimeInterval(-timeWindow)
        let recentEvents = errorHistory.filter { $0.timestamp > cutoffDate }
        
        // Group by error type
        let errorTypeGroups = Dictionary(grouping: recentEvents) { event in
            String(describing: type(of: event.error))
        }
        
        // Find correlations between error types
        let errorTypes = Array(errorTypeGroups.keys)
        for i in 0..<errorTypes.count {
            for j in (i+1)..<errorTypes.count {
                let type1 = errorTypes[i]
                let type2 = errorTypes[j]
                
                let events1 = errorTypeGroups[type1] ?? []
                let events2 = errorTypeGroups[type2] ?? []
                
                let correlation = calculateCorrelation(events1: events1, events2: events2, timeWindow: timeWindow)
                if correlation.strength > 0.3 {
                    correlations.append(correlation)
                }
            }
        }
        
        return correlations.sorted { $0.strength > $1.strength }
    }
    
    /// Configures alert threshold for specific error type
    public func setAlertThreshold(errorType: String, threshold: Int) {
        alertThresholds[errorType] = threshold
    }
    
    /// Clears analytics history
    public func clearHistory() {
        errorHistory.removeAll()
        errorPatterns.removeAll()
        invalidateCache()
    }
    
    // MARK: - Private Implementation
    
    
    private func updateCachesIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastCacheUpdate) > cacheInvalidationInterval {
            rebuildCaches()
            lastCacheUpdate = now
        }
    }
    
    private func updateCachesIncremental(with event: ErrorEvent) {
        let errorType = String(describing: type(of: event.error))
        
        // Update error type cache
        if errorTypeCache[errorType] == nil {
            errorTypeCache[errorType] = []
        }
        errorTypeCache[errorType]?.append(event)
        
        // Update feature cache
        if let feature = event.context.feature {
            if featureCache[feature] == nil {
                featureCache[feature] = []
            }
            featureCache[feature]?.append(event)
        }
    }
    
    private func rebuildCaches() {
        errorTypeCache = Dictionary(grouping: errorHistory) { event in
            String(describing: type(of: event.error))
        }
        
        featureCache = Dictionary(grouping: errorHistory) { event in
            event.context.feature ?? "unknown"
        }
    }
    
    private func invalidateCache() {
        errorTypeCache.removeAll()
        featureCache.removeAll()
        lastCacheUpdate = Date.distantPast
    }
    
    private func checkForPatternsIfNeeded() async {
        let now = Date()
        if now.timeIntervalSince(lastPatternCheck) > 300 { // Check every 5 minutes
            _ = await detectErrorPatterns()
            lastPatternCheck = now
        }
    }
    
    private func checkCriticalErrorRates() async {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentErrors = errorHistory.filter { $0.timestamp > oneHourAgo }
        
        // Group by error type
        let errorTypeCounts = recentErrors.reduce(into: [String: Int]()) { result, event in
            let errorType = String(describing: type(of: event.error))
            result[errorType, default: 0] += 1
        }
        
        // Check against thresholds
        for (errorType, count) in errorTypeCounts {
            let threshold = alertThresholds[errorType] ?? 20
            if count > threshold {
                let pattern = ErrorPattern(
                    errorType: errorType,
                    frequency: count,
                    timeWindow: 3600,
                    severity: .critical
                )
                await analyticsReporter.reportPattern(pattern)
            }
        }
    }
    
    private func analyzeErrorTypePattern(errorType: String, events: [ErrorEvent]) -> ErrorPattern? {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentEvents = events.filter { $0.timestamp > oneHourAgo }
        
        guard recentEvents.count >= 3 else { return nil }
        
        let frequency = recentEvents.count
        let severity: PatternSeverity
        
        if frequency >= 50 {
            severity = .critical
        } else if frequency >= 20 {
            severity = .high
        } else if frequency >= 10 {
            severity = .medium
        } else {
            severity = .low
        }
        
        let affectedFeatures = Array(Set(recentEvents.compactMap { $0.context.feature }))
        
        return ErrorPattern(
            errorType: errorType,
            frequency: frequency,
            timeWindow: 3600,
            severity: severity,
            affectedFeatures: affectedFeatures
        )
    }
    
    private func analyzeFeatureCorrelations() -> [ErrorPattern] {
        var patterns: [ErrorPattern] = []
        
        for (feature, events) in featureCache {
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let recentEvents = events.filter { $0.timestamp > oneHourAgo }
            
            if recentEvents.count >= 5 {
                let errorTypes = recentEvents.map { String(describing: type(of: $0.error)) }
                let uniqueErrorTypes = Array(Set(errorTypes))
                
                if uniqueErrorTypes.count > 1 {
                    let pattern = ErrorPattern(
                        errorType: "FeatureCorrelation",
                        frequency: recentEvents.count,
                        timeWindow: 3600,
                        severity: .medium,
                        affectedFeatures: [feature],
                        correlatedErrors: uniqueErrorTypes
                    )
                    patterns.append(pattern)
                }
            }
        }
        
        return patterns
    }
    
    private func getTopErrorTypes() -> [String] {
        let errorTypeCounts = errorHistory.reduce(into: [String: Int]()) { result, event in
            let errorType = String(describing: type(of: event.error))
            result[errorType, default: 0] += 1
        }
        
        return errorTypeCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func getErrorTrends() -> [ErrorTrend] {
        let dayAgo = Date().addingTimeInterval(-86400)
        let recentEvents = errorHistory.filter { $0.timestamp > dayAgo }
        
        _ = Dictionary(grouping: recentEvents) { event in
            Calendar.current.dateInterval(of: .hour, for: event.timestamp)?.start ?? event.timestamp
        }
        
        var trends: [ErrorTrend] = []
        
        for errorType in getTopErrorTypes().prefix(3) {
            let typeEvents = recentEvents.filter { String(describing: type(of: $0.error)) == errorType }
            let typeHourlyGroups = Dictionary(grouping: typeEvents) { event in
                Calendar.current.dateInterval(of: .hour, for: event.timestamp)?.start ?? event.timestamp
            }
            
            let timePoints = typeHourlyGroups.map { (date, events) in
                (date, events.count)
            }.sorted { $0.0 < $1.0 }
            
            if timePoints.count >= 2 {
                let trend = calculateTrend(timePoints: timePoints)
                trends.append(ErrorTrend(
                    errorType: errorType,
                    timePoints: timePoints,
                    trend: trend.direction,
                    changePercentage: trend.changePercentage
                ))
            }
        }
        
        return trends
    }
    
    private func calculateTrend(timePoints: [(Date, Int)]) -> (direction: TrendDirection, changePercentage: Double) {
        guard timePoints.count >= 2 else {
            return (.stable, 0)
        }
        
        let values = timePoints.map { Double($0.1) }
        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let changePercentage = firstAvg > 0 ? (secondAvg - firstAvg) / firstAvg * 100 : 0
        
        if abs(changePercentage) < 10 {
            return (.stable, changePercentage)
        } else if changePercentage > 0 {
            return (.increasing, changePercentage)
        } else {
            return (.decreasing, changePercentage)
        }
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Recovery success rate recommendations
        let recoveryMetrics = errorHistory.filter { $0.recoveryAttempted }
        if !recoveryMetrics.isEmpty {
            let successRate = Double(recoveryMetrics.filter { $0.recoverySuccessful }.count) / Double(recoveryMetrics.count)
            if successRate < 0.7 {
                recommendations.append("Recovery success rate is below 70%. Consider improving error recovery strategies.")
            }
        }
        
        // Pattern-based recommendations
        for pattern in errorPatterns.filter({ $0.severity == .high || $0.severity == .critical }) {
            recommendations.append("High frequency of \(pattern.errorType) errors detected. Investigate root cause.")
        }
        
        // Top error recommendations
        let topErrors = getTopErrorTypes()
        if topErrors.contains("ValidationError") {
            recommendations.append("High validation error rate. Consider improving input validation UX.")
        }
        if topErrors.contains("NetworkError") {
            recommendations.append("Network errors are frequent. Consider improving offline capabilities.")
        }
        
        return recommendations
    }
    
    private func calculateCorrelation(events1: [ErrorEvent], events2: [ErrorEvent], timeWindow: TimeInterval) -> ErrorCorrelation {
        let type1 = String(describing: type(of: events1.first?.error))
        let type2 = String(describing: type(of: events2.first?.error))
        
        // Simple correlation: events occurring within 5 minutes of each other
        let correlationWindow: TimeInterval = 300
        var correlatedCount = 0
        
        for event1 in events1 {
            for event2 in events2 {
                if abs(event1.timestamp.timeIntervalSince(event2.timestamp)) <= correlationWindow {
                    correlatedCount += 1
                    break
                }
            }
        }
        
        let strength = Double(correlatedCount) / Double(max(events1.count, events2.count))
        
        return ErrorCorrelation(
            primaryType: type1,
            correlatedType: type2,
            strength: strength,
            occurrences: correlatedCount,
            timeWindow: timeWindow
        )
    }
}

// MARK: - Error Correlation

/// Correlation analysis between error types
public struct ErrorCorrelation {
    public let primaryType: String
    public let correlatedType: String
    public let strength: Double // 0.0 to 1.0
    public let occurrences: Int
    public let timeWindow: TimeInterval
    
    public init(primaryType: String, correlatedType: String, strength: Double, occurrences: Int, timeWindow: TimeInterval) {
        self.primaryType = primaryType
        self.correlatedType = correlatedType
        self.strength = strength
        self.occurrences = occurrences
        self.timeWindow = timeWindow
    }
}