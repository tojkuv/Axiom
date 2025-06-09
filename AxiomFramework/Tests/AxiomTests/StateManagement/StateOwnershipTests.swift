import XCTest
@testable import Axiom

// Use the correct TestState from StateOwnership module
private typealias OwnershipTestState = Axiom.TestState
private typealias OwnershipTestClient = Axiom.TestClient

@MainActor
final class StateOwnershipTests: XCTestCase {
    // Test that shared state fails
    func testSharedStateFails() {
        let validator = StateOwnershipValidator()
        
        // Create a state
        let state = OwnershipTestState(value: "initial")
        
        // Create two clients
        let client1 = OwnershipTestClient(id: "client1")
        let client2 = OwnershipTestClient(id: "client2")
        
        // First ownership should succeed
        XCTAssertTrue(validator.assignOwnership(of: state, to: client1))
        
        // Second ownership attempt should fail
        XCTAssertFalse(validator.assignOwnership(of: state, to: client2))
        
        // Verify error message
        XCTAssertEqual(
            validator.lastError,
            "State 'TestState' is already owned by client 'client1'; cannot assign to 'client2'"
        )
    }
    
    // Test that state is immutable value type
    func testStateIsImmutableValueType() {
        // Test that State protocol requires value semantics
        let validator = StateOwnershipValidator()
        
        // States must be value types (structs)
        XCTAssertTrue(validator.validateValueSemantics(OwnershipTestState.self))
        
        // Reference types should fail
        XCTAssertFalse(validator.validateValueSemantics(InvalidReferenceState.self))
        
        // All stored properties must be immutable (let)
        XCTAssertTrue(validator.validateImmutability(OwnershipTestState.self))
        
        // States with mutable properties should fail
        XCTAssertFalse(validator.validateImmutability(InvalidMutableState.self))
    }
    
    // Test 1:1 client-state pairing
    func testOneToOneClientStatePairing() {
        let validator = StateOwnershipValidator()
        
        // Create multiple clients and states
        let clients = (0..<5).map { OwnershipTestClient(id: "client-\($0)") }
        let states = (0..<5).map { OwnershipTestState(value: "state-\($0)") }
        
        // Each client should own exactly one state
        for (index, client) in clients.enumerated() {
            XCTAssertTrue(validator.assignOwnership(of: states[index], to: client))
        }
        
        // Verify ownership mapping
        for (index, client) in clients.enumerated() {
            let ownedState = validator.getState(for: client) as? OwnershipTestState
            XCTAssertEqual(ownedState?.value, "state-\(index)")
        }
        
        // Verify counts
        XCTAssertEqual(validator.totalOwnershipCount, 5)
        XCTAssertEqual(validator.uniqueClientCount, 5)
        XCTAssertEqual(validator.uniqueStateCount, 5)
    }
    
    // Test state ownership with protocol conformance
    func testStateProtocolConformance() {
        // All states must conform to State protocol
        XCTAssertTrue(OwnershipTestState.self is any State.Type)
        
        // States must be Equatable for change detection
        let state1 = OwnershipTestState(value: "test")
        let state2 = OwnershipTestState(value: "test")
        let state3 = OwnershipTestState(value: "different")
        
        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
        
        // States must be Sendable for actor isolation
        XCTAssertTrue(OwnershipTestState.self is any Sendable.Type)
    }
    
    // Test boundary conditions with many clients/states
    func testBoundaryConditionsWithManyStates() {
        let validator = StateOwnershipValidator()
        
        // Create 100 clients and states
        let clients = (0..<100).map { OwnershipTestClient(id: "client-\($0)") }
        let states = (0..<100).map { OwnershipTestState(value: "state-\($0)") }
        
        // Assign all ownerships
        for (client, state) in zip(clients, states) {
            XCTAssertTrue(validator.assignOwnership(of: state, to: client))
        }
        
        // Verify no cross-ownership allowed
        XCTAssertFalse(validator.assignOwnership(of: states[0], to: clients[1]))
        
        // Verify all pairings are maintained
        XCTAssertEqual(validator.totalOwnershipCount, 100)
    }
    
    // Test state transitions produce new instances
    func testStateTransitionsProduceNewInstances() {
        let state = OwnershipTestState(value: "initial")
        
        // State mutations should produce new instances
        let newState = state.withValue("updated")
        
        // Verify they are different instances
        XCTAssertNotEqual(state, newState)
        
        // Verify values are correct
        XCTAssertEqual(state.value, "initial") // Original unchanged
        XCTAssertEqual(newState.value, "updated") // New instance with update
        
        // Test that equal values produce equal states
        let anotherState = OwnershipTestState(value: "initial")
        XCTAssertEqual(state, anotherState)
    }
}

