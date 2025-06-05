import XCTest
@testable import Axiom

final class UnidirectionalFlowTests: XCTestCase {
    
    // Test that reverse dependencies fail at compile time
    func testReverseDependenciesFail() {
        // Test Capability → Client (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .capability, to: .client), 
                       "Capability should not depend on Client")
        
        // Test Client → Context (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .client, to: .context),
                       "Client should not depend on Context")
        
        // Test Context → Orchestrator (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .context, to: .orchestrator),
                       "Context should not depend on Orchestrator")
        
        // Test State → Client (reverse from owner) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .state, to: .client),
                       "State should not depend on Client")
        
        // Test Presentation → Context (reverse from binding) fails  
        XCTAssertFalse(UnidirectionalFlow.validate(from: .presentation, to: .context),
                       "Presentation should not have explicit dependency on Context")
    }
    
    // Test that forward dependencies are allowed
    func testForwardDependenciesAllowed() {
        // Test Orchestrator → Context is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .orchestrator, to: .context),
                      "Orchestrator should be able to depend on Context")
        
        // Test Context → Client is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .context, to: .client),
                      "Context should be able to depend on Client")
        
        // Test Client → Capability is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .client, to: .capability),
                      "Client should be able to depend on Capability")
    }
    
    // Test that the dependency flow is strictly unidirectional
    func testStrictUnidirectionalFlow() {
        let flowOrder: [ComponentType] = [.orchestrator, .context, .client, .capability]
        
        // Verify each component can only depend on downstream components
        for (index, component) in flowOrder.enumerated() {
            // Check dependencies on upstream components fail
            for upstreamIndex in 0..<index {
                let upstream = flowOrder[upstreamIndex]
                XCTAssertFalse(UnidirectionalFlow.validate(from: component, to: upstream),
                              "\(component) should not depend on upstream \(upstream)")
            }
            
            // Check dependencies on downstream components succeed
            for downstreamIndex in (index + 1)..<flowOrder.count {
                let downstream = flowOrder[downstreamIndex]
                XCTAssertTrue(UnidirectionalFlow.validate(from: component, to: downstream),
                              "\(component) should be able to depend on downstream \(downstream)")
            }
        }
    }
    
    // Test dependency analyzer confirms unidirectional graph
    func testDependencyAnalyzerConfirmsUnidirectionalGraph() {
        // Create a sample dependency graph
        let dependencies: [(ComponentType, ComponentType)] = [
            (.orchestrator, .context),
            (.context, .client),
            (.client, .capability)
        ]
        
        // Analyze the graph
        let analyzer = DependencyAnalyzer(dependencies: dependencies)
        
        // Verify the graph is unidirectional
        XCTAssertTrue(analyzer.isUnidirectional(),
                      "Dependency graph should be unidirectional")
        
        // Verify topological sort succeeds
        XCTAssertNotNil(analyzer.topologicalSort(),
                        "Unidirectional graph should have valid topological ordering")
    }
    
    // Test that cyclic dependencies are detected
    func testCyclicDependenciesDetected() {
        // Create a cyclic dependency graph
        let cyclicDependencies: [(ComponentType, ComponentType)] = [
            (.orchestrator, .context),
            (.context, .client),
            (.client, .orchestrator) // Creates a cycle
        ]
        
        let analyzer = DependencyAnalyzer(dependencies: cyclicDependencies)
        
        // Verify the graph is not unidirectional
        XCTAssertFalse(analyzer.isUnidirectional(),
                       "Cyclic graph should not be unidirectional")
        
        // Verify topological sort fails
        XCTAssertNil(analyzer.topologicalSort(),
                     "Cyclic graph should not have valid topological ordering")
    }
    
    // Test compile-time validation through protocol constraints
    func testCompileTimeValidation() {
        // This test verifies that our compile-time constraints work
        // by checking that the validation logic matches expected rules
        
        // Test all valid forward dependencies
        let validDependencies: [(ComponentType, ComponentType)] = [
            (.orchestrator, .context),
            (.orchestrator, .client),
            (.orchestrator, .capability),
            (.context, .client),
            (.context, .capability),
            (.client, .capability)
        ]
        
        for (from, to) in validDependencies {
            XCTAssertTrue(UnidirectionalFlow.validate(from: from, to: to),
                          "Valid dependency from \(from) to \(to) should be allowed")
        }
        
        // Test all invalid reverse dependencies
        let invalidDependencies: [(ComponentType, ComponentType)] = [
            (.capability, .client),
            (.capability, .context),
            (.capability, .orchestrator),
            (.client, .context),
            (.client, .orchestrator),
            (.context, .orchestrator)
        ]
        
        for (from, to) in invalidDependencies {
            XCTAssertFalse(UnidirectionalFlow.validate(from: from, to: to),
                           "Invalid dependency from \(from) to \(to) should be rejected")
        }
    }
    
    // Test special component dependencies
    func testSpecialComponentDependencies() {
        // State can only be owned by Client
        XCTAssertTrue(UnidirectionalFlow.validate(from: .client, to: .state),
                      "Client should be able to own State")
        XCTAssertFalse(UnidirectionalFlow.validate(from: .state, to: .client),
                       "State should not depend on Client")
        
        // Presentation binds to Context but doesn't explicitly depend
        XCTAssertTrue(UnidirectionalFlow.validate(from: .context, to: .presentation),
                      "Context can provide data to Presentation")
        XCTAssertFalse(UnidirectionalFlow.validate(from: .presentation, to: .context),
                       "Presentation should not explicitly depend on Context")
    }
    
    // Test performance of dependency validation
    func testDependencyValidationPerformance() {
        measure {
            // Validate many dependencies
            for _ in 0..<1000 {
                _ = UnidirectionalFlow.validate(from: .orchestrator, to: .context)
                _ = UnidirectionalFlow.validate(from: .context, to: .client)
                _ = UnidirectionalFlow.validate(from: .client, to: .capability)
            }
        }
    }
}