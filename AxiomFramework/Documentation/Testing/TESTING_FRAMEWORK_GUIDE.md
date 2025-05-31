# AxiomTesting Framework Guide

A comprehensive testing framework designed specifically for the Axiom framework, providing mocks, utilities, and patterns for efficient testing of Axiom-based applications.

## Overview

The AxiomTesting framework provides:

- **Complete Mock Implementations** - Ready-to-use mocks for all major Axiom components
- **Test Data Builders** - Convenient builders for creating test data and domain models
- **Testing Utilities** - Helper functions for common testing patterns and assertions
- **Test Environment Management** - Complete test environment setup and teardown
- **XCTest Extensions** - Convenient extensions for common testing scenarios

## Quick Start

### Basic Test Setup

```swift
import XCTest
@testable import Axiom
@testable import AxiomTesting

class MyFeatureTests: XCTestCase {
    private var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        try await super.setUp()
        testEnvironment = await setupAxiomTestEnvironment()
    }
    
    override func tearDown() async throws {
        await tearDownAxiomTestEnvironment(testEnvironment)
        try await super.tearDown()
    }
    
    func testMyFeature() async throws {
        // Your test code here
    }
}
```

### Creating Test Data

```swift
// Domain models
let validUser = TestDomainModelBuilder.user()
let invalidUser = TestDomainModelBuilder.invalidUser()

// Test clients
let userClient = await TestClientBuilder.userClient()
let analyticsClient = await TestClientBuilder.analyticsClient()

// Test DNA
let dna = AxiomTestUtilities.createTestArchitecturalDNA(
    for: ComponentID("MyComponent")
)
```

## Core Components

### 1. TestEnvironment

Complete test environment with all necessary mocks:

```swift
let environment = await AxiomTestUtilities.createTestEnvironment()

// Access individual components
let capabilityManager = environment.capabilityManager
let performanceMonitor = environment.performanceMonitor
let intelligence = environment.intelligence

// Create client dependencies
let dependencies = await environment.createClientDependencies()

// Reset between tests
await environment.reset()
```

### 2. Mock Components

#### MockCapabilityManager

```swift
let mockManager = await MockCapabilityManager(
    availableCapabilities: [.userDefaults, .analytics]
)

// Test capability validation
try await mockManager.validate(.userDefaults) // Success
try await mockManager.validate(.network) // Throws error

// Verify validation history
let history = await mockManager.validationHistory
// [(Capability, Bool)] showing what was validated

// Dynamically add/remove capabilities
await mockManager.addCapability(.network)
await mockManager.removeCapability(.userDefaults)
```

#### MockPerformanceMonitor

```swift
let mockMonitor = await MockPerformanceMonitor()

// Track operations
let token = await mockMonitor.startOperation("my-operation", category: .client)
// ... perform work ...
await mockMonitor.endOperation(token)

// Verify metrics
let metrics = await mockMonitor.getMetrics(for: .client)
XCTAssertEqual(metrics.totalOperations, 1)
XCTAssertGreaterThan(metrics.averageDuration, 0)
```

#### MockAxiomIntelligence

```swift
let mockIntelligence = await MockAxiomIntelligence()

// Configure features
await mockIntelligence.enableFeature(.naturalLanguageQueries)

// Test query processing
let result = try await mockIntelligence.processQuery("test query")
XCTAssertEqual(result.intent, .help)

// Add test data
let dna = AxiomTestUtilities.createTestArchitecturalDNA(for: ComponentID("Test"))
await mockIntelligence.addDNA(dna, for: ComponentID("Test"))

// Verify query history
let queries = await mockIntelligence.processedQueries
```

### 3. Test Data Builders

#### Domain Model Builder

```swift
// Valid user with defaults
let user = TestDomainModelBuilder.user()

// Custom user
let customUser = TestDomainModelBuilder.user(
    id: "custom-id",
    name: "Custom Name", 
    email: "custom@example.com"
)

// Invalid user for validation testing
let invalidUser = TestDomainModelBuilder.invalidUser()
```

#### Client Builder

```swift
// Default clients with mock capability manager
let userClient = await TestClientBuilder.userClient()
let analyticsClient = await TestClientBuilder.analyticsClient()

// Clients with custom capability manager
let customManager = await MockCapabilityManager()
let customClient = await TestClientBuilder.userClient(
    capabilityManager: customManager
)
```

### 4. Testing Utilities

#### Async Assertions

```swift
// Assert operation completes within time limit
let result = try await AxiomTestUtilities.assertCompletes(within: 1.0) {
    return await performSlowOperation()
}

// Wait for async operations
try await AxiomTestUtilities.waitForAsync(timeout: 0.5)
```

#### Domain Model Assertions

```swift
// Assert domain models are equivalent
AxiomTestUtilities.assertEqual(user1, user2)

// Test capability validation
await AxiomTestUtilities.assertCapabilityValidation(
    client: myClient,
    capability: .userDefaults,
    shouldSucceed: true
)
```

#### Architectural DNA Creation

