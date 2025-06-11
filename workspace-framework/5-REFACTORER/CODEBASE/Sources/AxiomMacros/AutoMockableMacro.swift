import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Enhanced macro that generates comprehensive mock implementations
///
/// Usage:
/// ```swift
/// @AutoMockable
/// protocol TaskService {
///     func loadTasks() async throws -> [Task]
///     var isLoading: Bool { get }
/// }
/// ```
///
/// This macro generates:
/// - MockTaskService with property recording
/// - Method call tracking
/// - Return value stubs
/// - Async support
/// - Validation helpers
/// - Test assertion methods
public struct AutoMockableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate this is applied to a protocol
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            throw AutoMockableError.unsupportedDeclaration
        }
        
        // Extract protocol name and members
        let protocolName = protocolDecl.name.text
        let mockName = "Mock\(protocolName)"
        
        // Extract mock configuration
        let configuration = try extractConfiguration(from: node)
        
        // Extract protocol methods and properties
        let methods = extractMethods(from: protocolDecl)
        let properties = extractProperties(from: protocolDecl)
        
        // Generate comprehensive mock implementation
        let mockClass = generateMockClass(
            mockName: mockName,
            protocolName: protocolName,
            methods: methods,
            properties: properties,
            configuration: configuration
        )
        
        return [mockClass]
    }
    
    // MARK: - Configuration and Data Structures
    
    private struct MockConfiguration {
        let includeCallCounting: Bool
        let includePropertyRecording: Bool
        let includeValidationHelpers: Bool
        let includeAsyncSupport: Bool
    }
    
    private struct MethodInfo {
        let name: String
        let parameters: [ParameterInfo]
        let returnType: String?
        let isAsync: Bool
        let isThrowing: Bool
    }
    
    private struct ParameterInfo {
        let label: String?
        let name: String
        let type: String
    }
    
    private struct PropertyInfo {
        let name: String
        let type: String
        let isGettable: Bool
        let isSettable: Bool
    }
    
    // MARK: - Configuration Extraction
    
    private static func extractConfiguration(from node: AttributeSyntax) throws -> MockConfiguration {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return MockConfiguration(
                includeCallCounting: true,
                includePropertyRecording: true,
                includeValidationHelpers: true,
                includeAsyncSupport: true
            )
        }
        
        var includeCallCounting = true
        var includePropertyRecording = true
        var includeValidationHelpers = true
        var includeAsyncSupport = true
        
        for argument in arguments {
            switch argument.label?.text {
            case "includeCallCounting":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeCallCounting = boolLiteral.literal.text == "true"
                }
            case "includePropertyRecording":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includePropertyRecording = boolLiteral.literal.text == "true"
                }
            case "includeValidationHelpers":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeValidationHelpers = boolLiteral.literal.text == "true"
                }
            case "includeAsyncSupport":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    includeAsyncSupport = boolLiteral.literal.text == "true"
                }
            default:
                break
            }
        }
        
        return MockConfiguration(
            includeCallCounting: includeCallCounting,
            includePropertyRecording: includePropertyRecording,
            includeValidationHelpers: includeValidationHelpers,
            includeAsyncSupport: includeAsyncSupport
        )
    }
    
    // MARK: - Protocol Analysis
    
    private static func extractMethods(from protocolDecl: ProtocolDeclSyntax) -> [MethodInfo] {
        var methods: [MethodInfo] = []
        
        for member in protocolDecl.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                let name = functionDecl.name.text
                let parameters = extractParameters(from: functionDecl.signature.parameterClause)
                let returnType = extractReturnType(from: functionDecl.signature.returnClause)
                let isAsync = functionDecl.signature.effectSpecifiers?.asyncSpecifier != nil
                let isThrowing = functionDecl.signature.effectSpecifiers?.throwsSpecifier != nil
                
                methods.append(MethodInfo(
                    name: name,
                    parameters: parameters,
                    returnType: returnType,
                    isAsync: isAsync,
                    isThrowing: isThrowing
                ))
            }
        }
        
        return methods
    }
    
    private static func extractProperties(from protocolDecl: ProtocolDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []
        
        for member in protocolDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                       let typeAnnotation = binding.typeAnnotation {
                        let name = pattern.identifier.text
                        let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)
                        
                        // Determine getter/setter based on accessor block
                        let isGettable = true // Protocols always have getters
                        let isSettable: Bool = {
                            guard let accessors = binding.accessorBlock?.accessors else { return false }
                            
                            switch accessors {
                            case .accessors(let list):
                                return list.contains { accessor in
                                    accessor.accessorSpecifier.text == "set"
                                }
                            case .getter:
                                return false
                            }
                        }()
                        
                        properties.append(PropertyInfo(
                            name: name,
                            type: type,
                            isGettable: isGettable,
                            isSettable: isSettable
                        ))
                    }
                }
            }
        }
        
        return properties
    }
    
    private static func extractParameters(from parameterClause: FunctionParameterClauseSyntax) -> [ParameterInfo] {
        return parameterClause.parameters.map { parameter in
            let label = parameter.firstName.text == "_" ? nil : parameter.firstName.text
            let name = parameter.secondName?.text ?? parameter.firstName.text
            let type = parameter.type.description.trimmingCharacters(in: .whitespaces)
            
            return ParameterInfo(label: label, name: name, type: type)
        }
    }
    
    private static func extractReturnType(from returnClause: ReturnClauseSyntax?) -> String? {
        return returnClause?.type.description.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Mock Class Generation
    
    private static func generateMockClass(
        mockName: String,
        protocolName: String,
        methods: [MethodInfo],
        properties: [PropertyInfo],
        configuration: MockConfiguration
    ) -> DeclSyntax {
        var classComponents: [String] = []
        
        // Class declaration
        classComponents.append("public class \(mockName): \(protocolName) {")
        
        // Call counting infrastructure
        if configuration.includeCallCounting {
            classComponents.append(generateCallCountingInfrastructure(methods: methods))
        }
        
        // Property recording infrastructure
        if configuration.includePropertyRecording {
            classComponents.append(generatePropertyRecordingInfrastructure(properties: properties))
        }
        
        // Property implementations
        classComponents.append(generatePropertyImplementations(properties: properties, configuration: configuration))
        
        // Method implementations
        classComponents.append(generateMethodImplementations(methods: methods, configuration: configuration))
        
        // Validation helpers
        if configuration.includeValidationHelpers {
            classComponents.append(generateValidationHelpers(methods: methods, properties: properties))
        }
        
        // Reset functionality
        classComponents.append(generateResetFunctionality(methods: methods, properties: properties, configuration: configuration))
        
        classComponents.append("}")
        
        return DeclSyntax(stringLiteral: classComponents.joined(separator: "\n\n"))
    }
    
    // MARK: - Infrastructure Generation
    
    private static func generateCallCountingInfrastructure(methods: [MethodInfo]) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Call Counting Infrastructure")
        
        for method in methods {
            components.append("    public private(set) var \(method.name)CallCount = 0")
            if !method.parameters.isEmpty {
                components.append("    public private(set) var \(method.name)CalledWith: [(\(method.parameters.map { $0.name + ": " + $0.type }.joined(separator: ", ")))] = []")
            }
        }
        
        return components.joined(separator: "\n")
    }
    
    private static func generatePropertyRecordingInfrastructure(properties: [PropertyInfo]) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Property Recording Infrastructure")
        
        for property in properties {
            if property.isGettable {
                components.append("    public private(set) var \(property.name)GetCount = 0")
            }
            if property.isSettable {
                components.append("    public private(set) var \(property.name)SetCount = 0")
                components.append("    public private(set) var \(property.name)SetValues: [\(property.type)] = []")
            }
        }
        
        return components.joined(separator: "\n")
    }
    
    // MARK: - Implementation Generation
    
    private static func generatePropertyImplementations(properties: [PropertyInfo], configuration: MockConfiguration) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Property Implementations")
        
        for property in properties {
            var propertyComponents: [String] = []
            
            // Storage for the property
            components.append("    private var _\(property.name): \(property.type)?")
            components.append("    public var \(property.name)Stub: \(property.type)?")
            
            // Property implementation
            propertyComponents.append("    public var \(property.name): \(property.type) {")
            
            if property.isGettable {
                propertyComponents.append("        get {")
                if configuration.includePropertyRecording {
                    propertyComponents.append("            \(property.name)GetCount += 1")
                }
                propertyComponents.append("            return \(property.name)Stub ?? _\(property.name) ?? defaultValue(for: \(property.type).self)")
                propertyComponents.append("        }")
            }
            
            if property.isSettable {
                propertyComponents.append("        set {")
                if configuration.includePropertyRecording {
                    propertyComponents.append("            \(property.name)SetCount += 1")
                    propertyComponents.append("            \(property.name)SetValues.append(newValue)")
                }
                propertyComponents.append("            _\(property.name) = newValue")
                propertyComponents.append("        }")
            }
            
            propertyComponents.append("    }")
            
            components.append(propertyComponents.joined(separator: "\n"))
        }
        
        return components.joined(separator: "\n\n")
    }
    
    private static func generateMethodImplementations(methods: [MethodInfo], configuration: MockConfiguration) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Method Implementations")
        
        for method in methods {
            var methodComponents: [String] = []
            
            // Stub storage
            let returnTypeString = method.returnType ?? "Void"
            if method.returnType != nil {
                components.append("    public var \(method.name)Stub: \(returnTypeString)?")
            }
            
            // Error stub for throwing methods
            if method.isThrowing {
                components.append("    public var \(method.name)ErrorStub: Error?")
            }
            
            // Method signature
            let parameters = method.parameters.map { param in
                let label = param.label.map { "\($0) " } ?? ""
                return "\(label)\(param.name): \(param.type)"
            }.joined(separator: ", ")
            
            let asyncKeyword = method.isAsync ? " async" : ""
            let throwsKeyword = method.isThrowing ? " throws" : ""
            let returnClause = method.returnType.map { " -> \($0)" } ?? ""
            
            methodComponents.append("    public func \(method.name)(\(parameters))\(asyncKeyword)\(throwsKeyword)\(returnClause) {")
            
            // Call counting
            if configuration.includeCallCounting {
                methodComponents.append("        \(method.name)CallCount += 1")
                if !method.parameters.isEmpty {
                    let parameterTuple = "(\(method.parameters.map { $0.name + ": " + $0.name }.joined(separator: ", ")))"
                    methodComponents.append("        \(method.name)CalledWith.append(\(parameterTuple))")
                }
            }
            
            // Error handling for throwing methods
            if method.isThrowing {
                methodComponents.append("        if let error = \(method.name)ErrorStub {")
                methodComponents.append("            throw error")
                methodComponents.append("        }")
            }
            
            // Return value handling
            if let returnType = method.returnType {
                methodComponents.append("        return \(method.name)Stub ?? defaultValue(for: \(returnType).self)")
            }
            
            methodComponents.append("    }")
            
            components.append(methodComponents.joined(separator: "\n"))
        }
        
        return components.joined(separator: "\n\n")
    }
    
    // MARK: - Helper Generation
    
    private static func generateValidationHelpers(methods: [MethodInfo], properties: [PropertyInfo]) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Validation Helpers")
        
        // Method call validation
        for method in methods {
            components.append("    public func verify\(method.name.capitalized)Called(times: Int = 1) -> Bool {")
            components.append("        return \(method.name)CallCount == times")
            components.append("    }")
            
            if !method.parameters.isEmpty {
                components.append("    public func verify\(method.name.capitalized)CalledWith(\(method.parameters.map { "\($0.name): \($0.type)" }.joined(separator: ", "))) -> Bool {")
                let comparisonTuple = "(\(method.parameters.map { $0.name + ": " + $0.name }.joined(separator: ", ")))"
                components.append("        return \(method.name)CalledWith.contains { $0 == \(comparisonTuple) }")
                components.append("    }")
            }
        }
        
        // Property access validation
        for property in properties {
            if property.isGettable {
                components.append("    public func verify\(property.name.capitalized)Accessed(times: Int = 1) -> Bool {")
                components.append("        return \(property.name)GetCount == times")
                components.append("    }")
            }
            
            if property.isSettable {
                components.append("    public func verify\(property.name.capitalized)Set(times: Int = 1) -> Bool {")
                components.append("        return \(property.name)SetCount == times")
                components.append("    }")
                
                components.append("    public func verify\(property.name.capitalized)SetTo(_ value: \(property.type)) -> Bool {")
                components.append("        return \(property.name)SetValues.contains { $0 == value }")
                components.append("    }")
            }
        }
        
        return components.joined(separator: "\n\n")
    }
    
    private static func generateResetFunctionality(methods: [MethodInfo], properties: [PropertyInfo], configuration: MockConfiguration) -> String {
        var components: [String] = []
        
        components.append("    // MARK: - Reset Functionality")
        components.append("    public func reset() {")
        
        // Reset call counts
        if configuration.includeCallCounting {
            for method in methods {
                components.append("        \(method.name)CallCount = 0")
                if !method.parameters.isEmpty {
                    components.append("        \(method.name)CalledWith.removeAll()")
                }
            }
        }
        
        // Reset property recording
        if configuration.includePropertyRecording {
            for property in properties {
                if property.isGettable {
                    components.append("        \(property.name)GetCount = 0")
                }
                if property.isSettable {
                    components.append("        \(property.name)SetCount = 0")
                    components.append("        \(property.name)SetValues.removeAll()")
                }
            }
        }
        
        // Reset stubs
        for method in methods {
            if method.returnType != nil {
                components.append("        \(method.name)Stub = nil")
            }
            if method.isThrowing {
                components.append("        \(method.name)ErrorStub = nil")
            }
        }
        
        for property in properties {
            components.append("        \(property.name)Stub = nil")
            components.append("        _\(property.name) = nil")
        }
        
        components.append("    }")
        
        // Default value helper
        components.append("")
        components.append("    private func defaultValue<T>(for type: T.Type) -> T {")
        components.append("        switch type {")
        components.append("        case is String.Type: return \"\" as! T")
        components.append("        case is Int.Type: return 0 as! T")
        components.append("        case is Bool.Type: return false as! T")
        components.append("        case is Array<Any>.Type: return [] as! T")
        components.append("        case is Dictionary<AnyHashable, Any>.Type: return [:] as! T")
        components.append("        default: fatalError(\"No default value for type \\(type)\")")
        components.append("        }")
        components.append("    }")
        
        return components.joined(separator: "\n")
    }
}

// MARK: - Error Types

enum AutoMockableError: Error, CustomStringConvertible {
    case unsupportedDeclaration
    case invalidConfiguration
    
    var description: String {
        switch self {
        case .unsupportedDeclaration:
            return "@AutoMockable can only be applied to protocols"
        case .invalidConfiguration:
            return "@AutoMockable configuration is invalid"
        }
    }
}