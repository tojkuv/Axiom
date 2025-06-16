import Foundation
import AxiomCore

/// Advanced dependency resolver for managing complex capability relationships
public actor CapabilityDependencyResolver {
    public static let shared = CapabilityDependencyResolver()
    
    private var dependencyGraph: [String: Set<String>] = [:]
    private var resolvedOrder: [String] = []
    private var circularDependencies: Set<CircularDependency> = []
    
    public init() {}
    
    /// Register a capability with dependencies
    public func registerCapability(_ capability: any AxiomCapability, withId id: String, dependencies: [String]) async {
        dependencyGraph[id] = Set(dependencies)
    }
    
    /// Validate all dependencies
    public func validateDependencies() async throws {
        try await validateDependencyGraph()
    }
    
    /// Resolve initialization order
    public func resolveInitializationOrder() async throws -> [String] {
        return try resolveDependencies()
    }
    
    /// Get dependents of a capability
    public func getDependents(of capability: String) async -> [String] {
        return dependencyGraph.compactMap { (key, dependencies) in
            dependencies.contains(capability) ? key : nil
        }
    }
    
    /// Get dependencies of a capability
    public func getDependencies(of capability: String) async -> [String] {
        return Array(dependencyGraph[capability] ?? [])
    }
    
    /// Check if a capability can be initialized (all dependencies are satisfied)
    public func canInitialize(_ capability: String) async -> Bool {
        let result = await canEnable(capability: capability)
        return result.isSuccess
    }
    
    /// Add a dependency relationship
    public func addDependency(
        capability: String,
        dependsOn: String
    ) throws {
        if dependencyGraph[capability] == nil {
            dependencyGraph[capability] = []
        }
        dependencyGraph[capability]?.insert(dependsOn)
        
        // Check for circular dependencies
        if let circular = findCircularDependency(from: capability) {
            circularDependencies.insert(circular)
            throw DependencyError.circularDependency(circular.capabilities)
        }
    }
    
    /// Remove a dependency relationship
    public func removeDependency(
        capability: String,
        dependsOn: String
    ) {
        dependencyGraph[capability]?.remove(dependsOn)
        if dependencyGraph[capability]?.isEmpty == true {
            dependencyGraph.removeValue(forKey: capability)
        }
        
        // Recompute resolved order
        resolvedOrder = (try? computeResolutionOrder()) ?? []
    }
    
    /// Resolve dependencies and return initialization order
    public func resolveDependencies() throws -> [String] {
        resolvedOrder = try computeResolutionOrder()
        return resolvedOrder
    }
    
    /// Check if a capability can be enabled based on its dependencies
    public func canEnable(capability: String) async -> DependencyCheckResult {
        guard let dependencies = dependencyGraph[capability] else {
            return .success
        }
        
        var missingDependencies: [String] = []
        var unavailableDependencies: [String] = []
        
        for dependency in dependencies {
            if !(await AxiomCapabilityDiscoveryService.shared.hasAxiomCapability(dependency)) {
                // Check if the dependency is registered but not available
                if await AxiomCapabilityRegistry.shared.isRegistered(identifier: dependency) {
                    unavailableDependencies.append(dependency)
                } else {
                    missingDependencies.append(dependency)
                }
            }
        }
        
        if !missingDependencies.isEmpty {
            return .missingDependencies(missingDependencies)
        }
        
        if !unavailableDependencies.isEmpty {
            return .unavailableDependencies(unavailableDependencies)
        }
        
        return .success
    }
    
    /// Get all capabilities that depend on the given capability
    public func getDependents(of capability: String) -> [String] {
        var dependents: [String] = []
        
        for (capabilityId, dependencies) in dependencyGraph {
            if dependencies.contains(capability) {
                dependents.append(capabilityId)
            }
        }
        
        return dependents
    }
    
    /// Get direct dependencies of a capability
    public func getDependencies(of capability: String) -> Set<String> {
        return dependencyGraph[capability] ?? []
    }
    
    /// Get all transitive dependencies (dependencies of dependencies)
    public func getTransitiveDependencies(of capability: String) -> Set<String> {
        var visited: Set<String> = []
        var transitive: Set<String> = []
        
        func collectDependencies(_ cap: String) {
            guard !visited.contains(cap) else { return }
            visited.insert(cap)
            
            if let deps = dependencyGraph[cap] {
                for dep in deps {
                    transitive.insert(dep)
                    collectDependencies(dep)
                }
            }
        }
        
        collectDependencies(capability)
        return transitive
    }
    
    /// Get dependency depth for a capability (longest path to a leaf dependency)
    public func getDependencyDepth(of capability: String) -> Int {
        var visited: Set<String> = []
        
        func calculateDepth(_ cap: String) -> Int {
            guard !visited.contains(cap) else { return 0 }
            visited.insert(cap)
            
            guard let deps = dependencyGraph[cap], !deps.isEmpty else {
                return 0
            }
            
            let maxDepth = deps.map { calculateDepth($0) }.max() ?? 0
            return maxDepth + 1
        }
        
        return calculateDepth(capability)
    }
    
    /// Analyze dependency complexity
    public func analyzeDependencyComplexity() -> DependencyComplexityAnalysis {
        let totalCapabilities = dependencyGraph.keys.count
        let totalDependencies = dependencyGraph.values.reduce(0) { $0 + $1.count }
        let averageDependencies = totalCapabilities > 0 ? Double(totalDependencies) / Double(totalCapabilities) : 0.0
        
        let maxDepth = dependencyGraph.keys.map { getDependencyDepth(of: $0) }.max() ?? 0
        let circularCount = circularDependencies.count
        
        let complexity: DependencyComplexity
        switch (maxDepth, averageDependencies, circularCount) {
        case (0...2, 0...2, 0):
            complexity = .simple
        case (0...4, 0...4, 0):
            complexity = .moderate
        case (_, _, 0):
            complexity = .complex
        default:
            complexity = .problematic
        }
        
        return DependencyComplexityAnalysis(
            totalCapabilities: totalCapabilities,
            totalDependencies: totalDependencies,
            averageDependencies: averageDependencies,
            maxDepth: maxDepth,
            circularDependencies: circularCount,
            complexity: complexity,
            suggestions: generateOptimizationSuggestions()
        )
    }
    
    /// Validate dependency graph integrity
    public func validateDependencyGraph() async throws {
        // Check for missing dependencies
        var missingCapabilities: Set<String> = []
        
        for (_, dependencies) in dependencyGraph {
            for dependency in dependencies {
                if !(await AxiomCapabilityRegistry.shared.isRegistered(identifier: dependency)) {
                    missingCapabilities.insert(dependency)
                }
            }
        }
        
        if !missingCapabilities.isEmpty {
            throw DependencyError.missingCapabilities(Array(missingCapabilities))
        }
        
        // Check for circular dependencies
        if !circularDependencies.isEmpty {
            throw DependencyError.circularDependencies(Array(circularDependencies))
        }
    }
    
    /// Initialize capabilities in dependency order
    public func initializeInDependencyOrder() async throws {
        let order = try resolveDependencies()
        
        for capabilityId in order {
            // Check if dependencies are satisfied before initializing
            let checkResult = await canEnable(capability: capabilityId)
            guard case .success = checkResult else {
                throw DependencyError.dependenciesNotSatisfied(capabilityId, checkResult)
            }
            
            // Get capability and initialize it
            if let capability = await AxiomCapabilityRegistry.shared.capability(withId: capabilityId) {
                try await capability.activate()
            }
        }
    }
    
    /// Compute topological sort for dependency resolution
    private func computeResolutionOrder() throws -> [String] {
        var order: [String] = []
        var visiting: Set<String> = []
        var visited: Set<String> = []
        
        func visit(_ id: String) throws {
            if visiting.contains(id) {
                throw DependencyError.circularDependency([id])
            }
            
            if visited.contains(id) {
                return
            }
            
            visiting.insert(id)
            
            // Visit dependencies first
            if let dependencies = dependencyGraph[id] {
                for dependencyId in dependencies {
                    try visit(dependencyId)
                }
            }
            
            visiting.remove(id)
            visited.insert(id)
            order.append(id)
        }
        
        // Visit all capabilities
        for capabilityId in dependencyGraph.keys {
            try visit(capabilityId)
        }
        
        return order
    }
    
    /// Find circular dependency starting from a capability
    private func findCircularDependency(from start: String) -> CircularDependency? {
        var path: [String] = []
        var visited: Set<String> = []
        
        func detectCycle(_ current: String) -> CircularDependency? {
            if path.contains(current) {
                let cycleStart = path.firstIndex(of: current)!
                let cycle = Array(path[cycleStart...]) + [current]
                return CircularDependency(capabilities: cycle)
            }
            
            if visited.contains(current) {
                return nil
            }
            
            visited.insert(current)
            path.append(current)
            
            if let dependencies = dependencyGraph[current] {
                for dependency in dependencies {
                    if let cycle = detectCycle(dependency) {
                        return cycle
                    }
                }
            }
            
            path.removeLast()
            return nil
        }
        
        return detectCycle(start)
    }
    
    /// Generate optimization suggestions based on dependency analysis
    private func generateOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if !circularDependencies.isEmpty {
            suggestions.append("Remove circular dependencies by refactoring capability relationships")
        }
        
        let maxDepth = dependencyGraph.keys.map { getDependencyDepth(of: $0) }.max() ?? 0
        if maxDepth > 5 {
            suggestions.append("Consider flattening deep dependency chains (current max depth: \(maxDepth))")
        }
        
        let heavilyDependent = dependencyGraph.filter { $1.count > 5 }
        if !heavilyDependent.isEmpty {
            suggestions.append("Review capabilities with many dependencies: \(heavilyDependent.keys.joined(separator: ", "))")
        }
        
        return suggestions
    }
}

