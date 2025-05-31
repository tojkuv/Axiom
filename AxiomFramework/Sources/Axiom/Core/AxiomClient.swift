import Foundation
import Observation

// MARK: - Client Dependencies Protocol

/// Protocol for declaring client dependencies in a type-safe manner
public protocol ClientDependencies: Sendable {
    init()
}

// MARK: - Generic Client Container (Eliminates Boilerplate)

/// ENHANCED: Generic client container that eliminates the need for manual client container types
/// Replaces verbose manual container structs with a simple generic solution
public struct ClientContainer<Client1: AxiomClient>: ClientDependencies {
    public let client1: Client1
    
    public init() {
        preconditionFailure("ClientContainer should be initialized with actual clients - use init(_:) instead")
    }
    
    public init(_ client1: Client1) {
        self.client1 = client1
    }
}

/// Two-client container for contexts that manage multiple clients
public struct ClientContainer2<Client1: AxiomClient, Client2: AxiomClient>: ClientDependencies {
    public let client1: Client1
    public let client2: Client2
    
    public init() {
        preconditionFailure("ClientContainer2 should be initialized with actual clients - use init(_:_:) instead")
    }
    
    public init(_ client1: Client1, _ client2: Client2) {
        self.client1 = client1
        self.client2 = client2
    }
}

/// Three-client container for contexts that manage multiple clients
public struct ClientContainer3<Client1: AxiomClient, Client2: AxiomClient, Client3: AxiomClient>: ClientDependencies {
    public let client1: Client1
    public let client2: Client2
    public let client3: Client3
    
    public init() {
        preconditionFailure("ClientContainer3 should be initialized with actual clients - use init(_:_:_:) instead")
    }
    
    public init(_ client1: Client1, _ client2: Client2, _ client3: Client3) {
        self.client1 = client1
        self.client2 = client2
        self.client3 = client3
    }
}

/// Named client container that provides property access by name instead of position
/// Use this when you want meaningful property names instead of client1, client2, etc.
public struct NamedClientContainer: ClientDependencies {
    private var clients: [String: any AxiomClient] = [:]
    
    public init() {}
    
    public init(_ clients: [String: any AxiomClient]) {
        self.clients = clients
    }
    
    /// Add a client with a specific name
    public mutating func add<T: AxiomClient>(_ client: T, named name: String) {
        clients[name] = client
    }
    
    /// Get a client by name with type safety
    public func get<T: AxiomClient>(_ name: String, as type: T.Type) -> T? {
        return clients[name] as? T
    }
    
    /// Get a client by name (unsafe - use with caution)
    public func get(_ name: String) -> (any AxiomClient)? {
        return clients[name]
    }
}

// MARK: - Client Container Convenience Extensions

/// Convenience methods for easier access to clients in containers
extension ClientContainer {
    /// Direct access to the single client with a more natural name
    public var client: Client1 {
        client1
    }
}

extension ClientContainer2 {
    /// Access first client with meaningful name
    public var firstClient: Client1 {
        client1
    }
    
    /// Access second client with meaningful name
    public var secondClient: Client2 {
        client2
    }
}

extension ClientContainer3 {
    /// Access first client with meaningful name
    public var firstClient: Client1 {
        client1
    }
    
    /// Access second client with meaningful name
    public var secondClient: Client2 {
        client2
    }
    
    /// Access third client with meaningful name
    public var thirdClient: Client3 {
        client3
    }
}

// MARK: - AxiomClient Protocol

/// The core protocol for all state-managing clients in the Axiom framework
public protocol AxiomClient: Actor {
    associatedtype State: Sendable
    associatedtype DomainModelType: DomainModel = EmptyDomain
    
    /// The current state snapshot
    var stateSnapshot: State { get }
    
    /// The capability manager for this client
    var capabilities: CapabilityManager { get }
    
    // MARK: State Management
    
    /// Updates the state atomically
    func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T
    
    /// Validates the current state
    func validateState() async throws
    
    // MARK: Observer Pattern
    
    /// Adds an observer to be notified of state changes
    func addObserver<T: AxiomContext>(_ context: T) async
    
    /// Removes an observer
    func removeObserver<T: AxiomContext>(_ context: T) async
    
    /// Notifies all observers of a state change
    func notifyObservers() async
    
    // MARK: Lifecycle
    
    /// Initializes the client
    func initialize() async throws
    
    /// Shuts down the client
    func shutdown() async
}



// MARK: - Base Client Implementation

/// A base implementation of AxiomClient that provides common functionality
public actor BaseAxiomClient<State: Sendable, DomainModelType: DomainModel>: AxiomClient {
    // State management
    private var _state: State
    private var _stateVersion: StateVersion
    private var _observers: Set<AnyHashable> = []
    
    // Public properties
    public let capabilities: CapabilityManager
    
    public var stateSnapshot: State {
        _state
    }
    
    // MARK: Initialization
    
    public init(initialState: State, capabilities: CapabilityManager) {
        self._state = initialState
        self._stateVersion = StateVersion()
        self.capabilities = capabilities
    }
    
    // MARK: State Management
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {
        // Override in subclasses to provide custom validation
    }
    
    // MARK: Observer Pattern
    
    public func addObserver<T: AxiomContext>(_ context: T) async {
        _observers.insert(ObjectIdentifier(context))
    }
    
    public func removeObserver<T: AxiomContext>(_ context: T) async {
        _observers.remove(ObjectIdentifier(context))
    }
    
    public func notifyObservers() async {
        // In a real implementation, this would notify all registered observers
        // For now, we just track that observers exist
    }
    
    // MARK: Lifecycle
    
    public func initialize() async throws {
        // Override in subclasses to provide initialization logic
        try await validateState()
    }
    
    public func shutdown() async {
        _observers.removeAll()
    }
}


// MARK: - Infrastructure Client Protocol

/// Protocol for infrastructure clients that don't manage domain models
public protocol InfrastructureClient: AxiomClient {
    /// Performs a health check
    func healthCheck() async -> HealthStatus
    
    /// Configures the client with the given configuration
    func configure(_ configuration: Configuration) async throws
}

// MARK: - Domain Client Protocol

/// Protocol for clients that manage domain models
public protocol DomainClient: AxiomClient {
    /// Creates a new domain model
    func create(_ model: DomainModelType) async throws -> DomainModelType
    
    /// Updates an existing domain model
    func update(_ model: DomainModelType) async throws -> DomainModelType
    
    /// Deletes a domain model by ID
    func delete(id: DomainModelType.ID) async throws
    
    /// Finds a domain model by ID
    func find(id: DomainModelType.ID) async -> DomainModelType?
    
    /// Queries domain models based on criteria
    func query(_ criteria: QueryCriteria<DomainModelType>) async -> [DomainModelType]
    
    /// Validates business rules for a domain model
    func validateBusinessRules(_ model: DomainModelType) async throws
    
    /// Applies a business operation to a domain model
    func applyBusinessLogic(_ operation: BusinessOperation<DomainModelType>) async throws -> DomainModelType
}

// MARK: - Supporting Types

/// The health status of an infrastructure component
public enum HealthStatus: String, Sendable {
    case healthy
    case degraded
    case unhealthy
}

/// Configuration for infrastructure clients
public struct Configuration: Sendable {
    public let settings: [String: String]
    
    public init(settings: [String: String] = [:]) {
        self.settings = settings
    }
}

