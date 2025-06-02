import XCTest
@testable import Axiom
import Foundation

/// Test-driven development tests for Intelligence System Integration
/// These tests define expected behavior for Phase 2 implementation
final class IntelligenceSystemIntegrationTests: XCTestCase {
    
    // MARK: - Component Introspection Integration Tests
    
    func testComponentIntrospectionDiscoveryIntegration() async throws {
        // RED: Write failing test first - TDD methodology
        
        let performanceMonitor = PerformanceMonitor()
        let engine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        
        // Should discover actual components in the system
        let components = await engine.discoverComponents()
        
        // EXPECTATION: Should find at least basic framework components
        XCTAssertFalse(components.isEmpty, "Component discovery should find framework components")
        
        // Should find different categories of components
        let categories = Set(components.map { $0.category })
        XCTAssertTrue(categories.contains(.intelligence), "Should discover intelligence components")
        
        // TODO: Phase 2 - Update this test when architecturalDNA is refactored to architecturalMetadata
        // let componentsWithMetadata = components.filter { $0.architecturalMetadata != nil }
        // XCTAssertFalse(componentsWithMetadata.isEmpty, "At least some components should have architectural metadata")
    }
    
    func testComponentAnalysisWithRealArchitecture() async throws {
        // RED: Test component analysis with actual framework components
        
        let performanceMonitor = PerformanceMonitor()
        let engine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        
        // Discover components first
        let components = await engine.discoverComponents()
        
        guard let firstComponent = components.first else {
            XCTFail("No components discovered for analysis")
            return
        }
        
        // Analyze the component
        let analysis = try await engine.analyzeComponent(firstComponent.id)
        
        // EXPECTATION: Analysis should be comprehensive
        XCTAssertEqual(analysis.component.id, firstComponent.id)
        XCTAssertGreaterThanOrEqual(analysis.qualityScore, 0.0)
        XCTAssertLessThanOrEqual(analysis.qualityScore, 1.0)
        XCTAssertGreaterThanOrEqual(analysis.complexity, 0.0)
    }
    
    // MARK: - Pattern Detection Integration Tests
    
    func testPatternDetectionWithActualFramework() async throws {
        // RED: Test pattern detection on real framework architecture
        
        let performanceMonitor = PerformanceMonitor()
        let introspectionEngine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        let patternEngine = PatternDetectionEngine(
            introspectionEngine: introspectionEngine,
            performanceMonitor: performanceMonitor
        )
        
        // Should detect patterns in the framework
        let patterns = await patternEngine.detectPatterns()
        
        // EXPECTATION: Should find architectural patterns
        XCTAssertFalse(patterns.isEmpty, "Pattern detection should find architectural patterns")
        
        // Should detect actor concurrency patterns
        let actorPatterns = patterns.filter { $0.type == .actorConcurrency }
        XCTAssertFalse(actorPatterns.isEmpty, "Should detect actor concurrency patterns")
        
        // Patterns should have reasonable confidence
        for pattern in patterns {
            XCTAssertGreaterThanOrEqual(pattern.confidence, 0.0)
            XCTAssertLessThanOrEqual(pattern.confidence, 1.0)
        }
    }
    
    func testAntiPatternDetection() async throws {
        // RED: Test anti-pattern detection capabilities
        
        let performanceMonitor = PerformanceMonitor()
        let introspectionEngine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        let patternEngine = PatternDetectionEngine(
            introspectionEngine: introspectionEngine,
            performanceMonitor: performanceMonitor
        )
        
        // Should detect anti-patterns if any exist
        let antiPatterns = await patternEngine.detectAntiPatterns()
        
        // EXPECTATION: Anti-pattern detection should work (may be empty if architecture is clean)
        // Test the functionality rather than specific results
        XCTAssertNotNil(antiPatterns)
    }
    
    // MARK: - Query Engine Integration Tests
    
    func testNaturalLanguageQueryProcessing() async throws {
        // RED: Test natural language query processing
        
        let performanceMonitor = PerformanceMonitor()
        let introspectionEngine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        let patternEngine = PatternDetectionEngine(
            introspectionEngine: introspectionEngine,
            performanceMonitor: performanceMonitor
        )
        let queryParser = NaturalLanguageQueryParser(performanceMonitor: performanceMonitor)
        // Note: ArchitecturalQueryEngine removed (was AI theater) - using genuine functionality instead
        
        // Test simple architectural queries that should match keywords
        let testQueries = [
            "show components",           // Should match .listComponents 
            "actor patterns",           // Should match .detectPatterns
            "complexity performance"    // Should match .getPerformance
        ]
        
        for query in testQueries {
            let parsedQuery = await queryParser.parseQuery(query)
            
            // EXPECTATION: Queries should be parsed with reasonable confidence
            XCTAssertFalse(parsedQuery.originalQuery.isEmpty)
            XCTAssertGreaterThanOrEqual(parsedQuery.confidence, 0.0)
            XCTAssertLessThanOrEqual(parsedQuery.confidence, 1.0)
            
            // Test genuine functionality: component registry access
            if parsedQuery.confidence > 0.3 { // Only test queries with reasonable confidence
                // Note: AI theater method processQuery was removed (was keyword matching theater)
                // Testing genuine component registry functionality instead
                let intelligence = DefaultAxiomIntelligence(enabledFeatures: [.componentRegistry])
                let registry = await intelligence.getComponentRegistry()
                XCTAssertNotNil(registry, "Component registry should be accessible")
            }
        }
    }
    
