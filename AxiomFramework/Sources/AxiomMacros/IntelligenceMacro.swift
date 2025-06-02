import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

// MARK: - @Intelligence Macro Implementation

/// The @Intelligence macro for feature configuration and capability registration
/// Applied to structs, classes, or actors to enable intelligence features
public struct IntelligenceMacro: MemberMacro, AxiomMacro {
    public static var macroName: String { "Intelligence" }
    
    public static func validateDeclaration<D: DeclSyntaxProtocol>(_ declaration: D, in context: some MacroExpansionContext) throws {
        // Validation is performed during expansion to provide better context
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate this is applied to a struct, class, or actor only
        let isStruct = declaration.as(StructDeclSyntax.self) != nil
        let isClass = declaration.as(ClassDeclSyntax.self) != nil
        let isActor = declaration.as(ActorDeclSyntax.self) != nil
        
        guard isStruct || isClass || isActor else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: IntelligenceMacroDiagnostic.onlyOnStructsClassesActors
                )
            )
            return []
        }
        
        // Extract features from the macro argument
        let features = try extractFeatures(from: node, in: context)
        guard !features.isEmpty || hasEmptyFeaturesArray(node) else {
            return []
        }
        
        // Validate that the declaration has an AxiomIntelligence property
        let members: MemberBlockItemListSyntax
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            members = structDecl.memberBlock.members
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            members = classDecl.memberBlock.members
        } else if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            members = actorDecl.memberBlock.members
        } else {
            members = MemberBlockItemListSyntax([])
        }
        
        guard hasAxiomIntelligenceProperty(in: members) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: IntelligenceMacroDiagnostic.missingIntelligenceProperty
                )
            )
            return []
        }
        
        // Generate the boilerplate code as individual strings and concatenate them
        var codeString = ""
        
        // Generate intelligence configuration property with MARK comment
        let configProperty = generateIntelligenceConfigProperty(features: features)
        codeString += configProperty
        
        // Generate registration method with MARK comment  
        let registrationMethod = generateRegistrationMethod(features: features)
        codeString += registrationMethod
        
        // Generate query methods for each feature (if any exist)
        if !features.isEmpty {
            // Add MARK comment for query methods section
            codeString += "// MARK: - Intelligence Query Methods\n"
            
            for feature in features {
                let queryMethod = generateQueryMethod(for: feature)
                codeString += queryMethod
            }
        }
        
        // Add MARK comment for status methods section
        codeString += "// MARK: - Intelligence Status Methods\n"
        
        // Generate status methods
        let statusMethods = generateStatusMethods()
        for (index, statusMethod) in statusMethods.enumerated() {
            codeString += statusMethod
            if index == 0 && statusMethods.count > 1 {
                codeString += "\n"  // Add blank line after first method
            }
        }
        
        // Ensure proper final formatting
        codeString = codeString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return [DeclSyntax(stringLiteral: codeString)]
    }
    
    // MARK: - Feature Extraction
    
    private static func extractFeatures(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) throws -> [String] {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: IntelligenceMacroDiagnostic.missingFeaturesArgument
                )
            )
            return []
        }
        
        // Look for the features argument
        guard let featuresArgument = argumentList.first(where: { arg in
            arg.label?.text == "features"
        }) else {
            context.diagnose(
                SyntaxUtilities.createDiagnostic(
                    node: node,
                    message: IntelligenceMacroDiagnostic.missingFeaturesArgument
                )
            )
            return []
        }
        
        // Extract features from array literal
        guard let arrayExpr = featuresArgument.expression.as(ArrayExprSyntax.self) else {
            // Not an array literal, could be empty or invalid
            return []
        }
        
        var features: [String] = []
        for element in arrayExpr.elements {
            if let stringLiteral = element.expression.as(StringLiteralExprSyntax.self),
               let value = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text {
                features.append(value)
            }
        }
        
        return features
    }
    
    private static func hasEmptyFeaturesArray(_ node: AttributeSyntax) -> Bool {
        guard let arguments = node.arguments,
              case .argumentList(let argumentList) = arguments,
              let featuresArgument = argumentList.first(where: { $0.label?.text == "features" }),
              let arrayExpr = featuresArgument.expression.as(ArrayExprSyntax.self) else {
            return false
        }
        
        return arrayExpr.elements.isEmpty
    }
    
    // MARK: - Validation Helpers
    
    private static func hasAxiomIntelligenceProperty(in members: MemberBlockItemListSyntax) -> Bool {
        return members.contains { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                return false
            }
            
            for binding in varDecl.bindings {
                if let typeAnnotation = binding.typeAnnotation?.type,
                   typeAnnotation.trimmedDescription == "AxiomIntelligence" {
                    return true
                }
            }
            
            return false
        }
    }
    
    // MARK: - Code Generation
    
    private static func generateIntelligenceConfigProperty(features: [String]) -> String {
        let featuresString = features.map { "\"\($0)\"" }.joined(separator: ", ")
        let initializer = "[\(featuresString)]"
        
        return """

        // MARK: - Intelligence Configuration
        private let intelligenceFeatures: Set<String> = \(initializer)
        
        """
    }
    
    private static func generateRegistrationMethod(features: [String]) -> String {
        var enableStatements = ""
        if !features.isEmpty {
            let enableLines = features.map { "    await intelligence.enableFeature(\"\($0)\")" }
            enableStatements = "\n" + enableLines.joined(separator: "\n")
        }
        
        return """
        // MARK: - Intelligence Capability Registration
        func registerIntelligenceCapabilities() async {
            await intelligence.registerCapabilities(features: intelligenceFeatures)\(enableStatements)
        }
        
        """
    }
    
    private static func generateQueryMethod(for feature: String) -> String {
        let methodName = "query" + feature.toPascalCase()
        
        return """
        func \(methodName)(_ query: String) async -> String? {
            guard intelligenceFeatures.contains("\(feature)") else { return nil }
            return await intelligence.query(query, feature: "\(feature)")
        }
        
        """
    }
    
    private static func generateStatusMethods() -> [String] {
        let isEnabledMethod = """
        func isIntelligenceFeatureEnabled(_ feature: String) -> Bool {
            return intelligenceFeatures.contains(feature)
        }
        """
        
        let getEnabledMethod = """
        func getEnabledIntelligenceFeatures() -> Set<String> {
            return intelligenceFeatures
        }
        """
        
        return [isEnabledMethod, getEnabledMethod]
    }
}

