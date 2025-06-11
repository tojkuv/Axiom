import Foundation

// MARK: - Dependency Types

/// Type of dependency relationship between capabilities
public enum DependencyType: Equatable, Sendable {
    case required    // Must be available for capability to function
    case optional    // Enhances functionality but not required
    case exclusive   // Cannot coexist with this capability
    case composable  // Can be combined for enhanced features
    
    public var isMandatory: Bool {
        switch self {
        case .required: return true
        case .optional, .exclusive, .composable: return false
        }
    }
    
    public var canCoexist: Bool {
        switch self {
        case .exclusive: return false
        case .required, .optional, .composable: return true
        }
    }
    
    public var canCombine: Bool {
        switch self {
        case .composable: return true
        case .required, .optional, .exclusive: return false
        }
    }
}

// MARK: - Dependency Protocol

/// Protocol for capability dependencies (legacy)
public protocol LegacyCapabilityDependency: Sendable {
    var id: String { get }
    var type: DependencyType { get }
}

/// Basic implementation of capability dependency (legacy)
public struct LegacyBasicCapabilityDependency: LegacyCapabilityDependency {
    public let id: String
    public let type: DependencyType
    
    public init(id: String, type: DependencyType) {
        self.id = id
        self.type = type
    }
}

// MARK: - Legacy Composable Capability Protocol (deprecated - use CapabilityCompositionPatterns.swift)

// MARK: - Resource Priority

