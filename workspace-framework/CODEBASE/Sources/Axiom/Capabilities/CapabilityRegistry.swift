import Foundation

/// Central registry for managing all capabilities in the system
public actor CapabilityRegistry {
    public static let shared = CapabilityRegistry()
    
    private var registrations: [String: CapabilityRegistration] = [:]
    private var categories: [String: Set<String>] = [:]
    private let registrationLock = AsyncSemaphore(value: 1)
    
    private init() {}
    
    /// Register a capability with the registry
    public func register<C: Capability>(
        _ capability: C,
        requirements: Set<CapabilityDiscoveryService.Requirement> = [],
        category: String? = nil,
        validator: @escaping () async -> Bool = { true },
        metadata: CapabilityMetadata? = nil
    ) async throws {
        await registrationLock.wait()
        defer { registrationLock.signal() }
        
        let identifier = String(describing: type(of: capability))
        
        // Create default metadata if none provided
        let capabilityMetadata = metadata ?? CapabilityMetadata(
            name: identifier,
            description: "Capability: \(identifier)",
            version: "1.0.0",
            category: category
        )
        
        // Create registration
        let registration = CapabilityRegistration(
            identifier: identifier,
            capability: capability,
            requirements: requirements,
            validator: validator,
            metadata: capabilityMetadata
        )
        
        // Store registration
        registrations[identifier] = registration
        
        // Update category index
        if let category = category {
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.insert(identifier)
        }
        
        // Register with discovery service
        await CapabilityDiscoveryService.shared.register(
            capability: capability,
            identifier: identifier,
            requirements: requirements,
            validator: validator,
            metadata: capabilityMetadata
        )
        
        // Notify discovery service
        await CapabilityDiscoveryService.shared.capabilityRegistered(registration)
    }
    
    /// Get capabilities in a specific category
    public func capabilities(in category: String) -> [any Capability] {
        guard let identifiers = categories[category] else { return [] }
        
        return identifiers.compactMap { identifier in
            registrations[identifier]?.capability
        }
    }
    
    /// Get all registered capabilities
    public func allCapabilities() -> [CapabilityInfo] {
        return registrations.values.map { registration in
            CapabilityInfo(
                identifier: registration.identifier,
                name: registration.metadata.name,
                description: registration.metadata.description,
                category: registration.metadata.category,
                isAvailable: CapabilityDiscoveryService.shared.hasCapability(registration.identifier)
            )
        }
    }
    
    /// Get all available categories
    public func categories() -> [String] {
        return Array(categories.keys).sorted()
    }
    
    /// Get capability by identifier
    public func capability(withId identifier: String) -> (any Capability)? {
        return registrations[identifier]?.capability
    }
    
    /// Check if a capability is registered
    public func isRegistered(identifier: String) -> Bool {
        return registrations[identifier] != nil
    }
    
    /// Unregister a capability
    public func unregister(identifier: String) async {
        await registrationLock.wait()
        defer { registrationLock.signal() }
        
        guard let registration = registrations.removeValue(forKey: identifier) else {
            return
        }
        
        // Remove from category index
        if let category = registration.metadata.category {
            categories[category]?.remove(identifier)
            if categories[category]?.isEmpty == true {
                categories.removeValue(forKey: category)
            }
        }
        
        // Notify discovery service
        await CapabilityDiscoveryService.shared.capabilityBecameUnavailable(identifier)
    }
    
    /// Get registration details for a capability
    public func registration(for identifier: String) -> CapabilityRegistration? {
        return registrations[identifier]
    }
    
    /// Get capabilities by metadata criteria
    public func capabilities(matching criteria: CapabilitySearchCriteria) -> [CapabilityInfo] {
        return registrations.values.compactMap { registration in
            if criteria.matches(registration) {
                return CapabilityInfo(
                    identifier: registration.identifier,
                    name: registration.metadata.name,
                    description: registration.metadata.description,
                    category: registration.metadata.category,
                    isAvailable: CapabilityDiscoveryService.shared.hasCapability(registration.identifier)
                )
            }
            return nil
        }
    }
}

// MARK: - Capability Registration

public struct CapabilityRegistration {
    public let identifier: String
    public let capability: any Capability
    public let requirements: Set<CapabilityDiscoveryService.Requirement>
    public let validator: () async -> Bool
    public let metadata: CapabilityMetadata
    
