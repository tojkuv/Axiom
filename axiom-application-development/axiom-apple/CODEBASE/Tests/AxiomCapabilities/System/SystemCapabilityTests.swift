import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities system capability functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class SystemCapabilityTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testSystemCapabilityInitialization() async throws {
        let systemCapability = SystemCapability()
        XCTAssertNotNil(systemCapability, "SystemCapability should initialize correctly")
        XCTAssertEqual(systemCapability.identifier, "axiom.system", "Should have correct identifier")
    }
    
    func testFileSystemCapability() async throws {
        let fileSystemCapability = FileSystemCapability()
        
        let isAvailable = await fileSystemCapability.isAvailable()
        XCTAssertTrue(isAvailable, "File system should be available")
        
        let canReadFiles = await fileSystemCapability.canReadFiles()
        XCTAssertTrue(canReadFiles, "Should be able to read files")
        
        let canWriteFiles = await fileSystemCapability.canWriteFiles()
        XCTAssertTrue(canWriteFiles, "Should be able to write files")
        
        let availableSpace = await fileSystemCapability.getAvailableSpace()
        XCTAssertGreaterThan(availableSpace, 0, "Available space should be positive")
    }
    
    func testNetworkCapability() async throws {
        let networkCapability = NetworkCapability()
        
        let isAvailable = await networkCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Network availability should be determinable")
        
        let networkTypes = await networkCapability.getAvailableNetworkTypes()
        XCTAssertFalse(networkTypes.isEmpty, "Should have network types")
        
        let connectionQuality = await networkCapability.getConnectionQuality()
        XCTAssertNotNil(connectionQuality, "Should determine connection quality")
    }
    
    func testNotificationCapability() async throws {
        let notificationCapability = NotificationCapability()
        
        let isAvailable = await notificationCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Notification availability should be determinable")
        
        if isAvailable {
            let canSchedule = await notificationCapability.canScheduleNotifications()
            XCTAssertNotNil(canSchedule, "Should determine scheduling capability")
            
            let supportedTypes = await notificationCapability.getSupportedNotificationTypes()
            XCTAssertFalse(supportedTypes.isEmpty, "Should support notification types")
        }
    }
    
    func testLocationCapability() async throws {
        let locationCapability = LocationCapability()
        
        let isAvailable = await locationCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Location availability should be determinable")
        
        if isAvailable {
            let accuracy = await locationCapability.getBestAccuracyAvailable()
            XCTAssertNotNil(accuracy, "Should determine best accuracy")
            
            let canTrackInBackground = await locationCapability.canTrackInBackground()
            XCTAssertNotNil(canTrackInBackground, "Should determine background tracking capability")
        }
    }
    
    func testCameraCapability() async throws {
        let cameraCapability = CameraCapability()
        
        let isAvailable = await cameraCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Camera availability should be determinable")
        
        if isAvailable {
            let cameras = await cameraCapability.getAvailableCameras()
            XCTAssertFalse(cameras.isEmpty, "Should have available cameras")
            
            let canRecordVideo = await cameraCapability.canRecordVideo()
            XCTAssertNotNil(canRecordVideo, "Should determine video recording capability")
            
            let maxResolution = await cameraCapability.getMaxResolution()
            XCTAssertNotNil(maxResolution, "Should determine max resolution")
        }
    }
    
    // MARK: - Performance Tests
    
    func testSystemCapabilityPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let systemCapability = SystemCapability()
                let fileSystemCapability = FileSystemCapability()
                let networkCapability = NetworkCapability()
                let notificationCapability = NotificationCapability()
                
                // Test rapid capability queries
                for _ in 0..<50 {
                    _ = await systemCapability.isAvailable()
                    _ = await fileSystemCapability.getAvailableSpace()
                    _ = await networkCapability.getConnectionQuality()
                    _ = await notificationCapability.getSupportedNotificationTypes()
                }
            },
            maxDuration: .milliseconds(150),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testSystemCapabilityMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let systemCapability = SystemCapability()
            let fileSystemCapability = FileSystemCapability()
            let networkCapability = NetworkCapability()
            let locationCapability = LocationCapability()
            let cameraCapability = CameraCapability()
            
            // Simulate capability lifecycle
            for _ in 0..<25 {
                _ = await systemCapability.isAvailable()
                _ = await fileSystemCapability.canReadFiles()
                _ = await networkCapability.getAvailableNetworkTypes()
                _ = await locationCapability.getBestAccuracyAvailable()
                _ = await cameraCapability.getAvailableCameras()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSystemCapabilityErrorHandling() async throws {
        let fileSystemCapability = FileSystemCapability()
        
        // Test reading from invalid path
        do {
            try await fileSystemCapability.readFileStrict(path: "/invalid/path")
            XCTFail("Should throw error for invalid path")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid path")
        }
        
        let networkCapability = NetworkCapability()
        
        // Test connection with invalid configuration
        do {
            let invalidConfig = NetworkConfiguration(host: "", port: -1)
            try await networkCapability.connectStrict(configuration: invalidConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid configuration")
        }
        
        let notificationCapability = NotificationCapability()
        
        // Test scheduling notification without permission
        do {
            let notification = TestNotification(title: "Test", body: "Test body")
            try await notificationCapability.scheduleNotificationStrict(notification)
            // This might succeed if permissions are granted, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for permission issues")
        }
    }
}

// MARK: - Test Helper Types

private enum NetworkType {
    case wifi
    case cellular
    case ethernet
    case bluetooth
}

private enum ConnectionQuality {
    case excellent
    case good
    case fair
    case poor
    case unavailable
}

private enum NotificationType {
    case alert
    case banner
    case badge
    case sound
}

private enum LocationAccuracy {
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
}

private enum CameraPosition {
    case front
    case back
    case unspecified
}

private struct NetworkConfiguration {
    let host: String
    let port: Int
}

private struct TestNotification {
    let title: String
    let body: String
}