import Foundation

// MARK: - Unified Error Handling

/// Standardized result type for consistent error handling across the framework
public typealias AxiomResult<T> = Result<T, AxiomError>

// MARK: - Standardized API Protocol

/// Defines the consistent API patterns that all framework components should follow
public protocol StandardizedAPI {
    associatedtype StateType
    associatedtype ActionType
    
    // MARK: Core Operations
    
    /// Process an action with unified error handling
    func processAction(_ action: ActionType) async -> AxiomResult<Void>
    
    /// Update state with unified error handling
    func update(_ newValue: StateType) async -> AxiomResult<Void>
    
    /// Get current state with unified error handling
    func get() async -> AxiomResult<StateType>
    
    /// Query specific data with unified error handling
    func query<T>(_ query: T) async -> AxiomResult<T> where T: Sendable
}

// MARK: - Navigation API Standardization

/// Standardized navigation operations
public protocol StandardizedNavigation {
    associatedtype RouteType
    
    /// Navigate to a destination with consistent error handling
    func navigate(to destination: RouteType, options: NavigationOptions) async -> AxiomResult<Void>
    
    /// Navigate back with consistent error handling
    func navigateBack(options: NavigationOptions) async -> AxiomResult<Void>
    
    /// Dismiss current view with consistent error handling
    func dismiss(animated: Bool) async -> AxiomResult<Void>
    
    /// Navigate to root with consistent error handling
    func navigateToRoot(animated: Bool) async -> AxiomResult<Void>
}


// MARK: - Core API Enumeration

/// Defines the 47 essential APIs that comprise the standardized framework interface
public enum CoreAPI: String, CaseIterable, Sendable {
    // Context operations (8 APIs)
    case contextCreate = "context.create"
    case contextUpdate = "context.update"
    case contextQuery = "context.query"
    case contextLifecycle = "context.lifecycle"
    case contextBinding = "context.binding"
    case contextObservation = "context.observation"
    case contextError = "context.error"
    case contextCleanup = "context.cleanup"
    
    // Client operations (12 APIs)
    case clientCreate = "client.create"
    case clientProcess = "client.process"
    case clientState = "client.state"
    case clientStream = "client.stream"
    case clientUpdate = "client.update"
    case clientQuery = "client.query"
    case clientObserve = "client.observe"
    case clientError = "client.error"
    case clientRetry = "client.retry"
    case clientCache = "client.cache"
    case clientMock = "client.mock"
    case clientCleanup = "client.cleanup"
    
    // Navigation operations (8 APIs)
    case navigateForward = "navigate.forward"
    case navigateBack = "navigate.back"
    case navigateDismiss = "navigate.dismiss"
    case navigateRoot = "navigate.root"
    case navigateRoute = "navigate.route"
    case navigateFlow = "navigate.flow"
    case navigateDeepLink = "navigate.deeplink"
    case navigatePattern = "navigate.pattern"
    
    // Capability operations (8 APIs)
    case capabilityCreate = "capability.create"
    case capabilityInit = "capability.init"
    case capabilityState = "capability.state"
    case capabilityResource = "capability.resource"
    case capabilityConfig = "capability.config"
    case capabilityPermission = "capability.permission"
    case capabilityLifecycle = "capability.lifecycle"
    case capabilityCompose = "capability.compose"
    
    // Orchestrator operations (6 APIs)
    case orchestratorCreate = "orchestrator.create"
    case orchestratorRegister = "orchestrator.register"
    case orchestratorResolve = "orchestrator.resolve"
    case orchestratorManage = "orchestrator.manage"
    case orchestratorNavigate = "orchestrator.navigate"
    case orchestratorLifecycle = "orchestrator.lifecycle"
    
    // Testing operations (7 APIs)
    case testScenario = "test.scenario"
    case testExpect = "test.expect"
    case testMock = "test.mock"
    case testPerformance = "test.performance"
    case testAsync = "test.async"
    case testSnapshot = "test.snapshot"
    case testIntegration = "test.integration"
}

// MARK: - API Standardization Helpers

/// Extension to check if a method follows predictable patterns
public extension StandardizedAPI {
    static func hasPredictableMethod(component: String, operation: String) -> Bool {
        let expectedPattern = "\(component.lowercased()).\(operation)"
        return CoreAPI.allCases.contains { $0.rawValue == expectedPattern }
    }
}


// MARK: - Standardized Error Context

/// Extension to provide consistent error context across all APIs
public extension AxiomError {
    /// Wrap any error with consistent AxiomError context
    static func wrap(_ error: Error, context: String) -> AxiomError {
        if let axiomError = error as? AxiomError {
            return axiomError
        }
        // Use clientError with description since custom case doesn't exist
        return .clientError(.invalidAction("\(context): \(error.localizedDescription)"))
    }
}