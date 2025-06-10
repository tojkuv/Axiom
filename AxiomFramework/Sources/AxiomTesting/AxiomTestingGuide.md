# Axiom Testing Framework Guide

A comprehensive testing suite that makes it easy for applications using Axiom to test all aspects of their implementation.

## Overview

The Axiom Testing Framework provides a complete set of utilities for testing:

- **Context State & Actions** - Test context lifecycle, state management, and action processing
- **Navigation Flows** - Test routes, navigation flows, and deep links  
- **SwiftUI Integration** - Test view-context binding, interactions, and presentation layer
- **Performance & Memory** - Benchmark performance and detect memory leaks
- **Async Operations** - Test async patterns, debouncing, and streams
- **Form Validation** - Test form binding, validation, and submission flows

## Quick Start

```swift
import XCTest
@testable import Axiom
@testable import AxiomTesting

class MyAppTests: XCTestCase {
    
    func testContextBasics() async throws {
        let context = MyTaskContext()
        
        // Test context state
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { ctx in ctx.tasks.isEmpty },
            description: "Initial state should be empty"
        )
        
        // Test action processing
        await context.process(.addTask("Test Task"))
        
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { ctx in ctx.tasks.count == 1 },
            description: "Should have one task after adding"
        )
    }
}
```

## Core Testing Utilities

### ContextTestHelpers

Test context state, actions, lifecycle, and dependencies.

```swift
// State testing
try await ContextTestHelpers.assertState(
    in: context,
    condition: { state in state.isLoading == false },
    description: "Loading should be complete"
)

// Action sequence testing  
try await ContextTestHelpers.assertActionSequence(
    in: context,
    actions: [.load, .process, .save],
    expectedStates: [
        { ctx in ctx.isLoading },
        { ctx in ctx.isProcessing },
        { ctx in ctx.isSaved }
    ]
)

// Memory leak detection
try await ContextTestHelpers.assertNoMemoryLeaks {
    let context = MyContext()
    await context.onAppear()
    // Use context...
    await context.onDisappear()
    // Context should be deallocated
}
```

### NavigationTestHelpers

Test routes, navigation flows, and deep links.

```swift
// Route testing
try NavigationTestHelpers.assertRoute(
    TaskRoute.detail(id: "123"),
    hasPath: "/tasks/123",
    hasParameters: ["mode": "view"],
    description: "Task detail route should be correctly formed"
)

// Navigation flow testing
try await NavigationTestHelpers.assertNavigationFlow(
    using: navigator,
    sequence: [
        .navigate(to: TaskRoute.list),
        .navigate(to: TaskRoute.detail(id: "123")),
        .goBack()
    ],
    expectedStack: [TaskRoute.list]
)

// Deep link testing
let route = try await NavigationTestHelpers.assertDeepLinkHandling(
    url: URL(string: "myapp://tasks/123")!,
    handler: deepLinkHandler,
    expectedRoute: TaskRoute.detail(id: "123")
)
```

### SwiftUITestHelpers

Test SwiftUI views with context integration.

```swift
// View-context binding
let context = MyContext()
let view = MyView().environmentObject(context)
let testHost = try await SwiftUITestHelpers.createTestHost(for: view)

try await SwiftUITestHelpers.assertContextBinding(
    in: testHost,
    contextType: MyContext.self,
    matches: context
)

// User interaction simulation
try await SwiftUITestHelpers.simulateTap(
    in: testHost,
    on: .button(withText: "Save")
)

try await SwiftUITestHelpers.assertContextAction(
    in: context,
    wasTriggered: .save,
    timeout: .seconds(1)
)

// Animation testing
try await SwiftUITestHelpers.assertAnimation(
    in: testHost,
    type: .slideIn,
    onView: .listRow(containing: "New Item"),
    duration: .milliseconds(300)
)
```

### PerformanceTestHelpers

Benchmark performance and detect memory issues.

