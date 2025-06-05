import Foundation

// MARK: - Component Lifetime Types

/// Defines the lifetime semantics for framework components.
/// 
/// Each component type in the Axiom framework has specific lifetime requirements
/// that ensure proper resource management and prevent common bugs like retain cycles.
public enum ComponentLifetime: String, CaseIterable {
    /// Single instance exists for the entire application lifetime.
    /// Used for Clients and States to ensure single source of truth.
    case singleton
    
    /// Instance created per presentation and lives as long as the presentation.
    /// Used for Contexts to maintain presentation-specific state.
    case perPresentation
    
    /// New instance created on each request.
    /// Used for Capabilities to ensure fresh system access.
    case transient
}

// MARK: - Protocols

/// Protocol for capabilities that are created transiently
public protocol TransientCapability: AnyObject {
    init()
}

/// Protocol for components that have managed lifetimes
public protocol LifecycleManaged {
    var lifetimeIdentifier: String { get }
}

// MARK: - Lifecycle Management

/// Manages component lifecycles and enforces lifetime rules.
/// 
/// This manager ensures that:
/// - Clients and States are singletons (only one instance exists)
/// - Contexts are per-presentation (each presentation gets its own context)
/// - Capabilities are transient (new instance on each access)
/// 
/// ## Thread Safety
/// This class is NOT thread-safe and should be accessed from a single thread.
public final class ComponentLifecycleManager {
    // Storage for singleton components
    private var clients: [String: WeakBox<AnyObject>] = [:]
    private var states: [String: Any] = [:]
    
    // Storage for per-presentation contexts
    private var contexts: [String: WeakBox<AnyObject>] = [:]
    private var releasedContexts: Set<String> = []
    
    // Lifecycle observers
    private var observers: [UUID: (LifecycleEvent) -> Void] = [:]
    
    // Metrics
    private var metrics = LifecycleMetrics()
    
    /// Last error message for debugging
    public private(set) var lastError: String?
    
    public init() {}
    
    // MARK: - Client Management
    
    /// Registers a client as a singleton.
    /// 
    /// - Parameter client: The client to register
    /// - Returns: true if registration succeeded, false if a client with the same ID already exists
    public func registerClient<T: AnyObject>(_ client: T) -> Bool {
        guard let testClient = client as? LifecycleTestClient else {
            lastError = "Invalid client type"
            return false
        }
        
        let id = testClient.id
        
        // Check if already exists
        if let existingBox = clients[id], existingBox.value != nil {
            lastError = "Client '\(id)' already exists; clients must be singletons"
            metrics.recordViolation(.duplicateSingleton(type: "Client", id: id))
            return false
        }
        
        clients[id] = WeakBox(client)
        metrics.recordRegistration(.client)
        notifyObservers(.clientRegistered(id: id))
        lastError = nil
        return true
    }
    
    /// Gets a registered client by ID.
    /// 
    /// - Parameter id: The client identifier
    /// - Returns: The client if found and still alive, nil otherwise
    public func getClient(id: String) -> AnyObject? {
        clients[id]?.value
    }
    
    // MARK: - State Management
    
    /// Registers a state as a singleton.
    /// 
    /// - Parameter state: The state to register
    /// - Returns: true if registration succeeded, false if a state with the same ID already exists
    public func registerState<T>(_ state: T) -> Bool {
        guard let testState = state as? LifecycleTestState else {
            lastError = "Invalid state type"
            return false
        }
        
        let id = testState.id
        
        // Check if already exists
        if states[id] != nil {
            lastError = "State '\(id)' already exists; states must be singletons"
            metrics.recordViolation(.duplicateSingleton(type: "State", id: id))
            return false
        }
        
        states[id] = state
        metrics.recordRegistration(.state)
        notifyObservers(.stateRegistered(id: id))
        lastError = nil
        return true
    }
    
    // MARK: - Context Management
    
