/// Validates unidirectional dependency flow in the Axiom architecture
///
/// The Axiom architecture enforces a strict unidirectional flow of dependencies:
/// ```
/// Orchestrator → Context → Client → Capability → System
/// ```
///
/// This ensures:
/// - No circular dependencies
/// - Clear separation of concerns
/// - Predictable data flow
/// - Testable components
public enum UnidirectionalFlow {
    
    /// The hierarchy levels for main component types
    private static let hierarchyLevels: [ComponentType: Int] = [
        .orchestrator: 0,
        .context: 1,
        .client: 2,
        .capability: 3
    ]
    
    /// Validates whether a dependency from one component type to another is allowed
    /// - Parameters:
    ///   - from: The component type that has the dependency
    ///   - to: The component type being depended upon
    /// - Returns: `true` if the dependency is allowed, `false` otherwise
    public static func validate(from: ComponentType, to: ComponentType) -> Bool {
        // Define the strict unidirectional flow order
        // Orchestrator → Context → Client → Capability → System
        
        // Special cases first
        switch (from, to) {
        case (.client, .state):
            // Client owns State (allowed)
            return true
        case (.state, .client):
            // State depending on Client (not allowed)
            return false
        case (.context, .presentation):
            // Context provides data to Presentation (allowed)
            return true
        case (.presentation, .context):
            // Presentation explicitly depending on Context (not allowed)
            return false
        case (_, .state), (_, .presentation):
            // Only Client can depend on State, only Context can depend on Presentation
            return from == .client || from == .context
        case (.state, _), (.presentation, _):
            // State and Presentation should not depend on anything
            return false
        default:
            break
        }
        
        // Get levels for the components
        guard let fromLevel = hierarchyLevels[from],
              let toLevel = hierarchyLevels[to] else {
            // If not in the main hierarchy, dependency is not allowed
            return false
        }
        
        // Dependencies can only flow downstream (higher level → lower level)
        return fromLevel < toLevel
    }
    
    /// Gets a descriptive error message for an invalid dependency
    /// - Parameters:
    ///   - from: The component type that has the dependency
    ///   - to: The component type being depended upon
    /// - Returns: A descriptive error message
    public static func errorMessage(from: ComponentType, to: ComponentType) -> String {
        if validate(from: from, to: to) {
            return "Dependency from \(from) to \(to) is allowed"
        }
        
        // Special case messages
        switch (from, to) {
        case (.state, _):
            return "State components are value types and should not depend on other components"
        case (.presentation, _):
            return "Presentation components should only receive data through their bound Context"
        case (_, .state) where from != .client:
            return "Only Client components can own State; \(from) cannot depend on State"
        case (_, .presentation) where from != .context:
            return "Only Context components can bind to Presentation; \(from) cannot depend on Presentation"
        default:
            break
        }
        
        // Check if it's a reverse dependency in the main hierarchy
        if let fromLevel = hierarchyLevels[from],
           let toLevel = hierarchyLevels[to],
           fromLevel > toLevel {
            return "Reverse dependency detected: \(from) (level \(fromLevel)) cannot depend on \(to) (level \(toLevel)). Dependencies must flow downstream."
        }
        
        return "Invalid dependency: \(from) cannot depend on \(to)"
    }
}

/// Analyzes dependency graphs for architectural compliance
///
/// This analyzer helps validate that component dependencies follow
/// the unidirectional flow requirements and contain no cycles.
public struct DependencyAnalyzer {
    private let dependencies: [(ComponentType, ComponentType)]
    
    /// Creates a new dependency analyzer
    /// - Parameter dependencies: Array of dependency pairs (from, to)
    public init(dependencies: [(ComponentType, ComponentType)]) {
        self.dependencies = dependencies
    }
    
    /// Creates a dependency analyzer from a dependency graph
    /// - Parameter graph: Dictionary mapping components to their dependencies
    public init(graph: [ComponentType: Set<ComponentType>]) {
        var deps: [(ComponentType, ComponentType)] = []
        for (from, toSet) in graph {
            for to in toSet {
                deps.append((from, to))
            }
        }
        self.dependencies = deps
    }
    