```swift
// Performance benchmarking
let benchmark = try await PerformanceTestHelpers.benchmark {
    for i in 0..<1000 {
        await context.process(.update(i))
    }
}

XCTAssertLessThan(benchmark.averageDuration, .milliseconds(10))

// Load testing
try await PerformanceTestHelpers.assertLoadTestRequirements(
    concurrency: 10,
    duration: .seconds(30),
    minThroughput: 100, // ops/sec
    maxErrorRate: 0.01, // 1%
    operation: {
        await someAsyncOperation()
    }
)

// Memory bounds testing
try await PerformanceTestHelpers.assertMemoryBounds(
    during: heavyOperation,
    maxGrowth: 10 * 1024 * 1024, // 10MB
    maxPeak: 100 * 1024 * 1024   // 100MB
)
```

### AsyncTestHelpers

Test async operations, streams, and timing.

```swift
// State stream testing
let states = try await AsyncTestHelpers.collectStates(
    from: client,
    count: 3,
    timeout: .seconds(5)
) {
    await client.process(.start)
    await client.process(.update)
    await client.process(.finish)
}

// Debouncing testing
let result = try await DebouncingTestHelpers.assertDebouncing(
    debounceDuration: .milliseconds(500),
    operation: { return "test" },
    rapidCallCount: 10,
    rapidCallInterval: .milliseconds(50)
)

// Stream error handling
try await AsyncStreamTestHelpers.assertStreamErrorHandling(
    stream: errorProneStream,
    expectedError: MyError.networkFailure,
    beforeErrorCount: 5
)
```

### FormTestHelpers

Test form validation, binding, and submission.

```swift
// Form validation flow
try await AdvancedFormTestHelpers.assertFormValidationFlow(
    form: myForm,
    validInputs: ["email": "test@example.com", "name": "John"],
    invalidInputs: ["email": "invalid", "name": ""],
    expectedErrors: ["email": "Invalid format", "name": "Required"]
)

// Binding performance
try await FormBindingTestHelpers.assertBindingPerformance(
    binding: $viewModel.text,
    values: Array(0..<1000).map { "Text \($0)" },
    maxUpdateTime: .milliseconds(100)
)

// Validation rules
FormValidationTestHelpers.assertValidationRule(
    rule: EmailValidationRule(),
    validCases: ["test@example.com", "user@domain.org"],
    invalidCases: ["invalid", "@example.com", "test@"]
)
```

## Testing Patterns

### Context Testing Pattern

```swift
class TaskContextTests: XCTestCase {
    var context: TaskContext!
    
    override func setUp() async throws {
        context = TaskContext()
        await context.onAppear()
    }
    
    override func tearDown() async throws {
        await context.onDisappear()
        context = nil
    }
    
    func testTaskLifecycle() async throws {
        // Test initial state
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { $0.tasks.isEmpty }
        )
        
        // Test adding task
        await context.process(.addTask("Test Task"))
        
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { $0.tasks.count == 1 }
        )
        
        // Test completing task
        await context.process(.completeTask(0))
        
        try await ContextTestHelpers.assertState(
            in: context,
            condition: { $0.tasks[0].isCompleted }
        )
    }
    
    func testMemoryManagement() async throws {
        try await ContextTestHelpers.assertNoMemoryLeaks {
            let tempContext = TaskContext()
            await tempContext.onAppear()
            
            // Heavy usage
            for i in 0..<1000 {
                await tempContext.process(.addTask("Task \(i)"))
            }
            
            await tempContext.onDisappear()
        }
    }
}
```

### Navigation Testing Pattern

```swift
class NavigationTests: XCTestCase {
    var navigator: TestNavigationService!
    
    override func setUp() {
        navigator = TestNavigationService()
    }
    
    func testUserFlow() async throws {
        // Test typical user navigation flow
        try await NavigationTestHelpers.assertNavigationFlow(
            using: navigator,
            sequence: [
                .navigate(to: HomeRoute.dashboard),
                .navigate(to: TaskRoute.list),
                .navigate(to: TaskRoute.detail(id: "123")),
                .navigate(to: TaskRoute.edit(id: "123")),
                .goBack(), // Back to detail
                .goBack(), // Back to list
                .goBack()  // Back to dashboard
            ],
            expectedStack: [HomeRoute.dashboard]
        )
    }
    
    func testDeepLinking() async throws {
        let deepLink = URL(string: "myapp://tasks/123/edit")!
        
        try await NavigationTestHelpers.assertDeepLinkRestoration(
            url: deepLink,
            handler: deepLinkHandler,
            navigator: navigator,
            expectedStack: [
                HomeRoute.dashboard,
                TaskRoute.list,
                TaskRoute.detail(id: "123"),
                TaskRoute.edit(id: "123")
            ]
        )
    }
}
```