/// Priority levels for capability resource allocation
public enum CapabilityResourcePriority: Int, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3
    
    public static func < (lhs: CapabilityResourcePriority, rhs: CapabilityResourcePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Dependency Resolver

/// Resolves capability dependencies and determines initialization order
public actor CapabilityDependencyResolver {
    private var capabilities: [String: any DomainCapability] = [:]
    private var dependencyGraph: [String: Set<String>] = [:]
    
    public init() {}
    
    /// Register a capability with its dependencies
    public func registerCapability(_ id: String, dependencies: [String]) async {
        dependencyGraph[id] = Set(dependencies)
    }
    
    /// Add dependencies for a capability
    public func addDependencies(for id: String, dependencies: [String]) async {
        dependencyGraph[id] = Set(dependencies)
    }
    
    /// Resolve dependencies for a capability and return initialization order
    public func resolveDependencies(for capabilityId: String) async throws -> [String] {
        var resolved: [String] = []
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        
        try await topologicalSort(
            capabilityId: capabilityId,
            visited: &visited,
            recursionStack: &recursionStack,
            resolved: &resolved
        )
        
        return resolved
    }
    
    /// Resolve initialization order for all capabilities
    public func resolveOrder() async throws -> [String] {
        var resolved: [String] = []
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        
        for capabilityId in dependencyGraph.keys {
            if !visited.contains(capabilityId) {
                try await topologicalSort(
                    capabilityId: capabilityId,
                    visited: &visited,
                    recursionStack: &recursionStack,
                    resolved: &resolved
                )
            }
        }
        
        return resolved
    }
    
    private func topologicalSort(
        capabilityId: String,
        visited: inout Set<String>,
        recursionStack: inout Set<String>,
        resolved: inout [String]
    ) async throws {
        // Check for circular dependency
        guard !recursionStack.contains(capabilityId) else {
            throw CapabilityError.initializationFailed("Circular dependency detected involving \(capabilityId)")
        }
        
        // Skip if already visited
        guard !visited.contains(capabilityId) else {
            return
        }
        
        // Mark as being processed
        recursionStack.insert(capabilityId)
        
        // Process dependencies first
        if let dependencies = dependencyGraph[capabilityId] {
            for dependency in dependencies {
                try await topologicalSort(
                    capabilityId: dependency,
                    visited: &visited,
                    recursionStack: &recursionStack,
                    resolved: &resolved
                )
            }
        }
        
        // Mark as visited and remove from recursion stack
        visited.insert(capabilityId)
        recursionStack.remove(capabilityId)
        
        // Add to resolved list
        resolved.append(capabilityId)
    }
}

// MARK: - Resource Pool Management

/// Manages shared resources across capabilities
public actor CapabilityResourcePool {
    private var resources: [String: any CapabilityResource] = [:]
    private var allocations: [String: [AllocationRecord]] = [:]
    private var reservations: [String: [ReservationRecord]] = [:]
    
    private struct AllocationRecord {
        let capabilityId: String
        let priority: CapabilityResourcePriority
        let timestamp: Date
    }
    
    private struct ReservationRecord {
        let capabilityId: String
        let priority: CapabilityResourcePriority
        let expiresAt: Date
    }
    
    public init() {}
    
    /// Register a resource with the pool
    public func registerResource<T: CapabilityResource>(_ resource: T, withId id: String) async {
        resources[id] = resource
        allocations[id] = []
        reservations[id] = []
    }
    
    /// Request a resource for a capability
    public func requestResource(
        resourceId: String,
        capabilityId: String,
        priority: CapabilityResourcePriority
    ) async throws {
        guard let resource = resources[resourceId] else {
            throw CapabilityError.resourceUnavailable("Resource \(resourceId) not found")
        }
        
        // Check if resource is available
        let isAvailable = await resource.isAvailable
        
        // Get current allocations
        var currentAllocations = allocations[resourceId] ?? []
        
        // If resource is limited and not available, check if we can preempt
        if !isAvailable && !currentAllocations.isEmpty {
            // Find lowest priority allocation
            let lowestPriority = currentAllocations.min { $0.priority < $1.priority }
            
            // Can only preempt if new request has higher priority
            if let lowest = lowestPriority, priority > lowest.priority {
                // Preempt the lowest priority allocation
                currentAllocations.removeAll { $0.capabilityId == lowest.capabilityId }
                await resource.release()
            } else {
                throw CapabilityError.resourceUnavailable("Resource \(resourceId) not available")
            }
        }
        
        // Allocate resource
        try await resource.allocate()
        
        // Record allocation
        currentAllocations.append(AllocationRecord(
            capabilityId: capabilityId,
            priority: priority,
            timestamp: Date()
        ))
        allocations[resourceId] = currentAllocations
    }
    
    /// Release a resource
    public func releaseResource(resourceId: String, capabilityId: String) async {
        guard let resource = resources[resourceId] else {
            return
        }
        
        // Remove allocation record
        var currentAllocations = allocations[resourceId] ?? []
        let hadAllocation = currentAllocations.contains { $0.capabilityId == capabilityId }
        currentAllocations.removeAll { $0.capabilityId == capabilityId }
        allocations[resourceId] = currentAllocations
        
        // Release resource if we had an allocation
        if hadAllocation {
            await resource.release()
        }
    }
    
    /// Reserve a resource for future use
    public func reserveResource(
        resourceId: String,
        capabilityId: String,
        duration: TimeInterval
    ) async throws {
        guard resources[resourceId] != nil else {
            throw CapabilityError.resourceUnavailable("Resource \(resourceId) not found")
        }
        
        // Add reservation
        var currentReservations = reservations[resourceId] ?? []
        currentReservations.append(ReservationRecord(
            capabilityId: capabilityId,
            priority: .medium,
            expiresAt: Date().addingTimeInterval(duration)
        ))
        reservations[resourceId] = currentReservations
    }
    
    /// Check if a resource is allocated to a capability
    public func isResourceAllocated(resourceId: String, to capabilityId: String) async -> Bool {
        let currentAllocations = allocations[resourceId] ?? []
        return currentAllocations.contains { $0.capabilityId == capabilityId }
    }
}

// MARK: - Capability Hierarchy Protocol

/// Protocol for managing hierarchical capability relationships
public protocol CapabilityHierarchyManager: Actor {
    associatedtype ParentCapability: DomainCapability
    associatedtype ChildCapability: DomainCapability
    
    var parent: ParentCapability? { get async }
    var children: [ChildCapability] { get async }
    
    func addChild(_ child: ChildCapability) async throws
    func removeChild(_ child: ChildCapability) async
    func propagateStateChange(_ state: CapabilityState) async
}

// MARK: - Aggregated Capability Protocol

/// Protocol for capabilities that aggregate multiple other capabilities
public protocol AggregatedCapability: DomainCapability {
    var capabilities: [String: any DomainCapability] { get async }
    
    func addCapability(_ capability: any DomainCapability, withId id: String) async throws
    func removeCapability(withId id: String) async
    func getCapability<T: DomainCapability>(withId id: String, as type: T.Type) async -> T?
}

// MARK: - Adaptive Capability Protocol

/// Protocol for capabilities that adapt to environment changes
public protocol AdaptiveCapability<BaseCapability>: DomainCapability {
    associatedtype BaseCapability: DomainCapability
    
    var environment: CapabilityEnvironment { get async }
    func adaptToEnvironment() async
    func updateConfiguration(_ configuration: BaseCapability.ConfigurationType) async
}

// MARK: - Capability Criteria

/// Criteria for discovering capabilities
public struct CapabilityCriteria {
    public let type: CapabilityType?
    public let state: CapabilityState?
    public let tags: Set<String>
    
    public init(
        type: CapabilityType? = nil,
        state: CapabilityState? = nil,
        tags: Set<String> = []
    ) {
        self.type = type
        self.state = state
        self.tags = tags
    }
    
    public func matches<T: DomainCapability>(_ capability: T) async -> Bool {
        // Check type
        if let type = type, capability.capabilityType != type {
            return false
        }
        
        // Check state
        if let state = state, await capability.state != state {
            return false
        }
        
        // Check tags if capability supports them
        // For now, return true if all other criteria match
        return true
    }
}

// MARK: - Versioning Support

/// Semantic version for capabilities
public struct SemanticVersion: Comparable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

/// Protocol for versioned capabilities
public protocol VersionedCapability: DomainCapability {
    var version: SemanticVersion { get }
    var minimumSupportedVersion: SemanticVersion { get }
    
    func migrate(from oldVersion: SemanticVersion) async throws
    func isCompatible(with version: SemanticVersion) -> Bool
}