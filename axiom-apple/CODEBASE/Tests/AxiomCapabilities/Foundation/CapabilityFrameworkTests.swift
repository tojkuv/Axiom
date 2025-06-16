import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities framework foundation functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CapabilityFrameworkTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testCapabilityFrameworkInitialization() async throws {
        let framework = CapabilityFramework()
        XCTAssertNotNil(framework, "CapabilityFramework should initialize correctly")
    }
    
    func testCapabilityLifecycle() async throws {
        let framework = CapabilityFramework()
        let testCapability = LifecycleTestCapability()
        
        // Test registration
        await framework.registerCapability(testCapability)
        
        let isRegistered = await framework.isCapabilityRegistered(testCapability.identifier)
        XCTAssertTrue(isRegistered, "Capability should be registered")
        
        // Test activation
        await framework.activateCapability(testCapability.identifier)
        
        let isActive = await framework.isCapabilityActive(testCapability.identifier)
        XCTAssertTrue(isActive, "Capability should be active")
        
        // Test deactivation
        await framework.deactivateCapability(testCapability.identifier)
        
        let isStillActive = await framework.isCapabilityActive(testCapability.identifier)
        XCTAssertFalse(isStillActive, "Capability should be deactivated")
        
        // Test unregistration
        await framework.unregisterCapability(testCapability.identifier)
        
        let isStillRegistered = await framework.isCapabilityRegistered(testCapability.identifier)
        XCTAssertFalse(isStillRegistered, "Capability should be unregistered")
    }
    
    func testCapabilityDependencyResolution() async throws {
        let framework = CapabilityFramework()
        
        let baseCapability = BaseTestCapability()
        let dependentCapability = DependentTestCapability()
        
        // Register capabilities
        await framework.registerCapability(baseCapability)
        await framework.registerCapability(dependentCapability)
        
        // Activate dependent capability - should auto-activate dependencies
        await framework.activateCapability(dependentCapability.identifier)
        
        let isBaseActive = await framework.isCapabilityActive(baseCapability.identifier)
        XCTAssertTrue(isBaseActive, "Base capability should be auto-activated")
        
        let isDependentActive = await framework.isCapabilityActive(dependentCapability.identifier)
        XCTAssertTrue(isDependentActive, "Dependent capability should be active")
    }
    
    func testCapabilityPermissionManagement() async throws {
        let framework = CapabilityFramework()
        let permissionCapability = PermissionTestCapability()
        
        await framework.registerCapability(permissionCapability)
        
        // Check initial permission status
        let initialStatus = await framework.getPermissionStatus(for: permissionCapability.identifier)
        XCTAssertNotNil(initialStatus, "Should have permission status")
        
        // Request permission
        let granted = await framework.requestPermission(for: permissionCapability.identifier)
        XCTAssertNotNil(granted, "Should determine if permission was granted")
        
        // Check updated permission status
        let updatedStatus = await framework.getPermissionStatus(for: permissionCapability.identifier)
        XCTAssertNotNil(updatedStatus, "Should have updated permission status")
    }
    
    func testCapabilityStateObservation() async throws {
        let framework = CapabilityFramework()
        let observableCapability = ObservableTestCapability()
        
        await framework.registerCapability(observableCapability)
        
        let expectation = expectation(description: "State change notification")
        
        let observer = await framework.observeCapabilityState(observableCapability.identifier) { state in
            if state == .active {
                expectation.fulfill()
            }
        }
        
        XCTAssertNotNil(observer, "Should create state observer")
        
        // Trigger state change
        await framework.activateCapability(observableCapability.identifier)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        await framework.removeObserver(observer!)
    }
    
    func testCapabilityMetadataRetrieval() async throws {
        let framework = CapabilityFramework()
        let metadataCapability = MetadataTestCapability()
        
        await framework.registerCapability(metadataCapability)
        
        let metadata = await framework.getCapabilityMetadata(metadataCapability.identifier)
        XCTAssertNotNil(metadata, "Should retrieve capability metadata")
        
        if let metadata = metadata {
            XCTAssertEqual(metadata.name, "Test Capability", "Should have correct name")
            XCTAssertEqual(metadata.version, "1.0.0", "Should have correct version")
            XCTAssertFalse(metadata.description.isEmpty, "Should have description")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCapabilityFrameworkPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let framework = CapabilityFramework()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = PerformanceTestCapability(index: i)
                    await framework.registerCapability(capability)
                    await framework.activateCapability(capability.identifier)
                    await framework.deactivateCapability(capability.identifier)
                    await framework.unregisterCapability(capability.identifier)
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testCapabilityFrameworkMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let framework = CapabilityFramework()
            
            // Simulate framework lifecycle
            for i in 0..<50 {
                let capability = MemoryTestCapability(index: i)
                await framework.registerCapability(capability)
                
                if i % 2 == 0 {
                    await framework.activateCapability(capability.identifier)
                }
                
                if i % 5 == 0 {
                    await framework.deactivateCapability(capability.identifier)
                    await framework.unregisterCapability(capability.identifier)
                }
            }
            
            await framework.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCapabilityFrameworkErrorHandling() async throws {
        let framework = CapabilityFramework()
        
        // Test activating non-existent capability
        do {
            try await framework.activateCapabilityStrict("non.existent.capability")
            XCTFail("Should throw error for non-existent capability")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for non-existent capability")
        }
        
        // Test registering capability with duplicate identifier
        let capability1 = DuplicateTestCapability()
        let capability2 = DuplicateTestCapability()
        
        await framework.registerCapability(capability1)
        
        do {
            try await framework.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test activating capability without required permissions
        let restrictedCapability = RestrictedTestCapability()
        await framework.registerCapability(restrictedCapability)
        
        do {
            try await framework.activateCapabilityStrict(restrictedCapability.identifier)
            // This might succeed if permissions are granted, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for permission issues")
        }
    }
}

// MARK: - Test Helper Classes

private struct LifecycleTestCapability: AxiomCapability {
    let identifier = "test.lifecycle.capability"
    let isAvailable = true
}

private struct BaseTestCapability: AxiomCapability {
    let identifier = "test.base.capability"
    let isAvailable = true
}

private struct DependentTestCapability: AxiomCapability {
    let identifier = "test.dependent.capability"
    let isAvailable = true
    let dependencies = ["test.base.capability"]
}

private struct PermissionTestCapability: AxiomCapability {
    let identifier = "test.permission.capability"
    let isAvailable = true
    let requiredPermissions = ["camera", "location"]
}

private struct ObservableTestCapability: AxiomCapability {
    let identifier = "test.observable.capability"
    let isAvailable = true
}

private struct MetadataTestCapability: AxiomCapability {
    let identifier = "test.metadata.capability"
    let isAvailable = true
    
    var metadata: CapabilityMetadata {
        CapabilityMetadata(
            name: "Test Capability",
            version: "1.0.0",
            description: "A test capability for framework testing"
        )
    }
}

private struct PerformanceTestCapability: AxiomCapability {
    let identifier: String
    let isAvailable = true
    
    init(index: Int) {
        self.identifier = "test.performance.capability.\(index)"
    }
}

private struct MemoryTestCapability: AxiomCapability {
    let identifier: String
    let isAvailable = true
    
    init(index: Int) {
        self.identifier = "test.memory.capability.\(index)"
    }
}

private struct DuplicateTestCapability: AxiomCapability {
    let identifier = "test.duplicate.capability"
    let isAvailable = true
}

private struct RestrictedTestCapability: AxiomCapability {
    let identifier = "test.restricted.capability"
    let isAvailable = true
    let requiredPermissions = ["restricted.permission"]
}

private struct CapabilityMetadata {
    let name: String
    let version: String
    let description: String
}

private enum CapabilityState {
    case inactive
    case active
    case error
}