import Foundation

/// Represents a client definition for validation purposes
public struct ClientDefinition {
    public let name: String
    public let dependencies: [String]
    
    public init(name: String, dependencies: [String]) {
        self.name = name
        self.dependencies = dependencies
    }
}

/// Validates client isolation constraints in the Axiom architecture
public struct ClientIsolationValidator {
    
    /// Types of isolation violations
    public enum ViolationType: String, CustomStringConvertible {
        case clientToClient = "client-to-client dependency"
        case selfReference = "self-reference"
        case circularDependency = "circular dependency"
        
        public var description: String { rawValue }
    }
    
    /// Detailed error information for violations
    public struct IsolationError: CustomStringConvertible {
        public let source: String
        public let target: String
        public let violationType: ViolationType
        public let suggestion: String
        
        public var description: String {
            "\(source) cannot depend on \(target): Clients must be isolated from each other (\(violationType)). \(suggestion)"
        }
        
        /// Short error message without suggestion
        public var shortDescription: String {
            "\(source) cannot depend on \(target): Clients must be isolated from each other"
        }
    }
    
    /// Result of client isolation validation
    public struct ValidationResult {
        public let isValid: Bool
        public let errors: [String]
        public let detailedErrors: [IsolationError]
        
        public init(isValid: Bool, errors: [String], detailedErrors: [IsolationError] = []) {
            self.isValid = isValid
            self.errors = errors
            self.detailedErrors = detailedErrors
        }
        
        /// Generates a diagnostic report
        public func diagnosticReport() -> String {
            guard !isValid else { return "✅ All client isolation rules are satisfied." }
            
            var report = ["❌ Client Isolation Violations Found:", ""]
            
            for (index, error) in detailedErrors.enumerated() {
                report.append("\(index + 1). \(error.description)")
            }
            
            report.append("")
            report.append("Total violations: \(detailedErrors.count)")
            
            return report.joined(separator: "\n")
        }
    }
    
    /// Known client names for validation
    private let knownClients: Set<String>
    
    public init(knownClients: Set<String> = []) {
        self.knownClients = knownClients
    }
    
    /// Validates that clients follow isolation rules
    /// - Parameter clients: Array of client definitions to validate
    /// - Returns: Validation result with any errors found
    public func validate(clients: [ClientDefinition]) -> ValidationResult {
        var errors: [String] = []
        var detailedErrors: [IsolationError] = []
        
        // Build a set of all client names
        let clientNames = Set(clients.map { $0.name })
        let allKnownClients = clientNames.union(knownClients)
        
        // Check each client's dependencies
        for client in clients {
            for dependency in client.dependencies {
                // Check for self-reference
                if dependency == client.name {
                    let isolationError = IsolationError(
                        source: client.name,
                        target: dependency,
                        violationType: .selfReference,
                        suggestion: "Remove the self-reference from \(client.name)'s dependencies."
                    )
                    detailedErrors.append(isolationError)
                    errors.append(isolationError.shortDescription)
                }
                // Check if dependency is another client
                else if allKnownClients.contains(dependency) {
                    let isolationError = IsolationError(
                        source: client.name,
                        target: dependency,
                        violationType: .clientToClient,
                        suggestion: "Consider using a Context to coordinate between \(client.name) and \(dependency), or refactor to eliminate the dependency."
                    )
                    detailedErrors.append(isolationError)
                    errors.append(isolationError.shortDescription)
                }
            }
        }
        
        // Check for circular dependencies
        let circularErrors = detectCircularDependencies(clients: clients, allKnownClients: allKnownClients)
        detailedErrors.append(contentsOf: circularErrors)
        errors.append(contentsOf: circularErrors.map { $0.shortDescription })
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors, detailedErrors: detailedErrors)
    }
    
    /// Detects circular dependencies between clients
    private func detectCircularDependencies(clients: [ClientDefinition], allKnownClients: Set<String>) -> [IsolationError] {
        var errors: [IsolationError] = []
        var visited = Set<String>()
        var recursionStack = Set<String>()
        
        // Build adjacency list
        var adjacencyList: [String: Set<String>] = [:]
        for client in clients {
            adjacencyList[client.name] = Set(client.dependencies.filter { allKnownClients.contains($0) })
        }
        
        func hasCycle(from node: String, path: [String] = []) -> Bool {
            visited.insert(node)
            recursionStack.insert(node)
            let currentPath = path + [node]
            
            if let neighbors = adjacencyList[node] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        if hasCycle(from: neighbor, path: currentPath) {
                            return true
                        }
                    } else if recursionStack.contains(neighbor) {
                        // Found a cycle
                        let cycleStart = currentPath.firstIndex(of: neighbor) ?? 0
                        let cycle = currentPath[cycleStart...] + [neighbor]
                        let cycleDescription = cycle.joined(separator: " → ")
                        
                        let error = IsolationError(
                            source: node,
                            target: neighbor,
                            violationType: .circularDependency,
                            suggestion: "Break the circular dependency chain: \(cycleDescription)"
                        )
                        errors.append(error)
                        return true
                    }
                }
            }
            
            recursionStack.remove(node)
            return false
        }
        
        // Check all nodes
        for client in clients {
            if !visited.contains(client.name) {
                _ = hasCycle(from: client.name)
            }
        }
        
        return errors
    }
    
    /// Validates a single client definition
    public func validateSingle(_ client: ClientDefinition) -> ValidationResult {
        return validate(clients: [client])
    }
}

// MARK: - Build Script Integration

/// Provides build-time validation for client isolation
public extension ClientIsolationValidator {
    
    /// Generates a build script that validates client isolation
    static func generateBuildScript() -> String {
        return """
        #!/bin/bash
        # Auto-generated client isolation validation script
        
        # This script should be integrated into the build process to ensure
        # client isolation rules are enforced at build time.
        
        # Example usage:
        # swift run axiom-validate-clients Sources/
        
        echo "Validating client isolation rules..."
        
        # The actual validation would be performed by a build tool
        # that parses Swift files and checks import statements
        """
    }
    
    /// Validates client isolation from source file imports
    /// - Parameters:
    ///   - sourceFile: Path to the source file
    ///   - imports: List of import statements in the file
    /// - Returns: Validation result
    static func validateSourceFile(path: String, imports: [String], clientIdentifier: String?) -> ValidationResult {
        guard let clientName = clientIdentifier else {
            return ValidationResult(isValid: true, errors: [])
        }
        
        var errors: [String] = []
        
        // Check if any imports reference other clients
        for importStatement in imports {
            // Simple heuristic: if import contains "Client" and isn't a capability
            if importStatement.contains("Client") && 
               !importStatement.contains("Capability") &&
               importStatement != clientName {
                let error = "File \(path): \(clientName) cannot import \(importStatement): Clients must be isolated from each other"
                errors.append(error)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - Test Support

/// Mock implementation for testing
public struct MockClientDefinition {
    public let name: String
    public let dependencies: [String]
    
    public init(name: String, dependencies: [String]) {
        self.name = name
        self.dependencies = dependencies
    }
    
    /// Converts to ClientDefinition for validation
    public func toClientDefinition() -> ClientDefinition {
        return ClientDefinition(name: name, dependencies: dependencies)
    }
}