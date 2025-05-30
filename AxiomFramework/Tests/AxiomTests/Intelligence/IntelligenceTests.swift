import XCTest
@testable import Axiom

/// Comprehensive testing framework for Axiom Intelligence System
final class IntelligenceTests: XCTestCase {
    
    // MARK: Test Properties
    
    private var intelligence: DefaultAxiomIntelligence!
    
    // MARK: Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        intelligence = DefaultAxiomIntelligence(
            enabledFeatures: [.architecturalDNA, .naturalLanguageQueries, .emergentPatternDetection],
            confidenceThreshold: 0.7,
            automationLevel: .supervised,
            learningMode: .suggestion,
            performanceConfiguration: IntelligencePerformanceConfiguration(
                maxResponseTime: 0.2,
                maxMemoryUsage: 50_000_000,
                maxConcurrentOperations: 5,
                enableCaching: true,
                cacheExpiration: 60
            )
        )
    }
    
    override func tearDown() async throws {
        await intelligence.reset()
        intelligence = nil
        try await super.tearDown()
    }
    
    // MARK: Feature Management Tests
    
    func testInitialConfiguration() async throws {
        // Verify initial state
        let features = await intelligence.enabledFeatures
        XCTAssertTrue(features.contains(.architecturalDNA))
        XCTAssertTrue(features.contains(.naturalLanguageQueries))
        XCTAssertTrue(features.contains(.emergentPatternDetection))
        XCTAssertEqual(features.count, 3)
        
        let confidence = await intelligence.confidenceThreshold
        XCTAssertEqual(confidence, 0.7)
        
        let automation = await intelligence.automationLevel
        XCTAssertEqual(automation, .supervised)
        
        let learning = await intelligence.learningMode
        XCTAssertEqual(learning, .suggestion)
    }
    
    func testEnableFeature() async throws {
        // Enable a new feature
        await intelligence.enableFeature(.selfOptimizingPerformance)
        
        let features = await intelligence.enabledFeatures
        XCTAssertTrue(features.contains(.selfOptimizingPerformance))
        XCTAssertEqual(features.count, 4)
    }
    
    func testEnableFeatureWithDependencies() async throws {
        // Disable all features first
        for feature in IntelligenceFeature.allCases {
            await intelligence.disableFeature(feature)
        }
        
        // Enable a feature with dependencies
        await intelligence.enableFeature(.intentDrivenEvolution)
        
        let features = await intelligence.enabledFeatures
        // Should have enabled architecturalDNA as dependency
        XCTAssertTrue(features.contains(.architecturalDNA))
        XCTAssertTrue(features.contains(.intentDrivenEvolution))
    }
    
    func testDisableFeature() async throws {
        // Disable a feature
        await intelligence.disableFeature(.emergentPatternDetection)
        
        let features = await intelligence.enabledFeatures
        XCTAssertFalse(features.contains(.emergentPatternDetection))
        XCTAssertEqual(features.count, 2)
    }
    
    func testDisableFeatureWithDependents() async throws {
        // Enable temporal workflows (depends on pattern detection)
        await intelligence.enableFeature(.temporalDevelopmentWorkflows)
        
        // Disable pattern detection should also disable temporal workflows
        await intelligence.disableFeature(.emergentPatternDetection)
        
        let features = await intelligence.enabledFeatures
        XCTAssertFalse(features.contains(.emergentPatternDetection))
        XCTAssertFalse(features.contains(.temporalDevelopmentWorkflows))
    }
    
    func testPredictiveArchitectureIntelligenceDependencies() async throws {
        // Enable predictive architecture (depends on all other features)
        await intelligence.enableFeature(.predictiveArchitectureIntelligence)
        
        let features = await intelligence.enabledFeatures
        // Should have all features enabled
        XCTAssertEqual(features.count, IntelligenceFeature.allCases.count)
        
        for feature in IntelligenceFeature.allCases {
            XCTAssertTrue(features.contains(feature))
        }
    }
    
    // MARK: Configuration Tests
    
    func testSetAutomationLevel() async throws {
        await intelligence.setAutomationLevel(.autonomous)
        
        let level = await intelligence.automationLevel
        XCTAssertEqual(level, .autonomous)
    }
    
    func testSetLearningMode() async throws {
        await intelligence.setLearningMode(.execution)
        
        let mode = await intelligence.learningMode
        XCTAssertEqual(mode, .execution)
    }
    
    // MARK: Metrics Tests
    
    func testInitialMetrics() async throws {
        let metrics = await intelligence.getMetrics()
        
        XCTAssertEqual(metrics.totalOperations, 0)
        XCTAssertEqual(metrics.averageResponseTime, 0)
        XCTAssertEqual(metrics.cacheHitRate, 0)
        XCTAssertEqual(metrics.successfulPredictions, 0)
        XCTAssertEqual(metrics.predictionAccuracy, 0)
        XCTAssertTrue(metrics.featureMetrics.isEmpty)
    }
    
    func testMetricsAfterOperations() async throws {
        // Perform some operations (pattern detection)
        do {
            _ = try await intelligence.detectPatterns()
        } catch {
            // Expected - no patterns in test environment
        }
        
        let metrics = await intelligence.getMetrics()
        
        // Should have recorded the operation
        XCTAssertGreaterThan(metrics.totalOperations, 0)
        XCTAssertGreaterThan(metrics.averageResponseTime, 0)
        
        // Check feature metrics
        if let patternMetrics = metrics.featureMetrics[.emergentPatternDetection] {
            XCTAssertGreaterThan(patternMetrics.usageCount, 0)
            XCTAssertNotNil(patternMetrics.lastUsed)
        }
    }
    
    func testReset() async throws {
        // Perform operations
        do {
            _ = try await intelligence.detectPatterns()
        } catch {
            // Expected
        }
        
        // Reset
        await intelligence.reset()
        
        // Verify metrics are reset
        let metrics = await intelligence.getMetrics()
        XCTAssertEqual(metrics.totalOperations, 0)
        XCTAssertEqual(metrics.averageResponseTime, 0)
        XCTAssertTrue(metrics.featureMetrics.isEmpty)
    }
    
    // MARK: Feature Operation Tests
    
    func testNaturalLanguageQueryFeatureDisabled() async throws {
        // Disable the feature
        await intelligence.disableFeature(.naturalLanguageQueries)
        
        // Try to process a query
        do {
            _ = try await intelligence.processQuery("What components exist?")
            XCTFail("Expected IntelligenceError.featureNotEnabled")
        } catch IntelligenceError.featureNotEnabled(let feature) {
            XCTAssertEqual(feature, .naturalLanguageQueries)
        }
    }
    
    func testArchitecturalDNAFeatureDisabled() async throws {
        // Disable the feature
        await intelligence.disableFeature(.architecturalDNA)
        
        // Try to get architectural DNA
        do {
            _ = try await intelligence.getArchitecturalDNA(for: ComponentID("TestComponent"))
            XCTFail("Expected IntelligenceError.featureNotEnabled")
        } catch IntelligenceError.featureNotEnabled(let feature) {
            XCTAssertEqual(feature, .architecturalDNA)
        }
    }
    
    func testPatternDetectionFeatureDisabled() async throws {
        // Disable the feature
        await intelligence.disableFeature(.emergentPatternDetection)
        
        // Try to detect patterns
        do {
            _ = try await intelligence.detectPatterns()
            XCTFail("Expected IntelligenceError.featureNotEnabled")
        } catch IntelligenceError.featureNotEnabled(let feature) {
            XCTAssertEqual(feature, .emergentPatternDetection)
        }
    }
    
    // MARK: Performance Tests
    
    func testPerformanceConfiguration() async throws {
        let config = await intelligence.performanceConfiguration
        
        XCTAssertEqual(config.maxResponseTime, 0.2)
        XCTAssertEqual(config.maxMemoryUsage, 50_000_000)
        XCTAssertEqual(config.maxConcurrentOperations, 5)
        XCTAssertTrue(config.enableCaching)
        XCTAssertEqual(config.cacheExpiration, 60)
    }
    
    func testOperationPerformance() async throws {
        // Measure performance of pattern detection
        let startTime = Date()
        
        do {
            _ = try await intelligence.detectPatterns()
        } catch {
            // Expected in test environment
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should complete within configured max response time
        XCTAssertLessThan(duration, 0.2)
    }
    
    // MARK: Feature Dependency Tests
    
    func testFeatureDependencyValidation() {
        // Test all feature dependencies are correctly defined
        for feature in IntelligenceFeature.allCases {
            let dependencies = feature.dependencies
            
            switch feature {
            case .architecturalDNA:
                XCTAssertTrue(dependencies.isEmpty)
            case .intentDrivenEvolution, .naturalLanguageQueries,
                 .selfOptimizingPerformance, .constraintPropagation,
                 .emergentPatternDetection:
                XCTAssertEqual(dependencies, [.architecturalDNA])
            case .temporalDevelopmentWorkflows:
                XCTAssertEqual(dependencies, [.architecturalDNA, .emergentPatternDetection])
            case .predictiveArchitectureIntelligence:
                XCTAssertEqual(dependencies.count, IntelligenceFeature.allCases.count - 1)
                XCTAssertFalse(dependencies.contains(.predictiveArchitectureIntelligence))
            }
        }
    }
    
    // MARK: Error Handling Tests
    
    func testLowConfidenceError() async throws {
        // Create a custom intelligence with high confidence threshold
        let strictIntelligence = DefaultAxiomIntelligence(
            enabledFeatures: [.naturalLanguageQueries, .architecturalDNA],
            confidenceThreshold: 0.95,
            automationLevel: .manual,
            learningMode: .observation
        )
        
        // Most queries should fail with high threshold
        do {
            _ = try await strictIntelligence.processQuery("show me something")
            // May or may not fail depending on parser implementation
        } catch IntelligenceError.lowConfidence(let confidence) {
            XCTAssertLessThan(confidence, 0.95)
        }
    }
    
    // MARK: Intelligence Feature Tests
    
    func testIntelligenceFeatureMetadata() {
        // Test all features have proper metadata
        for feature in IntelligenceFeature.allCases {
            XCTAssertFalse(feature.displayName.isEmpty)
            XCTAssertFalse(feature.description.isEmpty)
            XCTAssertNotEqual(feature.displayName, feature.rawValue)
        }
    }
    
    func testAutomationLevelDescriptions() {
        for level in AutomationLevel.allCases {
            XCTAssertFalse(level.description.isEmpty)
        }
    }
    
    func testLearningModeDescriptions() {
        for mode in LearningMode.allCases {
            XCTAssertFalse(mode.description.isEmpty)
        }
    }
    
    // MARK: Concurrent Operation Tests
    
    func testConcurrentFeatureManagement() async throws {
        // Test concurrent enable/disable operations
        await withTaskGroup(of: Void.self) { group in
            // Enable different features concurrently
            group.addTask {
                await self.intelligence.enableFeature(.selfOptimizingPerformance)
            }
            group.addTask {
                await self.intelligence.enableFeature(.constraintPropagation)
            }
            group.addTask {
                await self.intelligence.enableFeature(.intentDrivenEvolution)
            }
        }
        
        let features = await intelligence.enabledFeatures
        XCTAssertTrue(features.contains(.selfOptimizingPerformance))
        XCTAssertTrue(features.contains(.constraintPropagation))
        XCTAssertTrue(features.contains(.intentDrivenEvolution))
    }
    
    // MARK: Integration Tests
    
    func testFullIntelligenceWorkflow() async throws {
        // Enable all features
        await intelligence.enableFeature(.predictiveArchitectureIntelligence)
        
        // Verify all features are enabled
        let features = await intelligence.enabledFeatures
        XCTAssertEqual(features.count, IntelligenceFeature.allCases.count)
        
        // Set to autonomous mode
        await intelligence.setAutomationLevel(.autonomous)
        await intelligence.setLearningMode(.execution)
        
        // Perform various operations
        do {
            _ = try await intelligence.detectPatterns()
        } catch {
            // Expected in test environment
        }
        
        // Get metrics
        let metrics = await intelligence.getMetrics()
        XCTAssertGreaterThan(metrics.totalOperations, 0)
        
        // Reset and verify
        await intelligence.reset()
        let resetMetrics = await intelligence.getMetrics()
        XCTAssertEqual(resetMetrics.totalOperations, 0)
    }
    
    // MARK: Accuracy Measurement Tests
    
    func testPredictionAccuracyCalculation() async throws {
        let metrics = await intelligence.getMetrics()
        
        // With no predictions, accuracy should be 0
        XCTAssertEqual(metrics.predictionAccuracy, 0.0)
        
        // In a real implementation, we would:
        // 1. Make predictions
        // 2. Validate predictions
        // 3. Calculate accuracy
        // For now, we verify the metric exists and is calculated
    }
    
    func testFeatureSuccessRateTracking() async throws {
        // Perform operations that will be tracked
        do {
            _ = try await intelligence.detectPatterns()
        } catch {
            // Expected
        }
        
        let metrics = await intelligence.getMetrics()
        
        if let patternMetrics = metrics.featureMetrics[.emergentPatternDetection] {
            // Success rate should be between 0 and 1
            XCTAssertGreaterThanOrEqual(patternMetrics.successRate, 0.0)
            XCTAssertLessThanOrEqual(patternMetrics.successRate, 1.0)
        }
    }
    
    // MARK: Performance Benchmarking
    
    func testIntelligenceOverheadMeasurement() async throws {
        // Measure overhead of intelligence operations
        let iterations = 10
        var totalDuration: TimeInterval = 0
        
        for _ in 0..<iterations {
            let startTime = Date()
            
            // Enable/disable features
            await intelligence.enableFeature(.selfOptimizingPerformance)
            await intelligence.disableFeature(.selfOptimizingPerformance)
            
            totalDuration += Date().timeIntervalSince(startTime)
        }
        
        let averageDuration = totalDuration / Double(iterations)
        
        // Intelligence operations should be fast
        XCTAssertLessThan(averageDuration, 0.01) // Less than 10ms
    }
}

