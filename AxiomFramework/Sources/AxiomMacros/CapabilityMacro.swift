import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CapabilityMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract capability type from macro arguments
        guard let capabilityType = extractCapabilityType(from: node) else {
            return []
        }
        
        // Get capability name for comment
        let capabilityName = declaration.as(ActorDeclSyntax.self)?.name.text ?? 
                           declaration.as(ClassDeclSyntax.self)?.name.text ?? 
                           "YourCapability"
        
        // Add a comment about conformance that needs to be added manually
        let conformanceComment: DeclSyntax = "// Note: Add 'extension \(raw: capabilityName): ExtendedCapability {}' to conform to the protocol"
        
        let members: [DeclSyntax] = [
            conformanceComment,
            
            // State management
            """
            private var _state: CapabilityState = .unknown
            """,
            """
            private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
            """,
            
            // State property
            """
            public var state: CapabilityState {
                get async { _state }
            }
            """,
            
            // State stream
            """
            public var stateStream: AsyncStream<CapabilityState> {
                get async {
                    AsyncStream { continuation in
                        self.stateStreamContinuation = continuation
                        continuation.yield(_state)
                    }
                }
            }
            """,
            
            // Is available
            """
            public var isAvailable: Bool {
                get async { await state == .available }
            }
            """,
            
            // Initialize
            """
            public func initialize() async throws {
                await transitionTo(.available)
            }
            """,
            
            // Terminate
            """
            public func terminate() async {
                await transitionTo(.unavailable)
                stateStreamContinuation?.finish()
            }
            """,
            
            // Is supported
            """
            public func isSupported() async -> Bool {
                return true
            }
            """,
            
            // Request permission
            generateRequestPermission(for: capabilityType),
            
            // State transition helper
            """
            private func transitionTo(_ newState: CapabilityState) async {
                guard _state != newState else { return }
                _state = newState
                stateStreamContinuation?.yield(newState)
            }
            """
        ]
        
        return members
    }
    
    private static func extractCapabilityType(from node: AttributeSyntax) -> String? {
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first,
              let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) else {
            return nil
        }
        return memberAccess.declName.baseName.text
    }
    
    private static func generateRequestPermission(for type: String) -> DeclSyntax {
        switch type {
        case "network":
            return """
            public func requestPermission() async throws {
                // Network capability doesn't require permission
            }
            """
        case "hardware":
            return """
            public func requestPermission() async throws {
                // Request hardware permissions (camera, microphone, etc.)
                // Implementation depends on specific hardware
            }
            """
        case "location":
            return """
            public func requestPermission() async throws {
                // Request location permission
                // Implementation depends on platform
            }
            """
        default:
            return """
            public func requestPermission() async throws {
                // Default permission handling
            }
            """
        }
    }
}

