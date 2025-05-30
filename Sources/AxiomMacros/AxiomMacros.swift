import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Axiom Macros Plugin

/// The main plugin that provides all Axiom macros
@main
public struct AxiomMacrosPlugin: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        // Example macro for testing infrastructure
        GreetingMacro.self,
        
        // Core Axiom macros
        ClientMacro.self,
        CapabilitiesMacro.self,
        DomainModelMacro.self,
        
        // Additional macros (to be implemented)
        // CrossCuttingMacro.self,
        // ObservableStateMacro.self,
        // IntelligenceMacro.self
    ]
    
    public init() {}
}

// MARK: - Macro Exports

// Re-export all macro declarations for easier importing
public extension AxiomMacrosPlugin {
    /// List of all available Axiom macros
    static var availableMacros: [String: String] {
        [
            "@Greeting": "Adds a greeting property to a struct (example macro)",
            "@Client": "Automatically inject and manage client dependencies",
            "@Capabilities": "Declare and validate capability requirements",
            "@DomainModel": "Generate domain model boilerplate including validation and immutable updates",
            "@CrossCutting": "Inject cross-cutting concerns (to be implemented)",
            "@ObservableState": "Make state observable with automatic updates (to be implemented)",
            "@Intelligence": "Enable intelligence features for a component (to be implemented)"
        ]
    }
}