```swift
let dna = AxiomTestUtilities.createTestArchitecturalDNA(
    for: ComponentID("MyComponent"),
    category: .client
)

// DNA has realistic test data
XCTAssertEqual(dna.componentId, ComponentID("MyComponent"))
XCTAssertTrue(dna.requiredCapabilities.contains(.businessLogic))
```

### 5. XCTest Extensions

#### Convenient Test Methods

```swift
class MyTests: XCTestCase {
    
    func testDomainValidation() {
        let valid = TestDomainModelBuilder.user()
        let invalid = TestDomainModelBuilder.invalidUser()
        
        // Tests both valid and invalid cases
        testDomainModelValidation(valid: valid, invalid: invalid)
    }
    
    func testClientOperation() async {
        let client = await TestClientBuilder.userClient()
        
        // Tests that operation succeeds without throwing
        await testClientOperation(client: client) { client in
            let user = TestDomainModelBuilder.user()
            _ = try await client.create(user)
        }
    }
}
```

## Testing Patterns

### 1. Component Testing

```swift
func testUserClientCRUD() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    let dependencies = await environment.createClientDependencies()
    
    // Test creation
    let user = TestDomainModelBuilder.user()
    let created = try await dependencies.userClient.create(user)
    AxiomTestUtilities.assertEqual(user, created)
    
    // Test retrieval
    let found = await dependencies.userClient.find(id: user.id)
    XCTAssertNotNil(found)
    AxiomTestUtilities.assertEqual(user, found!)
    
    // Test update
    let updated = TestDomainModelBuilder.user(id: user.id, name: "Updated Name", email: user.email)
    let result = try await dependencies.userClient.update(updated)
    AxiomTestUtilities.assertEqual(updated, result)
    
    // Test deletion
    try await dependencies.userClient.delete(id: user.id)
    let notFound = await dependencies.userClient.find(id: user.id)
    XCTAssertNil(notFound)
}
```

### 2. Capability Testing

```swift
func testCapabilityDegradation() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    // Remove capability to test degradation
    await environment.capabilityManager.removeCapability(.userDefaults)
    
    let client = await TestClientBuilder.userClient(
        capabilityManager: environment.capabilityManager
    )
    
    // Verify graceful degradation
    await AxiomTestUtilities.assertCapabilityValidation(
        client: client,
        capability: .userDefaults,
        shouldSucceed: false
    )
}
```

### 3. Intelligence Testing

```swift
func testIntelligenceQueryProcessing() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    // Enable features
    await environment.intelligence.enableFeature(.naturalLanguageQueries)
    
    // Test query processing
    let result = try await environment.intelligence.processQuery(
        "What components are in the system?"
    )
    
    XCTAssertEqual(result.intent, .help)
    XCTAssertFalse(result.answer.isEmpty)
    XCTAssertFalse(result.suggestions.isEmpty)
    
    // Verify query was recorded
    let queries = await environment.intelligence.processedQueries
    XCTAssertEqual(queries.count, 1)
}
```

### 4. Performance Testing

```swift
func testPerformanceMonitoring() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    // Start operation
    let token = await environment.performanceMonitor.startOperation(
        "test-operation", 
        category: .client
    )
    
    // Simulate work
    try await AxiomTestUtilities.waitForAsync(timeout: 0.1)
    
    // End operation
    await environment.performanceMonitor.endOperation(token)
    
    // Verify metrics
    let metrics = await environment.performanceMonitor.getMetrics(for: .client)
    XCTAssertEqual(metrics.totalOperations, 1)
    XCTAssertGreaterThan(metrics.averageDuration, 0.05) // At least 50ms
    XCTAssertLessThan(metrics.averageDuration, 0.2)     // Less than 200ms
}
```

### 5. Integration Testing

```swift
func testFullIntegration() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    // Configure environment
    await environment.intelligence.enableFeature(.architecturalDNA)
    await environment.capabilityManager.configure(
        availableCapabilities: [.businessLogic, .userDefaults, .analytics]
    )
    
    // Create dependencies
    let dependencies = await environment.createClientDependencies()
    
    // Test full workflow
    let user = TestDomainModelBuilder.user()
    let created = try await dependencies.userClient.create(user)
    
    // Test intelligence integration
    let dna = AxiomTestUtilities.createTestArchitecturalDNA(
        for: ComponentID("UserClient")
    )
    await environment.intelligence.addDNA(dna, for: ComponentID("UserClient"))
    
    let retrievedDNA = try await environment.intelligence.getArchitecturalDNA(
        for: ComponentID("UserClient")
    )
    XCTAssertNotNil(retrievedDNA)
    
    // Verify all components worked together
    let state = await dependencies.userClient.stateSnapshot
    XCTAssertEqual(state.count, 1)
    XCTAssertNotNil(state[user.id])
}
```

## Best Practices

### 1. Test Environment Management

- Always use `setupAxiomTestEnvironment()` and `tearDownAxiomTestEnvironment()` in test setup/teardown
- Reset the environment between tests to ensure isolation
- Use the environment's capability manager consistently across all clients

