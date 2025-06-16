import Foundation

// MARK: - Enhanced Actor Isolation Patterns (W-02-001)

/// Unique identifier for actors in the system
public struct ActorIdentifier: Hashable, Sendable, Codable {
    public let id: UUID
    public let name: String
    public let type: String
    
    public init(id: UUID, name: String, type: String) {
        self.id = id
        self.name = name
        self.type = type
    }
}

/// Reentrancy policies for actor operations
public enum ReentrancyPolicy: Sendable {
    case allow
    case deny
    case queue
    case detectAndHandle
}

/// Enhanced actor protocol with isolation guarantees
public protocol IsolatedActor: Actor {
    associatedtype StateType: Sendable
    associatedtype ActionType
    associatedtype MessageType: ClientMessage
    
    /// Unique actor identifier for debugging and monitoring
    var actorID: ActorIdentifier { get }
    
    /// Quality of service for this actor
    var qualityOfService: DispatchQoS { get }
    
    /// Reentrancy policy for this actor
    var reentrancyPolicy: ReentrancyPolicy { get }
    
    /// Handle messages from contexts only
    func handleMessage(_ message: MessageType) async throws
    
    /// Validate actor state consistency
    func validateActorInvariants() async throws
}

/// Protocol for type-safe message passing between actors
public protocol ClientMessage: Sendable {
    var source: MessageSource { get }
    var timestamp: Date { get }
    var correlationID: UUID { get }
}

/// Message source for validation
public enum MessageSource: Sendable {
    case context(ContextIdentifier)
    case system
    case test
}

/// Context identifier for isolation enforcement
public struct ContextIdentifier: Hashable, Sendable {
    public let id: String
    
    public init(_ id: String) {
        self.id = id
    }
}

/// Isolation enforcer for runtime validation
public actor IsolationEnforcer {
    private var clientRegistry: [ActorIdentifier: IsolationInfo] = [:]
    private var communicationLog: [CommunicationRecord] = []
    
    struct IsolationInfo {
        let allowedContexts: Set<ContextIdentifier>
        let createdAt: Date
    }
    
    struct CommunicationRecord {
        let source: MessageSource
        let destination: ActorIdentifier
        let timestamp: Date
    }
    
    /// Register client with isolation rules
    public func registerClient(
        _ client: any IsolatedActor,
        allowedContexts: Set<ContextIdentifier>
    ) async throws {
        let actorID = await client.actorID
        let info = IsolationInfo(
            allowedContexts: allowedContexts,
            createdAt: Date()
        )
        clientRegistry[actorID] = info
    }
    
    /// Validate message routing
    public func validateCommunication(
        from source: MessageSource,
        to client: ActorIdentifier
    ) async throws {
        guard let info = clientRegistry[client] else {
            throw IsolationError.unregisteredClient(client)
        }
        
        switch source {
        case .context(let contextID):
            guard info.allowedContexts.contains(contextID) else {
                throw IsolationError.unauthorizedContext(
                    context: contextID,
                    client: client
                )
            }
        case .system, .test:
            // Always allowed
            break
        }
        
        // Log communication
        let record = CommunicationRecord(
            source: source,
            destination: client,
            timestamp: Date()
        )
        communicationLog.append(record)
    }
}

/// Context-mediated communication router
@MainActor
public class IsolatedCommunicationRouter {
    private let enforcer: IsolationEnforcer
    private var routingTable: [ActorIdentifier: any IsolatedActor] = [:]
    
    public init(enforcer: IsolationEnforcer) {
        self.enforcer = enforcer
    }
    
    /// Register client for routing
    public func registerClient(
        _ client: any IsolatedActor,
        allowedContexts: Set<ContextIdentifier>
    ) async {
        try? await enforcer.registerClient(client, allowedContexts: allowedContexts)
        let actorID = await client.actorID
        routingTable[actorID] = client
    }
    
