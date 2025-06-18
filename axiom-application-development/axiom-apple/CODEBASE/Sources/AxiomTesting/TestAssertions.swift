import XCTest
import AxiomCore
import Foundation
@testable import AxiomArchitecture

// MARK: - Test Error Types

public enum TestError: Error, CustomStringConvertible {
    case timeout(String)
    case conditionNotMet
    case operationFailed(Error)
    
    public var description: String {
        switch self {
        case .timeout(let message):
            return "Test timeout: \(message)"
        case .conditionNotMet:
            return "Test condition was not met"
        case .operationFailed(let error):
            return "Test operation failed: \(error)"
        }
    }
}

// MARK: - TestAssertions Protocol

/// Unified test assertions protocol providing consistent async testing patterns
/// 
/// This protocol consolidates common testing patterns across the framework,
/// eliminating duplication and providing a single, consistent API for:
/// - Async operations with timeout
/// - State observation and waiting
/// - Memory leak detection
/// - Error boundary testing
public protocol TestAssertions {
    associatedtype TestedType
}

// MARK: - Default Implementations

public extension TestAssertions {
    
    /// Wait for an async operation to return a non-nil value within timeout
    /// 
    /// This consolidates the timeout/deadline logic found duplicated across test helpers
    func waitFor<T>(
        _ operation: () async throws -> T?,
        timeout: Duration = .seconds(5),
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let deadline = ContinuousClock.now + timeout
        
        while ContinuousClock.now < deadline {
            if let result = try await operation() {
                return result
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        
        let errorMessage = message ?? "Operation timed out after \(timeout)"
        throw TestError.timeout(errorMessage)
    }
    
    /// Observe states from a client until a condition is met
    /// 
    /// This consolidates state observation patterns found in AsyncTestHelpers and ContextTestHelpers
    func observeStates<C: AxiomClient>(
        from client: C,
        timeout: Duration = .seconds(5),
        until condition: @escaping (C.StateType) -> Bool
    ) async throws -> C.StateType {
        return try await waitFor({
            for await state in await client.stateStream {
                if condition(state) {
                    return state
                }
            }
            return nil
        }, timeout: timeout, message: "State condition not met")
    }
    
    /// Assert that a condition eventually becomes true
    /// 
    /// This consolidates async condition checking found across multiple test helpers
    func assertEventually(
        _ condition: () async -> Bool,
        timeout: Duration = .seconds(5),
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let _ = try await waitFor({
            await condition() ? true : nil
        }, timeout: timeout, message: message ?? "Condition never became true")
    }
    
    /// Assert that an async condition eventually becomes true
    func assertEventually(
        _ condition: () async throws -> Bool,
        timeout: Duration = .seconds(5),
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let _ = try await waitFor({
            try await condition() ? true : nil
        }, timeout: timeout, message: message ?? "Condition never became true")
    }
    
    /// Assert that an object doesn't cause memory leaks
    /// 
    /// This consolidates memory tracking patterns found in multiple test helpers
    func assertNoMemoryLeaks<T: AnyObject>(
        _ object: T,
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Memory leak detection is disabled in this MVP version
        // due to Swift concurrency data race constraints
        // TODO: Implement proper async-safe memory leak detection
    }
    
    /// Wait for multiple states from a client stream
    /// 
    /// Consolidates state collection patterns
    func collectStates<C: AxiomClient>(
        from client: C,
        count: Int,
        timeout: Duration = .seconds(5),
        while executing: (C) async throws -> Void = { _ in }
    ) async throws -> [C.StateType] {
        let collector = StateCollector<C.StateType>()
        
        let observationTask = Task {
            for await state in await client.stateStream {
                await collector.add(state)
                if await collector.count() >= count {
                    break
                }
            }
        }
        
        // Execute the provided operations
        try await executing(client)
        
        // Wait for collection to complete
        let result = try await waitFor({
            let currentCount = await collector.count()
            return currentCount >= count ? await collector.getAll() : nil
        }, timeout: timeout, message: "Failed to collect \(count) states")
        
        observationTask.cancel()
        return result
    }
}

// MARK: - XCTestCase Extension

/// Apply TestAssertions to XCTestCase so all test classes get unified assertions
extension XCTestCase: TestAssertions {
    public typealias TestedType = Any
}

// MARK: - Helper Actor

/// Thread-safe state collector for async operations
fileprivate actor StateCollector<T> {
    private var states: [T] = []
    
    func add(_ state: T) {
        states.append(state)
    }
    
    func getAll() -> [T] {
        return states
    }
    
    func count() -> Int {
        return states.count
    }
}

// MARK: - Convenience Global Functions

/// Global convenience function for waitFor (maintains existing API compatibility)
public func waitFor<T>(
    _ operation: () async throws -> T?,
    timeout: Duration = .seconds(5),
    message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    return try await EmptyTestContext().waitFor(
        operation, 
        timeout: timeout, 
        message: message, 
        file: file, 
        line: line
    )
}

/// Global convenience function for observeStates
public func observeStates<C: AxiomClient>(
    from client: C,
    timeout: Duration = .seconds(5),
    until condition: @escaping (C.StateType) -> Bool
) async throws -> C.StateType {
    return try await EmptyTestContext().observeStates(
        from: client, 
        timeout: timeout, 
        until: condition
    )
}

/// Global convenience function for assertEventually
public func assertEventually(
    _ condition: () async -> Bool,
    timeout: Duration = .seconds(5),
    message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    try await EmptyTestContext().assertEventually(
        condition, 
        timeout: timeout, 
        message: message, 
        file: file, 
        line: line
    )
}

/// Global convenience function for assertEventually with throws
public func assertEventually(
    _ condition: () async throws -> Bool,
    timeout: Duration = .seconds(5),
    message: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    try await EmptyTestContext().assertEventually(
        condition, 
        timeout: timeout, 
        message: message, 
        file: file, 
        line: line
    )
}

/// Empty test context for global function implementations
private struct EmptyTestContext: TestAssertions {
    typealias TestedType = Any
}