import XCTest
@testable import Axiom
import Foundation

/// Phase 3 Milestone 2: Parallel Processing Engine Tests
/// TDD implementation for concurrent intelligence operations and load balancing
final class ParallelProcessingTests: XCTestCase {
    
    private var intelligence: DefaultAxiomIntelligence!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Configure intelligence with all features for testing
        intelligence = DefaultAxiomIntelligence(
            enabledFeatures: Set(IntelligenceFeature.allCases),
            confidenceThreshold: 0.7,
            automationLevel: .supervised,
            learningMode: .suggestion,
            performanceConfiguration: IntelligencePerformanceConfiguration(
                maxResponseTime: 0.1,
                maxMemoryUsage: 50 * 1024 * 1024, // 50MB
                maxConcurrentOperations: 8,
                enableCaching: true,
                cacheExpiration: 300
            )
        )
    }
    
    // MARK: - TDD Phase 1: Parallel Component Discovery Tests
    
    /// Test: Parallel component discovery should be faster than sequential
    func testParallelComponentDiscoveryPerformance() async throws {
        // RED: This test should fail initially because parallel discovery isn't implemented
        
        let startTime = Date()
        
        // This should use parallel component discovery when implemented
        let components = try await intelligence.discoverComponentsParallel()
        
        let parallelDuration = Date().timeIntervalSince(startTime)
        
        // Verify we got components back
        XCTAssertFalse(components.isEmpty, "Parallel component discovery should return components")
        
        // Performance expectation: Should complete in reasonable time
        XCTAssertLessThan(parallelDuration, 0.5, "Parallel component discovery should complete within 500ms")
        
        print("📊 Parallel Component Discovery: \(String(format: "%.3f", parallelDuration))s")
    }
    
    /// Test: Parallel component discovery should maintain data integrity
    func testParallelComponentDiscoveryIntegrity() async throws {
        // RED: This test should fail initially
        
        let components = try await intelligence.discoverComponentsParallel()
        
        // Verify component integrity
        for component in components {
            XCTAssertFalse(component.name.isEmpty, "Component name should not be empty")
            XCTAssertNotNil(component.id, "Component ID should not be nil")
            XCTAssertNotNil(component.type, "Component type should not be nil")
        }
        
        // Verify no duplicate components
        let uniqueIDs = Set(components.map { $0.id })
        XCTAssertEqual(components.count, uniqueIDs.count, "Should not have duplicate components")
    }
    
    // MARK: - TDD Phase 2: Concurrent Intelligence Feature Execution Tests
    
    /// Test: Intelligence features should execute with dependency resolution and parallelism
    func testConcurrentIndependentFeatureExecution() async throws {
        // Test concurrent execution with dependency resolution
        // .componentRegistry first, then others that depend on it can run in parallel
        
        let features: [IntelligenceFeature] = [
            .componentRegistry,
            .performanceMonitoring,
            .capabilityValidation
        ]
        
        let startTime = Date()
        
        // This should execute independent features concurrently
        let results = try await intelligence.executeFeaturesConcurrently(features)
        
        let concurrentDuration = Date().timeIntervalSince(startTime)
        
        // Verify all features executed
        XCTAssertEqual(results.count, features.count, "All features should execute")
        
        // Verify results are valid
        for result in results {
            XCTAssertTrue(result.success, "Feature execution should succeed")
            XCTAssertGreaterThan(result.confidence, 0.0, "Result should have confidence score")
        }
        
        // Performance expectation: Concurrent execution should be faster than sequential
        XCTAssertLessThan(concurrentDuration, 1.0, "Concurrent feature execution should complete within 1s")
        
        print("📊 Concurrent Feature Execution: \(String(format: "%.3f", concurrentDuration))s")
    }
    
    /// Test: Dependent features should respect dependencies while maximizing parallelism
    func testDependentFeatureExecutionWithParallelism() async throws {
        // RED: This test should fail initially
        
        let features: [IntelligenceFeature] = [
            .componentRegistry, // No dependencies
            .performanceMonitoring, // Depends on componentRegistry
            .capabilityValidation // Depends on componentRegistry
        ]
        
        let startTime = Date()
        
        // This should execute features with proper dependency resolution
        let results = try await intelligence.executeFeaturesConcurrentlyWithDependencies(features)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify all features executed
        XCTAssertEqual(results.count, features.count, "All features should execute")
        
        // Verify dependency order was respected
        let dependencyValidation = await intelligence.validateDependencyExecution(results)
        XCTAssertTrue(dependencyValidation, "Dependencies should be executed in correct order")
        
        print("📊 Dependent Feature Execution: \(String(format: "%.3f", duration))s")
    }
    
    // MARK: - TDD Phase 3: Load Balancing Tests
    
    /// Test: Intelligence load balancer should distribute operations efficiently
    func testIntelligenceLoadBalancing() async throws {
        // RED: This test should fail initially
        
        let operations: [IntelligenceOperation] = [
            .performanceAnalysis,
            .patternDetection,
            .componentIntrospection,
            .documentationGeneration,
            .riskPrediction
        ]
        
        let startTime = Date()
        
        // This should use load balancing for operation distribution
        let results = try await intelligence.executeOperationsWithLoadBalancing(operations)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify all operations completed
        XCTAssertEqual(results.count, operations.count, "All operations should complete")
        
        // Verify load balancing metrics
        let balancingMetrics = await intelligence.getLoadBalancingMetrics()
        XCTAssertGreaterThan(balancingMetrics.workerUtilization, 0.0, "Workers should be utilized")
        XCTAssertLessThan(balancingMetrics.queueWaitTime, 0.1, "Queue wait time should be minimal")
        
        print("📊 Load Balanced Operations: \(String(format: "%.3f", duration))s")
        print("📊 Worker Utilization: \(String(format: "%.1f%%", balancingMetrics.workerUtilization * 100))")
    }
    
    /// Test: Load balancer should handle high concurrent load efficiently
    func testHighConcurrentLoadHandling() async throws {
        // RED: This test should fail initially
        
        let numberOfOperations = 20
        let operations = Array(repeating: IntelligenceOperation.patternDetection, count: numberOfOperations)
        
        let startTime = Date()
        
        // This should handle high concurrent load with load balancing
        let results = try await intelligence.executeOperationsWithLoadBalancing(operations)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify all operations completed
        XCTAssertEqual(results.count, numberOfOperations, "All operations should complete")
        
        // Performance expectation: Should handle high load efficiently
        let operationsPerSecond = Double(numberOfOperations) / duration
        XCTAssertGreaterThan(operationsPerSecond, 10.0, "Should handle at least 10 operations per second")
        
        print("📊 High Load Performance: \(String(format: "%.1f", operationsPerSecond)) ops/sec")
    }
    
    // MARK: - TDD Phase 4: Performance Improvement Validation Tests
    
    /// Test: Parallel processing should significantly improve intelligence query response times
    func testIntelligenceQueryPerformanceImprovement() async throws {
        // RED: This test should fail initially until parallel processing is implemented
        
        let complexQuery = "Analyze the architectural patterns, detect performance bottlenecks, predict risks, and generate documentation for all components"
        
        let startTime = Date()
        
        // This should use parallel processing for complex multi-feature queries
        let response = try await intelligence.processComplexQueryWithParallelProcessing(complexQuery)
        
        let parallelDuration = Date().timeIntervalSince(startTime)
        
        // Verify response quality
        XCTAssertFalse(response.answer.isEmpty, "Query should return meaningful answer")
        XCTAssertGreaterThan(response.confidence, 0.7, "Response should have high confidence")
        XCTAssertEqual(response.query, complexQuery, "Response should match query")
        
        // Performance target: <100ms for intelligence queries (Phase 3 goal)
        XCTAssertLessThan(parallelDuration, 0.1, "Intelligence query should complete within 100ms target")
        
        print("📊 Complex Query Performance: \(String(format: "%.3f", parallelDuration))s")
        print("📊 Response Confidence: \(String(format: "%.1f%%", response.confidence * 100))")
    }
    
    /// Test: Concurrent pattern detection should scale beyond current 3-operation limit
    func testEnhancedPatternDetectionConcurrency() async throws {
        // RED: This test should fail initially
        
        let startTime = Date()
        
        // This should use enhanced concurrent pattern detection
        let patterns = try await intelligence.detectPatternsWithEnhancedConcurrency()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify pattern detection results
        XCTAssertFalse(patterns.isEmpty, "Should detect patterns")
        
        // Verify concurrent execution metrics
        let concurrencyMetrics = await intelligence.getPatternDetectionMetrics()
        XCTAssertGreaterThan(concurrencyMetrics.maxConcurrentOperations, 3, "Should exceed current 3-operation limit")
        
        // Performance expectation: Should be faster than sequential processing
        XCTAssertLessThan(duration, 0.5, "Enhanced pattern detection should complete within 500ms")
        
        print("📊 Enhanced Pattern Detection: \(String(format: "%.3f", duration))s")
        print("📊 Max Concurrent Operations: \(concurrencyMetrics.maxConcurrentOperations)")
    }
    
    // MARK: - TDD Phase 5: Resource Management Tests
    
    /// Test: Parallel processing should maintain memory efficiency
    func testParallelProcessingMemoryEfficiency() async throws {
        // RED: This test should fail initially
        
        let initialMemory = await intelligence.getCurrentMemoryUsage()
        
        // Execute multiple concurrent operations
        let operations = Array(repeating: IntelligenceOperation.componentIntrospection, count: 10)
        let _ = try await intelligence.executeOperationsWithLoadBalancing(operations)
        
        let finalMemory = await intelligence.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory efficiency requirement: <50MB total usage
        XCTAssertLessThan(finalMemory, 50 * 1024 * 1024, "Total memory should stay under 50MB")
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory increase should be under 10MB")
        
        print("📊 Memory Usage: \(finalMemory / 1024 / 1024)MB")
        print("📊 Memory Increase: \(memoryIncrease / 1024 / 1024)MB")
    }
    
    /// Test: Concurrent operations should not exceed configured limits
    func testConcurrentOperationLimits() async throws {
        // RED: This test should fail initially
        
        let maxConcurrentOperations = 8
        let operationCount = 20
        
        let startTime = Date()
        var peakConcurrentOperations = 0
        
        // Monitor concurrent operations during execution
        let monitoringTask = Task {
            while Date().timeIntervalSince(startTime) < 2.0 {
                let currentConcurrent = await intelligence.getCurrentConcurrentOperations()
                peakConcurrentOperations = max(peakConcurrentOperations, currentConcurrent)
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        // Execute operations
        let operations = Array(repeating: IntelligenceOperation.riskPrediction, count: operationCount)
        let _ = try await intelligence.executeOperationsWithLoadBalancing(operations)
        
        monitoringTask.cancel()
        
        // Verify concurrent operation limits were respected
        XCTAssertLessThanOrEqual(peakConcurrentOperations, maxConcurrentOperations, 
                                "Should not exceed configured concurrent operation limit")
        
        print("📊 Peak Concurrent Operations: \(peakConcurrentOperations)/\(maxConcurrentOperations)")
    }
}

// MARK: - Test Support (Types are now in main codebase)

// MARK: - Extension for Testing Support

extension DefaultAxiomIntelligence {
    
    // NOTE: The actual implementations are now in AxiomIntelligence.swift
    // These test extension methods are no longer needed since the real implementations exist
    
    // All test support methods are now implemented in the main AxiomIntelligence.swift file
}

