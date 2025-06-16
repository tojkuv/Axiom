import Foundation
import AxiomCore

// MARK: - API Documentation Generator

/// Generates standardized documentation for APIs following the framework conventions
/// Part of REQUIREMENTS-W-07-005-API-STANDARDIZATION-FRAMEWORK
public struct APIDocumentationGenerator {
    
    // MARK: - Documentation Generation
    
    /// Generate documentation for a CoreAPI
    public static func generateDocumentation(for api: CoreAPI) -> APIDocumentation {
        let component = api.component
        let operation = api.operation
        
        return APIDocumentation(
            api: api,
            purpose: generatePurpose(component: component, operation: operation),
            parameters: generateParameters(component: component, operation: operation),
            returnValue: generateReturnValue(component: component, operation: operation),
            example: generateExample(component: component, operation: operation),
            complexity: generateComplexity(operation: operation)
        )
    }
    
    /// Generate documentation for all CoreAPIs
    public static func generateCompleteDocumentation() -> [APIDocumentation] {
        return CoreAPI.allCases.map { generateDocumentation(for: $0) }
    }
    
    // MARK: - Purpose Generation
    
    private static func generatePurpose(component: String, operation: String) -> String {
        let componentDesc = componentDescription(component)
        let operationDesc = operationDescription(operation)
        
        switch (component, operation) {
        // Context operations
        case ("context", "create"):
            return "Creates a new \(componentDesc) with initial state and client binding"
        case ("context", "update"):
            return "Updates the \(componentDesc) state with new values"
        case ("context", "query"):
            return "Queries specific data from the \(componentDesc)"
        case ("context", "lifecycle"):
            return "Manages \(componentDesc) lifecycle events (appear/disappear)"
        case ("context", "binding"):
            return "Establishes data binding between \(componentDesc) and views"
        case ("context", "observation"):
            return "Sets up state observation for the \(componentDesc)"
        case ("context", "error"):
            return "Handles errors within the \(componentDesc) scope"
        case ("context", "cleanup"):
            return "Performs cleanup when \(componentDesc) is deallocated"
            
        // Client operations
        case ("client", "create"):
            return "Creates a new \(componentDesc) instance with initial configuration"
        case ("client", "process"):
            return "Processes an action through the \(componentDesc) state machine"
        case ("client", "state"):
            return "Accesses the current state of the \(componentDesc)"
        case ("client", "stream"):
            return "Provides an async stream of \(componentDesc) state changes"
        case ("client", "update"):
            return "Updates the \(componentDesc) state directly"
        case ("client", "query"):
            return "Queries specific data from the \(componentDesc)"
        case ("client", "observe"):
            return "Observes \(componentDesc) state changes"
        case ("client", "error"):
            return "Handles errors in \(componentDesc) operations"
        case ("client", "retry"):
            return "Retries failed \(componentDesc) operations"
        case ("client", "cache"):
            return "Manages \(componentDesc) state caching"
        case ("client", "mock"):
            return "Creates a mock \(componentDesc) for testing"
        case ("client", "cleanup"):
            return "Cleans up \(componentDesc) resources"
            
        // Navigation operations
        case ("navigate", "forward"):
            return "Navigates forward to a new destination"
        case ("navigate", "back"):
            return "Navigates back to the previous screen"
        case ("navigate", "dismiss"):
            return "Dismisses the current modal or sheet"
        case ("navigate", "root"):
            return "Navigates to the root of the navigation stack"
        case ("navigate", "route"):
            return "Navigates using a type-safe route"
        case ("navigate", "flow"):
            return "Manages multi-step navigation flows"
        case ("navigate", "deeplink"):
            return "Handles deep link navigation"
        case ("navigate", "pattern"):
            return "Navigates using pattern matching"
            
        // Default
        default:
            return "\(operationDesc) the \(componentDesc)"
        }
    }
    
    // MARK: - Parameter Generation
    
    private static func generateParameters(component: String, operation: String) -> [ParameterDocumentation] {
        switch (component, operation) {
        case ("context", "create"):
            return [
                ParameterDocumentation(name: "initialState", type: "State", description: "The initial state for the context"),
                ParameterDocumentation(name: "client", type: "Client", description: "The client to bind to this context")
            ]
        case ("context", "update"), ("client", "update"):
            return [
                ParameterDocumentation(name: "newValue", type: "State", description: "The new state value to set")
            ]
        case ("context", "query"), ("client", "query"):
            return [
                ParameterDocumentation(name: "query", type: "Query", description: "The query to execute")
            ]
        case ("client", "process"):
            return [
                ParameterDocumentation(name: "action", type: "Action", description: "The action to process")
            ]
        case ("navigate", "forward"), ("navigate", "route"):
            return [
                ParameterDocumentation(name: "destination", type: "Route", description: "The destination to navigate to"),
                ParameterDocumentation(name: "options", type: "NavigationOptions", description: "Navigation options (optional)")
            ]
        case ("navigate", "dismiss"):
            return [
                ParameterDocumentation(name: "animated", type: "Bool", description: "Whether to animate the dismissal")
            ]
        default:
            return []
        }
    }
    
    // MARK: - Return Value Generation
    
    private static func generateReturnValue(component: String, operation: String) -> String {
        switch operation {
        case "create":
            return "A new instance of \(componentDescription(component))"
        case "process", "update", "cleanup":
            return "AxiomResult<Void> indicating success or failure"
        case "get", "state":
            return "AxiomResult<State> containing the current state"
        case "query":
            return "AxiomResult<T> containing the query result"
        case "stream", "observe":
            return "AsyncStream<State> for continuous state updates"
        default:
            return "AxiomResult<Void>"
        }
    }
    
