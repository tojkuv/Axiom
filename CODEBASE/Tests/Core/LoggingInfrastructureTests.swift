import XCTest
@testable import Axiom
import OSLog

/// Comprehensive tests for the logging infrastructure
class LoggingInfrastructureTests: XCTestCase {
    
    // MARK: - Core Logging API Tests
    
    func testLogLevelComparison() {
        // Test log level ordering
        XCTAssertLessThan(LogLevel.trace, LogLevel.debug)
        XCTAssertLessThan(LogLevel.debug, LogLevel.info)
        XCTAssertLessThan(LogLevel.info, LogLevel.warning)
        XCTAssertLessThan(LogLevel.warning, LogLevel.error)
        XCTAssertLessThan(LogLevel.error, LogLevel.critical)
    }
    
    func testLogLevelRawValues() {
        // Test log level raw values for ordering
        XCTAssertEqual(LogLevel.trace.rawValue, 0)
        XCTAssertEqual(LogLevel.debug.rawValue, 1)
        XCTAssertEqual(LogLevel.info.rawValue, 2)
        XCTAssertEqual(LogLevel.warning.rawValue, 3)
        XCTAssertEqual(LogLevel.error.rawValue, 4)
        XCTAssertEqual(LogLevel.critical.rawValue, 5)
    }
    
    func testLogMetadataCreation() {
        // Test metadata dictionary literal creation
        let metadata: LogMetadata = [
            "userId": PublicString("user123"),
            "action": PublicString("login"),
            "timestamp": PublicString("2025-01-11")
        ]
        
        XCTAssertEqual(metadata.values.count, 3)
        XCTAssertEqual(metadata.values["userId"]?.description, "user123")
        XCTAssertEqual(metadata.values["action"]?.description, "login")
    }
    
    func testLogCategoryCreation() {
        // Test standard log categories
        XCTAssertEqual(LogCategory.context.rawValue, "axiom.context")
        XCTAssertEqual(LogCategory.client.rawValue, "axiom.client")
        XCTAssertEqual(LogCategory.capability.rawValue, "axiom.capability")
        XCTAssertEqual(LogCategory.navigation.rawValue, "axiom.navigation")
        XCTAssertEqual(LogCategory.performance.rawValue, "axiom.performance")
        
        // Test custom category creation
        let customCategory = LogCategory(rawValue: "custom.test")
        XCTAssertEqual(customCategory.rawValue, "custom.test")
    }
    
    // MARK: - Privacy-Safe Logging Tests
    
    func testPrivateStringInDebug() {
        let privateData = PrivateString("sensitive-data")
        
        #if DEBUG
        XCTAssertEqual(privateData.description, "sensitive-data")
        #else
        XCTAssertEqual(privateData.description, "<private>")
        #endif
        
        XCTAssertTrue(privateData.isPrivate)
    }
    
    func testPublicStringLogging() {
        let publicData = PublicString("public-info")
        
        XCTAssertEqual(publicData.description, "public-info")
        XCTAssertFalse(publicData.isPrivate)
    }
    
    func testMixedPrivacyMetadata() {
        let metadata: LogMetadata = [
            "publicInfo": PublicString("visible"),
            "privateInfo": PrivateString("hidden"),
            "userId": PrivateString("user123")
        ]
        
        XCTAssertEqual(metadata.values.count, 3)
        XCTAssertFalse(metadata.values["publicInfo"]!.isPrivate)
        XCTAssertTrue(metadata.values["privateInfo"]!.isPrivate)
        XCTAssertTrue(metadata.values["userId"]!.isPrivate)
    }
    
    // MARK: - Category Logger Tests
    
    func testCategoryLoggerCreation() {
        let contextLogger = CategoryLogger.logger(for: .context)
        
        XCTAssertEqual(contextLogger.category, LogCategory.context)
        XCTAssertEqual(contextLogger.subsystem, "com.axiom.framework")
    }
    
