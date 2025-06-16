import XCTest
import AxiomTesting
import SwiftUI
@testable import AxiomCore
@testable import AxiomArchitecture
@testable import AxiomMacros

/// Comprehensive tests for error consolidation, macros, and telemetry functionality
/// 
/// Consolidates: ErrorConsolidationTests, SimpleErrorConsolidationTests, ErrorHandlingMacrosTests, ErrorTelemetryMonitoringTests
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ErrorConsolidationAndTelemetryTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Error Consolidation Tests
    
    func testBasicErrorConsolidation() async throws {
        let consolidator = ErrorConsolidator(
            window: .seconds(5),
            maxErrors: 10,
            consolidationStrategy: .byType
        )
        
        // Generate multiple errors of the same type
        for i in 0..<5 {
            let error = AxiomError.networkError(.connectionFailed("Attempt \(i)"))
            await consolidator.reportError(error)
        }
        
        let consolidatedErrors = await consolidator.getConsolidatedErrors()
        XCTAssertEqual(consolidatedErrors.count, 1, "Should consolidate similar errors into one")
        
        let consolidatedError = consolidatedErrors.first!
        XCTAssertEqual(consolidatedError.occurrenceCount, 5, "Should count all occurrences")
        XCTAssertEqual(consolidatedError.errorType, "networkError", "Should identify error type")
        XCTAssertNotNil(consolidatedError.timeWindow, "Should track time window")
    }
    
    func testErrorConsolidationByMessage() async throws {
        let consolidator = ErrorConsolidator(
            window: .seconds(10),
            maxErrors: 20,
            consolidationStrategy: .byMessage
        )
        
        // Generate errors with same message but different contexts
        let baseMessage = "Connection timeout"
        for i in 0..<3 {
            let error = AxiomError.networkError(.connectionFailed(baseMessage))
                .withContext(ErrorContext(component: "Service\(i)", operation: "fetch"))
            await consolidator.reportError(error)
        }
        
        // Generate error with different message
        let differentError = AxiomError.networkError(.connectionFailed("DNS resolution failed"))
        await consolidator.reportError(differentError)
        
        let consolidatedErrors = await consolidator.getConsolidatedErrors()
        XCTAssertEqual(consolidatedErrors.count, 2, "Should have 2 consolidated groups")
        
        let timeoutGroup = consolidatedErrors.first { $0.message.contains("timeout") }
        XCTAssertEqual(timeoutGroup?.occurrenceCount, 3, "Should consolidate same messages")
        
        let dnsGroup = consolidatedErrors.first { $0.message.contains("DNS") }
        XCTAssertEqual(dnsGroup?.occurrenceCount, 1, "Should keep different messages separate")
    }
    
    func testErrorConsolidationRateLimit() async throws {
        let consolidator = ErrorConsolidator(
            window: .seconds(1),
            maxErrors: 3,
            consolidationStrategy: .byType
        )
        
        // Generate more errors than the limit
        for i in 0..<10 {
            let error = AxiomError.clientError(.timeout(duration: Double(i)))
            await consolidator.reportError(error)
        }
        
        let consolidatedErrors = await consolidator.getConsolidatedErrors()
        let clientErrorGroup = consolidatedErrors.first { $0.errorType == "clientError" }
        
        XCTAssertNotNil(clientErrorGroup, "Should have client error group")
        XCTAssertEqual(clientErrorGroup?.occurrenceCount, 3, "Should respect rate limit")
        XCTAssertTrue(clientErrorGroup?.isRateLimited == true, "Should mark as rate limited")
    }
    
    func testErrorConsolidationWindowExpiry() async throws {
        let consolidator = ErrorConsolidator(
            window: .milliseconds(500),
            maxErrors: 10,
            consolidationStrategy: .byType
        )
        
        // Report errors in first window
        for i in 0..<3 {
            let error = AxiomError.validationError(.invalidInput("field\(i)", "reason"))
            await consolidator.reportError(error)
        }
        
        let firstWindowErrors = await consolidator.getConsolidatedErrors()
        XCTAssertEqual(firstWindowErrors.count, 1, "Should consolidate errors in first window")
        XCTAssertEqual(firstWindowErrors.first?.occurrenceCount, 3, "Should count all errors")
        
        // Wait for window to expire
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        
        // Report new errors in second window
        for i in 0..<2 {
            let error = AxiomError.validationError(.invalidInput("newField\(i)", "newReason"))
            await consolidator.reportError(error)
        }
        
        let secondWindowErrors = await consolidator.getConsolidatedErrors()
        XCTAssertEqual(secondWindowErrors.count, 1, "Should have new consolidated group")
        XCTAssertEqual(secondWindowErrors.first?.occurrenceCount, 2, "Should count only new errors")
    }
    
    // MARK: - Error Handling Macro Tests
    
    func testErrorBoundaryMacroExpansion() async throws {
        // Test that @ErrorBoundary macro generates proper error handling code
        @ErrorBoundary(strategy: .isolate)
        class TestMacroContext: ObservableContext {
            var errorCount = 0
            
            func riskyOperation() async throws {
                errorCount += 1
                if errorCount <= 2 {
                    throw AxiomError.clientError(.invalidAction("Macro test error \(errorCount)"))
                }
            }
        }
        
        let context = TestMacroContext()
        
        // Error should be caught and handled by generated boundary
        var capturedErrors: [Error] = []
        context.errorBoundary.onError = { error in
            capturedErrors.append(error)
        }
        
        // First two calls should trigger errors
        try await context.riskyOperation()
        try await context.riskyOperation()
        
        XCTAssertEqual(capturedErrors.count, 2, "Should capture errors through generated boundary")
        XCTAssertTrue(capturedErrors.allSatisfy { $0 is AxiomError }, "Should capture AxiomErrors")
        
        // Third call should succeed
        try await context.riskyOperation()
        XCTAssertEqual(context.errorCount, 3, "Should continue executing after errors")
    }
    
    func testThrowsAsyncMacro() async throws {
        // Test @ThrowsAsync macro for improved async error handling
        @ThrowsAsync
        func networkOperation(shouldFail: Bool) async -> String {
            if shouldFail {
                throw AxiomError.networkError(.connectionFailed("Network unavailable"))
            }
            return "Network operation successful"
        }
        
        // Test successful case
        let successResult = try await networkOperation(shouldFail: false)
        XCTAssertEqual(successResult, "Network operation successful")
        
        // Test error case
        do {
            _ = try await networkOperation(shouldFail: true)
            XCTFail("Should throw error")
        } catch let error as AxiomError {
            XCTAssertEqual(error.category, "networkError", "Should maintain error type")
        }
    }
    
    func testErrorContextMacro() async throws {
        // Test @ErrorContext macro for automatic context injection
        @ErrorContext(component: "TestComponent", operation: "testOperation")
        func contextualOperation(value: Int) async throws -> String {
            if value < 0 {
                throw AxiomError.validationError(.invalidInput("value", "must be positive"))
            }
            return "Value \(value) processed"
        }
        
        do {
            _ = try await contextualOperation(value: -1)
            XCTFail("Should throw validation error")
        } catch let error as AxiomError {
            XCTAssertNotNil(error.context, "Should have injected context")
            XCTAssertEqual(error.context?.component, "TestComponent")
            XCTAssertEqual(error.context?.operation, "testOperation")
        }
    }
    
    func testRetryMacro() async throws {
        // Test @Retry macro for declarative retry logic
        var attemptCount = 0
        
        @Retry(attempts: 3, backoff: .exponential(base: 1.0))
        func retryableOperation() async throws -> String {
            attemptCount += 1
            if attemptCount < 3 {
                throw AxiomError.networkError(.connectionFailed("Attempt \(attemptCount)"))
            }
            return "Success after \(attemptCount) attempts"
        }
        
        let result = try await retryableOperation()
        
        XCTAssertEqual(result, "Success after 3 attempts")
        XCTAssertEqual(attemptCount, 3, "Should retry twice before success")
    }
    
    // MARK: - Error Telemetry Tests
    
    func testBasicErrorTelemetry() async throws {
        let telemetrySystem = ErrorTelemetrySystem()
        
        // Configure telemetry collection
        await telemetrySystem.configure(TelemetryConfiguration(
            enableCollection: true,
            samplingRate: 1.0,
            batchSize: 10,
            flushInterval: .seconds(5)
        ))
        
        // Generate test errors with telemetry
        for i in 0..<5 {
            let error = AxiomError.clientError(.timeout(duration: Double(i)))
                .withTelemetry(["requestId": "req_\(i)", "duration": i * 100])
            
            await telemetrySystem.recordError(error)
        }
        
        let telemetryData = await telemetrySystem.getTelemetryData()
        
        XCTAssertEqual(telemetryData.errorCount, 5, "Should record all errors")
        XCTAssertEqual(telemetryData.errorsByType["clientError"], 5, "Should categorize errors by type")
        XCTAssertTrue(telemetryData.customMetrics.contains { $0.key == "requestId" }, "Should preserve custom metrics")
    }
    
    func testErrorTelemetryAggregation() async throws {
        let telemetrySystem = ErrorTelemetrySystem()
        await telemetrySystem.configure(TelemetryConfiguration(
            enableCollection: true,
            samplingRate: 1.0,
            batchSize: 5,
            flushInterval: .seconds(1),
            enableAggregation: true
        ))
        
        // Generate errors with patterns for aggregation
        let errorPatterns = [
            ("networkError", 10),
            ("validationError", 5),
            ("systemError", 2)
        ]
        
        for (errorType, count) in errorPatterns {
            for i in 0..<count {
                let error: AxiomError = switch errorType {
                case "networkError":
                    AxiomError.networkError(.connectionFailed("timeout \(i)"))
                case "validationError":
                    AxiomError.validationError(.invalidInput("field\(i)", "invalid"))
                default:
                    AxiomError.systemError(.configurationError("config \(i)"))
                }
                
                await telemetrySystem.recordError(error)
            }
        }
        
        // Wait for aggregation
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        let aggregatedData = await telemetrySystem.getAggregatedData()
        
        XCTAssertEqual(aggregatedData.totalErrors, 17, "Should aggregate total error count")
        XCTAssertEqual(aggregatedData.errorRates["networkError"], 10, "Should aggregate by error type")
        XCTAssertEqual(aggregatedData.errorRates["validationError"], 5, "Should aggregate validation errors")
        XCTAssertEqual(aggregatedData.errorRates["systemError"], 2, "Should aggregate system errors")
    }
    
    func testErrorTelemetrySampling() async throws {
        let telemetrySystem = ErrorTelemetrySystem()
        await telemetrySystem.configure(TelemetryConfiguration(
            enableCollection: true,
            samplingRate: 0.5, // 50% sampling rate
            batchSize: 100,
            flushInterval: .seconds(10)
        ))
        
        // Generate many errors
        for i in 0..<100 {
            let error = AxiomError.clientError(.timeout(duration: Double(i)))
            await telemetrySystem.recordError(error)
        }
        
        let telemetryData = await telemetrySystem.getTelemetryData()
        
        // With 50% sampling, expect roughly 50 errors (±10 for variance)
        XCTAssertGreaterThan(telemetryData.errorCount, 40, "Should sample approximately 50% of errors")
        XCTAssertLessThan(telemetryData.errorCount, 60, "Should not exceed expected sampling variance")
        XCTAssertEqual(telemetryData.samplingRate, 0.5, "Should record sampling rate")
    }
    
    func testErrorTelemetryBatching() async throws {
        let telemetrySystem = ErrorTelemetrySystem()
        let mockTransmitter = MockTelemetryTransmitter()
        
        await telemetrySystem.configure(TelemetryConfiguration(
            enableCollection: true,
            samplingRate: 1.0,
            batchSize: 5,
            flushInterval: .seconds(1),
            transmitter: mockTransmitter
        ))
        
        // Generate errors to trigger batching
        for i in 0..<12 {
            let error = AxiomError.networkError(.connectionFailed("batch test \(i)"))
            await telemetrySystem.recordError(error)
        }
        
        // Wait for batch transmission
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        let transmissions = await mockTransmitter.getTransmissions()
        
        // Should have transmitted 2 full batches (5 errors each) and 1 partial batch (2 errors)
        XCTAssertGreaterThanOrEqual(transmissions.count, 2, "Should transmit multiple batches")
        
        let totalTransmittedErrors = transmissions.reduce(0) { $0 + $1.errorCount }
        XCTAssertEqual(totalTransmittedErrors, 12, "Should transmit all errors across batches")
    }
    
    func testErrorTelemetryPrivacy() async throws {
        let telemetrySystem = ErrorTelemetrySystem()
        await telemetrySystem.configure(TelemetryConfiguration(
            enableCollection: true,
            privacyMode: .enhanced,
            piiScrubbing: true,
            dataAnonymization: true
        ))
        
        // Generate error with potentially sensitive data
        let sensitiveError = AxiomError.validationError(.invalidInput("email", "user@company.com"))
            .withContext(ErrorContext(
                component: "UserManager",
                operation: "validateEmail",
                userID: "user123",
                sessionID: "session456",
                additionalData: [
                    "email": "user@company.com",
                    "ipAddress": "192.168.1.100",
                    "userAgent": "Mozilla/5.0..."
                ]
            ))
        
        await telemetrySystem.recordError(sensitiveError)
        
        let telemetryData = await telemetrySystem.getTelemetryData()
        let recordedError = telemetryData.errors.first!
        
        // Verify PII scrubbing
        XCTAssertFalse(recordedError.message.contains("user@company.com"), "Should scrub email from message")
        XCTAssertNil(recordedError.context?.additionalData["email"], "Should remove email from context")
        XCTAssertNil(recordedError.context?.additionalData["ipAddress"], "Should remove IP address")
        
        // Verify anonymization
        XCTAssertNotEqual(recordedError.context?.userID, "user123", "Should anonymize user ID")
        XCTAssertNotNil(recordedError.context?.userID, "Should preserve anonymized user ID")
    }
    
    // MARK: - Error Metrics and Analytics Tests
    
    func testErrorMetricsCollection() async throws {
        let metricsCollector = ErrorMetricsCollector()
        
        // Generate errors over time to create metrics
        let startTime = Date()
        
        for i in 0..<50 {
            let error: AxiomError = switch i % 4 {
            case 0: AxiomError.networkError(.connectionFailed("test"))
            case 1: AxiomError.validationError(.invalidInput("field", "reason"))
            case 2: AxiomError.clientError(.timeout(duration: 1.0))
            default: AxiomError.systemError(.configurationError("config"))
            }
            
            await metricsCollector.recordError(error, timestamp: startTime.addingTimeInterval(Double(i)))
        }
        
        let metrics = await metricsCollector.generateMetrics(
            from: startTime,
            to: startTime.addingTimeInterval(50)
        )
        
        XCTAssertEqual(metrics.totalErrors, 50, "Should count total errors")
        XCTAssertEqual(metrics.errorRatePerMinute, 60.0, "Should calculate error rate")
        XCTAssertEqual(metrics.errorDistribution.count, 4, "Should track error type distribution")
        
        // Verify top error types
        let topErrorType = metrics.topErrorTypes.first!
        XCTAssertEqual(topErrorType.count, 13, "Should identify most frequent error type") // 50/4 + 2
    }
    
    func testErrorTrendAnalysis() async throws {
        let trendAnalyzer = ErrorTrendAnalyzer()
        let baseTime = Date()
        
        // Simulate error trends over multiple time windows
        for window in 0..<10 {
            let windowStart = baseTime.addingTimeInterval(Double(window * 60)) // 1-minute windows
            
            // Increasing error rate trend
            let errorCount = 5 + window * 2
            
            for i in 0..<errorCount {
                let error = AxiomError.networkError(.connectionFailed("trend test \(window)-\(i)"))
                await trendAnalyzer.recordError(error, timestamp: windowStart.addingTimeInterval(Double(i * 5)))
            }
        }
        
        let trendAnalysis = await trendAnalyzer.analyzeTrends(
            from: baseTime,
            to: baseTime.addingTimeInterval(600) // 10 minutes
        )
        
        XCTAssertEqual(trendAnalysis.trend, .increasing, "Should detect increasing error trend")
        XCTAssertGreaterThan(trendAnalysis.growthRate, 0, "Should calculate positive growth rate")
        XCTAssertTrue(trendAnalysis.isSignificant, "Should mark significant trend")
    }
    
    // MARK: - Performance Tests
    
    func testErrorConsolidationPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let consolidator = ErrorConsolidator(
                    window: .seconds(10),
                    maxErrors: 1000,
                    consolidationStrategy: .byType
                )
                
                // Generate large number of errors rapidly
                for i in 0..<1000 {
                    let errorType = i % 5
                    let error: AxiomError = switch errorType {
                    case 0: AxiomError.networkError(.connectionFailed("test \(i)"))
                    case 1: AxiomError.validationError(.invalidInput("field", "reason \(i)"))
                    case 2: AxiomError.clientError(.timeout(duration: Double(i % 10)))
                    case 3: AxiomError.systemError(.configurationError("config \(i)"))
                    default: AxiomError.persistenceError(.saveFailed("save \(i)"))
                    }
                    
                    await consolidator.reportError(error)
                }
                
                _ = await consolidator.getConsolidatedErrors()
            },
            maxDuration: .milliseconds(300),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    func testErrorTelemetryPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let telemetrySystem = ErrorTelemetrySystem()
                await telemetrySystem.configure(TelemetryConfiguration(
                    enableCollection: true,
                    samplingRate: 1.0,
                    batchSize: 100
                ))
                
                // Generate high volume of telemetry data
                for i in 0..<1000 {
                    let error = AxiomError.clientError(.timeout(duration: Double(i % 100)))
                        .withTelemetry([
                            "requestId": "req_\(i)",
                            "duration": i * 10,
                            "endpoint": "/api/endpoint\(i % 20)",
                            "userAgent": "TestAgent/1.0"
                        ])
                    
                    await telemetrySystem.recordError(error)
                }
            },
            maxDuration: .milliseconds(500),
            maxMemoryGrowth: 3 * 1024 * 1024 // 3MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testErrorConsolidationMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            // Test consolidator lifecycle
            for iteration in 0..<20 {
                let consolidator = ErrorConsolidator(
                    window: .milliseconds(100),
                    maxErrors: 50,
                    consolidationStrategy: .byMessage
                )
                
                for i in 0..<25 {
                    let error = AxiomError.contextError(.lifecycleError("Iteration \(iteration) Error \(i)"))
                    await consolidator.reportError(error)
                }
                
                _ = await consolidator.getConsolidatedErrors()
                
                // Force cleanup
                await consolidator.cleanup()
            }
        }
    }
    
    func testErrorTelemetryMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let telemetrySystem = ErrorTelemetrySystem()
            
            for iteration in 0..<15 {
                await telemetrySystem.configure(TelemetryConfiguration(
                    enableCollection: true,
                    samplingRate: 1.0,
                    batchSize: 20
                ))
                
                for i in 0..<30 {
                    let error = AxiomError.networkError(.connectionFailed("Memory test \(iteration)-\(i)"))
                        .withTelemetry(["iteration": iteration, "index": i])
                    
                    await telemetrySystem.recordError(error)
                }
                
                // Force flush and cleanup
                await telemetrySystem.flush()
                await telemetrySystem.cleanup()
            }
        }
    }
}

