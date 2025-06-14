import Foundation
import XCTest

/// Base test environment for framework tests
public actor TestEnvironment {
    public init() {}
    
    /// Clean up test environment resources
    public func cleanup() async {
        // Base cleanup implementation
    }
    
    /// Run a test in this environment
    public func runTest<T>(_ operation: (TestEnvironment) async throws -> T) async throws -> T {
        return try await operation(self)
    }
}

/// Base test helpers structure that other test modules extend
public struct TestHelpers {
    /// Create a new test environment for testing
    public static func createTestEnvironment() -> TestEnvironment {
        return TestEnvironment()
    }
    
    /// Performance testing utilities
    public static let performance = PerformanceTestHelpers.self
}