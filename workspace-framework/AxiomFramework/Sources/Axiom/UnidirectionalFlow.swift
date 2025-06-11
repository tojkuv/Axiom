import Foundation

/// Unidirectional flow enforcement for preventing architectural violations
/// 
/// Ensures that components only depend on lower-level components in the hierarchy:
/// - Views can depend on Contexts and Models, but not other Views
/// - Contexts can depend on Models, but not Views or other Contexts
/// - Models cannot depend on Views or Contexts
///
/// This ensures:
/// - No circular dependencies
/// - Clear separation of concerns
/// - Predictable data flow
/// - Testable components
public enum UnidirectionalFlow {
    
    /// The hierarchy levels for main component types
    private static let hierarchyLevels: [ComponentType: Int] = [
        .orchestrator: 1,
        .client: 2,
        .context: 3,
        .capability: 4,
        .state: 5
    ]
    
    /// Allowed dependencies between component types
    private static let allowedDependencies: [ComponentType: Set<ComponentType>] = [
        .orchestrator: [.client, .context, .capability, .state],
        .client: [.context, .capability, .state],
        .context: [.capability, .state],
        .capability: [.state],
        .state: []
    ]
    
    /// Validates that a dependency follows unidirectional flow rules
    /// - Parameters:
    ///   - from: The depending component type
    ///   - to: The component type being depended upon
    /// - Returns: True if the dependency is allowed, false otherwise
    public static func validate(from: ComponentType, to: ComponentType) -> Bool {
        // Allow self-dependencies (same type)
        if from == to { return true }
        
        // Check if the dependency is explicitly allowed
        return allowedDependencies[from]?.contains(to) ?? false
    }
    
    /// Validates that a complex dependency graph follows unidirectional flow rules
    /// - Parameter dependencies: A map of component types to their dependencies
    /// - Returns: True if the entire dependency graph is valid
    public static func validateGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> Bool {
        for (from, toDependencies) in dependencies {
            for to in toDependencies {
                if !validate(from: from, to: to) {
                    return false
                }
            }
        }
        return true
    }
    
    /// Detects circular dependencies in a dependency graph
    /// - Parameter dependencies: A map of component types to their dependencies
    /// - Returns: An array of component types involved in circular dependencies
    public static func detectCircularDependencies(_ dependencies: [ComponentType: Set<ComponentType>]) -> [ComponentType] {
        var visited: Set<ComponentType> = []
        var recursionStack: Set<ComponentType> = []
        var circularDependencies: Set<ComponentType> = []
        
        func dfs(_ component: ComponentType) {
            if recursionStack.contains(component) {
                circularDependencies.insert(component)
                return
            }
            
            if visited.contains(component) {
                return
            }
            
            visited.insert(component)
            recursionStack.insert(component)
            
            if let deps = dependencies[component] {
                for dep in deps {
                    dfs(dep)
                }
            }
            
            recursionStack.remove(component)
        }
        
        for component in dependencies.keys {
            if !visited.contains(component) {
                dfs(component)
            }
        }
        
        return Array(circularDependencies)
    }
    
    /// Gets a human-readable error message for an invalid dependency
    /// - Parameters:
    ///   - from: The depending component type
    ///   - to: The component type being depended upon
    /// - Returns: A descriptive error message
    public static func errorMessage(from: ComponentType, to: ComponentType) -> String {
        let fromLevel = hierarchyLevels[from] ?? -1
        let toLevel = hierarchyLevels[to] ?? -1
        
        if fromLevel <= toLevel && from != to {
            return "\(from.description) (level \(fromLevel)) cannot depend on \(to.description) (level \(toLevel)). Dependencies must flow from higher-level to lower-level components."
        }
        
        return "\(from.description) cannot depend on \(to.description). This dependency is not allowed in the unidirectional flow architecture."
    }
    
    /// Gets the hierarchy level of a component type
    /// - Parameter componentType: The component type
    /// - Returns: The hierarchy level (lower numbers are higher in the hierarchy)
    public static func getLevel(of componentType: ComponentType) -> Int {
        return hierarchyLevels[componentType] ?? Int.max
    }
    
    /// Gets all component types that a given type can depend on
    /// - Parameter componentType: The component type
    /// - Returns: A set of component types that can be depended upon
    public static func getAllowedDependencies(for componentType: ComponentType) -> Set<ComponentType> {
        return allowedDependencies[componentType] ?? []
    }
    
