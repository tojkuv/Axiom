import XCTest
@testable import Axiom

/// Tests for comprehensive error telemetry and monitoring system (REQUIREMENTS-W-06-004)
class ErrorTelemetryMonitoringTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any global state
        UserInteractionMock.setNextResponse("") // Clear mock responses
    }
    
    // MARK: - Structured Error Logging Tests
    
    @MainActor
    func testStructuredErrorLogging() async throws {
        // Test structured error logging with comprehensive context
        let telemetryLogger = TelemetryLogger()
        let errorContext = ErrorContext(
            error: AxiomError.networkError(.invalidURL(component: "host", value: "invalid")),
            source: "NetworkService",
            metadata: ["user_id": "12345", "request_id": "req-789"]
        )
        
        telemetryLogger.log(errorContext.error, severity: .error, context: errorContext.metadata)
        
        // Verify structured logging
        let loggedEvents = telemetryLogger.getLoggedEvents()
        XCTAssertEqual(loggedEvents.count, 1)
        
        let loggedEvent = loggedEvents.first!
        XCTAssertEqual(loggedEvent.severity, .error)
        XCTAssertEqual(loggedEvent.source, "NetworkService")
        XCTAssertEqual(loggedEvent.metadata["user_id"] as? String, "12345")
        XCTAssertNotNil(loggedEvent.timestamp)
    }
    
    @MainActor
    func testErrorMetricsCollection() async throws {
        // Test comprehensive error metrics collection
        let metricsCollector = ErrorMetricsCollector()
        
        // Record multiple errors
        for i in 0..<10 {
            let errorContext = ErrorContext(
                error: AxiomError.validationError(.invalidInput("field\(i)", "error")),
                source: "ValidationService",
                metadata: ["batch": "test"]
            )
            metricsCollector.recordError(errorContext)
        }
        
        // Verify metrics collection
        let metrics = metricsCollector.getMetrics(for: "ValidationService")
        XCTAssertEqual(metrics.errorCount, 10)
        XCTAssertEqual(metrics.errorCategory[.validation], 10)
        XCTAssertGreaterThan(metrics.errorRate, 0.0)
    }
    
    @MainActor
    func testErrorPatternDetection() async throws {
        // Test error pattern analysis and spike detection
        let patternAnalyzer = ErrorPatternAnalyzer()
        
        // Create pattern of network errors
        for i in 0..<5 {
            let errorContext = ErrorContext(
                error: AxiomError.networkError(.invalidURL(component: "api", value: "endpoint\(i)")),
                source: "APIService",
                metadata: ["timestamp": Date().timeIntervalSince1970 + Double(i)]
            )
            patternAnalyzer.addError(errorContext)
        }
        
        // Analyze patterns
        let patterns = patternAnalyzer.analyzePatterns()
        XCTAssertFalse(patterns.isEmpty)
        
        let networkPattern = patterns.first { $0.category == .network }
        XCTAssertNotNil(networkPattern)
        XCTAssertEqual(networkPattern?.frequency, 5)
        
        // Test spike detection
        let hasSpike = patternAnalyzer.detectSpike(in: 60.0) // 1 minute window
        XCTAssertTrue(hasSpike)
    }
    
    @MainActor
    func testPrivacyCompliantLogging() async throws {
        // Test privacy-compliant error sanitization
        let sensitiveError = AxiomError.validationError(.invalidInput("email", "user@company.com"))
        let sanitizedError = sensitiveError.sanitized()
        
        if case .validationError(.invalidInput(let field, let value)) = sanitizedError {
            XCTAssertEqual(field, "email")
            XCTAssertEqual(value, "***") // Sensitive data should be masked
        } else {
            XCTFail("Expected sanitized validation error")
        }
        
        // Test URL sanitization
        let networkError = AxiomError.networkError(NetworkContext(
            operation: "fetchUser",
            url: URL(string: "https://api.company.com/users/12345?token=secret123"),
            metadata: ["session": "abc123"]
        ))
        let sanitizedNetworkError = networkError.sanitized()
        
        // URL should be sanitized to remove sensitive query parameters
        XCTAssertTrue(sanitizedNetworkError.localizedDescription.contains("api.company.com"))
        XCTAssertFalse(sanitizedNetworkError.localizedDescription.contains("secret123"))
    }
    
    @MainActor
    func testRealTimeErrorMonitoring() async throws {
        // Test real-time error monitoring with thresholds
        let errorMonitor = ErrorMonitor()
        await errorMonitor.startMonitoring()
        
        // Trigger multiple errors to test threshold
        for i in 0..<5 {
            let error = AxiomError.clientError(.timeout(duration: Double(i)))
            await GlobalErrorHandler.shared.handle(error, severity: .error)
        }
        
        // Verify monitoring response
        await Task.yield() // Allow async processing
        
        XCTAssertEqual(errorMonitor.recentErrors.count, 5)
        XCTAssertGreaterThan(errorMonitor.errorRate, 0.0)
        
        // Test alert threshold
        if errorMonitor.errorRate > errorMonitor.criticalThreshold {
            XCTAssertTrue(errorMonitor.criticalAlertTriggered)
        }
        
        errorMonitor.stopMonitoring()
    }
    
    @MainActor
    func testExternalServiceIntegration() async throws {
        // Test external service integration with crash reporting
        let crashReporter = MockCrashReporter()
        let crashLogger = CrashReportingLogger(crashReporter: crashReporter)
        
        let criticalError = AxiomError.persistenceError(.saveFailed("Database corruption"))
        crashLogger.log(criticalError, severity: .critical, context: ["component": "DataLayer"])
        
        // Verify crash reporting integration
        XCTAssertEqual(crashReporter.recordedErrors.count, 1)
        let recordedError = crashReporter.recordedErrors.first!
        XCTAssertEqual(recordedError.severity, .critical)
        XCTAssertEqual(recordedError.metadata["component"] as? String, "DataLayer")
        
        // Test APM integration
        let apmService = MockAPMService()
        let apmLogger = APMLogger(apmService: apmService)
        
        apmLogger.log(criticalError, severity: .error, context: ["transaction": "user_save"])
        
        XCTAssertEqual(apmService.trackedErrors.count, 1)
        let trackedError = apmService.trackedErrors.first!
        XCTAssertEqual(trackedError.context["transaction"] as? String, "user_save")
    }
    
    // MARK: - Additional Telemetry Tests
    
    @MainActor
    func testTelemetryLoggerThreadSafety() async throws {
        // Test concurrent logging operations
        let logger = TelemetryLogger()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let error = AxiomError.validationError(.invalidInput("field\(i)", "test"))
                    logger.log(error, severity: .warning, context: ["thread": "concurrent"])
                }
            }
        }
        
        let events = logger.getLoggedEvents()
        XCTAssertEqual(events.count, 100)
    }
    
    @MainActor
    func testErrorMetricsAccuracy() async throws {
        // Test metrics accuracy with various error types
        let collector = ErrorMetricsCollector()
        
        // Add network errors
        for _ in 0..<3 {
            let context = ErrorContext(
                error: AxiomError.networkError(.invalidURL(component: "api", value: "test")),
                source: "NetworkService"
            )
            collector.recordError(context)
        }
        
        // Add validation errors
        for _ in 0..<2 {
            let context = ErrorContext(
                error: AxiomError.validationError(.invalidInput("field", "test")),
                source: "ValidationService"
            )
            collector.recordError(context)
        }
        
        let networkMetrics = collector.getMetrics(for: "NetworkService")
        let validationMetrics = collector.getMetrics(for: "ValidationService")
        
        XCTAssertEqual(networkMetrics.errorCount, 3)
        XCTAssertEqual(validationMetrics.errorCount, 2)
        XCTAssertEqual(networkMetrics.errorCategory[.network], 3)
        XCTAssertEqual(validationMetrics.errorCategory[.validation], 2)
    }
    
    @MainActor
    func testURLSanitization() throws {
        // Test URL sanitization for privacy compliance
        let sensitiveURL = URL(string: "https://api.example.com/users?token=abc123&secret=xyz789&user_id=12345")!
        let sanitizedURL = sensitiveURL.sanitized()
        
        let sanitizedString = sanitizedURL.absoluteString
        XCTAssertFalse(sanitizedString.contains("abc123"))
        XCTAssertFalse(sanitizedString.contains("xyz789"))
        XCTAssertTrue(sanitizedString.contains("user_id=12345")) // Non-sensitive param preserved
    }
    
    @MainActor
    func testErrorPatternTimeWindows() async throws {
        // Test pattern analysis with different time windows
        let analyzer = ErrorPatternAnalyzer()
        
        let now = Date()
        
        // Add errors with specific timestamps
        for i in 0..<3 {
            let context = ErrorContext(
                error: AxiomError.networkError(.invalidURL(component: "api", value: "test\(i)")),
                source: "TimeWindowTest"
            )
            // Manually set timestamp by creating new context
            let timedContext = ErrorContext(
                error: context.error,
                source: context.source,
                metadata: context.metadata
            )
            analyzer.addError(timedContext)
        }
        
        let patterns = analyzer.analyzePatterns()
        let networkPattern = patterns.first { $0.category == .network }
        
        XCTAssertNotNil(networkPattern)
        XCTAssertEqual(networkPattern?.frequency, 3)
        XCTAssertGreaterThanOrEqual(networkPattern?.timeWindow ?? 0, 0)
    }
    
    @MainActor
    func testMonitoringThresholdAdjustment() async throws {
        // Test error monitoring with custom thresholds
        let monitor = ErrorMonitor()
        
        // Verify initial threshold
        XCTAssertEqual(monitor.criticalThreshold, 10.0)
        
        await monitor.startMonitoring()
        
        // Add errors below threshold
        for i in 0..<3 {
            let error = AxiomError.validationError(.invalidInput("test\(i)", "error"))
            await GlobalErrorHandler.shared.handle(error, severity: .warning)
        }
        
        await Task.yield()
        
        // Should not trigger alert for low volume
        XCTAssertFalse(monitor.criticalAlertTriggered)
        
        monitor.stopMonitoring()
    }
}