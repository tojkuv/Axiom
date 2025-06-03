import Foundation

// MARK: - Axiom Error

/// Base error type for Axiom framework
public enum AxiomError: Error, LocalizedError, Sendable {
    case invalidState(String)
    case invalidConfiguration(String)
    case capabilityUnavailable(String)
    case clientError(String)
    case contextError(String)
    case presentationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidState(let message):
            return "Invalid State: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid Configuration: \(message)"
        case .capabilityUnavailable(let capability):
            return "Capability Unavailable: \(capability)"
        case .clientError(let message):
            return "Client Error: \(message)"
        case .contextError(let message):
            return "Context Error: \(message)"
        case .presentationError(let message):
            return "Presentation Error: \(message)"
        }
    }
}