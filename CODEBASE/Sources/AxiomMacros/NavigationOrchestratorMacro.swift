import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Enhanced macro that generates comprehensive navigation orchestration
///
/// Usage:
/// ```swift
/// @NavigationOrchestrator
/// class AppOrchestrator {
///     // Generated: navigation management, context registration
/// }
/// ```
///
/// This macro generates:
/// - Context registry management
/// - Navigation state coordination
/// - Deep link handling setup
/// - Flow management infrastructure
/// - Type-safe route handling
/// - Lifecycle management for orchestrators
public struct NavigationOrchestratorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Validate this is applied to a class
        guard declaration.is(ClassDeclSyntax.self) else {
            throw NavigationOrchestratorError.unsupportedDeclaration
        }
        
        // Extract orchestrator parameters
        let parameters = try extractParameters(from: node)
        
        // Generate comprehensive orchestrator components
        let contextRegistry = generateContextRegistry(parameters)
        let navigationState = generateNavigationState(parameters)
        let routeHandling = generateRouteHandling(parameters)
        let deepLinkHandling = generateDeepLinkHandling(parameters)
        let flowManagement = generateFlowManagement(parameters)
        let lifecycleManagement = generateLifecycleManagement(parameters)
        let coordinatorMethods = generateCoordinatorMethods(parameters)
        
        return contextRegistry + navigationState + routeHandling + 
               deepLinkHandling + flowManagement + lifecycleManagement + coordinatorMethods
    }
    
    // MARK: - Parameter Extraction
    
    private struct OrchestratorParameters {
        let enableDeepLinks: Bool
        let enableFlowManagement: Bool
        let routeType: String?
        let contextTypes: [String]
    }
    
    private static func extractParameters(from node: AttributeSyntax) throws -> OrchestratorParameters {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return OrchestratorParameters(
                enableDeepLinks: true,
                enableFlowManagement: true,
                routeType: nil,
                contextTypes: []
            )
        }
        
        var enableDeepLinks = true
        var enableFlowManagement = true
        var routeType: String?
        var contextTypes: [String] = []
        
        for argument in arguments {
            switch argument.label?.text {
            case "enableDeepLinks":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableDeepLinks = boolLiteral.literal.text == "true"
                }
            case "enableFlowManagement":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    enableFlowManagement = boolLiteral.literal.text == "true"
                }
            case "routeType":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    routeType = memberAccess.base?.description.trimmingCharacters(in: .whitespaces)
                }
            case "contextTypes":
                if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                    contextTypes = arrayExpr.elements.compactMap { element in
                        element.expression.description.trimmingCharacters(in: .whitespaces)
                    }
                }
            default:
                break
            }
        }
        
        return OrchestratorParameters(
            enableDeepLinks: enableDeepLinks,
            enableFlowManagement: enableFlowManagement,
            routeType: routeType,
            contextTypes: contextTypes
        )
    }
    
    // MARK: - Component Generation
    
    private static func generateContextRegistry(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Context Registry
            
            /// Registry for managing contexts
            private var contextRegistry: [String: Any] = [:]
            
            /// Registry lock for thread safety
            private let registryLock = NSLock()
            
            /// Register a context with the orchestrator
            public func register<T: ContextValidatable>(_ context: T, withKey key: String) {
                registryLock.lock()
                defer { registryLock.unlock() }
                contextRegistry[key] = context
            }
            
            /// Retrieve a context by key
            public func context<T: ContextValidatable>(forKey key: String, type: T.Type) -> T? {
                registryLock.lock()
                defer { registryLock.unlock() }
                return contextRegistry[key] as? T
            }
            
            /// Remove a context from registry
            public func unregister(contextWithKey key: String) {
                registryLock.lock()
                defer { registryLock.unlock() }
                contextRegistry.removeValue(forKey: key)
            }
            """
        ]
    }
    
    private static func generateNavigationState(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Navigation State
            
            /// Current navigation path
            @Published public var navigationPath = NavigationPath()
            
            /// Current route information
            @Published public var currentRoute: Any?
            
            /// Navigation history stack
            private var navigationHistory: [Any] = []
            
            /// Maximum history size
            private let maxHistorySize = 50
            
            /// Navigate to a specific route
            public func navigate<T>(to route: T) {
                currentRoute = route
                addToHistory(route)
                navigationPath.append(route)
            }
            
            /// Navigate back to previous route
            public func navigateBack() {
                guard !navigationHistory.isEmpty else { return }
                navigationHistory.removeLast()
                navigationPath.removeLast()
                currentRoute = navigationHistory.last
            }
            
            /// Clear navigation history
            public func clearHistory() {
                navigationHistory.removeAll()
                navigationPath = NavigationPath()
                currentRoute = nil
            }
            
            private func addToHistory<T>(_ route: T) {
                navigationHistory.append(route)
                if navigationHistory.count > maxHistorySize {
                    navigationHistory.removeFirst()
                }
            }
            """
        ]
    }
    
    private static func generateRouteHandling(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Route Handling
            
            /// Route change handler
            public typealias RouteHandler = (Any) -> Void
            
            /// Route handlers registry
            private var routeHandlers: [String: RouteHandler] = [:]
            
            /// Register a route handler
            public func registerRouteHandler(forRoute route: String, handler: @escaping RouteHandler) {
                routeHandlers[route] = handler
            }
            
            /// Handle route change
            public func handleRouteChange(_ route: Any) {
                let routeKey = String(describing: type(of: route))
                routeHandlers[routeKey]?(route)
            }
            
            /// Type-safe route handling
            public func handle<T>(_ route: T, with handler: @escaping (T) -> Void) {
                let routeKey = String(describing: T.self)
                routeHandlers[routeKey] = { anyRoute in
                    if let typedRoute = anyRoute as? T {
                        handler(typedRoute)
                    }
                }
            }
            """
        ]
    }
    
    private static func generateDeepLinkHandling(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        guard parameters.enableDeepLinks else { return [] }
        
        return [
            """
            
            // MARK: - Generated Deep Link Handling
            
            /// Deep link handler
            public typealias DeepLinkHandler = (URL) -> Bool
            
            /// Deep link handlers registry
            private var deepLinkHandlers: [String: DeepLinkHandler] = [:]
            
            /// Register a deep link handler
            public func registerDeepLinkHandler(forScheme scheme: String, handler: @escaping DeepLinkHandler) {
                deepLinkHandlers[scheme] = handler
            }
            
            /// Handle incoming deep link
            public func handleDeepLink(_ url: URL) -> Bool {
                guard let scheme = url.scheme else { return false }
                return deepLinkHandlers[scheme]?(url) ?? false
            }
            
            /// Parse deep link parameters
            public func parseDeepLinkParameters(from url: URL) -> [String: String] {
                var parameters: [String: String] = [:]
                
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let queryItems = components.queryItems {
                    for item in queryItems {
                        parameters[item.name] = item.value
                    }
                }
                
                return parameters
            }
            """
        ]
    }
    
    private static func generateFlowManagement(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        guard parameters.enableFlowManagement else { return [] }
        
        return [
            """
            
            // MARK: - Generated Flow Management
            
            /// Flow state tracking
            private var currentFlow: String?
            private var flowStack: [String] = []
            
            /// Start a new flow
            public func startFlow(_ flowName: String) {
                currentFlow = flowName
                flowStack.append(flowName)
            }
            
            /// End current flow
            public func endFlow() {
                guard !flowStack.isEmpty else { return }
                flowStack.removeLast()
                currentFlow = flowStack.last
            }
            
            /// Check if flow is active
            public func isFlowActive(_ flowName: String) -> Bool {
                return flowStack.contains(flowName)
            }
            
            /// Get current flow
            public var activeFlow: String? {
                return currentFlow
            }
            
            /// Flow completion handlers
            private var flowCompletionHandlers: [String: () -> Void] = [:]
            
            /// Register flow completion handler
            public func onFlowCompletion(_ flowName: String, handler: @escaping () -> Void) {
                flowCompletionHandlers[flowName] = handler
            }
            
            /// Complete a flow
            public func completeFlow(_ flowName: String) {
                flowCompletionHandlers[flowName]?()
                endFlow()
            }
            """
        ]
    }
    
    private static func generateLifecycleManagement(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Lifecycle Management
            
            /// Orchestrator state
            @Published public var isActive = false
            
            /// Initialize the orchestrator
            public func initialize() async throws {
                guard !isActive else { return }
                isActive = true
                await setupInitialState()
                setupDefaultHandlers()
            }
            
            /// Terminate the orchestrator
            public func terminate() async {
                await cleanupState()
                contextRegistry.removeAll()
                routeHandlers.removeAll()
                \(raw: parameters.enableDeepLinks ? "deepLinkHandlers.removeAll()" : "// Deep links disabled")
                \(raw: parameters.enableFlowManagement ? "flowCompletionHandlers.removeAll()" : "// Flow management disabled")
                isActive = false
            }
            
            /// Setup initial state
            private func setupInitialState() async {
                // Override in concrete implementation if needed
            }
            
            /// Setup default route handlers
            private func setupDefaultHandlers() {
                // Override in concrete implementation if needed
            }
            
            /// Cleanup orchestrator state
            private func cleanupState() async {
                // Override in concrete implementation if needed
            }
            """
        ]
    }
    
    private static func generateCoordinatorMethods(_ parameters: OrchestratorParameters) -> [DeclSyntax] {
        return [
            """
            
            // MARK: - Generated Coordination Methods
            
            /// Coordinate between contexts
            public func coordinate<T, U>(from sourceContext: T, to targetContext: U, with data: Any? = nil) 
                where T: ContextValidatable, U: ContextValidatable {
                // Context coordination logic
                handleCoordination(source: sourceContext, target: targetContext, data: data)
            }
            
            /// Handle context coordination
            private func handleCoordination(source: Any, target: Any, data: Any?) {
                // Override in concrete implementation for custom coordination
            }
            
            /// Broadcast event to all registered contexts
            public func broadcast<T>(_ event: T) {
                for (_, context) in contextRegistry {
                    if let observableContext = context as? any ObservableObject {
                        // Send event to context if it can handle it
                        handleContextEvent(context: observableContext, event: event)
                    }
                }
            }
            
            /// Handle context-specific events
            private func handleContextEvent<T>(context: any ObservableObject, event: T) {
                // Override in concrete implementation for custom event handling
            }
            
            /// Get all registered context keys
            public var registeredContextKeys: [String] {
                registryLock.lock()
                defer { registryLock.unlock() }
                return Array(contextRegistry.keys)
            }
            """
        ]
    }
}

// MARK: - Error Types

enum NavigationOrchestratorError: Error, CustomStringConvertible {
    case unsupportedDeclaration
    case invalidConfiguration
    
    var description: String {
        switch self {
        case .unsupportedDeclaration:
            return "@NavigationOrchestrator can only be applied to classes"
        case .invalidConfiguration:
            return "@NavigationOrchestrator configuration is invalid"
        }
    }
}

// MARK: - Extension Macro Implementation

extension NavigationOrchestratorMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Extract type name
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw NavigationOrchestratorError.unsupportedDeclaration
        }
        
        let typeName = classDecl.name.text
        
        // Generate OrchestratorValidatable conformance
        let orchestratorExtension = try ExtensionDeclSyntax(
            """
            extension \(raw: typeName): OrchestratorValidatable {
            }
            """
        )
        
        return [orchestratorExtension]
    }
}