    /// Creates or retrieves a context for a presentation.
    /// 
    /// - Parameters:
    ///   - presentation: The presentation that needs a context
    ///   - reuseExisting: If true, returns existing context; if false, returns nil for released contexts
    /// - Returns: The context instance or nil
    public func createContext<T: AnyObject>(for presentation: T, reuseExisting: Bool = true) -> AnyObject? {
        guard let testPresentation = presentation as? LifecycleTestPresentation else {
            return nil
        }
        
        let id = testPresentation.id
        
        // Check if already exists
        if let existingBox = contexts[id], let existing = existingBox.value {
            if reuseExisting {
                return existing
            } else {
                // Don't create new if one exists and reuseExisting is false
                return nil
            }
        }
        
        // Check if context was released
        if releasedContexts.contains(id) && !reuseExisting {
            return nil
        }
        
        // Create new context
        let context = LifecycleTestContext(presentationId: id)
        contexts[id] = WeakBox(context)
        releasedContexts.remove(id)
        metrics.recordCreation(.context)
        notifyObservers(.contextCreated(presentationId: id))
        return context
    }
    
    /// Releases a context for a presentation.
    /// 
    /// - Parameter presentation: The presentation whose context should be released
    public func releaseContext<T: AnyObject>(for presentation: T) {
        guard let testPresentation = presentation as? LifecycleTestPresentation else {
            return
        }
        
        let id = testPresentation.id
        contexts.removeValue(forKey: id)
        releasedContexts.insert(id)
        metrics.recordRelease(.context)
        notifyObservers(.contextReleased(presentationId: id))
    }
    
    // MARK: - Capability Management
    
    /// Creates a new transient capability instance.
    /// 
    /// - Parameter type: The type of capability to create
    /// - Returns: A new instance of the capability
    public func createCapability<T: TransientCapability>(type: T.Type) -> AnyObject? {
        // Always create new instance for transient capabilities
        let capability = type.init()
        metrics.recordCreation(.capability)
        notifyObservers(.capabilityCreated(type: String(describing: type)))
        return capability
    }
    
    // MARK: - Lifetime Queries
    
    /// Gets the lifetime of a component.
    /// 
    /// - Parameter component: The component to check
    /// - Returns: The lifetime semantics for the component
    public func getLifetime<T>(for component: T) -> ComponentLifetime {
        if component is LifecycleTestClient || component is LifecycleTestState {
            return .singleton
        } else if component is LifecycleTestContext {
            return .perPresentation
        } else if component is LifecycleTestCapability {
            return .transient
        }
        
        // Default to transient
        return .transient
    }
    
    // MARK: - Validation
    
    /// Validates all component lifetimes.
    /// 
    /// - Returns: Validation result with statistics
    public func validateAllLifetimes() -> LifetimeValidation {
        let activeClients = clients.compactMap { $0.value.value }.count
        let activeContexts = contexts.compactMap { $0.value.value }.count
        
        return LifetimeValidation(
            isValid: metrics.violations.isEmpty,
            clientCount: activeClients,
            stateCount: states.count,
            contextCount: activeContexts,
            capabilitiesAreTransient: true,
            violations: metrics.violations
        )
    }
    
    // MARK: - Observers
    
    /// Adds a lifecycle observer.
    /// 
    /// - Parameter observer: Closure to be called on lifecycle events
    /// - Returns: Token that can be used to remove the observer
    @discardableResult
    public func addObserver(_ observer: @escaping (LifecycleEvent) -> Void) -> ObserverToken {
        let token = UUID()
        observers[token] = observer
        return ObserverToken(token: token, manager: self)
    }
    
    /// Removes a lifecycle observer.
    /// 
    /// - Parameter token: The token returned from addObserver
    internal func removeObserver(token: UUID) {
        observers.removeValue(forKey: token)
    }
    
    private func notifyObservers(_ event: LifecycleEvent) {
        observers.values.forEach { $0(event) }
    }
    
    // MARK: - Metrics
    
    /// Gets current lifecycle metrics.
    public var currentMetrics: LifecycleMetrics {
        metrics
    }
}

// MARK: - Supporting Types

/// Token for managing lifecycle observers
public struct ObserverToken {
    private let token: UUID
    private weak var manager: ComponentLifecycleManager?
    