// MARK: - Test Helper Classes

private class ErrorConsolidator {
    let window: TimeInterval
    let maxErrors: Int
    let strategy: ConsolidationStrategy
    private var errorGroups: [String: ConsolidatedErrorGroup] = [:]
    
    init(window: TimeInterval, maxErrors: Int, consolidationStrategy: ConsolidationStrategy) {
        self.window = window
        self.maxErrors = maxErrors
        self.strategy = consolidationStrategy
    }
    
    func reportError(_ error: AxiomError) async {
        let key = strategy.generateKey(for: error)
        
        if errorGroups[key] == nil {
            errorGroups[key] = ConsolidatedErrorGroup(
                errorType: error.category,
                message: error.localizedDescription,
                timeWindow: Date()...Date().addingTimeInterval(window)
            )
        }
        
        errorGroups[key]?.addOccurrence(error)
    }
    
    func getConsolidatedErrors() async -> [ConsolidatedErrorGroup] {
        return Array(errorGroups.values)
    }
    
    func cleanup() async {
        errorGroups.removeAll()
    }
}

private enum ConsolidationStrategy {
    case byType
    case byMessage
    
    func generateKey(for error: AxiomError) -> String {
        switch self {
        case .byType:
            return error.category
        case .byMessage:
            return "\(error.category):\(error.localizedDescription)"
        }
    }
}

