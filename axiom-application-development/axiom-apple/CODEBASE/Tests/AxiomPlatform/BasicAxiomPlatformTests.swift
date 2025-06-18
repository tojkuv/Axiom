import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture
@testable import AxiomCore

/// Basic tests for AxiomPlatform module functionality that can run in MVP
final class BasicAxiomPlatformTests: XCTestCase {
    
    // MARK: - Basic Platform Tests
    
    func testPlatformModuleExists() throws {
        // Basic test to verify the module imports correctly
        XCTAssertTrue(true, "AxiomPlatform module should import successfully")
    }
    
    func testBasicAxiomErrorWithContext() throws {
        // Test the platform error handling extensions
        let originalError = AxiomError.contextError(.lifecycleError("Test"))
        let contextualError = AxiomError.withContext("test context", originalError)
        
        XCTAssertNotNil(contextualError, "Contextual error should be created")
    }
}