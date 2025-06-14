import XCTest
import SwiftSyntaxMacrosTestSupport
import SwiftSyntax
import SwiftSyntaxBuilder
import Axiom
@testable import AxiomMacros

final class MacroTests: XCTestCase {
    
    let testMacros: [String: Macro.Type] = [
        "Context": ContextMacro.self,
        "Presentation": PresentationMacro.self,
        "NavigationOrchestrator": NavigationOrchestratorMacro.self,
        "AutoMockable": AutoMockableMacro.self,
        "Capability": CapabilityMacro.self,
    ]
    
    // MARK: - Context Macro Tests
    
    func testContextMacroGeneratesComprehensiveBoilerplate() throws {
        assertMacroExpansion(
            """
            @Context(client: TaskClient.self)
            struct TaskContext {
                func loadTasks() async {
                    await client.process(.loadTasks)
                }
            }
            """,
            expandedSource: """
            struct TaskContext {
                func loadTasks() async {
                    await client.process(.loadTasks)
                }
                
                // MARK: - Generated Client
                
                /// The client this context observes
                public let client: TaskClient
                
                // MARK: - Generated Published Properties
                
                /// Auto-generated from client state
                @Published public var tasks: Any?
                
                /// Auto-generated from client state
                @Published public var isLoading: Any?
                
                /// Auto-generated from client state
                @Published public var error: Any?
                
                // MARK: - Generated State Management
                
                /// Tracks if context is currently active
                public private(set) var isActive = false
                
                /// Task managing client state observation
                private var observationTask: Task<Void, Never>?
                
                /// Tracks initialization state
                private var isInitialized = false
                
                // MARK: - Generated Initializer
                
                public init(client: TaskClient) {
                    self.client = client
                    setupInitialState()
                }
                
                // MARK: - Generated Lifecycle Methods
                
                /// Called when view appears
                public func viewAppeared() async {
                    guard !isActive else { return }
                    isActive = true
                    startObservation()
                    await handleAppearance()
                }
                
                /// Called when view disappears
                public func viewDisappeared() async {
                    stopObservation()
                    isActive = false
                    await handleDisappearance()
                }
                
                /// Setup initial state
                private func setupInitialState() {
                    // Initialize @Published properties with default values
                    self.tasks = nil
                    self.isLoading = nil
                    self.error = nil
                }
                
                /// Handle appearance logic
                private func handleAppearance() async {
                    // Override in concrete implementation if needed
                }
                
                /// Handle disappearance logic  
                private func handleDisappearance() async {
                    // Override in concrete implementation if needed
                }
                
                // MARK: - Generated Observation Management
                
                private func startObservation() {
                    observationTask = Task { [weak self] in
                        guard let self = self else { return }
                        for await state in await self.client.stateStream {
                            await self.handleStateUpdate(state)
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                @MainActor
                private func handleStateUpdate(_ state: Any) async {
                    // Update @Published properties from client state
                    if let value = (state as? AnyObject)?.value(forKeyPath: "tasks") {
                        self.tasks = value
                    }
                    if let value = (state as? AnyObject)?.value(forKeyPath: "isLoading") {
                        self.isLoading = value
                    }
                    if let value = (state as? AnyObject)?.value(forKeyPath: "error") {
                        self.error = value
                    }
                    
                    // Trigger SwiftUI update
                    objectWillChange.send()
                }
                
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
            }
            
            extension TaskContext: ObservableObject {
            }
            """,
            macros: ["Context": ContextMacro.self]
        )
    }
    