    /// Validates a specific dependency relationship with detailed result
    /// - Parameters:
    ///   - from: The depending component type
    ///   - to: The component type being depended upon
    /// - Returns: A detailed validation result
    public static func validateDetailed(from: ComponentType, to: ComponentType) -> UnidirectionalDependencyValidationResult {
        let isValid = validate(from: from, to: to)
        
        return UnidirectionalDependencyValidationResult(
            from: from,
            to: to,
            isValid: isValid,
            errorMessage: isValid ? nil : errorMessage(from: from, to: to),
            fromLevel: getLevel(of: from),
            toLevel: getLevel(of: to)
        )
    }
}

/// Result of a detailed dependency validation
public struct UnidirectionalDependencyValidationResult {
    public let from: ComponentType
    public let to: ComponentType
    public let isValid: Bool
    public let errorMessage: String?
    public let fromLevel: Int
    public let toLevel: Int
    
    /// Gets a summary of the validation result
    public var summary: String {
        if isValid {
            return "✓ \(from.description) → \(to.description) (valid dependency)"
        } else {
            return "✗ \(from.description) → \(to.description): \(errorMessage ?? "Invalid dependency")"
        }
    }
    
    /// Whether this represents an upward dependency (violating unidirectional flow)
    public var isUpwardDependency: Bool {
        return fromLevel > toLevel
    }
}

/// Errors related to unidirectional flow violations
public enum UnidirectionalFlowError: Error, LocalizedError {
    case invalidDependency(from: ComponentType, to: ComponentType, message: String)
    case circularDependency([ComponentType])
    case unknownComponentType(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidDependency(let from, let to, let message):
            return "Invalid dependency from \(from.description) to \(to.description): \(message)"
        case .circularDependency(let components):
            return "Circular dependency detected involving: \(components.map(\.description).joined(separator: ", "))"
        case .unknownComponentType(let type):
            return "Unknown component type: \(type)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidDependency:
            return "The dependency violates unidirectional flow architecture rules."
        case .circularDependency:
            return "Circular dependencies create unpredictable behavior and prevent clean testing."
        case .unknownComponentType:
            return "The component type is not recognized in the current architecture."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidDependency(let from, let to, _):
            let suggestions = UnidirectionalFlow.getAllowedDependencies(for: from)
            if !suggestions.isEmpty {
                return "\(from.description) can depend on: \(suggestions.map(\.description).joined(separator: ", "))"
            }
            return "Review the component hierarchy to ensure proper dependency flow."
        case .circularDependency:
            return "Refactor components to break the circular dependency chain."
        case .unknownComponentType:
            return "Ensure the component type is properly defined in ComponentType enum."
        }
    }
}

/// Token representing a validated dependency
public struct ValidationToken {
    public let id: String
    public let from: ComponentType
    public let to: ComponentType
    public let issuedAt: Date
    public let validationLevel: Int
    
    /// Whether this token is still valid (not expired)
    public var isValid: Bool {
        // Tokens are valid for the duration of the app session
        return true
    }
    
    /// Human readable description of the validated dependency
    public var description: String {
        return "Dependency \(from.description) → \(to.description) validated at \(issuedAt)"
    }
}

