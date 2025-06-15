import Foundation
import SwiftUI
import Combine

// MARK: - Capability Aggregation and Orchestration

/// Aggregated capability that combines multiple capabilities
public actor DefaultAggregatedCapability: AggregatedCapability {
    public typealias ConfigurationType = AggregatedConfiguration
    public typealias ResourceType = AggregatedResource
    
    public var capabilities: [String: any DomainCapability] = [:]
    private var _configuration: AggregatedConfiguration
    private var _resources: AggregatedResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var orchestrationStrategy: OrchestrationStrategy
    private var _activationTimeout: Duration = .milliseconds(10)
    
    public init(
        configuration: AggregatedConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment(isDebug: true),
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
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AggregatedConfiguration) async throws {
        _configuration = configuration.adjusted(for: _environment)
        _resources = AggregatedResource(configuration: _configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjustedConfig = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjustedConfig)
        
        // Propagate environment change to all capabilities
        for (_, capability) in capabilities {
            await capability.handleEnvironmentChange(environment)
        }
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
        guard await isSupported() else {
            _state = .unavailable
            throw AxiomCapabilityError.notAvailable("One or more capabilities not supported")
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
    
    public func deactivate() async {
        // Terminate all capabilities
        for (_, capability) in capabilities {
            await capability.deactivate()
        }
        
        await _resources.release()
        _state = .unavailable
    }
    
    // MARK: - Aggregation Methods
    
    public func addCapability(_ capability: any DomainCapability, withId id: String) async throws {
        guard !capabilities.keys.contains(id) else {
            throw AxiomCapabilityError.initializationFailed("Capability with id '\(id)' already exists")
        }
        
        capabilities[id] = capability
        
        // Initialize if aggregated capability is already available
        if _state == .available {
            try await capability.activate()
        }
    }
    
    public func removeCapability(withId id: String) async {
        if let capability = capabilities.removeValue(forKey: id) {
            await capability.deactivate()
        }
    }
    
    public func getCapability<T: DomainCapability>(withId id: String, as type: T.Type) async -> T? {
        capabilities[id] as? T
    }
    
    private func initializeSequentially() async throws {
        for (id, capability) in capabilities {
            do {
                try await capability.activate()
            } catch {
                // If a capability fails, terminate all previously initialized ones
                for (previousId, previousCapability) in capabilities {
                    if previousId == id { break }
                    await previousCapability.deactivate()
                }
                throw error
            }
        }
    }
    
    private func initializeInParallel() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (_, capability) in capabilities {
                group.addTask {
                    try await capability.activate()
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
                        try await capability.activate()
                        initialized.insert(id)
                        remaining.remove(id)
                    }
                } else {
                    // No dependencies, initialize immediately
                    try await capabilities[id]?.activate()
                    initialized.insert(id)
                    remaining.remove(id)
                }
            }
            
            // If no progress was made, we have circular dependencies
            if remaining.count == previousCount {
                throw AxiomCapabilityError.initializationFailed("Circular dependencies detected")
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
public struct AggregatedConfiguration: AxiomCapabilityConfiguration {
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
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AggregatedConfiguration {
        return AggregatedConfiguration(
            orchestrationTimeout: environment.isDebug ? min(orchestrationTimeout, 10) : orchestrationTimeout,
            failureStrategy: failureStrategy
        )
    }
}

/// Failure strategies for aggregated capabilities
public enum FailureStrategy: String, Codable, Sendable {
    case failFast      // Stop on first failure
    case continueOnError // Continue with available capabilities
    case retryFailed   // Retry failed capabilities
}

/// Resource management for aggregated capabilities
public actor AggregatedResource: AxiomCapabilityResource {
    private let configuration: AggregatedConfiguration
    private var allocatedResources: [String: any AxiomCapabilityResource] = [:]
    
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
                totalMemory += Int64(usage.memory)
                totalCPU += usage.cpu
                totalNetwork += Int64(usage.bandwidth)
                totalDisk += Int64(usage.storage)
            }
            
            return ResourceUsage(memory: Int(totalMemory), cpu: totalCPU, bandwidth: Int(totalNetwork), storage: Int(totalDisk))
        }
    }
    
    public let maxUsage = ResourceUsage(memory: 1_000_000_000, cpu: 90.0, bandwidth: 10_000_000, storage: 5_000_000_000)
    
    public func isAvailable() async -> Bool {
        let usage = await currentUsage
        return !usage.exceeds(maxUsage)
    }
    
    public func allocate() async throws {
        guard await isAvailable() else {
            throw AxiomCapabilityError.resourceAllocationFailed("Insufficient resources for aggregated capability")
        }
    }
    
    public func release() async {
        for (_, resource) in allocatedResources {
            await resource.release()
        }
        allocatedResources.removeAll()
    }
    
    func addResource(_ resource: any AxiomCapabilityResource, withId id: String) async {
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
public actor AdaptiveCapabilityActor<BaseCapability: DomainCapability>: DomainCapability {
    public typealias ConfigurationType = AdaptiveConfiguration<BaseCapability.ConfigurationType>
    public typealias ResourceType = BaseCapability.ResourceType
    
    private var baseCapability: BaseCapability
    private var _configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>
    private var _environment: AxiomCapabilityEnvironment
    private var configurationUpdater: Task<Void, Never>?
    private var _activationTimeout: Duration = .milliseconds(10)
    
    public init(
        baseCapability: BaseCapability,
        configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment(isDebug: true)
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
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public func updateConfiguration(_ configuration: AdaptiveConfiguration<BaseCapability.ConfigurationType>) async throws {
        _configuration = configuration.adjusted(for: _environment)
        
        let baseConfig = await resolveConfiguration(for: _environment)
        try await baseCapability.updateConfiguration(baseConfig)
        
        await startConfigurationUpdater()
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        
        let baseConfig = await resolveConfiguration(for: environment)
        try? await baseCapability.updateConfiguration(baseConfig)
        await baseCapability.handleEnvironmentChange(environment)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public var state: AxiomCapabilityState {
        get async { await baseCapability.state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        get async { await baseCapability.stateStream }
    }
    
    public func isSupported() async -> Bool {
        await baseCapability.isSupported()
    }
    
    public func requestPermission() async throws {
        try await baseCapability.requestPermission()
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public var isAvailable: Bool {
        get async { await baseCapability.isAvailable }
    }
    
    public func activate() async throws {
        let baseConfig = await resolveConfiguration(for: _environment)
        try await baseCapability.updateConfiguration(baseConfig)
        try await baseCapability.activate()
        
        await startConfigurationUpdater()
    }
    
    public func deactivate() async {
        configurationUpdater?.cancel()
        configurationUpdater = nil
        await baseCapability.deactivate()
    }
    
    // MARK: - Adaptive Methods
    
    private func resolveConfiguration(for environment: AxiomCapabilityEnvironment) async -> BaseCapability.ConfigurationType {
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
public struct AdaptiveConfiguration<BaseConfig: AxiomCapabilityConfiguration>: AxiomCapabilityConfiguration {
    public let defaultConfiguration: BaseConfig
    public let environmentConfigurations: [AxiomCapabilityEnvironment: BaseConfig]
    public let enableRuntimeUpdates: Bool
    public let updateInterval: TimeInterval
    public let featureFlags: [String: Bool]
    public let abTestVariant: String?
    
    public init(
        defaultConfiguration: BaseConfig,
        environmentConfigurations: [AxiomCapabilityEnvironment: BaseConfig] = [:],
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
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> AdaptiveConfiguration<BaseConfig> {
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

// MARK: - Aggregated Capability Protocol

/// Protocol for capabilities that aggregate multiple other capabilities
public protocol AggregatedCapability: DomainCapability {
    var capabilities: [String: any DomainCapability] { get async }
    
    func addCapability(_ capability: any DomainCapability, withId id: String) async throws
    func removeCapability(withId id: String) async
    func getCapability<T: DomainCapability>(withId id: String, as type: T.Type) async -> T?
}