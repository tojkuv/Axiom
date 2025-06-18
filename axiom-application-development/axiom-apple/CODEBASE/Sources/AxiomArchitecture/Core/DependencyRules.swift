import Foundation
import AxiomCore

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
    
    // MARK: - Enhanced Dependency Validation
    
    /// Comprehensive dependency graph validation with detailed violation reporting
    /// - Parameter dependencies: Dictionary of component to its dependencies
    /// - Returns: Validation result with detailed violations
    public static func validateDependencyGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> DependencyValidationResult {
        var violations: [DependencyViolation] = []
        
        // Check for self-dependencies
        for (component, deps) in dependencies {
            if deps.contains(component) {
                violations.append(DependencyViolation(
                    from: component,
                    to: component,
                    violationType: .selfDependency,
                    message: "Component \(component.description) cannot depend on itself",
                    cyclePath: [component, component]
                ))
            }
        }
        
        // Check for rule violations
        for (source, targets) in dependencies {
            for target in targets {
                if !isValidDependency(from: source, to: target) {
                    let violationType = determineViolationType(from: source, to: target)
                    violations.append(DependencyViolation(
                        from: source,
                        to: target,
                        violationType: violationType,
                        message: dependencyError(from: source, to: target),
                        cyclePath: nil
                    ))
                }
            }
        }
        
        // Check for cycles and collect paths
        let cycleViolations = detectCyclesWithPaths(dependencies)
        violations.append(contentsOf: cycleViolations)
        
        return DependencyValidationResult(
            isValid: violations.isEmpty,
            violations: violations
        )
    }
    
    /// Validates DAG composition for specific component types
    /// - Parameters:
    ///   - dependencies: Dictionary of component to its dependencies
    ///   - componentType: The specific component type to validate
    /// - Returns: Validation result for the specific component type
    public static func validateDAGComposition(_ dependencies: [ComponentType: Set<ComponentType>], componentType: ComponentType) -> DependencyValidationResult {
        // Filter dependencies to only include the specified component type
        let filteredDeps = dependencies.filter { (key, value) in
            key == componentType && value.allSatisfy { allowedDependencies(for: componentType).contains($0) }
        }
        
        return validateDependencyGraph(filteredDeps)
    }
    
    /// Generates build-time validation code for CI/CD integration
    /// - Returns: Swift code string with compile-time assertions
    public static func generateBuildTimeValidation() -> String {
        var validationCode = [
            "// Auto-generated build-time dependency validation",
            "// Generated on: \\(Date())",
            ""
        ]
        
        // Generate validation for all invalid dependency combinations
        for source in ComponentType.allCases {
            for target in ComponentType.allCases {
                if !isValidDependency(from: source, to: target) {
                    validationCode.append("""
                    #if canImport(\\(source.description)Module) && canImport(\\(target.description)Module)
                    #error("\\(dependencyError(from: source, to: target))")
                    #endif
                    """)
                }
            }
        }
        
        return validationCode.joined(separator: "\\n")
    }
    
    // MARK: - Private Helper Methods
    
    private static func determineViolationType(from source: ComponentType, to target: ComponentType) -> DependencyViolationType {
        switch source {
        case .state:
            return .stateViolation
        case .client where target == .client:
            return .isolationViolation
        case .presentation where target != .context:
            return .presentationViolation
        default:
            return .ruleViolation
        }
    }
    
    private static func detectCyclesWithPaths(_ dependencies: [ComponentType: Set<ComponentType>]) -> [DependencyViolation] {
        var violations: [DependencyViolation] = []
        var visited = Set<ComponentType>()
        var recursionStack = Set<ComponentType>()
        var path: [ComponentType] = []
        
        func findCycles(from node: ComponentType) -> Bool {
            visited.insert(node)
            recursionStack.insert(node)
            path.append(node)
            
            if let neighbors = dependencies[node] {
                for neighbor in neighbors {
                    if neighbor == node { continue } // Skip self-loops
                    
                    if !visited.contains(neighbor) {
                        if findCycles(from: neighbor) {
                            return true
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found cycle - create violation with path
                        let cycleStart = path.firstIndex(of: neighbor) ?? 0
                        let cyclePath = Array(path[cycleStart...]) + [neighbor]
                        
                        violations.append(DependencyViolation(
                            from: node,
                            to: neighbor,
                            violationType: .cyclicDependency,
                            message: "Cyclic dependency detected: \(cyclePath.map(\.description).joined(separator: " → "))",
                            cyclePath: cyclePath
                        ))
                        return true
                    }
                }
            }
            
            recursionStack.remove(node)
            path.removeLast()
            return false
        }
        
        // Check all nodes for cycles
        for node in dependencies.keys {
            if !visited.contains(node) {
                _ = findCycles(from: node)
            }
        }
        
        return violations
    }
}