    /// Route message through context
    public func routeMessage<M: ClientMessage>(
        _ message: M,
        to clientID: ActorIdentifier,
        from context: ContextIdentifier
    ) async throws {
        // Validate routing is allowed
        try await enforcer.validateCommunication(
            from: .context(context),
            to: clientID
        )
        
        // Get client and deliver message
        guard routingTable[clientID] != nil else {
            throw RoutingError.actorNotFound(clientID)
        }
        
        // Type-safe message delivery implementation deferred
        // Message routing validated but delivery mechanism simplified
    }
}

/// Actor metrics collection
public actor ActorMetrics {
    private var callCounts: [ActorIdentifier: Int] = [:]
    private var callDurations: [ActorIdentifier: [Duration]] = [:]
    private var reentrancyCounts: [ActorIdentifier: Int] = [:]
    
    public func recordCall(
        actorID: ActorIdentifier,
        duration: Duration,
        wasReentrant: Bool
    ) {
        callCounts[actorID, default: 0] += 1
        callDurations[actorID, default: []].append(duration)
        
        if wasReentrant {
            reentrancyCounts[actorID, default: 0] += 1
        }
    }
    
    public func getMetrics(for actorID: ActorIdentifier) -> ActorMetricsSnapshot {
        let calls = callCounts[actorID] ?? 0
        let durations = callDurations[actorID] ?? []
        let reentrancies = reentrancyCounts[actorID] ?? 0
        
        let averageDuration = durations.isEmpty ? Duration.zero :
            Duration.nanoseconds(durations.map(\.components.attoseconds).reduce(0, +) / Int64(durations.count))
        
        return ActorMetricsSnapshot(
            callCount: calls,
            averageCallDuration: averageDuration,
            reentrancyRate: calls > 0 ? Double(reentrancies) / Double(calls) : 0.0
        )
    }
    
    private func calculateAverage(_ durations: [Duration]) -> Duration {
        guard !durations.isEmpty else { return Duration.zero }
        let total = durations.map(\.components.attoseconds).reduce(0, +)
        return Duration.nanoseconds(total / Int64(durations.count))
    }
    
    private func calculateReentrancyRate(_ actorID: ActorIdentifier) -> Double {
        let calls = callCounts[actorID] ?? 0
        let reentrancies = reentrancyCounts[actorID] ?? 0
        return calls > 0 ? Double(reentrancies) / Double(calls) : 0.0
    }
}

/// Performance metrics snapshot
public struct ActorMetricsSnapshot {
    public let callCount: Int
    public let averageCallDuration: Duration
    public let reentrancyRate: Double
    
    public init(callCount: Int, averageCallDuration: Duration, reentrancyRate: Double) {
        self.callCount = callCount
        self.averageCallDuration = averageCallDuration
        self.reentrancyRate = reentrancyRate
    }
}

// MARK: - Actor-based Client Protocol

/// Protocol for clients that ensures concurrency safety through actor isolation.
/// 
/// All state mutations are actor-isolated with documented await points to prevent
/// data races and ensure thread safety. Clients can safely call other clients
/// through defined async protocols without risk of deadlock.
public protocol ConcurrentClient: Actor {
    /// The unique identifier for this client
    var id: String { get }
    
    /// The current state version for reentrancy checking
    var stateVersion: Int { get }
    
    /// Validates state consistency after await points
    /// 
    /// This method should be called after any await point where state
    /// might have changed due to reentrancy.
    /// 
    /// - Parameter expectedVersion: The state version before the await
    /// - Returns: true if state is still consistent
    func validateStateConsistency(expectedVersion: Int) -> Bool
}

// MARK: - Error Types

/// Isolation-related errors
public enum IsolationError: Error {
    case unregisteredClient(ActorIdentifier)
    case unauthorizedContext(context: ContextIdentifier, client: ActorIdentifier)
    case unauthorizedCommunication
    case clientToClientDependency(from: IsolationClientID, to: IsolationClientID)
    case unauthorizedClientContext(context: ContextIdentifier, client: IsolationClientID)
}

