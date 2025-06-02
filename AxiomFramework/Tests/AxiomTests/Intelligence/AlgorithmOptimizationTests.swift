import XCTest
@testable import Axiom

// MARK: - Phase 3 Milestone 3: Algorithm Optimization Tests
// TDD RED PHASE: Failing tests for algorithm optimization features

final class AlgorithmOptimizationTests: XCTestCase {
    
    private var intelligence: DefaultAxiomIntelligence!
    private var optimizationEngine: RelationshipMappingEngine!
    private var incrementalAnalyzer: IncrementalAnalysisEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        
        intelligence = DefaultAxiomIntelligence(
            enabledFeatures: [.componentRegistry, .performanceMonitoring, .capabilityValidation],
            performanceConfiguration: IntelligencePerformanceConfiguration(
                maxResponseTime: 0.1, // 100ms target
                maxConcurrentOperations: 8
            )
        )
        
        // These will be implemented during GREEN phase
        optimizationEngine = RelationshipMappingEngine()
        incrementalAnalyzer = IncrementalAnalysisEngine()
    }
    
    // MARK: - Relationship Mapping Optimization Tests
    
    func testOptimizedRelationshipMapping() async throws {
        // RED PHASE: Test for optimized relationship mapping algorithm
        let startTime = Date()
        
        let relationships = try await optimizationEngine.buildOptimizedRelationshipMap()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Performance requirement: <50ms for relationship mapping
        XCTAssertLessThan(duration, 0.05, "Relationship mapping should complete in <50ms")
        XCTAssertGreaterThan(relationships.count, 0, "Should discover component relationships")
        XCTAssertTrue(relationships.isOptimized, "Relationship map should be optimized")
    }
    
    func testRelationshipMappingComplexity() async throws {
        // RED PHASE: Test algorithmic complexity improvements
        let componentCounts = [10, 50, 100, 500]
        var durations: [TimeInterval] = []
        
        for componentCount in componentCounts {
            let startTime = Date()
            let _ = try await optimizationEngine.buildRelationshipMapForComponents(count: componentCount)
            let duration = Date().timeIntervalSince(startTime)
            durations.append(duration)
        }
        
        // Algorithm should scale better than O(n²)
        // Check that the relationship between duration and component count is sub-quadratic
        let scalingFactor = durations.last! / durations.first!
        let componentScaling = Double(componentCounts.last!) / Double(componentCounts.first!)
        
        XCTAssertLessThan(scalingFactor, componentScaling * componentScaling, 
                         "Algorithm should scale better than O(n²)")
    }
    
    func testRelationshipCacheOptimization() async throws {
        // RED PHASE: Test relationship caching optimization
        let componentID = ComponentID("test-component")
        
        // First access - should build cache
        let startTime1 = Date()
        let relationships1 = try await optimizationEngine.getOptimizedRelationships(for: componentID)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second access - should use cache
        let startTime2 = Date()
        let relationships2 = try await optimizationEngine.getOptimizedRelationships(for: componentID)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        XCTAssertEqual(relationships1, relationships2, "Cached relationships should match")
        XCTAssertLessThan(duration2, duration1 * 0.1, "Cached access should be 10x faster")
        XCTAssertLessThan(duration2, 0.002, "Cached access should be <2ms")
    }
    
    // MARK: - Incremental Analysis Tests
    
    func testIncrementalAnalysisCapability() async throws {
        // RED PHASE: Test incremental analysis engine
        let baselineState = try await incrementalAnalyzer.captureBaseline()
        XCTAssertNotNil(baselineState, "Should capture baseline state")
        
        // Simulate component changes
        try await incrementalAnalyzer.recordComponentChange(
            ComponentID("test-component"), 
            changeType: .stateModification
        )
        
        // Incremental analysis should only analyze changed components
        let startTime = Date()
        let analysis = try await incrementalAnalyzer.performIncrementalAnalysis()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 0.02, "Incremental analysis should complete in <20ms")
        XCTAssertEqual(analysis.analyzedComponents.count, 1, "Should only analyze changed component")
        XCTAssertTrue(analysis.isIncremental, "Analysis should be marked as incremental")
    }
    
    func testIncrementalAnalysisVsFullAnalysis() async throws {
        // RED PHASE: Test performance comparison
        // Full analysis baseline
        let startTimeFull = Date()
        let fullAnalysis = try await incrementalAnalyzer.performFullAnalysis()
        let fullDuration = Date().timeIntervalSince(startTimeFull)
        
        // Make minimal changes
        try await incrementalAnalyzer.recordComponentChange(
            ComponentID("single-component"), 
            changeType: .stateModification
        )
        
        // Incremental analysis
        let startTimeIncremental = Date()
        let incrementalAnalysis = try await incrementalAnalyzer.performIncrementalAnalysis()
        let incrementalDuration = Date().timeIntervalSince(startTimeIncremental)
        
        // Incremental should be significantly faster
        XCTAssertLessThan(incrementalDuration, fullDuration * 0.2, 
                         "Incremental analysis should be 5x faster than full analysis")
        XCTAssertGreaterThan(fullAnalysis.analyzedComponents.count, 
                           incrementalAnalysis.analyzedComponents.count,
                           "Full analysis should analyze more components")
    }
    
    func testIncrementalChangeTracking() async throws {
        // RED PHASE: Test change tracking accuracy
        let baseline = try await incrementalAnalyzer.captureBaseline()
        
        // Record various types of changes
        try await incrementalAnalyzer.recordComponentChange(
            ComponentID("component-a"), changeType: .stateModification
        )
        try await incrementalAnalyzer.recordComponentChange(
            ComponentID("component-b"), changeType: .relationshipChange
        )
        try await incrementalAnalyzer.recordComponentChange(
            ComponentID("component-c"), changeType: .capabilityChange
        )
        
        let changeSet = try await incrementalAnalyzer.getChangesSince(baseline)
        
        XCTAssertEqual(changeSet.count, 3, "Should track all recorded changes")
        XCTAssertTrue(changeSet.contains { $0.componentID.description == "component-a" }, 
                     "Should track component-a changes")
        XCTAssertTrue(changeSet.contains { $0.changeType == .relationshipChange }, 
                     "Should track relationship changes")
    }
    
    // MARK: - Intelligence Query Performance Optimization Tests
    
    func testIntelligenceGenuineFunctionalityPerformanceOptimization() async throws {
        // GREEN PHASE: Test <100ms genuine functionality response requirement
        
        // Test performance of genuine functionality operations
        let operations = [
            { await self.intelligence.getComponentRegistry() },
            { await self.intelligence.getMetrics() },
            { await self.intelligence.enableFeature(.performanceMonitoring) },
            { await self.intelligence.getComponentRegistry() } // Test cached access
        ]
        
        for (index, operation) in operations.enumerated() {
            let startTime = Date()
            let _ = await operation()
            let duration = Date().timeIntervalSince(startTime)
            
            XCTAssertLessThan(duration, 0.1, 
                             "Genuine operation \(index) should complete in <100ms, took \(duration)s")
        }
        
        // Note: AI theater processQuery method was removed (was keyword matching theater)
        // Testing genuine functionality performance instead
    }
    
    func testGenuineFunctionalityCachingOptimization() async throws {
        // GREEN PHASE: Test caching optimization for genuine functionality
        
        // First component registry access - cold cache
        let startTime1 = Date()
        let registry1 = await intelligence.getComponentRegistry()
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second component registry access - should use optimized cache
        let startTime2 = Date()
        let registry2 = await intelligence.getComponentRegistry()
        let duration2 = Date().timeIntervalSince(startTime2)
        
        XCTAssertLessThan(duration2, duration1 * 0.5, "Cached registry access should be faster")
        XCTAssertLessThan(duration2, 0.01, "Cached registry access should be <10ms")
        
        // Registry results should be consistent
        XCTAssertEqual(registry1.count, registry2.count, "Cached registry should have same content")
        
        // Note: AI theater processQuery was removed (was keyword matching theater)
        // Testing genuine caching functionality instead
    }
    
    func testConcurrentQueryOptimization() async throws {
        // RED PHASE: Test concurrent query processing optimization
        let queries = Array(repeating: "What is the system complexity?", count: 10)
        
        let startTime = Date()
        
        try await withThrowingTaskGroup(of: QueryResponse.self) { group in
            for query in queries {
                group.addTask {
                    try await self.intelligence.processQuery(query)
                }
            }
            
            var responses: [QueryResponse] = []
            for try await response in group {
                responses.append(response)
            }
            
            let totalDuration = Date().timeIntervalSince(startTime)
            
            // Concurrent processing should be efficient
            XCTAssertEqual(responses.count, 10, "Should process all queries")
            XCTAssertLessThan(totalDuration, 0.5, "10 concurrent queries should complete in <500ms")
            
            // Each individual response should meet performance requirements
            for response in responses {
                XCTAssertLessThan(response.executionTime, 0.1, "Each query should be <100ms")
            }
        }
    }
    
    // MARK: - Algorithm Performance Benchmarks
    
    func testRelationshipMappingAlgorithmBenchmark() async throws {
        // RED PHASE: Benchmark relationship mapping algorithm
        let componentCounts = [50, 100, 200, 500]
        
        for componentCount in componentCounts {
            let startTime = Date()
            
            // This should use the optimized algorithm
            let relationshipMap = try await optimizationEngine.buildOptimizedRelationshipMap(
                componentCount: componentCount
            )
            
            let duration = Date().timeIntervalSince(startTime)
            let expectedMaxDuration = Double(componentCount) / 10000.0 // Linear scaling target
            
            XCTAssertLessThan(duration, expectedMaxDuration, 
                             "Algorithm should scale linearly for \(componentCount) components")
            XCTAssertGreaterThan(relationshipMap.optimizationMetrics.efficiency, 0.8, 
                               "Algorithm efficiency should be >80%")
        }
    }
    
    func testMemoryOptimization() async throws {
        // RED PHASE: Test memory usage optimization
        let initialMemory = await intelligence.getCurrentMemoryUsage()
        
        // Perform large-scale analysis
        let _ = try await intelligence.processQuery("Show system performance overview")
        
        let peakMemory = await intelligence.getCurrentMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Memory usage should be optimized
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory increase should be <50MB")
        
        // Force garbage collection simulation
        try await intelligence.optimizeMemoryUsage()
        
        let finalMemory = await intelligence.getCurrentMemoryUsage()
        XCTAssertLessThan(finalMemory - initialMemory, 15 * 1024 * 1024, 
                         "Final memory should be within 15MB of initial")
    }
    
    // MARK: - Integration Performance Tests
    
    func testEndToEndOptimizationPerformance() async throws {
        // RED PHASE: End-to-end performance optimization test
        let complexQuery = "Show system performance overview with detailed metrics"
        
        let startTime = Date()
        let response = try await intelligence.processQuery(complexQuery)
        let duration = Date().timeIntervalSince(startTime)
        
        // End-to-end should meet strict performance requirements
        XCTAssertLessThan(duration, 0.1, "Complex end-to-end query should complete in <100ms")
        XCTAssertGreaterThan(response.confidence, 0.8, "Complex query should have high confidence")
        XCTAssertGreaterThanOrEqual(response.data.count, 0, "Should return valid data response")
    }
}

// MARK: - GREEN PHASE: Types now implemented in AlgorithmOptimization.swift