// MARK: - Dependency Check Result

public enum DependencyCheckResult: Equatable, Sendable {
    case success
    case missingDependencies([String])
    case unavailableDependencies([String])
    case circularDependency([String])
    
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    public var errorDescription: String {
        switch self {
        case .success:
            return "All dependencies satisfied"
        case .missingDependencies(let deps):
            return "Missing dependencies: \(deps.joined(separator: ", "))"
        case .unavailableDependencies(let deps):
            return "Unavailable dependencies: \(deps.joined(separator: ", "))"
        case .circularDependency(let cycle):
            return "Circular dependency: \(cycle.joined(separator: " -> "))"
        }
    }
}

// MARK: - Dependency Errors

public enum DependencyError: Error, LocalizedError {
    case circularDependency([String])
    case circularDependencies([CircularDependency])
    case missingCapabilities([String])
    case dependenciesNotSatisfied(String, DependencyCheckResult)
    
    public var errorDescription: String? {
        switch self {
        case .circularDependency(let cycle):
            return "Circular dependency detected: \(cycle.joined(separator: " -> "))"
        case .circularDependencies(let cycles):
            return "Multiple circular dependencies detected: \(cycles.count) cycles"
        case .missingCapabilities(let missing):
            return "Missing capabilities: \(missing.joined(separator: ", "))"
        case .dependenciesNotSatisfied(let capability, let result):
            return "Dependencies not satisfied for \(capability): \(result.errorDescription)"
        }
    }
}

