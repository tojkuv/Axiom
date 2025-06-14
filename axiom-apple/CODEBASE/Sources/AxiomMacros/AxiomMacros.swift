import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AxiomPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // Existing macros
        ContextMacro.self,
        PresentationMacro.self,
        NavigationOrchestratorMacro.self,
        AutoMockableMacro.self,
        ErrorBoundaryMacro.self,
        ErrorHandlingMacro.self,
        ErrorContextMacro.self,
        CapabilityMacro.self,
        RecoveryStrategyMacro.self,
        RecoverableMacro.self,
        PropagateErrorsMacro.self,
        
        // New core developer experience macros
        ClientMacro.self,
        StateMacro.self,
        ActionMacro.self,
    ]
}