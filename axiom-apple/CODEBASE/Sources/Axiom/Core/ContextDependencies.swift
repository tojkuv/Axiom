/// Context dependency validation and enforcement
///
/// Ensures that Contexts can only depend on Clients and downstream Contexts,
/// never directly on Capabilities. This validator provides both compile-time
/// and runtime validation capabilities.
public struct ContextDependencyValidator {
    
    public init() {}
    
    /// Validation result for a dependency check
    public struct ValidationResult {
        public let isValid: Bool
        public let violations: [Violation]
        
        public struct Violation: Equatable {
            public let rule: DependencyRule
            public let description: String
            
            public init(rule: DependencyRule, description: String) {
                self.rule = rule
                self.description = description
            }
        }
        
        public static var success: ValidationResult {
            ValidationResult(isValid: true, violations: [])
        }
        
        public static func failure(_ violations: [Violation]) -> ValidationResult {
            ValidationResult(isValid: false, violations: violations)
        }
    }
    
    /// Dependency rules that can be violated
    public enum DependencyRule: String, CaseIterable {
        case contextCannotAccessCapability = "context_capability_dependency"
        case circularDependency = "circular_dependency"
        case invalidDependencyType = "invalid_dependency"
        
        public var description: String {
            switch self {
            case .contextCannotAccessCapability:
                return "Context cannot depend directly on Capability"
            case .circularDependency:
                return "Circular dependency detected"
            case .invalidDependencyType:
                return "Invalid dependency type"
            }
        }
    }
    
    /// Validates a dependency between two component types
    public func validate(source: ComponentType, target: ComponentType) -> ValidationResult {
        // Extract validation logic for reusability
        let violations = validateDependency(from: source, to: target)
        return violations.isEmpty ? .success : .failure(violations)
    }
    
    /// Internal validation logic that can be reused
    private func validateDependency(from source: ComponentType, to target: ComponentType) -> [ValidationResult.Violation] {
        var violations: [ValidationResult.Violation] = []
        
        // Context-specific rules
        if source == .context {
            if target == .capability {
                violations.append(ValidationResult.Violation(
                    rule: .contextCannotAccessCapability,
                    description: DependencyRule.contextCannotAccessCapability.description
                ))
            }
            // Contexts can only depend on Clients and other Contexts
            else if target != .client && target != .context {
                violations.append(ValidationResult.Violation(
                    rule: .invalidDependencyType,
                    description: "Context can only depend on Client or Context"
                ))
            }
        }
        
        return violations
    }
}

/// Module-level dependency validation
public struct ModuleDependencyValidator {
    private var dependencies: [Module: Set<Module>] = [:]
    
    public init() {}
    
    /// Represents a module with its type
    public struct Module: Hashable {
        public let name: String
        public let type: ComponentType
        
        public init(name: String, type: ComponentType) {
            self.name = name
            self.type = type
        }
    }
    
    /// Adds a dependency between modules
    public mutating func addDependency(from source: Module, to target: Module) {
        dependencies[source, default: []].insert(target)
    }
    
    /// Validates all registered dependencies
    public func validateDependencies() -> [String] {
        var violations: [String] = []
        
        // Check for Context -> Capability violations
        for (source, targets) in dependencies {
            if source.type == .context {
                for target in targets {
                    if target.type == .capability {
                        violations.append(
                            "Context '\(source.name)' cannot depend on Capability '\(target.name)'"
                        )
                    }
                }
            }
        }
        
        // Check for circular dependencies among contexts
        let contextModules = dependencies.keys.filter { $0.type == .context }
        for module in contextModules {
            if let cycle = findCycleFrom(module) {
                let cycleDescription = cycle.map { $0.name }.joined(separator: " -> ")
                violations.append("Circular dependency detected: \(cycleDescription)")
                break // Report only the first cycle found
            }
        }
        
        return violations
    }
    
    /// Gets all dependency edges for analysis
    public func getDependencyEdges() -> [DependencyEdge] {
        var edges: [DependencyEdge] = []
        
        for (source, targets) in dependencies {
            for target in targets {
                edges.append(DependencyEdge(
                    from: source.name,
                    to: target.name,
                    sourceType: source.type,
                    targetType: target.type
                ))
            }
        }
        
        return edges
    }
    
    /// Dependency edge representation
    public struct DependencyEdge {
        public let from: String
        public let to: String
        public let sourceType: ComponentType
        public let targetType: ComponentType
    }
    
