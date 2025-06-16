import XCTest
import AxiomCore
@testable import AxiomArchitecture
@testable import AxiomCapabilities

// Test helper for persistence assertions
public func XCTAssertPersisted<T: Codable & Equatable & Sendable>(
    _ value: T,
    key: String,
    in persistence: PersistenceCapability,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    let loaded = try await persistence.load(T.self, for: key)
    XCTAssertEqual(loaded, value, file: file, line: line)
}