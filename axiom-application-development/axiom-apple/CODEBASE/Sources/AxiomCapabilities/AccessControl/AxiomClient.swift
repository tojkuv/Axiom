import Foundation
import AxiomCore

// MARK: - Axiom Client Base Class

/// Base class for all Axiom clients
/// Clients can only access ExternalServiceCapability instances for external service communication
open class AxiomClient: ObservableObject {
    
    /// Unique identifier for this client
    public let id: UUID
    
    /// Client name for identification and debugging
    public let name: String
    
    /// Environment client is operating in
    public private(set) var environment: AxiomCapabilityEnvironment
    
    /// Active external service capabilities managed by this client
    private var activeCapabilities: [String: any ExternalServiceCapability] = [:]
    
    /// Capability lifecycle observers
    private var capabilityObservers: [String: CapabilityObserver] = [:]
    
    /// Client connection state
    @Published public private(set) var connectionState: ClientConnectionState = .disconnected
    
    public init(
        name: String,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self.id = UUID()
        self.name = name
        self.environment = environment
        
        Task {
            await self.registerClient()
        }
    }
    
    deinit {
        Task {
            await self.cleanup()
        }
    }
    
    // MARK: - Capability Access Control
    
    /// Access an external service capability with type safety and access control enforcement
    public func capability<T: ExternalServiceCapability>(_ type: T.Type) async throws -> T {
        // Validate access control
        try await CapabilityAccessControlManager.shared.validateAccess(
            capabilityType: type,
            componentType: .client
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
    
    /// Attempt to access a local capability (will throw error)
    public func capability<T: LocalCapability>(_ type: T.Type) async throws -> T {
        throw CapabilityAccessError.unauthorizedAccess(
            capability: String(describing: type),
            component: "Client",
            reason: "Clients cannot access local device capabilities. Use a Context instead."
        )
    }
    
    /// Release a specific capability
    public func releaseCapability<T: ExternalServiceCapability>(_ type: T.Type) async {
        let capabilityKey = String(describing: type)
        
        if let capability = activeCapabilities[capabilityKey] {
            await capability.deactivate()
            activeCapabilities.removeValue(forKey: capabilityKey)
            capabilityObservers.removeValue(forKey: capabilityKey)
        }
    }
    
    /// Get all active capabilities
    public func getActiveCapabilities() -> [any ExternalServiceCapability] {
        return Array(activeCapabilities.values)
    }
    
    /// Check if a capability is active
    public func isCapabilityActive<T: ExternalServiceCapability>(_ type: T.Type) -> Bool {
        let capabilityKey = String(describing: type)
        return activeCapabilities[capabilityKey] != nil
    }
    
    // MARK: - Connection Management
    
    /// Connect to external services
    public func connect() async throws {
        await updateConnectionState(.connecting)
        
        do {
            try await performConnection()
            await updateConnectionState(.connected)
            await onConnected()
        } catch {
            await updateConnectionState(.failed(error))
            await onConnectionFailed(error)
            throw error
        }
    }
    
    /// Disconnect from external services
    public func disconnect() async {
        await updateConnectionState(.disconnecting)
        
        // Deactivate all capabilities
        for capability in activeCapabilities.values {
            await capability.deactivate()
        }
        
        await performDisconnection()
        await updateConnectionState(.disconnected)
        await onDisconnected()
    }
    
    /// Check if client is connected
    public var isConnected: Bool {
        switch connectionState {
        case .connected:
            return true
        default:
            return false
        }
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
    
    // MARK: - Client Lifecycle
    
    /// Called when client is registered
    open func onRegistered() async {
        // Override in subclasses
    }
    
    /// Called when environment changes
    open func onEnvironmentChanged(_ environment: AxiomCapabilityEnvironment) async {
        // Override in subclasses
    }
    
    /// Called when capability state changes
    open func onCapabilityStateChanged<T: ExternalServiceCapability>(
        _ capability: T,
        oldState: AxiomCapabilityState,
        newState: AxiomCapabilityState
    ) async {
        // Override in subclasses
    }
    
    /// Called when connection is established
    open func onConnected() async {
        // Override in subclasses
    }
    
    /// Called when connection fails
    open func onConnectionFailed(_ error: Error) async {
        // Override in subclasses
    }
    
    /// Called when disconnected
    open func onDisconnected() async {
        // Override in subclasses
    }
    
    /// Perform connection setup - override in subclasses
    open func performConnection() async throws {
        // Default implementation does nothing
    }
    
    /// Perform disconnection cleanup - override in subclasses
    open func performDisconnection() async {
        // Default implementation does nothing
    }
    
    /// Called during client cleanup
    open func onCleanup() async {
        // Override in subclasses
    }
    
    // MARK: - Private Implementation
    
    private func createCapability<T: ExternalServiceCapability>(_ type: T.Type) async throws -> T {
        // Get default configuration for capability type
        let defaultConfig = getDefaultConfiguration(for: type)
        
        // Create capability with environment-adjusted configuration
        return T(
            configuration: defaultConfig.adjusted(for: environment),
            environment: environment
        )
    }
    
    private func getDefaultConfiguration<T: ExternalServiceCapability>(for type: T.Type) -> T.ConfigurationType {
        // Return default configuration - subclasses can override this behavior
        return T.ConfigurationType()
    }
    
    private func setupCapabilityObserver<T: ExternalServiceCapability>(
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
    
    private func updateConnectionState(_ newState: ClientConnectionState) async {
        await MainActor.run {
            self.connectionState = newState
        }
    }
    
    private func registerClient() async {
        await ClientRegistry.shared.register(self)
        await onRegistered()
    }
    
    private func cleanup() async {
        // Disconnect if connected
        if isConnected {
            await disconnect()
        }
        
        // Deactivate all capabilities
        for capability in activeCapabilities.values {
            await capability.deactivate()
        }
        
        activeCapabilities.removeAll()
        capabilityObservers.removeAll()
        
        await ClientRegistry.shared.unregister(self)
        await onCleanup()
    }
}

// MARK: - Client Connection State

/// Represents the connection state of a client
public enum ClientConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed(Error)
    
    public var isConnected: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    public var isConnecting: Bool {
        switch self {
        case .connecting:
            return true
        default:
            return false
        }
    }
    
    public var isFailed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Client Registry

/// Registry for tracking active clients
public actor ClientRegistry {
    public static let shared = ClientRegistry()
    
    private var activeClients: [UUID: ClientRegistration] = [:]
    
    private init() {}
    
    /// Register a client
    public func register(_ client: AxiomClient) {
        activeClients[client.id] = ClientRegistration(
            id: client.id,
            name: client.name,
            connectionState: client.connectionState,
            registeredAt: Date()
        )
    }
    
    /// Unregister a client
    public func unregister(_ client: AxiomClient) {
        activeClients.removeValue(forKey: client.id)
    }
    
    /// Get all active clients
    public func getActiveClients() -> [ClientRegistration] {
        return Array(activeClients.values)
    }
    
    /// Get client by ID
    public func getClient(id: UUID) -> ClientRegistration? {
        return activeClients[id]
    }
    
    /// Update client connection state
    public func updateConnectionState(_ clientId: UUID, state: ClientConnectionState) {
        if var registration = activeClients[clientId] {
            registration = ClientRegistration(
                id: registration.id,
                name: registration.name,
                connectionState: state,
                registeredAt: registration.registeredAt
            )
            activeClients[clientId] = registration
        }
    }
}

/// Registration information for a client
public struct ClientRegistration: Sendable {
    public let id: UUID
    public let name: String
    public let connectionState: ClientConnectionState
    public let registeredAt: Date
}

// MARK: - Capability Observer

/// Observer for capability state changes
private class CapabilityObserver {
    let handler: (any ExternalServiceCapability, AxiomCapabilityState, AxiomCapabilityState) async -> Void
    
    init(handler: @escaping (any ExternalServiceCapability, AxiomCapabilityState, AxiomCapabilityState) async -> Void) {
        self.handler = handler
    }
    
    func handleStateChange(
        _ capability: any ExternalServiceCapability,
        oldState: AxiomCapabilityState,
        newState: AxiomCapabilityState
    ) async {
        await handler(capability, oldState, newState)
    }
}

// MARK: - Client Extensions

extension AxiomClient {
    /// Convenience method to get capability configuration
    public func getCapabilityConfiguration<T: ExternalServiceCapability>(_ type: T.Type) async throws -> T.ConfigurationType {
        let capability = try await self.capability(type)
        return await capability.configuration
    }
    
    /// Convenience method to check capability support
    public func isCapabilitySupported<T: ExternalServiceCapability>(_ type: T.Type) async throws -> Bool {
        let capability = try await self.capability(type)
        return await capability.isSupported()
    }
    
    /// Get client metrics
    public func getMetrics() -> ClientMetrics {
        return ClientMetrics(
            id: id,
            name: name,
            activeCapabilities: activeCapabilities.count,
            connectionState: connectionState,
            environment: environment
        )
    }
}

/// Client performance and state metrics
public struct ClientMetrics: Sendable {
    public let id: UUID
    public let name: String
    public let activeCapabilities: Int
    public let connectionState: ClientConnectionState
    public let environment: AxiomCapabilityEnvironment
    public let timestamp: Date
    
    public init(
        id: UUID,
        name: String,
        activeCapabilities: Int,
        connectionState: ClientConnectionState,
        environment: AxiomCapabilityEnvironment
    ) {
        self.id = id
        self.name = name
        self.activeCapabilities = activeCapabilities
        self.connectionState = connectionState
        self.environment = environment
        self.timestamp = Date()
    }
}