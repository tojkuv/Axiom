import XCTest
import AxiomTesting
@testable import AxiomMacros
@testable import AxiomArchitecture
@testable import AxiomCore
import SwiftSyntaxMacrosTestSupport

/// Integration tests for multiple AxiomMacros working together
final class MacroIntegrationTests: XCTestCase {
    
    // MARK: - AutoMockableMacro Tests
    
    func testAutoMockableMacroOnProtocol() throws {
        assertMacroExpansion(
            """
            @AxiomAutoMockable
            protocol DataService {
                func fetchData() async throws -> Data
                func saveData(_ data: Data) async throws
                var isConnected: Bool { get }
            }
            """,
            expandedSource: """
            protocol DataService {
                func fetchData() async throws -> Data
                func saveData(_ data: Data) async throws
                var isConnected: Bool { get }
            }
            
            class MockDataService: DataService {
                // Generated mock properties
                var fetchDataCallCount = 0
                var fetchDataReturnValue: Data = Data()
                var fetchDataShouldThrow = false
                var fetchDataThrownError: Error?
                
                var saveDataCallCount = 0
                var saveDataShouldThrow = false
                var saveDataThrownError: Error?
                var saveDataReceivedData: Data?
                
                var isConnectedReturnValue = false
                var isConnected: Bool {
                    return isConnectedReturnValue
                }
                
                // Generated mock methods
                func fetchData() async throws -> Data {
                    fetchDataCallCount += 1
                    
                    if fetchDataShouldThrow {
                        throw fetchDataThrownError ?? MockError.genericError
                    }
                    
                    return fetchDataReturnValue
                }
                
                func saveData(_ data: Data) async throws {
                    saveDataCallCount += 1
                    saveDataReceivedData = data
                    
                    if saveDataShouldThrow {
                        throw saveDataThrownError ?? MockError.genericError
                    }
                }
                
                // Reset functionality
                func resetMock() {
                    fetchDataCallCount = 0
                    fetchDataShouldThrow = false
                    fetchDataThrownError = nil
                    
                    saveDataCallCount = 0
                    saveDataShouldThrow = false
                    saveDataThrownError = nil
                    saveDataReceivedData = nil
                    
                    isConnectedReturnValue = false
                }
            }
            
            enum MockError: Error {
                case genericError
            }
            """,
            macros: ["AxiomAutoMockable": AutoMockableMacro.self]
        )
    }
    
    // MARK: - PresentationMacro Tests
    
    func testPresentationMacroOnSwiftUIView() throws {
        assertMacroExpansion(
            """
            @AxiomPresentation(context: TodoContext.self)
            struct TodoView: View {
                var body: some View {
                    Text("Todo List")
                }
            }
            """,
            expandedSource: """
            struct TodoView: View {
                var body: some View {
                    Text("Todo List")
                }
            }
            
            extension TodoView: PresentationProtocol {
                typealias ContextType = TodoContext
                
                var contextType: ContextType.Type {
                    return TodoContext.self
                }
                
                func bindToContext(_ context: TodoContext) -> some View {
                    self.environmentObject(context)
                        .onAppear {
                            context.viewAppeared()
                        }
                        .onDisappear {
                            context.viewDisappeared()
                        }
                        .onChange(of: context.updateTrigger) { _ in
                            // Handle context updates
                        }
                }
                
                static func withContext() -> some View {
                    let context = TodoContext()
                    return TodoView().bindToContext(context)
                }
            }
            
            // Validation struct for compile-time safety
            struct _ValidatePresentationTodoView {
                static func validateContextType() {
                    let _: TodoContext.Type = TodoContext.self
                }
                
                static func validateViewConformance() {
                    let _: any View = TodoView()
                }
            }
            """,
            macros: ["AxiomPresentation": PresentationMacro.self]
        )
    }
    
    // MARK: - NavigationOrchestratorMacro Tests
    
    func testNavigationOrchestratorMacro() throws {
        assertMacroExpansion(
            """
            @NavigationOrchestrator
            struct AppNavigator {
                let routes: [AppRoute]
            }
            """,
            expandedSource: """
            struct AppNavigator {
                let routes: [AppRoute]
            }
            
            extension AppNavigator: NavigationOrchestrator {
                func navigate(to route: AppRoute) async throws {
                    // Auto-generated navigation logic
                    guard routes.contains(route) else {
                        throw AxiomError.navigationError(.routeNotFound(route.identifier))
                    }
                    
                    // Route validation
                    try validateRoute(route)
                    
                    // Navigation execution
                    await executeNavigation(to: route)
                }
                
                func canNavigate(to route: AppRoute) -> Bool {
                    return routes.contains(route) && validateRouteAccess(route)
                }
                
                private func validateRoute(_ route: AppRoute) throws {
                    // Route validation logic
                    if route.requiresAuthentication && !isAuthenticated() {
                        throw AxiomError.navigationError(.authenticationRequired)
                    }
                }
                
                private func executeNavigation(to route: AppRoute) async {
                    // Navigation execution logic
                    await route.execute()
                }
                
                private func validateRouteAccess(_ route: AppRoute) -> Bool {
                    // Access validation logic
                    return !route.requiresAuthentication || isAuthenticated()
                }
                
                private func isAuthenticated() -> Bool {
                    // Authentication check
                    return UserDefaults.standard.bool(forKey: "isAuthenticated")
                }
            }
            """,
            macros: ["NavigationOrchestrator": NavigationOrchestratorMacro.self]
        )
    }
    
