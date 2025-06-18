import Foundation
import Network
import AxiomCore
import AxiomCapabilities

// MARK: - Network Analytics Capability Configuration

/// Configuration for Network Analytics capability
public struct NetworkAnalyticsCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableRealTimeAnalytics: Bool
    public let enableHistoricalAnalytics: Bool
    public let enableNetworkPathAnalysis: Bool
    public let enablePerformanceBaselining: Bool
    public let enableAnomalyDetection: Bool
    public let enablePredictiveAnalytics: Bool
    public let enableGeoLocationTracking: Bool
    public let enableBandwidthAnalysis: Bool
    public let enableLatencyAnalysis: Bool
    public let enableErrorAnalysis: Bool
    public let samplingRate: Double
    public let retentionPeriod: TimeInterval
    public let aggregationInterval: TimeInterval
    public let anomalyThreshold: Double
    public let performanceThresholds: PerformanceThresholds
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableExport: Bool
    public let exportFormat: ExportFormat
    public let enableAlerts: Bool
    public let alertThresholds: AlertThresholds
    public let enableDeepPacketInspection: Bool
    public let maxDataPoints: Int
    public let enableCorrelationAnalysis: Bool
    
    public struct PerformanceThresholds: Codable {
        public let maxLatency: TimeInterval
        public let minThroughput: Double
        public let maxErrorRate: Double
        public let maxJitter: TimeInterval
        public let maxPacketLoss: Double
        
        public init(
            maxLatency: TimeInterval = 2.0,
            minThroughput: Double = 1_000_000, // 1 Mbps
            maxErrorRate: Double = 0.05, // 5%
            maxJitter: TimeInterval = 0.1,
            maxPacketLoss: Double = 0.01 // 1%
        ) {
            self.maxLatency = maxLatency
            self.minThroughput = minThroughput
            self.maxErrorRate = maxErrorRate
            self.maxJitter = maxJitter
            self.maxPacketLoss = maxPacketLoss
        }
    }
    
    public struct AlertThresholds: Codable {
        public let criticalLatency: TimeInterval
        public let criticalThroughputDrop: Double
        public let criticalErrorRate: Double
        public let consecutiveFailures: Int
        
        public init(
            criticalLatency: TimeInterval = 5.0,
            criticalThroughputDrop: Double = 0.5, // 50% drop
            criticalErrorRate: Double = 0.1, // 10%
            consecutiveFailures: Int = 5
        ) {
            self.criticalLatency = criticalLatency
            self.criticalThroughputDrop = criticalThroughputDrop
            self.criticalErrorRate = criticalErrorRate
            self.consecutiveFailures = consecutiveFailures
        }
    }
    
    public enum ExportFormat: String, Codable, CaseIterable {
        case json = "json"
        case csv = "csv"
        case protobuf = "protobuf"
        case influxdb = "influxdb"
        case prometheus = "prometheus"
    }
    
    public init(
        enableRealTimeAnalytics: Bool = true,
        enableHistoricalAnalytics: Bool = true,
        enableNetworkPathAnalysis: Bool = true,
        enablePerformanceBaselining: Bool = true,
        enableAnomalyDetection: Bool = true,
        enablePredictiveAnalytics: Bool = false,
        enableGeoLocationTracking: Bool = false,
        enableBandwidthAnalysis: Bool = true,
        enableLatencyAnalysis: Bool = true,
        enableErrorAnalysis: Bool = true,
        samplingRate: Double = 1.0, // 100% sampling
        retentionPeriod: TimeInterval = 604800.0, // 7 days
        aggregationInterval: TimeInterval = 60.0, // 1 minute
        anomalyThreshold: Double = 2.0, // 2 standard deviations
        performanceThresholds: PerformanceThresholds = PerformanceThresholds(),
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableExport: Bool = false,
        exportFormat: ExportFormat = .json,
        enableAlerts: Bool = true,
        alertThresholds: AlertThresholds = AlertThresholds(),
        enableDeepPacketInspection: Bool = false,
        maxDataPoints: Int = 100000,
        enableCorrelationAnalysis: Bool = true
    ) {
        self.enableRealTimeAnalytics = enableRealTimeAnalytics
        self.enableHistoricalAnalytics = enableHistoricalAnalytics
        self.enableNetworkPathAnalysis = enableNetworkPathAnalysis
        self.enablePerformanceBaselining = enablePerformanceBaselining
        self.enableAnomalyDetection = enableAnomalyDetection
        self.enablePredictiveAnalytics = enablePredictiveAnalytics
        self.enableGeoLocationTracking = enableGeoLocationTracking
        self.enableBandwidthAnalysis = enableBandwidthAnalysis
        self.enableLatencyAnalysis = enableLatencyAnalysis
        self.enableErrorAnalysis = enableErrorAnalysis
        self.samplingRate = samplingRate
        self.retentionPeriod = retentionPeriod
        self.aggregationInterval = aggregationInterval
        self.anomalyThreshold = anomalyThreshold
        self.performanceThresholds = performanceThresholds
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableExport = enableExport
        self.exportFormat = exportFormat
        self.enableAlerts = enableAlerts
        self.alertThresholds = alertThresholds
        self.enableDeepPacketInspection = enableDeepPacketInspection
        self.maxDataPoints = maxDataPoints
        self.enableCorrelationAnalysis = enableCorrelationAnalysis
    }
    
    public var isValid: Bool {
        samplingRate > 0 && samplingRate <= 1.0 &&
        retentionPeriod > 0 &&
        aggregationInterval > 0 &&
        anomalyThreshold > 0 &&
        maxDataPoints > 0
    }
    
    public func merged(with other: NetworkAnalyticsCapabilityConfiguration) -> NetworkAnalyticsCapabilityConfiguration {
        NetworkAnalyticsCapabilityConfiguration(
            enableRealTimeAnalytics: other.enableRealTimeAnalytics,
            enableHistoricalAnalytics: other.enableHistoricalAnalytics,
            enableNetworkPathAnalysis: other.enableNetworkPathAnalysis,
            enablePerformanceBaselining: other.enablePerformanceBaselining,
            enableAnomalyDetection: other.enableAnomalyDetection,
            enablePredictiveAnalytics: other.enablePredictiveAnalytics,
            enableGeoLocationTracking: other.enableGeoLocationTracking,
            enableBandwidthAnalysis: other.enableBandwidthAnalysis,
            enableLatencyAnalysis: other.enableLatencyAnalysis,
            enableErrorAnalysis: other.enableErrorAnalysis,
            samplingRate: other.samplingRate,
            retentionPeriod: other.retentionPeriod,
            aggregationInterval: other.aggregationInterval,
            anomalyThreshold: other.anomalyThreshold,
            performanceThresholds: other.performanceThresholds,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableExport: other.enableExport,
            exportFormat: other.exportFormat,
            enableAlerts: other.enableAlerts,
            alertThresholds: other.alertThresholds,
            enableDeepPacketInspection: other.enableDeepPacketInspection,
            maxDataPoints: other.maxDataPoints,
            enableCorrelationAnalysis: other.enableCorrelationAnalysis
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> NetworkAnalyticsCapabilityConfiguration {
        var adjustedSamplingRate = samplingRate
        var adjustedMaxDataPoints = maxDataPoints
        var adjustedLogging = enableLogging
        var adjustedRealTime = enableRealTimeAnalytics
        
        if environment.isLowPowerMode {
            adjustedSamplingRate = min(samplingRate, 0.1) // Reduce to 10% sampling
            adjustedMaxDataPoints = min(maxDataPoints, 10000)
            adjustedRealTime = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return NetworkAnalyticsCapabilityConfiguration(
            enableRealTimeAnalytics: adjustedRealTime,
            enableHistoricalAnalytics: enableHistoricalAnalytics,
            enableNetworkPathAnalysis: enableNetworkPathAnalysis,
            enablePerformanceBaselining: enablePerformanceBaselining,
            enableAnomalyDetection: enableAnomalyDetection,
            enablePredictiveAnalytics: enablePredictiveAnalytics,
            enableGeoLocationTracking: enableGeoLocationTracking,
            enableBandwidthAnalysis: enableBandwidthAnalysis,
            enableLatencyAnalysis: enableLatencyAnalysis,
            enableErrorAnalysis: enableErrorAnalysis,
            samplingRate: adjustedSamplingRate,
            retentionPeriod: retentionPeriod,
            aggregationInterval: aggregationInterval,
            anomalyThreshold: anomalyThreshold,
            performanceThresholds: performanceThresholds,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableExport: enableExport,
            exportFormat: exportFormat,
            enableAlerts: enableAlerts,
            alertThresholds: alertThresholds,
            enableDeepPacketInspection: enableDeepPacketInspection,
            maxDataPoints: adjustedMaxDataPoints,
            enableCorrelationAnalysis: enableCorrelationAnalysis
        )
    }
}

// MARK: - Network Analytics Types

/// Network performance measurement
public struct NetworkMeasurement: Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let endpoint: String
    public let method: String
    public let responseTime: TimeInterval
    public let requestSize: Int64
    public let responseSize: Int64
    public let statusCode: Int?
    public let error: String?
    public let connectionType: String
    public let networkType: NetworkType
    public let throughput: Double
    public let jitter: TimeInterval?
    public let packetLoss: Double?
    public let retryCount: Int
    public let geolocation: GeoLocation?
    public let userAgent: String?
    public let sessionId: String?
    
    public enum NetworkType: String, Sendable, Codable, CaseIterable {
        case wifi = "wifi"
        case cellular = "cellular"
        case ethernet = "ethernet"
        case unknown = "unknown"
    }
    
    public struct GeoLocation: Sendable, Codable {
        public let latitude: Double
        public let longitude: Double
        public let country: String?
        public let region: String?
        public let city: String?
        
        public init(latitude: Double, longitude: Double, country: String? = nil, region: String? = nil, city: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.country = country
            self.region = region
            self.city = city
        }
    }
    
    public init(
        endpoint: String,
        method: String,
        responseTime: TimeInterval,
        requestSize: Int64,
        responseSize: Int64,
        statusCode: Int? = nil,
        error: String? = nil,
        connectionType: String = "unknown",
        networkType: NetworkType = .unknown,
        throughput: Double = 0,
        jitter: TimeInterval? = nil,
        packetLoss: Double? = nil,
        retryCount: Int = 0,
        geolocation: GeoLocation? = nil,
        userAgent: String? = nil,
        sessionId: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.endpoint = endpoint
        self.method = method
        self.responseTime = responseTime
        self.requestSize = requestSize
        self.responseSize = responseSize
        self.statusCode = statusCode
        self.error = error
        self.connectionType = connectionType
        self.networkType = networkType
        self.throughput = throughput
        self.jitter = jitter
        self.packetLoss = packetLoss
        self.retryCount = retryCount
        self.geolocation = geolocation
        self.userAgent = userAgent
        self.sessionId = sessionId
    }
    
    public var isSuccess: Bool {
        error == nil && (statusCode == nil || (200...299).contains(statusCode!))
    }
    
    public var isError: Bool {
        !isSuccess
    }
    
    public var totalBytes: Int64 {
        requestSize + responseSize
    }
}

/// Aggregated network statistics
public struct NetworkStatistics: Sendable {
    public let timeWindow: TimeInterval
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageResponseTime: TimeInterval
    public let medianResponseTime: TimeInterval
    public let p95ResponseTime: TimeInterval
    public let p99ResponseTime: TimeInterval
    public let minResponseTime: TimeInterval
    public let maxResponseTime: TimeInterval
    public let totalBytesTransferred: Int64
    public let averageThroughput: Double
    public let peakThroughput: Double
    public let errorRate: Double
    public let averageJitter: TimeInterval?
    public let averagePacketLoss: Double?
    public let networkTypeDistribution: [String: Int]
    public let endpointStatistics: [String: EndpointStats]
    public let statusCodeDistribution: [Int: Int]
    
    public struct EndpointStats: Sendable {
        public let endpoint: String
        public let requestCount: Int
        public let averageResponseTime: TimeInterval
        public let errorRate: Double
        public let throughput: Double
        
        public init(endpoint: String, requestCount: Int, averageResponseTime: TimeInterval, errorRate: Double, throughput: Double) {
            self.endpoint = endpoint
            self.requestCount = requestCount
            self.averageResponseTime = averageResponseTime
            self.errorRate = errorRate
            self.throughput = throughput
        }
    }
    
    public init(
        timeWindow: TimeInterval,
        totalRequests: Int = 0,
        successfulRequests: Int = 0,
        failedRequests: Int = 0,
        averageResponseTime: TimeInterval = 0,
        medianResponseTime: TimeInterval = 0,
        p95ResponseTime: TimeInterval = 0,
        p99ResponseTime: TimeInterval = 0,
        minResponseTime: TimeInterval = 0,
        maxResponseTime: TimeInterval = 0,
        totalBytesTransferred: Int64 = 0,
        averageThroughput: Double = 0,
        peakThroughput: Double = 0,
        errorRate: Double = 0,
        averageJitter: TimeInterval? = nil,
        averagePacketLoss: Double? = nil,
        networkTypeDistribution: [String: Int] = [:],
        endpointStatistics: [String: EndpointStats] = [:],
        statusCodeDistribution: [Int: Int] = [:]
    ) {
        self.timeWindow = timeWindow
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageResponseTime = averageResponseTime
        self.medianResponseTime = medianResponseTime
        self.p95ResponseTime = p95ResponseTime
        self.p99ResponseTime = p99ResponseTime
        self.minResponseTime = minResponseTime
        self.maxResponseTime = maxResponseTime
        self.totalBytesTransferred = totalBytesTransferred
        self.averageThroughput = averageThroughput
        self.peakThroughput = peakThroughput
        self.errorRate = errorRate
        self.averageJitter = averageJitter
        self.averagePacketLoss = averagePacketLoss
        self.networkTypeDistribution = networkTypeDistribution
        self.endpointStatistics = endpointStatistics
        self.statusCodeDistribution = statusCodeDistribution
    }
    
    public var successRate: Double {
        totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
    }
    
    public var requestsPerSecond: Double {
        timeWindow > 0 ? Double(totalRequests) / timeWindow : 0
    }
}

/// Network anomaly detection result
public struct NetworkAnomaly: Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: AnomalyType
    public let severity: Severity
    public let metric: String
    public let actualValue: Double
    public let expectedValue: Double
    public let threshold: Double
    public let confidence: Double
    public let description: String
    public let affected: AffectedScope
    public let duration: TimeInterval?
    
    public enum AnomalyType: String, Sendable, Codable, CaseIterable {
        case latencySpike = "latency-spike"
        case throughputDrop = "throughput-drop"
        case errorRateIncrease = "error-rate-increase"
        case connectivityIssue = "connectivity-issue"
        case jitterIncrease = "jitter-increase"
        case packetLossIncrease = "packet-loss-increase"
        case timeoutIncrease = "timeout-increase"
    }
    
    public enum Severity: String, Sendable, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public struct AffectedScope: Sendable, Codable {
        public let endpoints: [String]
        public let networkTypes: [String]
        public let regions: [String]
        public let userSegments: [String]
        
        public init(endpoints: [String] = [], networkTypes: [String] = [], regions: [String] = [], userSegments: [String] = []) {
            self.endpoints = endpoints
            self.networkTypes = networkTypes
            self.regions = regions
            self.userSegments = userSegments
        }
    }
    
    public init(
        type: AnomalyType,
        severity: Severity,
        metric: String,
        actualValue: Double,
        expectedValue: Double,
        threshold: Double,
        confidence: Double,
        description: String,
        affected: AffectedScope = AffectedScope(),
        duration: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.severity = severity
        self.metric = metric
        self.actualValue = actualValue
        self.expectedValue = expectedValue
        self.threshold = threshold
        self.confidence = confidence
        self.description = description
        self.affected = affected
        self.duration = duration
    }
    
    public var deviationPercentage: Double {
        guard expectedValue != 0 else { return 0 }
        return ((actualValue - expectedValue) / expectedValue) * 100
    }
}

