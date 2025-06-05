import XCTest
@testable import Axiom

// Type aliases for test types
typealias TestClient = LifecycleTestClient
typealias TestState = LifecycleTestState
typealias TestPresentation = LifecycleTestPresentation
typealias TestContext = LifecycleTestContext
typealias TestCapability = LifecycleTestCapability

final class ComponentLifetimesTests: XCTestCase {
    // Test that lifetime violations are detected
    func testLifetimeViolations() {
        let lifecycleManager = ComponentLifecycleManager()
        
        // Test Client singleton violation
        let client1 = TestClient(id: "user-client")
        let client2 = TestClient(id: "user-client") // Same ID should violate singleton
        
        XCTAssertTrue(lifecycleManager.registerClient(client1))
        XCTAssertFalse(lifecycleManager.registerClient(client2))
        XCTAssertEqual(
            lifecycleManager.lastError,
            "Client 'user-client' already exists; clients must be singletons"
        )
        
        // Test State singleton violation
        let state1 = TestState(id: "app-state")
        let state2 = TestState(id: "app-state") // Same ID should violate singleton
        
        XCTAssertTrue(lifecycleManager.registerState(state1))
        XCTAssertFalse(lifecycleManager.registerState(state2))
        XCTAssertEqual(
            lifecycleManager.lastError,
            "State 'app-state' already exists; states must be singletons"
        )
    }
    
    // Test that Clients are singletons
    func testClientsAreSingletons() {
        let lifecycleManager = ComponentLifecycleManager()
        
        let client = TestClient(id: "singleton-client")
        XCTAssertTrue(lifecycleManager.registerClient(client))
        
        // Get instance should always return the same instance
        let retrieved1 = lifecycleManager.getClient(id: "singleton-client")
        let retrieved2 = lifecycleManager.getClient(id: "singleton-client")
        
        XCTAssertNotNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertTrue(retrieved1 === retrieved2) // Same instance
        
        // Verify lifetime is singleton
        XCTAssertEqual(lifecycleManager.getLifetime(for: client), .singleton)
    }
    
    // Test that States are singletons
    func testStatesAreSingletons() {
        let lifecycleManager = ComponentLifecycleManager()
        
        let state = TestState(id: "singleton-state")
        XCTAssertTrue(lifecycleManager.registerState(state))
        
        // States should be registered as singletons
        let lifetime = lifecycleManager.getLifetime(for: state)
        XCTAssertEqual(lifetime, .singleton)
        
        // Multiple registrations should fail
        let duplicateState = TestState(id: "singleton-state")
        XCTAssertFalse(lifecycleManager.registerState(duplicateState))
    }
    
    // Test that Contexts are per-presentation
    func testContextsArePerPresentation() {
        let lifecycleManager = ComponentLifecycleManager()
        
        let presentation1 = TestPresentation(id: "presentation-1")
        let presentation2 = TestPresentation(id: "presentation-2")
        
        // Each presentation should get its own context instance
        let context1 = lifecycleManager.createContext(for: presentation1)
        let context2 = lifecycleManager.createContext(for: presentation2)
        
        XCTAssertNotNil(context1)
        XCTAssertNotNil(context2)
        XCTAssertTrue(context1 !== context2) // Different instances
        
        // Same presentation should get the same context
        let context1Again = lifecycleManager.createContext(for: presentation1)
        XCTAssertTrue(context1 === context1Again) // Same instance
        
        // Verify lifetime is per-presentation
        XCTAssertEqual(lifecycleManager.getLifetime(for: context1!), .perPresentation)
    }
    
    // Test that Capabilities are transient
    func testCapabilitiesAreTransient() {
        let lifecycleManager = ComponentLifecycleManager()
        
        // Each capability request should create a new instance
        let capability1 = lifecycleManager.createCapability(type: TestCapability.self)
        let capability2 = lifecycleManager.createCapability(type: TestCapability.self)
        
        XCTAssertNotNil(capability1)
        XCTAssertNotNil(capability2)
        XCTAssertTrue(capability1 !== capability2) // Different instances
        
        // Verify lifetime is transient
        XCTAssertEqual(lifecycleManager.getLifetime(for: capability1!), .transient)
    }
    
    // Test lifecycle validation for all component types
    func testComponentLifecycleValidation() {
        let lifecycleManager = ComponentLifecycleManager()
        
        // Register components
        let client = TestClient(id: "test-client")
        let state = TestState(id: "test-state")
        let presentation = TestPresentation(id: "test-presentation")
        
        XCTAssertTrue(lifecycleManager.registerClient(client))
        XCTAssertTrue(lifecycleManager.registerState(state))
        
        let context = lifecycleManager.createContext(for: presentation)
        let capability = lifecycleManager.createCapability(type: TestCapability.self)
        
        // Validate all lifetime rules
        let validation = lifecycleManager.validateAllLifetimes()
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.clientCount, 1)
        XCTAssertEqual(validation.stateCount, 1)
        XCTAssertEqual(validation.contextCount, 1)
        XCTAssertTrue(validation.capabilitiesAreTransient)
        
        // Test deallocation tracking
        lifecycleManager.releaseContext(for: presentation)
        XCTAssertNil(lifecycleManager.createContext(for: presentation, reuseExisting: false))
    }
    
    // Test lifecycle observers
    func testLifecycleObservers() {
        let lifecycleManager = ComponentLifecycleManager()
        var events: [String] = []
        
        // Add observer
        lifecycleManager.addObserver { event in
            events.append(event.description)
        }
        
        // Trigger lifecycle events
        let client = TestClient(id: "observed-client")
        _ = lifecycleManager.registerClient(client)
        
        let presentation = TestPresentation(id: "observed-presentation")
        _ = lifecycleManager.createContext(for: presentation)
        _ = lifecycleManager.createCapability(type: TestCapability.self)
        
        // Verify events were observed
        XCTAssertTrue(events.contains("Client 'observed-client' registered"))
        XCTAssertTrue(events.contains("Context created for presentation 'observed-presentation'"))
        XCTAssertTrue(events.contains("Transient capability 'LifecycleTestCapability' created"))
    }
}

