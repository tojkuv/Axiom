import XCTest
import AxiomCore
import Foundation

// MARK: - Test Scenario DSL

/// A declarative DSL for writing async tests with Given/When/Then structure
/// 
/// Example usage:
/// ```swift
/// await TestScenario {
///     Given { MockClient() }
///     When { $0.process(.update) }
///     Then { $0.state.isUpdated }
/// }.run()
/// ```
public struct TestScenario: Sendable {
    let components: [TestComponent]
    
    public init(@TestScenarioBuilder _ builder: () -> [TestComponent]) {
        self.components = builder()
    }
    
    // Direct initializer for array of components
    public init(components: [TestComponent]) {
        self.components = components
    }
    
    public func run() async throws {
        var context: Any?
        
        for component in components {
            switch component {
            case .given(let setup):
                context = try await setup()
                
            case .when(let action):
                guard let ctx = context else {
                    throw TestScenarioError.missingContext
                }
                try await action(ctx)
                
            case .then(let assertion):
                guard let ctx = context else {
                    throw TestScenarioError.missingContext
                }
                try await assertion(ctx)
                
            case .thenEventually(let condition, let timeout):
                guard let ctx = context else {
                    throw TestScenarioError.missingContext
                }
                try await waitForCondition(
                    timeout: timeout,
                    context: ctx,
                    condition: condition
                )
            }
        }
    }
}

// MARK: - Test Components

public enum TestComponent: @unchecked Sendable {
    case given(@Sendable () async throws -> Any)
    case when(@Sendable (Any) async throws -> Void)
    case then(@Sendable (Any) async throws -> Void)
    case thenEventually(@Sendable (Any) async throws -> Bool, timeout: Duration)
}

// MARK: - Result Builder

@resultBuilder
public struct TestScenarioBuilder {
    public static func buildBlock(_ components: TestComponent...) -> [TestComponent] {
        components
    }
}

// MARK: - DSL Functions

public func Given<T>(_ setup: @escaping @Sendable () async throws -> T) -> TestComponent {
    .given {
        try await setup()
    }
}

public func When<T>(_ action: @escaping @Sendable (T) async throws -> Void) -> TestComponent {
    .when { context in
        guard let typedContext = context as? T else {
            throw TestScenarioError.invalidContextType(
                expected: String(describing: T.self),
                actual: String(describing: type(of: context))
            )
        }
        try await action(typedContext)
    }
}

public func Then<T>(_ assertion: @escaping @Sendable (T) async throws -> Void) -> TestComponent {
    .then { context in
        guard let typedContext = context as? T else {
            throw TestScenarioError.invalidContextType(
                expected: String(describing: T.self),
                actual: String(describing: type(of: context))
            )
        }
        try await assertion(typedContext)
    }
}

public func ThenEventually<T>(
    timeout: Duration = .seconds(5),
    _ condition: @escaping @Sendable (T) async throws -> Bool
) -> TestComponent {
    .thenEventually({ context in
        guard let typedContext = context as? T else {
            throw TestScenarioError.invalidContextType(
                expected: String(describing: T.self),
                actual: String(describing: type(of: context))
            )
        }
        return try await condition(typedContext)
    }, timeout: timeout)
}

// MARK: - Error Types

public enum TestScenarioError: Error, LocalizedError {
    case missingContext
    case invalidContextType(expected: String, actual: String)
    case conditionTimeout(Duration)
    
    public var errorDescription: String? {
        switch self {
        case .missingContext:
            return "No context available - ensure Given block is defined"
        case .invalidContextType(let expected, let actual):
            return "Context type mismatch - expected \(expected), got \(actual)"
        case .conditionTimeout(let timeout):
            return "Condition not met within \(timeout)"
        }
    }
}

// MARK: - Timing Utilities

private func waitForCondition(
    timeout: Duration,
    context: Any,
    condition: (Any) async throws -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    var checkInterval = Duration.milliseconds(10) // Start with fast checks
    let maxInterval = Duration.milliseconds(100)
    
    while ContinuousClock.now < deadline {
        if try await condition(context) {
            return
        }
        
        try await Task.sleep(for: checkInterval)
        
        // Exponential backoff for efficiency
        if checkInterval < maxInterval {
            checkInterval = Duration(
                secondsComponent: checkInterval.components.seconds,
                attosecondsComponent: checkInterval.components.attoseconds * 2
            )
        }
    }
    
    // Final check
    if try await condition(context) {
        return
    }
    
    throw TestScenarioError.conditionTimeout(timeout)
}

// MARK: - Advanced DSL Features

public extension TestScenario {
    /// Run multiple test scenarios in parallel
    static func parallel(_ scenarios: TestScenario...) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for scenario in scenarios {
                group.addTask { [scenario] in
                    try await scenario.run()
                }
            }
            try await group.waitForAll()
        }
    }
    
    /// Run multiple test scenarios sequentially
    static func sequence(_ scenarios: TestScenario...) async throws {
        for scenario in scenarios {
            try await scenario.run()
        }
    }
    
    /// Create a test scenario with shared context
    static func withSharedContext<T: Sendable>(
        _ context: T,
        @TestScenarioBuilder builder: () -> [TestComponent]
    ) -> TestScenario {
        var components = [TestComponent.given { context }]
        components.append(contentsOf: builder())
        return TestScenario(components: components)
    }
}

// MARK: - Integration with TestAssertions

/// Enhanced Then function that integrates with TestAssertions protocol
public func ThenAssert<T>(
    _ assertion: @escaping @Sendable (T) async throws -> Void
) -> TestComponent where T: TestAssertions & Sendable {
    .then { context in
        guard let typedContext = context as? T else {
            throw TestScenarioError.invalidContextType(
                expected: String(describing: T.self),
                actual: String(describing: type(of: context))
            )
        }
        try await assertion(typedContext)
    }
}

// MARK: - Performance Monitoring

/// Test scenario with performance tracking
public struct PerformanceTestScenario {
    let scenario: TestScenario
    let name: String
    
    public init(name: String, @TestScenarioBuilder _ builder: () -> [TestComponent]) {
        self.name = name
        self.scenario = TestScenario(components: builder())
    }
    
    public func run() async throws -> Duration {
        let start = ContinuousClock.now
        try await scenario.run()
        let duration = ContinuousClock.now - start
        
        print("[Performance] \(name): \(duration)")
        return duration
    }
}