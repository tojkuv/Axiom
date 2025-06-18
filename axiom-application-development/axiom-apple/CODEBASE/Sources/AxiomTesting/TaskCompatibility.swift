import Foundation
import AxiomCore

// MVP: Compatibility layer for Task.sleep
extension Task where Success == Never, Failure == Never {
    static func sleep(nanoseconds duration: UInt64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(duration) / 1_000_000_000.0) {
                continuation.resume()
            }
        }
    }
}

// MVP: TestDuration type for compatibility
public struct TestDuration: Sendable {
    let nanoseconds: UInt64
    
    public static func milliseconds(_ value: Int) -> TestDuration {
        TestDuration(nanoseconds: UInt64(value) * 1_000_000)
    }
    
    public static func seconds(_ value: Int) -> TestDuration {
        TestDuration(nanoseconds: UInt64(value) * 1_000_000_000)
    }
    
    public var components: (seconds: Int64, attoseconds: Int64) {
        let seconds = Int64(nanoseconds / 1_000_000_000)
        let attoseconds = Int64((nanoseconds % 1_000_000_000) * 1_000_000_000)
        return (seconds, attoseconds)
    }
}

// Extension for Task.sleep with TestDuration
extension Task where Success == Never, Failure == Never {
    static func sleep(for duration: TestDuration) async throws {
        try await sleep(nanoseconds: duration.nanoseconds)
    }
}

// Convenience alias to Duration if available
@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public typealias Duration = Swift.Duration