    // MARK: - Example Generation
    
    private static func generateExample(component: String, operation: String) -> String {
        switch (component, operation) {
        case ("context", "create"):
            return """
            let context = TaskContext(
                initialState: TaskState(),
                client: taskClient
            )
            """
        case ("context", "update"):
            return """
            let result = await context.update(newTaskState)
            switch result {
            case .success:
                print("State updated successfully")
            case .failure(let error):
                print("Update failed: \\(error)")
            }
            """
        case ("client", "process"):
            return """
            let result = await client.process(.loadTasks)
            if case .failure(let error) = result {
                // Handle error
            }
            """
        case ("navigate", "forward"):
            return """
            let result = await navigator.navigate(
                to: .taskDetail(id: taskId),
                options: .animated
            )
            """
        default:
            return "// Example usage for \(component).\(operation)"
        }
    }
    
    // MARK: - Complexity Generation
    
    private static func generateComplexity(operation: String) -> String {
        switch operation {
        case "get", "state":
            return "O(1)"
        case "query":
            return "O(n) where n is the data size"
        case "process", "update":
            return "O(1) for state update"
        case "stream", "observe":
            return "O(1) for subscription"
        default:
            return "O(1)"
        }
    }
    
    // MARK: - Helper Methods
    
    private static func componentDescription(_ component: String) -> String {
        switch component {
        case "context": return "context"
        case "client": return "client"
        case "navigate": return "navigation"
        case "capability": return "capability"
        case "orchestrator": return "orchestrator"
        case "test": return "test"
        default: return component
        }
    }
    
    private static func operationDescription(_ operation: String) -> String {
        switch operation {
        case "create": return "Creates"
        case "update": return "Updates"
        case "query": return "Queries"
        case "process": return "Processes"
        case "observe": return "Observes"
        case "cleanup": return "Cleans up"
        default: return operation.capitalized
        }
    }
}

// MARK: - Documentation Types

/// Represents complete documentation for an API
public struct APIDocumentation {
    public let api: CoreAPI
    public let purpose: String
    public let parameters: [ParameterDocumentation]
    public let returnValue: String
    public let example: String
    public let complexity: String
    
    /// Generate markdown documentation
    public var markdown: String {
        """
        ## \(api.rawValue)
        
        ### Purpose
        \(purpose)
        
        ### Parameters
        \(parameters.isEmpty ? "None" : parameters.map { "- `\($0.name)`: \($0.type) - \($0.description)" }.joined(separator: "\n"))
        
        ### Return Value
        \(returnValue)
        
        ### Example
        ```swift
        \(example)
        ```
        
        ### Complexity
        \(complexity)
        
        ---
        """
    }
    
    /// Generate DocC documentation
    public var docC: String {
        """
        /// \(purpose)
        ///
        /// - Parameters:
        \(parameters.map { "///   - \($0.name): \($0.description)" }.joined(separator: "\n"))
        /// - Returns: \(returnValue)
        /// - Complexity: \(complexity)
        """
    }
}

/// Represents documentation for a parameter
public struct ParameterDocumentation {
    public let name: String
    public let type: String
    public let description: String
}

// MARK: - Documentation Export

/// Exports documentation in various formats
public enum DocumentationExporter {
    
    /// Export all API documentation as markdown
    public static func exportMarkdown() -> String {
        let docs = APIDocumentationGenerator.generateCompleteDocumentation()
        
        let header = """
        # Axiom Framework API Reference
        
        This document provides complete API reference for the 47 essential APIs in the Axiom framework.
        
        ## API Naming Convention
        
        All APIs follow the pattern: `component.operation`
        
        ---
        
        """
        
        let content = docs.map { $0.markdown }.joined(separator: "\n")
        
        return header + content
    }
    
    /// Export documentation summary
    public static func exportSummary() -> String {
        let apis = CoreAPI.allCases
        let components = Dictionary(grouping: apis) { $0.component }
        
        var summary = "# API Summary\n\n"
        
        for (component, apis) in components.sorted(by: { $0.key < $1.key }) {
            summary += "## \(component.capitalized) (\(apis.count) APIs)\n"
            for api in apis {
                let doc = APIDocumentationGenerator.generateDocumentation(for: api)
                summary += "- **\(api.operation)**: \(doc.purpose)\n"
            }
            summary += "\n"
        }
        
        return summary
    }
    
    /// Export quick reference card
    public static func exportQuickReference() -> String {
        let apis = CoreAPI.allCases
        let components = Dictionary(grouping: apis) { $0.component }
        
        var reference = """
        # Axiom API Quick Reference
        
        """
        
        for (component, apis) in components.sorted(by: { $0.key < $1.key }) {
            reference += "**\(component)**:"
            reference += " " + apis.map { $0.operation }.joined(separator: ", ")
            reference += "\n"
        }
        
        return reference
    }
}

// MARK: - CoreAPI Documentation Extensions

extension CoreAPI {
    /// Get the component part of the API
    public var component: String {
        String(rawValue.split(separator: ".").first ?? "")
    }
    
    /// Get the operation part of the API
    public var operation: String {
        String(rawValue.split(separator: ".").last ?? "")
    }
    
    /// Get full documentation for this API
    public var documentation: APIDocumentation {
        APIDocumentationGenerator.generateDocumentation(for: self)
    }
}