import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests that demonstrate and validate the enhanced AxiomTesting framework
final class AxiomTestingFrameworkTests: XCTestCase {
    
    // MARK: Test Environment Tests
    
    func testTestEnvironmentCreation() async throws {
        // Test that the test environment creates all necessary components
        let environment = await AxiomTestUtilities.createTestEnvironment()
        
        // Verify all components are created
        XCTAssertNotNil(environment.capabilityManager)
        XCTAssertNotNil(environment.performanceMonitor)
        XCTAssertNotNil(environment.intelligence)
        
        // Test environment reset
        await environment.reset()
        
        // Verify reset worked
        let metrics = await environment.performanceMonitor.getOverallMetrics()
        XCTAssertEqual(metrics.totalOperations, 0)
        
        let intelligenceMetrics = await environment.intelligence.getMetrics()
        XCTAssertEqual(intelligenceMetrics.totalOperations, 0)
    }
    
    func testTestEnvironmentClientDependencies() async throws {
        let environment = await AxiomTestUtilities.createTestEnvironment()
        
        // Test creating client dependencies
        let dependencies = await environment.createClientDependencies()
        
        XCTAssertNotNil(dependencies.userClient)
        XCTAssertNotNil(dependencies.analyticsClient)
        
        // Test that clients are properly initialized
        let userState = await dependencies.userClient.stateSnapshot
        XCTAssertTrue(userState.isEmpty)
        
        let analyticsState = await dependencies.analyticsClient.stateSnapshot
        XCTAssertTrue(analyticsState.isEmpty)
    }
    
    // MARK: Mock Component Tests
    
