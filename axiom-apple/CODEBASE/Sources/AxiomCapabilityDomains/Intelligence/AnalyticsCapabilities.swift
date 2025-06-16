import Foundation
import AxiomCapabilities
import AxiomCore

// MARK: - Analytics and Tracking Capabilities

/// Analytics configuration
public struct AnalyticsCapabilityConfiguration: AxiomCapabilityConfiguration {
    public let trackingId: String
    public let batchSize: Int
    public let flushInterval: TimeInterval
    public let enableDebugLogging: Bool
    public let enableCrashReporting: Bool
    public let enablePerformanceMonitoring: Bool
    public let samplingRate: Double
    public let endpoint: URL?
    
    public init(
        trackingId: String,
        batchSize: Int = 20,
        flushInterval: TimeInterval = 30,
        enableDebugLogging: Bool = false,
        enableCrashReporting: Bool = true,
        enablePerformanceMonitoring: Bool = true,
        samplingRate: Double = 1.0,
        endpoint: URL? = nil
    ) {
        self.trackingId = trackingId
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.enableDebugLogging = enableDebugLogging
        self.enableCrashReporting = enableCrashReporting
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.samplingRate = samplingRate
        self.endpoint = endpoint
    }
    
    public var isValid: Bool {
        !trackingId.isEmpty && batchSize > 0 && samplingRate >= 0 && samplingRate <= 1
    }
    