/// Network performance alert
public struct NetworkAlert: Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: AlertType
    public let severity: Severity
    public let title: String
    public let message: String
    public let metric: String
    public let currentValue: Double
    public let thresholdValue: Double
    public let affectedEndpoints: [String]
    public let recommendedActions: [String]
    public let isResolved: Bool
    public let resolvedAt: Date?
    
    public enum AlertType: String, Sendable, Codable, CaseIterable {
        case performanceDegradation = "performance-degradation"
        case serviceUnavailable = "service-unavailable"
        case highErrorRate = "high-error-rate"
        case connectivityIssue = "connectivity-issue"
        case capacityThreshold = "capacity-threshold"
        case securityAnomaly = "security-anomaly"
    }
    
    public enum Severity: String, Sendable, Codable, CaseIterable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
    }
    
    public init(
        type: AlertType,
        severity: Severity,
        title: String,
        message: String,
        metric: String,
        currentValue: Double,
        thresholdValue: Double,
        affectedEndpoints: [String] = [],
        recommendedActions: [String] = [],
        isResolved: Bool = false,
        resolvedAt: Date? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.metric = metric
        self.currentValue = currentValue
        self.thresholdValue = thresholdValue
        self.affectedEndpoints = affectedEndpoints
        self.recommendedActions = recommendedActions
        self.isResolved = isResolved
        self.resolvedAt = resolvedAt
    }
    
    public var thresholdExceedancePercentage: Double {
        guard thresholdValue != 0 else { return 0 }
        return ((currentValue - thresholdValue) / thresholdValue) * 100
    }
}