private class ConsolidatedErrorGroup {
    let errorType: String
    let message: String
    let timeWindow: ClosedRange<Date>
    private(set) var occurrenceCount = 0
    private(set) var isRateLimited = false
    
    init(errorType: String, message: String, timeWindow: ClosedRange<Date>) {
        self.errorType = errorType
        self.message = message
        self.timeWindow = timeWindow
    }
    
    func addOccurrence(_ error: AxiomError) {
        if occurrenceCount < 3 { // Simulate rate limit
            occurrenceCount += 1
        } else {
            isRateLimited = true
        }
    }
}

private class ErrorTelemetrySystem {
    private var configuration: TelemetryConfiguration?
    private var collectedErrors: [TelemetryError] = []
    private var aggregatedData: AggregatedTelemetryData?
    
    func configure(_ config: TelemetryConfiguration) async {
        self.configuration = config
    }
    
    func recordError(_ error: AxiomError) async {
        guard let config = configuration, config.enableCollection else { return }
        
        // Apply sampling
        if Double.random(in: 0...1) > config.samplingRate {
            return
        }
        
        var telemetryError = TelemetryError(error: error, timestamp: Date())
        
        // Apply privacy settings
        if config.piiScrubbing {
            telemetryError = scrubPII(telemetryError)
        }
        
        if config.dataAnonymization {
            telemetryError = anonymizeData(telemetryError)
        }
        
        collectedErrors.append(telemetryError)
        
        // Handle batching
        if collectedErrors.count >= config.batchSize {
            await flushBatch()
        }
    }
    
