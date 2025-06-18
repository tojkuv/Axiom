import Foundation
import AxiomCore

// MARK: - Axiom Context Base Class

/// Base class for all Axiom contexts
/// Contexts can only access LocalCapability instances for device-local processing
open class AxiomContext: ObservableObject {
    
    /// Unique identifier for this context
    public let id: UUID
    
    /// Context name for identification and debugging
    public let name: String
    
    /// Environment context is operating in
    public private(set) var environment: AxiomCapabilityEnvironment
    
    /// Active local capabilities managed by this context
    private var activeCapabilities: [String: any LocalCapability] = [:]
    
    /// Capability lifecycle observers
    private var capabilityObservers: [String: CapabilityObserver] = [:]
    
    public init(
        name: String,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self.id = UUID()
        self.name = name
        self.environment = environment
        
        Task {
            await self.registerContext()
        }
    }
    
    deinit {
        Task {
            await self.cleanup()
        }
    }
    
    // MARK: - Capability Access Control
    
    /// Access a local capability with type safety and access control enforcement
    public func capability<T: LocalCapability>(_ type: T.Type) async throws -> T {
        // Validate access control
        try await CapabilityAccessControlManager.shared.validateAccess(
            capabilityType: type,
            componentType: .context
        )
        
        let capabilityKey = String(describing: type)
        
        // Return existing capability if already active
        if let existing = activeCapabilities[capabilityKey] as? T {
            return existing
        }
        
        // Create and activate new capability
        let capability = try await createCapability(type)
        try await capability.activate()
        
        activeCapabilities[capabilityKey] = capability
        
        // Set up capability lifecycle observer
        await setupCapabilityObserver(for: capability, key: capabilityKey)
        
        return capability
    }
    
    /// Attempt to access an external service capability (will throw error)
    public func capability<T: ExternalServiceCapability>(_ type: T.Type) async throws -> T {
        throw CapabilityAccessError.unauthorizedAccess(
            capability: String(describing: type),
            component: "Context",
            reason: "Contexts cannot access external service capabilities. Use a Client instead."
        )
    }
    
    /// Release a specific capability
    public func releaseCapability<T: LocalCapability>(_ type: T.Type) async {
        let capabilityKey = String(describing: type)
        
        if let capability = activeCapabilities[capabilityKey] {
            await capability.deactivate()
            activeCapabilities.removeValue(forKey: capabilityKey)
            capabilityObservers.removeValue(forKey: capabilityKey)
        }
    }
    
    /// Get all active capabilities
    public func getActiveCapabilities() -> [any LocalCapability] {
        return Array(activeCapabilities.values)
    }
    
    /// Check if a capability is active
    public func isCapabilityActive<T: LocalCapability>(_ type: T.Type) -> Bool {
        let capabilityKey = String(describing: type)
        return activeCapabilities[capabilityKey] != nil
    }
    
    // MARK: - Environment Management
    
    /// Update the environment and propagate changes to capabilities
    public func updateEnvironment(_ newEnvironment: AxiomCapabilityEnvironment) async {
        self.environment = newEnvironment
        
        // Update all active capabilities with new environment
        for capability in activeCapabilities.values {
            await capability.handleEnvironmentChange(newEnvironment)
        }
        
        await onEnvironmentChanged(newEnvironment)
    }
    
    // MARK: - Context Lifecycle
    
    /// Called when context is registered
    open func onRegistered() async {
        // Override in subclasses
    }
    
    /// Called when environment changes
    open func onEnvironmentChanged(_ environment: AxiomCapabilityEnvironment) async {
        // Override in subclasses
    }
    
    /// Called when capability state changes
    open func onCapabilityStateChanged<T: LocalCapability>(
        _ capability: T,
        oldState: AxiomCapabilityState,
        newState: AxiomCapabilityState
    ) async {
        // Override in subclasses
    }
    
    /// Called during context cleanup
    open func onCleanup() async {
        // Override in subclasses
    }
    
    // MARK: - Private Implementation
    
    private func createCapability<T: LocalCapability>(_ type: T.Type) async throws -> T {
        // Get default configuration for capability type
        let defaultConfig = getDefaultConfiguration(for: type)
        
        // Create capability with environment-adjusted configuration
        return T(
            configuration: defaultConfig.adjusted(for: environment),
            environment: environment
        )
    }
    
