import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

// MARK: - Enhanced Diagnostic System

/// Enhanced diagnostic system with context awareness and suggestions
public class EnhancedDiagnosticSystem {
    private let context: any MacroExpansionContext
    private let coordinator: MacroCoordinator
    
    public init(context: any MacroExpansionContext, coordinator: MacroCoordinator) {
        self.context = context
        self.coordinator = coordinator
    }
    
    /// Validate macro application with enhanced context awareness
    public func validateMacroApplication<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        on declaration: D,
        with node: AttributeSyntax
    ) -> ValidationResult {
        var issues: [DiagnosticIssue] = []
        
        // 1. Context-aware declaration validation
        issues.append(contentsOf: validateDeclarationContext(macro, declaration, node))
        
        // 2. Cross-macro compatibility validation
        issues.append(contentsOf: validateCrossMacroCompatibility(macro, declaration, node))
        
        // 3. Architectural constraint validation
        issues.append(contentsOf: validateArchitecturalConstraints(macro, declaration, node))
        
        // 4. Generate intelligent suggestions
        let suggestions = generateIntelligentSuggestions(for: issues, macro: macro, declaration: declaration)
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            suggestions: suggestions
        )
    }
    
    /// Validate declaration type compatibility
    public func validateDeclarationType<D: DeclSyntaxProtocol>(
        _ declaration: D,
        for macro: ComposableMacro.Type
    ) throws {
        let declarationType = getDeclarationType(declaration)
        let allowedTypes = getAllowedDeclarationTypes(for: macro)
        
        if !allowedTypes.contains(declarationType) {
            throw ValidationError.incompatibleDeclarationType(
                macro: macro.macroName,
                declarationType: declarationType,
                allowedTypes: allowedTypes
            )
        }
    }
    
    // MARK: - Private Validation Methods
    
    private func validateDeclarationContext<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [DiagnosticIssue] {
        var issues: [DiagnosticIssue] = []
        
        // Enhanced declaration type validation
        let declarationType = getDeclarationType(declaration)
        let allowedTypes = getAllowedDeclarationTypes(for: macro)
        
        if !allowedTypes.contains(declarationType) {
            issues.append(DiagnosticIssue(
                severity: .error,
                message: "'\(macro.macroName)' cannot be applied to \(declarationType)",
                node: node,
                suggestions: [
                    "Apply '\(macro.macroName)' to: \(allowedTypes.joined(separator: ", "))",
                    "Consider using a different macro for \(declarationType) declarations"
                ],
                fixIts: generateDeclarationTypeFixIts(macro, declaration, node),
                category: .declarationType
            ))
        }
        
        // Protocol conformance validation with context
        if let requiredProtocols = getRequiredProtocols(for: macro) {
            for protocolName in requiredProtocols {
                if !SyntaxUtilities.conformsToProtocol(declaration, protocolName: protocolName) {
                    issues.append(DiagnosticIssue(
                        severity: .error,
                        message: "'\(macro.macroName)' requires '\(String(describing: declaration))' to conform to '\(protocolName)'",
                        node: node,
                        suggestions: [
                            "Add '\(protocolName)' to the inheritance clause",
                            "Implement required '\(protocolName)' methods"
                        ],
                        fixIts: generateProtocolConformanceFixIts(protocolName, declaration, node),
                        category: .protocolConformance
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func validateCrossMacroCompatibility<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [DiagnosticIssue] {
        var issues: [DiagnosticIssue] = []
        let sharedContext = coordinator.getSharedContext()
        
        // Check for naming conflicts
        let membersToGenerate = predictGeneratedMembers(macro, declaration)
        for memberName in membersToGenerate {
            if sharedContext.isNameReserved(memberName) {
                issues.append(DiagnosticIssue(
                    severity: .warning,
                    message: "Generated member '\(memberName)' may conflict with existing member",
                    node: node,
                    suggestions: [
                        "Use unique naming in your implementation",
                        "Consider reordering macro applications"
                    ],
                    fixIts: generateNamingConflictFixIts(memberName, node),
                    category: .namingConflict
                ))
            }
        }
        
        return issues
    }
    
    private func validateArchitecturalConstraints<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [DiagnosticIssue] {
        var issues: [DiagnosticIssue] = []
        
        // Validate against architectural constraints
        // Example: @Client should only be used in @Context-enabled classes
        if macro.macroName == "Client" {
            if !hasContextMacro(declaration) && !isContextConformant(declaration) {
                issues.append(DiagnosticIssue(
                    severity: .warning,
                    message: "@Client is most effective when used with @Context or AxiomContext conformance",
                    node: node,
                    suggestions: [
                        "Add @Context macro to automate client orchestration",
                        "Ensure class conforms to AxiomContext protocol",
                        "Consider using @Context(clients: [ClientType.self]) for full automation"
                    ],
                    fixIts: generateContextIntegrationFixIts(declaration, node),
                    category: .architecturalConstraint
                ))
            }
        }
        
        return issues
    }
    
    private func generateIntelligentSuggestions<D: DeclSyntaxProtocol>(
        for issues: [DiagnosticIssue],
        macro: ComposableMacro.Type,
        declaration: D
    ) -> [String] {
        var suggestions: [String] = []
        
        // Collect suggestions from individual issues
        for issue in issues {
            suggestions.append(contentsOf: issue.suggestions)
        }
        
        // Generate context-aware suggestions
        if issues.contains(where: { $0.category == .declarationType }) {
            let declarationType = getDeclarationType(declaration)
            if declarationType == "enum" && macro.macroName == "View" {
                suggestions.append("Consider using 'struct' instead of 'enum' for SwiftUI views")
            }
        }
        
        // Suggest complementary macros
        let registeredMacros = coordinator.getRegisteredMacros()
        if macro.macroName == "Client" && registeredMacros.contains("Context") {
            suggestions.append("Consider adding @Context macro for comprehensive client orchestration")
        }
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func getDeclarationType<D: DeclSyntaxProtocol>(_ declaration: D) -> String {
        if declaration is StructDeclSyntax {
            return "struct"
        } else if declaration is ClassDeclSyntax {
            return "class"
        } else if declaration is ActorDeclSyntax {
            return "actor"
        } else if declaration is EnumDeclSyntax {
            return "enum"
        } else if declaration is ProtocolDeclSyntax {
            return "protocol"
        }
        return "unknown"
    }
    
    private func getAllowedDeclarationTypes(for macro: ComposableMacro.Type) -> [String] {
        switch macro.macroName {
        case "Client":
            return ["actor"]
        case "Context":
            return ["struct", "class"]
        case "View":
            return ["struct"]
        case "Intelligence":
            return ["struct", "class", "actor"]
        case "ObservableState":
            return ["struct", "class"]
        case "Capabilities":
            return ["actor"]
        case "DomainModel":
            return ["struct"]
        case "CrossCutting":
            return ["struct", "class"]
        default:
            return ["struct", "class", "actor"]
        }
    }
    
    private func getRequiredProtocols(for macro: ComposableMacro.Type) -> [String]? {
        switch macro.macroName {
        case "Context":
            return ["AxiomContext"]
        case "View":
            return ["AxiomView"]
        case "Client":
            return ["AxiomClient"]
        default:
            return nil
        }
    }
    
    private func predictGeneratedMembers<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        _ declaration: D
    ) -> [String] {
        switch macro.macroName {
        case "Client":
            return ["client", "clientContainer"]
        case "Context":
            return ["client", "intelligence", "capabilities"]
        case "Intelligence":
            return ["intelligenceFeatures", "registerIntelligenceCapabilities"]
        case "ObservableState":
            return ["_stateVersion", "notifyStateChange"]
        default:
            return []
        }
    }
    
    private func hasContextMacro<D: DeclSyntaxProtocol>(_ declaration: D) -> Bool {
        // Check if declaration has @Context macro
        // This would require more sophisticated AST traversal
        return false // Simplified implementation
    }
    
    private func isContextConformant<D: DeclSyntaxProtocol>(_ declaration: D) -> Bool {
        // Check if declaration conforms to AxiomContext
        return SyntaxUtilities.conformsToProtocol(declaration, protocolName: "AxiomContext")
    }
    
    private func generateDeclarationTypeFixIts<D: DeclSyntaxProtocol>(
        _ macro: ComposableMacro.Type,
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [FixIt] {
        // Generate Fix-Its for declaration type issues
        return [] // Simplified implementation
    }
    
    private func generateProtocolConformanceFixIts<D: DeclSyntaxProtocol>(
        _ protocolName: String,
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [FixIt] {
        // Generate Fix-Its for protocol conformance
        // For now, return empty array to focus on core functionality
        return []
    }
    
    private func generateNamingConflictFixIts(
        _ memberName: String,
        _ node: AttributeSyntax
    ) -> [FixIt] {
        // Generate Fix-Its for naming conflicts
        return [] // Simplified implementation
    }
    
    private func generateContextIntegrationFixIts<D: DeclSyntaxProtocol>(
        _ declaration: D,
        _ node: AttributeSyntax
    ) -> [FixIt] {
        // Generate Fix-Its for context integration
        return [] // Simplified implementation
    }
}

// MARK: - Diagnostic Types

/// Represents a diagnostic issue with enhanced information
public struct DiagnosticIssue {
    public let severity: DiagnosticSeverity
    public let message: String
    public let node: SyntaxProtocol
    public let suggestions: [String]
    public let fixIts: [FixIt]
    public let category: DiagnosticCategory
    
    public init(
        severity: DiagnosticSeverity,
        message: String,
        node: SyntaxProtocol,
        suggestions: [String] = [],
        fixIts: [FixIt] = [],
        category: DiagnosticCategory = .general
    ) {
        self.severity = severity
        self.message = message
        self.node = node
        self.suggestions = suggestions
        self.fixIts = fixIts
        self.category = category
    }
}

/// Categories for organizing diagnostics
public enum DiagnosticCategory: String, CaseIterable {
    case general
    case declarationType
    case protocolConformance
    case namingConflict
    case architecturalConstraint
    case macroComposition
    case performanceOptimization
    case bestPractice
}

/// Enhanced validation result with actionable information
public struct ValidationResult {
    public let isValid: Bool
    public let issues: [DiagnosticIssue]
    public let suggestions: [String]
    
    public init(isValid: Bool, issues: [DiagnosticIssue], suggestions: [String]) {
        self.isValid = isValid
        self.issues = issues
        self.suggestions = suggestions
    }
    
    public var hasErrors: Bool {
        issues.contains { $0.severity == .error }
    }
    
    public var hasWarnings: Bool {
        issues.contains { $0.severity == .warning }
    }
    
    public func issuesByCategory() -> [DiagnosticCategory: [DiagnosticIssue]] {
        Dictionary(grouping: issues) { $0.category }
    }
}

/// Validation errors
public enum ValidationError: Error, LocalizedError {
    case incompatibleDeclarationType(macro: String, declarationType: String, allowedTypes: [String])
    case missingProtocolConformance(macro: String, protocol: String)
    case namingConflict(memberName: String, conflictingMacro: String)
    
    public var errorDescription: String? {
        switch self {
        case .incompatibleDeclarationType(let macro, let type, let allowed):
            return "Macro '\(macro)' cannot be applied to '\(type)'. Allowed types: \(allowed.joined(separator: ", "))"
        case .missingProtocolConformance(let macro, let protocolName):
            return "Macro '\(macro)' requires conformance to '\(protocolName)'"
        case .namingConflict(let member, let conflicting):
            return "Member '\(member)' conflicts with member generated by '\(conflicting)'"
        }
    }
}