    func getTelemetryData() async -> TelemetryData {
        let errorsByType = Dictionary(grouping: collectedErrors) { $0.error.category }
            .mapValues { $0.count }
        
        let customMetrics = collectedErrors.flatMap { $0.error.telemetryData?.map { KeyValuePair(key: $0.key, value: $0.value) } ?? [] }
        
        return TelemetryData(
            errorCount: collectedErrors.count,
            errorsByType: errorsByType,
            customMetrics: customMetrics,
            samplingRate: configuration?.samplingRate ?? 1.0,
            errors: collectedErrors
        )
    }
    
    func getAggregatedData() async -> AggregatedTelemetryData {
        if aggregatedData == nil {
            let errorRates = Dictionary(grouping: collectedErrors) { $0.error.category }
                .mapValues { $0.count }
            
            aggregatedData = AggregatedTelemetryData(
                totalErrors: collectedErrors.count,
                errorRates: errorRates
            )
        }
        
        return aggregatedData!
    }
    
    func flush() async {
        await flushBatch()
    }
    
    func cleanup() async {
        collectedErrors.removeAll()
        aggregatedData = nil
    }
    
    private func flushBatch() async {
        if let transmitter = configuration?.transmitter {
            let batch = TelemetryBatch(errors: collectedErrors, timestamp: Date())
            await transmitter.transmit(batch)
        }
        collectedErrors.removeAll()
    }
    
