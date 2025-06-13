import Foundation
import SwiftUI
import Combine

// MARK: - Core Capability Composition Patterns

/// Type-erased capability dependency
public struct AnyCapabilityDependency {
    public let id: String
    public let state: CapabilityState
    
    public init(id: String, state: CapabilityState) {
        self.id = id
        self.state = state
    }
}

/// Protocol for capabilities that can be composed together
public protocol ComposableCapability: DomainCapability {
    associatedtype DependencyType: CapabilityDependency
    
    /// Dependencies required by this capability
    var dependencies: [DependencyType] { get async }
    
    /// Check if all dependencies are satisfied
    func validateDependencies() async throws
    
    /// Handle dependency state changes
    func handleDependencyChange(_ dependency: DependencyType, newState: CapabilityState) async
}

/// Capability dependency specification
public protocol CapabilityDependency: Sendable {
    /// Unique identifier for the dependency
    var id: String { get }
    
    /// Type of dependency
    var type: CapabilityDependencyType { get }
    
    /// Whether this dependency is required
    var isRequired: Bool { get }
    
    /// Minimum version required (if applicable)
    var minimumVersion: String? { get }
}

/// Types of capability dependencies
public enum CapabilityDependencyType: String, Codable, CaseIterable, Sendable {
    case required       // Must be available before this capability can initialize
    case optional       // Enhances functionality but not required
    case exclusive      // Cannot coexist with this capability
    case composable     // Can be combined to create enhanced functionality
}

/// Basic capability dependency implementation
public struct BasicCapabilityDependency: CapabilityDependency {
    public let id: String
    public let type: CapabilityDependencyType
    public let isRequired: Bool
    public let minimumVersion: String?
    
    public init(id: String, type: CapabilityDependencyType, isRequired: Bool = true, minimumVersion: String? = nil) {
        self.id = id
        self.type = type
        self.isRequired = isRequired
        self.minimumVersion = minimumVersion
    }
}

// MARK: - Capability Hierarchy and Inheritance

/// Base class for capability hierarchies
public protocol CapabilityHierarchy {
    associatedtype ParentCapability: DomainCapability
    associatedtype ChildCapability: DomainCapability
    
    /// Parent capability in the hierarchy
    var parent: ParentCapability? { get async }
    
    /// Child capabilities in the hierarchy
    var children: [ChildCapability] { get async }
    
    /// Add a child capability
    func addChild(_ child: ChildCapability) async throws
    
    /// Remove a child capability
    func removeChild(_ child: ChildCapability) async
    
    /// Propagate state changes to children
    func propagateStateChange(_ state: CapabilityState) async
}

/// Hierarchical capability implementation
public actor HierarchicalCapability<Parent: DomainCapability, Child: DomainCapability>: CapabilityHierarchy {
    private weak var _parent: Parent?
    private var _children: [Child] = []
    private let hierarchyRules: HierarchyRules
    
    public init(hierarchyRules: HierarchyRules = HierarchyRules()) {
        self.hierarchyRules = hierarchyRules
    }
    
    public var parent: Parent? {
        get async { _parent }
    }
    
    public var children: [Child] {
        get async { _children }
    }
    
    public func addChild(_ child: Child) async throws {
        // Validate hierarchy rules
        guard _children.count < hierarchyRules.maxChildren else {
            throw CapabilityError.initializationFailed("Maximum children exceeded")
        }
        
        // Check for conflicts
        for existingChild in _children {
            if await areConflicting(child, existingChild) {
                throw CapabilityError.initializationFailed("Conflicting capabilities")
            }
        }
        
        _children.append(child)
        
        // Initialize child if parent is available
        if let parentState = await _parent?.state, parentState == .available {
            try await child.activate()
        }
    }
    
    public func removeChild(_ child: Child) async {
        // Find index using async comparison
        var foundIndex: Int? = nil
        for (index, existingChild) in _children.enumerated() {
            if await areSameCapability(existingChild, child) {
                foundIndex = index
                break
            }
        }
        
        if let index = foundIndex {
            let removedChild = _children.remove(at: index)
            await removedChild.deactivate()
        }
    }
    
    public func propagateStateChange(_ state: CapabilityState) async {
        for child in _children {
            switch state {
            case .available:
                try? await child.activate()
            case .unavailable, .restricted:
                await child.deactivate()
            case .unknown:
                break
            }
        }
    }
    
    private func areConflicting(_ capability1: Child, _ capability2: Child) async -> Bool {
        // Check if capabilities have exclusive dependencies
        // In a real implementation, this would check capability-specific rules
        return false
    }
    
    private func areSameCapability(_ capability1: Child, _ capability2: Child) async -> Bool {
        // In a real implementation, this would compare capability identifiers
        return ObjectIdentifier(capability1) == ObjectIdentifier(capability2)
    }
}

/// Rules for capability hierarchies
public struct HierarchyRules {
    public let maxChildren: Int
    public let allowDynamicAddition: Bool
    public let requireParentInitialization: Bool
    
    public init(maxChildren: Int = 10, allowDynamicAddition: Bool = true, requireParentInitialization: Bool = true) {
        self.maxChildren = maxChildren
        self.allowDynamicAddition = allowDynamicAddition
        self.requireParentInitialization = requireParentInitialization
    }
}

