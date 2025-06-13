import Foundation

// MARK: - Global Error Handler

/// Global error handler for the framework
@MainActor
public final class GlobalErrorHandler {
    public static let shared = GlobalErrorHandler()
    
    private var logger: any ErrorLogger = ConsoleErrorLogger()
    private var errorHandlers: [(AxiomError) -> Bool] = []
    
    private init() {}
    
    /// Set custom error logger
    public func setLogger(_ logger: any ErrorLogger) {
        self.logger = logger
    }
    
    /// Register error handler (returns true if handled)
    public func registerHandler(_ handler: @escaping (AxiomError) -> Bool) {
        errorHandlers.append(handler)
    }
    
    /// Handle an error with logging and registered handlers
    public func handle(_ error: AxiomError, severity: ErrorSeverity = .error, context: [String: Any] = [:]) {
        // Log the error
        logger.log(error, severity: severity, context: context)
        
        // Try registered handlers
        for handler in errorHandlers {
            if handler(error) {
                return // Error was handled
            }
        }
        
        // Default handling based on recovery strategy
        switch error.recoveryStrategy {
        case .silent:
            // Already logged, nothing more to do
            break
        case .userPrompt(let message):
            // In a real app, would show alert
            print("User Alert: \(message)")
        case .retry(let attempts):
            print("Retry suggested with \(attempts) attempts")
        case .propagate:
            // Error should be propagated up
            print("Error propagated: \(error)")
        case .fallback:
            print("Fallback recovery attempted")
        }
    }
}

// MARK: - Error Telemetry and Monitoring Infrastructure (REQUIREMENTS-W-06-004)

/// Comprehensive error context for telemetry logging
public struct TelemetryErrorContext: Sendable {
    public let error: AxiomError
    public let source: String
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(error: AxiomError, source: String = "unknown", metadata: [String: String] = [:]) {
        self.error = error
        self.source = source
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var category: ErrorCategory {
        return ErrorCategory.categorize(error)
    }
}

/// Structured telemetry logging with comprehensive context capture
public actor TelemetryLogger: ErrorLogger {
    private var loggedEvents: [ErrorTelemetryEvent] = []
    
    public init() {}
    
    public nonisolated func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        let stringContext = context.compactMapValues { $0 as? String }
        let event = ErrorTelemetryEvent(
            error: error,
            severity: severity,
            source: context["source"] as? String ?? "unknown",
            metadata: stringContext,
            timestamp: Date()
        )
        
        Task { await addEvent(event) }
    }
    
    private func addEvent(_ event: ErrorTelemetryEvent) {
        loggedEvents.append(event)
    }
    
    public func getLoggedEvents() -> [ErrorTelemetryEvent] {
        return loggedEvents
    }
    
    public func clearEvents() {
        loggedEvents.removeAll()
    }
}

/// Telemetry event structure for logged errors
public struct ErrorTelemetryEvent: Sendable {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let source: String
    public let metadata: [String: String]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, source: String, metadata: [String: String], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.source = source
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// Error metrics collection for comprehensive analytics (optimized for performance)
public actor ErrorMetricsCollector {
    private var errorCounts: [String: Int] = [:]
    private var errorCategories: [ErrorCategory: Int] = [:]
    private var sourceCategories: [String: [ErrorCategory: Int]] = [:]
    private var errorHistory: [TelemetryErrorContext] = []
    
    // Performance optimization: limit history size
    private let maxHistorySize = 10000
    private let historyCleanupThreshold = 12000
    
    public init() {}
    
    public func recordError(_ context: TelemetryErrorContext) {
        // Update counts
        errorCounts[context.source, default: 0] += 1
        errorCategories[context.category, default: 0] += 1
        
        // Update source-specific category tracking (optimization)
        if sourceCategories[context.source] == nil {
            sourceCategories[context.source] = [:]
        }
        sourceCategories[context.source]![context.category, default: 0] += 1
        
        // Add to history with size management
        errorHistory.append(context)
        
        // Cleanup old history if needed (performance optimization)
        if errorHistory.count > historyCleanupThreshold {
            let keepCount = maxHistorySize
            let removeCount = errorHistory.count - keepCount
            errorHistory.removeFirst(removeCount)
        }
    }
    
    public func getMetrics(for source: String) -> ErrorSourceMetrics {
        let count = errorCounts[source] ?? 0
        
        // Use cached source-specific category data for better performance
        let categoryDistribution = sourceCategories[source] ?? [:]
        
        // Calculate error rate (optimized with limited time window)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentErrorCount = errorHistory.lazy
            .reversed() // Start from most recent
            .prefix(while: { $0.timestamp > oneHourAgo })
            .filter { $0.source == source }
            .count
        
        let errorRate = Double(recentErrorCount) / 60.0
        
        return ErrorSourceMetrics(
            errorCount: count,
            errorCategory: categoryDistribution,
            errorRate: errorRate
        )
    }
    
    public func getAllMetrics() -> [String: ErrorSourceMetrics] {
        var result: [String: ErrorSourceMetrics] = [:]
        
        // Optimized: iterate over sources with cached data
        for source in errorCounts.keys {
            let count = errorCounts[source] ?? 0
            let categoryDistribution = sourceCategories[source] ?? [:]
            
            // Batch calculate error rates
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let recentErrorCount = errorHistory.lazy
                .reversed()
                .prefix(while: { $0.timestamp > oneHourAgo })
                .filter { $0.source == source }
                .count
            
            let errorRate = Double(recentErrorCount) / 60.0
            
            result[source] = ErrorSourceMetrics(
                errorCount: count,
                errorCategory: categoryDistribution,
                errorRate: errorRate
            )
        }
        return result
    }
    
    // Performance monitoring method
    public func getCollectorHealth() -> CollectorHealth {
        return CollectorHealth(
            historySize: errorHistory.count,
            totalSources: errorCounts.count,
            memoryUsageEstimate: estimateMemoryUsage()
        )
    }
    
    private func estimateMemoryUsage() -> Int {
        // Rough estimate: context + overhead per error
        return errorHistory.count * 200 // ~200 bytes per error context
    }
}

/// Health metrics for the error metrics collector
public struct CollectorHealth {
    public let historySize: Int
    public let totalSources: Int
    public let memoryUsageEstimate: Int
    
