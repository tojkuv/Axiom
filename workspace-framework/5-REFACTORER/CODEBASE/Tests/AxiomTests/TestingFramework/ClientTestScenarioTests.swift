import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests for Client-focused test scenarios
final class ClientTestScenarioTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct TodoState: State, Equatable {
        var todos: [Todo] = []
        var isLoading: Bool = false
        var error: String? = nil
    }
    
    struct Todo: Equatable {
        let id: String
        let title: String
        var completed: Bool = false
    }
    
    enum TodoAction {
        case addTodo(Todo)
        case toggleTodo(id: String)
        case deleteTodo(id: String)
        case setLoading(Bool)
        case setError(String?)
    }
    
    actor TodoClient: BaseClient<TodoState, TodoAction> {
        override func process(_ action: TodoAction) async throws {
            var newState = state
            
            switch action {
            case .addTodo(let todo):
                newState.todos.append(todo)
            case .toggleTodo(let id):
                if let index = newState.todos.firstIndex(where: { $0.id == id }) {
                    newState.todos[index].completed.toggle()
                }
            case .deleteTodo(let id):
                newState.todos.removeAll { $0.id == id }
            case .setLoading(let loading):
                newState.isLoading = loading
            case .setError(let error):
                newState.error = error
            }
            
            updateState(newState)
        }
    }
    
    // MARK: - Client Test Scenario Tests
    
    func testClientScenarioBasicUsage() async throws {
        // Test basic given/when/then for clients
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .when(.addTodo(Todo(id: "1", title: "Test Todo")))
            .then { state in
                state.todos.count == 1 && state.todos[0].title == "Test Todo"
            }
        
        try await scenario.execute()
    }
    
    func testClientScenarioMultipleActions() async throws {
        // Test chaining multiple actions
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: [
                Todo(id: "1", title: "Todo 1", completed: false),
                Todo(id: "2", title: "Todo 2", completed: false)
            ]))
            .when(.toggleTodo(id: "1"))
            .when(.toggleTodo(id: "2"))
            .when(.deleteTodo(id: "1"))
            .then { state in
                state.todos.count == 1 &&
                state.todos[0].id == "2" &&
                state.todos[0].completed == true
            }
        
        try await scenario.execute()
    }
    
    func testClientScenarioStateStream() async throws {
        // Test that state stream is properly captured
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .captureStateHistory()
            .when(.setLoading(true))
            .when(.addTodo(Todo(id: "1", title: "New Todo")))
            .when(.setLoading(false))
        
        try await scenario.execute()
        
        // Should have captured 4 states: initial + 3 actions
        XCTAssertEqual(scenario.stateHistory.count, 4)
        XCTAssertEqual(scenario.stateHistory[0].isLoading, false)
        XCTAssertEqual(scenario.stateHistory[1].isLoading, true)
        XCTAssertEqual(scenario.stateHistory[2].todos.count, 1)
        XCTAssertEqual(scenario.stateHistory[3].isLoading, false)
    }
    
    func testClientScenarioWithTimeout() async throws {
        // Test action timeout
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .withActionTimeout(.milliseconds(100))
            .when(.addTodo(Todo(id: "1", title: "Test")))
            .then { $0.todos.count == 1 }
        
        try await scenario.execute()
    }
    
    func testClientScenarioFailureCondition() async throws {
        // Test that failures are properly reported
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .when(.addTodo(Todo(id: "1", title: "Test")))
            .then { state in
                state.todos.count == 2 // This should fail
            }
        
        do {
            try await scenario.execute()
            XCTFail("Expected scenario to fail")
        } catch let error as ClientTestScenarioError {
            XCTAssertTrue(error.message.contains("Assertion failed"))
            XCTAssertEqual(error.actualState.todos.count, 1)
        }
    }
    
    func testClientScenarioPerformanceMeasurement() async throws {
        // Test performance measurement
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .measureExecutionTime()
            .when(.addTodo(Todo(id: "1", title: "Todo 1")))
            .when(.addTodo(Todo(id: "2", title: "Todo 2")))
            .when(.toggleTodo(id: "1"))
            .when(.deleteTodo(id: "2"))
        
        try await scenario.execute()
        
        XCTAssertNotNil(scenario.executionMetrics)
        XCTAssertGreaterThan(scenario.executionMetrics!.totalDuration, 0)
        XCTAssertEqual(scenario.executionMetrics!.actionCount, 4)
    }
    
    func testClientScenarioWithPreconditions() async throws {
        // Test preconditions
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: [Todo(id: "1", title: "Existing")]))
            .require { state in
                !state.todos.isEmpty // Precondition
            }
            .when(.toggleTodo(id: "1"))
            .then { state in
                state.todos[0].completed == true
            }
        
        try await scenario.execute()
    }
    
    func testClientScenarioAsyncAssertions() async throws {
        // Test async assertions
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .when(.addTodo(Todo(id: "1", title: "Test")))
            .thenAsync { state in
                // Simulate async validation
                try await Task.sleep(for: .milliseconds(10))
                return state.todos.count == 1
            }
        
        try await scenario.execute()
    }
    
    func testClientScenarioStateValidation() async throws {
        // Test intermediate state validation
        let scenario = ClientTestScenario(TodoClient.self)
            .given(TodoState(todos: []))
            .when(.setLoading(true))
            .validate { $0.isLoading == true }
            .when(.addTodo(Todo(id: "1", title: "New")))
            .validate { $0.todos.count == 1 && $0.isLoading == true }
            .when(.setLoading(false))
            .then { $0.isLoading == false && $0.todos.count == 1 }
        
        try await scenario.execute()
    }
}

// MARK: - Expected API Documentation

/*
ClientTestScenario API:

1. Basic usage:
   ClientTestScenario(ClientType.self)
       .given(initialState)
       .when(action)
       .then { state in Bool }

2. Multiple actions:
   .when(action1)
   .when(action2)
   .then { finalState in Bool }

3. State history capture:
   .captureStateHistory()

4. Performance measurement:
   .measureExecutionTime()

5. Timeout configuration:
   .withActionTimeout(.seconds(5))

6. Preconditions:
   .require { state in Bool }

7. Intermediate validation:
   .validate { state in Bool }

8. Async assertions:
   .thenAsync { state in async Bool }
*/