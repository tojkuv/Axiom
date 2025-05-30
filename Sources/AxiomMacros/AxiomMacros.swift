import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct AxiomMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // Macros will be added here as they are implemented
    ]
}