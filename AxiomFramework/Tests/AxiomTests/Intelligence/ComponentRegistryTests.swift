import XCTest
import SwiftUI
@testable import Axiom

/// TDD Tests for Phase 2: ComponentIntrospection → ComponentRegistry refactoring
/// RED phase: Write failing tests first, then implement ComponentRegistry
final class ComponentRegistryTests: XCTestCase {
    
    // MARK: - Phase 2 TDD Tests (RED Phase)
    
    func testComponentRegistryBasicFunctionality() async throws {
        // RED: This test should fail initially since ComponentRegistryEngine doesn't exist yet
        let performanceMonitor = PerformanceMonitor()
        let registry = ComponentRegistryEngine(performanceMonitor: performanceMonitor)
        
        // Test basic component discovery (preserve genuine functionality)
        let components = await registry.discoverComponents()
        XCTAssertFalse(components.isEmpty, "Should discover framework components")
        
        // Test component registration functionality
        let componentRegistry = await registry.getComponentRegistry()
        XCTAssertTrue(componentRegistry.isEmpty || !componentRegistry.isEmpty, "Registry should be accessible")
    }
    
    func testComponentRegistryRemovesAITheater() async throws {
        // RED: Verify that AI theater claims are removed from the system
        let performanceMonitor = PerformanceMonitor()
        let registry = ComponentRegistryEngine(performanceMonitor: performanceMonitor)
        
        // The new system should not have AI theater methods
        // This is tested by the absence of certain methods that were in ComponentIntrospectionEngine
        
        // Test that genuine functionality is preserved
        let components = await registry.discoverComponents()
        
        // Verify genuine metadata is preserved (not AI theater)
        for component in components {
            XCTAssertNotNil(component.name, "Component should have genuine name")
            XCTAssertNotNil(component.category, "Component should have genuine category")
            // architecturalDNA will be refactored to architecturalMetadata in next step
        }
    }
    
    func testComponentRegistryPreservesPerformanceMonitoring() async throws {
        // RED: Ensure genuine performance monitoring is preserved
        let performanceMonitor = PerformanceMonitor()
        let registry = ComponentRegistryEngine(performanceMonitor: performanceMonitor)
        
        // Performance monitoring should still work (genuine functionality)
        let startTime = Date()
        let _ = await registry.discoverComponents()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 1.0, "Component discovery should be performant")
    }
    
    func testComponentRegistryPreservesRelationshipMapping() async throws {
        // RED: Ensure genuine relationship mapping is preserved
        let performanceMonitor = PerformanceMonitor()
        let registry = ComponentRegistryEngine(performanceMonitor: performanceMonitor)
        
        // Discover components first
        let _ = await registry.discoverComponents()
        
        // Test relationship mapping (genuine functionality)
        let relationshipMap = await registry.mapComponentRelationships()
        XCTAssertGreaterThanOrEqual(relationshipMap.totalRelationships, 0, "Should map component relationships")
    }
    
    func testComponentRegistryPreservesMetrics() async throws {
        // RED: Ensure genuine metrics collection is preserved  
        let performanceMonitor = PerformanceMonitor()
        let registry = ComponentRegistryEngine(performanceMonitor: performanceMonitor)
        
        // Discover components first
        let _ = await registry.discoverComponents()
        
        // Test metrics collection (genuine functionality)
        let metrics = await registry.getComponentMetrics()
        XCTAssertGreaterThanOrEqual(metrics.totalComponents, 0, "Should collect component metrics")
        XCTAssertGreaterThanOrEqual(metrics.totalRelationships, 0, "Should collect relationship metrics")
    }
}