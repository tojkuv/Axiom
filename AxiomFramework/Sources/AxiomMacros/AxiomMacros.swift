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
        CrossCuttingMacro.self,
        ViewMacro.self,
        ContextMacro.self,
        
        // Additional macros (to be implemented)
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
            "@CrossCutting": "Inject supervised cross-cutting concerns like analytics, logging, and error reporting",
            "@View": "Generate SwiftUI view boilerplate with AxiomContext integration, lifecycle methods, and error handling",
            "@Context": "Comprehensive context orchestration automation - integrates @Client + @CrossCutting + context-specific features for 95% boilerplate reduction",
            "@ObservableState": "Make state observable with automatic updates (to be implemented)",
            "@Intelligence": "Enable intelligence features for a component (to be implemented)"
        ]
    }
}