import Foundation

// MARK: - Capability Validation

/// Configuration for capability validation
public struct CapabilityValidationConfig: Sendable {
    public let enableRuntimeValidation: Bool
    public let strictMode: Bool
    public let allowDevelopmentCapabilities: Bool
    
    public static let `default` = CapabilityValidationConfig(
        enableRuntimeValidation: true,
        strictMode: false,
        allowDevelopmentCapabilities: true
    )
    
    public static let production = CapabilityValidationConfig(
        enableRuntimeValidation: true,
        strictMode: true,
        allowDevelopmentCapabilities: false
    )
    
    public init(
        enableRuntimeValidation: Bool = true,
        strictMode: Bool = false,
        allowDevelopmentCapabilities: Bool = true
    ) {
        self.enableRuntimeValidation = enableRuntimeValidation
        self.strictMode = strictMode
        self.allowDevelopmentCapabilities = allowDevelopmentCapabilities
    }
}

// MARK: - Graceful Degradation

/// Defines fallback behavior when capabilities are unavailable
public struct GracefulDegradation: Sendable {
    public let capability: Capability
    public let alternatives: [Capability]
    public let fallbackBehavior: FallbackBehavior
    
    public enum FallbackBehavior: Sendable {
        case useAlternative
        case disableFeature
        case showWarning(String)
        case custom(@Sendable () async -> Void)
    }
    
    public init(
        capability: Capability,
        alternatives: [Capability] = [],
        fallbackBehavior: FallbackBehavior
    ) {
        self.capability = capability
        self.alternatives = alternatives
        self.fallbackBehavior = fallbackBehavior
    }
    
    // MARK: Convenience Initializers
    
    /// Creates degradation that uses the first available alternative
    public static func useAlternatives(
        for capability: Capability,
        alternatives: [Capability]
    ) -> GracefulDegradation {
        GracefulDegradation(
            capability: capability,
            alternatives: alternatives,
            fallbackBehavior: .useAlternative
        )
    }
    
    /// Creates degradation that disables the feature
    public static func disableFeature(
        for capability: Capability
    ) -> GracefulDegradation {
        GracefulDegradation(
            capability: capability,
            fallbackBehavior: .disableFeature
        )
    }
    
    /// Creates degradation that shows a warning
    public static func showWarning(
        for capability: Capability,
        message: String
    ) -> GracefulDegradation {
        GracefulDegradation(
            capability: capability,
            fallbackBehavior: .showWarning(message)
        )
    }
}

// MARK: - Capability Context

/// Context information for capability validation
public struct CapabilityContext: Sendable {
    public let component: ComponentID
    public let operation: String
    public let metadata: [String: String]
    
    public init(
        component: ComponentID,
        operation: String,
        metadata: [String: String] = [:]
    ) {
        self.component = component
        self.operation = operation
        self.metadata = metadata
    }
}

// MARK: - Capability Declaration

/// Declarative capability requirements for a component
public struct CapabilityDeclaration: Sendable {
    public let required: Set<Capability>
    public let optional: Set<Capability>
    public let domains: Set<CapabilityDomain>
    
    public init(
        required: Set<Capability> = [],
        optional: Set<Capability> = [],
        domains: Set<CapabilityDomain> = []
    ) {
        self.required = required
        self.optional = optional
        self.domains = domains
    }
    
    /// All capabilities (required + optional + from domains)
    public var allCapabilities: Set<Capability> {
        var all = required.union(optional)
        for domain in domains {
            all = all.union(domain.capabilities)
        }
        return all
    }
    
    /// Validates that all required capabilities are available
    public func validate(with manager: CapabilityManager) async throws {
        // Validate required capabilities
        for capability in required {
            try await manager.validate(capability)
        }
        
        // Validate domain capabilities
        for domain in domains {
            for capability in domain.capabilities {
                try await manager.validate(capability)
            }
        }
    }
}

// MARK: - Capability Annotations

/// Protocol for types that declare their capability requirements
public protocol CapabilityAware {
    static var capabilities: CapabilityDeclaration { get }
}

/// Protocol for types that can validate capabilities
public protocol CapabilityValidating {
    func validateCapabilities() async throws
}