    public init(historySize: Int, totalSources: Int, memoryUsageEstimate: Int) {
        self.historySize = historySize
        self.totalSources = totalSources
        self.memoryUsageEstimate = memoryUsageEstimate
    }
}

/// Error metrics for a specific source
public struct ErrorSourceMetrics {
    public let errorCount: Int
    public let errorCategory: [ErrorCategory: Int]
    public let errorRate: Double
    
    public init(errorCount: Int, errorCategory: [ErrorCategory: Int], errorRate: Double) {
        self.errorCount = errorCount
        self.errorCategory = errorCategory
        self.errorRate = errorRate
    }
}

/// Error pattern analysis and spike detection (optimized with smart caching)
public actor ErrorPatternAnalyzer {
    private var errorHistory: [TelemetryErrorContext] = []
    private var categoryCache: [ErrorCategory: [TelemetryErrorContext]] = [:]
    private var sourceCache: [String: [TelemetryErrorContext]] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    
    // Performance optimization: limit analysis window
    private let maxAnalysisHistorySize = 5000
    private let cacheInvalidationInterval: TimeInterval = 300 // 5 minutes
    
    public init() {}
    
    public func addError(_ context: TelemetryErrorContext) {
        errorHistory.append(context)
        
        // Maintain reasonable history size for performance
        if errorHistory.count > maxAnalysisHistorySize * 2 {
            let keepCount = maxAnalysisHistorySize
            let removeCount = errorHistory.count - keepCount
            errorHistory.removeFirst(removeCount)
            invalidateCache()
        }
        
        // Update caches incrementally for better performance
        updateCachesIncremental(with: context)
    }
    
    public func analyzePatterns() -> [TelemetryErrorPattern] {
        updateCachesIfNeeded()
        
        return categoryCache.compactMap { category, errors in
            guard errors.count > 0 else { return nil }
            
            // Use cached data for faster analysis
            let timeWindow = calculateTimeWindow(for: errors)
            let commonSources = findCommonSourcesOptimized(in: errors)
            
            return TelemetryErrorPattern(
                category: category,
                frequency: errors.count,
                timeWindow: timeWindow,
                commonSources: commonSources,
                correlationScore: calculateCorrelationScore(for: errors)
            )
        }
    }
    
    public func detectSpike(in timeWindow: TimeInterval, 
                           category: ErrorCategory? = nil,
                           source: String? = nil) -> SpikeDetectionResult {
            let now = Date()
            let windowStart = now.addingTimeInterval(-timeWindow)
            
            // Optimized filtering 
            var relevantErrors = Array(errorHistory.lazy
                .reversed() // Start from most recent
                .prefix(while: { $0.timestamp >= windowStart }))
            
            if let category = category {
                relevantErrors = relevantErrors.filter { $0.category == category }
            }
            
            if let source = source {
                relevantErrors = relevantErrors.filter { $0.source == source }
            }
            
            let recentCount = relevantErrors.count
            let recentRate = Double(recentCount) / (timeWindow / 60.0)
            
            // Enhanced historical analysis with better window handling
            let historicalStart = now.addingTimeInterval(-86400) // 24 hours
            let historicalErrors = errorHistory.lazy
                .filter { $0.timestamp >= historicalStart && $0.timestamp < windowStart }
                .filter { context in
                    if let category = category, context.category != category { return false }
                    if let source = source, context.source != source { return false }
                    return true
                }
            
            let historicalCount = historicalErrors.count
            let historicalRate = Double(historicalCount) / (86400.0 / 60.0)
            
            // Enhanced spike detection with adaptive thresholds
            let adaptiveThreshold = max(historicalRate * 3.0, 5.0)
            let isSpike = recentRate > adaptiveThreshold
            
            return SpikeDetectionResult(
                isSpike: isSpike,
                currentRate: recentRate,
                historicalRate: historicalRate,
                threshold: adaptiveThreshold,
                recentCount: recentCount,
                timeWindow: timeWindow
            )
    }
    
    // Enhanced pattern correlation analysis
    public func findCorrelatedPatterns(category: ErrorCategory, 
                                     timeWindow: TimeInterval = 3600) -> [PatternCorrelation] {
            let now = Date()
            let windowStart = now.addingTimeInterval(-timeWindow)
            
            let categoryErrors = errorHistory.filter { 
                $0.category == category && $0.timestamp >= windowStart 
            }
            
            guard !categoryErrors.isEmpty else { return [] }
            
            var correlations: [PatternCorrelation] = []
            
            // Analyze temporal correlations with other categories
            for otherCategory in ErrorCategory.allCases where otherCategory != category {
                let otherErrors = errorHistory.filter { 
                    $0.category == otherCategory && $0.timestamp >= windowStart 
                }
                
                let correlation = calculateTemporalCorrelation(
                    primary: categoryErrors,
                    secondary: otherErrors,
                    timeWindow: timeWindow
                )
                
                if correlation.strength > 0.3 { // Significant correlation threshold
                    correlations.append(PatternCorrelation(
                        primaryCategory: category,
                        correlatedCategory: otherCategory,
                        strength: correlation.strength,
                        timeOffset: correlation.offset
                    ))
                }
            }
            
            return correlations.sorted { $0.strength > $1.strength }
    }
    
    // MARK: - Private Optimization Methods
    
    private func updateCachesIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastCacheUpdate) > cacheInvalidationInterval {
            rebuildCaches()
            lastCacheUpdate = now
        }
    }
    
    private func updateCachesIncremental(with context: TelemetryErrorContext) {
        // Update category cache
        if categoryCache[context.category] == nil {
            categoryCache[context.category] = []
        }
        categoryCache[context.category]?.append(context)
        
        // Update source cache
        if sourceCache[context.source] == nil {
            sourceCache[context.source] = []
        }
        sourceCache[context.source]?.append(context)
    }
    
    private func rebuildCaches() {
        categoryCache = Dictionary(grouping: errorHistory) { $0.category }
        sourceCache = Dictionary(grouping: errorHistory) { $0.source }
    }
    
    private func invalidateCache() {
        categoryCache.removeAll()
        sourceCache.removeAll()
        lastCacheUpdate = Date.distantPast
    }
    
    private func calculateTimeWindow(for errors: [TelemetryErrorContext]) -> TimeInterval {
        guard errors.count > 1,
              let earliest = errors.map({ $0.timestamp }).min(),
              let latest = errors.map({ $0.timestamp }).max() else {
            return 0
        }
        return latest.timeIntervalSince(earliest)
    }
    
    private func findCommonSourcesOptimized(in errors: [TelemetryErrorContext]) -> [String] {
        let sourceCounts = errors.reduce(into: [String: Int]()) { result, context in
            result[context.source, default: 0] += 1
        }
        
        return sourceCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map({ $0.key })
    }
    
    private func calculateCorrelationScore(for errors: [TelemetryErrorContext]) -> Double {
        guard errors.count > 1 else { return 0 }
        
        // Calculate temporal clustering score
        let timestamps = errors.map { $0.timestamp.timeIntervalSince1970 }
        let sortedTimestamps = timestamps.sorted()
        
        // Measure clustering using inter-arrival times
        let intervals: [Double] = zip(sortedTimestamps.dropFirst(), sortedTimestamps).map { $0 - $1 }
        let averageInterval: Double = intervals.reduce(0, +) / Double(intervals.count)
        
        // Break up variance calculation to avoid compiler timeout
        let squaredDeviations = intervals.map { interval -> Double in
            let deviation = interval - averageInterval
            return deviation * deviation
        }
        let variance = squaredDeviations.reduce(0, +) / Double(intervals.count)
        
        // Higher variance indicates more random distribution (lower correlation)
        // Lower variance indicates clustering (higher correlation)
        let denominator = (averageInterval * averageInterval) + 1.0
        return max(0, 1.0 - (variance / denominator))
    }
    
    private func calculateTemporalCorrelation(primary: [TelemetryErrorContext], 
                                            secondary: [TelemetryErrorContext], 
                                            timeWindow: TimeInterval) -> (strength: Double, offset: TimeInterval) {
        guard !primary.isEmpty && !secondary.isEmpty else {
            return (strength: 0, offset: 0)
        }
        
        let primaryTimes = primary.map { $0.timestamp.timeIntervalSince1970 }
        let secondaryTimes = secondary.map { $0.timestamp.timeIntervalSince1970 }
        
        // Calculate cross-correlation at different time offsets
        var maxCorrelation: Double = 0
        var bestOffset: TimeInterval = 0
        
        let maxOffset = min(timeWindow / 4, 1800) // Max 30 minutes or 1/4 of window
        let step: TimeInterval = 60 // 1 minute steps
        
        for offset in stride(from: -maxOffset, through: maxOffset, by: step) {
            let correlation = calculateCrossCorrelation(
                primary: primaryTimes,
                secondary: secondaryTimes,
                offset: offset
            )
            
            if abs(correlation) > abs(maxCorrelation) {
                maxCorrelation = correlation
                bestOffset = offset
            }
        }
        
        return (strength: abs(maxCorrelation), offset: bestOffset)
    }
    
    private func calculateCrossCorrelation(primary: [Double], 
                                         secondary: [Double], 
                                         offset: TimeInterval) -> Double {
        // Simplified cross-correlation calculation
        let adjustedSecondary = secondary.map { $0 + offset }
        
        var matchCount = 0
        let tolerance: Double = 300 // 5 minutes tolerance
        
        for primaryTime in primary {
            if adjustedSecondary.contains(where: { abs($0 - primaryTime) <= tolerance }) {
                matchCount += 1
            }
        }
        
        return Double(matchCount) / Double(max(primary.count, secondary.count))
    }
}

