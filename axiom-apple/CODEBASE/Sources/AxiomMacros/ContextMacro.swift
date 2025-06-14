import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Enhanced macro that generates comprehensive context boilerplate
///
/// Usage:
/// ```swift
/// @Context(client: TaskClient.self)
/// struct TaskListContext {
///     func loadTasks() async {
///         await client.process(.loadTasks)
///     }
/// }
/// ```
///
/// This macro generates:
/// - Client property and initialization
/// - @Published properties from client state
/// - Automatic client state observation
/// - Lifecycle management (viewAppeared/viewDisappeared)
/// - SwiftUI ObservableObject conformance
/// - Error boundary integration
public struct ContextMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Support both struct and class declarations
        let isStruct = declaration.is(StructDeclSyntax.self)
        let isClass = declaration.is(ClassDeclSyntax.self)
        
        guard isStruct || isClass else {
            throw MacroError.unsupportedDeclaration
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        // Generate organized member groups
        let clientMember = generateClientMember(parameters.clientType)
        let publishedProperties = generatePublishedProperties(parameters)
        let stateMembers = generateStateMembers()
        let lifecycleMethods = generateEnhancedLifecycleMethods(parameters)
        let observationMethods = generateEnhancedObservationMethods(parameters)
        let initMethod = generateInitializer(parameters)
        let errorHandling = generateErrorHandling(parameters)
        
        // Combine all members
        return [clientMember] + publishedProperties + stateMembers + 
               [initMethod] + lifecycleMethods + observationMethods + errorHandling
    }
    
    // MARK: - Parameter Extraction
    
    private struct MacroParameters {
        let clientType: String
        let observedKeyPaths: [String]
        let errorHandling: ErrorHandlingStrategy
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> MacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw MacroError.invalidArguments
        }
        
        var clientType: String?
        var observedKeyPaths: [String] = []
        var errorHandling = ErrorHandlingStrategy.automatic
        
        for argument in arguments {
            switch argument.label?.text {
            case "client":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    clientType = memberAccess.base?.description.trimmingCharacters(in: .whitespaces)
                }
            case "observes":
                // Parse observed key paths if provided
                if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                    observedKeyPaths = arrayExpr.elements.compactMap { element in
                        element.expression.description.trimmingCharacters(in: .whitespaces)
                    }
                }
            case "errorHandling":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let strategy = memberAccess.declName.baseName.text
                    errorHandling = ErrorHandlingStrategy(rawValue: strategy) ?? .automatic
                }
            default:
                break
            }
        }
        
        guard let client = clientType else {
            throw MacroError.missingClientType
        }
        
        // If no observed keypaths specified, generate defaults
        if observedKeyPaths.isEmpty {
            observedKeyPaths = ["tasks", "isLoading", "error"]
        }
        
        return MacroParameters(
            clientType: client,
            observedKeyPaths: observedKeyPaths,
            errorHandling: errorHandling
        )
    }
    
    // MARK: - Member Generation Helpers
    
    private static func generateClientMember(_ clientType: String) -> DeclSyntax {
        return """
        
        // MARK: - Generated Client
        
        /// The client this context observes
        public let client: \(raw: clientType)
        """
    }
    
    private static func generatePublishedProperties(_ parameters: MacroParameters) -> [DeclSyntax] {
        var properties: [DeclSyntax] = [
            """
            
            // MARK: - Generated Published Properties
            """
        ]
        
        // Generate @Published properties based on observed keypaths
        for keyPath in parameters.observedKeyPaths {
            let propertyName = keyPath.split(separator: ".").last ?? Substring(keyPath)
            properties.append("""
            
            /// Auto-generated from client state
            @Published public var \(raw: propertyName): Any?
            """)
        }
        
        return properties
    }
    
    private static func generateStateMembers() -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated State Management
            
            /// Tracks if context is currently active
            public private(set) var isActive = false
            """,
            """
            
            /// Task managing client state observation
            private var observationTask: Task<Void, Never>?
            """,
            """
            
            /// Tracks initialization state
            private var isInitialized = false
            """
        ]
    }
    
    private static func generateInitializer(_ parameters: MacroParameters) -> DeclSyntax {
        return """
        
        // MARK: - Generated Initializer
        
        public init(client: \(raw: parameters.clientType)) {
            self.client = client
            setupInitialState()
        }
        """
    }
    
    private static func generateEnhancedLifecycleMethods(_ parameters: MacroParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Lifecycle Methods
            
            /// Called when view appears
            public func viewAppeared() async {
                guard !isActive else { return }
                isActive = true
                startObservation()
                await handleAppearance()
            }
            """,
            """
            
            /// Called when view disappears
            public func viewDisappeared() async {
                stopObservation()
                isActive = false
                await handleDisappearance()
            }
            """,
            """
            
            /// Setup initial state
            private func setupInitialState() {
                // Initialize @Published properties with default values
                \(raw: parameters.observedKeyPaths.map { keyPath in
                    let propertyName = keyPath.split(separator: ".").last ?? Substring(keyPath)
                    return "self.\(propertyName) = nil"
                }.joined(separator: "\n        "))
            }
            """,
            """
            
            /// Handle appearance logic
            private func handleAppearance() async {
                // Override in concrete implementation if needed
            }
            """,
            """
            
            /// Handle disappearance logic  
            private func handleDisappearance() async {
                // Override in concrete implementation if needed
            }
            """
        ]
    }
    
    private static func generateEnhancedObservationMethods(_ parameters: MacroParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Observation Management
            
            private func startObservation() {
                observationTask = Task { [weak self] in
                    guard let self = self else { return }
                    let stream = await self.client.stateStream
                    for await state in stream {
                        await self.handleStateUpdate(state)
                    }
                }
            }
            """,
            """
            
            private func stopObservation() {
                observationTask?.cancel()
                observationTask = nil
            }
            """,
            """
            
            @MainActor
            public func handleStateUpdate(_ state: Any) async {
                // Update @Published properties from client state
                // Subclasses should override this method to update their specific properties
                // Default implementation does nothing
            }
            """
        ]
    }
    
    private static func generateErrorHandling(_ parameters: MacroParameters) -> [DeclSyntax] {
        guard parameters.errorHandling == .automatic else {
            return []
        }
        
        return [
            """
            
            // MARK: - Generated Error Handling
            
            /// Captures and handles errors from client operations
            @Published public var error: Error?
            
            /// Execute an action with automatic error handling
            public func withErrorHandling(_ action: () async throws -> Void) async {
                do {
                    try await action()
                } catch {
                    self.error = error
                }
            }
            """
        ]
    }
}

// MARK: - Supporting Types

enum ErrorHandlingStrategy: String {
    case automatic
    case custom
    case none
}

// MARK: - Error Types

enum MacroError: Error, CustomStringConvertible {
    case invalidArguments
    case unsupportedDeclaration
    case missingClientType
    
    var description: String {
        switch self {
        case .invalidArguments:
            return "@Context requires 'client' parameter with a Client type"
        case .unsupportedDeclaration:
            return "@Context can only be applied to structs or classes"
        case .missingClientType:
            return "@Context requires a client type parameter"
        }
    }
}

// MARK: - Plugin Registration

extension ContextMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Extract type name
        let typeName = if let structDecl = declaration.as(StructDeclSyntax.self) {
            structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            classDecl.name.text
        } else {
            throw MacroError.unsupportedDeclaration
        }
        
        // Generate ObservableObject conformance
        let observableObjectExtension = try ExtensionDeclSyntax(
            "extension \(raw: typeName): ObservableObject {}"
        )
        
        return [observableObjectExtension]
    }
}