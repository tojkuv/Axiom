import Foundation
import AxiomCore
import SwiftUI
import Combine

// MARK: - Resource Management Patterns

/// Resource pool for managing shared resources across capabilities
public actor CapabilityResourcePool {
    private var resources: [String: any AxiomCapabilityResource] = [:]
    private var allocations: [String: Set<String>] = [:] // resource_id -> capability_ids
    private var reservations: [String: ResourceReservation] = [:]
    private let maxTotalUsage: ResourceUsage
    
    public init(maxTotalUsage: ResourceUsage) {
        self.maxTotalUsage = maxTotalUsage
    }
    
    /// Register a shareable resource
    public func registerResource<T: AxiomCapabilityResource>(_ resource: T, withId id: String) async {
        resources[id] = resource
        allocations[id] = Set()
    }
    
    /// Request resource allocation for a capability
    public func requestResource(resourceId: String, capabilityId: String, priority: ResourcePriority = .normal) async throws {
        guard let resource = resources[resourceId] else {
            throw AxiomCapabilityError.operationFailed("Resource not found: \(resourceId)")
        }
        
        // Check if resource is available
        guard await resource.isAvailable() else {
            throw AxiomCapabilityError.operationFailed("Resource not available: \(resourceId)")
        }
        
        // Check total usage limits
        let currentUsage = await getTotalUsage()
        let resourceUsage = await resource.currentUsage
        let projectedUsage = ResourceUsage(
            memory: currentUsage.memory + resourceUsage.memory,
            cpu: currentUsage.cpu + resourceUsage.cpu,
            bandwidth: currentUsage.bandwidth + resourceUsage.bandwidth,
            storage: currentUsage.storage + resourceUsage.storage
        )
        
        guard !projectedUsage.exceeds(maxTotalUsage) else {
            throw AxiomCapabilityError.operationFailed("Resource allocation would exceed limits")
        }
        
        // Check resource availability
        guard await resource.isAvailable() else {
            throw AxiomCapabilityError.operationFailed("Resource not available: \(resourceId)")
        }
        allocations[resourceId]?.insert(capabilityId)
    }
    
    /// Release resource allocation for a capability
    public func releaseResource(resourceId: String, capabilityId: String) async {
        guard let resource = resources[resourceId] else { return }
        
        allocations[resourceId]?.remove(capabilityId)
        
        // If no more allocations, release the resource
        if allocations[resourceId]?.isEmpty == true {
            await resource.release()
        }
    }
    
    /// Make a resource reservation for future use
    public func reserveResource(resourceId: String, capabilityId: String, duration: TimeInterval) async throws {
        let reservation = ResourceReservation(
            resourceId: resourceId,
            capabilityId: capabilityId,
            expiresAt: Date().addingTimeInterval(duration)
        )
        
        reservations["\(resourceId)_\(capabilityId)"] = reservation
        
        // Clean up expired reservations
        await cleanupExpiredReservations()
    }
    
    /// Get current total resource usage
    public func getTotalUsage() async -> ResourceUsage {
        var totalMemory: Int64 = 0
        var totalCPU: Double = 0
        var totalNetwork: Int64 = 0
        var totalDisk: Int64 = 0
        
        for (resourceId, capabilityIds) in allocations where !capabilityIds.isEmpty {
            if let resource = resources[resourceId] {
                let usage = await resource.currentUsage
                totalMemory += Int64(usage.memory)
                totalCPU += usage.cpu
                totalNetwork += Int64(usage.bandwidth)
                totalDisk += Int64(usage.storage)
            }
        }
        
        return ResourceUsage(memory: Int(totalMemory), cpu: totalCPU, bandwidth: Int(totalNetwork), storage: Int(totalDisk))
    }
    
    private func cleanupExpiredReservations() async {
        let now = Date()
        let expiredKeys = reservations.compactMap { (key, reservation) in
            reservation.expiresAt < now ? key : nil
        }
        
        for key in expiredKeys {
            reservations.removeValue(forKey: key)
        }
    }
}

/// Resource reservation
public struct ResourceReservation {
    public let resourceId: String
    public let capabilityId: String
    public let expiresAt: Date
}

/// Resource priority levels
public enum ResourcePriority: Int, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}

// MARK: - Integration Patterns

