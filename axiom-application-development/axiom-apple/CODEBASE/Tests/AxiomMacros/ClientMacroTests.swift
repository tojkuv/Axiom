import XCTest
import AxiomTesting
@testable import AxiomMacros
@testable import AxiomArchitecture
import SwiftSyntaxMacrosTestSupport

/// Comprehensive tests for AxiomMacros client macro functionality
final class ClientMacroTests: XCTestCase {
    
    // MARK: - Basic Client Macro Tests
    
    func testClientMacroOnActor() throws {
        assertMacroExpansion(
            """
            @AxiomClient(
                state: TodoState.self,
                action: TodoAction.self,
                initialState: TodoState(),
                performanceBudget: .responsive
            )
            actor TodoClient {
                
            }
            """,
            expandedSource: """
            actor TodoClient {
                
            }
            
            extension TodoClient: AxiomClient {
                private var _internalState: TodoState = TodoState()
                private var _stateObservers: [AsyncStream<TodoState>.Continuation] = []
                
                var state: TodoState {
                    get async {
                        return _internalState
                    }
                }
                
                var stateStream: AsyncStream<TodoState> {
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
                
                func getCurrentState() async -> TodoState {
                    return _internalState
                }
                
                func rollbackToState(_ state: TodoState) async {
                    await _updateState(state)
                }
                
                private func _updateState(_ newState: TodoState) async {
                    _internalState = newState
                    
                    // Notify all observers
                    for observer in _stateObservers {
                        observer.yield(newState)
                    }
                }
                
                private func removeObserver(_ observer: AsyncStream<TodoState>.Continuation) async {
                    _stateObservers.removeAll { $0 === observer }
                }
                
                // Performance budget handling
                private func validatePerformanceBudget() {
                    // Performance budget: responsive
                    // Auto-generated performance monitoring
                }
                
                // Action processing
                func process(_ action: TodoAction) async throws {
                    validatePerformanceBudget()
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    defer {
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let duration = endTime - startTime
                        
                        // Log performance metrics
                        if duration > 0.1 { // 100ms threshold for responsive
                            print("Performance warning: Action processing took \\(duration)s")
                        }
                    }
                    
                    // Process action and update state
                    let newState = try await processAction(action, currentState: _internalState)
                    await _updateState(newState)
                }
                
                private func processAction(_ action: TodoAction, currentState: TodoState) async throws -> TodoState {
                    // Action processing logic would be implemented here
                    return currentState
                }
            }
            """,
            macros: ["AxiomClient": ClientMacro.self]
        )
    }
    
    func testClientMacroWithMinimalParameters() throws {
        assertMacroExpansion(
            """
            @AxiomClient(state: UserState.self)
            actor UserClient {
                
            }
            """,
            expandedSource: """
            actor UserClient {
                
            }
            
            extension UserClient: AxiomClient {
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
                    
                    // Notify all observers
                    for observer in _stateObservers {
                        observer.yield(newState)
                    }
                }
                
                private func removeObserver(_ observer: AsyncStream<UserState>.Continuation) async {
                    _stateObservers.removeAll { $0 === observer }
                }
                
                // Default performance budget
                private func validatePerformanceBudget() {
                    // Performance budget: standard
                }
                
                // Generic action processing
                func process<A>(_ action: A) async throws {
                    validatePerformanceBudget()
                    // Generic action processing implementation
                }
            }
            """,
            macros: ["AxiomClient": ClientMacro.self]
        )
    }
    
    // MARK: - State Macro Integration Tests
    