// MARK: - Supporting Extensions

private extension String {
    /// Converts a string to PascalCase for method naming
    func toPascalCase() -> String {
        // If it contains underscore or hyphen, split and capitalize each part
        if self.contains("_") || self.contains("-") {
            let components = self.components(separatedBy: CharacterSet(charactersIn: "_-"))
            return components.map { component in
                guard !component.isEmpty else { return "" }
                return component.capitalized
            }.joined()
        }
        
        // If it's already camelCase, just capitalize the first letter
        guard !self.isEmpty else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }
}

// MARK: - Diagnostic Messages

/// Diagnostic messages specific to the @Intelligence macro
enum IntelligenceMacroDiagnostic: String, DiagnosticMessage {
    case onlyOnStructsClassesActors
    case missingFeaturesArgument
    case missingIntelligenceProperty
    case invalidFeaturesFormat
    case conflictingMacros
    
    var message: String {
        switch self {
        case .onlyOnStructsClassesActors:
            return "@Intelligence can only be applied to structs or classes"
        case .missingFeaturesArgument:
            return "@Intelligence requires a features array argument"
        case .missingIntelligenceProperty:
            return "@Intelligence requires a property of type AxiomIntelligence"
        case .invalidFeaturesFormat:
            return "@Intelligence features must be an array of strings"
        case .conflictingMacros:
            return "@Intelligence conflicts with other intelligence-related macros"
        }
    }
    
    var diagnosticID: MessageID {
        MessageID(domain: "AxiomMacros.Intelligence", id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        .error
    }
}

// MARK: - Macro Declaration

/// The @Intelligence macro adds intelligence feature configuration and capability registration
@attached(member, names: named(intelligenceFeatures), named(registerIntelligenceCapabilities), named(isIntelligenceFeatureEnabled), named(getEnabledIntelligenceFeatures), arbitrary)
public macro Intelligence(features: [String]) = #externalMacro(module: "AxiomMacros", type: "IntelligenceMacro")