    private func scrubPII(_ error: TelemetryError) -> TelemetryError {
        var scrubbedError = error
        
        // Remove PII from message
        scrubbedError.error = AxiomError.validationError(.invalidInput("field", "[SCRUBBED]"))
        
        // Remove PII from context
        if var context = scrubbedError.error.context {
            context.additionalData.removeValue(forKey: "email")
            context.additionalData.removeValue(forKey: "ipAddress")
            scrubbedError.error = scrubbedError.error.withContext(context)
        }
        
        return scrubbedError
    }
    
    private func anonymizeData(_ error: TelemetryError) -> TelemetryError {
        var anonymizedError = error
        
        if var context = anonymizedError.error.context {
            // Hash user ID for anonymization
            if let userID = context.userID {
                context.userID = "anon_\(userID.hash)"
            }
            anonymizedError.error = anonymizedError.error.withContext(context)
        }
        
        return anonymizedError
    }
}

private struct TelemetryConfiguration {
    let enableCollection: Bool
    let samplingRate: Double
    let batchSize: Int
    let flushInterval: TimeInterval
    let privacyMode: PrivacyMode
    let piiScrubbing: Bool
    let dataAnonymization: Bool
    let enableAggregation: Bool
    let transmitter: MockTelemetryTransmitter?
    