    public func merged(with other: AnalyticsCapabilityConfiguration) -> AnalyticsCapabilityConfiguration {
        AnalyticsCapabilityConfiguration(
            trackingId: other.trackingId.isEmpty ? trackingId : other.trackingId,
            batchSize: other.batchSize > 0 ? other.batchSize : batchSize,
            flushInterval: other.flushInterval > 0 ? other.flushInterval : flushInterval,
            enableDebugLogging: other.enableDebugLogging,
            enableCrashReporting: other.enableCrashReporting,
            enablePerformanceMonitoring: other.enablePerformanceMonitoring,
            samplingRate: other.samplingRate,
            endpoint: other.endpoint ?? endpoint
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AnalyticsCapabilityConfiguration {
        AnalyticsCapabilityConfiguration(
            trackingId: trackingId,
            batchSize: environment.isDebug ? min(batchSize, 5) : batchSize,
            flushInterval: environment.isDebug ? min(flushInterval, 10) : flushInterval,
            enableDebugLogging: environment.isDebug,
            enableCrashReporting: !environment.isDebug,
            enablePerformanceMonitoring: !environment.isDebug,
            samplingRate: environment.isDebug ? 1.0 : samplingRate,
            endpoint: endpoint
        )
    }
}

extension AnalyticsCapabilityConfiguration: Codable {}

/// Analytics resource management
public actor AnalyticsCapabilityResource: AxiomCapabilityResource {
    private var eventQueue: [AnalyticsEvent] = []
    private var uploadTask: Task<Void, Never>?
    private let configuration: AnalyticsCapabilityConfiguration
    
    public init(configuration: AnalyticsCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let memoryBytes = eventQueue.count * 1000 // Estimate 1KB per event
            let bandwidthBytes = uploadTask != nil ? 10000 : 0 // 10KB/s when uploading
            return ResourceUsage(memory: memoryBytes, bandwidth: bandwidthBytes)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 10_000_000, bandwidth: 100_000) // 10MB, 100KB/s
    
    public var isAvailable: Bool {
        get async {
            let usage = await currentUsage
            return usage.memory < maxUsage.memory && usage.bandwidth < maxUsage.bandwidth
        }
    }
    
    public func isAvailable() async -> Bool {
        let usage = await currentUsage
        return usage.memory < maxUsage.memory && usage.bandwidth < maxUsage.bandwidth
    }
    
    public func allocate() async throws {
        // Initialize analytics storage
        eventQueue.reserveCapacity(configuration.batchSize * 2)
    }
    
    public func release() async {
        uploadTask?.cancel()
        uploadTask = nil
        eventQueue.removeAll()
    }
    
    func addEvent(_ event: AnalyticsEvent) async {
        eventQueue.append(event)
        
        if eventQueue.count >= configuration.batchSize {
            await flushEvents()
        }
    }
    
    func flushEvents() async {
        guard !eventQueue.isEmpty else { return }
        
        let _ = eventQueue // Events to upload (placeholder for actual upload logic)
        eventQueue.removeAll()
        
        uploadTask = Task {
            // Simulate upload
            try? await Task.sleep(for: .seconds(1))
            // In real implementation, send to analytics endpoint
        }
        
        await uploadTask?.value
        uploadTask = nil
    }
}

/// Analytics capability implementation
public actor AnalyticsCapability: DomainCapability {
    private var _configuration: AnalyticsCapabilityConfiguration
    private var _resources: AnalyticsCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var flushTimer: Task<Void, Never>?
    
    public init(
        configuration: AnalyticsCapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment(isDebug: true)
    ) {
        self._configuration = configuration
        self._resources = AnalyticsCapabilityResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: AnalyticsCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: AnalyticsCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AnalyticsCapabilityConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = AnalyticsCapabilityResource(configuration: _configuration)
        await startFlushTimer()
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        true // Analytics always supported
    }
    
    public func requestPermission() async throws {
        // Analytics may require tracking permission in some regions
        if #available(iOS 14, *) {
            // In real implementation, request ATTrackingManager permission
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func activate() async throws {
        try await _resources.allocate()
        await startFlushTimer()
        _state = .available
    }
    
    public func deactivate() async {
        await _resources.flushEvents() // Flush remaining events
        await _resources.release()
        flushTimer?.cancel()
        flushTimer = nil
        _state = .unavailable
    }
    
    // MARK: - Analytics-Specific Methods
    
    public func track(event: String, properties: [String: Any] = [:]) async {
        guard _state == .available else { return }
        
        // Apply sampling
        guard Double.random(in: 0...1) <= _configuration.samplingRate else { return }
        
        let analyticsEvent = AnalyticsEvent(
            name: event,
            properties: properties,
            timestamp: Date(),
            sessionId: await getCurrentSessionId()
        )
        
        await _resources.addEvent(analyticsEvent)
        
        if _configuration.enableDebugLogging {
            print("[Analytics] \(event): \(properties)")
        }
    }
    
    public func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) async {
        var screenProperties = properties
        screenProperties["screen_name"] = screenName
        await track(event: "screen_view", properties: screenProperties)
    }
    
    public func trackUserAction(_ action: String, target: String?, properties: [String: Any] = [:]) async {
        var actionProperties = properties
        actionProperties["action"] = action
        if let target = target {
            actionProperties["target"] = target
        }
        await track(event: "user_action", properties: actionProperties)
    }
    
    public func flush() async {
        await _resources.flushEvents()
    }
    
    private func startFlushTimer() async {
        flushTimer?.cancel()
        flushTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?._configuration.flushInterval ?? 30))
                await self?._resources.flushEvents()
            }
        }
    }
    
    private func getCurrentSessionId() async -> String {
        // In real implementation, maintain session management
        "session-\(UUID().uuidString)"
    }
}

/// Analytics event structure
public struct AnalyticsEvent: Codable, Sendable {
    public let name: String
    public let properties: [String: AnyCodable]
    public let timestamp: Date
    public let sessionId: String
    
    public init(name: String, properties: [String: Any], timestamp: Date, sessionId: String) {
        self.name = name
        self.properties = properties.compactMapValues { value in
            // Try to convert common Sendable types
            if let stringValue = value as? String {
                return AnyCodable(stringValue)
            } else if let intValue = value as? Int {
                return AnyCodable(intValue)
            } else if let doubleValue = value as? Double {
                return AnyCodable(doubleValue)
            } else if let boolValue = value as? Bool {
                return AnyCodable(boolValue)
            }
            return nil
        }
        self.timestamp = timestamp
        self.sessionId = sessionId
    }
}

/// Helper for encoding Any values
public struct AnyCodable: Codable, Sendable {
    public let value: any Sendable
    
    public init(_ value: any Sendable) {
        self.value = value
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = ""
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encode("")
        }
    }
}