    /// Checks if the dependency graph is unidirectional
    /// - Returns: `true` if the graph has no cycles and follows unidirectional flow
    public func isUnidirectional() -> Bool {
        // First check if all individual dependencies are valid
        for (from, to) in dependencies {
            if !UnidirectionalFlow.validate(from: from, to: to) {
                return false
            }
        }
        
        // Then check for cycles using topological sort
        return topologicalSort() != nil
    }
    
    /// Performs a topological sort on the dependency graph
    /// - Returns: An ordered array of components if the graph is acyclic, `nil` if cyclic
    public func topologicalSort() -> [ComponentType]? {
        // Build adjacency list
        var adjacencyList: [ComponentType: Set<ComponentType>] = [:]
        var inDegree: [ComponentType: Int] = [:]
        var allComponents = Set<ComponentType>()
        
        // Initialize structures
        for (from, to) in dependencies {
            adjacencyList[from, default: []].insert(to)
            inDegree[to, default: 0] += 1
            inDegree[from] = inDegree[from] ?? 0
            allComponents.insert(from)
            allComponents.insert(to)
        }
        
        // Find all nodes with in-degree 0
        var queue = Array(allComponents.filter { inDegree[$0, default: 0] == 0 })
        var result: [ComponentType] = []
        
        // Kahn's algorithm
        while !queue.isEmpty {
            let node = queue.removeFirst()
            result.append(node)
            
            // Remove edges from this node
            if let neighbors = adjacencyList[node] {
                for neighbor in neighbors {
                    inDegree[neighbor]! -= 1
                    if inDegree[neighbor]! == 0 {
                        queue.append(neighbor)
                    }
                }
            }
        }
        
        // If we processed all nodes, the graph is acyclic
        return result.count == allComponents.count ? result : nil
    }
    
    /// Finds all invalid dependencies in the graph
    /// - Returns: Array of invalid dependency pairs with error messages
    public func findInvalidDependencies() -> [(from: ComponentType, to: ComponentType, error: String)] {
        var invalid: [(ComponentType, ComponentType, String)] = []
        
        for (from, to) in dependencies {
            if !UnidirectionalFlow.validate(from: from, to: to) {
                let error = UnidirectionalFlow.errorMessage(from: from, to: to)
                invalid.append((from, to, error))
            }
        }
        
        return invalid
    }
    
    /// Generates a visual representation of the dependency graph
    /// - Returns: A string representation suitable for debugging
    public func visualize() -> String {
        var result = "Dependency Graph:\n"
        
        // Group dependencies by source
        var graph: [ComponentType: Set<ComponentType>] = [:]
        for (from, to) in dependencies {
            graph[from, default: []].insert(to)
        }
        
        // Sort components for consistent output
        let sortedComponents = graph.keys.sorted { $0.description < $1.description }
        
        for component in sortedComponents {
            if let deps = graph[component] {
                let depsList = deps.sorted { $0.description < $1.description }
                    .map { $0.description }
                    .joined(separator: ", ")
                result += "  \(component) → [\(depsList)]\n"
            }
        }
        
        return result
    }
}

// MARK: - Compile-time validation support

/// Protocol for components that can have dependencies
public protocol DependencyValidatable {
    static var componentType: ComponentType { get }
}

/// Extension to provide compile-time dependency validation
extension DependencyValidatable {
    /// Validates a dependency at compile time
    /// - Parameter target: The type being depended upon
    /// - Returns: A validated dependency token
    @discardableResult
    public static func validateDependency<T: DependencyValidatable>(
        on target: T.Type
    ) -> DependencyValidation {
        let isValid = UnidirectionalFlow.validate(
            from: Self.componentType,
            to: T.componentType
        )
        
        if !isValid {
            let error = UnidirectionalFlow.errorMessage(
                from: Self.componentType,
                to: T.componentType
            )
            // In a real implementation, this would trigger a compile-time diagnostic
            fatalError("Invalid dependency: \(error)")
        }
        
        return DependencyValidation(from: Self.componentType, to: T.componentType)
    }
}

/// Token representing a validated dependency
public struct DependencyValidation {
    public let from: ComponentType
    public let to: ComponentType
    
    init(from: ComponentType, to: ComponentType) {
        self.from = from
        self.to = to
    }
}