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