// MARK: - Enhanced Validation Types

/// Detailed dependency validation result
public struct DependencyValidationResult {
    public let isValid: Bool
    public let violations: [DependencyViolation]
    
    public init(isValid: Bool, violations: [DependencyViolation]) {
        self.isValid = isValid
        self.violations = violations
    }
}

/// Specific dependency violation information
public struct DependencyViolation {
    public let from: ComponentType
    public let to: ComponentType
    public let violationType: DependencyViolationType
    public let message: String
    public let cyclePath: [ComponentType]?
    
    public init(from: ComponentType, to: ComponentType, violationType: DependencyViolationType, message: String, cyclePath: [ComponentType]? = nil) {
        self.from = from
        self.to = to
        self.violationType = violationType
        self.message = message
        self.cyclePath = cyclePath
    }
}

/// Types of dependency violations
public enum DependencyViolationType: Equatable, CaseIterable {
    case selfDependency
    case cyclicDependency
    case stateViolation
    case isolationViolation
    case presentationViolation
    case ruleViolation
}

// MARK: - Runtime Validation

public extension DependencyRules {
    /// Runtime dependency validator for dynamic validation
    class RuntimeValidator {
        private var registeredDependencies: [String: (ComponentType, ComponentType)] = [:]
        
        public init() {}
        
        /// Register a dependency for runtime validation
        /// - Parameters:
        ///   - from: Source component type
        ///   - to: Target component type
        ///   - context: Context information for debugging
        /// - Returns: Registration result
        public func registerDependency(from: ComponentType, to: ComponentType, context: String) -> DependencyRegistrationResult {
            // Validate the dependency
            if !DependencyRules.isValidDependency(from: from, to: to) {
                let violationType = determineViolationType(from: from, to: to)
                let violation = DependencyViolation(
                    from: from,
                    to: to,
                    violationType: violationType,
                    message: DependencyRules.dependencyError(from: from, to: to)
                )
                
                return DependencyRegistrationResult(
                    isSuccess: false,
                    dependencyId: nil,
                    error: violation
                )
            }
            
            // Register the valid dependency
            let dependencyId = UUID().uuidString
            registeredDependencies[dependencyId] = (from, to)
            
            return DependencyRegistrationResult(
                isSuccess: true,
                dependencyId: dependencyId,
                error: nil
            )
        }
        
        /// Get all registered dependencies
        public func getRegisteredDependencies() -> [String: (ComponentType, ComponentType)] {
            return registeredDependencies
        }
    }
}

/// Result of dependency registration
public struct DependencyRegistrationResult {
    public let isSuccess: Bool
    public let dependencyId: String?
    public let error: DependencyViolation?
    
    public init(isSuccess: Bool, dependencyId: String?, error: DependencyViolation?) {
        self.isSuccess = isSuccess
        self.dependencyId = dependencyId
        self.error = error
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
        
        // Run comprehensive validation
        let result = validateDependencyGraph(dependencyMap)
        assert(result.isValid, "Dependency graph validation failed: \(result.violations.map(\.message).joined(separator: ", "))")
    }
}
#endif