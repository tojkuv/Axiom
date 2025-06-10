import Foundation

// MARK: - Macro Declarations

/// Macro for generating mock implementations of protocols
@attached(peer, names: arbitrary)
public macro AutoMockable() = #externalMacro(module: "AxiomMacros", type: "AutoMockableMacro")

/// Macro for automatic context setup
@attached(member, names: arbitrary)
public macro Context(observing: Any.Type) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")

// MARK: - Capability Pattern Macro

/// The `@Capability` macro automatically generates lifecycle management and state tracking for capabilities.
///
/// This macro eliminates 87% of boilerplate code by generating:
/// - ExtendedCapability conformance
/// - State management and transitions
/// - Async state stream for observation
/// - Lifecycle methods (initialize/terminate)
/// - Permission handling based on capability type
///
/// Example:
/// ```swift
/// @Capability(.network)
/// struct NetworkCapability {
///     func fetchData(from url: URL) async throws -> Data {
///         return try await URLSession.shared.data(from: url).0
///     }
/// }
/// ```
@attached(member, names: arbitrary)
public macro Capability(_ type: CapabilityType) = #externalMacro(module: "AxiomMacros", type: "CapabilityMacro")

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
// @attached(extension, conformances: NavigationService) // Disabled - NavigationService is now a class
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
/// class TaskContext: ObservableContext {
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

// MARK: - Error Handling Macros

/// Macro that generates automatic retry logic with configurable backoff strategies
/// 
/// Example:
/// ```swift
/// @ErrorHandling(retry: 3, backoff: .exponential(initial: 0.5))
/// class APIClient {
///     func fetchUser(_ id: String) async throws -> User {
///         // Use the generated executeWithRetry method
///         try await executeWithRetry {
///             try await network.get("/users/\(id)")
///         }
///     }
/// }
/// ```
@attached(member, names: named(executeWithRetry), named(calculateBackoffDelay))
public macro ErrorHandling(
    retry: Int = 3,
    backoff: BackoffStrategy = .exponential()
) = #externalMacro(
    module: "AxiomMacros",
    type: "ErrorHandlingMacro"
)

/// Macro that automatically adds error context to function calls
/// 
/// Example:
/// ```swift
/// @ErrorContext(operation: "processData")
/// class DataProcessor {
///     func processData(_ data: Data) throws -> ProcessedData {
///         // Use the generated executeWithContext method
///         try await executeWithContext {
///             try validate(data)
///             return try transform(data)
///         }
///     }
/// }
/// ```
@attached(member, names: named(executeWithContext))
public macro ErrorContext(
    operation: String? = nil
) = #externalMacro(
    module: "AxiomMacros",
    type: "ErrorContextMacro"
)