/// Error pattern detected by telemetry analysis (enhanced with correlation metrics)
public struct TelemetryErrorPattern: Sendable {
    public let category: ErrorCategory
    public let frequency: Int
    public let timeWindow: TimeInterval
    public let commonSources: [String]
    public let correlationScore: Double
    
    public init(category: ErrorCategory, frequency: Int, timeWindow: TimeInterval, commonSources: [String], correlationScore: Double = 0.0) {
        self.category = category
        self.frequency = frequency
        self.timeWindow = timeWindow
        self.commonSources = commonSources
        self.correlationScore = correlationScore
    }
}

/// Enhanced spike detection result with detailed metrics
public struct SpikeDetectionResult {
    public let isSpike: Bool
    public let currentRate: Double
    public let historicalRate: Double
    public let threshold: Double
    public let recentCount: Int
    public let timeWindow: TimeInterval
    
    public init(isSpike: Bool, currentRate: Double, historicalRate: Double, threshold: Double, recentCount: Int, timeWindow: TimeInterval) {
        self.isSpike = isSpike
        self.currentRate = currentRate
        self.historicalRate = historicalRate
        self.threshold = threshold
        self.recentCount = recentCount
        self.timeWindow = timeWindow
    }
}

/// Pattern correlation analysis between error categories
public struct PatternCorrelation {
    public let primaryCategory: ErrorCategory
    public let correlatedCategory: ErrorCategory
    public let strength: Double // 0.0 to 1.0
    public let timeOffset: TimeInterval // Offset in seconds
    