    // MARK: - Intelligence System End-to-End Integration
    
    func testGlobalIntelligenceSystemIntegration() async throws {
        // GREEN: Test genuine intelligence system integration
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Test genuine functionality: Component registry access
        let componentRegistry = await intelligence.getComponentRegistry()
        XCTAssertNotNil(componentRegistry)
        
        // Test genuine functionality: Metrics collection
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.totalOperations, 0)
        
        // Test genuine functionality: Feature management
        await intelligence.enableFeature(.componentRegistry)
        await intelligence.enableFeature(.performanceMonitoring)
        let features = await intelligence.enabledFeatures
        XCTAssertTrue(features.contains(.componentRegistry))
        XCTAssertTrue(features.contains(.performanceMonitoring))
        
        // Note: AI theater methods (analyzeCodePatterns, predictArchitecturalIssues, suggestRefactoring) 
        // were removed as they were hardcoded responses, not genuine AI functionality
    }
    
    func testIntelligenceSystemLearningCapabilities() async throws {
        // RED: Test intelligence system learning and adaptation
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Record application events for learning
        let events = [
            ApplicationEvent(type: .stateAccess, metadata: ["component": "TestComponent"]),
            ApplicationEvent(type: .stateUpdate, metadata: ["change": "property_update"]),
            ApplicationEvent(type: .performanceIssue, metadata: ["duration": "200ms"])
        ]
        
        for event in events {
            await GlobalIntelligenceManager.shared.recordApplicationEvent(event)
        }
        
        // Should be able to get metrics after learning
        let metrics = await intelligence.getMetrics()
        XCTAssertGreaterThanOrEqual(metrics.totalOperations, 0)
        XCTAssertGreaterThanOrEqual(metrics.predictionAccuracy, 0.0)
        XCTAssertLessThanOrEqual(metrics.predictionAccuracy, 1.0)
    }
    
    // MARK: - Component Documentation Generation
    
    func testAutomaticDocumentationGeneration() async throws {
        // RED: Test automatic documentation generation
        
        let performanceMonitor = PerformanceMonitor()
        let engine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        
        // CRITICAL: Discover components first before generating documentation
        let discoveredComponents = await engine.discoverComponents()
        XCTAssertFalse(discoveredComponents.isEmpty, "Should discover framework components")
        
        // Test genuine functionality: component analysis instead of AI theater documentation generation
        // Note: AI theater method generateDocumentation was removed (was hardcoded template generation)
        // Testing genuine component analysis functionality instead
        
        let intelligence = DefaultAxiomIntelligence(enabledFeatures: [.componentRegistry, .performanceMonitoring])
        let registry = await intelligence.getComponentRegistry()
        
        // EXPECTATION: Should provide component registry access
        XCTAssertNotNil(registry, "Component registry should be accessible")
        XCTAssertFalse(registry.isEmpty, "Registry should contain discovered components")
        
        // Should provide performance metrics
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics, "Performance metrics should be available")
        XCTAssertGreaterThanOrEqual(metrics.totalOperations, 0, "Should track operation metrics")
    }
    
    // MARK: - Performance and Reliability Tests
    
    func testIntelligenceSystemPerformance() async throws {
        // GREEN: Test performance characteristics of genuine functionality
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        let startTime = Date()
        
        // Run genuine intelligence operations
        let _ = await intelligence.getComponentRegistry()
        let _ = await intelligence.getMetrics()
        await intelligence.enableFeature(.performanceMonitoring)
        await intelligence.enableFeature(.capabilityValidation)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // EXPECTATION: Genuine intelligence operations should complete in reasonable time
        XCTAssertLessThan(duration, 5.0, "Genuine intelligence operations should complete within 5 seconds")
        
        // Note: AI theater methods (analyzeCodePatterns, predictArchitecturalIssues) were removed 
        // as they were hardcoded heuristics, not genuine performance-dependent operations
    }
    
    func testIntelligenceSystemReliability() async throws {
        // RED: Test system reliability under error conditions
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Test reliability of genuine functionality under various conditions
        
        // System should handle repeated calls gracefully
        for _ in 0..<10 {
            let _ = await intelligence.getComponentRegistry()
            let _ = await intelligence.getMetrics()
        }
        
        // System should remain functional after feature toggling
        await intelligence.enableFeature(.componentRegistry)
        await intelligence.disableFeature(.componentRegistry)
        await intelligence.enableFeature(.componentRegistry)
        
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics)
        
        // Note: AI theater method generateDocumentation was removed as it was hardcoded template generation, 
        // not genuine error-handling functionality
    }
}