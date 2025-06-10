import Foundation
import SwiftUI
import Combine

// MARK: - Capability Composition Patterns

/// Protocol for capabilities that can be composed together
public protocol ComposableCapability: DomainCapability {
    associatedtype DependencyType: CapabilityDependency
    
    /// Dependencies required by this capability
    var dependencies: [DependencyType] { get async }
    
    /// Check if all dependencies are satisfied
    func validateDependencies() async throws
    
    /// Handle dependency state changes
    func handleDependencyChange(_ dependency: DependencyType, newState: CapabilityState) async
}

/// Capability dependency specification
public protocol CapabilityDependency: Sendable {
    /// Unique identifier for the dependency
    var id: String { get }
    
    /// Type of dependency
    var type: CapabilityDependencyType { get }
    
    /// Whether this dependency is required
    var isRequired: Bool { get }
    
    /// Minimum version required (if applicable)
    var minimumVersion: String? { get }
}

/// Types of capability dependencies
public enum CapabilityDependencyType: String, Codable, CaseIterable {
    case required       // Must be available before this capability can initialize
    case optional       // Enhances functionality but not required
    case exclusive      // Cannot coexist with this capability
    case composable     // Can be combined to create enhanced functionality
}

/// Basic capability dependency implementation
public struct BasicCapabilityDependency: CapabilityDependency {
    public let id: String
    public let type: CapabilityDependencyType
    public let isRequired: Bool
    public let minimumVersion: String?
    
    public init(id: String, type: CapabilityDependencyType, isRequired: Bool = true, minimumVersion: String? = nil) {
        self.id = id
        self.type = type
        self.isRequired = isRequired
        self.minimumVersion = minimumVersion
    }
}

// MARK: - Capability Hierarchy and Inheritance

/// Base class for capability hierarchies
public protocol CapabilityHierarchy {
    associatedtype ParentCapability: DomainCapability
    associatedtype ChildCapability: DomainCapability
    
    /// Parent capability in the hierarchy
    var parent: ParentCapability? { get async }
    
    /// Child capabilities in the hierarchy
    var children: [ChildCapability] { get async }
    
    /// Add a child capability
    func addChild(_ child: ChildCapability) async throws
    
    /// Remove a child capability
    func removeChild(_ child: ChildCapability) async
    
    /// Propagate state changes to children
    func propagateStateChange(_ state: CapabilityState) async
}

/// Hierarchical capability implementation
public actor HierarchicalCapability<Parent: DomainCapability, Child: DomainCapability>: CapabilityHierarchy {
    private weak var _parent: Parent?
    private var _children: [Child] = []
    private let hierarchyRules: HierarchyRules
    
    public init(hierarchyRules: HierarchyRules = HierarchyRules()) {
        self.hierarchyRules = hierarchyRules
    }
    
    public var parent: Parent? {
        get async { _parent }
    }
    
    public var children: [Child] {
        get async { _children }
    }
    
    public func addChild(_ child: Child) async throws {
        // Validate hierarchy rules
        guard _children.count < hierarchyRules.maxChildren else {
            throw CapabilityError.initializationFailed("Maximum children exceeded")
        }
        
        // Check for conflicts
        for existingChild in _children {
            if await areConflicting(child, existingChild) {
                throw CapabilityError.initializationFailed("Conflicting capabilities")
            }
        }
        
        _children.append(child)
        
        // Initialize child if parent is available
        if let parentState = await _parent?.state, parentState == .available {
            try await child.initialize()
        }
    }
    
    public func removeChild(_ child: Child) async {
        // Find index using async comparison
        var foundIndex: Int? = nil
        for (index, existingChild) in _children.enumerated() {
            if await areSameCapability(existingChild, child) {
                foundIndex = index
                break
            }
        }
        
        if let index = foundIndex {
            let removedChild = _children.remove(at: index)
            await removedChild.terminate()
        }
    }
    
    public func propagateStateChange(_ state: CapabilityState) async {
        for child in _children {
            switch state {
            case .available:
                try? await child.initialize()
            case .unavailable, .restricted:
                await child.terminate()
            case .unknown:
                break
            }
        }
    }
    
    private func areConflicting(_ capability1: Child, _ capability2: Child) async -> Bool {
        // Check if capabilities have exclusive dependencies
        // In a real implementation, this would check capability-specific rules
        return false
    }
    
    private func areSameCapability(_ capability1: Child, _ capability2: Child) async -> Bool {
        // In a real implementation, this would compare capability identifiers
        return ObjectIdentifier(capability1) == ObjectIdentifier(capability2)
    }
}