### Performance Testing Pattern

```swift
class PerformanceTests: XCTestCase {
    
    func testContextPerformance() async throws {
        let context = TaskContext()
        
        // Test context can handle high load
        let results = try await PerformanceTestHelpers.testContextPerformance(
            context: context,
            actionCount: 10000,
            concurrentClients: 10
        )
        
        XCTAssertGreaterThan(results.throughput, 1000) // 1000 actions/sec
        XCTAssertLessThan(results.averageActionDuration, .milliseconds(1))
        XCTAssertLessThan(results.memoryGrowth, 50 * 1024 * 1024) // 50MB
    }
    
    func testViewPerformance() async throws {
        let context = TaskListContext()
        let view = TaskListView().environmentObject(context)
        
        let benchmark = try await SwiftUITestHelpers.benchmarkView(view) {
            // Simulate heavy UI updates
            for i in 0..<1000 {
                await context.addTask("Task \(i)")
            }
        }
        
        XCTAssertLessThan(benchmark.averageRenderTime, 16.67) // 60 FPS
        XCTAssertLessThan(benchmark.memoryGrowth, 10 * 1024 * 1024) // 10MB
    }
}
```

## Integration with XCTest

### Custom Assertions

```swift
extension XCTestCase {
    
    func assertEventually<T>(
        _ expression: @autoclosure () async throws -> T,
        equals expected: T,
        timeout: Duration = .seconds(1),
        file: StaticString = #file,
        line: UInt = #line
    ) async throws where T: Equatable {
        try await TimingHelpers.eventually(within: timeout) {
            let actual = try await expression()
            XCTAssertEqual(actual, expected, file: file, line: line)
        }
    }
    
    func measureAsyncPerformance<T>(
        _ operation: () async throws -> T
    ) async throws -> T {
        return try await measureDetailedPerformance(operation)
    }
}
```

### Test Utilities

```swift
class TestableTaskContext: TaskContext {
    private(set) var processedActions: [Action] = []
    
    override func process(_ action: Action) async {
        processedActions.append(action)
        await super.process(action)
    }
    
    func assertActionWasProcessed(_ action: Action) {
        XCTAssertTrue(processedActions.contains(action))
    }
}
```

## Best Practices

### 1. Test Organization

```swift
// Group related tests
class TaskContextStateTests: XCTestCase { }
class TaskContextActionTests: XCTestCase { }
class TaskContextLifecycleTests: XCTestCase { }

// Use descriptive test names
func testAddingTaskUpdatesStateCorrectly() async throws { }
func testDeletingNonExistentTaskThrowsError() async throws { }
func testContextMemoryIsReleasedAfterDisappear() async throws { }
```

### 2. Setup and Teardown

```swift
class ObservableContextTests: XCTestCase {
    var context: TestableContext!
    
    override func setUp() async throws {
        context = TestableContext()
        await context.onAppear()
    }
    
    override func tearDown() async throws {
        await context.onDisappear()
        context = nil
    }
}
```

### 3. Mock and Test Doubles

```swift
class MockTaskService: TaskService {
    var shouldFail = false
    private(set) var calledMethods: [String] = []
    
    func loadTasks() async throws -> [Task] {
        calledMethods.append("loadTasks")
        if shouldFail {
            throw TaskError.networkFailure
        }
        return [Task(id: "1", title: "Test Task")]
    }
}
```

### 4. Error Testing

```swift
func testNetworkErrorHandling() async throws {
    let mockService = MockTaskService()
    mockService.shouldFail = true
    
    let context = TaskContext(service: mockService)
    
    await context.process(.loadTasks)
    
    try await ContextTestHelpers.assertState(
        in: context,
        condition: { $0.error != nil },
        description: "Should set error state on failure"
    )
}
```

### 5. Performance Constraints