// MARK: - Network Analytics Resource

/// Network analytics resource management
public actor NetworkAnalyticsCapabilityResource: AxiomCapabilityResource {
    private let configuration: NetworkAnalyticsCapabilityConfiguration
    private var measurements: [NetworkMeasurement] = []
    private var statistics: [TimeInterval: NetworkStatistics] = [:]
    private var anomalies: [NetworkAnomaly] = []
    private var alerts: [NetworkAlert] = []
    private var performanceBaseline: [String: PerformanceBaseline] = [:]
    private var measurementStreamContinuation: AsyncStream<NetworkMeasurement>.Continuation?
    private var anomalyStreamContinuation: AsyncStream<NetworkAnomaly>.Continuation?
    private var alertStreamContinuation: AsyncStream<NetworkAlert>.Continuation?
    private var aggregationTimer: Timer?
    
    private struct PerformanceBaseline {
        var averageResponseTime: Double
        var averageThroughput: Double
        var errorRate: Double
        var sampleCount: Int
        var lastUpdated: Date
        
        init() {
            self.averageResponseTime = 0
            self.averageThroughput = 0
            self.errorRate = 0
            self.sampleCount = 0
            self.lastUpdated = Date()
        }
        
        mutating func update(with measurement: NetworkMeasurement) {
            let newCount = sampleCount + 1
            averageResponseTime = ((averageResponseTime * Double(sampleCount)) + measurement.responseTime) / Double(newCount)
            averageThroughput = ((averageThroughput * Double(sampleCount)) + measurement.throughput) / Double(newCount)
            
            let errorValue = measurement.isError ? 1.0 : 0.0
            errorRate = ((errorRate * Double(sampleCount)) + errorValue) / Double(newCount)
            
            sampleCount = newCount
            lastUpdated = Date()
        }
    }
    
    public init(configuration: NetworkAnalyticsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxDataPoints * 2000, // 2KB per measurement
            cpu: configuration.enableRealTimeAnalytics ? 3.0 : 1.0,
            bandwidth: 0,
            storage: configuration.maxDataPoints * 1000 // 1KB per measurement
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let measurementMemory = measurements.count * 1000
            let statisticsMemory = statistics.count * 5000
            let anomalyMemory = anomalies.count * 500
            
            return ResourceUsage(
                memory: measurementMemory + statisticsMemory + anomalyMemory,
                cpu: configuration.enableRealTimeAnalytics ? 2.0 : 0.5,
                bandwidth: 0,
                storage: measurements.count * 500
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // Network analytics is always available
    }
    
    public func release() async {
        aggregationTimer?.invalidate()
        aggregationTimer = nil
        
        measurements.removeAll()
        statistics.removeAll()
        anomalies.removeAll()
        alerts.removeAll()
        performanceBaseline.removeAll()
        
        measurementStreamContinuation?.finish()
        anomalyStreamContinuation?.finish()
        alertStreamContinuation?.finish()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        await startAggregationTimer()
    }
    
    internal func updateConfiguration(_ configuration: NetworkAnalyticsCapabilityConfiguration) async throws {
        // Restart aggregation timer if interval changed
        if configuration.aggregationInterval != self.configuration.aggregationInterval {
            await startAggregationTimer()
        }
        
        // Trim data if max data points reduced
        if configuration.maxDataPoints < measurements.count {
            let excessCount = measurements.count - configuration.maxDataPoints
            measurements.removeFirst(excessCount)
        }
    }
    
    // MARK: - Measurement Collection
    
    public func recordMeasurement(_ measurement: NetworkMeasurement) async {
        // Apply sampling rate
        if Double.random(in: 0...1) > configuration.samplingRate {
            return
        }
        
        measurements.append(measurement)
        
        // Trim if exceeding max data points
        if measurements.count > configuration.maxDataPoints {
            let excessCount = measurements.count - configuration.maxDataPoints
            measurements.removeFirst(excessCount)
        }
        
        // Update performance baseline
        if configuration.enablePerformanceBaselining {
            await updatePerformanceBaseline(with: measurement)
        }
        
        // Real-time anomaly detection
        if configuration.enableAnomalyDetection && configuration.enableRealTimeAnalytics {
            await detectAnomalies(for: measurement)
        }
        
        // Real-time alerting
        if configuration.enableAlerts && configuration.enableRealTimeAnalytics {
            await checkAlerts(for: measurement)
        }
        
        measurementStreamContinuation?.yield(measurement)
        
        if configuration.enableLogging {
            await logMeasurement(measurement)
        }
    }
    
    public var measurementStream: AsyncStream<NetworkMeasurement> {
        AsyncStream { continuation in
            self.measurementStreamContinuation = continuation
        }
    }
    
    // MARK: - Statistics
    
    public func getStatistics(for timeWindow: TimeInterval) async -> NetworkStatistics? {
        if let cachedStats = statistics[timeWindow] {
            return cachedStats
        }
        
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        let relevantMeasurements = measurements.filter { $0.timestamp >= cutoffTime }
        
        guard !relevantMeasurements.isEmpty else { return nil }
        
        let stats = await calculateStatistics(from: relevantMeasurements, timeWindow: timeWindow)
        statistics[timeWindow] = stats
        
        return stats
    }
    
    public func getHistoricalStatistics(from startDate: Date, to endDate: Date, interval: TimeInterval) async -> [NetworkStatistics] {
        var results: [NetworkStatistics] = []
        var currentTime = startDate
        
        while currentTime < endDate {
            let windowEnd = min(currentTime.addingTimeInterval(interval), endDate)
            let windowMeasurements = measurements.filter { measurement in
                measurement.timestamp >= currentTime && measurement.timestamp < windowEnd
            }
            
            if !windowMeasurements.isEmpty {
                let stats = await calculateStatistics(from: windowMeasurements, timeWindow: interval)
                results.append(stats)
            }
            
            currentTime = windowEnd
        }
        
        return results
    }
    
    // MARK: - Anomaly Detection
    
    public var anomalyStream: AsyncStream<NetworkAnomaly> {
        AsyncStream { continuation in
            self.anomalyStreamContinuation = continuation
        }
    }
    
    public func getAnomalies(since: Date? = nil) async -> [NetworkAnomaly] {
        if let since = since {
            return anomalies.filter { $0.timestamp >= since }
        }
        return anomalies
    }
    
    public func getAnomalies(ofType type: NetworkAnomaly.AnomalyType) async -> [NetworkAnomaly] {
        anomalies.filter { $0.type == type }
    }
    
    // MARK: - Alerts
    
    public var alertStream: AsyncStream<NetworkAlert> {
        AsyncStream { continuation in
            self.alertStreamContinuation = continuation
        }
    }
    
    public func getAlerts(since: Date? = nil) async -> [NetworkAlert] {
        if let since = since {
            return alerts.filter { $0.timestamp >= since }
        }
        return alerts
    }
    
    public func getActiveAlerts() async -> [NetworkAlert] {
        alerts.filter { !$0.isResolved }
    }
    
    public func resolveAlert(_ alertId: UUID) async {
        if let index = alerts.firstIndex(where: { $0.id == alertId }) {
            let resolvedAlert = NetworkAlert(
                type: alerts[index].type,
                severity: alerts[index].severity,
                title: alerts[index].title,
                message: alerts[index].message,
                metric: alerts[index].metric,
                currentValue: alerts[index].currentValue,
                thresholdValue: alerts[index].thresholdValue,
                affectedEndpoints: alerts[index].affectedEndpoints,
                recommendedActions: alerts[index].recommendedActions,
                isResolved: true,
                resolvedAt: Date()
            )
            alerts[index] = resolvedAlert
        }
    }
    
    // MARK: - Data Export
    
    public func exportData(format: NetworkAnalyticsCapabilityConfiguration.ExportFormat, timeRange: DateInterval? = nil) async -> Data? {
        let dataToExport: [NetworkMeasurement]
        
        if let timeRange = timeRange {
            dataToExport = measurements.filter { measurement in
                timeRange.contains(measurement.timestamp)
            }
        } else {
            dataToExport = measurements
        }
        
        switch format {
        case .json:
            return await exportAsJSON(dataToExport)
        case .csv:
            return await exportAsCSV(dataToExport)
        case .protobuf:
            return await exportAsProtobuf(dataToExport)
        case .influxdb:
            return await exportAsInfluxDB(dataToExport)
        case .prometheus:
            return await exportAsPrometheus(dataToExport)
        }
    }
    
    // MARK: - Performance Analysis
    
    public func getPerformanceReport(for endpoint: String, timeWindow: TimeInterval) async -> PerformanceReport? {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        let endpointMeasurements = measurements.filter { measurement in
            measurement.endpoint == endpoint && measurement.timestamp >= cutoffTime
        }
        
        guard !endpointMeasurements.isEmpty else { return nil }
        
        return await generatePerformanceReport(from: endpointMeasurements, endpoint: endpoint)
    }
    
    public func getNetworkPathAnalysis() async -> NetworkPathAnalysis? {
        guard configuration.enableNetworkPathAnalysis else { return nil }
        
        // Analyze network paths and connection patterns
        return await analyzeNetworkPaths()
    }
    
    // MARK: - Private Methods
    
    private func startAggregationTimer() async {
        aggregationTimer?.invalidate()
        
        aggregationTimer = Timer.scheduledTimer(withTimeInterval: configuration.aggregationInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performAggregation()
            }
        }
    }
    
    private func performAggregation() async {
        if configuration.enableHistoricalAnalytics {
            await aggregateHistoricalData()
        }
        
        if configuration.enableAnomalyDetection {
            await performBatchAnomalyDetection()
        }
        
        await cleanupOldData()
    }
    
    private func calculateStatistics(from measurements: [NetworkMeasurement], timeWindow: TimeInterval) async -> NetworkStatistics {
        let totalRequests = measurements.count
        let successfulRequests = measurements.filter { $0.isSuccess }.count
        let failedRequests = totalRequests - successfulRequests
        
        let responseTimes = measurements.map { $0.responseTime }.sorted()
        let averageResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        let medianResponseTime = responseTimes.isEmpty ? 0 : responseTimes[responseTimes.count / 2]
        let p95ResponseTime = responseTimes.isEmpty ? 0 : responseTimes[Int(Double(responseTimes.count) * 0.95)]
        let p99ResponseTime = responseTimes.isEmpty ? 0 : responseTimes[Int(Double(responseTimes.count) * 0.99)]
        let minResponseTime = responseTimes.first ?? 0
        let maxResponseTime = responseTimes.last ?? 0
        
        let totalBytes = measurements.reduce(0) { $0 + $1.totalBytes }
        let throughputs = measurements.map { $0.throughput }
        let averageThroughput = throughputs.isEmpty ? 0 : throughputs.reduce(0, +) / Double(throughputs.count)
        let peakThroughput = throughputs.max() ?? 0
        
        let errorRate = totalRequests > 0 ? Double(failedRequests) / Double(totalRequests) : 0
        
        let jitters = measurements.compactMap { $0.jitter }
        let averageJitter = jitters.isEmpty ? nil : jitters.reduce(0, +) / Double(jitters.count)
        
        let packetLosses = measurements.compactMap { $0.packetLoss }
        let averagePacketLoss = packetLosses.isEmpty ? nil : packetLosses.reduce(0, +) / Double(packetLosses.count)
        
        // Network type distribution
        var networkTypeDistribution: [String: Int] = [:]
        for measurement in measurements {
            networkTypeDistribution[measurement.networkType.rawValue, default: 0] += 1
        }
        
        // Endpoint statistics
        var endpointStats: [String: NetworkStatistics.EndpointStats] = [:]
        let groupedByEndpoint = Dictionary(grouping: measurements) { $0.endpoint }
        for (endpoint, endpointMeasurements) in groupedByEndpoint {
            let endpointResponseTimes = endpointMeasurements.map { $0.responseTime }
            let endpointAvgResponseTime = endpointResponseTimes.reduce(0, +) / Double(endpointResponseTimes.count)
            let endpointErrors = endpointMeasurements.filter { $0.isError }.count
            let endpointErrorRate = Double(endpointErrors) / Double(endpointMeasurements.count)
            let endpointThroughputs = endpointMeasurements.map { $0.throughput }
            let endpointAvgThroughput = endpointThroughputs.reduce(0, +) / Double(endpointThroughputs.count)
            
            endpointStats[endpoint] = NetworkStatistics.EndpointStats(
                endpoint: endpoint,
                requestCount: endpointMeasurements.count,
                averageResponseTime: endpointAvgResponseTime,
                errorRate: endpointErrorRate,
                throughput: endpointAvgThroughput
            )
        }
        
        // Status code distribution
        var statusCodeDistribution: [Int: Int] = [:]
        for measurement in measurements {
            if let statusCode = measurement.statusCode {
                statusCodeDistribution[statusCode, default: 0] += 1
            }
        }
        
        return NetworkStatistics(
            timeWindow: timeWindow,
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            averageResponseTime: averageResponseTime,
            medianResponseTime: medianResponseTime,
            p95ResponseTime: p95ResponseTime,
            p99ResponseTime: p99ResponseTime,
            minResponseTime: minResponseTime,
            maxResponseTime: maxResponseTime,
            totalBytesTransferred: totalBytes,
            averageThroughput: averageThroughput,
            peakThroughput: peakThroughput,
            errorRate: errorRate,
            averageJitter: averageJitter,
            averagePacketLoss: averagePacketLoss,
            networkTypeDistribution: networkTypeDistribution,
            endpointStatistics: endpointStats,
            statusCodeDistribution: statusCodeDistribution
        )
    }
    
    private func updatePerformanceBaseline(with measurement: NetworkMeasurement) async {
        let key = measurement.endpoint
        
        if performanceBaseline[key] == nil {
            performanceBaseline[key] = PerformanceBaseline()
        }
        
        performanceBaseline[key]?.update(with: measurement)
    }
    
    private func detectAnomalies(for measurement: NetworkMeasurement) async {
        guard let baseline = performanceBaseline[measurement.endpoint] else { return }
        
        // Detect response time anomalies
        if measurement.responseTime > baseline.averageResponseTime * configuration.anomalyThreshold {
            let anomaly = NetworkAnomaly(
                type: .latencySpike,
                severity: .medium,
                metric: "response_time",
                actualValue: measurement.responseTime,
                expectedValue: baseline.averageResponseTime,
                threshold: baseline.averageResponseTime * configuration.anomalyThreshold,
                confidence: 0.85,
                description: "Response time significantly higher than baseline for \(measurement.endpoint)",
                affected: NetworkAnomaly.AffectedScope(endpoints: [measurement.endpoint])
            )
            
            anomalies.append(anomaly)
            anomalyStreamContinuation?.yield(anomaly)
        }
        
        // Detect throughput anomalies
        if measurement.throughput < baseline.averageThroughput * (1.0 - configuration.anomalyThreshold) {
            let anomaly = NetworkAnomaly(
                type: .throughputDrop,
                severity: .medium,
                metric: "throughput",
                actualValue: measurement.throughput,
                expectedValue: baseline.averageThroughput,
                threshold: baseline.averageThroughput * (1.0 - configuration.anomalyThreshold),
                confidence: 0.80,
                description: "Throughput significantly lower than baseline for \(measurement.endpoint)",
                affected: NetworkAnomaly.AffectedScope(endpoints: [measurement.endpoint])
            )
            
            anomalies.append(anomaly)
            anomalyStreamContinuation?.yield(anomaly)
        }
    }
    
    private func checkAlerts(for measurement: NetworkMeasurement) async {
        // Check latency threshold
        if measurement.responseTime > configuration.alertThresholds.criticalLatency {
            let alert = NetworkAlert(
                type: .performanceDegradation,
                severity: .critical,
                title: "Critical Latency Alert",
                message: "Response time (\(String(format: "%.2f", measurement.responseTime))s) exceeds critical threshold",
                metric: "response_time",
                currentValue: measurement.responseTime,
                thresholdValue: configuration.alertThresholds.criticalLatency,
                affectedEndpoints: [measurement.endpoint],
                recommendedActions: ["Check network connectivity", "Investigate server performance", "Consider scaling resources"]
            )
            
            alerts.append(alert)
            alertStreamContinuation?.yield(alert)
        }
        
        // Check error conditions
        if measurement.isError {
            let recentErrors = measurements.suffix(configuration.alertThresholds.consecutiveFailures)
                .filter { $0.endpoint == measurement.endpoint && $0.isError }
            
            if recentErrors.count >= configuration.alertThresholds.consecutiveFailures {
                let alert = NetworkAlert(
                    type: .serviceUnavailable,
                    severity: .critical,
                    title: "Service Unavailable Alert",
                    message: "\(configuration.alertThresholds.consecutiveFailures) consecutive failures for \(measurement.endpoint)",
                    metric: "error_rate",
                    currentValue: 1.0,
                    thresholdValue: 0.0,
                    affectedEndpoints: [measurement.endpoint],
                    recommendedActions: ["Check service status", "Verify network connectivity", "Review recent deployments"]
                )
                
                alerts.append(alert)
                alertStreamContinuation?.yield(alert)
            }
        }
    }
    
    private func performBatchAnomalyDetection() async {
        // Perform more sophisticated anomaly detection on batched data
        // This would include time series analysis, seasonal decomposition, etc.
        
        if configuration.enableLogging {
            print("[NetworkAnalytics] 🔍 Performing batch anomaly detection")
        }
    }
    
    private func aggregateHistoricalData() async {
        // Aggregate recent measurements into time-based statistics
        let now = Date()
        let hourAgo = now.addingTimeInterval(-3600)
        
        let recentMeasurements = measurements.filter { $0.timestamp >= hourAgo }
        if !recentMeasurements.isEmpty {
            let hourlyStats = await calculateStatistics(from: recentMeasurements, timeWindow: 3600)
            statistics[3600] = hourlyStats
        }
    }
    
    private func cleanupOldData() async {
        let cutoffTime = Date().addingTimeInterval(-configuration.retentionPeriod)
        
        measurements.removeAll { $0.timestamp < cutoffTime }
        anomalies.removeAll { $0.timestamp < cutoffTime }
        alerts.removeAll { $0.timestamp < cutoffTime && $0.isResolved }
        
        // Clean up old statistics
        let oldStatistics = statistics.filter { (timeWindow, stats) in
            // Keep only recent aggregated statistics
            Date().timeIntervalSince(Date()) < timeWindow * 2
        }
        statistics = oldStatistics
    }
    
    private func exportAsJSON(_ measurements: [NetworkMeasurement]) async -> Data? {
        return try? JSONEncoder().encode(measurements)
    }
    
    private func exportAsCSV(_ measurements: [NetworkMeasurement]) async -> Data? {
        var csv = "timestamp,endpoint,method,response_time,request_size,response_size,status_code,error,throughput\n"
        
        for measurement in measurements {
            csv += "\(measurement.timestamp.timeIntervalSince1970),"
            csv += "\(measurement.endpoint),"
            csv += "\(measurement.method),"
            csv += "\(measurement.responseTime),"
            csv += "\(measurement.requestSize),"
            csv += "\(measurement.responseSize),"
            csv += "\(measurement.statusCode ?? 0),"
            csv += "\(measurement.error ?? ""),"
            csv += "\(measurement.throughput)\n"
        }
        
        return csv.data(using: .utf8)
    }
    
    private func exportAsProtobuf(_ measurements: [NetworkMeasurement]) async -> Data? {
        // Simplified protobuf export - would use actual protobuf library
        return try? JSONEncoder().encode(measurements)
    }
    
    private func exportAsInfluxDB(_ measurements: [NetworkMeasurement]) async -> Data? {
        var influxData = ""
        
        for measurement in measurements {
            influxData += "network_measurement,"
            influxData += "endpoint=\(measurement.endpoint),"
            influxData += "method=\(measurement.method) "
            influxData += "response_time=\(measurement.responseTime),"
            influxData += "throughput=\(measurement.throughput) "
            influxData += "\(Int(measurement.timestamp.timeIntervalSince1970 * 1_000_000_000))\n"
        }
        
        return influxData.data(using: .utf8)
    }
    
    private func exportAsPrometheus(_ measurements: [NetworkMeasurement]) async -> Data? {
        var prometheusData = ""
        
        // Response time histogram
        prometheusData += "# HELP network_response_time_seconds Response time in seconds\n"
        prometheusData += "# TYPE network_response_time_seconds histogram\n"
        
        for measurement in measurements {
            prometheusData += "network_response_time_seconds{endpoint=\"\(measurement.endpoint)\",method=\"\(measurement.method)\"} \(measurement.responseTime)\n"
        }
        
        return prometheusData.data(using: .utf8)
    }
    
    private func generatePerformanceReport(from measurements: [NetworkMeasurement], endpoint: String) async -> PerformanceReport {
        let stats = await calculateStatistics(from: measurements, timeWindow: 3600) // 1 hour window
        
        return PerformanceReport(
            endpoint: endpoint,
            timeWindow: 3600,
            statistics: stats,
            recommendations: generateRecommendations(for: stats),
            performanceGrade: calculatePerformanceGrade(for: stats)
        )
    }
    
    private func analyzeNetworkPaths() async -> NetworkPathAnalysis {
        // Analyze network connection patterns and paths
        let uniqueEndpoints = Set(measurements.map { $0.endpoint })
        let connectionTypes = Set(measurements.map { $0.connectionType })
        let networkTypes = Set(measurements.map { $0.networkType.rawValue })
        
        return NetworkPathAnalysis(
            totalEndpoints: uniqueEndpoints.count,
            connectionTypes: Array(connectionTypes),
            networkTypes: Array(networkTypes),
            averageHopCount: 0, // Would be calculated from actual network analysis
            pathDiversity: Double(connectionTypes.count) / Double(uniqueEndpoints.count)
        )
    }
    
    private func generateRecommendations(for stats: NetworkStatistics) -> [String] {
        var recommendations: [String] = []
        
        if stats.errorRate > configuration.performanceThresholds.maxErrorRate {
            recommendations.append("High error rate detected (\(String(format: "%.2f%%", stats.errorRate * 100))). Investigate service health.")
        }
        
        if stats.averageResponseTime > configuration.performanceThresholds.maxLatency {
            recommendations.append("Average response time (\(String(format: "%.2f", stats.averageResponseTime))s) exceeds threshold. Consider optimization.")
        }
        
        if stats.averageThroughput < configuration.performanceThresholds.minThroughput {
            recommendations.append("Low throughput detected. Check network capacity and server resources.")
        }
        
        return recommendations
    }
    
    private func calculatePerformanceGrade(for stats: NetworkStatistics) -> String {
        var score = 100.0
        
        // Deduct points for poor performance metrics
        if stats.errorRate > configuration.performanceThresholds.maxErrorRate {
            score -= 30
        }
        
        if stats.averageResponseTime > configuration.performanceThresholds.maxLatency {
            score -= 25
        }
        
        if stats.averageThroughput < configuration.performanceThresholds.minThroughput {
            score -= 20
        }
        
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    private func logMeasurement(_ measurement: NetworkMeasurement) async {
        let status = measurement.isSuccess ? "✅" : "❌"
        print("[NetworkAnalytics] \(status) \(measurement.method) \(measurement.endpoint) - \(String(format: "%.2f", measurement.responseTime))s")
    }
    
    // Additional helper types
    private struct PerformanceReport {
        let endpoint: String
        let timeWindow: TimeInterval
        let statistics: NetworkStatistics
        let recommendations: [String]
        let performanceGrade: String
    }
    
    private struct NetworkPathAnalysis {
        let totalEndpoints: Int
        let connectionTypes: [String]
        let networkTypes: [String]
        let averageHopCount: Int
        let pathDiversity: Double
    }
}

// MARK: - Network Analytics Capability Implementation

/// Network Analytics capability providing comprehensive network performance monitoring
public actor NetworkAnalyticsCapability: DomainCapability {
    public typealias ConfigurationType = NetworkAnalyticsCapabilityConfiguration
    public typealias ResourceType = NetworkAnalyticsCapabilityResource
    
    private var _configuration: NetworkAnalyticsCapabilityConfiguration
    private var _resources: NetworkAnalyticsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "network-analytics-capability" }
    
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
    
    public var configuration: NetworkAnalyticsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: NetworkAnalyticsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: NetworkAnalyticsCapabilityConfiguration = NetworkAnalyticsCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = NetworkAnalyticsCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: NetworkAnalyticsCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Network Analytics configuration")
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
        // Network analytics is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // Network analytics doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Network Analytics Operations
    
    /// Record a network measurement
    public func recordMeasurement(_ measurement: NetworkMeasurement) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        await _resources.recordMeasurement(measurement)
    }
    
    /// Get measurement stream
    public func getMeasurementStream() async throws -> AsyncStream<NetworkMeasurement> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.measurementStream
    }
    
    /// Get network statistics for time window
    public func getStatistics(for timeWindow: TimeInterval) async throws -> NetworkStatistics? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.getStatistics(for: timeWindow)
    }
    
    /// Get historical statistics
    public func getHistoricalStatistics(from startDate: Date, to endDate: Date, interval: TimeInterval) async throws -> [NetworkStatistics] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.getHistoricalStatistics(from: startDate, to: endDate, interval: interval)
    }
    
    /// Get anomaly stream
    public func getAnomalyStream() async throws -> AsyncStream<NetworkAnomaly> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.anomalyStream
    }
    
    /// Get detected anomalies
    public func getAnomalies(since: Date? = nil) async throws -> [NetworkAnomaly] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.getAnomalies(since: since)
    }
    
    /// Get alert stream
    public func getAlertStream() async throws -> AsyncStream<NetworkAlert> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.alertStream
    }
    
    /// Get alerts
    public func getAlerts(since: Date? = nil) async throws -> [NetworkAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.getAlerts(since: since)
    }
    
    /// Get active alerts
    public func getActiveAlerts() async throws -> [NetworkAlert] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.getActiveAlerts()
    }
    
    /// Resolve alert
    public func resolveAlert(_ alertId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        await _resources.resolveAlert(alertId)
    }
    
    /// Export analytics data
    public func exportData(format: NetworkAnalyticsCapabilityConfiguration.ExportFormat, timeRange: DateInterval? = nil) async throws -> Data? {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Network Analytics capability not available")
        }
        
        return await _resources.exportData(format: format, timeRange: timeRange)
    }
    
    // MARK: - Convenience Methods
    
    /// Record URL request measurement
    public func recordURLRequest(_ request: URLRequest, response: URLResponse?, data: Data?, error: Error?, duration: TimeInterval) async throws {
        let measurement = NetworkMeasurement(
            endpoint: request.url?.absoluteString ?? "unknown",
            method: request.httpMethod ?? "GET",
            responseTime: duration,
            requestSize: Int64(request.httpBody?.count ?? 0),
            responseSize: Int64(data?.count ?? 0),
            statusCode: (response as? HTTPURLResponse)?.statusCode,
            error: error?.localizedDescription,
            throughput: data != nil ? Double(data!.count) / duration : 0
        )
        
        try await recordMeasurement(measurement)
    }
    
    /// Get performance summary for last hour
    public func getPerformanceSummary() async throws -> NetworkStatistics? {
        return try await getStatistics(for: 3600) // 1 hour
    }
    
    /// Get error rate for endpoint
    public func getErrorRate(for endpoint: String, timeWindow: TimeInterval = 3600) async throws -> Double {
        guard let stats = try await getStatistics(for: timeWindow) else { return 0 }
        
        if let endpointStats = stats.endpointStatistics[endpoint] {
            return endpointStats.errorRate
        }
        
        return 0
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Network Analytics specific errors
public enum NetworkAnalyticsError: Error, LocalizedError {
    case invalidMeasurement(String)
    case exportFailed(String)
    case dataRetentionExceeded
    case anomalyDetectionFailed(String)
    case alertProcessingFailed(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidMeasurement(let reason):
            return "Invalid network measurement: \(reason)"
        case .exportFailed(let reason):
            return "Data export failed: \(reason)"
        case .dataRetentionExceeded:
            return "Data retention period exceeded"
        case .anomalyDetectionFailed(let reason):
            return "Anomaly detection failed: \(reason)"
        case .alertProcessingFailed(let reason):
            return "Alert processing failed: \(reason)"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        }
    }
}