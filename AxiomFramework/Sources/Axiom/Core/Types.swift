import Foundation

// MARK: - Core Types

/// Basic capability implementation
public struct BasicCapability: Capability {
    public let id: String
    private let available: Bool
    
    public init(id: String, available: Bool = true) {
        self.id = id
        self.available = available
    }
    
    public func isAvailable() -> Bool {
        available
    }
    
    public var description: String {
        "\(id) (\(available ? "available" : "unavailable"))"
    }
}

// MARK: - Common Capabilities

extension BasicCapability {
    /// Network access capability
    public static let network = BasicCapability(id: "axiom.capability.network")
    
    /// File system access capability
    public static let fileSystem = BasicCapability(id: "axiom.capability.filesystem")
    
    /// Camera access capability
    public static let camera = BasicCapability(id: "axiom.capability.camera")
    
    /// Location access capability
    public static let location = BasicCapability(id: "axiom.capability.location")
}

// MARK: - Type Aliases

/// State update closure type
public typealias StateUpdate<S: State> = (inout S) -> Void

/// Async state update closure type
public typealias AsyncStateUpdate<S: State> = (inout S) async throws -> Void