    public init(
        identifier: String,
        capability: any Capability,
        requirements: Set<CapabilityDiscoveryService.Requirement>,
        validator: @escaping () async -> Bool,
        metadata: CapabilityMetadata
    ) {
        self.identifier = identifier
        self.capability = capability
        self.requirements = requirements
        self.validator = validator
        self.metadata = metadata
    }
}

// MARK: - Capability Info

public struct CapabilityInfo: Sendable {
    public let identifier: String
    public let name: String
    public let description: String
    public let category: String?
    public let isAvailable: Bool
    
    public init(
        identifier: String,
        name: String,
        description: String,
        category: String?,
        isAvailable: Bool
    ) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.category = category
        self.isAvailable = isAvailable
    }
}

// MARK: - Search Criteria

public struct CapabilitySearchCriteria {
    public let namePattern: String?
    public let category: String?
    public let requiredTags: Set<String>
    public let excludedTags: Set<String>
    public let minimumVersion: String?
    public let onlyAvailable: Bool
    
    public init(
        namePattern: String? = nil,
        category: String? = nil,
        requiredTags: Set<String> = [],
        excludedTags: Set<String> = [],
        minimumVersion: String? = nil,
        onlyAvailable: Bool = false
    ) {
        self.namePattern = namePattern
        self.category = category
        self.requiredTags = requiredTags
        self.excludedTags = excludedTags
        self.minimumVersion = minimumVersion
        self.onlyAvailable = onlyAvailable
    }
    
    public func matches(_ registration: CapabilityRegistration) -> Bool {
        // Check category
        if let requiredCategory = category,
           registration.metadata.category != requiredCategory {
            return false
        }
        
        // Check name pattern
        if let pattern = namePattern,
           !registration.metadata.name.lowercased().contains(pattern.lowercased()) {
            return false
        }
        
        // Check version (simplified string comparison)
        if let minVersion = minimumVersion,
           registration.metadata.version < minVersion {
            return false
        }
        
        // Check availability if required
        if onlyAvailable &&
           !CapabilityDiscoveryService.shared.hasCapability(registration.identifier) {
            return false
        }
        
        return true
    }
}

// MARK: - AsyncSemaphore

/// Simple async semaphore implementation for capability registry synchronization
public actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    public init(value: Int) {
        self.value = value
    }
    
    public func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    public func signal() {
        if waiters.isEmpty {
            value += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}

// MARK: - Capability Bootstrap

/// Bootstrap helper for automatic capability registration
public struct CapabilityBootstrap {
    
    /// Register all built-in system capabilities
    public static func registerSystemCapabilities() async throws {
        let registry = CapabilityRegistry.shared
        
        // Network capability - simplified for now
        /*
        let networkCapability = NetworkCapability()
        try await registry.register(
            networkCapability,
            category: "System",
            validator: { await networkCapability.isAvailable },
            metadata: CapabilityMetadata(
                name: "Network",
                description: "Network connectivity capability",
                version: "1.0.0",
                category: "System"
            )
        )
        */
    }
    
    /// Register capability using type-based discovery
    public static func register<T: Capability>(_ type: T.Type) async throws {
        let capability = await createCapability(of: type)
        try await CapabilityRegistry.shared.register(capability)
    }
    
    /// Create capability instance based on type
    private static func createCapability<T: Capability>(of type: T.Type) async -> T {
        // This would be implemented based on specific capability initialization requirements
        // For now, we assume capabilities have default initializers
        fatalError("Capability auto-creation not implemented for type: \(type)")
    }
}

// MARK: - Registrable Capability Protocol

/// Protocol for capabilities that can self-register
public protocol RegistrableCapability: Capability {
    static var defaultCategory: String? { get }
    static var defaultRequirements: Set<CapabilityDiscoveryService.Requirement> { get }
    static var metadata: CapabilityMetadata { get }
    
    /// Register this capability type with the registry
    static func register() async throws
}

// MARK: - Default Implementations

extension RegistrableCapability {
    public static var defaultCategory: String? { nil }
    public static var defaultRequirements: Set<CapabilityDiscoveryService.Requirement> { [] }
    
    public static func register() async throws {
        // This would create an instance and register it
        // Implementation would depend on capability-specific initialization
        let instance = try await createInstance()
        try await CapabilityRegistry.shared.register(
            instance,
            requirements: defaultRequirements,
            category: defaultCategory,
            metadata: metadata
        )
    }
    
    private static func createInstance() async throws -> Self {
        // Default implementation - would be overridden by specific capabilities
        fatalError("createInstance() must be implemented by capability: \(Self.self)")
    }
}