// MARK: - Circular Dependency

public struct CircularDependency: Hashable, Sendable {
    public let capabilities: [String]
    
    public init(capabilities: [String]) {
        self.capabilities = capabilities
    }
    
    public var description: String {
        capabilities.joined(separator: " -> ")
    }
}

// MARK: - Dependency Complexity Analysis

public struct DependencyComplexityAnalysis: Sendable {
    public let totalCapabilities: Int
    public let totalDependencies: Int
    public let averageDependencies: Double
    public let maxDepth: Int
    public let circularDependencies: Int
    public let complexity: DependencyComplexity
    public let suggestions: [String]
    
    public init(
        totalCapabilities: Int,
        totalDependencies: Int,
        averageDependencies: Double,
        maxDepth: Int,
        circularDependencies: Int,
        complexity: DependencyComplexity,
        suggestions: [String]
    ) {
        self.totalCapabilities = totalCapabilities
        self.totalDependencies = totalDependencies
        self.averageDependencies = averageDependencies
        self.maxDepth = maxDepth
        self.circularDependencies = circularDependencies
        self.complexity = complexity
        self.suggestions = suggestions
    }
}

public enum DependencyComplexity: String, CaseIterable, Sendable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case problematic = "Problematic"
    
    public var description: String {
        switch self {
        case .simple:
            return "Simple dependency graph with minimal complexity"
        case .moderate:
            return "Moderate complexity with manageable dependencies"
        case .complex:
            return "Complex dependency relationships requiring careful management"
        case .problematic:
            return "Problematic dependencies with circular references or excessive complexity"
        }
    }
}

