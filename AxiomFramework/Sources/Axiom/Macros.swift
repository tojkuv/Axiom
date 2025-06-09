import Foundation

// MARK: - Macro Declarations

/// Macro for generating mock implementations of protocols
@attached(peer, names: arbitrary)
public macro AutoMockable() = #externalMacro(module: "AxiomMacros", type: "AutoMockableMacro")

/// Macro for automatic context setup
@attached(member, names: arbitrary)
public macro Context(observing: Any.Type) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")

// MARK: - Navigation Orchestrator Macro

/// Macro that generates a complete navigation service from route definitions
/// 
/// Example:
/// ```swift
/// @NavigationOrchestrator
/// class AppNavigation {
///     @RouteProperty(.push) var home = "/"
///     @RouteProperty(.modal) var settings = "/settings"
///     @RouteProperty(.push) var detail = "/detail/{id}"
/// }
/// ```
@attached(member, names: named(routes), named(navigate), named(canNavigate), named(currentRoute), named(navigationStack))
@attached(extension, conformances: NavigationService)
public macro NavigationOrchestrator() = #externalMacro(
    module: "AxiomMacros",
    type: "NavigationOrchestratorMacro"
)

// MARK: - Error Boundary Macro

/// Macro that generates automatic error boundary handling for contexts
/// 
/// Example:
/// ```swift
/// @ErrorBoundary(strategy: .retry(attempts: 3))
/// class TaskContext: BaseContext {
///     func loadTasks() async throws {
///         // Errors automatically handled by boundary
///     }
/// }
/// ```
@attached(member, names: named(initializeErrorBoundary), named(performAppearance), arbitrary)
public macro ErrorBoundary(
    strategy: ErrorRecoveryStrategy = .propagate,
    customHandler: String? = nil
) = #externalMacro(
    module: "AxiomMacros",
    type: "ErrorBoundaryMacro"
)