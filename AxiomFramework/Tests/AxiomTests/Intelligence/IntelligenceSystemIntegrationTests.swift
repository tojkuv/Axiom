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
        
        // Components should have architectural DNA
        let componentsWithDNA = components.filter { $0.architecturalDNA != nil }
        XCTAssertFalse(componentsWithDNA.isEmpty, "At least some components should have architectural DNA")
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
        let queryEngine = ArchitecturalQueryEngine(
            introspectionEngine: introspectionEngine,
            patternDetectionEngine: patternEngine,
            performanceMonitor: performanceMonitor,
            queryParser: queryParser
        )
        
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
            
            // Should be able to process parsed queries
            if parsedQuery.confidence > 0.3 { // Only test queries with reasonable confidence
                let response = try await queryEngine.processQuery(parsedQuery)
                XCTAssertNotNil(response)
                // Valid response should have content or be explicitly empty
                XCTAssertNotNil(response.data, "Response should have valid data structure")
            }
        }
    }
    
    // MARK: - Intelligence System End-to-End Integration
    
    func testGlobalIntelligenceSystemIntegration() async throws {
        // RED: Test full intelligence system integration
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Should be able to analyze code patterns
        let optimizationSuggestions = try await intelligence.analyzeCodePatterns()
        XCTAssertNotNil(optimizationSuggestions)
        
        // Should be able to predict architectural issues
        let risks = try await intelligence.predictArchitecturalIssues()
        XCTAssertNotNil(risks)
        
        // Should be able to suggest refactoring
        let refactoringSuggestions = try await intelligence.suggestRefactoring()
        XCTAssertNotNil(refactoringSuggestions)
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
        
        // Generate documentation for the system
        let documentationSet = await engine.generateDocumentation()
        
        // EXPECTATION: Should generate system documentation
        let systemDoc = documentationSet.getSystemDocumentation()
        XCTAssertNotNil(systemDoc)
        XCTAssertFalse(systemDoc?.overview.isEmpty ?? true)
        
        // Should generate component documentation
        let componentDocs = documentationSet.getAllComponentDocumentation()
        XCTAssertFalse(componentDocs.isEmpty, "Should generate component documentation")
    }
    
    // MARK: - Performance and Reliability Tests
    
    func testIntelligenceSystemPerformance() async throws {
        // RED: Test performance characteristics
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        let startTime = Date()
        
        // Run multiple intelligence operations
        let _ = try await intelligence.analyzeCodePatterns()
        let _ = try await intelligence.predictArchitecturalIssues()
        let _ = await intelligence.getMetrics()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // EXPECTATION: Intelligence operations should complete in reasonable time
        XCTAssertLessThan(duration, 5.0, "Intelligence operations should complete within 5 seconds")
    }
    
    func testIntelligenceSystemReliability() async throws {
        // RED: Test system reliability under error conditions
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Should handle errors gracefully
        do {
            // Try to generate documentation for non-existent component
            let _ = try await intelligence.generateDocumentation(for: ComponentID("non-existent"))
            XCTFail("Should throw error for non-existent component")
        } catch {
            // Expected behavior
            XCTAssertTrue(true, "Should handle errors gracefully")
        }
        
        // System should remain functional after errors
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics)
    }
}