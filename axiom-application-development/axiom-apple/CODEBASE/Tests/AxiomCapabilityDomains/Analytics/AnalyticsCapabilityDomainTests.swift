import XCTest
import AxiomTesting
@testable import AxiomCapabilityDomains
@testable import AxiomCapabilities
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomCapabilityDomains analytics capability domain functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class AnalyticsCapabilityDomainTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testAnalyticsCapabilityDomainInitialization() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        XCTAssertNotNil(analyticsDomain, "AnalyticsCapabilityDomain should initialize correctly")
        XCTAssertEqual(analyticsDomain.identifier, "axiom.capability.domain.analytics", "Should have correct identifier")
    }
    
    func testEventTrackingCapabilityRegistration() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        let appEventCapability = AppEventTrackingCapability()
        let userEventCapability = UserEventTrackingCapability()
        let performanceEventCapability = PerformanceEventTrackingCapability()
        let customEventCapability = CustomEventTrackingCapability()
        
        await analyticsDomain.registerCapability(appEventCapability)
        await analyticsDomain.registerCapability(userEventCapability)
        await analyticsDomain.registerCapability(performanceEventCapability)
        await analyticsDomain.registerCapability(customEventCapability)
        
        let registeredCapabilities = await analyticsDomain.getRegisteredCapabilities()
        XCTAssertEqual(registeredCapabilities.count, 4, "Should have 4 registered event tracking capabilities")
        
        let hasAppEvent = await analyticsDomain.hasCapability("axiom.analytics.events.app")
        XCTAssertTrue(hasAppEvent, "Should have App Event capability")
        
        let hasUserEvent = await analyticsDomain.hasCapability("axiom.analytics.events.user")
        XCTAssertTrue(hasUserEvent, "Should have User Event capability")
        
        let hasPerformanceEvent = await analyticsDomain.hasCapability("axiom.analytics.events.performance")
        XCTAssertTrue(hasPerformanceEvent, "Should have Performance Event capability")
        
        let hasCustomEvent = await analyticsDomain.hasCapability("axiom.analytics.events.custom")
        XCTAssertTrue(hasCustomEvent, "Should have Custom Event capability")
    }
    
    func testMetricsCollectionCapabilityManagement() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        let systemMetricsCapability = SystemMetricsCapability()
        let businessMetricsCapability = BusinessMetricsCapability()
        let engagementMetricsCapability = EngagementMetricsCapability()
        let crashMetricsCapability = CrashMetricsCapability()
        
        await analyticsDomain.registerCapability(systemMetricsCapability)
        await analyticsDomain.registerCapability(businessMetricsCapability)
        await analyticsDomain.registerCapability(engagementMetricsCapability)
        await analyticsDomain.registerCapability(crashMetricsCapability)
        
        let metricsCapabilities = await analyticsDomain.getCapabilitiesOfType(.metrics)
        XCTAssertEqual(metricsCapabilities.count, 4, "Should have 4 metrics capabilities")
        
        let realtimeMetricsCapability = await analyticsDomain.getBestCapabilityForUseCase(.realtimeMonitoring)
        XCTAssertNotNil(realtimeMetricsCapability, "Should find best capability for realtime monitoring")
        
        let batchMetricsCapability = await analyticsDomain.getBestCapabilityForUseCase(.batchProcessing)
        XCTAssertNotNil(batchMetricsCapability, "Should find best capability for batch processing")
    }
    
    func testDataVisualizationCapabilities() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        let chartCapability = ChartVisualizationCapability()
        let dashboardCapability = DashboardCapability()
        let reportCapability = ReportGenerationCapability()
        let heatmapCapability = HeatmapCapability()
        
        await analyticsDomain.registerCapability(chartCapability)
        await analyticsDomain.registerCapability(dashboardCapability)
        await analyticsDomain.registerCapability(reportCapability)
        await analyticsDomain.registerCapability(heatmapCapability)
        
        let visualizationCapabilities = await analyticsDomain.getCapabilitiesOfType(.visualization)
        XCTAssertEqual(visualizationCapabilities.count, 4, "Should have 4 visualization capabilities")
        
        let interactiveCapability = await analyticsDomain.getBestCapabilityForUseCase(.interactiveVisualization)
        XCTAssertNotNil(interactiveCapability, "Should find best capability for interactive visualization")
    }
    
    func testAnalyticsDataPipeline() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        // Register various analytics capabilities
        await analyticsDomain.registerCapability(AppEventTrackingCapability())
        await analyticsDomain.registerCapability(SystemMetricsCapability())
        await analyticsDomain.registerCapability(ChartVisualizationCapability())
        
        let pipeline = await analyticsDomain.createDataPipeline(
            for: AnalyticsPipelineRequirements(
                dataTypes: [.events, .metrics],
                processingMode: .realtime,
                outputFormats: [.charts, .reports],
                retentionPeriod: .days(30)
            )
        )
        
        XCTAssertNotNil(pipeline, "Should create analytics data pipeline")
        XCTAssertTrue(pipeline!.stages.count > 0, "Pipeline should have processing stages")
        
        let canProcessEvents = await pipeline!.canProcess(dataType: .events)
        XCTAssertTrue(canProcessEvents, "Pipeline should be able to process events")
        
        let canProcessMetrics = await pipeline!.canProcess(dataType: .metrics)
        XCTAssertTrue(canProcessMetrics, "Pipeline should be able to process metrics")
    }
    
    func testPrivacyComplianceCapability() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        let privacyManager = await analyticsDomain.getPrivacyManager()
        XCTAssertNotNil(privacyManager, "Should provide privacy manager")
        
        // Test privacy configuration
        let privacyConfig = PrivacyConfiguration(
            dataAnonymization: true,
            userConsent: true,
            dataRetention: .days(90),
            gdprCompliance: true
        )
        
        await privacyManager!.configurePrivacy(privacyConfig)
        
        let currentConfig = await privacyManager!.getPrivacyConfiguration()
        XCTAssertTrue(currentConfig.dataAnonymization, "Should enable data anonymization")
        XCTAssertTrue(currentConfig.gdprCompliance, "Should enable GDPR compliance")
        
        // Test data anonymization
        let sensitiveData = TestAnalyticsData(userId: "user123", email: "test@example.com")
        let anonymizedData = await privacyManager!.anonymizeData(sensitiveData)
        
        XCTAssertNotEqual(anonymizedData.userId, "user123", "User ID should be anonymized")
        XCTAssertNil(anonymizedData.email, "Email should be removed for privacy")
    }
    
    func testRealtimeAnalyticsCapability() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        await analyticsDomain.registerCapability(AppEventTrackingCapability())
        await analyticsDomain.registerCapability(SystemMetricsCapability())
        
        let realtimeProcessor = await analyticsDomain.getRealtimeProcessor()
        XCTAssertNotNil(realtimeProcessor, "Should provide realtime processor")
        
        // Test realtime event processing
        let eventStream = TestEventStream()
        await realtimeProcessor!.attachEventStream(eventStream)
        
        let isProcessing = await realtimeProcessor!.isProcessing()
        XCTAssertTrue(isProcessing, "Should be processing events")
        
        // Test realtime alerts
        let alertRule = AlertRule(
            metric: "error_rate",
            threshold: 0.05, // 5%
            timeWindow: .minutes(5)
        )
        
        await realtimeProcessor!.addAlertRule(alertRule)
        
        let alertRules = await realtimeProcessor!.getAlertRules()
        XCTAssertEqual(alertRules.count, 1, "Should have 1 alert rule")
    }
    
    // MARK: - Performance Tests
    
    func testAnalyticsCapabilityDomainPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let analyticsDomain = AnalyticsCapabilityDomain()
                
                // Test rapid capability operations
                for i in 0..<100 {
                    let capability = TestAnalyticsCapability(index: i)
                    await analyticsDomain.registerCapability(capability)
                }
                
                // Test pipeline creation performance
                for _ in 0..<25 {
                    let requirements = AnalyticsPipelineRequirements(
                        dataTypes: [.events],
                        processingMode: .batch,
                        outputFormats: [.raw],
                        retentionPeriod: .days(7)
                    )
                    _ = await analyticsDomain.createDataPipeline(for: requirements)
                }
            },
            maxDuration: .milliseconds(400),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testAnalyticsCapabilityDomainMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let analyticsDomain = AnalyticsCapabilityDomain()
            
            // Simulate domain lifecycle
            for i in 0..<30 {
                let capability = TestAnalyticsCapability(index: i)
                await analyticsDomain.registerCapability(capability)
                
                if i % 5 == 0 {
                    let requirements = AnalyticsPipelineRequirements(
                        dataTypes: [.metrics, .events],
                        processingMode: .realtime,
                        outputFormats: [.charts],
                        retentionPeriod: .days(1)
                    )
                    _ = await analyticsDomain.createDataPipeline(for: requirements)
                }
                
                if i % 8 == 0 {
                    await analyticsDomain.unregisterCapability(capability.identifier)
                }
            }
            
            await analyticsDomain.cleanup()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAnalyticsCapabilityDomainErrorHandling() async throws {
        let analyticsDomain = AnalyticsCapabilityDomain()
        
        // Test registering capability with duplicate identifier
        let capability1 = TestAnalyticsCapability(index: 1)
        let capability2 = TestAnalyticsCapability(index: 1) // Same index = same identifier
        
        await analyticsDomain.registerCapability(capability1)
        
        do {
            try await analyticsDomain.registerCapabilityStrict(capability2)
            XCTFail("Should throw error for duplicate identifier")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for duplicate identifier")
        }
        
        // Test pipeline creation with unsupported data type
        do {
            let unsupportedRequirements = AnalyticsPipelineRequirements(
                dataTypes: [.unsupported],
                processingMode: .realtime,
                outputFormats: [.charts],
                retentionPeriod: .days(30)
            )
            try await analyticsDomain.createDataPipelineStrict(for: unsupportedRequirements)
            XCTFail("Should throw error for unsupported data type")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for unsupported data type")
        }
        
        // Test privacy configuration with invalid settings
        let privacyManager = await analyticsDomain.getPrivacyManager()
        if let manager = privacyManager {
            do {
                let invalidConfig = PrivacyConfiguration(
                    dataAnonymization: false,
                    userConsent: false,
                    dataRetention: .days(-1), // Invalid negative retention
                    gdprCompliance: true
                )
                try await manager.configurePrivacyStrict(invalidConfig)
                XCTFail("Should throw error for invalid privacy configuration")
            } catch {
                XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid configuration")
            }
        }
    }
}

