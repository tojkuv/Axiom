import XCTest
@testable import Axiom

// Test helper for persistence assertions
public func XCTAssertPersisted<T: Codable & Equatable>(
    _ value: T,
    key: String,
    in persistence: PersistenceCapability,
    file: StaticString = #file,
    line: UInt = #line
) async throws {
    let loaded = try await persistence.load(T.self, for: key)
    XCTAssertEqual(loaded, value, file: file, line: line)
}