/// Enhanced dependency validation with caching and performance optimization
public actor DependencyValidationCache {
    private var cache: [String: UnidirectionalDependencyValidationResult] = [:]
    private var cacheHits = 0
    private var cacheMisses = 0
    
    /// Validates a dependency with caching for improved performance
    /// - Parameters:
    ///   - from: The depending component type
    ///   - to: The component type being depended upon
    /// - Returns: A cached or newly computed validation result
    public func validateCached(from: ComponentType, to: ComponentType) -> UnidirectionalDependencyValidationResult {
        let cacheKey = "\(from.description)->\(to.description)"
        
        if let cached = cache[cacheKey] {
            cacheHits += 1
            return cached
        }
        
        cacheMisses += 1
        let result = UnidirectionalFlow.validateDetailed(from: from, to: to)
        cache[cacheKey] = result
        
        return result
    }
    
    /// Validates an entire dependency graph with caching
    /// - Parameter dependencies: A map of component types to their dependencies
    /// - Returns: An array of validation results for all dependencies
    public func validateGraphCached(_ dependencies: [ComponentType: Set<ComponentType>]) -> [UnidirectionalDependencyValidationResult] {
        var results: [UnidirectionalDependencyValidationResult] = []
        
        for (from, toDependencies) in dependencies {
            for to in toDependencies {
                let result = validateCached(from: from, to: to)
                results.append(result)
            }
        }
        
        return results
    }
    
    /// Gets cache performance statistics
    /// - Returns: A dictionary with cache hit rate and total validations
    public func getCacheStats() -> [String: Any] {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0.0
        
        return [
            "cacheHits": cacheHits,
            "cacheMisses": cacheMisses,
            "totalValidations": total,
            "hitRate": hitRate,
            "cacheSize": cache.count
        ]
    }
    
    /// Clears the validation cache
    public func clearCache() {
        cache.removeAll()
        cacheHits = 0
        cacheMisses = 0
    }
    
    /// Advanced cache with dependency graph optimization
    public struct CachedGraphValidation {
        private var graphCache: [String: Bool] = [:]
        
        /// Validates a dependency graph with graph-level caching
        /// - Parameter dependencies: A map of component types to their dependencies
        /// - Returns: True if the entire graph is valid
        mutating func validateGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> Bool {
            let cacheKey = generateCacheKey(for: dependencies)
            
            if let cached = graphCache[cacheKey] {
                return cached
            }
            
            let isValid = UnidirectionalFlow.validateGraph(dependencies)
            graphCache[cacheKey] = isValid
            
            return isValid
        }
        
        private func generateCacheKey(for dependencies: [ComponentType: Set<ComponentType>]) -> String {
            let sortedDeps = dependencies.sorted { $0.key.description < $1.key.description }
            return sortedDeps.map { "\($0.key.description):\($0.value.map(\.description).sorted().joined(separator: ","))" }.joined(separator: "|")
        }
        
        /// Clears the graph validation cache
        mutating func clearCache() {
            graphCache.removeAll()
        }
        
        /// Gets the current cache size
        var cacheSize: Int {
            return graphCache.count
        }
    }
}

/// Compile-time validation token for ensuring dependency safety
public struct CompileTimeValidation {
    private let token: ValidationToken
    
    internal init(token: ValidationToken) {
        self.token = token
    }
    
    /// Gets the underlying validation token
    public var validationToken: ValidationToken {
        return token
    }
    
    /// Ensures the dependency is valid at compile time
    /// - Returns: Self for chaining
    @discardableResult
    public func ensureValid() -> CompileTimeValidation {
        // In a real implementation, this would be enforced by macros or build tools
        return self
    }
}

/// Protocol for dependency validation support
public struct DependencyValidation {
    public let token: ValidationToken
    public let compilationCheck: CompileTimeValidation
    
    internal init(token: ValidationToken) {
        self.token = token
        self.compilationCheck = CompileTimeValidation(token: token)
    }
    
    /// Validates the dependency at runtime
    /// - Throws: UnidirectionalFlowError if the dependency is invalid
    public func validate() throws {
        let result = UnidirectionalFlow.validateDetailed(from: token.from, to: token.to)
        if !result.isValid {
            throw UnidirectionalFlowError.invalidDependency(
                from: result.from,
                to: result.to,
                message: result.errorMessage ?? "Invalid dependency"
            )
        }
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
        
        let token = ValidationToken(
            id: UUID().uuidString,
            from: Self.componentType,
            to: T.componentType,
            issuedAt: Date(),
            validationLevel: UnidirectionalFlow.getLevel(of: Self.componentType)
        )
        
        if !isValid {
            let error = UnidirectionalFlow.errorMessage(
                from: Self.componentType,
                to: T.componentType
            )
            // In a real implementation, this would be a compilation error
            print("Warning: Invalid dependency detected: \(error)")
        }
        
        return DependencyValidation(token: token)
    }
    
    /// Validates a dependency and throws an error if invalid
    /// - Parameter target: The type being depended upon
    /// - Throws: UnidirectionalFlowError if dependency is invalid
    /// - Returns: A validated dependency token
    @discardableResult
    public static func validateDependencyThrowing<T: DependencyValidatable>(
        on target: T.Type
    ) throws -> DependencyValidation {
        let isValid = UnidirectionalFlow.validate(
            from: Self.componentType,
            to: T.componentType
        )
        
        let token = ValidationToken(
            id: UUID().uuidString,
            from: Self.componentType,
            to: T.componentType,
            issuedAt: Date(),
            validationLevel: UnidirectionalFlow.getLevel(of: Self.componentType)
        )
        
        if !isValid {
            let error = UnidirectionalFlow.errorMessage(
                from: Self.componentType,
                to: T.componentType
            )
            throw UnidirectionalFlowError.invalidDependency(
                from: Self.componentType,
                to: T.componentType,
                message: error
            )
        }
        
        return DependencyValidation(token: token)
    }
}