    // MARK: - ErrorBoundaryMacro Tests
    
    func testErrorBoundaryMacro() throws {
        assertMacroExpansion(
            """
            @ErrorBoundary
            class PaymentService {
                func processPayment(_ amount: Double) async throws -> PaymentResult {
                    // Implementation
                    return PaymentResult.success
                }
            }
            """,
            expandedSource: """
            class PaymentService {
                func processPayment(_ amount: Double) async throws -> PaymentResult {
                    // Implementation
                    return PaymentResult.success
                }
            }
            
            extension PaymentService: ErrorBoundaryManaged {
                private var errorBoundary: AxiomErrorBoundary = AxiomErrorBoundary()
                
                func handle(_ error: Error) async {
                    await errorBoundary.handle(error)
                    
                    // Service-specific error handling
                    if let paymentError = error as? PaymentError {
                        await handlePaymentError(paymentError)
                    }
                }
                
                func executeWithRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    maxRetries: Int? = nil,
                    strategy: ErrorRecoveryStrategy = .propagate
                ) async throws -> T {
                    return try await errorBoundary.executeWithRecovery(
                        operation,
                        maxRetries: maxRetries,
                        strategy: strategy
                    )
                }
                
                func canRecover(from error: Error) -> Bool {
                    return errorBoundary.canRecover(from: error)
                }
                
                private func handlePaymentError(_ error: PaymentError) async {
                    switch error {
                    case .insufficientFunds:
                        // Handle insufficient funds
                        break
                    case .networkError:
                        // Handle network error with retry
                        break
                    case .invalidCard:
                        // Handle invalid card
                        break
                    }
                }
                
                // Safe payment processing with error boundary
                func safeProcessPayment(_ amount: Double) async throws -> PaymentResult {
                    return try await executeWithRecovery(
                        {
                            try await self.processPayment(amount)
                        },
                        maxRetries: 3,
                        strategy: .retry(attempts: 3)
                    )
                }
            }
            """,
            macros: ["ErrorBoundary": ErrorBoundaryMacro.self]
        )
    }
    
    // MARK: - Macro Combination Tests
    
