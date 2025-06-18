import XCTest
import CoreData
@testable import AxiomCapabilityDomains
@testable import AxiomCore
@testable import AxiomCapabilities

/// Comprehensive test suite for CoreData capability
@available(iOS 13.0, macOS 10.15, *)
final class CoreDataCapabilityTests: XCTestCase {
    
    var capability: CoreDataCapability!
    var testEnvironment: AxiomCapabilityEnvironment!
    var testConfiguration: CoreDataCapabilityConfiguration!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test environment
        testEnvironment = AxiomCapabilityEnvironment(
            isDebug: true,
            isLowPowerMode: false
        )
        
        // Create test configuration
        testConfiguration = CoreDataCapabilityConfiguration(
            enablePersistentStore: true,
            enableCloudKitSync: false, // Disable for testing
            enableWALJournaling: true,
            enableAutomaticMigration: true,
            enableBatchOperations: true,
            enableLogging: true,
            enableMetrics: true,
            enableCaching: true,
            cacheSize: 50,
            batchSize: 10,
            fetchLimit: 100,
            persistentStoreType: .sqlite,
            mergePolicy: .mergeByPropertyObjectTrump
        )
        
        capability = CoreDataCapability(
            configuration: testConfiguration,
            environment: testEnvironment
        )
    }
    
    override func tearDown() async throws {
        if let capability = capability, await capability.isAvailable {
            await capability.deactivate()
        }
        capability = nil
        testConfiguration = nil
        testEnvironment = nil
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationValidation() {
        XCTAssertTrue(testConfiguration.isValid, "Test configuration should be valid")
        
        // Test invalid configuration
        let invalidConfig = CoreDataCapabilityConfiguration(
            batchSize: 0, // Invalid batch size
            fetchLimit: -1 // Invalid fetch limit
        )
        XCTAssertFalse(invalidConfig.isValid, "Invalid configuration should not be valid")
    }
    
    func testConfigurationMerging() {
        let baseConfig = CoreDataCapabilityConfiguration()
        let updateConfig = CoreDataCapabilityConfiguration(
            enableCloudKitSync: true,
            batchSize: 50
        )
        
        let mergedConfig = baseConfig.merged(with: updateConfig)
        
        XCTAssertTrue(mergedConfig.enableCloudKitSync, "Merged config should enable CloudKit sync")
        XCTAssertEqual(mergedConfig.batchSize, 50, "Merged config should have updated batch size")
    }
    
    func testEnvironmentAdjustment() {
        let lowPowerEnvironment = AxiomCapabilityEnvironment(isLowPowerMode: true)
        let adjustedConfig = testConfiguration.adjusted(for: lowPowerEnvironment)
        
        XCTAssertEqual(adjustedConfig.batchSize, min(testConfiguration.batchSize, 5), "Batch size should be reduced in low power mode")
        XCTAssertEqual(adjustedConfig.cacheSize, min(testConfiguration.cacheSize, 10), "Cache size should be reduced in low power mode")
        XCTAssertFalse(adjustedConfig.enableBatchOperations, "Batch operations should be disabled in low power mode")
    }
    
    // MARK: - Capability Lifecycle Tests
    
    func testCapabilityActivation() async throws {
        XCTAssertEqual(await capability.state, .unknown, "Initial state should be unknown")
        
        try await capability.activate()
        
        XCTAssertEqual(await capability.state, .available, "State should be available after activation")
        XCTAssertTrue(await capability.isAvailable, "Capability should be available")
    }
    
    func testCapabilityDeactivation() async throws {
        try await capability.activate()
        XCTAssertTrue(await capability.isAvailable, "Capability should be available")
        
        await capability.deactivate()
        
        XCTAssertEqual(await capability.state, .unavailable, "State should be unavailable after deactivation")
        XCTAssertFalse(await capability.isAvailable, "Capability should not be available")
    }
    
    func testCapabilitySupport() async {
        let isSupported = await capability.isSupported()
        XCTAssertTrue(isSupported, "CoreData should be supported on iOS 13+")
    }
    
    func testPermissionRequest() async throws {
        // CoreData doesn't require special permissions
        try await capability.requestPermission()
        // Should not throw
    }
    
    // MARK: - Core Data Operations Tests
    
    func testEntityCreation() async throws {
        try await capability.activate()
        
        // Create test entity
        let createRequest = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Test Name", "value": 42],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let result = try await capability.executeOperation(createRequest)
        
        XCTAssertTrue(result.success, "Create operation should succeed")
        XCTAssertNil(result.error, "Create operation should not have errors")
        XCTAssertEqual(result.operationMetrics.affectedObjects, 1, "Should affect one object")
    }
    
    func testEntityFetch() async throws {
        try await capability.activate()
        
        // First create an entity
        let createRequest = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Fetch Test", "value": 100],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let createResult = try await capability.executeOperation(createRequest)
        XCTAssertTrue(createResult.success, "Create operation should succeed")
        
        // Now fetch the entity
        let fetchRequest = CoreDataOperationRequest(
            operationType: .fetch,
            entityName: "TestEntity",
            predicate: NSPredicate(format: "name == %@", "Fetch Test"),
            sortDescriptors: [],
            propertiesToUpdate: [:],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let fetchResult = try await capability.executeOperation(fetchRequest)
        
        XCTAssertTrue(fetchResult.success, "Fetch operation should succeed")
        XCTAssertEqual(fetchResult.operationMetrics.affectedObjects, 1, "Should fetch one object")
    }
    
    func testEntityUpdate() async throws {
        try await capability.activate()
        
        // Create entity first
        let createRequest = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Update Test", "value": 50],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let createResult = try await capability.executeOperation(createRequest)
        XCTAssertTrue(createResult.success, "Create operation should succeed")
        
        // Update the entity
        let updateRequest = CoreDataOperationRequest(
            operationType: .update,
            entityName: "TestEntity",
            predicate: NSPredicate(format: "name == %@", "Update Test"),
            sortDescriptors: [],
            propertiesToUpdate: ["value": 75],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let updateResult = try await capability.executeOperation(updateRequest)
        
        XCTAssertTrue(updateResult.success, "Update operation should succeed")
        XCTAssertEqual(updateResult.operationMetrics.affectedObjects, 1, "Should update one object")
    }
    
    func testEntityDeletion() async throws {
        try await capability.activate()
        
        // Create entity first
        let createRequest = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Delete Test", "value": 25],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let createResult = try await capability.executeOperation(createRequest)
        XCTAssertTrue(createResult.success, "Create operation should succeed")
        
        // Delete the entity
        let deleteRequest = CoreDataOperationRequest(
            operationType: .delete,
            entityName: "TestEntity",
            predicate: NSPredicate(format: "name == %@", "Delete Test"),
            sortDescriptors: [],
            propertiesToUpdate: [:],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let deleteResult = try await capability.executeOperation(deleteRequest)
        
        XCTAssertTrue(deleteResult.success, "Delete operation should succeed")
        XCTAssertEqual(deleteResult.operationMetrics.affectedObjects, 1, "Should delete one object")
    }
    
    func testBatchOperations() async throws {
        try await capability.activate()
        
        // Test batch insert
        let batchRequest = CoreDataOperationRequest(
            operationType: .batchInsert,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Batch Item", "value": 10],
            options: CoreDataOperationRequest.OperationOptions(batchSize: 5)
        )
        
        let batchResult = try await capability.executeOperation(batchRequest)
        
        XCTAssertTrue(batchResult.success, "Batch operation should succeed")
        XCTAssertGreaterThan(batchResult.operationMetrics.affectedObjects, 0, "Should affect objects in batch")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMetrics() async throws {
        try await capability.activate()
        
        // Perform multiple operations to generate metrics
        for i in 0..<10 {
            let request = CoreDataOperationRequest(
                operationType: .create,
                entityName: "TestEntity",
                predicate: nil,
                sortDescriptors: [],
                propertiesToUpdate: ["name": "Performance Test \(i)", "value": i * 10],
                options: CoreDataOperationRequest.OperationOptions()
            )
            
            let result = try await capability.executeOperation(request)
            XCTAssertTrue(result.success, "Performance test operation should succeed")
        }
        
        let metrics = try await capability.getMetrics()
        
        XCTAssertGreaterThan(metrics.totalOperations, 0, "Should have recorded operations")
        XCTAssertGreaterThan(metrics.successfulOperations, 0, "Should have successful operations")
        XCTAssertGreaterThan(metrics.averageOperationTime, 0, "Should have positive average operation time")
        XCTAssertEqual(metrics.failedOperations, 0, "Should have no failed operations")
    }
    
    func testOperationTimeout() async throws {
        try await capability.activate()
        
        // Test with very short timeout
        let shortTimeoutConfig = CoreDataCapabilityConfiguration(
            operationTimeout: 0.001 // 1ms timeout
        )
        
        let timeoutCapability = CoreDataCapability(
            configuration: shortTimeoutConfig,
            environment: testEnvironment
        )
        
        try await timeoutCapability.activate()
        
        // This operation might timeout due to very short timeout
        let request = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Timeout Test", "value": 1],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        // Operation may succeed or timeout - both are valid outcomes for this test
        do {
            let result = try await timeoutCapability.executeOperation(request)
            // If it succeeds, verify it's properly recorded
            XCTAssertNotNil(result, "Result should not be nil")
        } catch {
            // Timeout is expected with such a short timeout
            XCTAssertTrue(error is CoreDataError, "Should throw CoreDataError on timeout")
        }
        
        await timeoutCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidEntityName() async throws {
        try await capability.activate()
        
        let invalidRequest = CoreDataOperationRequest(
            operationType: .create,
            entityName: "NonExistentEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Test"],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        do {
            let result = try await capability.executeOperation(invalidRequest)
            XCTAssertFalse(result.success, "Operation with invalid entity should fail")
            XCTAssertNotNil(result.error, "Should have error for invalid entity")
        } catch {
            // Throwing an error is also acceptable
            XCTAssertTrue(error is CoreDataError, "Should throw CoreDataError")
        }
    }
    
    func testUnavailableCapability() async throws {
        // Test operations on inactive capability
        do {
            let request = CoreDataOperationRequest(
                operationType: .create,
                entityName: "TestEntity",
                predicate: nil,
                sortDescriptors: [],
                propertiesToUpdate: ["name": "Test"],
                options: CoreDataOperationRequest.OperationOptions()
            )
            
            _ = try await capability.executeOperation(request)
            XCTFail("Should throw error when capability is not activated")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError when unavailable")
        }
    }
    
    // MARK: - Stream Tests
    
    func testResultStream() async throws {
        try await capability.activate()
        
        let resultStream = try await capability.getResultStream()
        
        // Create expectation for stream result
        let expectation = XCTestExpectation(description: "Result stream should emit result")
        expectation.expectedFulfillmentCount = 1
        
        // Listen to stream
        Task {
            for await result in resultStream {
                XCTAssertNotNil(result, "Stream result should not be nil")
                expectation.fulfill()
                break // Exit after first result
            }
        }
        
        // Perform operation to trigger stream
        let request = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Stream Test", "value": 42],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let result = try await capability.executeOperation(request)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Configuration Update Tests
    
    func testConfigurationUpdate() async throws {
        try await capability.activate()
        
        let newConfig = CoreDataCapabilityConfiguration(
            batchSize: 25,
            enableLogging: false
        )
        
        try await capability.updateConfiguration(newConfig)
        
        let updatedConfig = await capability.configuration
        XCTAssertEqual(updatedConfig.batchSize, 25, "Configuration should be updated")
        XCTAssertFalse(updatedConfig.enableLogging, "Logging should be disabled")
    }
    
    func testInvalidConfigurationUpdate() async throws {
        try await capability.activate()
        
        let invalidConfig = CoreDataCapabilityConfiguration(
            batchSize: -1 // Invalid batch size
        )
        
        do {
            try await capability.updateConfiguration(invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is AxiomCapabilityError, "Should throw AxiomCapabilityError for invalid config")
        }
    }
    
    // MARK: - Cleanup Tests
    
    func testMetricsClearance() async throws {
        try await capability.activate()
        
        // Generate some metrics
        let request = CoreDataOperationRequest(
            operationType: .create,
            entityName: "TestEntity",
            predicate: nil,
            sortDescriptors: [],
            propertiesToUpdate: ["name": "Metrics Test", "value": 1],
            options: CoreDataOperationRequest.OperationOptions()
        )
        
        let result = try await capability.executeOperation(request)
        XCTAssertTrue(result.success, "Operation should succeed")
        
        let metricsBeforeClear = try await capability.getMetrics()
        XCTAssertGreaterThan(metricsBeforeClear.totalOperations, 0, "Should have metrics before clear")
        
        // Clear metrics
        try await capability.clearMetrics()
        
        let metricsAfterClear = try await capability.getMetrics()
        XCTAssertEqual(metricsAfterClear.totalOperations, 0, "Metrics should be cleared")
    }
    
    func testCacheClearance() async throws {
        try await capability.activate()
        
        // Clear cache should not throw
        try await capability.clearCache()
    }
}

// MARK: - Test Extensions

extension CoreDataCapabilityTests {
    
    /// Helper method to create test entities
    private func createTestEntities(count: Int) async throws {
        for i in 0..<count {
            let request = CoreDataOperationRequest(
                operationType: .create,
                entityName: "TestEntity",
                predicate: nil,
                sortDescriptors: [],
                propertiesToUpdate: ["name": "Test Entity \(i)", "value": i],
                options: CoreDataOperationRequest.OperationOptions()
            )
            
            let result = try await capability.executeOperation(request)
            XCTAssertTrue(result.success, "Test entity creation should succeed")
        }
    }
    
    /// Helper method to verify operation result
    private func verifyOperationResult(_ result: CoreDataOperationResult, shouldSucceed: Bool = true) {
        XCTAssertEqual(result.success, shouldSucceed, "Operation success should match expectation")
        
        if shouldSucceed {
            XCTAssertNil(result.error, "Successful operation should not have error")
            XCTAssertGreaterThan(result.processingTime, 0, "Processing time should be positive")
        } else {
            XCTAssertNotNil(result.error, "Failed operation should have error")
        }
        
        XCTAssertNotNil(result.operationMetrics, "Operation should have metrics")
    }
}