```swift
func testPerformanceRequirements() async throws {
    // Define clear performance requirements
    try await PerformanceTestHelpers.assertPerformanceRequirements(
        operation: heavyComputation,
        maxDuration: .seconds(2),      // Must complete in 2 seconds
        maxMemoryGrowth: 5 * 1024 * 1024, // Max 5MB growth
        iterations: 10
    )
}
```

## Common Testing Scenarios

### Testing Context Hierarchies

```swift
func testParentChildContextCommunication() async throws {
    let parentContext = TaskListContext()
    let childContext = TaskDetailContext()
    
    try await ContextTestHelpers.establishParentChild(
        parent: parentContext,
        child: childContext
    )
    
    await childContext.process(.deleteTask)
    
    try await ContextTestHelpers.assertChildActionReceived(
        by: parentContext,
        action: TaskDetailContext.Action.deleteTask,
        from: childContext
    )
}
```

### Testing Async Operations

```swift
func testAsyncDataLoading() async throws {
    let context = TaskContext()
    
    // Start loading
    await context.process(.loadTasks)
    
    // Verify loading state
    try await ContextTestHelpers.assertState(
        in: context,
        condition: { $0.isLoading },
        description: "Should be in loading state"
    )
    
    // Wait for completion
    try await ContextTestHelpers.assertState(
        in: context,
        condition: { !$0.isLoading && !$0.tasks.isEmpty },
        description: "Should complete loading with data"
    )
}
```

### Testing Form Validation

```swift
func testFormValidation() async throws {
    let form = TaskForm()
    
    try await AdvancedFormTestHelpers.assertFormValidationFlow(
        form: form,
        validInputs: [
            "title": "Valid Task Title",
            "description": "Valid description",
            "priority": "high"
        ],
        invalidInputs: [
            "title": "",
            "description": String(repeating: "x", count: 1001), // Too long
            "priority": "invalid"
        ],
        expectedErrors: [
            "title": "Title is required",
            "description": "Description too long",
            "priority": "Invalid priority value"
        ]
    )
}
```

## Troubleshooting

### Common Issues

1. **Memory Leaks in Tests**
   ```swift
   // Always use weak references in test observers
   weak var weakContext = context
   // Check deallocation
   XCTAssertNil(weakContext)
   ```

2. **Async Test Timeouts**
   ```swift
   // Use appropriate timeouts for operations
   try await ContextTestHelpers.assertState(
       in: context,
       timeout: .seconds(10), // Increase if needed
       condition: { $0.isReady }
   )
   ```

3. **Flaky UI Tests**
   ```swift
   // Always wait for UI updates
   try await SwiftUITestHelpers.assertViewState(
       in: testHost,
       condition: { $0.contains(text: "Expected Text") },
       timeout: .seconds(2)
   )
   ```

### Performance Tips

1. **Batch Test Operations**
   ```swift
   // Instead of many small tests, batch related operations
   func testCompleteUserFlow() async throws {
       // Test entire flow in one test for better performance
   }
   ```

2. **Use Appropriate Timeouts**
   ```swift
   // Don't use unnecessarily long timeouts
   try await assertEventually(timeout: .milliseconds(100)) {
       // Fast operations
   }
   ```

3. **Clean Up Resources**
   ```swift
   override func tearDown() async throws {
       // Always clean up contexts, observers, etc.
       await context.onDisappear()
       cancellables.forEach { $0.cancel() }
   }
   ```

## Migration Guide

### From Manual Testing

Before:
```swift
func testTaskContext() async throws {
    let context = TaskContext()
    await context.process(.addTask("Test"))
    
    // Manual state checking
    XCTAssertEqual(context.tasks.count, 1)
    XCTAssertEqual(context.tasks[0].title, "Test")
}
```

After:
```swift
func testTaskContext() async throws {
    let context = TaskContext()
    
    // Use helper utilities
    try await ContextTestHelpers.assertActionSequence(
        in: context,
        actions: [.addTask("Test")],
        expectedStates: [
            { $0.tasks.count == 1 && $0.tasks[0].title == "Test" }
        ]
    )
}
```

This comprehensive testing framework provides everything needed to thoroughly test Axiom-based applications with minimal boilerplate and maximum confidence.