// MARK: - Test Helper Classes

private struct AppEventTrackingCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.events.app"
    let isAvailable = true
    let analyticsType: AnalyticsType = .events
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .high
}

private struct UserEventTrackingCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.events.user"
    let isAvailable = true
    let analyticsType: AnalyticsType = .events
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .high
}

private struct PerformanceEventTrackingCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.events.performance"
    let isAvailable = true
    let analyticsType: AnalyticsType = .events
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .medium
}

private struct CustomEventTrackingCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.events.custom"
    let isAvailable = true
    let analyticsType: AnalyticsType = .events
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .medium
}

private struct SystemMetricsCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.metrics.system"
    let isAvailable = true
    let analyticsType: AnalyticsType = .metrics
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .high
}

private struct BusinessMetricsCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.metrics.business"
    let isAvailable = true
    let analyticsType: AnalyticsType = .metrics
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .high
}

private struct EngagementMetricsCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.metrics.engagement"
    let isAvailable = true
    let analyticsType: AnalyticsType = .metrics
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .medium
}

private struct CrashMetricsCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.metrics.crash"
    let isAvailable = true
    let analyticsType: AnalyticsType = .metrics
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .high
}

private struct ChartVisualizationCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.visualization.charts"
    let isAvailable = true
    let analyticsType: AnalyticsType = .visualization
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .high
}

