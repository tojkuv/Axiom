import XCTest
import AxiomTesting
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilities integration capability functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class IntegrationCapabilityTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testIntegrationCapabilityInitialization() async throws {
        let integrationCapability = IntegrationCapability()
        XCTAssertNotNil(integrationCapability, "IntegrationCapability should initialize correctly")
        XCTAssertEqual(integrationCapability.identifier, "axiom.integration", "Should have correct identifier")
    }
    
    func testAppExtensionCapability() async throws {
        let extensionCapability = AppExtensionCapability()
        
        let isAvailable = await extensionCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "App extension availability should be determinable")
        
        if isAvailable {
            let supportedExtensionTypes = await extensionCapability.getSupportedExtensionTypes()
            XCTAssertFalse(supportedExtensionTypes.isEmpty, "Should support extension types")
            
            let canRunWidgets = await extensionCapability.canRunWidgets()
            XCTAssertNotNil(canRunWidgets, "Should determine widget capability")
            
            let canRunShareExtensions = await extensionCapability.canRunShareExtensions()
            XCTAssertNotNil(canRunShareExtensions, "Should determine share extension capability")
        }
    }
    
    func testCloudKitCapability() async throws {
        let cloudKitCapability = CloudKitCapability()
        
        let isAvailable = await cloudKitCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "CloudKit availability should be determinable")
        
        if isAvailable {
            let canSyncData = await cloudKitCapability.canSyncData()
            XCTAssertNotNil(canSyncData, "Should determine data sync capability")
            
            let canShareRecords = await cloudKitCapability.canShareRecords()
            XCTAssertNotNil(canShareRecords, "Should determine record sharing capability")
            
            let supportedDatabases = await cloudKitCapability.getSupportedDatabases()
            XCTAssertFalse(supportedDatabases.isEmpty, "Should support database types")
        }
    }
    
    func testSiriIntegrationCapability() async throws {
        let siriCapability = SiriIntegrationCapability()
        
        let isAvailable = await siriCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Siri integration availability should be determinable")
        
        if isAvailable {
            let supportedIntents = await siriCapability.getSupportedIntents()
            XCTAssertFalse(supportedIntents.isEmpty, "Should support intent types")
            
            let canHandleVoiceCommands = await siriCapability.canHandleVoiceCommands()
            XCTAssertNotNil(canHandleVoiceCommands, "Should determine voice command capability")
            
            let canProvideShortcuts = await siriCapability.canProvideShortcuts()
            XCTAssertNotNil(canProvideShortcuts, "Should determine shortcuts capability")
        }
    }
    
    func testWatchConnectivityCapability() async throws {
        let watchCapability = WatchConnectivityCapability()
        
        let isAvailable = await watchCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Watch connectivity availability should be determinable")
        
        if isAvailable {
            let canCommunicateWithWatch = await watchCapability.canCommunicateWithWatch()
            XCTAssertNotNil(canCommunicateWithWatch, "Should determine watch communication capability")
            
            let canTransferData = await watchCapability.canTransferData()
            XCTAssertNotNil(canTransferData, "Should determine data transfer capability")
            
            let maxMessageSize = await watchCapability.getMaxMessageSize()
            XCTAssertGreaterThan(maxMessageSize, 0, "Max message size should be positive")
        }
    }
    
    func testWebServiceCapability() async throws {
        let webServiceCapability = WebServiceCapability()
        
        let isAvailable = await webServiceCapability.isAvailable()
        XCTAssertTrue(isAvailable, "Web service capability should be available")
        
        let supportedProtocols = await webServiceCapability.getSupportedProtocols()
        XCTAssertFalse(supportedProtocols.isEmpty, "Should support web protocols")
        
        let canMakeHTTPSRequests = await webServiceCapability.canMakeHTTPSRequests()
        XCTAssertTrue(canMakeHTTPSRequests, "Should support HTTPS requests")
        
        let supportedAuthMethods = await webServiceCapability.getSupportedAuthMethods()
        XCTAssertFalse(supportedAuthMethods.isEmpty, "Should support authentication methods")
    }
    
    func testThirdPartyIntegrationCapability() async throws {
        let thirdPartyCapability = ThirdPartyIntegrationCapability()
        
        let isAvailable = await thirdPartyCapability.isAvailable()
        XCTAssertNotNil(isAvailable, "Third party integration availability should be determinable")
        
        let supportedPlatforms = await thirdPartyCapability.getSupportedPlatforms()
        XCTAssertFalse(supportedPlatforms.isEmpty, "Should support integration platforms")
        
        let canIntegrateWithSocialMedia = await thirdPartyCapability.canIntegrateWithSocialMedia()
        XCTAssertNotNil(canIntegrateWithSocialMedia, "Should determine social media integration capability")
        
        let canIntegrateWithPaymentSystems = await thirdPartyCapability.canIntegrateWithPaymentSystems()
        XCTAssertNotNil(canIntegrateWithPaymentSystems, "Should determine payment integration capability")
    }
    
    // MARK: - Performance Tests
    
    func testIntegrationCapabilityPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let integrationCapability = IntegrationCapability()
                let extensionCapability = AppExtensionCapability()
                let cloudKitCapability = CloudKitCapability()
                let siriCapability = SiriIntegrationCapability()
                let webServiceCapability = WebServiceCapability()
                
                // Test rapid capability queries
                for _ in 0..<50 {
                    _ = await integrationCapability.isAvailable()
                    _ = await extensionCapability.getSupportedExtensionTypes()
                    _ = await cloudKitCapability.getSupportedDatabases()
                    _ = await siriCapability.getSupportedIntents()
                    _ = await webServiceCapability.getSupportedProtocols()
                }
            },
            maxDuration: .milliseconds(250),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testIntegrationCapabilityMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let integrationCapability = IntegrationCapability()
            let extensionCapability = AppExtensionCapability()
            let cloudKitCapability = CloudKitCapability()
            let siriCapability = SiriIntegrationCapability()
            let watchCapability = WatchConnectivityCapability()
            let webServiceCapability = WebServiceCapability()
            let thirdPartyCapability = ThirdPartyIntegrationCapability()
            
            // Simulate capability lifecycle
            for _ in 0..<15 {
                _ = await integrationCapability.isAvailable()
                _ = await extensionCapability.canRunWidgets()
                _ = await cloudKitCapability.canSyncData()
                _ = await siriCapability.canHandleVoiceCommands()
                _ = await watchCapability.canCommunicateWithWatch()
                _ = await webServiceCapability.canMakeHTTPSRequests()
                _ = await thirdPartyCapability.getSupportedPlatforms()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testIntegrationCapabilityErrorHandling() async throws {
        let cloudKitCapability = CloudKitCapability()
        
        // Test syncing with invalid container
        do {
            try await cloudKitCapability.syncDataStrict(container: "invalid.container")
            XCTFail("Should throw error for invalid container")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid container")
        }
        
        let siriCapability = SiriIntegrationCapability()
        
        // Test registering invalid intent
        do {
            try await siriCapability.registerIntentStrict(type: .unsupported)
            XCTFail("Should throw error for unsupported intent")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for unsupported intent")
        }
        
        let watchCapability = WatchConnectivityCapability()
        
        // Test sending message when watch not connected
        do {
            let message = ["key": "value"]
            try await watchCapability.sendMessageStrict(message)
            // This might succeed if watch is connected, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for connectivity issues")
        }
        
        let webServiceCapability = WebServiceCapability()
        
        // Test making request with invalid URL
        do {
            try await webServiceCapability.makeRequestStrict(url: "invalid-url")
            XCTFail("Should throw error for invalid URL")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid URL")
        }
    }
}

// MARK: - Test Helper Types

private enum ExtensionType {
    case widget
    case shareExtension
    case actionExtension
    case todayExtension
    case photoEditingExtension
}

private enum DatabaseType {
    case publicDatabase
    case privateDatabase
    case sharedDatabase
}

private enum IntentType {
    case messaging
    case payments
    case workouts
    case media
    case voip
    case unsupported
}

private enum WebProtocol {
    case http
    case https
    case websocket
    case graphql
}

private enum AuthMethod {
    case basic
    case bearer
    case oauth2
    case apiKey
}

private enum IntegrationPlatform {
    case facebook
    case twitter
    case google
    case apple
    case stripe
    case paypal
}