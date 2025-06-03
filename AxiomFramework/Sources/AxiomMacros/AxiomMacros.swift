import SwiftCompilerPlugin
import SwiftSyntaxMacros

// MARK: - Axiom Macro Plugin

/// The Axiom macro plugin that provides all framework macros
@main
struct AxiomMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // Core Framework Macros (One macro per component)
        ClientMacro.self,
        ContextMacro.self,
        PresentationMacro.self,
        StateMacro.self,
        CapabilityMacro.self,
        ApplicationMacro.self,
        
        // Example/Test Macro
        GreetingMacro.self
    ]
}