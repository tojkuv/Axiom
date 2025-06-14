import Foundation

// MARK: - Macro Declarations

/// Macro for generating mock implementations of protocols
@attached(peer, names: arbitrary)
public macro AutoMockable() = #externalMacro(module: "AxiomMacros", type: "AutoMockableMacro")

/// Enhanced macro for automatic context setup with client-based initialization
@attached(member, names: named(client), named(observationTask), named(init), named(viewAppeared), named(viewDisappeared), named(handleStateUpdate))
@attached(extension, conformances: ObservableObject)
public macro Context<C: PresentationClient>(client: C.Type) = #externalMacro(module: "AxiomMacros", type: "ContextMacro")

/// Macro that enforces single-context presentation architecture with compile-time safety
///
/// Usage:
/// ```swift
/// @Presentation(context: TaskListContext.self)
/// struct TaskListView {
///     var body: some View {
///         List(context.tasks) { task in
///             TaskRow(task: task)
///         }
///     }
/// }
/// ```
///
/// This macro:
/// - Enforces single context per presentation
/// - Generates context property and initializer
/// - Provides compile-time architectural safety
/// - Prevents architectural violations
@attached(member, names: named(context), named(init))
@attached(extension, conformances: PresentationProtocol)
@attached(peer, names: prefixed(_ValidatePresentation))
public macro Presentation<C: ObservableObject>(context: C.Type) = #externalMacro(module: "AxiomMacros", type: "PresentationMacro")

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
// @attached(extension, conformances: ModularNavigationService) // Disabled - ModularNavigationService is now a class
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

// MARK: - Core Developer Experience Macros

/// Macro that generates complete Client protocol conformance with state management
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
/// - Atomic action processing capabilities
/// - Performance monitoring and validation
@attached(member, names: named(_internalState), named(_stateObservers), named(state), named(stateStream), named(getCurrentState), named(rollbackToState), named(_updateState))
@attached(extension, conformances: Client)
public macro Client<S: AxiomState>(
    state: S.Type,
    action: Any.Type = Any.self,
    initialState: S? = nil,
    performanceBudget: Double? = nil
) = #externalMacro(module: "AxiomMacros", type: "ClientMacro")

/// Macro that generates Axiom State protocol conformance with validation and optimizations
///
/// Usage:
/// ```swift
/// @AxiomState
/// struct TodoState {
///     let items: [TodoItem]
///     let filter: Filter
/// }
/// ```
///
/// This macro generates:
/// - Axiom State protocol conformance (Equatable, Hashable, Sendable)
/// - Validation methods for immutability
/// - Optimized equality and hashing implementations
/// - State transition methods with validation
/// - Memory-efficient state storage
@attached(extension, conformances: AxiomState)
public macro AxiomState(
    validation: Bool = true,
    optimizeEquality: Bool = true,
    customHashable: Bool = false,
    memoryOptimized: Bool = true
) = #externalMacro(module: "AxiomMacros", type: "StateMacro")

/// Macro that generates Action protocol conformance with execution pipeline and validation
///
/// Usage:
/// ```swift
/// @Action
/// enum TodoAction {
///     case addItem(String)
///     case toggleItem(UUID)
///     case deleteItem(UUID)
/// }
/// ```
///
/// This macro generates:
/// - Sendable conformance for thread safety
/// - Action identification and description
/// - Action validation capabilities
/// - Performance tracking for action execution
/// - Save triggering logic
@attached(extension, conformances: Sendable, names: named(actionId), named(description), named(triggersSave), named(validate), named(validateParameters), named(isValid), named(trackExecution))
public macro Action(
    validation: Bool = true,
    performance: Bool = true,
    retry: Bool = false,
    timeout: Double? = nil,
    priority: String = "medium"
) = #externalMacro(module: "AxiomMacros", type: "ActionMacro")