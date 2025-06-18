import XCTest
import SwiftUI
@testable import AxiomHotReloadiOS
@testable import HotReloadProtocol
@testable import NetworkClient
@testable import SwiftUIRenderer

final class SimpleIntegrationTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testObservabilityConfigurationCreation() throws {
        let config = AxiomObservabilityConfiguration()
        XCTAssertNotNil(config)
        XCTAssertTrue(config.enableMetadataStreaming)
        XCTAssertTrue(config.enableScreenshotCapture)
    }
    
    // MARK: - Static Factory Tests
    
    func testObservabilityClientFactoryMethods() throws {
        // Test that we can create configurations without crashing
        let developmentClient = AxiomObservabilityClient<Text>.development { Text("Development") }
        XCTAssertNotNil(developmentClient)
        
        let productionClient = AxiomObservabilityClient<Text>.production { Text("Production") }
        XCTAssertNotNil(productionClient)
    }
    
    // MARK: - Configuration Integration Tests
    
    func testConfigurationConversion() throws {
        let observabilityConfig = AxiomObservabilityConfiguration()
        let hotReloadConfig = observabilityConfig.toHotReloadConfiguration()
        
        XCTAssertNotNil(hotReloadConfig)
        XCTAssertEqual(hotReloadConfig.enableHotReload, observabilityConfig.enableHotReload)
        XCTAssertEqual(hotReloadConfig.enableDebugMode, observabilityConfig.enableDebugMode)
    }
    
    // MARK: - Network Configuration Tests
    
    func testNetworkConfigurationDefaults() throws {
        let config = NetworkConfiguration()
        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 8080)
        XCTAssertFalse(config.useSSL)
        XCTAssertEqual(config.timeout, 30.0)
    }
    
    // MARK: - Component Configuration Tests
    
    func testMetadataStreamingConfiguration() throws {
        let config = MetadataStreamingConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testScreenshotCaptureConfiguration() throws {
        let config = ScreenshotCaptureConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testViewHierarchyAnalyzerConfiguration() throws {
        let config = ViewHierarchyAnalyzerConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testContextInspectorConfiguration() throws {
        let config = ContextInspectorConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testConnectionConfiguration() throws {
        let config = ConnectionConfiguration()
        XCTAssertNotNil(config)
        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 3001)
    }
    
    func testSwiftUIStateConfiguration() throws {
        let config = SwiftUIStateConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testSwiftUIRenderConfiguration() throws {
        let config = SwiftUIRenderConfiguration()
        XCTAssertNotNil(config)
    }
}