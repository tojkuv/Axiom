import SwiftUI
import Foundation

/// The six immutable component types that form the foundation of Axiom architecture
@frozen
public enum ComponentType: Int, CaseIterable, CustomStringConvertible {
    /// Manages external system access (e.g., camera, location, network)
    case capability
    
    /// Value type containing domain-specific immutable data
    case state
    
    /// Actor-based container managing state and processing actions
    case client
    
    /// Application-level coordinator managing contexts and navigation
    case orchestrator
    
    /// MainActor-bound coordinator bridging clients and presentations
    case context
    
    /// SwiftUI View with single context binding
    case presentation
    
    public var description: String {
        switch self {
        case .capability:
            return "Capability"
        case .state:
            return "State"
        case .client:
            return "Client"
        case .orchestrator:
            return "Orchestrator"
        case .context:
            return "Context"
        case .presentation:
            return "Presentation"
        }
    }
}

// MARK: - Component Validation Protocols

/// Protocol for Capability component validation
public protocol CapabilityValidatable {
    /// Initialize the capability and establish resource connections
    func initialize() async throws
    
    /// Terminate the capability and clean up resources
    func terminate() async
    
    /// Check if the capability is currently available for use
    var isAvailable: Bool { get }
}

/// Protocol for State component validation
/// States must be value types with no dependencies
public protocol StateValidatable: Sendable {
    // Marker protocol for value type validation
    // The Sendable requirement enforces thread-safety
}

/// Protocol for Client component validation
/// Clients must be actor-isolated with proper state and action management
public protocol ClientValidatable: Actor {
    /// The state type managed by this client
    associatedtype StateType
    
    /// The action type processed by this client
    associatedtype ActionType
}

/// Protocol for Context component validation
/// Contexts must be MainActor-isolated and observe exactly one Client
public protocol ContextValidatable: ObservableObject {
    /// The client type observed by this context
    associatedtype ClientType: ClientValidatable
    
    /// The client instance being observed
    var client: ClientType { get }
}

/// Protocol for Orchestrator component validation
/// Orchestrators must be MainActor-isolated and manage Context lifecycle
public protocol OrchestratorValidatable: ObservableObject {
    /// Initialize the orchestrator and set up navigation
    func initialize() async throws
    
    /// Terminate the orchestrator and clean up resources
    func terminate() async
}

/// Protocol for Presentation component validation
/// Presentations must be SwiftUI Views with single Context binding
public protocol PresentationValidatable: View {
    /// The context type bound to this presentation
    associatedtype ContextType: ContextValidatable
}

// MARK: - Component Validation Infrastructure

/// Component registration and validation system
public actor ComponentRegistry {
    private var registeredComponents: [String: ComponentRegistration] = [:]
    
    /// Register a component for validation
    public func register<T>(_ component: T, type: ComponentType, id: String = UUID().uuidString) async throws {
        let registration = ComponentRegistration(
            id: id,
            type: type,
            component: component,
            registeredAt: Date()
        )
        
        try await validateComponent(registration)
        registeredComponents[id] = registration
    }
    
    /// Validate component against type constraints
    private func validateComponent(_ registration: ComponentRegistration) async throws {
        switch registration.type {
        case .capability:
            guard registration.component is any CapabilityValidatable else {
                throw ComponentValidationError.invalidCapability(
                    "Component does not conform to CapabilityValidatable protocol"
                )
            }
        case .state:
            guard registration.component is any StateValidatable else {
                throw ComponentValidationError.invalidState(
                    "Component does not conform to StateValidatable protocol"
                )
            }
        case .client:
            guard registration.component is any ClientValidatable else {
                throw ComponentValidationError.invalidClient(
                    "Component does not conform to ClientValidatable protocol"
                )
            }
        case .context:
            guard registration.component is any ContextValidatable else {
                throw ComponentValidationError.invalidContext(
                    "Component does not conform to ContextValidatable protocol"
                )
            }
        case .orchestrator:
            guard registration.component is any OrchestratorValidatable else {
                throw ComponentValidationError.invalidOrchestrator(
                    "Component does not conform to OrchestratorValidatable protocol"
                )
            }
        case .presentation:
            guard registration.component is any PresentationValidatable else {
                throw ComponentValidationError.invalidPresentation(
                    "Component does not conform to PresentationValidatable protocol"
                )
            }
        }
    }
    
    /// Get all registered components of a specific type
    public func getComponents(ofType type: ComponentType) async -> [ComponentRegistration] {
        registeredComponents.values.filter { $0.type == type }
    }
}

/// Component registration information
public struct ComponentRegistration {
    public let id: String
    public let type: ComponentType
    public let component: Any
    public let registeredAt: Date
}

/// Component validation errors
public enum ComponentValidationError: Error, LocalizedError {
    case invalidCapability(String)
    case invalidState(String)
    case invalidClient(String)
    case invalidContext(String)
    case invalidOrchestrator(String)
    case invalidPresentation(String)
    case lifecycleViolation(String)
    case dependencyViolation(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCapability(let message):
            return "Invalid Capability: \(message)"
        case .invalidState(let message):
            return "Invalid State: \(message)"
        case .invalidClient(let message):
            return "Invalid Client: \(message)"
        case .invalidContext(let message):
            return "Invalid Context: \(message)"
        case .invalidOrchestrator(let message):
            return "Invalid Orchestrator: \(message)"
        case .invalidPresentation(let message):
            return "Invalid Presentation: \(message)"
        case .lifecycleViolation(let message):
            return "Lifecycle Violation: \(message)"
        case .dependencyViolation(let message):
            return "Dependency Violation: \(message)"
        }
    }
}