    func testContextMacroWithCustomObservation() throws {
        assertMacroExpansion(
            """
            @Context(client: UserClient.self, observes: ["username", "isLoggedIn"])
            struct UserContext {
                func login(username: String) async {
                    await client.process(.login(username))
                }
            }
            """,
            expandedSource: """
            struct UserContext {
                func login(username: String) async {
                    await client.process(.login(username))
                }
                
                // MARK: - Generated Client
                
                /// The client this context observes
                public let client: UserClient
                
                // MARK: - Generated Published Properties
                
                /// Auto-generated from client state
                @Published public var username: Any?
                
                /// Auto-generated from client state
                @Published public var isLoggedIn: Any?
                
                // MARK: - Generated State Management
                
                /// Tracks if context is currently active
                public private(set) var isActive = false
                
                /// Task managing client state observation
                private var observationTask: Task<Void, Never>?
                
                /// Tracks initialization state
                private var isInitialized = false
                
                // MARK: - Generated Initializer
                
                public init(client: UserClient) {
                    self.client = client
                    setupInitialState()
                }
                
                // MARK: - Generated Lifecycle Methods
                
                /// Called when view appears
                public func viewAppeared() async {
                    guard !isActive else { return }
                    isActive = true
                    startObservation()
                    await handleAppearance()
                }
                
                /// Called when view disappears
                public func viewDisappeared() async {
                    stopObservation()
                    isActive = false
                    await handleDisappearance()
                }
                
                /// Setup initial state
                private func setupInitialState() {
                    // Initialize @Published properties with default values
                    self.username = nil
                    self.isLoggedIn = nil
                }
                
                /// Handle appearance logic
                private func handleAppearance() async {
                    // Override in concrete implementation if needed
                }
                
                /// Handle disappearance logic  
                private func handleDisappearance() async {
                    // Override in concrete implementation if needed
                }
                
                // MARK: - Generated Observation Management
                
                private func startObservation() {
                    observationTask = Task { [weak self] in
                        guard let self = self else { return }
                        for await state in await self.client.stateStream {
                            await self.handleStateUpdate(state)
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                @MainActor
                private func handleStateUpdate(_ state: Any) async {
                    // Update @Published properties from client state
                    if let value = (state as? AnyObject)?.value(forKeyPath: "username") {
                        self.username = value
                    }
                    if let value = (state as? AnyObject)?.value(forKeyPath: "isLoggedIn") {
                        self.isLoggedIn = value
                    }
                    
                    // Trigger SwiftUI update
                    objectWillChange.send()
                }
                
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
            }
            
            extension UserContext: ObservableObject {
            }
            """,
            macros: ["Context": ContextMacro.self]
        )
    }
    
    // MARK: - ErrorContext Macro Tests
    
    func testErrorContextMacroGeneratesComprehensiveErrorHandling() throws {
        assertMacroExpansion(
            """
            @ErrorContext(domain: "TaskManager")
            enum TaskError: Error {
                case loadFailed
                case networkUnavailable
                case permissionDenied
            }
            """,
            expandedSource: """
            enum TaskError: Error {
                case loadFailed
                case networkUnavailable
                case permissionDenied
                
                // MARK: - Generated Error Descriptions
                
                /// Provides detailed error descriptions
                public var errorDescription: String? {
                    switch self {
                    
                    /// Auto-generated error description for loadFailed
                    case .loadFailed:
                        return "Error: Load failed"
                    
                    /// Auto-generated error description for networkUnavailable
                    case .networkUnavailable:
                        return "Error: Network unavailable"
                    
                    /// Auto-generated error description for permissionDenied
                    case .permissionDenied:
                        return "Error: Permission denied"
                    }
                }
                
                // MARK: - Generated Recovery Strategies
                
                /// Provides recovery strategies for errors
                public var recoverySuggestion: String? {
                    switch self {
                    
                    case .loadFailed:
                        return "Please try reloading the data"
                    
                    case .networkUnavailable:
                        return "Check your internet connection and try again"
                    
                    case .permissionDenied:
                        return "Please grant the required permissions in Settings"
                    }
                }
                
                // MARK: - Generated User Messages
                
                /// Provides user-friendly error messages
                public var userMessage: String {
                    switch self {
                    
                    case .loadFailed:
                        return "Failed to load data"
                    
                    case .networkUnavailable:
                        return "Unable to connect to the internet"
                    
                    case .permissionDenied:
                        return "Permission required to continue"
                    }
                }
                
                // MARK: - Generated Context Information
                
                /// Error domain for this error type
                public static var errorDomain: String {
                    return "TaskManager"
                }
                
                /// Error code based on case
                public var errorCode: Int {
                    switch self {
                    // Error codes will be generated based on enum cases
                    }
                }
                
                /// Additional context information
                public var contextInfo: [String: Any] {
                    return [
                        "domain": Self.errorDomain,
                        "code": errorCode,
                        "timestamp": Date(),
                        "case": String(describing: self)
                    ]
                }
            }
            """,
            macros: ["ErrorContext": ErrorContextMacro.self]
        )
    }
    
