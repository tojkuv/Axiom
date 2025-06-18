import SwiftUI
import Combine
import NetworkClient
import HotReloadProtocol

public protocol MetadataStreamerDelegate: AnyObject {
    func streamer(_ streamer: MetadataStreamer, didStreamMetadata metadata: AppMetadata)
    func streamer(_ streamer: MetadataStreamer, didEncounterError error: Error)
}

@MainActor
public final class MetadataStreamer: ObservableObject {
    
    public weak var delegate: MetadataStreamerDelegate?
    
    @Published public private(set) var isStreaming = false
    @Published public private(set) var streamingStatistics = StreamingStatistics()
    
    private let configuration: MetadataStreamingConfiguration
    private var cancellables = Set<AnyCancellable>()
    private var streamingTimer: Timer?
    private var connectionManager: ConnectionManager?
    
    // Metadata collection components
    private var contextCollector: ContextMetadataCollector
    private var presentationCollector: PresentationMetadataCollector
    private var clientMetricsCollector: ClientMetricsCollector
    private var performanceCollector: PerformanceMetadataCollector
    
    public init(configuration: MetadataStreamingConfiguration = MetadataStreamingConfiguration()) {
        self.configuration = configuration
        self.contextCollector = ContextMetadataCollector()
        self.presentationCollector = PresentationMetadataCollector()
        self.clientMetricsCollector = ClientMetricsCollector()
        self.performanceCollector = PerformanceMetadataCollector()
    }
    
    public func startStreaming(connectionManager: ConnectionManager) {
        guard !isStreaming else { return }
        
        self.connectionManager = connectionManager
        isStreaming = true
        
        setupPeriodicStreaming()
        setupRealtimeStreaming()
        
        streamingStatistics.startTime = Date()
        streamingStatistics.totalStreamsSent = 0
    }
    
    public func stopStreaming() {
        guard isStreaming else { return }
        
        streamingTimer?.invalidate()
        streamingTimer = nil
        cancellables.removeAll()
        
        isStreaming = false
        streamingStatistics.endTime = Date()
    }
    
    public func streamAppMetadata() -> AsyncStream<AppMetadata> {
        return AsyncStream { continuation in
            let timer = Timer.scheduledTimer(withTimeInterval: configuration.streamingInterval, repeats: true) { _ in
                Task { @MainActor in
                    let metadata = await self.collectCurrentMetadata()
                    continuation.yield(metadata)
                }
            }
            
            continuation.onTermination = { _ in
                timer.invalidate()
            }
        }
    }
    
    public func captureStateTransition() async -> StateTransitionData {
        let beforeState = await contextCollector.captureCurrentState()
        
        // Wait a brief moment to capture transition
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let afterState = await contextCollector.captureCurrentState()
        
        return StateTransitionData(
            transitionId: UUID().uuidString,
            timestamp: Date(),
            beforeState: beforeState,
            afterState: afterState,
            changedKeys: calculateChangedKeys(before: beforeState, after: afterState),
            transitionDuration: 0.1
        )
    }
    
    public func collectCurrentMetadata() async -> AppMetadata {
        let contextHierarchy = await contextCollector.collectContextHierarchy()
        let presentationBindings = await presentationCollector.collectPresentationBindings()
        let clientMetrics = await clientMetricsCollector.collectClientMetrics()
        let performanceSnapshot = await performanceCollector.collectPerformanceSnapshot()
        let memoryUsage = await performanceCollector.collectMemoryUsage()
        let networkActivity = await performanceCollector.collectNetworkActivity()
        
        let metadata = AppMetadata(
            timestamp: Date(),
            contextHierarchy: contextHierarchy,
            presentationBindings: presentationBindings,
            clientMetrics: clientMetrics,
            performanceSnapshot: performanceSnapshot,
            memoryUsage: memoryUsage,
            networkActivity: networkActivity
        )
        
        delegate?.streamer(self, didStreamMetadata: metadata)
        streamingStatistics.totalStreamsSent += 1
        
        return metadata
    }
    