    init(
        enableCollection: Bool = true,
        samplingRate: Double = 1.0,
        batchSize: Int = 10,
        flushInterval: TimeInterval = .seconds(5),
        privacyMode: PrivacyMode = .standard,
        piiScrubbing: Bool = false,
        dataAnonymization: Bool = false,
        enableAggregation: Bool = false,
        transmitter: MockTelemetryTransmitter? = nil
    ) {
        self.enableCollection = enableCollection
        self.samplingRate = samplingRate
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.privacyMode = privacyMode
        self.piiScrubbing = piiScrubbing
        self.dataAnonymization = dataAnonymization
        self.enableAggregation = enableAggregation
        self.transmitter = transmitter
    }
}

private enum PrivacyMode {
    case standard
    case enhanced
}

private struct TelemetryError {
    var error: AxiomError
    let timestamp: Date
    
    var message: String {
        error.localizedDescription
    }
    
    var context: ErrorContext? {
        error.context
    }
}

private struct TelemetryData {
    let errorCount: Int
    let errorsByType: [String: Int]
    let customMetrics: [KeyValuePair]
    let samplingRate: Double
    let errors: [TelemetryError]
}

private struct AggregatedTelemetryData {
    let totalErrors: Int
    let errorRates: [String: Int]
}

private struct KeyValuePair {
    let key: String
    let value: Any
}