### 2. Mock Configuration

- Configure mocks with realistic data that matches your use cases
- Use builders for consistent test data creation
- Verify mock interactions to ensure your code is working correctly

### 3. Async Testing

- Use `AxiomTestUtilities.assertCompletes()` for performance-sensitive operations
- Use `waitForAsync()` when you need to wait for background tasks
- Always handle async errors properly in tests

### 4. Capability Testing

- Test both successful and failed capability validation scenarios
- Use `assertCapabilityValidation()` for consistent capability testing
- Test capability degradation scenarios where applicable

### 5. Domain Model Testing

- Use `testDomainModelValidation()` for consistent validation testing
- Test both valid and invalid domain models
- Use builders to create consistent test data

## Advanced Usage

### Custom Mocks

You can extend the provided mocks or create your own:

```swift
// Extend MockCapabilityManager for specific test scenarios
extension MockCapabilityManager {
    func simulateNetworkFailure() async {
        await removeCapability(.network)
        await removeCapability(.analytics)
    }
}

// Custom test client
actor CustomTestClient: AxiomClient {
    // Your custom implementation
}
```

### Performance Benchmarking

```swift
func testPerformanceBenchmark() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    measure {
        Task {
            for i in 0..<1000 {
                let user = TestDomainModelBuilder.user(id: "user-\(i)")
                try? await dependencies.userClient.create(user)
            }
        }
    }
}
```

### Error Scenario Testing

```swift
func testErrorScenarios() async throws {
    let environment = await AxiomTestUtilities.createTestEnvironment()
    
    // Test different error conditions
    let scenarios: [(String, () async throws -> Void)] = [
        ("No capability", {
            await environment.capabilityManager.removeCapability(.userDefaults)
            let client = await TestClientBuilder.userClient(capabilityManager: environment.capabilityManager)
            let user = TestDomainModelBuilder.user()
            _ = try await client.create(user) // Should throw
        }),
        ("Invalid domain model", {
            let client = await TestClientBuilder.userClient()
            let invalid = TestDomainModelBuilder.invalidUser()
            _ = try await client.create(invalid) // Should throw
        })
    ]
    
    for (description, scenario) in scenarios {
        do {
            try await scenario()
            XCTFail("Expected error for scenario: \(description)")
        } catch {
            // Expected error
        }
    }
}
```

## Migration Guide

If you have existing tests, here's how to migrate them to use the new testing framework:

### Before (Manual Setup)

```swift
func testUserClient() async throws {
    let capabilityManager = CapabilityManager()
    await capabilityManager.configure(availableCapabilities: [.businessLogic, .userDefaults])
    
    let client = TestUserClient(capabilityManager: capabilityManager)
    try await client.initialize()
    
    let user = TestUser(id: "1", name: "Test", email: "test@example.com")
    let created = try await client.create(user)
    
    XCTAssertEqual(created.id, user.id)
    // ... more assertions
}
```

### After (Using Framework)

```swift
func testUserClient() async throws {
    let environment = await setupAxiomTestEnvironment()
    defer { Task { await tearDownAxiomTestEnvironment(environment) } }
    
    let dependencies = await environment.createClientDependencies()
    
    let user = TestDomainModelBuilder.user()
    let created = try await dependencies.userClient.create(user)
    
    AxiomTestUtilities.assertEqual(user, created)
}
```

### Migration Benefits

- **90% less setup code** - Environment creation is one line
- **Consistent test data** - Builders ensure realistic test data
- **Better assertions** - Specialized assertions for domain models and capabilities
- **Automatic cleanup** - Environment management handles cleanup
- **Mock verification** - Built-in verification of mock interactions

## Troubleshooting

### Common Issues

1. **"Mock not configured"** - Ensure you're using the test environment's mocks
2. **"Capability not available"** - Check that your test environment has the required capabilities configured
3. **"Async test hanging"** - Use `assertCompletes()` with appropriate timeouts
4. **"Test isolation issues"** - Ensure you're resetting the environment between tests

### Debug Helpers

```swift
// Print mock state for debugging
let history = await environment.capabilityManager.validationHistory
print("Capability validation history: \(history)")

let queries = await environment.intelligence.processedQueries
print("Processed queries: \(queries)")

let metrics = await environment.performanceMonitor.getOverallMetrics()
print("Performance metrics: \(metrics)")
```

## API Reference

See the source code for complete API documentation. Key classes:

- `TestEnvironment` - Complete test environment
- `MockCapabilityManager` - Mock capability management
- `MockPerformanceMonitor` - Mock performance monitoring  
- `MockAxiomIntelligence` - Mock intelligence system
- `TestDomainModelBuilder` - Domain model builders
- `TestClientBuilder` - Client builders
- `AxiomTestUtilities` - Testing utilities
- `XCTestCase` extensions - Convenient test methods

---

The AxiomTesting framework provides a comprehensive foundation for testing Axiom-based applications with realistic mocks, convenient builders, and powerful utilities that reduce boilerplate while improving test quality and maintainability.