    func testStateMacroOnStruct() throws {
        assertMacroExpansion(
            """
            @AxiomState(validation: true, optimizeEquality: true, customHashable: false, memoryOptimized: true)
            struct AppState {
                let userId: String
                var isLoggedIn: Bool
                var preferences: [String: Any]
            }
            """,
            expandedSource: """
            struct AppState {
                let userId: String
                var isLoggedIn: Bool
                var preferences: [String: Any]
            }
            
            extension AppState: AxiomState {
                var stateId: String {
                    return "AppState"
                }
                
                var stateVersion: Int {
                    return 1
                }
                
                func validate() throws {
                    // Auto-generated validation
                    if userId.isEmpty {
                        throw AxiomError.validationError(.invalidInput("userId", "cannot be empty"))
                    }
                    
                    // Custom validation logic would go here
                }
                
                func isValid() -> Bool {
                    do {
                        try validate()
                        return true
                    } catch {
                        return false
                    }
                }
                
                // Optimized equality comparison
                static func == (lhs: AppState, rhs: AppState) -> Bool {
                    return lhs.userId == rhs.userId &&
                           lhs.isLoggedIn == rhs.isLoggedIn &&
                           NSDictionary(dictionary: lhs.preferences).isEqual(to: rhs.preferences)
                }
                
                // Memory-optimized operations
                func withMemoryOptimization() -> AppState {
                    var optimized = self
                    // Remove unnecessary data for memory optimization
                    if preferences.isEmpty {
                        optimized.preferences = [:]
                    }
                    return optimized
                }
                
                // State transition methods
                func applying<A>(_ action: A) throws -> AppState {
                    // State transition logic based on action
                    return self
                }
                
                func merged(with other: AppState) -> AppState {
                    // State merging logic
                    var merged = self
                    merged.isLoggedIn = other.isLoggedIn
                    merged.preferences.merge(other.preferences) { (_, new) in new }
                    return merged
                }
            }
            
            extension AppState: Equatable {
                // Generated by optimizeEquality parameter
            }
            
            extension AppState: Sendable {
                // Auto-generated Sendable conformance for thread safety
            }
            """,
            macros: ["AxiomState": StateMacro.self]
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testClientMacroErrorOnClass() throws {
        XCTAssertThrowsError(
            try ClientMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomClient"))
                ),
                attachedTo: ClassDeclSyntax(
                    name: .identifier("TestClass"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestClass")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ClientMacroError)
        }
    }
    
    func testClientMacroErrorOnStruct() throws {
        XCTAssertThrowsError(
            try ClientMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomClient"))
                ),
                attachedTo: StructDeclSyntax(
                    name: .identifier("TestStruct"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestStruct")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            XCTAssertTrue(error is ClientMacroError)
        }
    }
    
    func testClientMacroErrorMissingStateParameter() throws {
        XCTAssertThrowsError(
            try ClientMacro.expansion(
                of: AttributeSyntax(
                    attributeName: IdentifierTypeSyntax(name: .identifier("AxiomClient"))
                ),
                attachedTo: ActorDeclSyntax(
                    name: .identifier("TestActor"),
                    memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                ),
                providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestActor")),
                conformingTo: [],
                in: TestMacroExpansionContext()
            )
        ) { error in
            if let clientError = error as? ClientMacroError {
                XCTAssertEqual(clientError, .missingStateParameter)
            } else {
                XCTFail("Expected ClientMacroError.missingStateParameter")
            }
        }
    }
    
    // MARK: - Performance Budget Tests
    
    func testClientMacroWithPerformanceBudgets() throws {
        assertMacroExpansion(
            """
            @AxiomClient(
                state: DataState.self,
                performanceBudget: .realtime
            )
            actor DataClient {
                
            }
            """,
            expandedSource: """
            actor DataClient {
                
            }
            
            extension DataClient: AxiomClient {
                private var _internalState: DataState = DataState()
                private var _stateObservers: [AsyncStream<DataState>.Continuation] = []
                
                var state: DataState {
                    get async {
                        return _internalState
                    }
                }
                
                var stateStream: AsyncStream<DataState> {
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
                
                func getCurrentState() async -> DataState {
                    return _internalState
                }
                
                func rollbackToState(_ state: DataState) async {
                    await _updateState(state)
                }
                
                private func _updateState(_ newState: DataState) async {
                    _internalState = newState
                    
                    // Notify all observers
                    for observer in _stateObservers {
                        observer.yield(newState)
                    }
                }
                
                private func removeObserver(_ observer: AsyncStream<DataState>.Continuation) async {
                    _stateObservers.removeAll { $0 === observer }
                }
                
                // Performance budget handling
                private func validatePerformanceBudget() {
                    // Performance budget: realtime (< 16ms)
                    // Strict performance monitoring for realtime operations
                }
                
                // Realtime action processing
                func process<A>(_ action: A) async throws {
                    validatePerformanceBudget()
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    defer {
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let duration = endTime - startTime
                        
                        // Strict realtime threshold
                        if duration > 0.016 { // 16ms threshold for realtime
                            print("Performance violation: Realtime action processing took \\(duration)s")
                        }
                    }
                    
                    // Optimized action processing for realtime requirements
                }
            }
            """,
            macros: ["AxiomClient": ClientMacro.self]
        )
    }
    
    // MARK: - Performance Tests
    
    func testClientMacroPerformance() throws {
        let iterations = 20
        let expectation = self.expectation(description: "Client macro expansion performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for i in 0..<iterations {
                _ = try? ClientMacro.expansion(
                    of: AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(name: .identifier("AxiomClient")),
                        arguments: .argumentList([
                            LabeledExprSyntax(
                                label: .identifier("state"),
                                expression: MemberAccessExprSyntax(
                                    base: IdentifierExprSyntax(identifier: .identifier("TestState\\(i)")),
                                    dot: .periodToken(),
                                    name: .identifier("self")
                                )
                            )
                        ])
                    ),
                    attachedTo: ActorDeclSyntax(
                        name: .identifier("TestClient"),
                        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
                    ),
                    providingExtensionsOf: IdentifierTypeSyntax(name: .identifier("TestClient")),
                    conformingTo: [],
                    in: TestMacroExpansionContext()
                )
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let averageTime = (endTime - startTime) / Double(iterations)
            
            XCTAssertLessThan(averageTime, 0.01, "Client macro expansion should be fast (< 10ms per expansion)")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    // MARK: - Complex Client Tests
    
    func testClientMacroWithComplexState() throws {
        assertMacroExpansion(
            """
            @AxiomClient(
                state: ComplexState.self,
                action: ComplexAction.self,
                initialState: ComplexState.default,
                performanceBudget: .standard
            )
            actor ComplexClient {
                
            }
            """,
            expandedSource: """
            actor ComplexClient {
                
            }
            
            extension ComplexClient: AxiomClient {
                private var _internalState: ComplexState = ComplexState.default
                private var _stateObservers: [AsyncStream<ComplexState>.Continuation] = []
                
                var state: ComplexState {
                    get async {
                        return _internalState
                    }
                }
                
                var stateStream: AsyncStream<ComplexState> {
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
                
                func getCurrentState() async -> ComplexState {
                    return _internalState
                }
                
                func rollbackToState(_ state: ComplexState) async {
                    await _updateState(state)
                }
                
                private func _updateState(_ newState: ComplexState) async {
                    _internalState = newState
                    
                    // Notify all observers
                    for observer in _stateObservers {
                        observer.yield(newState)
                    }
                }
                
                private func removeObserver(_ observer: AsyncStream<ComplexState>.Continuation) async {
                    _stateObservers.removeAll { $0 === observer }
                }
                
                // Performance budget handling
                private func validatePerformanceBudget() {
                    // Performance budget: standard
                }
                
                // Complex action processing
                func process(_ action: ComplexAction) async throws {
                    validatePerformanceBudget()
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    defer {
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let duration = endTime - startTime
                        
                        // Log performance metrics
                        if duration > 0.5 { // 500ms threshold for standard
                            print("Performance warning: Complex action processing took \\(duration)s")
                        }
                    }
                    
                    // Process complex action and update state
                    let newState = try await processComplexAction(action, currentState: _internalState)
                    await _updateState(newState)
                }
                
                private func processComplexAction(_ action: ComplexAction, currentState: ComplexState) async throws -> ComplexState {
                    // Complex action processing logic would be implemented here
                    return currentState
                }
            }
            """,
            macros: ["AxiomClient": ClientMacro.self]
        )
    }
}

// MARK: - Test Helper

/// Test macro expansion context for client testing
class TestMacroExpansionContext: MacroExpansionContext {
    func makeUniqueName(_ name: String) -> TokenSyntax {
        return TokenSyntax(.identifier("\\(name)_\\(UUID().uuidString.prefix(8))"), presence: .present)
    }
    
    func diagnose(_ diagnostic: Diagnostic) {
        // Handle diagnostics in tests
    }
}

// MARK: - ClientMacroError for Testing

enum ClientMacroError: Error, LocalizedError, Equatable {
    case mustBeAppliedToActor
    case missingStateParameter
    case invalidStateType(String)
    case invalidActionType(String)
    case invalidPerformanceBudget(String)
    case invalidParameter(String)
    
    var errorDescription: String? {
        switch self {
        case .mustBeAppliedToActor:
            return "ClientMacro can only be applied to actor declarations"
        case .missingStateParameter:
            return "ClientMacro requires a state parameter"
        case .invalidStateType(let type):
            return "Invalid state type: \\(type)"
        case .invalidActionType(let type):
            return "Invalid action type: \\(type)"
        case .invalidPerformanceBudget(let budget):
            return "Invalid performance budget: \\(budget)"
        case .invalidParameter(let param):
            return "Invalid parameter: \\(param)"
        }
    }
}

// MARK: - Test Types

struct TodoState: AxiomState {
    let items: [String] = []
}

struct UserState: AxiomState {
    let userId: String = ""
}

struct DataState: AxiomState {
    let data: [String: Any] = [:]
}

struct ComplexState: AxiomState {
    static let `default` = ComplexState()
    let complexData: [String: [String: Any]] = [:]
}

enum TodoAction {
    case addItem(String)
    case removeItem(String)
}

enum ComplexAction {
    case processData([String: Any])
    case clearAll
}