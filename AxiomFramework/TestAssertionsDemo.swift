import XCTest
import Foundation
@testable import Axiom
@testable import AxiomTesting

// Quick demo to test that TestAssertions protocol works
func demonstrateTestAssertions() async throws {
    print("🧪 Testing TestAssertions Protocol...")
    
    // Test 1: waitFor functionality
    var flag = false
    Task {
        try await Task.sleep(for: .milliseconds(100))
        flag = true
    }
    
    let _ = try await EmptyTestContext().waitFor({
        flag ? "success" : nil
    }, timeout: .seconds(1))
    print("✅ waitFor functionality works")
    
    // Test 2: assertEventually functionality
    var counter = 0
    Task {
        for _ in 0..<5 {
            try await Task.sleep(for: .milliseconds(50))
            counter += 1
        }
    }
    
    try await EmptyTestContext().assertEventually {
        counter >= 3
    }
    print("✅ assertEventually functionality works")
    
    print("🎉 TestAssertions protocol working correctly!")
}

// Empty context for testing
struct EmptyTestContext: TestAssertions {
    typealias TestedType = Any
}

// If run directly
if CommandLine.argc > 0 {
    Task {
        do {
            try await demonstrateTestAssertions()
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}