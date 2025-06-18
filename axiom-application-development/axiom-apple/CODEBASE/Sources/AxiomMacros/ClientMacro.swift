import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// ClientMacro generates minimal, reliable Client protocol conformance
///
/// Usage:
/// ```swift
/// @Client(state: TodoState.self)
/// public actor TodoClient {
///     // Minimal Client implementation generated automatically
/// }
/// ```
///
/// This macro generates only essential components:
/// - State storage
/// - Simple AsyncStream for state observation
/// - Basic state update mechanism
/// - Required protocol methods
public struct ClientMacro: MemberMacro, ExtensionMacro {
    
    // MARK: - Member Generation
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Validate that this is applied to an actor
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            throw ClientMacroError.mustBeAppliedToActor
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        return [
            // Simple state storage
            """
            
            // MARK: - Generated State Management
            
            /// Internal state storage
            private var _internalState = \(raw: parameters.initialState ?? "\(parameters.stateType)()")
            
            /// Current state observers
            private var _stateObservers: [AsyncStream<\(raw: parameters.stateType)>.Continuation] = []
            
            /// Computed property for backward compatibility
            public var state: \(raw: parameters.stateType) {
                get { _internalState }
                set { 
                    Task { await _updateState(newValue) }
                }
            }
            """,
            
            // Simple state stream
            """
            
            /// Stream of state updates for observation
            public var stateStream: AsyncStream<\(raw: parameters.stateType)> {
                AsyncStream { continuation in
                    // Add this observer to the list
                    _stateObservers.append(continuation)
                    
                    // Immediately yield current state
                    continuation.yield(_internalState)
                    
                    // Clean up when stream terminates
                    continuation.onTermination = { @Sendable _ in
                        // Note: We don't remove from array to avoid complexity
                        // Finished continuations will ignore yields
                    }
                }
            }
            """,
            
            // Simple state access
            """
            
            /// Get current state
            public func getCurrentState() async -> \(raw: parameters.stateType) {
                return _internalState
            }
            """,
            
            // Simple rollback
            """
            
            /// Restore state during rollback
            public func rollbackToState(_ state: \(raw: parameters.stateType)) async {
                await _updateState(state)
            }
            """,
            
            // Simple state update
            """
            
            /// Update state and notify observers
            private func _updateState(_ newState: \(raw: parameters.stateType)) async {
                let oldState = _internalState
                
                // Call lifecycle hooks (no error handling to keep it simple)
                await stateWillUpdate(from: oldState, to: newState)
                
                // Update state
                _internalState = newState
                
                // Notify all observers
                for continuation in _stateObservers {
                    continuation.yield(newState)
                }
                
                // Call post-update hook
                await stateDidUpdate(from: oldState, to: newState)
            }
            """
        ]
    }
    
    // MARK: - Extension Generation
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            throw ClientMacroError.mustBeAppliedToActor
        }
        
        let typeName = actorDecl.name.text
        
        // Generate simple Client protocol conformance
        let clientExtension = try ExtensionDeclSyntax(
            "extension \(raw: typeName): Client {}"
        )
        
        return [clientExtension]
    }
    
    // MARK: - Parameter Extraction (Simplified)
    
    private struct ClientMacroParameters {
        let stateType: String
        let initialState: String?
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> ClientMacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw ClientMacroError.missingStateParameter
        }
        
        var stateType: String?
        var initialState: String?
        
        for argument in arguments {
            switch argument.label?.text {
            case "state":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    stateType = memberAccess.base?.description.trimmingCharacters(in: .whitespaces)
                }
            case "initialState":
                initialState = argument.expression.description.trimmingCharacters(in: .whitespaces)
            default:
                break
            }
        }
        
        guard let state = stateType else {
            throw ClientMacroError.missingStateParameter
        }
        
        return ClientMacroParameters(
            stateType: state,
            initialState: initialState
        )
    }
}

// MARK: - Error Types

enum ClientMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToActor
    case missingStateParameter
    
    var description: String {
        switch self {
        case .mustBeAppliedToActor:
            return "@Client can only be applied to actor declarations"
        case .missingStateParameter:
            return "@Client requires a 'state' parameter with a State type"
        }
    }
}