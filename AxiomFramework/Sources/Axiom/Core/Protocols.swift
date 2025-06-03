import SwiftUI
import Observation

// MARK: - Core Protocol Foundation

/// Client protocol - Actor-based state management with single ownership
/// One client owns one state (1:1 relationship enforced)
public protocol Client: Actor {
    associatedtype State: Axiom.State
    
    /// The single state instance owned by this client
    var state: State { get }
    
    /// Update state with automatic observation
    func updateState(_ transform: (inout State) -> Void) async
}

/// Context protocol - Client orchestration and SwiftUI integration
/// Manages client relationships and coordinates cross-cutting concerns
/// Can depend on any clients and read any states for orchestration
@MainActor
public protocol Context: ObservableObject {
    /// Derived state for presentation layer
    associatedtype State: Axiom.State
    
    /// Actions available to presentation layer
    associatedtype Actions
    
    /// Current derived state for presentation
    var state: State { get }
    
    /// Actions that presentation can trigger
    var actions: Actions { get }
    
    /// Capability validation
    var capabilities: [any Capability] { get }
    
    /// Contexts can depend on any clients for orchestration
    /// Specific client dependencies are defined by each context implementation
}

/// Presentation protocol - SwiftUI view with 1:1 context binding
/// Enforces single view-context relationship
public protocol Presentation: View {
    associatedtype ContextType: Context
    
    /// Required context binding
    var context: ContextType { get }
}

/// State protocol - Immutable value objects
/// Pure data structures without behavior
public protocol State: Sendable, Equatable {
    /// Required for all state types
    init()
}

/// Capability protocol - Runtime validation
/// Defines system capabilities and permissions
public protocol Capability: CustomStringConvertible {
    /// Unique capability identifier
    var id: String { get }
    
    /// Check if capability is available
    func isAvailable() -> Bool
}

/// Application protocol - Entry point and lifecycle
/// Manages application configuration and setup
@MainActor
public protocol Application {
    /// Configure application with framework
    func configure() async throws
    
    /// Application entry point
    static func main() async throws
}