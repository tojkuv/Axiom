import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AxiomMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ContextMacro.self,
        NavigationOrchestratorMacro.self,
        AutoMockableMacro.self,
        ErrorBoundaryMacro.self,
    ]
}