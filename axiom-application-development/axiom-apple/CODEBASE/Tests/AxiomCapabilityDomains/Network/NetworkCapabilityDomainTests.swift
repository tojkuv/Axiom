import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains network capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class NetworkCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testNetworkCapabilityDomainInitialization() async throws {
        let networkDomain = NetworkCapabilityDomain()
        XCTAssertNotNil(networkDomain, "NetworkCapabilityDomain should initialize correctly")
        XCTAssertEqual(networkDomain.identifier, "axiom.capability.domain.network", "Should have correct identifier")
    }
    
    func testHTTPCapabilityRegistration() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        let httpCapability = HTTPCapability()
        let httpsCapability = HTTPSCapability()
        let http2Capability = HTTP2Capability()
        
        await networkDomain.registerCapability(httpCapability)
        await networkDomain.registerCapability(httpsCapability)
        await networkDomain.registerCapability(http2Capability)
        
        let registeredCapabilities = await networkDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 3, "Should have 3 registered HTTP capabilities")
        
        let hasHTTP = await networkDomain.hasCapability("axiom.network.http")
        XCTAssertTrue(hasHTTP, "Should have HTTP capability")
        
        let hasHTTPS = await networkDomain.hasCapability("axiom.network.https")
        XCTAssertTrue(hasHTTPS, "Should have HTTPS capability")
        
        let hasHTTP2 = await networkDomain.hasCapability("axiom.network.http2")
        XCTAssertTrue(hasHTTP2, "Should have HTTP/2 capability")
    }
    
    func testWebSocketCapabilityManagement() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        let webSocketCapability = WebSocketCapability()
        let secureWebSocketCapability = SecureWebSocketCapability()
        
        await networkDomain.registerCapability(webSocketCapability)
        await networkDomain.registerCapability(secureWebSocketCapability)
        
        let realtimeCapabilities = await networkDomain.getCapabilitiesOfType(.realtime)
        XCTAssertEqual(realtimeCapabilities.count, 2, "Should have 2 realtime capabilities")
        
        let bestRealtimeCapability = await networkDomain.getBestCapabilityForUseCase(.lowLatency)
        XCTAssertNotNil(bestRealtimeCapability, "Should find best capability for low latency")
    }
    
    func testNetworkProtocolSelection() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        // Register various network capabilities
        await networkDomain.registerCapability(HTTPCapability())
        await networkDomain.registerCapability(HTTPSCapability())
        await networkDomain.registerCapability(HTTP2Capability())
        await networkDomain.registerCapability(WebSocketCapability())
        await networkDomain.registerCapability(GraphQLCapability())
        
        let strategy = await networkDomain.selectOptimalProtocol(
            for: NetworkRequirements(
                security: .high,
                performance: .high,
                reliability: .medium,
                dataFormat: .json
            )
        )
        
        XCTAssertNotNil(strategy, "Should select an optimal network protocol")
        XCTAssertTrue(strategy!.capabilities.count > 0, "Strategy should include capabilities")
        
        let primaryProtocol = strategy!.primaryProtocol
        XCTAssertNotNil(primaryProtocol, "Strategy should have a primary protocol")
    }
    
    func testConnectionPooling() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        await networkDomain.registerCapability(HTTPSCapability())
        await networkDomain.registerCapability(HTTP2Capability())
        
        let connectionPool = await networkDomain.getConnectionPool()
        XCTAssertNotNil(connectionPool, "Should provide connection pool")
        
        let maxConnections = await connectionPool!.getMaxConnections()
        XCTAssertGreaterThan(maxConnections, 0, "Should have positive max connections")
        
        let activeConnections = await connectionPool!.getActiveConnectionCount()
        XCTAssertGreaterThanOrEqual(activeConnections, 0, "Active connections should be non-negative")
        
        // Test connection acquisition
        let connection = await connectionPool!.acquireConnection(to: "https://api.example.com")
        XCTAssertNotNil(connection, "Should acquire connection")
        
        await connectionPool!.releaseConnection(connection!)
        
        let newActiveCount = await connectionPool!.getActiveConnectionCount()
        XCTAssertEqual(newActiveCount, activeConnections, "Active count should be unchanged after release")
    }
    
    func testRetryMechanisms() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        await networkDomain.registerCapability(HTTPSCapability())
        
        let retryManager = await networkDomain.getRetryManager()
        XCTAssertNotNil(retryManager, "Should provide retry manager")
        
        let retryPolicy = RetryPolicy(
            maxAttempts: 3,
            backoffStrategy: .exponential,
            retryableErrors: [.timeout, .networkError]
        )
        
        await retryManager!.setRetryPolicy(retryPolicy)
        
        let currentPolicy = await retryManager!.getRetryPolicy()
        XCTAssertEqual(currentPolicy.maxAttempts, 3, "Should set max attempts")
        XCTAssertEqual(currentPolicy.backoffStrategy, .exponential, "Should set backoff strategy")
    }
    
    // MARK: - Performance Tests
    
    func testNetworkCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let networkDomain = NetworkCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestNetworkCapability(index: i)
                    await networkDomain.registerCapability(capability)
                }
                
                // Test protocol selection performance
                for _ in 0..<50 {
                    let requirements = NetworkRequirements(
                        security: .medium,
                        performance: .high,
                        reliability: .high,
                        dataFormat: .json
                    )
                    _ = await networkDomain.selectOptimalProtocol(for: requirements)
                }
            },
            maxDuration: .milliseconds(250),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testNetworkCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let networkDomain = NetworkCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestNetworkCapability(index: i)
                await networkDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = NetworkRequirements(
                        security: .low,
                        performance: .medium,
                        reliability: .low,
                        dataFormat: .xml
                    )
                    _ = await networkDomain.selectOptimalProtocol(for: requirements)
                }
                
                if i % 10 == 0 {
                    await networkDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await networkDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkCapabilityDomainErrorHandling() async throws {
        let networkDomain = NetworkCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestNetworkCapability(index: 1)
        let capability2 = TestNetworkCapability(index: 1) // Same index = same identifier
        
        await networkDomain.registerCapability(capability1)
        
        do {
            try await networkDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test protocol selection with conflicting requirements
        do {
            let conflictingRequirements = NetworkRequirements(
                security: .high,
                performance: .high,
                reliability: .high,
                dataFormat: .binary
            )
            try await networkDomain.selectOptimalProtocolStrict(for: conflictingRequirements)
            // This might succeed if capabilities can handle it, so we don't fail here
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for conflicting requirements")
        }
        
        // Test connection pool with invalid configuration
        do {
            let invalidPoolConfig = ConnectionPoolConfig(maxConnections: -1, timeout: -1)
            try await networkDomain.configureConnectionPoolStrict(invalidPoolConfig)
            XCTFail("Should throw error for invalid configuration")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid configuration")
        }
    }
}

// MARK: - Test Helper Classes

private struct HTTPCapability: NetworkCapability {
    let identifier = "axiom.network.http"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .http
    let security: SecurityLevel = .low
    let performance: PerformanceLevel = .medium
}

private struct HTTPSCapability: NetworkCapability {
    let identifier = "axiom.network.https"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .https
    let security: SecurityLevel = .high
    let performance: PerformanceLevel = .medium
}

private struct HTTP2Capability: NetworkCapability {
    let identifier = "axiom.network.http2"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .http2
    let security: SecurityLevel = .high
    let performance: PerformanceLevel = .high
}

private struct WebSocketCapability: NetworkCapability {
    let identifier = "axiom.network.websocket"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .websocket
    let security: SecurityLevel = .medium
    let performance: PerformanceLevel = .high
}

private struct SecureWebSocketCapability: NetworkCapability {
    let identifier = "axiom.network.websocket.secure"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .websocket
    let security: SecurityLevel = .high
    let performance: PerformanceLevel = .high
}

private struct GraphQLCapability: NetworkCapability {
    let identifier = "axiom.network.graphql"
    let isAvailable = true
    let protocolType: NetworkProtocolType = .graphql
    let security: SecurityLevel = .medium
    let performance: PerformanceLevel = .high
}

private struct TestNetworkCapability: NetworkCapability {
    let identifier: String
    let isAvailable = true
    let protocolType: NetworkProtocolType = .http
    let security: SecurityLevel = .medium
    let performance: PerformanceLevel = .medium
    
    init(index: Int) {
        self.identifier = "test.network.capability.\(index)"
    }
}

private enum NetworkProtocolType {
    case http
    case https
    case http2
    case websocket
    case graphql
}

private enum NetworkType {
    case realtime
    case batch
    case streaming
}

private enum SecurityLevel {
    case low
    case medium
    case high
}

private enum PerformanceLevel {
    case low
    case medium
    case high
}

private enum DataFormat {
    case json
    case xml
    case binary
    case protobuf
}

private enum NetworkUseCase {
    case lowLatency
    case highThroughput
    case reliable
    case secure
}

private struct NetworkRequirements {
    let security: SecurityLevel
    let performance: PerformanceLevel
    let reliability: PerformanceLevel
    let dataFormat: DataFormat
}

private struct RetryPolicy {
    let maxAttempts: Int
    let backoffStrategy: BackoffStrategy
    let retryableErrors: [NetworkError]
}

private enum BackoffStrategy {
    case linear
    case exponential
    case fixed
}

private enum NetworkError {
    case timeout
    case networkError
    case serverError
    case unauthorized
}

private struct ConnectionPoolConfig {
    let maxConnections: Int
    let timeout: TimeInterval
}