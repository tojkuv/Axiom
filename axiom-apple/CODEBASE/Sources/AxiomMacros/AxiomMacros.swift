import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AxiomPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
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
    ]
}