// MARK: - Dependent Capability Protocol

/// Protocol for capabilities with explicit dependencies
public protocol DependentCapability: AxiomCapability {
    /// Set of capability identifiers this capability depends on
    var dependencies: Set<String> { get async }
    
    /// Validate that all dependencies are satisfied
    func validateDependencies() async throws
    
    /// Handle dependency state change
    func handleDependencyChange(_ dependencyId: String, newState: AxiomCapabilityState) async
}

// MARK: - Default Implementation

extension DependentCapability {
    public func validateDependencies() async throws {
        let deps = await dependencies
        let resolver = CapabilityDependencyResolver.shared
        
        for dependency in deps {
            let result = await resolver.canEnable(capability: dependency)
            if !result.isSuccess {
                throw DependencyError.dependenciesNotSatisfied(
                    String(describing: type(of: self)),
                    result
                )
            }
        }
    }
    
    public func handleDependencyChange(_ dependencyId: String, newState: AxiomCapabilityState) async {
        // Default implementation - can be overridden by specific capabilities
        if newState != .available {
            // If a required dependency becomes unavailable, deactivate this capability
            await self.deactivate()
        }
    }
}

// MARK: - Auto-Registration with Dependencies

/// Extension to support automatic dependency registration
extension AxiomCapabilityRegistry {
    
    /// Register a dependent capability and its dependencies
    public func registerWithDependencies<C: DependentCapability>(
        _ capability: C,
        category: String? = nil,
        metadata: AxiomCapabilityMetadata? = nil
    ) async throws {
        let capabilityId = String(describing: type(of: capability))
        let dependencies = await capability.dependencies
        
        // Register dependencies with the resolver
        for dependency in dependencies {
            try await CapabilityDependencyResolver.shared.addDependency(
                capability: capabilityId,
                dependsOn: dependency
            )
        }
        
        // Convert dependencies to requirements
        let requirements = Set(dependencies.map { dependencyId in
            AxiomCapabilityDiscoveryService.Requirement(
                type: .dependency(dependencyId),
                isMandatory: true
            )
        })
        
        // Register the capability  
        try await AxiomCapabilityRegistry.shared.register(
            capability,
            requirements: requirements,
            category: category,
            metadata: metadata
        )
    }
}

// MARK: - Dependency Visualization

/// Utility for visualizing dependency relationships
public struct DependencyVisualizer {
    
    /// Generate DOT format for dependency graph visualization
    public static func generateDOTGraph() async -> String {
        let resolver = CapabilityDependencyResolver.shared
        let capabilities = await AxiomCapabilityRegistry.shared.allCapabilities()
        
        var dot = "digraph CapabilityDependencies {\n"
        dot += "  rankdir=LR;\n"
        dot += "  node [shape=box];\n\n"
        
        // Add nodes
        for capability in capabilities {
            let color = capability.isAvailable ? "lightgreen" : "lightcoral"
            dot += "  \"\(capability.identifier)\" [fillcolor=\(color), style=filled];\n"
        }
        
        dot += "\n"
        
        // Add edges
        for capability in capabilities {
            let dependencies = await resolver.getDependencies(of: capability.identifier)
            for dependency in dependencies {
                dot += "  \"\(capability.identifier)\" -> \"\(dependency)\";\n"
            }
        }
        
        dot += "}\n"
        return dot
    }
    
    /// Generate simple text-based dependency tree
    public static func generateDependencyTree(for capabilityId: String) async -> String {
        let resolver = CapabilityDependencyResolver.shared
        
        func buildTree(_ id: String, depth: Int = 0, visited: Set<String> = []) async -> String {
            let indent = String(repeating: "  ", count: depth)
            let marker = visited.contains(id) ? " (circular)" : ""
            var result = "\(indent)├─ \(id)\(marker)\n"
            
            if visited.contains(id) {
                return result
            }
            
            let newVisited = visited.union([id])
            let dependencies = await resolver.getDependencies(of: id)
            
            for (index, dependency) in dependencies.enumerated() {
                let isLast = index == dependencies.count - 1
                let prefix = isLast ? "└─" : "├─"
                result += "\(indent)  \(prefix) \(await buildTree(dependency, depth: depth + 1, visited: newVisited))"
            }
            
            return result
        }
        
        return await buildTree(capabilityId)
    }
}