/// Routing-related errors
public enum RoutingError: Error {
    case actorNotFound(ActorIdentifier)
    case clientNotFound(IsolationClientID)
    case typeMismatch(expected: String, actual: String)
}

/// Actor-related errors for concurrency safety
public enum ConcurrencyActorError: Error {
    case invariantViolation(String)
    case reentrancyDenied(OperationIdentifier)
    case actorNotFound(ActorIdentifier)
}

/// Operation identifier for reentrancy tracking
public enum OperationIdentifier: Hashable, Sendable, Codable {
    case operation(String)
    case action(String)
    
    public var name: String {
        switch self {
        case .operation(let name):
            return name
        case .action(let name):
            return name
        }
    }
    
    public init(name: String, parameters: String = "") {
        self = .operation("\(name)(\(parameters))")
    }
    
    public static func actionType(_ action: String) -> OperationIdentifier {
        return .action(action)
    }
}

// MARK: - Client Isolation Enforcement (W-02-005)

/// Client identifier for isolation enforcement
public struct IsolationClientID: Hashable, Sendable {
    public let id: String
    
    public init(_ id: String) {
        self.id = id
    }
}

/// Actor for enforcing client isolation constraints
public actor ClientIsolationEnforcer {
    private var clientRegistry: [IsolationClientID: ClientInfo] = [:]
    private var contextClients: [ContextIdentifier: Set<IsolationClientID>] = [:]
    private var clientContexts: [IsolationClientID: Set<ContextIdentifier>] = [:]
    private var communicationLog: [IsolationRecord] = []
    private var allowedCommunications: [IsolationClientID: Set<IsolationClientID>] = [:]
    private let maxLogSize = 10000
    
    private struct ClientInfo {
        let allowedContexts: Set<ContextIdentifier>
        let registeredAt: Date
        var lastActivity: Date
    }
    
    public struct IsolationRecord {
        public let from: IsolationClientID
        public let to: IsolationClientID
        public let context: ContextIdentifier
        public let timestamp: Date
        public let operation: String
        
        public init(from: IsolationClientID, to: IsolationClientID, context: ContextIdentifier, timestamp: Date, operation: String) {
            self.from = from
            self.to = to
            self.context = context
            self.timestamp = timestamp
            self.operation = operation
        }
    }
    
    public init() {}
    
    /// Register a client with its allowed contexts
    public func registerClient(
        _ clientID: IsolationClientID,
        allowedContexts: Set<ContextIdentifier>
    ) async throws {
        // Validate contexts exist or create them
        for context in allowedContexts {
            if contextClients[context] == nil {
                contextClients[context] = Set<IsolationClientID>()
            }
            contextClients[context]?.insert(clientID)
        }
        
        // Register client
        let info = ClientInfo(
            allowedContexts: allowedContexts,
            registeredAt: Date(),
            lastActivity: Date()
        )
        clientRegistry[clientID] = info
        clientContexts[clientID] = allowedContexts
    }
    
    /// Validate client can operate in context
    public func validateClientContext(
        _ clientID: IsolationClientID,
        context: ContextIdentifier
    ) async throws {
        guard let info = clientRegistry[clientID] else {
            throw IsolationError.unauthorizedClientContext(context: context, client: clientID)
        }
        
        guard info.allowedContexts.contains(context) else {
            throw IsolationError.unauthorizedClientContext(context: context, client: clientID)
        }
        
        // Update last activity
        clientRegistry[clientID]?.lastActivity = Date()
    }
    
    /// Validate communication between clients
    public func validateCommunication(
        from source: IsolationClientID,
        to destination: IsolationClientID,
        in context: ContextIdentifier,
        operation: String
    ) async throws {
        // Ensure both clients are registered
        guard clientRegistry[source] != nil else {
            throw IsolationError.clientToClientDependency(from: source, to: destination)
        }
        
        guard let destInfo = clientRegistry[destination] else {
            throw IsolationError.clientToClientDependency(from: source, to: destination)
        }
        
        // Validate context access for destination
        guard destInfo.allowedContexts.contains(context) else {
            throw IsolationError.unauthorizedClientContext(context: context, client: destination)
        }
        
        // Check if communication is explicitly allowed
        if let allowed = allowedCommunications[source] {
            guard allowed.contains(destination) else {
                throw IsolationError.clientToClientDependency(from: source, to: destination)
            }
        } else {
            // First time communication - check context overlap
            guard let sourceInfo = clientRegistry[source],
                  !sourceInfo.allowedContexts.intersection(destInfo.allowedContexts).isEmpty else {
                throw IsolationError.clientToClientDependency(from: source, to: destination)
            }
        }
        
        // Log communication
        let record = IsolationRecord(
            from: source,
            to: destination,
            context: context,
            timestamp: Date(),
            operation: operation
        )
        communicationLog.append(record)
        
        // Maintain log size
        if communicationLog.count > maxLogSize {
            communicationLog.removeFirst(communicationLog.count - maxLogSize)
        }
        
        // Update activity timestamps
        clientRegistry[source]?.lastActivity = Date()
        clientRegistry[destination]?.lastActivity = Date()
    }
    
    /// Explicitly allow communication between clients
    public func allowCommunication(
        from source: IsolationClientID,
        to destination: IsolationClientID
    ) async {
        if allowedCommunications[source] == nil {
            allowedCommunications[source] = Set<IsolationClientID>()
        }
        allowedCommunications[source]?.insert(destination)
    }
    
    /// Get clients in a specific context
    public func getClientsInContext(_ context: ContextIdentifier) async -> Set<IsolationClientID> {
        return contextClients[context] ?? Set<IsolationClientID>()
    }
    
    /// Get contexts for a specific client
    public func getContextsForClient(_ clientID: IsolationClientID) async -> Set<ContextIdentifier> {
        return clientContexts[clientID] ?? Set<ContextIdentifier>()
    }
    
    /// Get communication history
    public func getCommunicationHistory(
        limit: Int = 100
    ) async -> [IsolationRecord] {
        let startIndex = max(0, communicationLog.count - limit)
        return Array(communicationLog[startIndex...])
    }
    
    /// Clean up inactive clients
    public func cleanupInactiveClients(olderThan timeInterval: TimeInterval) async {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        let inactiveClients = clientRegistry.compactMap { (id, info) in
            info.lastActivity < cutoffDate ? id : nil
        }
        
        for clientID in inactiveClients {
            await unregisterClient(clientID)
        }
    }
    
    /// Unregister a client
    public func unregisterClient(_ clientID: IsolationClientID) async {
        clientRegistry.removeValue(forKey: clientID)
        clientContexts.removeValue(forKey: clientID)
        allowedCommunications.removeValue(forKey: clientID)
        
        // Remove from context mappings
        for (context, clients) in contextClients {
            var updatedClients = clients
            updatedClients.remove(clientID)
            contextClients[context] = updatedClients.isEmpty ? nil : updatedClients
        }
        
        // Remove from allowed communications of other clients
        for (source, destinations) in allowedCommunications {
            var updatedDestinations = destinations
            updatedDestinations.remove(clientID)
            allowedCommunications[source] = updatedDestinations.isEmpty ? nil : updatedDestinations
        }
    }
}

/// Protocol for client isolation validation
public protocol IsolationValidated {
    var isolationClientID: IsolationClientID { get }
    
    /// Validate client can operate in given context
    func validateIsolation(in context: ContextIdentifier) async throws
}

/// Default implementation for isolation validation
public extension IsolationValidated {
    func validateIsolation(in context: ContextIdentifier) async throws {
        // This would typically coordinate with a shared ClientIsolationEnforcer
        // For now, we provide a default no-op implementation
    }
}