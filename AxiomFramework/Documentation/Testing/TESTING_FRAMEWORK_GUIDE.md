# Testing Framework Guide

Comprehensive testing infrastructure for the Axiom Framework with test-driven development methodologies and quality assurance patterns.

## Overview

The Axiom Framework provides robust testing infrastructure through the `AxiomTesting` module, enabling comprehensive unit testing, integration testing, and performance validation. This guide documents testing patterns, mock utilities, and best practices for maintaining high-quality framework code.

## AxiomTesting Usage

### Basic Setup

```swift
import XCTest
import Axiom
import AxiomTesting

class MyAxiomTests: XCTestCase {
    var mockCapabilityManager: MockCapabilityManager!
    
    override func setUp() {
        super.setUp()
        mockCapabilityManager = AxiomTestUtilities.createMockCapabilityManager()
    }
    
    override func tearDown() {
        super.tearDown()
        Task {
            await mockCapabilityManager.reset()
        }
    }
}
```

### Testing Infrastructure Components

The `AxiomTesting` module provides essential testing utilities:

- **MockCapabilityManager**: Actor-based capability mocking for isolation
- **AxiomTestUtilities**: Convenience methods for test setup
- **AxiomTestSuite**: Basic framework validation testing
- **MemoryTracker**: Performance testing and leak detection
- **WeakObserver**: Observer pattern testing utilities

## Mock Capability Manager

### Creating Mock Managers

```swift
// Create with all capabilities enabled
let fullCapabilityManager = MockCapabilityManager()

// Create with specific capabilities
let limitedCapabilityManager = MockCapabilityManager(
    availableCapabilities: [.analytics, .persistence, .networking]
)

// Create with no capabilities (testing degradation)
let noCapabilityManager = MockCapabilityManager(availableCapabilities: [])
```

### Capability Testing Patterns

```swift
func testCapabilityValidation() async throws {
    let mockManager = AxiomTestUtilities.createMockCapabilityManager(
        with: [.analytics, .persistence]
    )
    
    // Test available capability
    try await mockManager.validate(.analytics)
    
    // Test unavailable capability throws error
    do {
        try await mockManager.validate(.networking)
        XCTFail("Should throw unavailable error")
    } catch CapabilityError.unavailable(let capability) {
        XCTAssertEqual(capability, .networking)
    }
    
    // Verify validation history
    let history = await mockManager.validationHistory
    XCTAssertEqual(history.count, 2)
    XCTAssertEqual(history[0].0, .analytics)
    XCTAssertTrue(history[0].1)  // Available
    XCTAssertEqual(history[1].0, .networking)
    XCTAssertFalse(history[1].1) // Unavailable
}
```

### Dynamic Capability Management

```swift
func testDynamicCapabilityManagement() async throws {
    let mockManager = MockCapabilityManager(availableCapabilities: [])
    
    // Add capability at runtime
    await mockManager.addCapability(.analytics)
    try await mockManager.validate(.analytics) // Now succeeds
    
    // Remove capability at runtime
    await mockManager.removeCapability(.analytics)
    
    do {
        try await mockManager.validate(.analytics)
        XCTFail("Should fail after removal")
    } catch CapabilityError.unavailable {
        // Expected behavior
    }
}
```

## Unit Testing Patterns

### AxiomClient Testing

```swift
actor TestClient: AxiomClient {
    typealias State = TestState
    private(set) var stateSnapshot = TestState()
    let capabilities: CapabilityManager
    
    init(capabilities: CapabilityManager = MockCapabilityManager()) {
        self.capabilities = capabilities
    }
    
    func updateCounter(_ value: Int) async throws {
        try await capabilities.validate(.persistence)
        await updateState { state in
            state.counter = value
        }
    }
}

class AxiomClientTestCase: XCTestCase {
    func testClientStateUpdates() async throws {
        let mockCapabilities = MockCapabilityManager()
        let client = TestClient(capabilities: mockCapabilities)
        
        // Test state update
        try await client.updateCounter(42)
        
        let state = await client.stateSnapshot
        XCTAssertEqual(state.counter, 42)
        
        // Verify capability was validated
        let history = await mockCapabilities.validationHistory
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].0, .persistence)
    }
}
```

