import XCTest
@testable import Axiom

final class ClientIsolationTests: XCTestCase {
    
    // MARK: - Client Isolation Tests
    
    func testClientToClientCommunicationFails() {
        // Red: Test that clients cannot communicate with other clients
        
        // Test 1: Direct dependency validation
        let isValid = DependencyRules.isValidDependency(from: .client, to: .client)
        XCTAssertFalse(isValid, "Clients must not be able to depend on other clients")
        
        // Test 2: Error message for client-to-client dependency
        let errorMessage = DependencyRules.dependencyError(from: .client, to: .client)
        XCTAssertEqual(errorMessage, "Client cannot depend on Client: Clients must be isolated from each other")
        
        // Test 3: Client isolation validator should exist
        // This will fail initially as we haven't implemented it yet
        let validator = ClientIsolationValidator()
        XCTAssertNotNil(validator, "Client isolation validator must exist")
        
        // Test 4: Build validation should reject client importing another client
        let mockClient1 = MockClientDefinition(name: "UserClient", dependencies: ["NetworkCapability"])
        let mockClient2 = MockClientDefinition(name: "AuthClient", dependencies: ["UserClient"])
        
        let validationResult = validator.validate(clients: [mockClient1, mockClient2])
        XCTAssertFalse(validationResult.isValid, "Build validation must reject client importing another client")
        XCTAssertEqual(validationResult.errors.count, 1)
        XCTAssertEqual(validationResult.errors.first, "AuthClient cannot depend on UserClient: Clients must be isolated from each other")
    }
    
    func testClientCanDependOnCapabilities() {
        // Test that clients can properly depend on capabilities
        
        let isValid = DependencyRules.isValidDependency(from: .client, to: .capability)
        XCTAssertTrue(isValid, "Clients must be able to depend on capabilities")
        
        // Test with mock validator
        let validator = ClientIsolationValidator()
        let mockClient = MockClientDefinition(name: "LocationClient", dependencies: ["LocationCapability", "NetworkCapability"])
        
        let validationResult = validator.validate(clients: [mockClient])
        XCTAssertTrue(validationResult.isValid, "Client depending only on capabilities should pass validation")
        XCTAssertEqual(validationResult.errors.count, 0)
    }
    
    func testMultipleClientsWithProperIsolation() {
        // Test that multiple clients can coexist when properly isolated
        
        let validator = ClientIsolationValidator()
        let clients = [
            MockClientDefinition(name: "UserClient", dependencies: ["DatabaseCapability"]),
            MockClientDefinition(name: "AuthClient", dependencies: ["NetworkCapability", "CryptoCapability"]),
            MockClientDefinition(name: "LocationClient", dependencies: ["LocationCapability"])
        ]
        
        let validationResult = validator.validate(clients: clients)
        XCTAssertTrue(validationResult.isValid, "Multiple properly isolated clients should pass validation")
        XCTAssertEqual(validationResult.errors.count, 0)
    }
    
    func testClientIsolationBoundaryConditions() {
        // Test boundary conditions for client isolation
        
        let validator = ClientIsolationValidator()
        
        // Test 1: Empty client list
        let emptyClients: [MockClientDefinition] = []
        let emptyResult = validator.validate(clients: emptyClients)
        XCTAssertTrue(emptyResult.isValid, "Empty client list should be valid")
        
        // Test 2: Client with no dependencies
        let noDepsClient = MockClientDefinition(name: "SimpleClient", dependencies: [])
        let noDepsResult = validator.validate(clients: [noDepsClient])
        XCTAssertTrue(noDepsResult.isValid, "Client with no dependencies should be valid")
        
        // Test 3: Client with self-reference (should fail)
        let selfRefClient = MockClientDefinition(name: "SelfRefClient", dependencies: ["SelfRefClient"])
        let selfRefResult = validator.validate(clients: [selfRefClient])
        XCTAssertFalse(selfRefResult.isValid, "Client with self-reference should fail validation")
        
        // Test 4: Circular dependency chain
        let clientA = MockClientDefinition(name: "ClientA", dependencies: ["ClientB"])
        let clientB = MockClientDefinition(name: "ClientB", dependencies: ["ClientA"])
        let circularResult = validator.validate(clients: [clientA, clientB])
        XCTAssertFalse(circularResult.isValid, "Circular client dependencies should fail validation")
        XCTAssertGreaterThanOrEqual(circularResult.errors.count, 2)
    }
    
    func testDiagnosticMessages() {
        // Test that diagnostic messages provide helpful information
        
        let validator = ClientIsolationValidator()
        
        // Test 1: Client-to-client dependency with diagnostic
        let client1 = MockClientDefinition(name: "UserClient", dependencies: ["AuthClient"])
        let client2 = MockClientDefinition(name: "AuthClient", dependencies: [])
        
        let result = validator.validate(clients: [client1, client2])
        let clientDefs = [client1, client2].map { $0.toClientDefinition() }
        let detailedResult = validator.validate(clients: clientDefs)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(detailedResult.detailedErrors.count, 1)
        
        if let error = detailedResult.detailedErrors.first {
            XCTAssertEqual(error.violationType, .clientToClient)
            XCTAssertTrue(error.suggestion.contains("Context"))
            XCTAssertTrue(error.description.contains("Consider using a Context"))
        }
        
        // Test 2: Self-reference with diagnostic
        let selfRefClient = ClientDefinition(name: "SelfRefClient", dependencies: ["SelfRefClient"])
        let selfRefResult = validator.validate(clients: [selfRefClient])
        
        if let error = selfRefResult.detailedErrors.first {
            XCTAssertEqual(error.violationType, .selfReference)
            XCTAssertTrue(error.suggestion.contains("Remove the self-reference"))
        }
        
        // Test 3: Diagnostic report
        let report = detailedResult.diagnosticReport()
        XCTAssertTrue(report.contains("❌"))
        XCTAssertTrue(report.contains("Client Isolation Violations Found"))
        XCTAssertTrue(report.contains("Total violations: 1"))
        
        // Test 4: Valid configuration report
        let validClient = ClientDefinition(name: "ValidClient", dependencies: ["NetworkCapability"])
        let validResult = validator.validate(clients: [validClient])
        let validReport = validResult.diagnosticReport()
        XCTAssertTrue(validReport.contains("✅"))
        XCTAssertTrue(validReport.contains("All client isolation rules are satisfied"))
    }
}

// MARK: - Helper Extensions

extension ClientIsolationValidator {
    /// Convenience method for testing with mock definitions
    func validate(clients: [MockClientDefinition]) -> ValidationResult {
        let clientDefs = clients.map { $0.toClientDefinition() }
        return validate(clients: clientDefs)
    }
}