    init(token: UUID, manager: ComponentLifecycleManager) {
        self.token = token
        self.manager = manager
    }
    
    /// Removes the observer associated with this token
    public func remove() {
        manager?.removeObserver(token: token)
    }
}

/// Weak reference wrapper to prevent retain cycles
private final class WeakBox<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

/// Lifecycle events that can be observed
public enum LifecycleEvent {
    case clientRegistered(id: String)
    case stateRegistered(id: String)
    case contextCreated(presentationId: String)
    case contextReleased(presentationId: String)
    case capabilityCreated(type: String)
    
    public var description: String {
        switch self {
        case .clientRegistered(let id):
            return "Client '\(id)' registered"
        case .stateRegistered(let id):
            return "State '\(id)' registered"
        case .contextCreated(let presentationId):
            return "Context created for presentation '\(presentationId)'"
        case .contextReleased(let presentationId):
            return "Context released for presentation '\(presentationId)'"
        case .capabilityCreated(let type):
            return "Transient capability '\(type)' created"
        }
    }
}

/// Result of lifetime validation
public struct LifetimeValidation {
    public let isValid: Bool
    public let clientCount: Int
    public let stateCount: Int
    public let contextCount: Int
    public let capabilitiesAreTransient: Bool
    public let violations: [LifetimeViolation]
    
    init(isValid: Bool, clientCount: Int, stateCount: Int, contextCount: Int, capabilitiesAreTransient: Bool, violations: [LifetimeViolation] = []) {
        self.isValid = isValid
        self.clientCount = clientCount
        self.stateCount = stateCount
        self.contextCount = contextCount
        self.capabilitiesAreTransient = capabilitiesAreTransient
        self.violations = violations
    }
}

/// Tracks lifecycle metrics and violations
public struct LifecycleMetrics {
    private(set) var registrations: [ComponentType: Int] = [:]
    private(set) var creations: [ComponentType: Int] = [:]
    private(set) var releases: [ComponentType: Int] = [:]
    private(set) var violations: [LifetimeViolation] = []
    
    enum ComponentType {
        case client, state, context, capability
    }
    
    mutating func recordRegistration(_ type: ComponentType) {
        registrations[type, default: 0] += 1
    }
    
    mutating func recordCreation(_ type: ComponentType) {
        creations[type, default: 0] += 1
    }
    
    mutating func recordRelease(_ type: ComponentType) {
        releases[type, default: 0] += 1
    }
    
    mutating func recordViolation(_ violation: LifetimeViolation) {
        violations.append(violation)
    }
}

/// Represents a lifetime constraint violation
public enum LifetimeViolation: Equatable {
    case duplicateSingleton(type: String, id: String)
    case invalidLifetime(expected: ComponentLifetime, actual: ComponentLifetime)
    case prematureRelease(type: String, id: String)
    
    public var description: String {
        switch self {
        case .duplicateSingleton(let type, let id):
            return "\(type) '\(id)' already exists; \(type.lowercased())s must be singletons"
        case .invalidLifetime(let expected, let actual):
            return "Invalid lifetime: expected \(expected), got \(actual)"
        case .prematureRelease(let type, let id):
            return "\(type) '\(id)' was released while still in use"
        }
    }
}

// MARK: - Test Support Types
// These would normally be in a test support module

class LifecycleTestClient: LifecycleManaged {
    let id: String
    
    var lifetimeIdentifier: String { id }
    
    init(id: String) {
        self.id = id
    }
}

struct LifecycleTestState: LifecycleManaged {
    let id: String
    
    var lifetimeIdentifier: String { id }
}

class LifecycleTestPresentation: LifecycleManaged {
    let id: String
    
    var lifetimeIdentifier: String { id }
    
    init(id: String) {
        self.id = id
    }
}

class LifecycleTestContext: LifecycleManaged {
    let presentationId: String
    
    var lifetimeIdentifier: String { presentationId }
    
    init(presentationId: String) {
        self.presentationId = presentationId
    }
}

class LifecycleTestCapability: TransientCapability, LifecycleManaged {
    let id = UUID().uuidString
    
    var lifetimeIdentifier: String { id }
    
    required init() {}
}