import Foundation

/// Defines and validates component dependency rules for the Axiom architecture
public struct DependencyRules {
    
    // MARK: - Performance Optimization
    
    /// Pre-computed dependency rules for compile-time optimization
    private static let dependencyMap: [ComponentType: Set<ComponentType>] = [
        .capability: [.capability],
        .state: [],
        .client: [.capability],
        .orchestrator: [.context],
        .context: [.client, .context],
        .presentation: [.context]
    ]
    
    /// Pre-computed validation matrix for O(1) lookup
    private static let validationMatrix: [[Bool]] = {
        var matrix = Array(repeating: Array(repeating: false, count: 6), count: 6)
        for (source, targets) in dependencyMap {
            for target in targets {
                matrix[source.rawValue][target.rawValue] = true
            }
        }
        return matrix
    }()
    
    // MARK: - Public API
    
    /// Returns the set of component types that the given component type is allowed to depend on
    /// - Parameter componentType: The source component type
    /// - Returns: Set of allowed target component types
    /// - Complexity: O(1)
    public static func allowedDependencies(for componentType: ComponentType) -> Set<ComponentType> {
        return dependencyMap[componentType] ?? []
    }
    
    /// Validates whether a dependency from one component type to another is allowed
    /// - Parameters:
    ///   - source: The source component type
    ///   - target: The target component type
    /// - Returns: true if the dependency is valid, false otherwise
    /// - Complexity: O(1)
    public static func isValidDependency(from source: ComponentType, to target: ComponentType) -> Bool {
        return validationMatrix[source.rawValue][target.rawValue]
    }
    
    /// Returns a clear error message for an invalid dependency
    /// - Parameters:
    ///   - source: The source component type
    ///   - target: The target component type
    /// - Returns: A descriptive error message with architectural guidance
    public static func dependencyError(from source: ComponentType, to target: ComponentType) -> String {
        let sourceDesc = source.description
        let targetDesc = target.description
        
        switch source {
        case .capability:
            return "\(sourceDesc) cannot depend on \(targetDesc): Capabilities can only depend on other Capabilities"
            
        case .state:
            return "\(sourceDesc) cannot depend on \(targetDesc): States must be pure value types with no dependencies"
            
        case .client:
            return "\(sourceDesc) cannot depend on \(targetDesc): Clients must be isolated from each other"
            
        case .orchestrator:
            return "\(sourceDesc) cannot depend on \(targetDesc): Orchestrator can only depend on Contexts"
            
        case .context:
            return "\(sourceDesc) cannot depend on \(targetDesc): Contexts can only depend on Clients and downstream Contexts"
            
        case .presentation:
            return "\(sourceDesc) cannot depend on \(targetDesc): Presentations can only depend on Contexts"
        }
    }
    
    // MARK: - Compile-Time Validation Support
    
    /// Generates compile-time assertions for dependency validation
    /// This can be used in build scripts or code generation
    public static func generateCompileTimeAssertions() -> String {
        var assertions = ["// Auto-generated dependency assertions"]
        
        for source in ComponentType.allCases {
            for target in ComponentType.allCases {
                if !isValidDependency(from: source, to: target) {
                    let assertion = """
                    #if canImport(\(source.description)) && canImport(\(target.description))
                    #error("\(dependencyError(from: source, to: target))")
                    #endif
                    """
                    assertions.append(assertion)
                }
            }
        }
        
        return assertions.joined(separator: "\n")
    }
    
    // MARK: - Dependency Graph Analysis
    
    /// Analyzes the dependency graph for cycles
    /// - Parameter dependencies: Dictionary of component to its dependencies
    /// - Returns: true if the graph is acyclic, false if cycles exist
    /// - Complexity: O(V + E) where V is vertices and E is edges
    public static func isAcyclicGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> Bool {
        var visited = Set<ComponentType>()
        var recursionStack = Set<ComponentType>()
        
        func hasCycle(from node: ComponentType) -> Bool {
            visited.insert(node)
            recursionStack.insert(node)
            
            if let neighbors = dependencies[node] {
                for neighbor in neighbors {
                    // Skip self-loops (e.g., capability depending on capability)
                    if neighbor == node {
                        continue
                    }
                    
                    if !visited.contains(neighbor) {
                        if hasCycle(from: neighbor) {
                            return true
                        }
                    } else if recursionStack.contains(neighbor) {
                        return true
                    }
                }
            }
            
            recursionStack.remove(node)
            return false
        }
        
        // Check all nodes
        for node in dependencies.keys {
            if !visited.contains(node) {
                if hasCycle(from: node) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Performs topological sort on the dependency graph
    /// - Parameter dependencies: Dictionary of component to its dependencies
    /// - Returns: Array of components in topological order, or nil if cycles exist
    public static func topologicalSort(_ dependencies: [ComponentType: Set<ComponentType>]) -> [ComponentType]? {
        guard isAcyclicGraph(dependencies) else { return nil }
        
        var visited = Set<ComponentType>()
        var result = [ComponentType]()
        
        func visit(_ node: ComponentType) {
            guard !visited.contains(node) else { return }
            
            // First visit all dependencies
            if let neighbors = dependencies[node] {
                for neighbor in neighbors where neighbor != node {
                    visit(neighbor)
                }
            }
            
            // Then add the node itself
            visited.insert(node)
            result.append(node)
        }
        
        // Visit all nodes to ensure we include disconnected components
        for node in ComponentType.allCases {
            if dependencies.keys.contains(node) || dependencies.values.flatMap({ $0 }).contains(node) {
                visit(node)
            }
        }
        
        return result
    }
}

// MARK: - Build Script Support

#if DEBUG
/// Build-time validation that can be run in debug builds
public extension DependencyRules {
    static func validateArchitecturalConstraints() {
        // Validate that the dependency rules form a DAG
        let isDAG = isAcyclicGraph(dependencyMap)
        assert(isDAG, "Component dependency rules must form a directed acyclic graph")
        
        // Validate specific architectural constraints
        assert(!isValidDependency(from: .client, to: .client), "Clients must be isolated from each other")
        assert(!isValidDependency(from: .context, to: .capability), "Contexts cannot directly depend on capabilities")
        assert(isValidDependency(from: .presentation, to: .context), "Presentations must be able to depend on contexts")
        
        // Validate unidirectional flow
        let topOrder = topologicalSort(dependencyMap)
        assert(topOrder != nil, "Dependency graph must be acyclic for unidirectional flow")
    }
}
#endif