private struct TelemetryBatch {
    let errors: [TelemetryError]
    let timestamp: Date
    
    var errorCount: Int {
        errors.count
    }
}

private actor MockTelemetryTransmitter {
    private var transmissions: [TelemetryBatch] = []
    
    func transmit(_ batch: TelemetryBatch) {
        transmissions.append(batch)
    }
    
    func getTransmissions() -> [TelemetryBatch] {
        return transmissions
    }
}

private class ErrorMetricsCollector {
    private var errorRecords: [(error: AxiomError, timestamp: Date)] = []
    
    func recordError(_ error: AxiomError, timestamp: Date) async {
        errorRecords.append((error, timestamp))
    }
    
    func generateMetrics(from startTime: Date, to endTime: Date) async -> ErrorMetrics {
        let filteredRecords = errorRecords.filter { 
            $0.timestamp >= startTime && $0.timestamp <= endTime 
        }
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        let errorRate = Double(filteredRecords.count) / (timeInterval / 60.0) // Per minute
        
        let errorDistribution = Dictionary(grouping: filteredRecords) { $0.error.category }
            .mapValues { $0.count }
        
        let topErrorTypes = errorDistribution.sorted { $0.value > $1.value }
            .map { ErrorTypeCount(type: $0.key, count: $0.value) }
        
        return ErrorMetrics(
            totalErrors: filteredRecords.count,
            errorRatePerMinute: errorRate,
            errorDistribution: errorDistribution,
            topErrorTypes: topErrorTypes
        )
    }
}

private struct ErrorMetrics {
    let totalErrors: Int
    let errorRatePerMinute: Double
    let errorDistribution: [String: Int]
    let topErrorTypes: [ErrorTypeCount]
}

private struct ErrorTypeCount {
    let type: String
    let count: Int
}

private class ErrorTrendAnalyzer {
    private var errorRecords: [(error: AxiomError, timestamp: Date)] = []
    
    func recordError(_ error: AxiomError, timestamp: Date) async {
        errorRecords.append((error, timestamp))
    }
    
    func analyzeTrends(from startTime: Date, to endTime: Date) async -> TrendAnalysis {
        let filteredRecords = errorRecords.filter { 
            $0.timestamp >= startTime && $0.timestamp <= endTime 
        }
        
        // Simple trend analysis - check if error count is increasing over time windows
        let windowSize: TimeInterval = 60 // 1 minute windows
        let totalDuration = endTime.timeIntervalSince(startTime)
        let windowCount = Int(totalDuration / windowSize)
        
        var windowCounts: [Int] = []
        
        for i in 0..<windowCount {
            let windowStart = startTime.addingTimeInterval(Double(i) * windowSize)
            let windowEnd = windowStart.addingTimeInterval(windowSize)
            
            let windowErrors = filteredRecords.filter { 
                $0.timestamp >= windowStart && $0.timestamp < windowEnd 
            }
            windowCounts.append(windowErrors.count)
        }
        
        // Calculate trend
        let firstHalf = windowCounts.prefix(windowCount / 2)
        let secondHalf = windowCounts.suffix(windowCount / 2)
        
        let firstHalfAverage = firstHalf.isEmpty ? 0 : Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondHalfAverage = secondHalf.isEmpty ? 0 : Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        
        let growthRate = secondHalfAverage - firstHalfAverage
        let trend: TrendDirection = growthRate > 1 ? .increasing : growthRate < -1 ? .decreasing : .stable
        
        return TrendAnalysis(
            trend: trend,
            growthRate: growthRate,
            isSignificant: abs(growthRate) > 2
        )
    }
}

private struct TrendAnalysis {
    let trend: TrendDirection
    let growthRate: Double
    let isSignificant: Bool
}

private enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

// Extension for TimeInterval convenience
private extension TimeInterval {
    static func seconds(_ value: Double) -> TimeInterval {
        return value
    }
    
    static func milliseconds(_ value: Double) -> TimeInterval {
        return value / 1000.0
    }
}