    public init(primaryCategory: ErrorCategory, correlatedCategory: ErrorCategory, strength: Double, timeOffset: TimeInterval) {
        self.primaryCategory = primaryCategory
        self.correlatedCategory = correlatedCategory
        self.strength = strength
        self.timeOffset = timeOffset
    }
}

/// Real-time error monitoring with threshold alerts
@MainActor
public class ErrorMonitor: ObservableObject {
    @Published public var recentErrors: [TelemetryErrorContext] = []
    @Published public var errorRate: Double = 0.0
    @Published public var criticalAlertTriggered: Bool = false
    
    public let criticalThreshold: Double = 10.0 // errors per minute
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?
    
    public init() {}
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Register with global error handler
        GlobalErrorHandler.shared.registerHandler { [weak self] error in
            Task { @MainActor in
                await self?.recordError(error)
            }
            return false // Continue propagation
        }
        
        // Start monitoring task
        monitoringTask = Task { @MainActor in
            while self.isMonitoring {
                await self.updateErrorRate()
                await self.checkThresholds()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func recordError(_ error: AxiomError) async {
        let context = TelemetryErrorContext(error: error, source: "GlobalErrorHandler")
        recentErrors.append(context)
        
        // Keep only last 100 errors
        if recentErrors.count > 100 {
            recentErrors.removeFirst(recentErrors.count - 100)
        }
    }
    
    private func updateErrorRate() async {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let recentCount = recentErrors.filter { $0.timestamp > oneMinuteAgo }.count
        errorRate = Double(recentCount)
    }
    
    private func checkThresholds() async {
        if errorRate > criticalThreshold {
            criticalAlertTriggered = true
            await sendCriticalAlert()
        }
    }
    
    private func sendCriticalAlert() async {
        // In a real implementation, would send actual alerts
        print("CRITICAL ALERT: Error rate (\(errorRate)) exceeded threshold (\(criticalThreshold))")
    }
}

// MARK: - Privacy-Compliant Error Sanitization

/// Privacy-compliant error sanitization
public extension AxiomError {
    func sanitized() -> AxiomError {
        switch self {
        case .validationError(.invalidInput(let field, _)):
            // Remove potentially sensitive field values
            return .validationError(.invalidInput(field, "***"))
            
        case .navigationError(let navError):
            // Sanitize navigation errors that might contain sensitive URLs
            switch navError {
            case .invalidURL(let component, _):
                return .navigationError(.invalidURL(component: component, value: "***"))
            default:
                return self
            }
            
        case .persistenceError(.saveFailed(_)):
            // Sanitize persistence error messages that might contain data
            return .persistenceError(.saveFailed("Save operation failed"))
            
        case .clientError(.invalidAction(_)):
            // Sanitize client error actions that might contain sensitive info
            return .clientError(.invalidAction("***"))
            
        default:
            return self
        }
    }
}

/// URL sanitization extension
public extension URL {
    func sanitized() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        
        // Remove sensitive query parameters
        let sensitiveParams = ["token", "secret", "key", "password", "auth", "session"]
        components.queryItems = components.queryItems?.compactMap { item in
            if sensitiveParams.contains(where: { item.name.lowercased().contains($0) }) {
                return URLQueryItem(name: item.name, value: "***")
            }
            return item
        }
        
        return components.url ?? self
    }
}

// MARK: - External Service Integration

/// External service integration - Crash reporting logger
public class CrashReportingLogger: ErrorLogger {
    private let crashReporter: any CrashReporter
    
