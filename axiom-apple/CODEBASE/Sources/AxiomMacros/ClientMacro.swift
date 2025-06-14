import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// ClientMacro generates complete Client protocol conformance with state management
///
/// Usage:
/// ```swift
/// @Client(state: TodoState.self)
/// public actor TodoClient {
///     // All Client implementation generated automatically
/// }
/// ```
///
/// This macro generates:
/// - Client protocol conformance
/// - State storage and management
/// - stateStream property with AsyncStream
/// - process(_:) method for action handling
/// - State lifecycle hooks (stateWillUpdate/stateDidUpdate)
/// - Complete ObservableClient inheritance
public struct ClientMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate that this is applied to an actor
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            throw ClientMacroError.mustBeAppliedToActor
        }
        
        // Extract macro parameters
        let parameters = try extractParameters(from: node)
        
        // Generate the peer implementation
        let peerImplementation = try generatePeerImplementation(
            actorDecl: actorDecl,
            parameters: parameters,
            context: context
        )
        
        return [peerImplementation]
    }
    
    // MARK: - Parameter Extraction
    
    private struct ClientMacroParameters {
        let stateType: String
        let actionType: String
        let initialState: String?
        let performanceBudget: String?
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> ClientMacroParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            throw ClientMacroError.missingStateParameter
        }
        
        var stateType: String?
        var actionType: String?
        var initialState: String?
        var performanceBudget: String?
        
        for argument in arguments {
            switch argument.label?.text {
            case "state":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    stateType = memberAccess.base?.description.trimmingCharacters(in: .whitespaces)
                }
            case "action":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    actionType = memberAccess.base?.description.trimmingCharacters(in: .whitespaces)
                }
            case "initialState":
                initialState = argument.expression.description.trimmingCharacters(in: .whitespaces)
            case "performanceBudget":
                performanceBudget = argument.expression.description.trimmingCharacters(in: .whitespaces)
            default:
                break
            }
        }
        
        guard let state = stateType else {
            throw ClientMacroError.missingStateParameter
        }
        
        // Default action type to Any if not specified
        let action = actionType ?? "Any"
        
        return ClientMacroParameters(
            stateType: state,
            actionType: action,
            initialState: initialState,
            performanceBudget: performanceBudget
        )
    }
    
    // MARK: - Implementation Generation
    
    private static func generatePeerImplementation(
        actorDecl: ActorDeclSyntax,
        parameters: ClientMacroParameters,
        context: some MacroExpansionContext
    ) throws -> DeclSyntax {
        let originalName = actorDecl.name.text
        let generatedName = "_\(originalName)Implementation"
        
        // Build the generated implementation
        let implementation = """
        
        // MARK: - Generated Client Implementation
        
        /// Generated implementation for \(originalName)
        public actor \(generatedName): ObservableClient<\(parameters.stateType), \(parameters.actionType)> {
            
            // MARK: - Generated Properties
            
            /// Client identifier for debugging and analytics
            public let clientId: String
            
            /// Performance monitoring
            private let performanceMonitor: ClientPerformanceMonitor?
            
            /// State update timing
            private var lastStateUpdateTime: CFAbsoluteTime = 0
            
            // MARK: - Generated Initializer
            
            public init(
                initialState: \(parameters.stateType),
                clientId: String = "\(originalName)",
                performanceMonitor: ClientPerformanceMonitor? = nil
            ) {
                self.clientId = clientId
                self.performanceMonitor = performanceMonitor
                super.init(initialState: initialState)
            }
            
            // MARK: - Generated Client Protocol Implementation
            
            /// Process an action and update state accordingly
            public override func process(_ action: \(parameters.actionType)) async throws {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Call lifecycle hook
                let oldState = state
                await stateWillUpdate(from: oldState, to: oldState)
                
                // Process the action - delegate to original implementation
                try await processAction(action)
                
                // Call lifecycle hook
                await stateDidUpdate(from: oldState, to: state)
                
                // Record performance metrics
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                await performanceMonitor?.recordActionProcessing(
                    clientId: clientId,
                    duration: Duration.seconds(duration)
                )
            }
            
            /// Override state updates to include performance monitoring
            public override func updateState(_ newState: \(parameters.stateType)) {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                super.updateState(newState)
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                lastStateUpdateTime = CFAbsoluteTimeGetCurrent()
                
                // Record performance metrics
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.performanceMonitor?.recordStateUpdate(
                        clientId: self.clientId,
                        duration: Duration.seconds(duration)
                    )
                }
            }
            
            // MARK: - Action Processing (to be implemented by user)
            
            /// Process action implementation - override in extension
            func processAction(_ action: \(parameters.actionType)) async throws {
                // Default implementation - does nothing
                // User should extend this in their implementation
            }
            
            // MARK: - Generated Lifecycle Hooks
            
            public override func stateWillUpdate(from old: \(parameters.stateType), to new: \(parameters.stateType)) async {
                // Performance validation
                if let budget = \(parameters.performanceBudget ?? "nil") {
                    let timeSinceLastUpdate = CFAbsoluteTimeGetCurrent() - lastStateUpdateTime
                    if timeSinceLastUpdate < budget {
                        print("Warning: State update frequency exceeds performance budget")
                    }
                }
                
                // Call user implementation if available
                await customStateWillUpdate(from: old, to: new)
            }
            
            public override func stateDidUpdate(from old: \(parameters.stateType), to new: \(parameters.stateType)) async {
                // Call user implementation if available
                await customStateDidUpdate(from: old, to: new)
            }
            
            /// Custom state will update hook for user implementation
            func customStateWillUpdate(from old: \(parameters.stateType), to new: \(parameters.stateType)) async {
                // Override in extension
            }
            
            /// Custom state did update hook for user implementation
            func customStateDidUpdate(from old: \(parameters.stateType), to new: \(parameters.stateType)) async {
                // Override in extension
            }
            
            // MARK: - Generated Convenience Methods
            
            /// Safely update state with validation
            public func safeUpdateState(
                _ newState: \(parameters.stateType),
                validation: ((old: \(parameters.stateType), new: \(parameters.stateType)) -> Bool)? = nil
            ) {
                if let validation = validation {
                    guard validation((old: state, new: newState)) else {
                        print("State update validation failed")
                        return
                    }
                }
                updateState(newState)
            }
            
            /// Batch process multiple actions
            public func batchProcess(_ actions: [\(parameters.actionType)]) async throws {
                for action in actions {
                    try await process(action)
                }
            }
            
            /// Get current state synchronously (for debugging)
            public var currentState: \(parameters.stateType) {
                state
            }
        }
        """
        
        return DeclSyntax(stringLiteral: implementation)
    }
}

// MARK: - Error Types

enum ClientMacroError: Error, CustomStringConvertible {
    case mustBeAppliedToActor
    case missingStateParameter
    case invalidParameters
    
    var description: String {
        switch self {
        case .mustBeAppliedToActor:
            return "@Client can only be applied to actor declarations"
        case .missingStateParameter:
            return "@Client requires a 'state' parameter with a State type"
        case .invalidParameters:
            return "@Client has invalid parameters"
        }
    }
}