import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AxiomMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // Core macros
        ClientMacro.self,
        ActionMacro.self,
        ContextMacro.self,
        
        // Testing macro
        AutoMockableMacro.self,
        
        // Capability macro
        CapabilityMacro.self,
        
        // Presentation macros
        PresentationMacro.self,
        
        // Navigation macro
        NavigationOrchestratorMacro.self,
        
        // Error handling macros
        ErrorBoundaryMacro.self,
        ErrorHandlingMacro.self,
        
        // State macro
        StateMacro.self,
        
        // Recovery strategy macro
        RecoveryStrategyMacro.self,
        
        // Error propagation macro
        PropagateErrorsMacro.self
    ]
}