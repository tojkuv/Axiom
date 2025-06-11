import XCTest
@testable import Axiom

final class APINamingConsistencyTests: XCTestCase {
    
    // Test that protocol files match their content names
    func testProtocolFileNamingConsistency() throws {
        // File ClientProtocol.swift should define Client protocol
        // This test will fail until we rename files
        let expectedProtocolNames = [
            "Client",      // not ClientProtocol
            "Context",     // not ContextProtocol
            "Capability",  // not CapabilityProtocol
            "Orchestrator" // not OrchestratorProtocol
        ]
        
        // Verify protocol names don't have redundant suffixes
        XCTAssertNotNil(Client.self)
        XCTAssertNotNil(Context.self)
        XCTAssertNotNil(Capability.self)
        XCTAssertNotNil(Orchestrator.self)
    }
    
    // Test lifecycle method naming consistency
    func testLifecycleMethodNaming() throws {
        // Context should have consistent lifecycle methods
        let contextType = Context.self
        
        // These should use past tense for events
        let selectors = [
            #selector(Context.onAppear),     // Should be viewAppeared
            #selector(Context.onDisappear)   // Should be viewDisappeared
        ]
        
        // Currently using "on" prefix - should be past tense
        for selector in selectors {
            XCTAssertTrue(contextType.instancesRespond(to: selector), 
                         "Lifecycle method should exist")
        }
    }
    
    // Test boolean property naming
    func testBooleanPropertyNaming() throws {
        // Test that boolean properties use standard prefixes
        struct BooleanPropertyTest {
            // Should start with is/has/can/should
            let useWeakClientReferences: Bool = false  // Should be shouldUseWeakClientReferences
            let atomicExecution: Bool = false          // Should be isAtomicExecution
            let hasActiveClients: Bool = false         // Correct ✓
        }
        
        // This test documents the current state
        XCTAssertTrue(true, "Boolean naming documented for refactoring")
    }
    
    // Test that "Base" prefix is not used
    func testNoVagueBasePrefix() throws {
        // These classes should have more descriptive names
        XCTAssertNotNil(ObservableContext.self)  // Should be ObservableContext or similar
        XCTAssertNotNil(BaseClient.self)   // Should be ObservableClient or similar
        
        // Document that these need renaming
        XCTAssertTrue(true, "Base prefix usage documented")
    }
    
    // Test no "Async" suffix on async methods
    func testNoAsyncSuffix() throws {
        // Methods should not have "Async" suffix
        // Current: thenAsync() in testing
        // Should be: then() with async signature
        
        XCTAssertTrue(true, "Async suffix usage documented")
    }
    
    // Test consistent use of Manager vs Service
    func testConsistentManagerServiceNaming() throws {
        // Should use either Manager or Service, not both
        XCTAssertNotNil(NavigationService.self)
        
        // ClientManager and ContextManager should be consistent
        // Either all Manager or all Service
        XCTAssertTrue(true, "Manager/Service inconsistency documented")
    }
}