/// Capability adapter for wrapping existing SDKs
public protocol CapabilityAdapter {
    associatedtype SDKType
    associatedtype CapabilityType: DomainCapability
    
    /// The wrapped SDK instance
    var sdk: SDKType { get }
    
    /// The adapted capability
    var capability: CapabilityType { get }
    
    /// Adapt SDK methods to capability interface
    func adaptToCapability() async throws
    
    /// Handle SDK lifecycle events
    func handleSDKLifecycle(_ event: SDKLifecycleEvent) async
}

/// SDK lifecycle events
public enum SDKLifecycleEvent {
    case initialized
    case updated
    case deprecated
    case removed
}

/// Callback bridge for converting callback-based APIs to async/await
public actor CallbackBridge<ResultType: Sendable> {
    private var continuations: [String: CheckedContinuation<ResultType, any Error>] = [:]
    
    /// Start an async operation with a callback
    public func performAsync(
        operation: (@escaping (Result<ResultType, any Error>) -> Void) -> Void
    ) async throws -> ResultType {
        let id = UUID().uuidString
        
        return try await withCheckedThrowingContinuation { continuation in
            continuations[id] = continuation
            
            operation { result in
                Task {
                    self.complete(id: id, result: result)
                }
            }
        }
    }
    
    private func complete(id: String, result: Result<ResultType, any Error>) {
        guard let continuation = continuations.removeValue(forKey: id) else { return }
        
        switch result {
        case .success(let value):
            continuation.resume(returning: value)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - Example Implementation

/// Example usage of capability patterns with a complete implementation
public actor ExampleCompositeCapability: DomainCapability {
    public typealias ConfigurationType = ExampleCompositeConfiguration
    public typealias ResourceType = ExampleCompositeResource
    
    private var _configuration: ExampleCompositeConfiguration
    private var _resources: ExampleCompositeResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    // Note: Capability composition removed for MVP
    
    public init(
        configuration: ExampleCompositeConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment(isDebug: true)
    ) {
        self._configuration = configuration
        self._resources = ExampleCompositeResource(configuration: configuration)
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: ExampleCompositeConfiguration {
        get async { _configuration }
    }
    
    public var resources: ExampleCompositeResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: ExampleCompositeConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = ExampleCompositeResource(configuration: _configuration)
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
        true // Simplified for example
    }
    
    public func requestPermission() async throws {
        // Request permissions for all composed capabilities
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
        // Note: Capability composition removed for MVP
        // Configuration flags are preserved for future implementation
        
        try await _resources.allocate()
        _state = .available
    }
    
    public func deactivate() async {
        // Note: Capability composition removed for MVP
        
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Composite Methods
    
    public func processWithAnalytics<T>(
        data: T,
        operation: String
    ) async throws where T: Codable {
        // Note: Analytics capability removed for MVP - tracking disabled
        
        // Perform processing (example)
        try await Task.sleep(for: .milliseconds(100))
        
        // Analytics tracking would complete here
    }
}

/// Configuration for example composite capability
public struct ExampleCompositeConfiguration: AxiomCapabilityConfiguration {
    public let enableAnalytics: Bool
    public let enableML: Bool
    public let configurationName: String
    
    public init(
        enableAnalytics: Bool = true,
        enableML: Bool = false,
        configurationName: String = "default"
    ) {
        self.enableAnalytics = enableAnalytics
        self.enableML = enableML
        self.configurationName = configurationName
    }
    
    public var isValid: Bool {
        !configurationName.isEmpty
    }
    
    public func merged(with other: ExampleCompositeConfiguration) -> ExampleCompositeConfiguration {
        ExampleCompositeConfiguration(
            enableAnalytics: other.enableAnalytics,
            enableML: other.enableML,
            configurationName: other.configurationName
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ExampleCompositeConfiguration {
        ExampleCompositeConfiguration(
            enableAnalytics: enableAnalytics,
            enableML: enableML && !environment.isDebug, // Disable ML in debug for performance
            configurationName: configurationName
        )
    }
}

/// Resource management for example composite capability
public actor ExampleCompositeResource: AxiomCapabilityResource {
    private let configuration: ExampleCompositeConfiguration
    
    public init(configuration: ExampleCompositeConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            // Aggregate usage from enabled capabilities
            var memory: Int = 1_000_000 // Base 1MB
            if configuration.enableAnalytics { memory += 5_000_000 }
            if configuration.enableML { memory += 100_000_000 }
            
            return ResourceUsage(memory: memory, cpu: 10.0)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 200_000_000, cpu: 60.0)
    
    public func isAvailable() async -> Bool {
        let usage = await currentUsage
        return usage.memory <= maxUsage.memory && usage.cpu <= maxUsage.cpu
    }
    
    public func release() async {
        // Release resources if needed
    }
    
    public func allocate() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.operationFailed("Insufficient resources for composite capability")
        }
    }
}

// MARK: - Resource Management Utilities

/// Utility for managing resource lifecycle across capabilities
public actor ResourceLifecycleManager {
    private var allocatedResources: [String: [any AxiomCapabilityResource]] = [:]
    private var resourceUsageHistory: [String: [ResourceUsage]] = [:]
    private let maxHistorySize = 100
    
    public init() {}
    
    /// Track resource allocation for a capability
    public func trackAllocation(capabilityId: String, resource: any AxiomCapabilityResource) async {
        allocatedResources[capabilityId, default: []].append(resource)
        
        // Record usage snapshot
        let usage = await resource.currentUsage
        resourceUsageHistory[capabilityId, default: []].append(usage)
        
        // Trim history if needed
        if resourceUsageHistory[capabilityId]!.count > maxHistorySize {
            resourceUsageHistory[capabilityId]!.removeFirst()
        }
    }
    
    /// Release all resources for a capability
    public func releaseAllResources(for capabilityId: String) async {
        if let resources = allocatedResources[capabilityId] {
            for resource in resources {
                await resource.release()
            }
            allocatedResources.removeValue(forKey: capabilityId)
        }
    }
    
    /// Get resource usage statistics for a capability
    public func getUsageStatistics(for capabilityId: String) async -> ResourceUsageStatistics? {
        guard let history = resourceUsageHistory[capabilityId], !history.isEmpty else {
            return nil
        }
        
        let totalMemory = history.map { Int64($0.memory) }.reduce(0, +)
        let totalCPU = history.map { $0.cpu }.reduce(0, +)
        let totalNetwork = history.map { Int64($0.bandwidth) }.reduce(0, +)
        let totalDisk = history.map { Int64($0.storage) }.reduce(0, +)
        
        let count = Int64(history.count)
        
        return ResourceUsageStatistics(
            averageMemory: totalMemory / count,
            averageCPU: totalCPU / Double(count),
            averageNetwork: totalNetwork / count,
            averageDisk: totalDisk / count,
            peakMemory: history.map { Int64($0.memory) }.max() ?? 0,
            peakCPU: history.map { $0.cpu }.max() ?? 0.0
        )
    }
}

/// Resource usage statistics
public struct ResourceUsageStatistics {
    public let averageMemory: Int64
    public let averageCPU: Double
    public let averageNetwork: Int64
    public let averageDisk: Int64
    public let peakMemory: Int64
    public let peakCPU: Double
    
    public init(
        averageMemory: Int64,
        averageCPU: Double,
        averageNetwork: Int64,
        averageDisk: Int64,
        peakMemory: Int64,
        peakCPU: Double
    ) {
        self.averageMemory = averageMemory
        self.averageCPU = averageCPU
        self.averageNetwork = averageNetwork
        self.averageDisk = averageDisk
        self.peakMemory = peakMemory
        self.peakCPU = peakCPU
    }
}

// MARK: - Capability Discovery Criteria

/// Criteria for capability discovery
public struct CapabilityCriteria {
    public let namePattern: String?
    public let requiredTags: Set<String>
    public let excludedTags: Set<String>
    public let minimumVersion: String?
    
    public init(
        namePattern: String? = nil,
        requiredTags: Set<String> = [],
        excludedTags: Set<String> = [],
        minimumVersion: String? = nil
    ) {
        self.namePattern = namePattern
        self.requiredTags = requiredTags
        self.excludedTags = excludedTags
        self.minimumVersion = minimumVersion
    }
    
    public func matches<T: DomainCapability>(_ capability: T) async -> Bool {
        // Simplified matching - in real implementation would check metadata
        return true
    }
}