import Foundation
import AxiomCore

/// Central registry for managing all capabilities in the system
public actor AxiomCapabilityRegistry {
    public static let shared = AxiomCapabilityRegistry()
    
    private var registrations: [String: AxiomCapabilityRegistration] = [:]
    private var categories: [String: Set<String>] = [:]
    private let registrationLock = AsyncSemaphore(value: 1)
    
    private init() {}
    
    /// Register a capability with the registry
    public func register<C: AxiomCapability>(
        _ capability: C,
        requirements: Set<AxiomCapabilityDiscoveryService.Requirement> = [],
        category: String? = nil,
        validator: @escaping @Sendable () async -> Bool = { true },
        metadata: AxiomCapabilityMetadata? = nil
    ) async throws {
        await registrationLock.wait()
        defer { Task { await registrationLock.signal() } }
        
        let identifier = String(describing: type(of: capability))
        
        // Create default metadata if none provided
        let capabilityMetadata = metadata ?? AxiomCapabilityMetadata(
            name: identifier,
            description: "AxiomCapability: \(identifier)",
            version: "1.0.0",
            category: category
        )
        
        // Create registration
        let registration = AxiomCapabilityRegistration(
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
        await AxiomCapabilityDiscoveryService.shared.register(
            capability: capability,
            identifier: identifier,
            requirements: requirements,
            validator: validator,
            metadata: capabilityMetadata
        )
        
        // Notify discovery service
        let discoveryRegistration = AxiomCapabilityDiscoveryService.AxiomCapabilityRegistration(
            identifier: registration.identifier,
            capability: registration.capability,
            requirements: [],
            validator: { true },
            metadata: registration.metadata
        )
        await AxiomCapabilityDiscoveryService.shared.capabilityRegistered(discoveryRegistration)
    }
    
    /// Get capabilities in a specific category
    public func capabilities(in category: String) -> [any AxiomCapability] {
        guard let identifiers = categories[category] else { return [] }
        
        return identifiers.compactMap { identifier in
            registrations[identifier]?.capability
        }
    }
    
    /// Get all registered capabilities
    public func allCapabilities() async -> [AxiomCapabilityInfo] {
        var results: [AxiomCapabilityInfo] = []
        for registration in registrations.values {
            let isAvailable = await AxiomCapabilityDiscoveryService.shared.hasAxiomCapability(registration.identifier)
            results.append(AxiomCapabilityInfo(
                identifier: registration.identifier,
                name: registration.metadata.name ?? "Unknown",
                description: registration.metadata.description,
                category: registration.metadata.category ?? "General",
                isAvailable: isAvailable
            ))
        }
        return results
    }
    
    /// Get all available categories
    public func getAllCategories() -> [String] {
        return Array(categories.keys).sorted()
    }
    
    /// Get capability by identifier
    public func capability(withId identifier: String) -> (any AxiomCapability)? {
        return registrations[identifier]?.capability
    }
    
    /// Check if a capability is registered
    public func isRegistered(identifier: String) -> Bool {
        return registrations[identifier] != nil
    }
    
    /// Unregister a capability
    public func unregister(identifier: String) async {
        await registrationLock.wait()
        defer { Task { await registrationLock.signal() } }
        
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
        await AxiomCapabilityDiscoveryService.shared.capabilityBecameUnavailable(identifier)
    }
    
    /// Get registration details for a capability
    public func registration(for identifier: String) -> AxiomCapabilityRegistration? {
        return registrations[identifier]
    }
    
    /// Get capabilities by metadata criteria
    public func capabilities(matching criteria: AxiomCapabilitySearchCriteria) async -> [AxiomCapabilityInfo] {
        var results: [AxiomCapabilityInfo] = []
        for registration in registrations.values {
            if await criteria.matches(registration) {
                let isAvailable = await AxiomCapabilityDiscoveryService.shared.hasAxiomCapability(registration.identifier)
                results.append(AxiomCapabilityInfo(
                    identifier: registration.identifier,
                    name: registration.metadata.name ?? "Unknown",
                    description: registration.metadata.description,
                    category: registration.metadata.category ?? "General",
                    isAvailable: isAvailable
                ))
            }
        }
        return results
    }
    
    /// Activate a capability by identifier
    public func activateAxiomCapability(_ identifier: String) async throws {
        guard let registration = registrations[identifier] else {
            throw AxiomError.capabilityError(.unavailable("AxiomCapability not found: \(identifier)"))
        }
        
        // Try to activate the capability
        do {
            try await registration.capability.activate()
        } catch {
            throw AxiomError.capabilityError(.initializationFailed("Failed to activate capability \(identifier): \(error.localizedDescription)"))
        }
    }
    
    /// Get all capabilities with their current availability status
    public func getAllCapabilities() async -> [String: Bool] {
        var result: [String: Bool] = [:]
        
        for (identifier, registration) in registrations {
            let isAvailable = await registration.capability.isAvailable
            result[identifier] = isAvailable
        }
        
        return result
    }
}

// MARK: - AxiomCapability Registration

public struct AxiomCapabilityRegistration: @unchecked Sendable {
    public let identifier: String
    public let capability: any AxiomCapability
    public let requirements: Set<AxiomCapabilityDiscoveryService.Requirement>
    public let validator: @Sendable () async -> Bool
    public let metadata: AxiomCapabilityMetadata
    
    public init(
        identifier: String,
        capability: any AxiomCapability,
        requirements: Set<AxiomCapabilityDiscoveryService.Requirement>,
        validator: @escaping @Sendable () async -> Bool,
        metadata: AxiomCapabilityMetadata
    ) {
        self.identifier = identifier
        self.capability = capability
        self.requirements = requirements
        self.validator = validator
        self.metadata = metadata
    }
}

// MARK: - AxiomCapability Info

public struct AxiomCapabilityInfo: Sendable {
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

public struct AxiomCapabilitySearchCriteria: Sendable {
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
    
    public func matches(_ registration: AxiomCapabilityRegistration) async -> Bool {
        // Check category
        if let requiredCategory = category,
           registration.metadata.category != requiredCategory {
            return false
        }
        
        // Check name pattern
        if let pattern = namePattern,
           let name = registration.metadata.name,
           !name.lowercased().contains(pattern.lowercased()) {
            return false
        }
        
        // Check version (simplified string comparison)
        if let minVersion = minimumVersion,
           registration.metadata.version < minVersion {
            return false
        }
        
        // Check availability if required
        if onlyAvailable {
            let isAvailable = await AxiomCapabilityDiscoveryService.shared.hasAxiomCapability(registration.identifier)
            if !isAvailable {
                return false
            }
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

// MARK: - AxiomCapability Bootstrap

/// Bootstrap helper for automatic capability registration
public struct AxiomCapabilityBootstrap {
    
    /// Register all built-in system capabilities
    public static func registerSystemCapabilities() async throws {
        _ = AxiomCapabilityRegistry.shared
        
        // Network capability - simplified for now
        /*
        let networkAxiomCapability = NetworkAxiomCapability()
        try await registry.register(
            networkAxiomCapability,
            category: "System",
            validator: { await networkAxiomCapability.isAvailable },
            metadata: AxiomCapabilityMetadata(
                name: "Network",
                description: "Network connectivity capability",
                version: "1.0.0",
                category: "System"
            )
        )
        */
    }
    
    /// Register capability using type-based discovery
    public static func register<T: AxiomCapability>(_ type: T.Type) async throws {
        let capability = try await createAxiomCapability(of: type)
        try await AxiomCapabilityRegistry.shared.register(capability)
    }
    
    /// Create capability instance based on type
    private static func createAxiomCapability<T: AxiomCapability>(of type: T.Type) async throws -> T {
        // Throw error instead of crashing
        throw AxiomError.capabilityError(.initializationFailed("AxiomCapability auto-creation not implemented for type: \(type)"))
    }
}

// MARK: - Registrable AxiomCapability Protocol

/// Protocol for capabilities that can self-register
public protocol RegistrableAxiomCapability: AxiomCapability {
    static var defaultCategory: String? { get }
    static var defaultRequirements: Set<AxiomCapabilityDiscoveryService.Requirement> { get }
    static var metadata: AxiomCapabilityMetadata { get }
    
    /// Register this capability type with the registry
    static func register() async throws
}

// MARK: - Default Implementations

extension RegistrableAxiomCapability {
    public static var defaultCategory: String? { nil }
    public static var defaultRequirements: Set<AxiomCapabilityDiscoveryService.Requirement> { [] }
    
    public static func register() async throws {
        // This would create an instance and register it
        // Implementation would depend on capability-specific initialization
        let instance = try await createInstance()
        try await AxiomCapabilityRegistry.shared.register(
            instance,
            requirements: defaultRequirements,
            category: defaultCategory,
            metadata: metadata
        )
    }
    
    private static func createInstance() async throws -> Self {
        // Default implementation - would be overridden by specific capabilities
        throw AxiomError.capabilityError(.initializationFailed("createInstance() must be implemented by capability: \(Self.self)"))
    }
}