    private func setupPeriodicStreaming() {
        streamingTimer = Timer.scheduledTimer(withTimeInterval: configuration.streamingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendMetadataToServer()
            }
        }
    }
    
    private func setupRealtimeStreaming() {
        // Setup observers for real-time state changes
        NotificationCenter.default.publisher(for: .stateDidChange)
            .throttle(for: .milliseconds(configuration.throttleInterval), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.sendMetadataToServer()
                }
            }
            .store(in: &cancellables)
    }
    
    private func sendMetadataToServer() async {
        guard let connectionManager = connectionManager, connectionManager.isConnected else { return }
        
        do {
            let metadata = await collectCurrentMetadata()
            let message = createMetadataMessage(metadata)
            
            try await connectionManager.sendMessage(message)
            
        } catch {
            delegate?.streamer(self, didEncounterError: error)
        }
    }
    
    private func createMetadataMessage(_ metadata: AppMetadata) -> BaseMessage {
        let payload = HotReloadProtocol.MetadataPayload(
            timestamp: metadata.timestamp,
            contextHierarchy: metadata.contextHierarchy.map { context in
                HotReloadProtocol.MetadataContextInfo(
                    id: context.id,
                    name: context.name,
                    parentId: context.parentId,
                    properties: context.properties,
                    performanceMetrics: HotReloadProtocol.MetadataPerformanceMetrics(
                        updateCount: context.performanceMetrics.updateCount,
                        averageUpdateTime: context.performanceMetrics.averageUpdateTime
                    )
                )
            },
            presentationBindings: metadata.presentationBindings.map { binding in
                HotReloadProtocol.MetadataPresentationBinding(
                    contextId: binding.contextId,
                    presentationId: binding.presentationId,
                    bindingType: binding.bindingType,
                    isValid: binding.isValid
                )
            },
            clientMetrics: metadata.clientMetrics.map { metric in
                HotReloadProtocol.MetadataClientMetric(
                    name: metric.name,
                    value: metric.value,
                    unit: metric.unit,
                    timestamp: metric.timestamp
                )
            }
        )
        
        return BaseMessage(
            type: .metadata,
            platform: .ios,
            payload: .metadata(payload)
        )
    }
    
    private func calculateChangedKeys(before: [String: Any], after: [String: Any]) -> [String] {
        var changedKeys: [String] = []
        
        let allKeys = Set(before.keys).union(Set(after.keys))
        
        for key in allKeys {
            let beforeValue = before[key]
            let afterValue = after[key]
            
            // Simple comparison - in real implementation would need more sophisticated comparison
            if !isEqual(beforeValue, afterValue) {
                changedKeys.append(key)
            }
        }
        
        return changedKeys
    }
    
    private func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        // Simplified equality check - would need more sophisticated implementation
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let l as String, let r as String):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as Bool, let r as Bool):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

public struct MetadataStreamingConfiguration {
    public var streamingInterval: TimeInterval = 5.0
    public var throttleInterval: Int = 1000 // milliseconds
    public var enableRealtimeStreaming: Bool = true
    public var enablePeriodicStreaming: Bool = true
    public var bufferSize: Int = 100
    
    public init() {}
}

public struct StreamingStatistics {
    public var startTime: Date?
    public var endTime: Date?
    public var totalStreamsSent: Int = 0
    public var averageStreamSize: Int = 0
    public var lastStreamTime: Date?
    
    public var duration: TimeInterval {
        guard let startTime = startTime else { return 0 }
        let endTime = self.endTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    public var streamsPerSecond: Double {
        guard duration > 0 else { return 0 }
        return Double(totalStreamsSent) / duration
    }
}

public struct StateTransitionData: Codable {
    public let transitionId: String
    public let timestamp: Date
    public let beforeState: [String: Any]
    public let afterState: [String: Any]
    public let changedKeys: [String]
    public let transitionDuration: TimeInterval
    
    public init(transitionId: String, timestamp: Date, beforeState: [String: Any], afterState: [String: Any], changedKeys: [String], transitionDuration: TimeInterval) {
        self.transitionId = transitionId
        self.timestamp = timestamp
        self.beforeState = beforeState
        self.afterState = afterState
        self.changedKeys = changedKeys
        self.transitionDuration = transitionDuration
    }
    
    // Custom Codable implementation needed for [String: Any]
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transitionId, forKey: .transitionId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(changedKeys, forKey: .changedKeys)
        try container.encode(transitionDuration, forKey: .transitionDuration)
        // Note: beforeState and afterState would need custom encoding for [String: Any]
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transitionId = try container.decode(String.self, forKey: .transitionId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        changedKeys = try container.decode([String].self, forKey: .changedKeys)
        transitionDuration = try container.decode(TimeInterval.self, forKey: .transitionDuration)
        // Note: beforeState and afterState would need custom decoding
        beforeState = [:]
        afterState = [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        case transitionId, timestamp, changedKeys, transitionDuration
    }
}

// MARK: - Message Types

// Use HotReloadProtocol.MetadataPayload to avoid type conflicts
// All metadata types are now provided by HotReloadProtocol

// MARK: - Notification Extensions

extension Notification.Name {
    static let stateDidChange = Notification.Name("AxiomStateDidChange")
    static let contextDidUpdate = Notification.Name("AxiomContextDidUpdate")
    static let presentationDidBind = Notification.Name("AxiomPresentationDidBind")
}