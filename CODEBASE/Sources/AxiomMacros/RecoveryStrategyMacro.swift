import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// RecoveryStrategy macro implementation (REQUIREMENTS-W-06-005)
/// Generates strategy selection logic based on error types
public struct RecoveryStrategyMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro works in conjunction with @recoverable attributes on methods
        // It generates the infrastructure for recovery strategy selection
        
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw RecoveryStrategyMacroError.mustBeAppliedToClass
        }
        
        // Find all methods with @recoverable attributes
        var recoveryRules: [(method: String, rules: [RecoveryRule])] = []
        
        for member in classDecl.memberBlock.members {
            if let function = member.decl.as(FunctionDeclSyntax.self) {
                let rules = extractRecoveryRules(from: function)
                if !rules.isEmpty {
                    recoveryRules.append((method: function.name.text, rules: rules))
                }
            }
        }
        
        // Generate recovery infrastructure if any methods have recovery rules
        if !recoveryRules.isEmpty {
            return generateRecoveryInfrastructure(for: recoveryRules)
        }
        
        return []
    }
}

/// Recoverable macro - marks methods with recovery strategies
public struct RecoverableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This is a marker macro - the actual logic is handled by RecoveryStrategyMacro
        return []
    }
}

// Helper structures
private struct RecoveryRule {
    let errorCategory: String
    let strategy: String
}

// Helper functions
private func extractRecoveryRules(from function: FunctionDeclSyntax) -> [RecoveryRule] {
    var rules: [RecoveryRule] = []
    
    for attribute in function.attributes {
        if let attrSyntax = attribute.as(AttributeSyntax.self),
           attrSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "recoverable" {
            
            if let arguments = attrSyntax.arguments,
               case .argumentList(let argList) = arguments {
                
                var errorCategory: String?
                var strategy: String?
                
                // Extract error category (first positional argument)
                if let firstArg = argList.first,
                   firstArg.label == nil {
                    errorCategory = firstArg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Extract strategy
                for arg in argList {
                    if arg.label?.text == "strategy" {
                        strategy = arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                if let category = errorCategory, let strat = strategy {
                    rules.append(RecoveryRule(errorCategory: category, strategy: strat))
                }
            }
        }
    }
    
    return rules
}

private func generateRecoveryInfrastructure(for recoveryRules: [(method: String, rules: [RecoveryRule])]) -> [DeclSyntax] {
    var results: [DeclSyntax] = []
    
    // Generate method wrappers with recovery logic
    for (method, rules) in recoveryRules {
        let wrappedName = "_wrapped_\(method)"
        
        // Generate switch cases for each rule
        var switchCases = ""
        for rule in rules {
            switchCases += """
                        case \(rule.errorCategory):
                            strategy = \(rule.strategy)
                """
        }
        
        let methodWrapper = """
            
            // Recovery wrapper for \(method)
            func \(method)(_ amount: Decimal) async throws {
                do {
                    try await self.\(wrappedName)(amount)
                } catch {
                    let category = ErrorCategory.categorize(error)
                    let strategy: EnhancedRecoveryStrategy
                    
                    switch category {
            \(switchCases)
                    default:
                        strategy = RecoveryStrategySelector.defaultStrategy(for: error)
                    }
                    
                    return try await strategy.execute {
                        try await self.\(wrappedName)(amount)
                    }
                }
            }
            
            private func \(wrappedName)(_ amount: Decimal) async throws {
                // Original implementation placeholder
                fatalError("Original implementation should be preserved")
            }
            """
        
        results.append(DeclSyntax(stringLiteral: methodWrapper))
    }
    
    return results
}

enum RecoveryStrategyMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToClass
    case invalidRecoveryRule
    
    var description: String {
        switch self {
        case .mustBeAppliedToClass:
            return "@RecoveryStrategy can only be applied to classes"
        case .invalidRecoveryRule:
            return "Invalid recovery rule configuration"
        }
    }
}