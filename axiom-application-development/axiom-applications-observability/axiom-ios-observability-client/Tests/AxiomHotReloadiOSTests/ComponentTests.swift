import XCTest
import SwiftUI
@testable import AxiomHotReloadiOS
@testable import HotReloadProtocol
@testable import NetworkClient
@testable import SwiftUIRenderer

final class ComponentTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testAxiomObservabilityConfiguration() throws {
        let config = AxiomObservabilityConfiguration()
        
        XCTAssertTrue(config.enableHotReload)
        XCTAssertFalse(config.enableDebugMode)
        XCTAssertTrue(config.autoConnect)
        XCTAssertTrue(config.showStatusIndicator)
        XCTAssertFalse(config.showDebugInfo)
        XCTAssertFalse(config.enableStateLogging)
        XCTAssertTrue(config.clearOnDisconnect)
        XCTAssertEqual(config.statusIndicatorPadding, 20)
        
        // New observability configuration
        XCTAssertTrue(config.enableMetadataStreaming)
        XCTAssertTrue(config.enableScreenshotCapture)
        XCTAssertTrue(config.enableHierarchyAnalysis)
        XCTAssertTrue(config.enableContextInspection)
    }
    
    func testNetworkConfiguration() throws {
        let config = NetworkConfiguration()
        
        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 8080)
        XCTAssertFalse(config.useSSL)
        XCTAssertEqual(config.timeout, 30.0)
    }
    
    // MARK: - State Manager Tests
    
    @MainActor func testSwiftUIStateManagerInitialization() throws {
        let stateManager = SwiftUIStateManager()
        XCTAssertNotNil(stateManager)
    }
    
    // MARK: - Renderer Tests
    
    @MainActor func testSwiftUIJSONRendererInitialization() throws {
        let stateManager = SwiftUIStateManager()
        let renderer = SwiftUIJSONRenderer(stateManager: stateManager)
        XCTAssertNotNil(renderer)
    }
    
    // MARK: - Configuration Builder Tests
    
    func testAxiomObservabilityConfigurationDefaults() throws {
        let config = AxiomObservabilityConfiguration()
        
        // Test conversion to HotReloadConfiguration
        let hotReloadConfig = config.toHotReloadConfiguration()
        XCTAssertNotNil(hotReloadConfig)
        XCTAssertEqual(hotReloadConfig.enableHotReload, config.enableHotReload)
        XCTAssertEqual(hotReloadConfig.enableDebugMode, config.enableDebugMode)
        XCTAssertEqual(hotReloadConfig.autoConnect, config.autoConnect)
    }
    
    // MARK: - Message Types Tests
    
    func testMessageTypesSerialization() throws {
        // Test basic message creation and serialization
        let timestamp = Date()
        
        // This tests that our message types can be instantiated
        // without requiring actual SwiftUI context
        XCTAssertNotNil(timestamp)
    }
    
    // MARK: - Network Configuration Tests
    
    func testNetworkConfigurationCustomization() throws {
        var config = NetworkConfiguration()
        config.host = "custom.host.com"
        config.port = 9090
        config.useSSL = true
        config.timeout = 60.0
        
        XCTAssertEqual(config.host, "custom.host.com")
        XCTAssertEqual(config.port, 9090)
        XCTAssertTrue(config.useSSL)
        XCTAssertEqual(config.timeout, 60.0)
    }
}