    func testMockCapabilityManager() async throws {
        let mockManager = await MockCapabilityManager(availableCapabilities: [.userDefaults, .analytics])
        
        // Test successful validation
        try await mockManager.validate(.userDefaults)
        
        // Test failed validation
        do {
            try await mockManager.validate(.network)
            XCTFail("Should have thrown capability error")
        } catch CapabilityError.unavailable(let capability) {
            XCTAssertEqual(capability, .network)
        }
        
        // Test validation history tracking
        let history = await mockManager.validationHistory
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].0, .userDefaults)
        XCTAssertTrue(history[0].1)
        XCTAssertEqual(history[1].0, .network)
        XCTAssertFalse(history[1].1)
        
        // Test adding/removing capabilities
        await mockManager.addCapability(.network)
        try await mockManager.validate(.network) // Should succeed now
        
        await mockManager.removeCapability(.userDefaults)
        do {
            try await mockManager.validate(.userDefaults)
            XCTFail("Should have thrown capability error")
        } catch CapabilityError.unavailable {
            // Expected
        }
    }
    
    func testMockPerformanceMonitor() async throws {
        let mockMonitor = await MockPerformanceMonitor()
        
        // Test operation tracking
        let token = await mockMonitor.startOperation("test-operation", category: .intelligence)
        
        // Simulate some work
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await mockMonitor.endOperation(token)
        
        // Verify metrics
        let metrics = await mockMonitor.getMetrics(for: .intelligence)
        XCTAssertEqual(metrics.totalOperations, 1)
        XCTAssertGreaterThan(metrics.averageDuration, 0)
        XCTAssertGreaterThan(metrics.maxDuration, 0)
        
        // Test overall metrics
        let overallMetrics = await mockMonitor.getOverallMetrics()
        XCTAssertEqual(overallMetrics.totalOperations, 1)
        XCTAssertEqual(overallMetrics.activeOperations, 0)
    }
    
    func testMockAxiomIntelligence() async throws {
        let mockIntelligence = await MockAxiomIntelligence()
        
        // Test feature management
        await mockIntelligence.enableFeature(.naturalLanguageQueries)
        let features = await mockIntelligence.enabledFeatures
        XCTAssertTrue(features.contains(.naturalLanguageQueries))
        XCTAssertTrue(features.contains(.architecturalDNA)) // Dependency should be enabled
        
        // Test query processing
        let result = try await mockIntelligence.processQuery("test query")
        XCTAssertEqual(result.query, "test query")
        XCTAssertEqual(result.intent, .help)
        XCTAssertTrue(result.answer.contains("test query"))
        
        // Test query history
        let queries = await mockIntelligence.processedQueries
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries[0], "test query")
        
        // Test feature disabled error
        await mockIntelligence.disableFeature(.naturalLanguageQueries)
        do {
            _ = try await mockIntelligence.processQuery("another query")
            XCTFail("Should have thrown feature not enabled error")
        } catch IntelligenceError.featureNotEnabled(let feature) {
            XCTAssertEqual(feature, .naturalLanguageQueries)
        }
    }
    
    // MARK: Test Data Builder Tests
    
    func testTestDomainModelBuilder() {
        // Test valid user creation
        let validUser = TestDomainModelBuilder.user()
        XCTAssertEqual(validUser.id, "test-user-1")
        XCTAssertEqual(validUser.name, "Test User")
        XCTAssertEqual(validUser.email, "test@example.com")
        
        let validation = validUser.validate()
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        
        // Test invalid user creation
        let invalidUser = TestDomainModelBuilder.invalidUser()
        let invalidValidation = invalidUser.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.errors.isEmpty)
        XCTAssertEqual(invalidValidation.errors.count, 2)
        
        // Test custom user creation
        let customUser = TestDomainModelBuilder.user(
            id: "custom-id",
            name: "Custom User",
            email: "custom@test.com"
        )
        XCTAssertEqual(customUser.id, "custom-id")
        XCTAssertEqual(customUser.name, "Custom User")
        XCTAssertEqual(customUser.email, "custom@test.com")
    }
    
    func testTestClientBuilder() async throws {
        // Test user client creation with default capability manager
        let userClient = await TestClientBuilder.userClient()
        
        // Verify client is initialized
        let state = await userClient.stateSnapshot
        XCTAssertTrue(state.isEmpty)
        
        // Test client creation with custom capability manager
        let customCapabilityManager = await MockCapabilityManager(availableCapabilities: [.businessLogic, .userDefaults])
        let customUserClient = await TestClientBuilder.userClient(capabilityManager: customCapabilityManager)
        
        // Test analytics client creation
        let analyticsClient = await TestClientBuilder.analyticsClient()
        let analyticsState = await analyticsClient.stateSnapshot
        XCTAssertTrue(analyticsState.isEmpty)
    }
    
    // MARK: Testing Utility Tests
    
    func testAxiomTestUtilities() async throws {
        // Test async completion assertion
        let result = try await AxiomTestUtilities.assertCompletes(within: 0.5) {
            // Fast operation
            return "completed"
        }
        XCTAssertEqual(result, "completed")
        
        // Test domain model equality assertion
        let user1 = TestDomainModelBuilder.user(id: "same", name: "Same User", email: "same@example.com")
        let user2 = TestDomainModelBuilder.user(id: "same", name: "Same User", email: "same@example.com")
        
        AxiomTestUtilities.assertEqual(user1, user2)
        
        // Test architectural DNA creation
        let componentID = ComponentID("TestComponent")
        let dna = AxiomTestUtilities.createTestArchitecturalDNA(for: componentID)
        
        XCTAssertEqual(dna.componentId, componentID)
        XCTAssertEqual(dna.purpose.description, "Test component for TestComponent")
        XCTAssertTrue(dna.requiredCapabilities.contains(.businessLogic))
        XCTAssertTrue(dna.providedCapabilities.contains(.stateManagement))
        
        // Test DNA validation
        let validationResult = try await dna.validateArchitecturalIntegrity()
        XCTAssertTrue(validationResult.isValid)
        XCTAssertEqual(validationResult.score, 1.0)
    }
    
    func testCapabilityValidationAssertion() async {
        let environment = await AxiomTestUtilities.createTestEnvironment()
        let dependencies = await environment.createClientDependencies()
        
        // Test successful capability validation
        await AxiomTestUtilities.assertCapabilityValidation(
            client: dependencies.userClient,
            capability: .businessLogic,
            shouldSucceed: true
        )
        
        // Remove capability and test failure
        await environment.capabilityManager.removeCapability(.userDefaults)
        await AxiomTestUtilities.assertCapabilityValidation(
            client: dependencies.userClient,
            capability: .userDefaults,
            shouldSucceed: false
        )
    }
    
    // MARK: XCTest Extension Tests
    
    func testXCTestExtensions() async throws {
        // Test setup and teardown
        let environment = await setupAxiomTestEnvironment()
        
        XCTAssertNotNil(environment.capabilityManager)
        XCTAssertNotNil(environment.performanceMonitor)
        XCTAssertNotNil(environment.intelligence)
        
        await tearDownAxiomTestEnvironment(environment)
        
        // Verify teardown
        let metrics = await environment.intelligence.getMetrics()
        XCTAssertEqual(metrics.totalOperations, 0)
    }
    
    func testDomainModelValidationExtension() {
        let validUser = TestDomainModelBuilder.user()
        let invalidUser = TestDomainModelBuilder.invalidUser()
        
        testDomainModelValidation(valid: validUser, invalid: invalidUser)
    }
    
    func testClientOperationExtension() async {
        let environment = await setupAxiomTestEnvironment()
        let dependencies = await environment.createClientDependencies()
        
        await testClientOperation(client: dependencies.userClient) { client in
            let user = TestDomainModelBuilder.user()
            _ = try await client.create(user)
        }
        
        await tearDownAxiomTestEnvironment(environment)
    }
    
    // MARK: Integration Tests with Test Framework
    
    func testFullTestFrameworkIntegration() async throws {
        // Create test environment
        let environment = await AxiomTestUtilities.createTestEnvironment()
        
        // Set up intelligence features
        await environment.intelligence.enableFeature(.naturalLanguageQueries)
        await environment.intelligence.enableFeature(.architecturalDNA)
        
        // Create client dependencies
        let dependencies = await environment.createClientDependencies()
        
        // Test domain operations
        let user = TestDomainModelBuilder.user()
        let createdUser = try await dependencies.userClient.create(user)
        AxiomTestUtilities.assertEqual(user, createdUser)
        
        // Test intelligence operations
        let dna = AxiomTestUtilities.createTestArchitecturalDNA(for: ComponentID("TestUser"))
        await environment.intelligence.addDNA(dna, for: ComponentID("TestUser"))
        
        let retrievedDNA = try await environment.intelligence.getArchitecturalDNA(for: ComponentID("TestUser"))
        XCTAssertNotNil(retrievedDNA)
        
        // Test query processing
        let queryResult = try await environment.intelligence.processQuery("What is the TestUser component?")
        XCTAssertEqual(queryResult.intent, .help)
        XCTAssertTrue(queryResult.answer.contains("TestUser component"))
        
        // Test performance monitoring
        let token = await environment.performanceMonitor.startOperation("test-integration", category: .client)
        
        // Perform some work
        try await AxiomTestUtilities.waitForAsync(timeout: 0.1)
        
        await environment.performanceMonitor.endOperation(token)
        
        // Verify performance tracking
        let metrics = await environment.performanceMonitor.getMetrics(for: .client)
        XCTAssertEqual(metrics.totalOperations, 1)
        XCTAssertGreaterThan(metrics.averageDuration, 0)
        
        // Clean up
        await environment.reset()
        
        // Verify cleanup
        let finalMetrics = await environment.intelligence.getMetrics()
        XCTAssertEqual(finalMetrics.totalOperations, 0)
    }
    
    // MARK: Performance Tests for Test Framework
    
    func testTestFrameworkPerformance() async throws {
        measure {
            Task {
                // Test that creating test environments is fast
                let environment = await AxiomTestUtilities.createTestEnvironment()
                await environment.reset()
            }
        }
    }
    
    func testMockPerformanceOverhead() async throws {
        let mockMonitor = await MockPerformanceMonitor()
        
        // Measure overhead of mock operations
        let startTime = Date()
        
        for i in 0..<100 {
            let token = await mockMonitor.startOperation("test-\(i)", category: .intelligence)
            await mockMonitor.endOperation(token)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Mock operations should be very fast
        XCTAssertLessThan(duration, 1.0) // Less than 1 second for 100 operations
        
        let metrics = await mockMonitor.getMetrics(for: .intelligence)
        XCTAssertEqual(metrics.totalOperations, 100)
    }
    
    // MARK: Error Handling Tests
    
    func testTestFrameworkErrorHandling() async throws {
        let environment = await AxiomTestUtilities.createTestEnvironment()
        
        // Test capability error handling
        await environment.capabilityManager.removeCapability(.userDefaults)
        let dependencies = await environment.createClientDependencies()
        
        let invalidUser = TestDomainModelBuilder.user()
        
        do {
            _ = try await dependencies.userClient.create(invalidUser)
            XCTFail("Should have thrown capability error")
        } catch CapabilityError.unavailable(let capability) {
            XCTAssertEqual(capability, .userDefaults)
        }
        
        // Test domain validation error handling
        await environment.capabilityManager.addCapability(.userDefaults)
        let invalidUser2 = TestDomainModelBuilder.invalidUser()
        
        do {
            _ = try await dependencies.userClient.create(invalidUser2)
            XCTFail("Should have thrown domain validation error")
        } catch DomainError.validationFailed(let validation) {
            XCTAssertFalse(validation.isValid)
            XCTAssertEqual(validation.errors.count, 2)
        }
        
        await environment.reset()
    }
}