    func testErrorContextMacroWithCustomConfiguration() throws {
        assertMacroExpansion(
            """
            @ErrorContext(domain: "UserAuth", includeRecoveryStrategies: false, includeLocalization: true)
            enum AuthError: Error {
                case invalidCredentials
                case accountLocked
            }
            """,
            expandedSource: """
            enum AuthError: Error {
                case invalidCredentials
                case accountLocked
                
                // MARK: - Generated Error Descriptions
                
                /// Provides detailed error descriptions
                public var errorDescription: String? {
                    switch self {
                    
                    /// Auto-generated error description for invalidCredentials
                    case .invalidCredentials:
                        return "Error: Invalid credentials"
                    
                    /// Auto-generated error description for accountLocked
                    case .accountLocked:
                        return "Error: Account locked"
                    }
                }
                
                // MARK: - Generated User Messages
                
                /// Provides user-friendly error messages
                public var userMessage: String {
                    switch self {
                    
                    case .invalidCredentials:
                        return "An error occurred"
                    
                    case .accountLocked:
                        return "An error occurred"
                    }
                }
                
                // MARK: - Generated Context Information
                
                /// Error domain for this error type
                public static var errorDomain: String {
                    return "UserAuth"
                }
                
                /// Error code based on case
                public var errorCode: Int {
                    switch self {
                    // Error codes will be generated based on enum cases
                    }
                }
                
                /// Additional context information
                public var contextInfo: [String: Any] {
                    return [
                        "domain": Self.errorDomain,
                        "code": errorCode,
                        "timestamp": Date(),
                        "case": String(describing: self)
                    ]
                }
                
                // MARK: - Generated Localization Support
                
                /// Localized error description
                public var localizedDescription: String {
                    return NSLocalizedString(
                        "error_\\(String(describing: self))",
                        comment: "Error description for \\(String(describing: self))"
                    )
                }
                
                /// Localized recovery suggestion
                public var localizedRecoverySuggestion: String? {
                    return NSLocalizedString(
                        "error_\\(String(describing: self))_recovery",
                        comment: "Recovery suggestion for \\(String(describing: self))"
                    )
                }
            }
            """,
            macros: ["ErrorContext": ErrorContextMacro.self]
        )
    }
    
    // MARK: - Architectural Validation Integration Tests
    
    func testMacroArchitecturalValidationIntegration() throws {
        // Test that macros respect architectural constraints
        // This test validates that macro-generated code follows unidirectional flow
        assertMacroExpansion(
            """
            @Context(client: TaskClient.self)
            struct TaskContext {
                // Context can depend on Client (valid flow)
            }
            """,
            expandedSource: """
            struct TaskContext {
                // Context can depend on Client (valid flow)
                
                // MARK: - Generated Client
                
                /// The client this context observes
                public let client: TaskClient
                
                // MARK: - Generated Published Properties
                
                /// Auto-generated from client state
                @Published public var tasks: Any?
                
                /// Auto-generated from client state
                @Published public var isLoading: Any?
                
                /// Auto-generated from client state
                @Published public var error: Any?
                
                // MARK: - Generated State Management
                
                /// Tracks if context is currently active
                public private(set) var isActive = false
                
                /// Task managing client state observation
                private var observationTask: Task<Void, Never>?
                
                /// Tracks initialization state
                private var isInitialized = false
                
                // MARK: - Generated Initializer
                
                public init(client: TaskClient) {
                    self.client = client
                    setupInitialState()
                }
                
                // MARK: - Generated Lifecycle Methods
                
                /// Called when view appears
                public func viewAppeared() async {
                    guard !isActive else { return }
                    isActive = true
                    startObservation()
                    await handleAppearance()
                }
                
                /// Called when view disappears
                public func viewDisappeared() async {
                    stopObservation()
                    isActive = false
                    await handleDisappearance()
                }
                
                /// Setup initial state
                private func setupInitialState() {
                    // Initialize @Published properties with default values
                    self.tasks = nil
                    self.isLoading = nil
                    self.error = nil
                }
                
                /// Handle appearance logic
                private func handleAppearance() async {
                    // Override in concrete implementation if needed
                }
                
                /// Handle disappearance logic  
                private func handleDisappearance() async {
                    // Override in concrete implementation if needed
                }
                
                // MARK: - Generated Observation Management
                
                private func startObservation() {
                    observationTask = Task { [weak self] in
                        guard let self = self else { return }
                        for await state in await self.client.stateStream {
                            await self.handleStateUpdate(state)
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                @MainActor
                private func handleStateUpdate(_ state: Any) async {
                    // Update @Published properties from client state
                    if let value = (state as? AnyObject)?.value(forKeyPath: "tasks") {
                        self.tasks = value
                    }
                    if let value = (state as? AnyObject)?.value(forKeyPath: "isLoading") {
                        self.isLoading = value
                    }
                    if let value = (state as? AnyObject)?.value(forKeyPath: "error") {
                        self.error = value
                    }
                    
                    // Trigger SwiftUI update
                    objectWillChange.send()
                }
                
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
            }
            
            extension TaskContext: ObservableObject {
            }
            """,
            macros: ["Context": ContextMacro.self]
        )
    }
    