    private func getDefaultConfiguration<T: LocalCapability>(for type: T.Type) -> T.ConfigurationType {
        // Return default configuration - subclasses can override this behavior
        return T.ConfigurationType()
    }
    
    private func setupCapabilityObserver<T: LocalCapability>(
        for capability: T,
        key: String
    ) async {
        let observer = CapabilityObserver { [weak self] capability, oldState, newState in
            Task { [weak self] in
                await self?.onCapabilityStateChanged(capability, oldState: oldState, newState: newState)
            }
        }
        
        capabilityObservers[key] = observer
        
        // Start observing capability state changes
        Task {
            for await state in await capability.stateStream {
                // Handle state changes
                await observer.handleStateChange(capability, oldState: await capability.state, newState: state)
            }
        }
    }
    
    private func registerContext() async {
        await ContextRegistry.shared.register(self)
        await onRegistered()
    }
    
    private func cleanup() async {
        // Deactivate all capabilities
        for capability in activeCapabilities.values {
            await capability.deactivate()
        }
        
        activeCapabilities.removeAll()
        capabilityObservers.removeAll()
        
        await ContextRegistry.shared.unregister(self)
        await onCleanup()
    }
}

// MARK: - Context Registry

/// Registry for tracking active contexts
public actor ContextRegistry {
    public static let shared = ContextRegistry()
    
    private var activeContexts: [UUID: ContextRegistration] = [:]
    
    private init() {}
    
    /// Register a context
    public func register(_ context: AxiomContext) {
        activeContexts[context.id] = ContextRegistration(
            id: context.id,
            name: context.name,
            registeredAt: Date()
        )
    }
    
    /// Unregister a context
    public func unregister(_ context: AxiomContext) {
        activeContexts.removeValue(forKey: context.id)
    }
    
    /// Get all active contexts
    public func getActiveContexts() -> [ContextRegistration] {
        return Array(activeContexts.values)
    }
    
    /// Get context by ID
    public func getContext(id: UUID) -> ContextRegistration? {
        return activeContexts[id]
    }
}

/// Registration information for a context
public struct ContextRegistration: Sendable {
    public let id: UUID
    public let name: String
    public let registeredAt: Date
}

// MARK: - Capability Observer

/// Observer for capability state changes
private class CapabilityObserver {
    let handler: (any LocalCapability, AxiomCapabilityState, AxiomCapabilityState) async -> Void
    
    init(handler: @escaping (any LocalCapability, AxiomCapabilityState, AxiomCapabilityState) async -> Void) {
        self.handler = handler
    }
    
    func handleStateChange(
        _ capability: any LocalCapability,
        oldState: AxiomCapabilityState,
        newState: AxiomCapabilityState
    ) async {
        await handler(capability, oldState, newState)
    }
}

// MARK: - Context Extensions

extension AxiomContext {
    /// Convenience method to get capability configuration
    public func getCapabilityConfiguration<T: LocalCapability>(_ type: T.Type) async throws -> T.ConfigurationType {
        let capability = try await self.capability(type)
        return await capability.configuration
    }
    
    /// Convenience method to check capability support
    public func isCapabilitySupported<T: LocalCapability>(_ type: T.Type) async throws -> Bool {
        let capability = try await self.capability(type)
        return await capability.isSupported()
    }
    
    /// Get context metrics
    public func getMetrics() -> ContextMetrics {
        return ContextMetrics(
            id: id,
            name: name,
            activeCapabilities: activeCapabilities.count,
            environment: environment
        )
    }
}

/// Context performance and state metrics
public struct ContextMetrics: Sendable {
    public let id: UUID
    public let name: String
    public let activeCapabilities: Int
    public let environment: AxiomCapabilityEnvironment
    public let timestamp: Date
    
    public init(
        id: UUID,
        name: String,
        activeCapabilities: Int,
        environment: AxiomCapabilityEnvironment
    ) {
        self.id = id
        self.name = name
        self.activeCapabilities = activeCapabilities
        self.environment = environment
        self.timestamp = Date()
    }
}