// MARK: - Dependency Resolution
// Note: CapabilityDependencyResolver is defined in CapabilityDependencyResolver.swift

// MARK: - Composition Strategies

/// Strategy for composing capabilities
public enum CompositionStrategy {
    case sequential     // Initialize capabilities one by one
    case parallel       // Initialize all capabilities simultaneously
    case dependency     // Initialize based on dependency order
    case custom(([String: any DomainCapability]) async throws -> Void)  // Custom initialization logic
}

/// Capability composer for managing complex capability compositions
public actor CapabilityComposer {
    private let resolver: CapabilityDependencyResolver
    private var compositionStrategy: CompositionStrategy
    private var capabilities: [String: any DomainCapability] = [:]
    
    public init(
        strategy: CompositionStrategy = .dependency,
        resolver: CapabilityDependencyResolver = CapabilityDependencyResolver()
    ) {
        self.compositionStrategy = strategy
        self.resolver = resolver
    }
    
    /// Add a capability to the composition
    public func addCapability(
        _ capability: any DomainCapability,
        withId id: String,
        dependencies: [any CapabilityDependency] = []
    ) async throws {
        capabilities[id] = capability
        await resolver.registerCapability(capability, withId: id, dependencies: dependencies.map(\.id))
    }
    
    /// Initialize all capabilities according to the composition strategy
    public func initializeAll() async throws {
        try await resolver.validateDependencies()
        
        switch compositionStrategy {
        case .sequential:
            try await initializeSequentially()
        case .parallel:
            try await initializeInParallel()
        case .dependency:
            try await initializeByDependency()
        case .custom(let customInit):
            try await customInit(capabilities)
        }
    }
    
    /// Deactivate all capabilities in reverse dependency order
    public func deactivateAll() async {
        do {
            let order = try await resolver.resolveInitializationOrder()
            
            // Deactivate in reverse order
            for id in order.reversed() {
                await capabilities[id]?.deactivate()
            }
        } catch {
            // Fallback: deactivate all capabilities
            for (_, capability) in capabilities {
                await capability.deactivate()
            }
        }
    }
    
    /// Handle capability state change and propagate to dependents
    public func handleStateChange(capabilityId: String, newState: CapabilityState) async {
        let dependents = await resolver.getDependents(of: capabilityId)
        
        for dependentId in dependents {
            guard let dependent = capabilities[dependentId] else { continue }
            
            // Use type-erased approach for dependency change handling
            if let composable = dependent as? any ComposableCapability {
                // Create a generic dependency representation
                let genericDependency = AnyCapabilityDependency(id: capabilityId, state: newState)
                await notifyDependencyChange(capability: composable, dependency: genericDependency, newState: newState)
            }
        }
    }
    
    /// Helper method to handle dependency changes with type erasure
    private func notifyDependencyChange(capability: any ComposableCapability, dependency: AnyCapabilityDependency, newState: CapabilityState) async {
        // This is a simplified approach - in a full implementation, you'd need more sophisticated type handling
        // For now, just log that a dependency changed
        print("Dependency \(dependency.id) changed state for capability, new state: \(newState)")
    }
    
    private func initializeSequentially() async throws {
        let order = try await resolver.resolveInitializationOrder()
        
        for id in order {
            guard let capability = capabilities[id] else { continue }
            try await capability.activate()
        }
    }
    
    private func initializeInParallel() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (_, capability) in capabilities {
                group.addTask {
                    try await capability.activate()
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    private func initializeByDependency() async throws {
        let order = try await resolver.resolveInitializationOrder()
        
        for id in order {
            guard let capability = capabilities[id] else { continue }
            
            // Wait for dependencies to be available
            while !(await resolver.canInitialize(id)) {
                try await Task.sleep(for: .milliseconds(10))
            }
            
            try await capability.activate()
        }
    }
}

// MARK: - Capability Composition Utilities

/// Utility functions for capability composition
public struct CapabilityCompositionUtilities {
    
    /// Create a basic dependency
    public static func createDependency(
        id: String,
        type: CapabilityDependencyType = .required,
        isRequired: Bool = true,
        minimumVersion: String? = nil
    ) -> BasicCapabilityDependency {
        BasicCapabilityDependency(
            id: id,
            type: type,
            isRequired: isRequired,
            minimumVersion: minimumVersion
        )
    }
    
    /// Validate dependency compatibility
    public static func areDependenciesCompatible(
        _ capability1Dependencies: [any CapabilityDependency],
        _ capability2Dependencies: [any CapabilityDependency]
    ) -> Bool {
        for dep1 in capability1Dependencies {
            for dep2 in capability2Dependencies {
                if dep1.id == dep2.id && dep1.type == .exclusive && dep2.type == .exclusive {
                    return false
                }
            }
        }
        return true
    }
    
    /// Calculate composition complexity score
    public static func calculateComplexityScore(dependencies: [String: [any CapabilityDependency]]) -> Int {
        var score = 0
        
        for (_, deps) in dependencies {
            score += deps.count
            score += deps.filter { $0.isRequired }.count * 2
            score += deps.filter { $0.type == .exclusive }.count * 3
        }
        
        return score
    }
}