    public init(crashReporter: any CrashReporter) {
        self.crashReporter = crashReporter
    }
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        guard severity >= .error else { return }
        
        let crashEvent = CrashEvent(
            error: error.sanitized(),
            severity: severity,
            metadata: context,
            timestamp: Date()
        )
        
        crashReporter.recordCrash(crashEvent)
    }
}

/// External service integration - APM logger
public class APMLogger: ErrorLogger {
    private let apmService: any APMService
    
    public init(apmService: any APMService) {
        self.apmService = apmService
    }
    
    public func log(_ error: AxiomError, severity: ErrorSeverity, context: [String: Any]) {
        let errorEvent = APMErrorEvent(
            error: error,
            severity: severity,
            context: context,
            timestamp: Date()
        )
        
        apmService.trackError(errorEvent)
    }
}

/// Crash reporter protocol
public protocol CrashReporter {
    func recordCrash(_ event: CrashEvent)
}

/// APM service protocol
public protocol APMService {
    func trackError(_ event: APMErrorEvent)
}

/// Crash event structure
public struct CrashEvent {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let metadata: [String: Any]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, metadata: [String: Any], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// APM error event structure
public struct APMErrorEvent {
    public let error: AxiomError
    public let severity: ErrorSeverity
    public let context: [String: Any]
    public let timestamp: Date
    
    public init(error: AxiomError, severity: ErrorSeverity, context: [String: Any], timestamp: Date) {
        self.error = error
        self.severity = severity
        self.context = context
        self.timestamp = timestamp
    }
}

/// Mock crash reporter for testing
public class MockCrashReporter: CrashReporter {
    public var recordedErrors: [CrashEvent] = []
    
    public init() {}
    
    public func recordCrash(_ event: CrashEvent) {
        recordedErrors.append(event)
    }
}

/// Mock APM service for testing
public class MockAPMService: APMService {
    public var trackedErrors: [APMErrorEvent] = []
    
    public init() {}
    
    public func trackError(_ event: APMErrorEvent) {
        trackedErrors.append(event)
    }
}