    func testCategoryLoggerLogging() {
        let mockDestination = MockLogDestination()
        let logger = CategoryLogger(
            category: .client,
            subsystem: "test.axiom",
            destination: mockDestination
        )
        
        logger.log(.info, "Test message", metadata: nil)
        
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.level, .info)
        XCTAssertEqual(entry.message, "Test message")
        XCTAssertEqual(entry.category, .client)
    }
    
    // MARK: - Performance Logger Tests
    
    func testPerformanceTimingMeasurement() async throws {
        let mockDestination = MockLogDestination()
        let baseLogger = CategoryLogger(
            category: .performance,
            subsystem: "test.axiom",
            destination: mockDestination
        )
        let performanceLogger = PerformanceLogger(logger: baseLogger)
        
        let result = await performanceLogger.time("test_operation") {
            try await Task.sleep(for: .milliseconds(10))
            return "completed"
        }
        
        XCTAssertEqual(result, "completed")
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.level, .debug)
        XCTAssertTrue(entry.message.contains("test_operation"))
        XCTAssertTrue(entry.message.contains("took"))
    }
    
    func testPerformanceMemoryLogging() {
        let mockDestination = MockLogDestination()
        let baseLogger = CategoryLogger(
            category: .performance,
            subsystem: "test.axiom",
            destination: mockDestination
        )
        let performanceLogger = PerformanceLogger(logger: baseLogger)
        
        performanceLogger.memory("test_checkpoint")
        
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.level, .debug)
        XCTAssertTrue(entry.message.contains("Memory at 'test_checkpoint'"))
        XCTAssertTrue(entry.message.contains("MB"))
    }
    
    // MARK: - Log Configuration Tests
    
    func testDebugConfiguration() {
        let config = LogConfiguration.debug
        
        XCTAssertEqual(config.minimumLevel, .debug)
        XCTAssertTrue(config.enabledCategories.contains(.context))
        XCTAssertTrue(config.enabledCategories.contains(.client))
        XCTAssertEqual(config.outputDestination, .console)
    }
    
    func testReleaseConfiguration() {
        let config = LogConfiguration.release
        
        XCTAssertEqual(config.minimumLevel, .warning)
        XCTAssertTrue(config.enabledCategories.contains(.error))
        XCTAssertTrue(config.enabledCategories.contains(.performance))
        XCTAssertEqual(config.outputDestination, .oslog)
    }
    
    func testConfigurationFiltering() {
        let config = LogConfiguration(
            minimumLevel: .warning,
            enabledCategories: [.context, .client],
            outputDestination: .console
        )
        
        XCTAssertTrue(config.shouldLog(level: .warning, category: .context))
        XCTAssertTrue(config.shouldLog(level: .error, category: .client))
        XCTAssertFalse(config.shouldLog(level: .debug, category: .context))
        XCTAssertFalse(config.shouldLog(level: .warning, category: .capability))
    }
    
    // MARK: - Integration Tests
    
    func testContextLoggingIntegration() async {
        // Test that Context protocol gets logging extensions
        let mockDestination = MockLogDestination()
        await LogManager.shared.setDestination(mockDestination)
        
        let context = TestContext()
        context.logLifecycle("initialized")
        
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.category, .context)
        XCTAssertTrue(entry.message.contains("TestContext"))
        XCTAssertTrue(entry.message.contains("initialized"))
    }
    
    func testClientLoggingIntegration() async {
        // Test that Client protocol gets logging extensions
        let mockDestination = MockLogDestination()
        await LogManager.shared.setDestination(mockDestination)
        
        let client = TestClient()
        await client.logAction(TestAction.testAction)
        
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.category, .client)
        XCTAssertTrue(entry.message.contains("Processing action"))
        XCTAssertTrue(entry.message.contains("testAction"))
    }
    
    func testCapabilityLoggingIntegration() async {
        // Test that Capability protocol gets logging extensions
        let mockDestination = MockLogDestination()
        await LogManager.shared.setDestination(mockDestination)
        
        let capability = TestCapability()
        await capability.logStateTransition(from: "unknown", to: "available")
        
        XCTAssertEqual(mockDestination.loggedMessages.count, 1)
        let entry = mockDestination.loggedMessages.first!
        XCTAssertEqual(entry.category, .capability)
        XCTAssertTrue(entry.message.contains("State transition"))
        XCTAssertTrue(entry.message.contains("unknown"))
        XCTAssertTrue(entry.message.contains("available"))
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformanceWithDisabledLevel() {
        let config = LogConfiguration(
            minimumLevel: .error,
            enabledCategories: [.context],
            outputDestination: .console
        )
        
        let mockDestination = MockLogDestination()
        let logger = CategoryLogger(
            category: .context,
            subsystem: "test.performance",
            destination: mockDestination,
            configuration: config
        )
        
        // Measure performance of disabled log level
        measure {
            for _ in 0..<1000 {
                logger.log(.debug, "This should be ignored", metadata: nil)
            }
        }
        
        // Verify no messages were logged
        XCTAssertEqual(mockDestination.loggedMessages.count, 0)
    }
    
    func testLoggingPerformanceWithEnabledLevel() {
        let config = LogConfiguration(
            minimumLevel: .debug,
            enabledCategories: [.context],
            outputDestination: .console
        )
        
        let mockDestination = MockLogDestination()
        let logger = CategoryLogger(
            category: .context,
            subsystem: "test.performance",
            destination: mockDestination,
            configuration: config
        )
        
        // Measure performance of enabled log level
        measure {
            for _ in 0..<100 {
                logger.log(.debug, "Performance test message", metadata: nil)
            }
        }
        
        // Verify messages were logged
        XCTAssertEqual(mockDestination.loggedMessages.count, 100)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLogging() async {
        let mockDestination = MockLogDestination()
        let logger = CategoryLogger(
            category: .client,
            subsystem: "test.concurrent",
            destination: mockDestination
        )
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    logger.log(.info, "Concurrent message \(i)", metadata: nil)
                }
            }
        }
        
        // All messages should be logged
        XCTAssertEqual(mockDestination.loggedMessages.count, 50)
        
        // Check that all messages are present (order may vary)
        let messageNumbers = mockDestination.loggedMessages.compactMap { entry in
            entry.message.range(of: #"Concurrent message (\d+)"#, options: .regularExpression)
                .map { String(entry.message[$0]).components(separatedBy: " ").last }
        }
        
        XCTAssertEqual(Set(messageNumbers).count, 50)
    }
}

// MARK: - Test Helpers

class MockLogDestination: LogDestination {
    private(set) var loggedMessages: [LogEntry] = []
    private let queue = DispatchQueue(label: "mock.log.destination", attributes: .concurrent)
    
    func write(_ entry: LogEntry) {
        queue.async(flags: .barrier) {
            self.loggedMessages.append(entry)
        }
    }
    
    func flush() {
        // Synchronous operation for testing
        queue.sync(flags: .barrier) {}
    }
}


// Test implementations
class TestContext: Context {
    func handleChildAction<T>(_ action: T, from child: any Context) where T : Sendable {
        // Test implementation
    }
}

enum TestAction {
    case testAction
}

actor TestClient: Client {
    typealias StateType = String
    typealias ActionType = TestAction
    
    var stateStream: AsyncStream<String> {
        AsyncStream { _ in }
    }
    
    func process(_ action: TestAction) async throws {
        // Test implementation
    }
}

actor TestCapability: Capability {
    var isAvailable: Bool { true }
    
    func activate() async throws {
        // Test implementation
    }
    
    func deactivate() async {
        // Test implementation
    }
}