private struct DashboardCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.visualization.dashboard"
    let isAvailable = true
    let analyticsType: AnalyticsType = .visualization
    let processingMode: ProcessingMode = .realtime
    let accuracy: AnalyticsAccuracy = .high
}

private struct ReportGenerationCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.visualization.reports"
    let isAvailable = true
    let analyticsType: AnalyticsType = .visualization
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .high
}

private struct HeatmapCapability: AnalyticsCapability {
    let identifier = "axiom.analytics.visualization.heatmap"
    let isAvailable = true
    let analyticsType: AnalyticsType = .visualization
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .medium
}

private struct TestAnalyticsCapability: AnalyticsCapability {
    let identifier: String
    let isAvailable = true
    let analyticsType: AnalyticsType = .events
    let processingMode: ProcessingMode = .batch
    let accuracy: AnalyticsAccuracy = .medium
    
    init(index: Int) {
        self.identifier = "test.analytics.capability.\(index)"
    }
}

private enum AnalyticsType {
    case events
    case metrics
    case visualization
    case reporting
}

private enum ProcessingMode {
    case realtime
    case batch
    case hybrid
}

private enum AnalyticsAccuracy {
    case low
    case medium
    case high
    case exact
}

private enum DataType {
    case events
    case metrics
    case logs
    case traces
    case unsupported
}

private enum OutputFormat {
    case raw
    case charts
    case reports
    case dashboards
}

private enum AnalyticsUseCase {
    case realtimeMonitoring
    case batchProcessing
    case interactiveVisualization
    case compliance
}

private enum RetentionPeriod {
    case days(Int)
    case months(Int)
    case years(Int)
}

private enum TimeWindow {
    case minutes(Int)
    case hours(Int)
    case days(Int)
}

private struct AnalyticsPipelineRequirements {
    let dataTypes: [DataType]
    let processingMode: ProcessingMode
    let outputFormats: [OutputFormat]
    let retentionPeriod: RetentionPeriod
}

private struct PrivacyConfiguration {
    let dataAnonymization: Bool
    let userConsent: Bool
    let dataRetention: RetentionPeriod
    let gdprCompliance: Bool
}

private struct TestAnalyticsData {
    let userId: String
    let email: String?
    
    init(userId: String, email: String? = nil) {
        self.userId = userId
        self.email = email
    }
}

private class TestEventStream {
    private var isActive = false
    
    func start() {
        isActive = true
    }
    
    func stop() {
        isActive = false
    }
    
    var isStreaming: Bool {
        return isActive
    }
}

private struct AlertRule {
    let metric: String
    let threshold: Double
    let timeWindow: TimeWindow
}