### AxiomContext Testing

```swift
@MainActor
class TestContext: AxiomContext {
    let testClient: TestClient
    let intelligence: AxiomIntelligence
    
    @Published var isLoading = false
    
    init(
        testClient: TestClient,
        intelligence: AxiomIntelligence = DefaultAxiomIntelligence()
    ) {
        self.testClient = testClient
        self.intelligence = intelligence
    }
}

@MainActor
class AxiomContextTestCase: XCTestCase {
    func testContextStateBinding() async throws {
        let mockCapabilities = MockCapabilityManager()
        let client = TestClient(capabilities: mockCapabilities)
        let context = TestContext(testClient: client)
        
        // Test context orchestration
        try await client.updateCounter(100)
        
        let state = await client.stateSnapshot
        XCTAssertEqual(state.counter, 100)
        
        // Test loading state management
        context.isLoading = true
        XCTAssertTrue(context.isLoading)
    }
}
```

### AxiomView Testing

```swift
struct TestView: AxiomView {
    @ObservedObject var context: TestContext
    
    var body: some View {
        VStack {
            Text("Counter: \(context.bind(\.counter))")
            Button("Increment") {
                Task {
                    try await context.testClient.updateCounter(
                        context.bind(\.counter) + 1
                    )
                }
            }
        }
    }
}

class AxiomViewTestCase: XCTestCase {
    @MainActor
    func testViewStateBinding() async throws {
        let mockCapabilities = MockCapabilityManager()
        let client = TestClient(capabilities: mockCapabilities)
        let context = TestContext(testClient: client)
        
        // Initial state
        XCTAssertEqual(context.bind(\.counter), 0)
        
        // Update through client
        try await client.updateCounter(5)
        XCTAssertEqual(context.bind(\.counter), 5)
    }
}
```

## Integration Testing

### Full System Integration

```swift
class SystemIntegrationTests: XCTestCase {
    @MainActor
    func testCompleteApplicationFlow() async throws {
        // Setup complete system
        let mockCapabilities = MockCapabilityManager(
            availableCapabilities: Set(Capability.allCases)
        )
        let client = TestClient(capabilities: mockCapabilities)
        let context = TestContext(testClient: client)
        
        // Test capability-dependent operations
        try await client.updateCounter(10)
        
        // Verify state propagation
        XCTAssertEqual(context.bind(\.counter), 10)
        
        // Test capability removal (graceful degradation)
        await mockCapabilities.removeCapability(.persistence)
        
        do {
            try await client.updateCounter(20)
            XCTFail("Should fail without persistence capability")
        } catch CapabilityError.unavailable {
            // Expected graceful degradation
            XCTAssertEqual(context.bind(\.counter), 10) // Unchanged
        }
    }
}
```

### Cross-Domain Coordination Testing

```swift
class CrossDomainTests: XCTestCase {
    @MainActor
    func testMultipleDomainCoordination() async throws {
        let mockCapabilities = MockCapabilityManager()
        
        let userClient = UserClient(capabilities: mockCapabilities)
        let dataClient = DataClient(capabilities: mockCapabilities)
        
        let coordinatorContext = CoordinatorContext(
            userClient: userClient,
            dataClient: dataClient
        )
        
        // Test cross-domain operations
        try await userClient.setUser("TestUser")
        try await dataClient.saveData("TestData")
        
        // Verify coordination through context
        XCTAssertEqual(coordinatorContext.bind(\.username), "TestUser")
        XCTAssertEqual(coordinatorContext.bind(\.lastSavedData), "TestData")
    }
}
```

## Performance Testing

### Memory Efficiency Testing