    /// Finds cycles in the dependency graph starting from a specific module
    private func findCycleFrom(_ startModule: Module) -> [Module]? {
        var visited = Set<Module>()
        var recursionStack = Set<Module>()
        var path: [Module] = []
        
        func dfs(_ module: Module) -> Bool {
            visited.insert(module)
            recursionStack.insert(module)
            path.append(module)
            
            if let neighbors = dependencies[module] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if dfs(neighbor) {
                            return true
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found a cycle - trim path to show only the cycle
                        if let cycleStart = path.firstIndex(of: neighbor) {
                            path = Array(path[cycleStart...])
                            // Add the starting node again to show the complete cycle
                            path.append(neighbor)
                        }
                        return true
                    }
                }
            }
            
            recursionStack.remove(module)
            path.removeLast()
            return false
        }
        
        if dfs(startModule) {
            return path
        }
        
        return nil
    }
}

/// Import validation for static analysis
public struct ImportValidator {
    
    public init() {}
    
    /// Validates imports for a given component type
    public func validateImports(
        _ imports: String,
        forComponentType componentType: ComponentType,
        componentName: String
    ) -> [String] {
        var violations: [String] = []
        
        let lines = imports.split(separator: "\n").map { String($0) }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmedLine.isEmpty { continue }
            
            // Skip comment lines (but not inline comments)
            if trimmedLine.hasPrefix("//") { continue }
            
            // Check if this is an import statement
            if trimmedLine.hasPrefix("import") {
                // Remove inline comments
                let importPart = trimmedLine.split(separator: "//").first ?? ""
                let cleanImport = String(importPart).trimmingCharacters(in: .whitespaces)
                
                // Check for Context importing Capability
                if componentType == .context && cleanImport.contains("Capability") {
                    let importedModule = cleanImport
                        .replacingOccurrences(of: "import", with: "")
                        .replacingOccurrences(of: "@testable", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    violations.append(
                        "Context '\(componentName)' cannot import Capability: '\(importedModule)'"
                    )
                }
            }
        }
        
        return violations
    }
}

/// Build-time dependency validation
///
/// This validator can be integrated into build scripts to provide compile-time
/// validation of component dependencies. For maximum effectiveness, this should
/// be run as a pre-compilation build phase.
///
/// Example Build Script Integration:
/// ```bash
/// # Run as Xcode Build Phase Script
/// swift run axiom-validator validate-dependencies Sources/
/// ```
public struct BuildDependencyValidator {
    
    public init() {}
    
    /// Represents a scanned module from the build system
    public struct ScannedModule {
        public let name: String
        public let type: ComponentType
        public let imports: [String]
        public let dependencies: [String]
        
        public init(name: String, type: ComponentType, imports: [String], dependencies: [String]) {
            self.name = name
            self.type = type
            self.imports = imports
            self.dependencies = dependencies
        }
    }
    
    /// Validates a module's dependencies during build
    public func validateModule(_ module: ScannedModule) -> [String] {
        var errors: [String] = []
        
        if module.type == .context {
            // Check dependencies
            for dep in module.dependencies {
                if dep.contains("Capability") {
                    errors.append(
                        "Context '\(module.name)' cannot depend on Capability '\(dep)'"
                    )
                }
            }
            
            // Check imports - skip common system imports
            let systemImports = ["Foundation", "SwiftUI", "UIKit", "Combine"]
            for imp in module.imports {
                if !systemImports.contains(imp) && imp.contains("Capability") {
                    errors.append(
                        "Context '\(module.name)' cannot import '\(imp)'"
                    )
                }
            }
        }
        
        return errors
    }
}

// MARK: - Compile-Time Safety Extensions

/// Protocol marker for components that contexts can depend on
public protocol ContextDependable {}

/// Protocol marker for components that contexts cannot depend on
public protocol NotContextDependable {}

// Extend component protocols to enforce compile-time rules
extension ComponentType {
    /// Provides compile-time feedback about valid dependencies
    public var contextDependencyInfo: String {
        switch self {
        case .client:
            return "✓ Contexts can depend on Clients"
        case .context:
            return "✓ Contexts can depend on other Contexts"
        case .capability:
            return "✗ Contexts cannot depend on Capabilities"
        case .orchestrator:
            return "✗ Contexts cannot depend on Orchestrators"
        case .state:
            return "✗ Contexts cannot depend on States directly"
        case .presentation:
            return "✗ Contexts cannot depend on Presentations"
        }
    }
}