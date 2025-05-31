import Foundation
import Axiom
import XCTest
import SwiftUI

/// AxiomTesting provides comprehensive testing utilities for the Axiom framework
public struct AxiomTesting {
    public init() {}
}

// MARK: - Test Doubles and Mocks

/// Mock capability manager for testing
public actor MockCapabilityManager {
    public private(set) var availableCapabilities: Set<Capability> = []
    public private(set) var validationHistory: [(Capability, Bool)] = []
    
    public init(availableCapabilities: Set<Capability> = Set(Capability.allCases)) {
        self.availableCapabilities = availableCapabilities
    }
    
    public func validate(_ capability: Capability) async throws {
        let isAvailable = availableCapabilities.contains(capability)
        validationHistory.append((capability, isAvailable))
        
        if !isAvailable {
            throw CapabilityError.unavailable(capability)
        }
    }
    
    public func addCapability(_ capability: Capability) async {
        availableCapabilities.insert(capability)
    }
    
    public func removeCapability(_ capability: Capability) async {
        availableCapabilities.remove(capability)
    }
    
    public func reset() async {
        validationHistory.removeAll()
        availableCapabilities = Set(Capability.allCases)
    }
}

// MARK: - Basic Test Utilities

public struct AxiomTestUtilities {
    
    /// Creates a mock capability manager for testing
    public static func createMockCapabilityManager(with capabilities: [Capability] = Array(Capability.allCases)) -> MockCapabilityManager {
        return MockCapabilityManager(availableCapabilities: Set(capabilities))
    }
}

// MARK: - XCTest Extensions

public extension XCTestCase {
    
    /// Sets up a basic Axiom test environment
    func setupBasicAxiomTest() -> MockCapabilityManager {
        return AxiomTestUtilities.createMockCapabilityManager()
    }
    
    /// Validates capability functionality
    func assertCapabilityValidation(
        _ capability: Capability,
        shouldSucceed: Bool,
        with manager: MockCapabilityManager,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            try await manager.validate(capability)
            XCTAssertTrue(shouldSucceed, "Expected capability validation to fail", file: file, line: line)
        } catch {
            XCTAssertFalse(shouldSucceed, "Expected capability validation to succeed but got error: \(error)", file: file, line: line)
        }
    }
}