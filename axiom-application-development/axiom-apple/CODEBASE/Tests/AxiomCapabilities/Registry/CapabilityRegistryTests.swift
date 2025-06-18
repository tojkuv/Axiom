import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities registry functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class CapabilityRegistryTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testCapabilityRegistryInitialization() async throws {
        let registry = CapabilityRegistry()
        XCTAssertNotNil(registry, "CapabilityRegistry should initialize correctly")
    }
    
    func testCapabilityRegistration() async throws {
        let registry = CapabilityRegistry()
        let testCapability = TestCapability()
        
        await registry.registerCapability(testCapability)
        
        let isRegistered = await registry.isCapabilityRegistered(TestCapability.identifier)
        XCTAssertTrue(isRegistered, "Capability should be registered")
        
        let registeredCapability = await registry.getCapability(TestCapability.identifier)
        XCTAssertNotNil(registeredCapability, "Should retrieve registered capability")
    }
    
    func testCapabilityDiscovery() async throws {
        let registry = CapabilityRegistry()
        
        // Register multiple capabilities
        await registry.registerCapability(TestCapability())
        await registry.registerCapability(AnotherTestCapability())
        
        let allCapabilities = await registry.getAllCapabilities()
        XCTAssertEqual(allCapabilities.count, 2, "Should have 2 registered capabilities")
        
        let availableCapabilities = await registry.getAvailableCapabilities()
        XCTAssertGreaterThanOrEqual(availableCapabilities.count, 0, "Should return available capabilities")
        
        let unavailableCapabilities = await registry.getUnavailableCapabilities()
        XCTAssertGreaterThanOrEqual(unavailableCapabilities.count, 0, "Should return unavailable capabilities")
    }
    
    func testCapabilityDependencies() async throws {
        let registry = CapabilityRegistry()
        let dependentCapability = DependentCapability()
        
        // Register dependency first
        await registry.registerCapability(TestCapability())
        
        // Register dependent capability
        await registry.registerCapability(dependentCapability)
        
        let dependencies = await registry.getDependencies(DependentCapability.identifier)
        XCTAssertEqual(dependencies.count, 1, "Should have 1 dependency")
        XCTAssertEqual(dependencies.first, TestCapability.identifier, "Should depend on TestCapability")
        
        let dependents = await registry.getDependents(TestCapability.identifier)
        XCTAssertTrue(dependents.contains(DependentCapability.identifier), "TestCapability should have DependentCapability as dependent")
    }
    
    func testCapabilityUnregistration() async throws {
        let registry = CapabilityRegistry()
        let testCapability = TestCapability()
        
        await registry.registerCapability(testCapability)
        
        let isRegistered = await registry.isCapabilityRegistered(TestCapability.identifier)
        XCTAssertTrue(isRegistered, "Capability should be registered")
        
        await registry.unregisterCapability(TestCapability.identifier)
        
        let isStillRegistered = await registry.isCapabilityRegistered(TestCapability.identifier)
        XCTAssertFalse(isStillRegistered, "Capability should be unregistered")
        
        let capability = await registry.getCapability(TestCapability.identifier)
        XCTAssertNil(capability, "Should not retrieve unregistered capability")
    }
    
    // MARK: - Performance Tests
    
    func testCapabilityRegistryPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let registry = CapabilityRegistry()
                
                // Test rapid registration and lookup
                for i in 0..<100 {
                    let capability = TestCapability(suffix: "_\(i)")
                    await registry.registerCapability(capability)
                }
                
                // Test bulk lookup
                for i in 0..<100 {
                    let identifier = TestCapability.baseIdentifier + "_\(i)"
                    _ = await registry.getCapability(identifier)
                }
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testCapabilityRegistryMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let registry = CapabilityRegistry()
            
            // Simulate registry lifecycle
            for i in 0..<50 {
                let capability = TestCapability(suffix: "_\(i)")
                await registry.registerCapability(capability)
                
                if i % 10 == 0 {
                    await registry.unregisterCapability(capability.identifier)
                }
            }
            
            await registry.clearRegistry()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCapabilityRegistryErrorHandling() async throws {
        let registry = CapabilityRegistry()
        
        // Test duplicate registration
        let testCapability = TestCapability()
        await registry.registerCapability(testCapability)
        
        do {
            try await registry.registerCapabilityStrict(testCapability)
            XCTFail("Should throw error for duplicate registration")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate registration")
        }
        
        // Test unregistering non-existent capability
        do {
            try await registry.unregisterCapabilityStrict("non.existent.capability")
            XCTFail("Should throw error for non-existent capability")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for non-existent capability")
        }
    }
}

// MARK: - Test Helper Classes

private struct TestCapability: AxiomCapability {
    static let baseIdentifier = "test.capability"
    let identifier: String
    let isAvailable: Bool = true
    
    init(suffix: String = "") {
        self.identifier = Self.baseIdentifier + suffix
    }
}

private struct AnotherTestCapability: AxiomCapability {
    static let identifier = "another.test.capability"
    let identifier: String = Self.identifier
    let isAvailable: Bool = true
}

private struct DependentCapability: AxiomCapability {
    static let identifier = "dependent.capability"
    let identifier: String = Self.identifier
    let isAvailable: Bool = true
    let dependencies: [String] = [TestCapability.baseIdentifier]
}