/// Rules for capability hierarchies
public struct HierarchyRules {
    public let maxChildren: Int
    public let allowDynamicAddition: Bool
    public let requireParentInitialization: Bool
    
    public init(maxChildren: Int = 10, allowDynamicAddition: Bool = true, requireParentInitialization: Bool = true) {
        self.maxChildren = maxChildren
        self.allowDynamicAddition = allowDynamicAddition
        self.requireParentInitialization = requireParentInitialization
    }
}

// MARK: - Capability Aggregation and Orchestration

/// Aggregated capability that combines multiple capabilities
public actor AggregatedCapability: DomainCapability {
    public typealias ConfigurationType = AggregatedConfiguration
    public typealias ResourceType = AggregatedResource
    
    private var capabilities: [String: any DomainCapability] = [:]
    private var _configuration: AggregatedConfiguration
    private var _resources: AggregatedResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var orchestrationStrategy: OrchestrationStrategy
    
    public init(
        configuration: AggregatedConfiguration,
        environment: CapabilityEnvironment = .development,
        orchestrationStrategy: OrchestrationStrategy = .sequential
    ) {
        self._configuration = configuration
        self._resources = AggregatedResource(configuration: configuration)
        self._environment = environment
        self.orchestrationStrategy = orchestrationStrategy
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: AggregatedConfiguration {
        get async { _configuration }
    }
    
    public var resources: AggregatedResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AggregatedConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = AggregatedResource(configuration: _configuration)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
        
        // Propagate environment change to all capabilities
        for (_, capability) in capabilities {
            await capability.handleEnvironmentChange(environment)
        }
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                continuation.yield(_state)
                continuation.finish()
            }
        }
    }
    
    public func isSupported() async -> Bool {
        // Check if all required capabilities are supported
        for (_, capability) in capabilities {
            guard await capability.isSupported() else { return false }
        }
        return true
    }
    
    public func requestPermission() async throws {
        // Request permissions for all capabilities
        for (_, capability) in capabilities {
            try await capability.requestPermission()
        }
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func initialize() async throws {
        guard await isSupported() else {
            _state = .unavailable
            throw CapabilityError.notAvailable("One or more capabilities not supported")
        }
        
        try await _resources.allocate()
        
        // Initialize capabilities based on orchestration strategy
        switch orchestrationStrategy {
        case .sequential:
            try await initializeSequentially()
        case .parallel:
            try await initializeInParallel()
        case .conditional:
            try await initializeConditionally()
        }
        
        _state = .available
    }
    
    public func terminate() async {
        // Terminate all capabilities
        for (_, capability) in capabilities {
            await capability.terminate()
        }
        
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Aggregation Methods
    
    public func addCapability<T: DomainCapability>(_ capability: T, withId id: String) async throws {
        guard !capabilities.keys.contains(id) else {
            throw CapabilityError.initializationFailed("Capability with id '\(id)' already exists")
        }
        
        capabilities[id] = capability
        
        // Initialize if aggregated capability is already available
        if _state == .available {
            try await capability.initialize()
        }
    }
    
    public func removeCapability(withId id: String) async {
        if let capability = capabilities.removeValue(forKey: id) {
            await capability.terminate()
        }
    }
    
    public func getCapability<T: DomainCapability>(withId id: String, as type: T.Type) async -> T? {
        capabilities[id] as? T
    }
    
    private func initializeSequentially() async throws {
        for (id, capability) in capabilities {
            do {
                try await capability.initialize()
            } catch {
                // If a capability fails, terminate all previously initialized ones
                for (previousId, previousCapability) in capabilities {
                    if previousId == id { break }
                    await previousCapability.terminate()
                }
                throw error
            }
        }
    }
    
    private func initializeInParallel() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (_, capability) in capabilities {
                group.addTask {
                    try await capability.initialize()
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    private func initializeConditionally() async throws {
        // Initialize capabilities based on dependencies and conditions
        var initialized: Set<String> = []
        var remaining = Set(capabilities.keys)
        
        while !remaining.isEmpty {
            let previousCount = remaining.count
            
            for id in remaining {
                if let capability = capabilities[id] as? any ComposableCapability {
                    let dependencies = await capability.dependencies
                    let requiredDependencies = dependencies.filter { $0.isRequired }
                    let dependencyIds = Set(requiredDependencies.map { $0.id })
                    
                    // Check if all required dependencies are initialized
                    if dependencyIds.isSubset(of: initialized) {
                        try await capability.initialize()
                        initialized.insert(id)
                        remaining.remove(id)
                    }
                } else {
                    // No dependencies, initialize immediately
                    try await capabilities[id]?.initialize()
                    initialized.insert(id)
                    remaining.remove(id)
                }
            }
            
            // If no progress was made, we have circular dependencies
            if remaining.count == previousCount {
                throw CapabilityError.initializationFailed("Circular dependencies detected")
            }
        }
    }
}

/// Orchestration strategies for aggregated capabilities
public enum OrchestrationStrategy {
    case sequential    // Initialize one by one
    case parallel      // Initialize all at once
    case conditional   // Initialize based on dependencies
}

/// Configuration for aggregated capabilities
public struct AggregatedConfiguration: CapabilityConfiguration {
    // Note: For MVP, removing type-erased dictionary that can't be Codable
    // In production, would use concrete types or custom Codable implementation
    public let orchestrationTimeout: TimeInterval
    public let failureStrategy: FailureStrategy
    
    public init(
        orchestrationTimeout: TimeInterval = 30,
        failureStrategy: FailureStrategy = .failFast
    ) {
        self.orchestrationTimeout = orchestrationTimeout
        self.failureStrategy = failureStrategy
    }
    
    public var isValid: Bool {
        orchestrationTimeout > 0
    }
    
    public func merged(with other: AggregatedConfiguration) -> AggregatedConfiguration {
        return AggregatedConfiguration(
            orchestrationTimeout: other.orchestrationTimeout > 0 ? other.orchestrationTimeout : orchestrationTimeout,
            failureStrategy: other.failureStrategy
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> AggregatedConfiguration {
        return AggregatedConfiguration(
            orchestrationTimeout: environment.isDebug ? min(orchestrationTimeout, 10) : orchestrationTimeout,
            failureStrategy: failureStrategy
        )
    }
}

/// Failure strategies for aggregated capabilities
public enum FailureStrategy: String, Codable {
    case failFast      // Stop on first failure
    case continueOnError // Continue with available capabilities
    case retryFailed   // Retry failed capabilities
}

/// Resource management for aggregated capabilities
public actor AggregatedResource: CapabilityResource {
    private let configuration: AggregatedConfiguration
    private var allocatedResources: [String: any CapabilityResource] = [:]
    
    public init(configuration: AggregatedConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            var totalMemory: Int64 = 0
            var totalCPU: Double = 0
            var totalNetwork: Int64 = 0
            var totalDisk: Int64 = 0
            
            for (_, resource) in allocatedResources {
                let usage = await resource.currentUsage
                totalMemory += usage.memoryBytes
                totalCPU += usage.cpuPercentage
                totalNetwork += usage.networkBytesPerSecond
                totalDisk += usage.diskBytes
            }
            
            return ResourceUsage(memory: totalMemory, cpu: totalCPU, network: totalNetwork, disk: totalDisk)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 1_000_000_000, cpu: 90.0, network: 10_000_000, disk: 5_000_000_000)
    
    public var isAvailable: Bool {
        get async {
            let usage = await currentUsage
            return !usage.exceeds(maxUsage)
        }
    }
    
    public func allocate() async throws {
        guard await isAvailable else {
            throw CapabilityError.resourceAllocationFailed("Insufficient resources for aggregated capability")
        }
    }
    
    public func release() async {
        for (_, resource) in allocatedResources {
            await resource.release()
        }
        allocatedResources.removeAll()
    }
    
    func addResource(_ resource: any CapabilityResource, withId id: String) async {
        allocatedResources[id] = resource
    }
    
    func removeResource(withId id: String) async {
        if let resource = allocatedResources.removeValue(forKey: id) {
            await resource.release()
        }
    }
}

// MARK: - Configuration and Environment Patterns

/// Environment-aware capability that adapts to different configurations
public actor AdaptiveCapability<BaseCapability: DomainCapability>: DomainCapability {
    public typealias ConfigurationType = AdaptiveConfiguration<BaseCapability.ConfigurationType>
    public typealias ResourceType = BaseCapability.ResourceType
    
    private var baseCapability: BaseCapability
    private var _configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>
    private var _environment: CapabilityEnvironment
    private var configurationUpdater: Task<Void, Never>?
    
    public init(
        baseCapability: BaseCapability,
        configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>,
        environment: CapabilityEnvironment = .development
    ) {
        self.baseCapability = baseCapability
        self._configuration = configuration
        self._environment = environment
    }
    
    // MARK: - DomainCapability Protocol
    
    public var configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType> {
        get async { _configuration }
    }
    
    public var resources: BaseCapability.ResourceType {
        get async { await baseCapability.resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>) async throws {
        _configuration = configuration.adjusted(for: _environment)
        
        let baseConfig = await resolveConfiguration(for: _environment)
        try await baseCapability.updateConfiguration(baseConfig)
        
        await startConfigurationUpdater()
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        
        let baseConfig = await resolveConfiguration(for: environment)
        try? await baseCapability.updateConfiguration(baseConfig)
        await baseCapability.handleEnvironmentChange(environment)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { await baseCapability.state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async { await baseCapability.stateStream }
    }
    
    public func isSupported() async -> Bool {
        await baseCapability.isSupported()
    }
    
    public func requestPermission() async throws {
        try await baseCapability.requestPermission()
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { await baseCapability.isAvailable }
    }
    
    public func initialize() async throws {
        let baseConfig = await resolveConfiguration(for: _environment)
        try await baseCapability.updateConfiguration(baseConfig)
        try await baseCapability.initialize()
        
        await startConfigurationUpdater()
    }
    
    public func terminate() async {
        configurationUpdater?.cancel()
        configurationUpdater = nil
        await baseCapability.terminate()
    }
    
    // MARK: - Adaptive Methods
    
    private func resolveConfiguration(for environment: CapabilityEnvironment) async -> BaseCapability.ConfigurationType {
        let configurations = _configuration.environmentConfigurations
        
        if let envConfig = configurations[environment] {
            return envConfig
        }
        
        // Fallback to default configuration
        return _configuration.defaultConfiguration.adjusted(for: environment)
    }
    
    private func startConfigurationUpdater() async {
        configurationUpdater?.cancel()
        
        guard _configuration.enableRuntimeUpdates else { return }
        
        configurationUpdater = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?._configuration.updateInterval ?? 60))
                
                guard let self = self else { break }
                
                // Check for configuration updates
                if await self.shouldUpdateConfiguration() {
                    let newConfig = await self.resolveConfiguration(for: self._environment)
                    try? await self.baseCapability.updateConfiguration(newConfig)
                }
            }
        }
    }
    
    private func shouldUpdateConfiguration() async -> Bool {
        // Check for feature flags, A/B test changes, etc.
        // In real implementation, this would check external configuration sources
        return false
    }
}

/// Adaptive configuration with environment-specific settings
public struct AdaptiveConfiguration<BaseConfig: CapabilityConfiguration>: CapabilityConfiguration {
    public let defaultConfiguration: BaseConfig
    public let environmentConfigurations: [CapabilityEnvironment: BaseConfig]
    public let enableRuntimeUpdates: Bool
    public let updateInterval: TimeInterval
    public let featureFlags: [String: Bool]
    public let abTestVariant: String?
    
    public init(
        defaultConfiguration: BaseConfig,
        environmentConfigurations: [CapabilityEnvironment: BaseConfig] = [:],
        enableRuntimeUpdates: Bool = false,
        updateInterval: TimeInterval = 60,
        featureFlags: [String: Bool] = [:],
        abTestVariant: String? = nil
    ) {
        self.defaultConfiguration = defaultConfiguration
        self.environmentConfigurations = environmentConfigurations
        self.enableRuntimeUpdates = enableRuntimeUpdates
        self.updateInterval = updateInterval
        self.featureFlags = featureFlags
        self.abTestVariant = abTestVariant
    }
    
    public var isValid: Bool {
        defaultConfiguration.isValid && updateInterval > 0
    }
    
    public func merged(with other: AdaptiveConfiguration<BaseConfig>) -> AdaptiveConfiguration<BaseConfig> {
        var mergedEnvironmentConfigs = environmentConfigurations
        for (env, config) in other.environmentConfigurations {
            mergedEnvironmentConfigs[env] = config
        }
        
        var mergedFeatureFlags = featureFlags
        for (flag, value) in other.featureFlags {
            mergedFeatureFlags[flag] = value
        }
        
        return AdaptiveConfiguration(
            defaultConfiguration: other.defaultConfiguration,
            environmentConfigurations: mergedEnvironmentConfigs,
            enableRuntimeUpdates: other.enableRuntimeUpdates,
            updateInterval: other.updateInterval > 0 ? other.updateInterval : updateInterval,
            featureFlags: mergedFeatureFlags,
            abTestVariant: other.abTestVariant ?? abTestVariant
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> AdaptiveConfiguration<BaseConfig> {
        let adjustedDefault = defaultConfiguration.adjusted(for: environment)
        let adjustedEnvironmentConfigs = environmentConfigurations.mapValues { config in
            config.adjusted(for: environment)
        }
        
        return AdaptiveConfiguration(
            defaultConfiguration: adjustedDefault,
            environmentConfigurations: adjustedEnvironmentConfigs,
            enableRuntimeUpdates: enableRuntimeUpdates && !environment.isDebug,
            updateInterval: environment.isDebug ? min(updateInterval, 10) : updateInterval,
            featureFlags: featureFlags,
            abTestVariant: abTestVariant
        )
    }
    
    public func isFeatureEnabled(_ flag: String) -> Bool {
        featureFlags[flag] ?? false
    }
}

// MARK: - Resource Management Patterns

/// Resource pool for managing shared resources across capabilities
public actor CapabilityResourcePool {
    private var resources: [String: any CapabilityResource] = [:]
    private var allocations: [String: Set<String>] = [:] // resource_id -> capability_ids
    private var reservations: [String: ResourceReservation] = [:]
    private let maxTotalUsage: ResourceUsage
    
    public init(maxTotalUsage: ResourceUsage) {
        self.maxTotalUsage = maxTotalUsage
    }
    
    /// Register a shareable resource
    public func registerResource<T: CapabilityResource>(_ resource: T, withId id: String) async {
        resources[id] = resource
        allocations[id] = Set()
    }
    
    /// Request resource allocation for a capability
    public func requestResource(resourceId: String, capabilityId: String, priority: ResourcePriority = .normal) async throws {
        guard let resource = resources[resourceId] else {
            throw CapabilityError.resourceAllocationFailed("Resource not found: \(resourceId)")
        }
        
        // Check if resource is available
        guard await resource.isAvailable else {
            throw CapabilityError.resourceAllocationFailed("Resource not available: \(resourceId)")
        }
        
        // Check total usage limits
        let currentUsage = await getTotalUsage()
        let resourceUsage = await resource.currentUsage
        let projectedUsage = ResourceUsage(
            memory: currentUsage.memoryBytes + resourceUsage.memoryBytes,
            cpu: currentUsage.cpuPercentage + resourceUsage.cpuPercentage,
            network: currentUsage.networkBytesPerSecond + resourceUsage.networkBytesPerSecond,
            disk: currentUsage.diskBytes + resourceUsage.diskBytes
        )
        
        guard !projectedUsage.exceeds(maxTotalUsage) else {
            throw CapabilityError.resourceAllocationFailed("Resource allocation would exceed limits")
        }
        
        // Allocate resource
        try await resource.allocate()
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
                totalMemory += usage.memoryBytes
                totalCPU += usage.cpuPercentage
                totalNetwork += usage.networkBytesPerSecond
                totalDisk += usage.diskBytes
            }
        }
        
        return ResourceUsage(memory: totalMemory, cpu: totalCPU, network: totalNetwork, disk: totalDisk)
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
public actor CallbackBridge<ResultType> {
    private var continuations: [String: CheckedContinuation<ResultType, Error>] = [:]
    
    /// Start an async operation with a callback
    public func performAsync<T>(
        operation: (@escaping (Result<T, Error>) -> Void) -> Void
    ) async throws -> T where T == ResultType {
        let id = UUID().uuidString
        
        return try await withCheckedThrowingContinuation { continuation in
            continuations[id] = continuation as? CheckedContinuation<ResultType, Error>
            
            operation { result in
                Task {
                    await self.complete(id: id, result: result as! Result<ResultType, Error>)
                }
            }
        }
    }
    
    private func complete(id: String, result: Result<ResultType, Error>) {
        guard let continuation = continuations.removeValue(forKey: id) else { return }
        
        switch result {
        case .success(let value):
            continuation.resume(returning: value)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

/// Example usage of capability patterns with a complete implementation
public actor ExampleCompositeCapability: DomainCapability {
    public typealias ConfigurationType = ExampleCompositeConfiguration
    public typealias ResourceType = ExampleCompositeResource
    
    private var _configuration: ExampleCompositeConfiguration
    private var _resources: ExampleCompositeResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    
    // Composed capabilities
    private var analyticsCapability: AnalyticsCapability?
    private var mlCapability: MLCapability?
    
    public init(
        configuration: ExampleCompositeConfiguration,
        environment: CapabilityEnvironment = .development
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
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: ExampleCompositeConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = ExampleCompositeResource(configuration: _configuration)
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
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
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public func initialize() async throws {
        // Initialize composed capabilities
        if _configuration.enableAnalytics {
            analyticsCapability = AnalyticsCapability(
                configuration: _configuration.analyticsConfig,
                environment: _environment
            )
            try await analyticsCapability?.initialize()
        }
        
        if _configuration.enableML {
            mlCapability = MLCapability(
                configuration: _configuration.mlConfig,
                environment: _environment
            )
            try await mlCapability?.initialize()
        }
        
        
        try await _resources.allocate()
        _state = .available
    }
    
    public func terminate() async {
        await analyticsCapability?.terminate()
        await mlCapability?.terminate()
        
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Composite Methods
    
    public func processWithAnalytics<T>(
        data: T,
        operation: String
    ) async throws where T: Codable {
        // Track operation start
        await analyticsCapability?.track(event: "operation_started", properties: [
            "operation": operation,
            "data_type": String(describing: T.self)
        ])
        
        // Perform processing (example)
        try await Task.sleep(for: .milliseconds(100))
        
        // Track completion
        await analyticsCapability?.track(event: "operation_completed", properties: [
            "operation": operation,
            "success": true
        ])
    }
}

/// Configuration for example composite capability
public struct ExampleCompositeConfiguration: CapabilityConfiguration {
    public let enableAnalytics: Bool
    public let enableML: Bool
    public let analyticsConfig: AnalyticsCapabilityConfiguration
    public let mlConfig: MLCapabilityConfiguration
    
    public init(
        enableAnalytics: Bool = true,
        enableML: Bool = false,
        analyticsConfig: AnalyticsCapabilityConfiguration,
        mlConfig: MLCapabilityConfiguration
    ) {
        self.enableAnalytics = enableAnalytics
        self.enableML = enableML
        self.analyticsConfig = analyticsConfig
        self.mlConfig = mlConfig
    }
    
    public var isValid: Bool {
        analyticsConfig.isValid && mlConfig.isValid
    }
    
    public func merged(with other: ExampleCompositeConfiguration) -> ExampleCompositeConfiguration {
        ExampleCompositeConfiguration(
            enableAnalytics: other.enableAnalytics,
            enableML: other.enableML,
            analyticsConfig: analyticsConfig.merged(with: other.analyticsConfig),
            mlConfig: mlConfig.merged(with: other.mlConfig)
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> ExampleCompositeConfiguration {
        ExampleCompositeConfiguration(
            enableAnalytics: enableAnalytics,
            enableML: enableML && !environment.isDebug, // Disable ML in debug for performance
            analyticsConfig: analyticsConfig.adjusted(for: environment),
            mlConfig: mlConfig.adjusted(for: environment)
        )
    }
}

/// Resource management for example composite capability
public actor ExampleCompositeResource: CapabilityResource {
    private let configuration: ExampleCompositeConfiguration
    
    public init(configuration: ExampleCompositeConfiguration) {
        self.configuration = configuration
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            // Aggregate usage from enabled capabilities
            var memory: Int64 = 1_000_000 // Base 1MB
            if configuration.enableAnalytics { memory += 5_000_000 }
            if configuration.enableML { memory += 100_000_000 }
            
            return ResourceUsage(memory: memory, cpu: 10.0)
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 200_000_000, cpu: 60.0)
    
    public var isAvailable: Bool {
        get async {
            let usage = await currentUsage
            return !usage.exceeds(maxUsage)
        }
    }
    
    public func allocate() async throws {
        guard await isAvailable else {
            throw CapabilityError.resourceAllocationFailed("Insufficient resources for composite capability")
        }
    }
    
    public func release() async {
        // Release resources
    }
}