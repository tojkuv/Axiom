import XCTest
@testable import Axiom

final class DAGCompositionTests: XCTestCase {
    // Test that circular dependencies in Capabilities are detected
    func testCircularDependenciesInCapabilities() {
        let validator = DAGValidator()
        
        // Create circular dependency: A -> B -> C -> A
        validator.addDependency(from: "CapabilityA", to: "CapabilityB", type: .capability)
        validator.addDependency(from: "CapabilityB", to: "CapabilityC", type: .capability)
        validator.addDependency(from: "CapabilityC", to: "CapabilityA", type: .capability)
        
        let validation = validator.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.cycles.count, 1)
        
        // The cycle can be detected from any starting point, so check it contains the expected nodes
        XCTAssertNotNil(validation.errorMessage)
        XCTAssertTrue(validation.errorMessage!.contains("Circular dependency detected in capabilities"))
        XCTAssertTrue(validation.errorMessage!.contains("CapabilityA"))
        XCTAssertTrue(validation.errorMessage!.contains("CapabilityB"))
        XCTAssertTrue(validation.errorMessage!.contains("CapabilityC"))
    }
    
    // Test that circular dependencies in Contexts are detected
    func testCircularDependenciesInContexts() {
        let validator = DAGValidator()
        
        // Create circular dependency: Context1 -> Context2 -> Context1
        validator.addDependency(from: "Context1", to: "Context2", type: .context)
        validator.addDependency(from: "Context2", to: "Context1", type: .context)
        
        let validation = validator.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.cycles.count, 1)
        
        // The cycle can be detected from any starting point, so check it contains the expected nodes
        XCTAssertNotNil(validation.errorMessage)
        XCTAssertTrue(validation.errorMessage!.contains("Circular dependency detected in contexts"))
        XCTAssertTrue(validation.errorMessage!.contains("Context1"))
        XCTAssertTrue(validation.errorMessage!.contains("Context2"))
    }
    
    // Test that topological sort succeeds for valid DAGs
    func testTopologicalSortSucceedsForValidDAG() {
        let validator = DAGValidator()
        
        // Create valid DAG for capabilities
        validator.addDependency(from: "NetworkCapability", to: "HTTPCapability", type: .capability)
        validator.addDependency(from: "HTTPCapability", to: "URLSessionCapability", type: .capability)
        validator.addDependency(from: "AuthCapability", to: "HTTPCapability", type: .capability)
        
        let validation = validator.validate()
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.cycles.count, 0)
        
        // Verify topological sort produces valid ordering
        let sorted = validator.topologicalSort()
        XCTAssertNotNil(sorted)
        
        // Verify dependencies are respected
        let indices = sorted!.enumerated().reduce(into: [String: Int]()) { dict, pair in
            dict[pair.element] = pair.offset
        }
        
        XCTAssertLessThan(indices["URLSessionCapability"]!, indices["HTTPCapability"]!)
        XCTAssertLessThan(indices["HTTPCapability"]!, indices["NetworkCapability"]!)
        XCTAssertLessThan(indices["HTTPCapability"]!, indices["AuthCapability"]!)
    }
    
    // Test graph validation with 20 nodes
    func testGraphValidationWith20Nodes() {
        let validator = DAGValidator()
        
        // Create a valid DAG with 20 capability nodes
        for i in 0..<20 {
            let node = "Capability\(i)"
            
            // Create dependencies to previous nodes (valid DAG)
            if i > 0 {
                validator.addDependency(from: node, to: "Capability\(i-1)", type: .capability)
            }
            if i > 5 {
                validator.addDependency(from: node, to: "Capability\(i-5)", type: .capability)
            }
        }
        
        let startTime = Date()
        let validation = validator.validate()
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.cycles.count, 0)
        XCTAssertLessThan(elapsedTime, 0.1) // Should complete quickly
        
        // Verify topological sort works
        let sorted = validator.topologicalSort()
        XCTAssertNotNil(sorted)
        XCTAssertEqual(sorted!.count, 20)
    }
    
    // Test that self-cycles are detected
    func testSelfCyclesAreDetected() {
        let validator = DAGValidator()
        
        // Create self-cycle
        validator.addDependency(from: "CapabilityA", to: "CapabilityA", type: .capability)
        
        let validation = validator.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(
            validation.errorMessage,
            "Self-dependency detected: CapabilityA depends on itself"
        )
    }
    
    // Test complex cycle detection
    func testComplexCycleDetection() {
        let validator = DAGValidator()
        
        // Create complex graph with multiple cycles
        validator.addDependency(from: "A", to: "B", type: .capability)
        validator.addDependency(from: "B", to: "C", type: .capability)
        validator.addDependency(from: "C", to: "D", type: .capability)
        validator.addDependency(from: "D", to: "B", type: .capability) // Cycle: B->C->D->B
        validator.addDependency(from: "E", to: "F", type: .capability)
        validator.addDependency(from: "F", to: "E", type: .capability) // Cycle: E->F->E
        
        let validation = validator.validate()
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.cycles.count, 2)
        
        // Should detect both cycles
        let cycleDescriptions = validation.cycles.map { $0.description }
        XCTAssertTrue(cycleDescriptions.contains(where: { $0.contains("B") && $0.contains("C") && $0.contains("D") }))
        XCTAssertTrue(cycleDescriptions.contains(where: { $0.contains("E") && $0.contains("F") }))
    }
    
    // Test that capabilities and contexts have separate graphs
    func testCapabilitiesAndContextsHaveSeparateGraphs() {
        let validator = DAGValidator()
        
        // Add capability dependencies
        validator.addDependency(from: "CapA", to: "CapB", type: .capability)
        
        // Add context dependencies with same names
        validator.addDependency(from: "CapA", to: "CapB", type: .context)
        
        // No cycles should be detected (separate graphs)
        let validation = validator.validate()
        XCTAssertTrue(validation.isValid)
        
        // Each graph should have its own topological sort
        let capabilitySorted = validator.topologicalSort(for: .capability)
        let contextSorted = validator.topologicalSort(for: .context)
        
        XCTAssertNotNil(capabilitySorted)
        XCTAssertNotNil(contextSorted)
        XCTAssertEqual(capabilitySorted!.count, 2)
        XCTAssertEqual(contextSorted!.count, 2)
    }
    
    // Test cache functionality for performance optimization
    func testCachingImprovedPerformance() {
        let validator = DAGValidator()
        
        // Build a complex graph
        for i in 0..<10 {
            if i > 0 {
                validator.addDependency(from: "Node\(i)", to: "Node\(i-1)", type: .capability)
            }
        }
        
        // First validation should not use cache
        _ = validator.validate()
        XCTAssertEqual(validator.statistics.cacheHits, 0)
        XCTAssertEqual(validator.statistics.validationCount, 1)
        
        // Second validation should use cache
        _ = validator.validate()
        XCTAssertEqual(validator.statistics.cacheHits, 1)
        XCTAssertEqual(validator.statistics.validationCount, 2)
        
        // Adding a dependency should invalidate cache
        validator.addDependency(from: "Node10", to: "Node9", type: .capability)
        _ = validator.validate()
        XCTAssertEqual(validator.statistics.cacheHits, 1) // Still 1 from before
        XCTAssertEqual(validator.statistics.validationCount, 3)
        
        // Verify cache hit rate
        XCTAssertGreaterThan(validator.statistics.cacheHitRate, 0.0)
    }
    
    // Test cycle prevention check
    func testCyclePrevention() {
        let validator = DAGValidator()
        
        // Create a simple chain
        validator.addDependency(from: "A", to: "B", type: .capability)
        validator.addDependency(from: "B", to: "C", type: .capability)
        
        // Check if adding C -> A would create a cycle
        XCTAssertTrue(validator.wouldCreateCycle(from: "C", to: "A", in: .capability))
        
        // Check if adding C -> D would be safe
        XCTAssertFalse(validator.wouldCreateCycle(from: "C", to: "D", in: .capability))
        
        // Check if adding D -> E would be safe (D not in graph yet)
        XCTAssertFalse(validator.wouldCreateCycle(from: "D", to: "E", in: .capability))
    }
}