```swift
class PerformanceTests: XCTestCase {
    func testMemoryEfficiency() throws {
        let startMemory = MemoryTracker.currentUsage()
        
        // Create multiple instances
        let contexts = (0..<100).map { _ in
            TestContext(
                testClient: TestClient(),
                intelligence: DefaultAxiomIntelligence()
            )
        }
        
        let endMemory = MemoryTracker.currentUsage()
        let memoryPerContext = (endMemory - startMemory) / 100
        
        // Verify memory usage is reasonable
        XCTAssertLessThan(memoryPerContext, 50_000) // < 50KB per context
        
        _ = contexts // Keep alive for measurement
    }
    
    func testStateAccessPerformance() async throws {
        let client = TestClient()
        let iterations = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            try await client.updateCounter(i)
            _ = await client.stateSnapshot
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timePerOperation = (endTime - startTime) / Double(iterations)
        
        // Verify performance targets
        XCTAssertLessThan(timePerOperation, 0.001) // < 1ms per operation
    }
}
```

### Intelligence Query Performance

```swift
class IntelligencePerformanceTests: XCTestCase {
    func testIntelligenceQueryPerformance() async throws {
        let intelligence = DefaultAxiomIntelligence()
        let queryCount = 100
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<queryCount {
            let components = await intelligence.discoverComponents()
            XCTAssertGreaterThan(components.count, 0)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timePerQuery = (endTime - startTime) / Double(queryCount)
        
        // Verify <100ms intelligence query target
        XCTAssertLessThan(timePerQuery, 0.1) // < 100ms per query
    }
}
```

## Test Data Management

### State Structures for Testing

```swift
struct TestState: Equatable, Sendable {
    var counter: Int = 0
    var username: String = ""
    var isActive: Bool = false
    var timestamp: Date = Date()
}

struct TestUser: Equatable, Sendable {
    let id: String
    let name: String
    let email: String
}

struct TestDataModel: Equatable, Sendable {
    var users: [TestUser] = []
    var settings: [String: String] = [:]
    var metrics: [String: Double] = [:]
}
```

### Test Utilities and Helpers

```swift
extension AxiomTestUtilities {
    static func createTestState(
        counter: Int = 0,
        username: String = "TestUser",
        isActive: Bool = true
    ) -> TestState {
        TestState(
            counter: counter,
            username: username,
            isActive: isActive,
            timestamp: Date()
        )
    }
    
    static func createTestUser(
        id: String = "test-id",
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> TestUser {
        TestUser(id: id, name: name, email: email)
    }
}
```

## Best Practices

### Test Organization

1. **Test Structure**: Use descriptive test names that explain what is being tested
2. **Setup/Teardown**: Always reset mock state between tests
3. **Isolation**: Each test should be independent and not rely on other tests
4. **Async Testing**: Use proper async/await patterns for actor-based testing

### Capability Testing

1. **Test All Scenarios**: Available, unavailable, and graceful degradation
2. **Mock Isolation**: Use MockCapabilityManager for predictable testing
3. **History Validation**: Verify capability validation calls and timing
4. **Error Handling**: Test proper error propagation and recovery

### Performance Validation

1. **Baseline Measurements**: Establish performance baselines for regression detection
2. **Statistical Significance**: Run multiple iterations for reliable measurements
3. **Memory Tracking**: Monitor memory usage and detect leaks
4. **Real-World Scenarios**: Test performance under realistic usage patterns

### Integration Testing

1. **End-to-End Flows**: Test complete user workflows
2. **Cross-Domain Coordination**: Verify proper context orchestration
3. **State Consistency**: Ensure state remains consistent across components
4. **Error Recovery**: Test system behavior under failure conditions

## Continuous Integration

### Test Execution

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter AxiomClientTests

# Run with coverage (requires additional tooling)
swift test --enable-code-coverage
```

### Quality Gates

- **Test Coverage**: Maintain >95% test coverage
- **Performance Regression**: <10% performance degradation tolerance
- **Memory Efficiency**: <15MB baseline memory usage
- **Zero Test Failures**: All tests must pass before integration

The testing framework ensures high-quality framework development through comprehensive validation, performance monitoring, and quality assurance patterns that support the framework's architectural constraints and enterprise-grade requirements.