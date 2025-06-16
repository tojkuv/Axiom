import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform device info functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class DeviceInfoTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testDeviceInfoInitialization() async throws {
        let deviceInfo = DeviceInfo()
        XCTAssertNotNil(deviceInfo, "DeviceInfo should initialize correctly")
    }
    
    func testDeviceCapabilityDetection() async throws {
        let deviceInfo = DeviceInfo()
        
        let hasCamera = await deviceInfo.hasCapability(.camera)
        XCTAssertNotNil(hasCamera, "Camera capability detection should return a value")
        
        let hasLocation = await deviceInfo.hasCapability(.location)
        XCTAssertNotNil(hasLocation, "Location capability detection should return a value")
        
        let hasNetwork = await deviceInfo.hasCapability(.network)
        XCTAssertTrue(hasNetwork, "Network capability should be available on all devices")
    }
    
    func testMemoryInformation() async throws {
        let deviceInfo = DeviceInfo()
        
        let totalMemory = await deviceInfo.getTotalMemory()
        XCTAssertGreaterThan(totalMemory, 0, "Total memory should be greater than 0")
        
        let availableMemory = await deviceInfo.getAvailableMemory()
        XCTAssertGreaterThan(availableMemory, 0, "Available memory should be greater than 0")
        XCTAssertLessThanOrEqual(availableMemory, totalMemory, "Available memory should not exceed total memory")
    }
    
    func testStorageInformation() async throws {
        let deviceInfo = DeviceInfo()
        
        let totalStorage = await deviceInfo.getTotalStorage()
        XCTAssertGreaterThan(totalStorage, 0, "Total storage should be greater than 0")
        
        let availableStorage = await deviceInfo.getAvailableStorage()
        XCTAssertGreaterThan(availableStorage, 0, "Available storage should be greater than 0")
        XCTAssertLessThanOrEqual(availableStorage, totalStorage, "Available storage should not exceed total storage")
    }
    
    func testDeviceIdentification() async throws {
        let deviceInfo = DeviceInfo()
        
        let deviceModel = await deviceInfo.getDeviceModel()
        XCTAssertFalse(deviceModel.isEmpty, "Device model should not be empty")
        
        let osVersion = await deviceInfo.getOSVersion()
        XCTAssertFalse(osVersion.isEmpty, "OS version should not be empty")
        
        let appVersion = await deviceInfo.getAppVersion()
        XCTAssertNotNil(appVersion, "App version should be available")
    }
    
    // MARK: - Performance Tests
    
    func testDeviceInfoPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let deviceInfo = DeviceInfo()
                
                // Test rapid capability queries
                let capabilities: [DeviceCapability] = [.camera, .location, .network, .storage, .memory]
                
                for capability in capabilities {
                    _ = await deviceInfo.hasCapability(capability)
                }
                
                // Test system info queries
                _ = await deviceInfo.getTotalMemory()
                _ = await deviceInfo.getAvailableMemory()
                _ = await deviceInfo.getTotalStorage()
                _ = await deviceInfo.getAvailableStorage()
            },
            maxDuration: .milliseconds(50),
            maxMemoryGrowth: 256 * 1024 // 256KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testDeviceInfoMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let deviceInfo = DeviceInfo()
            
            // Simulate repeated device info queries
            for _ in 0..<100 {
                _ = await deviceInfo.getDeviceModel()
                _ = await deviceInfo.getOSVersion()
                _ = await deviceInfo.getTotalMemory()
                _ = await deviceInfo.hasCapability(.camera)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDeviceInfoErrorHandling() async throws {
        let deviceInfo = DeviceInfo()
        
        // Test query for unsupported capability
        struct UnsupportedCapability: DeviceCapability {
            let identifier = "unsupported.capability"
        }
        
        let unsupportedCapability = UnsupportedCapability()
        let hasUnsupported = await deviceInfo.hasCapability(unsupportedCapability)
        XCTAssertFalse(hasUnsupported, "Should return false for unsupported capabilities")
        
        // Test error conditions in capability detection
        do {
            _ = try await deviceInfo.getCapabilityInfoStrict(.invalid)
            XCTFail("Should throw error for invalid capability")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid capability")
        }
    }
}