    // MARK: - Capability Macro Tests
    
    func testCapabilityMacroGeneratesLifecycleManagement() throws {
        assertMacroExpansion(
            """
            @Capability(.network)
            actor NetworkCapability {
                func fetchData(from url: URL) async throws -> Data {
                    return try await URLSession.shared.data(from: url).0
                }
            }
            """,
            expandedSource: """
            actor NetworkCapability {
                func fetchData(from url: URL) async throws -> Data {
                    return try await URLSession.shared.data(from: url).0
                }
                
                // Note: Add 'extension NetworkCapability: ExtendedCapability {}' to conform to the protocol
                
                private var _state: CapabilityState = .unknown
                
                private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
                
                public var state: CapabilityState {
                    get async { _state }
                }
                
                public var stateStream: AsyncStream<CapabilityState> {
                    get async {
                        AsyncStream { continuation in
                            self.stateStreamContinuation = continuation
                            continuation.yield(_state)
                        }
                    }
                }
                
                public var isAvailable: Bool {
                    get async { await state == .available }
                }
                
                public func activate() async throws {
                    await transitionTo(.available)
                }
                
                public func deactivate() async {
                    await transitionTo(.unavailable)
                    stateStreamContinuation?.finish()
                }
                
                public func isSupported() async -> Bool {
                    return true
                }
                
                public func requestPermission() async throws {
                    // Network capability doesn't require permission
                }
                
                private func transitionTo(_ newState: CapabilityState) async {
                    guard _state != newState else { return }
                    _state = newState
                    stateStreamContinuation?.yield(newState)
                }
            }
            """,
            macros: ["Capability": CapabilityMacro.self]
        )
    }
    
    // MARK: - NavigationOrchestrator Macro Tests
    
    func testNavigationOrchestratorMacroGeneratesComprehensiveInfrastructure() throws {
        assertMacroExpansion(
            """
            @NavigationOrchestrator
            class AppOrchestrator {
                func navigateToHome() {
                    // Navigation logic
                }
            }
            """,
            expandedSource: """
            class AppOrchestrator {
                func navigateToHome() {
                    // Navigation logic
                }
                
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
                
                // Additional generated navigation and lifecycle methods...
            }
            
            extension AppOrchestrator: OrchestratorValidatable {
            }
            """,
            macros: ["NavigationOrchestrator": NavigationOrchestratorMacro.self]
        )
    }
    
    // MARK: - AutoMockable Macro Tests
    
    func testAutoMockableMacroGeneratesComprehensiveMock() throws {
        assertMacroExpansion(
            """
            @AutoMockable
            protocol TaskService {
                func loadTasks() async throws -> [String]
                var isLoading: Bool { get }
            }
            """,
            expandedSource: """
            protocol TaskService {
                func loadTasks() async throws -> [String]
                var isLoading: Bool { get }
            }
            
            public class MockTaskService: TaskService {
                
                // MARK: - Call Counting Infrastructure
                
                public private(set) var loadTasksCallCount = 0
                
                // MARK: - Property Recording Infrastructure
                
                public private(set) var isLoadingGetCount = 0
                
                // MARK: - Property Implementations
                
                private var _isLoading: Bool?
                public var isLoadingStub: Bool?
                
                public var isLoading: Bool {
                    get {
                        isLoadingGetCount += 1
                        return isLoadingStub ?? _isLoading ?? defaultValue(for: Bool.self)
                    }
                }
                
                // MARK: - Method Implementations
                
                public var loadTasksStub: [String]?
                
                public var loadTasksErrorStub: Error?
                
                public func loadTasks() async throws -> [String] {
                    loadTasksCallCount += 1
                    if let error = loadTasksErrorStub {
                        throw error
                    }
                    return loadTasksStub ?? defaultValue(for: [String].self)
                }
                
                // MARK: - Validation Helpers
                
                public func verifyLoadTasksCalled(times: Int = 1) -> Bool {
                    return loadTasksCallCount == times
                }
                
                public func verifyIsLoadingAccessed(times: Int = 1) -> Bool {
                    return isLoadingGetCount == times
                }
                
                // MARK: - Reset Functionality
                
                public func reset() {
                    loadTasksCallCount = 0
                    isLoadingGetCount = 0
                    loadTasksStub = nil
                    loadTasksErrorStub = nil
                    isLoadingStub = nil
                    _isLoading = nil
                }
                
                private func defaultValue<T>(for type: T.Type) -> T {
                    switch type {
                    case is String.Type: return "" as! T
                    case is Int.Type: return 0 as! T
                    case is Bool.Type: return false as! T
                    case is Array<Any>.Type: return [] as! T
                    case is Dictionary<AnyHashable, Any>.Type: return [:] as! T
                    default: fatalError("No default value for type \\(type)")
                    }
                }
            }
            """,
            macros: ["AutoMockable": AutoMockableMacro.self]
        )
    }
    