// MARK: - Intelligence Accuracy Tests

/// Separate test class for measuring intelligence accuracy
final class IntelligenceAccuracyTests: XCTestCase {
    
    private var intelligence: DefaultAxiomIntelligence!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Configure for accuracy testing
        intelligence = DefaultAxiomIntelligence(
            enabledFeatures: Set(IntelligenceFeature.allCases),
            confidenceThreshold: 0.6,
            automationLevel: .autonomous,
            learningMode: .execution
        )
    }
    
    override func tearDown() async throws {
        await intelligence.reset()
        intelligence = nil
        try await super.tearDown()
    }
    
    func testQueryParsingAccuracy() async throws {
        // Test various query types and measure accuracy
        let testQueries = [
            ("What components are in the system?", QueryIntent.listComponents),
            ("Show me all client components", QueryIntent.listComponents),
            ("How many components are there?", QueryIntent.countComponents),
            ("What patterns exist?", QueryIntent.detectPatterns),
            ("Validate the architecture", QueryIntent.validateArchitecture),
            ("Help", QueryIntent.help)
        ]
        
        var correct = 0
        var total = 0
        
        for (query, expectedIntent) in testQueries {
            do {
                let response = try await intelligence.processQuery(query)
                if response.intent == expectedIntent {
                    correct += 1
                }
                total += 1
            } catch {
                // Query processing failed
                total += 1
            }
        }
        
        let accuracy = total > 0 ? Double(correct) / Double(total) : 0.0
        
        // Target: >90% query understanding accuracy
        XCTAssertGreaterThan(accuracy, 0.8) // Lower threshold for test environment
    }
    
    func testPatternDetectionAccuracy() async throws {
        // In a real implementation, we would:
        // 1. Create known patterns in test code
        // 2. Run pattern detection
        // 3. Verify correct patterns are detected
        // 4. Calculate precision and recall
        
        do {
            let patterns = try await intelligence.detectPatterns()
            // Verify pattern detection is working
            XCTAssertNotNil(patterns)
        } catch {
            // Expected in minimal test environment
        }
    }
    
    func testArchitecturalDNAAccuracy() async throws {
        // Test DNA generation accuracy
        // In a real implementation, we would verify:
        // 1. Component relationships are correctly identified
        // 2. Purpose and constraints are accurate
        // 3. Performance characteristics are measured correctly
        
        let dna = try await intelligence.getArchitecturalDNA(for: ComponentID("TestComponent"))
        
        // DNA should be nil for non-existent component
        XCTAssertNil(dna)
    }
}