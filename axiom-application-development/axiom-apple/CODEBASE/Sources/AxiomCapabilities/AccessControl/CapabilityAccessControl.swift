import Foundation
import AxiomCore

// MARK: - Capability Access Control Protocols

/// Marker protocol for capabilities that operate purely on local device resources
/// These capabilities can only be accessed by Contexts, not Clients
public protocol LocalCapability: DomainCapability {
    /// Indicates this capability operates entirely on local device resources
    static var isLocalCapability: Bool { get }
}

/// Marker protocol for capabilities that interact with external services
/// These capabilities can only be accessed by Clients, not Contexts
public protocol ExternalServiceCapability: DomainCapability {
    /// Indicates this capability requires external service connectivity
    static var isExternalServiceCapability: Bool { get }
}

// MARK: - Default Implementations

extension LocalCapability {
    public static var isLocalCapability: Bool { true }
    public static var isExternalServiceCapability: Bool { false }
}

extension ExternalServiceCapability {
    public static var isLocalCapability: Bool { false }
    public static var isExternalServiceCapability: Bool { true }
}

// MARK: - Access Control Manager

/// Manages and enforces capability access control rules
public actor CapabilityAccessControlManager {
    public static let shared = CapabilityAccessControlManager()
    
    private init() {}
    
    /// Validates if a component can access a specific capability type
    public func validateAccess<T: DomainCapability>(
        capabilityType: T.Type,
        componentType: ComponentType
    ) throws {
        switch componentType {
        case .context:
            // Contexts can only access local capabilities
            if let externalCapabilityType = capabilityType as? ExternalServiceCapability.Type {
                throw CapabilityAccessError.unauthorizedAccess(
                    capability: String(describing: capabilityType),
                    component: "Context",
                    reason: "Contexts cannot access external service capabilities"
                )
            }
            
        case .client:
            // Clients can only access external service capabilities
            if let localCapabilityType = capabilityType as? LocalCapability.Type {
                throw CapabilityAccessError.unauthorizedAccess(
                    capability: String(describing: capabilityType),
                    component: "Client", 
                    reason: "Clients cannot access local device capabilities"
                )
            }
        }
    }
    
    /// Validates capability dependency access rules
    public func validateDependencyAccess<T: DomainCapability, U: DomainCapability>(
        parentCapability: T.Type,
        dependencyCapability: U.Type
    ) throws {
        // External service capabilities can use other external service capabilities
        if parentCapability is ExternalServiceCapability.Type {
            if dependencyCapability is LocalCapability.Type {
                throw CapabilityAccessError.invalidDependency(
                    parent: String(describing: parentCapability),
                    dependency: String(describing: dependencyCapability),
                    reason: "External service capabilities cannot depend on local capabilities"
                )
            }
        }
        
        // Local capabilities can use other local capabilities
        if parentCapability is LocalCapability.Type {
            if dependencyCapability is ExternalServiceCapability.Type {
                throw CapabilityAccessError.invalidDependency(
                    parent: String(describing: parentCapability),
                    dependency: String(describing: dependencyCapability),
                    reason: "Local capabilities cannot depend on external service capabilities"
                )
            }
        }
    }
    
    /// Gets the capability category for a given capability type
    public func getCapabilityCategory<T: DomainCapability>(_ capabilityType: T.Type) -> CapabilityCategory {
        if capabilityType is LocalCapability.Type {
            return .local
        } else if capabilityType is ExternalServiceCapability.Type {
            return .externalService
        } else {
            return .unclassified
        }
    }
    
    /// Lists all capabilities that can be accessed by a component type
    public func getAccessibleCapabilities(for componentType: ComponentType) -> [CapabilityCategory] {
        switch componentType {
        case .context:
            return [.local]
        case .client:
            return [.externalService]
        }
    }
}

// MARK: - Supporting Types

/// Types of components in the Axiom framework
public enum ComponentType: String, Sendable, CaseIterable {
    case context = "context"
    case client = "client"
}

/// Categories of capabilities based on their access patterns
public enum CapabilityCategory: String, Sendable, CaseIterable {
    case local = "local"
    case externalService = "external_service"
    case unclassified = "unclassified"
}

// MARK: - Error Types

/// Errors related to capability access control violations
public enum CapabilityAccessError: Error, LocalizedError {
    case unauthorizedAccess(capability: String, component: String, reason: String)
    case invalidDependency(parent: String, dependency: String, reason: String)
    case capabilityNotClassified(String)
    case accessControlViolation(String)
    
    public var errorDescription: String? {
        switch self {
        case .unauthorizedAccess(let capability, let component, let reason):
            return "Unauthorized access: \(component) cannot access \(capability). \(reason)"
        case .invalidDependency(let parent, let dependency, let reason):
            return "Invalid dependency: \(parent) cannot depend on \(dependency). \(reason)"
        case .capabilityNotClassified(let capability):
            return "Capability not classified: \(capability) must implement either LocalCapability or ExternalServiceCapability"
        case .accessControlViolation(let reason):
            return "Access control violation: \(reason)"
        }
    }
}

// MARK: - Capability Registry

/// Registry for tracking capability classifications and access patterns
public actor CapabilityRegistry {
    public static let shared = CapabilityRegistry()
    
    private var registeredCapabilities: [String: CapabilityRegistration] = [:]
    
    private init() {}
    
    /// Register a capability with its classification
    public func register<T: DomainCapability>(_ capabilityType: T.Type) {
        let name = String(describing: capabilityType)
        let category = CapabilityAccessControlManager.shared.getCapabilityCategory(capabilityType)
        
        registeredCapabilities[name] = CapabilityRegistration(
            name: name,
            type: capabilityType,
            category: category,
            registeredAt: Date()
        )
    }
    
    /// Get registration info for a capability
    public func getRegistration(for capabilityName: String) -> CapabilityRegistration? {
        return registeredCapabilities[capabilityName]
    }
    
    /// Get all registered capabilities by category
    public func getCapabilities(by category: CapabilityCategory) -> [CapabilityRegistration] {
        return registeredCapabilities.values.filter { $0.category == category }
    }
    
    /// Get all registered capabilities
    public func getAllCapabilities() -> [CapabilityRegistration] {
        return Array(registeredCapabilities.values)
    }
}

/// Registration information for a capability
public struct CapabilityRegistration: Sendable {
    public let name: String
    public let type: any DomainCapability.Type
    public let category: CapabilityCategory
    public let registeredAt: Date
    
    public var isLocal: Bool {
        category == .local
    }
    
    public var isExternalService: Bool {
        category == .externalService
    }
}

// MARK: - Access Control Extensions

extension DomainCapability {
    /// Validates access for this capability type
    public static func validateAccess(for componentType: ComponentType) async throws {
        try await CapabilityAccessControlManager.shared.validateAccess(
            capabilityType: self,
            componentType: componentType
        )
    }
    
    /// Gets the category of this capability
    public static func getCategory() async -> CapabilityCategory {
        return await CapabilityAccessControlManager.shared.getCapabilityCategory(self)
    }
    
    /// Registers this capability in the registry
    public static func register() async {
        await CapabilityRegistry.shared.register(self)
    }
}