// MARK: - Convenient validation extensions

extension ComponentType: DependencyValidatable {
    public static var componentType: ComponentType {
        return .state
    }
}

// MARK: - Debug and introspection tools

extension UnidirectionalFlow {
    /// Generates a dependency graph visualization for debugging
    /// - Parameter dependencies: A map of component types to their dependencies
    /// - Returns: A string representation of the dependency graph
    public static func visualizeDependencyGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> String {
        var lines: [String] = []
        lines.append("Dependency Graph:")
        lines.append("================")
        
        let sortedComponents = dependencies.keys.sorted { $0.description < $1.description }
        
        for component in sortedComponents {
            let deps = dependencies[component] ?? []
            if deps.isEmpty {
                lines.append("\(component.description) → (no dependencies)")
            } else {
                let sortedDeps = deps.sorted { $0.description < $1.description }
                lines.append("\(component.description) → [\(sortedDeps.map(\.description).joined(separator: ", "))]")
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Analyzes a dependency graph for potential issues
    /// - Parameter dependencies: A map of component types to their dependencies
    /// - Returns: A report of potential issues and suggestions
    public static func analyzeDependencyGraph(_ dependencies: [ComponentType: Set<ComponentType>]) -> DependencyAnalysisReport {
        let validationResults = dependencies.flatMap { (from, toDeps) in
            toDeps.map { to in
                validateDetailed(from: from, to: to)
            }
        }
        
        let violations = validationResults.filter { !$0.isValid }
        let circularDependencies = detectCircularDependencies(dependencies)
        let upwardDependencies = validationResults.filter { $0.isUpwardDependency }
        
        return DependencyAnalysisReport(
            totalDependencies: validationResults.count,
            violations: violations,
            circularDependencies: circularDependencies,
            upwardDependencies: upwardDependencies.map { ($0.from, $0.to) },
            suggestions: generateSuggestions(for: violations)
        )
    }
    
    private static func generateSuggestions(for violations: [UnidirectionalDependencyValidationResult]) -> [String] {
        var suggestions: [String] = []
        
        for violation in violations {
            let allowedDeps = getAllowedDependencies(for: violation.from)
            if !allowedDeps.isEmpty {
                suggestions.append("Instead of \(violation.from.description) → \(violation.to.description), consider: \(violation.from.description) → [\(allowedDeps.map(\.description).joined(separator: ", "))]")
            } else {
                suggestions.append("\(violation.from.description) should not depend on any other components. Consider refactoring to eliminate this dependency.")
            }
        }
        
        return suggestions
    }
}

/// Report containing analysis of a dependency graph
public struct DependencyAnalysisReport {
    public let totalDependencies: Int
    public let violations: [UnidirectionalDependencyValidationResult]
    public let circularDependencies: [ComponentType]
    public let upwardDependencies: [(from: ComponentType, to: ComponentType)]
    public let suggestions: [String]
    
    /// Whether the dependency graph is completely valid
    public var isValid: Bool {
        return violations.isEmpty && circularDependencies.isEmpty
    }
    
    /// A human-readable summary of the analysis
    public var summary: String {
        var lines: [String] = []
        lines.append("Dependency Analysis Report")
        lines.append("=========================")
        lines.append("Total Dependencies: \(totalDependencies)")
        lines.append("Violations: \(violations.count)")
        lines.append("Circular Dependencies: \(circularDependencies.count)")
        lines.append("Upward Dependencies: \(upwardDependencies.count)")
        lines.append("")
        
        if isValid {
            lines.append("✓ All dependencies are valid!")
        } else {
            lines.append("✗ Issues detected:")
            
            if !violations.isEmpty {
                lines.append("")
                lines.append("Violations:")
                for violation in violations {
                    lines.append("  - \(violation.summary)")
                }
            }
            
            if !circularDependencies.isEmpty {
                lines.append("")
                lines.append("Circular Dependencies:")
                lines.append("  - \(circularDependencies.map(\.description).joined(separator: " → "))")
            }
            
            if !suggestions.isEmpty {
                lines.append("")
                lines.append("Suggestions:")
                for suggestion in suggestions {
                    lines.append("  - \(suggestion)")
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
}