    func testCombinedMacros() throws {
        assertMacroExpansion(
            """
            @AxiomAction(validation: true, performance: true)
            @AxiomClient(state: UserState.self, action: UserAction.self)
            @AxiomErrorHandling
            actor UserManager {
                
            }
            """,
            expandedSource: """
            actor UserManager {
                
            }
            
            extension UserManager: Sendable {
                // From AxiomAction macro
                var actionId: String {
                    return "UserManager"
                }
                
                var description: String {
                    return "Action: \\(actionId)"
                }
                
                var triggersSave: Bool {
                    return true
                }
                
                func validate() throws {
                    // Validation implementation
                }
                
                func validateParameters() throws {
                    // Parameter validation implementation
                }
                
                var isValid: Bool {
                    do {
                        try validate()
                        try validateParameters()
                        return true
                    } catch {
                        return false
                    }
                }
                
                func trackExecution() {
                    // Performance tracking implementation
                }
            }
            
            extension UserManager: AxiomClient {
                // From AxiomClient macro
                private var _internalState: UserState = UserState()
                private var _stateObservers: [AsyncStream<UserState>.Continuation] = []
                
                var state: UserState {
                    get async {
                        return _internalState
                    }
                }
                
                var stateStream: AsyncStream<UserState> {
                    AsyncStream { continuation in
                        _stateObservers.append(continuation)
                        continuation.yield(_internalState)
                        
                        continuation.onTermination = { @Sendable _ in
                            Task {
                                await self.removeObserver(continuation)
                            }
                        }
                    }
                }
                
                func getCurrentState() async -> UserState {
                    return _internalState
                }
                
                func rollbackToState(_ state: UserState) async {
                    await _updateState(state)
                }
                
                private func _updateState(_ newState: UserState) async {
                    _internalState = newState
                    
                    for observer in _stateObservers {
                        observer.yield(newState)
                    }
                }
                
                private func removeObserver(_ observer: AsyncStream<UserState>.Continuation) async {
                    _stateObservers.removeAll { $0 === observer }
                }
                
                func process(_ action: UserAction) async throws {
                    trackExecution()
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    defer {
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let duration = endTime - startTime
                        print("Action processing took \\(duration)s")
                    }
                    
                    let newState = try await processUserAction(action, currentState: _internalState)
                    await _updateState(newState)
                }
                
                private func processUserAction(_ action: UserAction, currentState: UserState) async throws -> UserState {
                    return currentState
                }
            }
            
            extension UserManager: ErrorBoundaryManaged {
                // From AxiomErrorHandling macro
                func handle(_ error: Error) async {
                    if let axiomError = error as? AxiomError {
                        await handleAxiomError(axiomError)
                    } else {
                        await handleGenericError(error)
                    }
                }
                
                func executeWithRecovery<T: Sendable>(
                    _ operation: @Sendable () async throws -> T,
                    maxRetries: Int? = nil,
                    strategy: ErrorRecoveryStrategy = .propagate
                ) async throws -> T {
                    let maxAttempts = maxRetries ?? strategy.defaultRetryCount
                    var lastError: Error?
                    
                    for attempt in 1...maxAttempts {
                        do {
                            return try await operation()
                        } catch {
                            lastError = error
                            await handle(error)
                            
                            if attempt == maxAttempts || !canRecover(from: error) {
                                throw error
                            }
                            
                            try? await Task.sleep(for: .milliseconds(200 * attempt))
                        }
                    }
                    
                    throw lastError ?? AxiomError.unknownError
                }
                
                func canRecover(from error: Error) -> Bool {
                    guard let axiomError = error as? AxiomError else {
                        return false
                    }
                    
                    return axiomError.recoveryStrategy.allowsRetry
                }
                
                private func handleAxiomError(_ error: AxiomError) async {
                    // Handle AxiomError
                }
                
                private func handleGenericError(_ error: Error) async {
                    // Handle generic error
                }
            }
            """,
            macros: [
                "AxiomAction": ActionMacro.self,
                "AxiomClient": ClientMacro.self,
                "AxiomErrorHandling": ErrorHandlingMacro.self
            ]
        )
    }
    
    // MARK: - Performance Tests
    
    func testMacroIntegrationPerformance() throws {
        let iterations = 10
        let expectation = self.expectation(description: "Macro integration performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for _ in 0..<iterations {
                // Test multiple macro expansions
                _ = try? ActionMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomAction"))
                    ),
                    attachedTo: EnumDeclSyntax(
                        name: .identifier("TestAction"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestAction")),
                    conformingTo: [],
                    in: TestMacroExpansionContext()
                )
                
                _ = try? ContextMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomContext"))
                    ),
                    attachedTo: ClassDeclSyntax(
                        name: .identifier("TestContext"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestContext")),
                    conformingTo: [],
                    in: TestMacroExpansionContext()
                )
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let averageTime = (endTime - startTime) / Double(iterations)
            
            XCTAssertLessThan(averageTime, 0.02, "Multiple macro expansion should be fast (< 20ms per iteration)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testMacroErrorHandling() throws {
        // Test that invalid combinations produce appropriate errors
        XCTAssertThrowsError(
            try ActionMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomAction"))
                ),
                attachedTo: ProtocolDeclSyntax(
                    name: .identifier("TestProtocol"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestProtocol")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Test Helper

/// Test macro expansion context for integration testing
class TestMacroExpansionContext: MacroExpansionContext {
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax(.identifier("\\(name)_\\(UUID().uuidString.prefix(8))"), presence: .present)
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        // Handle diagnostics in tests
    }
}

// MARK: - Test Types

enum PaymentResult {
    case success
    case failure(PaymentError)
}

enum PaymentError: Error {
    case insufficientFunds
    case networkError
    case invalidCard
}

struct AppRoute: Equatable {
    let identifier: String
    let requiresAuthentication: Bool
    
    func execute() async {
        // Route execution logic
    }
}

struct TodoContext: ObservableObject {
    func viewAppeared() {}
    func viewDisappeared() {}
    var updateTrigger: Int = 0
}

enum UserAction {
    case login(String)
    case logout
}

// Extension for ErrorRecoveryStrategy to support testing
extension ErrorRecoveryStrategy {
    var defaultRetryCount: Int {
        switch self {
        case .retry(let attempts):
            return attempts
        case .propagate, .silent, .userPrompt:
            return 1
        }
    }
    
    var allowsRetry: Bool {
        switch self {
        case .retry:
            return true
        case .propagate, .silent, .userPrompt:
            return false
        }
    }
}