    // MARK: - Presentation Macro Tests
    
    func testPresentationMacroGeneratesViewBoilerplate() throws {
        assertMacroExpansion(
            """
            @Presentation(context: TaskListContext.self)
            struct TaskListView: View {
                var body: some View {
                    List {
                        Text("Tasks")
                    }
                }
            }
            """,
            expandedSource: """
            struct TaskListView: View {
                var body: some View {
                    List {
                        Text("Tasks")
                    }
                }
                
                // MARK: - Generated Context
                
                /// The context this presentation observes
                @StateObject private var context: TaskListContext
                
                // MARK: - Generated Initializer
                
                init(context: TaskListContext) {
                    self._context = StateObject(wrappedValue: context)
                }
                
                init() {
                    // Default initializer requires context parameter
                    fatalError("Presentation requires context parameter")
                }
                
                // Compile-time validation for TaskListView
                private struct _ValidatePresentationTaskListView {
                    // This type exists solely for compile-time validation
                    // It will cause errors if architectural constraints are violated
                }
            }
            
            extension TaskListView: PresentationProtocol {
                typealias ContextType = TaskListContext
            }
            """,
            macros: ["Presentation": PresentationMacro.self]
        )
    }
    
    // MARK: - ErrorBoundary Macro Tests
    
    func testErrorBoundaryMacroGeneratesErrorHandling() throws {
        assertMacroExpansion(
            """
            @ErrorBoundary
            class DataService {
                func loadData() async throws -> String {
                    return "data"
                }
            }
            """,
            expandedSource: """
            class DataService {
                func loadData() async throws -> String {
                    return "data"
                }
                
                // MARK: - Generated Error Boundary Infrastructure
                
                /// Error boundary state tracking
                private var errorBoundaryState = ErrorBoundaryState()
                
                /// Error boundary lock for thread safety
                private let errorBoundaryLock = NSLock()
                
                /// Initialize error boundary with configuration
                private func initializeErrorBoundary() {
                    errorBoundaryLock.lock()
                    defer { errorBoundaryLock.unlock() }
                    
                    errorBoundaryState.strategy = .propagate
                    errorBoundaryState.enableRetry = true
                    errorBoundaryState.maxRetries = 3
                    errorBoundaryState.enableLogging = true
                    errorBoundaryState.enableReporting = true
                    errorBoundaryState.enableUserFeedback = true
                }
                
                // Additional error boundary infrastructure and wrapped methods...
            }
            """,
            macros: ["ErrorBoundary": ErrorBoundaryMacro.self]
        )
    }
    
    // MARK: - Comprehensive Macro Integration Tests
    
    func testMacroSystemComprehensiveIntegration() throws {
        // Test that multiple macros work together
        assertMacroExpansion(
            """
            @Context(client: TaskClient.self)
            @ErrorBoundary
            struct TaskListContext {
                func loadTasks() async throws {
                    await client.process(.loadTasks)
                }
            }
            """,
            expandedSource: """
            struct TaskListContext {
                func loadTasks() async throws {
                    await client.process(.loadTasks)
                }
                
                // Generated from @Context macro
                // MARK: - Generated Client
                
                /// The client this context observes
                public let client: TaskClient
                
                // Generated from @ErrorBoundary macro  
                // MARK: - Generated Error Boundary Infrastructure
                
                /// Error boundary state tracking
                private var errorBoundaryState = ErrorBoundaryState()
                
                // Additional comprehensive macro-generated code...
            }
            
            extension TaskListContext: ObservableObject {
            }
            """,
            macros: [
                "Context": ContextMacro.self,
                "ErrorBoundary": ErrorBoundaryMacro.self
            ]
        )
    }
}