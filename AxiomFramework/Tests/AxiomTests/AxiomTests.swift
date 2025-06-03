import XCTest
@testable import Axiom

final class AxiomTests: XCTestCase {
    func testFrameworkVersion() {
        // Minimal test to verify framework imports work
        XCTAssertEqual(AxiomFramework.version, "2.0.0")
    }
}