import XCTest
import AxiomTesting
@testable import Axiom

final class EnhancedContextMacroTests: XCTestCase {
    
    // Test 1: Verify enhanced @Context macro generates complete context implementation
    func testEnhancedContextMacroGeneratesCompleteImplementation() async throws {
        // Create a context using enhanced @Context macro
        @Context(client: TaskClient.self)
        struct TaskListContext {
            func loadTasks() async {
                await client.process(.loadTasks)
            }
            
            func addTask(_ task: MockTask) async {
                await client.process(.addTask(task))
            }
        }
        
        // Verify generated implementation
        let client = MockTaskClient()
        let context = TaskListContext(client: client)
        
        // Test generated @Published properties
        XCTAssertNotNil(context.tasks)
        XCTAssertNotNil(context.isLoading)
        XCTAssertNotNil(context.error)
        
        // Test lifecycle methods exist
        await context.viewAppeared()
        XCTAssertTrue(context.isActive)
        
        await context.viewDisappeared()
        XCTAssertFalse(context.isActive)
    }
    
    // Test 2: Verify automatic client observation setup
    func testAutomaticClientObservation() async throws {
        @Context(client: TaskClient.self, observes: [\EnhancedMacroTaskState.tasks, \EnhancedMacroTaskState.isLoading])
        struct ObservingContext {
            // No manual observation setup needed
        }
        
        let client = MockTaskClient()
        let context = ObservingContext(client: client)
        
        // Start observation
        await context.viewAppeared()
        
        // Update client state
        await client.updateState { state in
            state.tasks = [MockTask(title: "Test Task")]
            state.isLoading = false
        }
        
        // Verify context reflects client state automatically
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(context.tasks.count, 1)
        XCTAssertEqual(context.tasks.first?.title, "Test Task")
        XCTAssertFalse(context.isLoading)
    }
    
    // Test 3: Verify error boundary integration
    func testErrorBoundaryIntegration() async throws {
        @Context(client: TaskClient.self, errorHandling: .automatic)
        struct ErrorHandlingContext {
            func triggerError() async {
                await client.process(.failingAction)
            }
        }
        
        let client = MockTaskClient()
        let context = ErrorHandlingContext(client: client)
        
        await context.viewAppeared()
        await context.triggerError()
        
        // Verify error is captured and exposed
        XCTAssertNotNil(context.error)
        XCTAssertTrue(context.error is TaskError)
    }
    
    // Test 4: Verify SwiftUI ObservableObject conformance
    func testSwiftUIIntegration() async throws {
        @Context(client: TaskClient.self)
        struct SwiftUIContext {
            // Should automatically conform to ObservableObject
        }
        
        let client = MockTaskClient()
        let context = SwiftUIContext(client: client)
        
        // Verify ObservableObject conformance
        XCTAssertTrue(context is ObservableObject)
        
        // Test objectWillChange publisher
        var updateCount = 0
        let cancellable = context.objectWillChange.sink { _ in
            updateCount += 1
        }
        
        // Trigger state change
        await client.updateState { $0.tasks.append(MockTask(title: "New")) }
        try await Task.sleep(for: .milliseconds(50))
        
        XCTAssertGreaterThan(updateCount, 0)
        cancellable.cancel()
    }
    
    // Test 5: Verify code reduction metrics
    func testCodeReductionMetrics() {
        // Measure lines of code for macro-based context
        let macroBasedLines = """
        @Context(client: TaskClient.self)
        struct TaskListContext {
            func loadTasks() async {
                await client.process(.loadTasks)
            }
            
            func addTask(_ task: MockTask) async {
                await client.process(.addTask(task))
            }
        }
        """.split(separator: "\n").count
        
        // Compare to manual implementation (47 lines in requirement)
        let manualImplementationLines = 47
        
        let reduction = Double(manualImplementationLines - macroBasedLines) / Double(manualImplementationLines) * 100
        
        XCTAssertEqual(macroBasedLines, 8, "Macro-based context should be 8 lines")
        XCTAssertGreaterThanOrEqual(reduction, 83.0, "Should achieve at least 83% reduction")
    }
}

// Mock implementations for testing
struct MockTask {
    let title: String
}

enum TaskAction {
    case loadTasks
    case addTask(MockTask)
    case failingAction
}

struct EnhancedMacroTaskState {
    var tasks: [MockTask] = []
    var isLoading = false
    var error: Error?
}

struct TaskError: Error {}

actor MockTaskClient: Client {
    typealias StateType = EnhancedMacroTaskState
    typealias ActionType = TaskAction
    
    private var state = EnhancedMacroTaskState()
    private var continuation: AsyncStream<EnhancedMacroTaskState>.Continuation?
    
    var stateStream: AsyncStream<EnhancedMacroTaskState> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(state)
        }
    }
    
    func process(_ action: TaskAction) async {
        switch action {
        case .loadTasks:
            state.isLoading = true
            continuation?.yield(state)
            try? await Task.sleep(for: .milliseconds(100))
            state.isLoading = false
            continuation?.yield(state)
            
        case .addTask(let task):
            state.tasks.append(task)
            continuation?.yield(state)
            
        case .failingAction:
            state.error = TaskError()
            continuation?.yield(state)
        }
    }
    
    func updateState(_ block: (inout EnhancedMacroTaskState) -> Void) async {
        block(&state)
        continuation?.yield(state)
    }
}