import Foundation
import Observation

// MARK: - Client Dependencies Protocol

/// Protocol for declaring client dependencies in a type-safe manner
public protocol ClientDependencies: Sendable {
    init()
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

