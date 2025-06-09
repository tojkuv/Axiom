import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates context lifecycle management boilerplate
///
/// Usage:
/// ```swift
/// @Context(observing: ClientType.self)
/// class MyContext: AutoObservingContext<ClientType> {
///     // Custom implementation
/// }
/// ```
///
/// This macro generates:
/// - Update trigger property for SwiftUI observation
/// - Lifecycle state management (isActive, appearanceCount)
/// - Observation task management
/// - Automatic client state observation setup
public struct ContextMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate this is being applied to a class
        guard declaration.is(ClassDeclSyntax.self) else {
            throw MacroError.unsupportedDeclaration
        }
        
        // Extract the client type from the macro arguments
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first,
              argument.label?.text == "observing" else {
            throw MacroError.invalidArguments
        }
        
        // Generate organized member groups
        let stateMembers = generateStateMembers()
        let lifecycleMethods = generateLifecycleMethods()
        let observationMethods = generateObservationMethods()
        let utilityMethods = generateUtilityMethods()
        
        // Combine all members with proper organization
        return stateMembers + lifecycleMethods + observationMethods + utilityMethods
    }
    
    // MARK: - Member Generation Helpers
    
    private static func generateStateMembers() -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated State Management
            
            /// Trigger for SwiftUI updates
            @Published private var updateTrigger = UUID()
            """,
            """
            
            /// Tracks if context is currently active
            public private(set) var isActive = false
            """,
            """
            
            /// Tracks appearance count for idempotency
            private var appearanceCount = 0
            """,
            """
            
            /// Task managing client state observation
            private var observationTask: Task<Void, Never>?
            """
        ]
    }
    
    private static func generateLifecycleMethods() -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Lifecycle Methods
            
            public override func performAppearance() async {
                guard appearanceCount == 0 else { return }
                appearanceCount += 1
                isActive = true
                startObservation()
                await super.performAppearance()
            }
            """,
            """
            
            public override func performDisappearance() async {
                stopObservation()
                isActive = false
                await super.performDisappearance()
            }
            """
        ]
    }
    
    private static func generateObservationMethods() -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Observation Management
            
            private func startObservation() {
                observationTask = Task { [weak self] in
                    guard let self = self else { return }
                    for await state in await self.client.stateStream {
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
            """
        ]
    }
    
    private static func generateUtilityMethods() -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Utility Methods
            
            /// Manually trigger a UI update
            public func triggerUpdate() {
                updateTrigger = UUID()
            }
            """
        ]
    }
}

// MARK: - Error Types

enum MacroError: Error, CustomStringConvertible {
    case invalidArguments
    case unsupportedDeclaration
    
    var description: String {
        switch self {
        case .invalidArguments:
            return "@Context requires 'observing' parameter with a Client type"
        case .unsupportedDeclaration:
            return "@Context can only be applied to classes"
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
        // No extensions needed for now
        return []
    }
}