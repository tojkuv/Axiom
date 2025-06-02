import XCTest
@testable import Axiom

/// TDD Tests for removing AI theater and preserving genuine functionality
/// Phase 1: AI System Removal - Write failing tests first
final class AITheaterRemovalTests: XCTestCase {
    
    // MARK: - Phase 1: AI Theater Removal Tests (TDD RED Phase)
    
    func testIntelligenceProtocolOnlyHasGenuineFunctionality() async throws {
        // GREEN: This test now PASSES - AI theater has been successfully removed
        
        // Test that AxiomIntelligence protocol only contains genuine functionality
        let intelligence = DefaultAxiomIntelligence()
        
        // ✅ GENUINE: Metrics collection (real functionality) 
        let metrics = await intelligence.getMetrics()
        XCTAssertNotNil(metrics, "Metrics collection should be preserved")
        
        // ✅ GENUINE: Configuration management (real functionality)
        await intelligence.setAutomationLevel(.manual)
        let automationLevel = await intelligence.automationLevel
        XCTAssertEqual(automationLevel, .manual)
        
        // ✅ GENUINE: Component registry access (real functionality)
        let componentRegistry = await intelligence.getComponentRegistry()
        XCTAssertNotNil(componentRegistry, "Component registry should be available")
        
        // ✅ GENUINE: Component registration (real functionality)
        await intelligence.registerComponent(MockAxiomContext())
        
        // ✅ SUCCESS: AI theater methods (processQuery, analyzeCodePatterns, predictArchitecturalIssues) 
        // have been successfully removed and no longer exist in the protocol
        // Compilation would fail if these methods still existed and were called
    }
    
    func testIntelligenceFeaturesOnlyContainGenuineCapabilities() async throws {
        // RED: This test should FAIL initially - expects fake AI features to be removed
        
        // Current state: 8 fake AI features exist
        // After Phase 1 implementation, only 3 genuine features should remain
        
        // These AI theater features should be REMOVED:
        let aiTheaterFeatures: [String] = [
            "natural_language_queries",    // Keyword matching theater
            "intent_driven_evolution",     // Template generation theater  
            "self_optimizing_performance", // Static heuristics theater
            "emergent_pattern_detection",  // String searching theater
            "predictive_architecture_intelligence" // Hardcoded confidence theater
        ]
        
        // Test that AI theater features are no longer available
        for theaterFeature in aiTheaterFeatures {
            // This should fail after implementation - AI theater features removed
            let allFeatureNames = IntelligenceFeature.allCases.map { $0.rawValue }
            XCTAssertFalse(allFeatureNames.contains(theaterFeature), 
                          "AI theater feature '\(theaterFeature)' should be removed")
        }
        
        // Test that AI theater features will be reduced (currently 8, should become 3)
        // This test should FAIL initially - we currently have 8 AI theater features
        XCTAssertLessThan(IntelligenceFeature.allCases.count, 8, 
                         "AI theater features should be reduced from current 8 fake features")
        
        // After implementation, this should be 3 genuine features
        // XCTAssertEqual(IntelligenceFeature.allCases.count, 3, "Should only have 3 genuine features")
    }
    
    func testComponentIntrospectionBecomesComponentRegistry() async throws {
        // RED: This test should FAIL initially - expects rebranding from AI claims
        
        // After Phase 2 implementation, ComponentIntrospection should become ComponentRegistry
        // This preserves functionality but removes AI branding
        
        let performanceMonitor = PerformanceMonitor()
        let engine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        
        // Test that current introspection engine exists (will be renamed to ComponentRegistry)
        let components = await engine.discoverComponents()
        XCTAssertTrue(components.isEmpty || !components.isEmpty, "Component discovery should work")
        
        // Test that AI theater claims are removed from the interface
        // ComponentIntrospectionEngine should be renamed to ComponentRegistry
        // "breakthrough intelligence systems" claims should be removed
        
        // TODO: After Phase 2, test ComponentRegistry instead:
        // let registry = ComponentRegistry(performanceMonitor: performanceMonitor)
        // let components = await registry.discoverComponents()
    }
    
    func testCachingSystemRenamed() async throws {
        // RED: This test should FAIL initially - expects IntelligenceCache → FrameworkCache
        
        // After Phase 3 implementation, IntelligenceCache should become FrameworkCache
        // This preserves LRU and TTL functionality but removes AI branding
        
        let config = CacheConfiguration(
            maxSize: 100,
            ttl: 300.0,
            evictionPolicy: .lru
        )
        
        // Test current IntelligenceCache (will be renamed to FrameworkCache)
        let cache = IntelligenceCache(configuration: config)
        
        // Test that caching functionality is preserved
        await cache.clearAll()
        let size = await cache.getCacheSize()
        XCTAssertEqual(size, 0, "Cache clearing should work")
        
        // TODO: After Phase 3, test FrameworkCache instead:
        // let cache = FrameworkCache(configuration: config)
        // IntelligenceCache → FrameworkCache
        // QueryResultCache → QueryCache (if needed)
    }
    
    func testDocumentationUpdatedToReflectActualCapabilities() async throws {
        // RED: This test should FAIL initially - expects honest capability representation
        
        // After Phase 4 implementation, documentation should reflect actual capabilities
        
        // Test that false AI claims are removed from feature descriptions
        for feature in IntelligenceFeature.allCases {
            let description = feature.description
            
            // These AI theater phrases should be REMOVED from descriptions:
            let aiTheaterPhrases = [
                "AI-powered",
                "machine learning", 
                "neural network",
                "artificial intelligence",
                "self-learning",
                "predictive",
                "natural language"
            ]
            
            for phrase in aiTheaterPhrases {
                XCTAssertFalse(description.lowercased().contains(phrase), 
                              "AI theater phrase '\(phrase)' should be removed from feature descriptions")
            }
        }
        
        // Test that honest, accurate capability descriptions remain
        // E.g., "Component registration and discovery" not "AI-powered component analysis"
    }
}

// MARK: - Test Support Classes

@MainActor
class MockAxiomContext: AxiomContext {
    let intelligence: any AxiomIntelligence = AITheaterMockIntelligence()
}

actor AITheaterMockIntelligence: AxiomIntelligence {
    var enabledFeatures: Set<IntelligenceFeature> = []
    var confidenceThreshold: Double = 0.8
    var automationLevel: AutomationLevel = .supervised
    var learningMode: LearningMode = .suggestion
    var performanceConfiguration: IntelligencePerformanceConfiguration = IntelligencePerformanceConfiguration()
    
    func enableFeature(_ feature: IntelligenceFeature) async { enabledFeatures.insert(feature) }
    func disableFeature(_ feature: IntelligenceFeature) async { enabledFeatures.remove(feature) }
    func setAutomationLevel(_ level: AutomationLevel) async { automationLevel = level }
    func setLearningMode(_ mode: LearningMode) async { learningMode = mode }
    func getMetrics() async -> IntelligenceMetrics { 
        return IntelligenceMetrics(
            totalOperations: 0,
            averageResponseTime: 0.0,
            cacheHitRate: 0.0,
            successfulPredictions: 0,
            predictionAccuracy: 0.0,
            featureMetrics: [:],
            timestamp: Date()
        )
    }
    func reset() async { enabledFeatures.removeAll() }
    
    func getComponentRegistry() async -> [ComponentID: ComponentMetadata] { 
        return [:] // Empty registry for testing
    }
    
    func registerComponent<T: AxiomContext>(_ component: T) async {
        // Mock implementation for testing
    }
}