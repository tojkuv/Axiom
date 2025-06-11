import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations tested by these tests. The tests need to be able to refer to the macros
// by name, so we import the module we're testing here.
@testable import AxiomMacros

final class PresentationMacroTests: XCTestCase {
    
    func testPresentationMacroBasicGeneration() throws {
        assertMacroExpansion(
            """
            @Presentation(context: TaskListContext.self)
            struct TaskListView {
                var body: some View {
                    Text("Tasks")
                }
            }
            """,
            expandedSource: """
            struct TaskListView {
                var body: some View {
                    Text("Tasks")
                }
                
                // MARK: - Generated Context
                
                /// The context this presentation observes
                @StateObject private var context: TaskListContext
                
                // MARK: - Generated Initializer
                
                init(context: TaskListContext) {
                    self._context = StateObject(wrappedValue: context)
                }
                
                init() {
                    // Default initializer requires client injection
                    fatalError("Presentation requires context parameter")
                }
            }
            
            extension TaskListView: PresentationProtocol {
                typealias ContextType = TaskListContext
            }
            """,
            macros: testMacros
        )
    }
    
    func testPresentationMacroRejectsMultipleContexts() throws {
        assertMacroExpansion(
            """
            @Presentation(context: TaskListContext.self)
            struct InvalidView {
                @StateObject var anotherContext = UserContext()
                var body: some View {
                    Text("Invalid")
                }
            }
            """,
            expandedSource: """
            struct InvalidView {
                @StateObject var anotherContext = UserContext()
                var body: some View {
                    Text("Invalid")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Presentation views can only have one context", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }
    
    func testPresentationMacroRejectsStatefulPlainViews() throws {
        assertMacroExpansion(
            """
            struct PlainViewWithState: View {
                @State private var items: [String] = []
                var body: some View {
                    List(items, id: \\.self) { Text($0) }
                }
            }
            """,
            expandedSource: """
            struct PlainViewWithState: View {
                @State private var items: [String] = []
                var body: some View {
                    List(items, id: \\.self) { Text($0) }
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Views with @State must use @Presentation macro", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }
    
    func testContextMacroClientBasedInitialization() throws {
        assertMacroExpansion(
            """
            @Context(client: TaskClient.self)
            class TaskListContext {
                func loadTasks() async {
                    await client.process(.loadTasks)
                }
            }
            """,
            expandedSource: """
            class TaskListContext {
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
            
            extension TaskListContext: ObservableObject {}
            
            extension TaskListContext: Context {}
            """,
            macros: testMacros
        )
    }
    
    func testFullPresentationContextPattern() throws {
        // This test validates the complete pattern works together
        assertMacroExpansion(
            """
            @Context(client: TaskClient.self)
            class TaskListContext {
                func selectTask(_ task: Task) async {
                    await client.process(.selectTask(task))
                }
            }
            
            @Presentation(context: TaskListContext.self)
            struct TaskListView {
                var body: some View {
                    List(context.tasks) { task in
                        TaskRow(task: task)
                            .onTap { await context.selectTask(task) }
                    }
                }
            }
            """,
            expandedSource: """
            class TaskListContext {
                func selectTask(_ task: Task) async {
                    await client.process(.selectTask(task))
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
            
            extension TaskListContext: ObservableObject {}
            
            extension TaskListContext: Context {}
            struct TaskListView {
                var body: some View {
                    List(context.tasks) { task in
                        TaskRow(task: task)
                            .onTap { await context.selectTask(task) }
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
                    // Default initializer requires client injection
                    fatalError("Presentation requires context parameter")
                }
            }
            
            extension TaskListView: PresentationProtocol {
                typealias ContextType = TaskListContext
            }
            """,
            macros: testMacros
        )
    }
}

let testMacros: [String: Macro.Type] = [
    "Context": ContextMacro.self,
    "Presentation": PresentationMacro.self,
]