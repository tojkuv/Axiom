import XCTest
import Foundation
@testable import Axiom

// MARK: - TestConfiguration

/// Configuration for test scenarios
public struct TestConfiguration {
    public let defaultTimeout: TestDuration
    public let propagationDelay: TestDuration
    public let pollingInterval: TestDuration
    
    public static let `default` = TestConfiguration(
        defaultTimeout: .seconds(5),
        propagationDelay: .milliseconds(10),
        pollingInterval: .milliseconds(10)
    )
    
    public init(
        defaultTimeout: TestDuration = .seconds(5),
        propagationDelay: TestDuration = .milliseconds(10),
        pollingInterval: TestDuration = .milliseconds(10)
    ) {
        self.defaultTimeout = defaultTimeout
        self.propagationDelay = propagationDelay
        self.pollingInterval = pollingInterval
    }
}

// MARK: - ContextTestScenario

/// Declarative test scenario builder for contexts
public struct ContextTestScenario<C> {
    private let contextType: C.Type
    private let configuration: TestConfiguration
    private var context: C?
    
    public init(_ contextType: C.Type, configuration: TestConfiguration = .default) {
        self.contextType = contextType
        self.configuration = configuration
    }
    
    /// Start a test action with optional timeout
    public func when<T>(
        timeout: TestDuration? = nil,
        _ action: @escaping (C) async throws -> T
    ) -> TestAction<C, T> {
        return TestAction(
            scenario: self,
            timeout: timeout ?? configuration.defaultTimeout,
            action: action
        )
    }
}

// MARK: - TestAction

/// Represents a test action in the scenario
public struct TestAction<C, T> {
    private let scenario: ContextTestScenario<C>
    private let timeout: TestDuration
    private let action: (C) async throws -> T
    
    init(scenario: ContextTestScenario<C>, timeout: TestDuration, action: @escaping (C) async throws -> T) {
        self.scenario = scenario
        self.timeout = timeout
        self.action = action
    }
    
    /// Verify the result of the action
    @discardableResult
    public func then<U>(
        timeout: TestDuration? = nil,
        _ verification: @escaping (C) async throws -> U
    ) async throws -> U {
        // Create context instance
        let context = try await createContext()
        
        // Execute action with timeout
        _ = try await executeWithTimeout(timeout ?? self.timeout) {
            try await self.action(context)
        }
        
        // Allow state to propagate
        try await Task.sleep(for: .milliseconds(10))
        
        // Execute verification with timeout
        return try await executeWithTimeout(timeout ?? self.timeout) {
            try await verification(context)
        }
    }
    
    /// Chain another action
    public func and<U>(
        timeout: TestDuration? = nil,
        _ action: @escaping (C) async throws -> U
    ) -> TestAction<C, U> {
        return TestAction<C, U>(
            scenario: scenario,
            timeout: timeout ?? self.timeout,
            action: action
        )
    }
    
    private func createContext() async throws -> C {
        // Try to create context using common patterns
        // For MVP, require manual context creation via factory
        throw AsyncTestError.timeout("Context type \(C.self) requires manual creation. Use withSetup() to provide a factory.")
    }
    
    private func executeWithTimeout<R>(_ timeout: TestDuration, operation: @escaping () async throws -> R) async throws -> R {
        try await withThrowingTaskGroup(of: R.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AsyncTestError.timeout("Operation exceeded timeout of \(timeout)")
            }
            
            guard let result = try await group.next() else {
                throw AsyncTestError.timeout("No result received")
            }
            group.cancelAll()
            return result
        }
    }
}

// MARK: - AsyncStreamTester

/// Testing utility for AsyncStream assertions
public struct AsyncStreamTester<Element> {
    private let stream: AsyncStream<Element>
    
    public init(_ stream: AsyncStream<Element>) {
        self.stream = stream
    }
    
    /// Expect specific values from the stream
    public func expectValues(
        _ expectedValues: [Element],
        timeout: TestDuration = .seconds(5)
    ) async throws where Element: Equatable {
        var receivedValues: [Element] = []
        let deadline = ContinuousClock.now + Swift.Duration.seconds(Double(timeout.nanoseconds) / 1_000_000_000.0)
        
        let task = Task {
            for await value in stream {
                receivedValues.append(value)
                if receivedValues.count >= expectedValues.count {
                    break
                }
                if ContinuousClock.now >= deadline {
                    break
                }
            }
        }
        
        // Wait for values with timeout
        while receivedValues.count < expectedValues.count && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        
        task.cancel()
        
        // Verify values
        if receivedValues.count < expectedValues.count {
            throw AsyncTestError.timeout("Only received \(receivedValues.count) of \(expectedValues.count) expected values")
        }
        
        XCTAssertEqual(receivedValues, expectedValues)
    }
    
    /// Expect a value matching a predicate
    public func expectValue(
        matching predicate: @escaping (Element) -> Bool,
        timeout: TestDuration = .seconds(5)
    ) async throws -> Element {
        let deadline = ContinuousClock.now + Swift.Duration.seconds(Double(timeout.nanoseconds) / 1_000_000_000.0)
        
        let task = Task { () -> Element? in
            for await value in stream {
                if predicate(value) {
                    return value
                }
                if ContinuousClock.now >= deadline {
                    break
                }
            }
            return nil
        }
        
        if let result = await task.value {
            return result
        }
        
        throw AsyncTestError.timeout("No value matching predicate found within \(timeout)")
    }
    
    /// Expect stream completion
    public func expectCompletion(timeout: TestDuration = .seconds(5)) async throws {
        let deadline = ContinuousClock.now + Swift.Duration.seconds(Double(timeout.nanoseconds) / 1_000_000_000.0)
        var completed = false
        
        let task = Task {
            for await _ in stream {
                if ContinuousClock.now >= deadline {
                    break
                }
            }
            completed = true
        }
        
        // Wait for completion
        while !completed && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        
        task.cancel()
        
        if !completed {
            throw AsyncTestError.timeout("Stream did not complete within \(timeout)")
        }
    }
}

// MARK: - ClientTestScenario

/// Testing scenario for client implementations
public struct ClientTestScenario<C: Client> {
    private let clientType: C.Type
    private let client: C
    
    public init(_ clientType: C.Type, initialState: C.StateType? = nil) {
        self.clientType = clientType
        if let mockClientType = C.self as? MockClient<C.StateType, C.ActionType>.Type,
           let state = initialState {
            self.client = mockClientType.init(initialState: state) as! C
        } else {
            // For real clients, we'd need a factory or protocol
            fatalError("Non-mock clients need custom initialization")
        }
    }
    
    /// Perform an action on the client
    public func whenAction(
        _ action: C.ActionType,
        timeout: TestDuration = .seconds(5)
    ) -> ClientAction<C> {
        return ClientAction(
            scenario: self,
            client: client,
            action: action,
            timeout: timeout
        )
    }
    
    /// Expect a specific state
    public func expectState(
        matching predicate: @escaping (C.StateType) -> Bool,
        timeout: TestDuration = .seconds(5)
    ) async throws -> C.StateType {
        let deadline = ContinuousClock.now + Swift.Duration.seconds(Double(timeout.nanoseconds) / 1_000_000_000.0)
        
        let task = Task { () -> C.StateType? in
            for await state in await client.stateStream {
                if predicate(state) {
                    return state
                }
                if ContinuousClock.now >= deadline {
                    break
                }
            }
            return nil
        }
        
        if let result = await task.value {
            return result
        }
        
        throw AsyncTestError.timeout("State matching predicate not found within \(timeout)")
    }
}

// MARK: - ClientAction

/// Represents an action in a client test scenario
public struct ClientAction<C: Client> {
    private let scenario: ClientTestScenario<C>
    private let client: C
    private let action: C.ActionType
    private let timeout: TestDuration
    
    init(scenario: ClientTestScenario<C>, client: C, action: C.ActionType, timeout: TestDuration) {
        self.scenario = scenario
        self.client = client
        self.action = action
        self.timeout = timeout
    }
    
    /// Verify the result after the action
    @discardableResult
    public func then<T>(
        timeout: TestDuration? = nil,
        _ verification: @escaping (C) async throws -> T
    ) async throws -> T {
        // Process the action
        try await client.process(action)
        
        // Allow state to propagate
        try await Task.sleep(for: .milliseconds(10))
        
        // Execute verification with timeout
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await verification(client)
            }
            
            group.addTask {
                try await Task.sleep(for: timeout ?? self.timeout)
                throw AsyncTestError.timeout("Verification exceeded timeout")
            }
            
            guard let result = try await group.next() else {
                throw AsyncTestError.timeout("No result received")
            }
            group.cancelAll()
            return result
        }
    }
    
    /// Chain another action
    public func and<T>(
        _ action: @escaping (C) async throws -> T
    ) -> ClientAction<C> {
        // Execute the chained action
        Task {
            try await action(client)
        }
        return self
    }
    
    /// Expect a specific state after the action
    public func expectState(
        matching predicate: @escaping (C.StateType) -> Bool,
        timeout: TestDuration? = nil
    ) async throws {
        _ = try await scenario.expectState(matching: predicate, timeout: timeout ?? self.timeout)
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {
    /// Execute async operation with automatic timeout and expectation handling
    public func expectAsync<T>(
        timeout: TestDuration = .seconds(5),
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AsyncTestError.timeout("Operation exceeded timeout of \(timeout)")
            }
            
            guard let result = try await group.next() else {
                throw AsyncTestError.timeout("No result received")
            }
            group.cancelAll()
            return result
        }
    }
    
    /// Assert values from an async stream
    public func expectValues<T: Equatable>(
        from stream: AsyncStream<T>,
        matching expected: [T],
        timeout: TestDuration = .seconds(5)
    ) async throws {
        let tester = AsyncStreamTester(stream)
        try await tester.expectValues(expected, timeout: timeout)
    }
    
    /// Memory leak detection for async operations
    public func expectNoMemoryLeaks<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        weak var weakReference: AnyObject?
        
        let result: T = try await {
            let innerResult = try await operation()
            
            // Capture weak reference to check for deallocation
            if let object = innerResult as? AnyObject {
                weakReference = object
            }
            
            return innerResult
        }()
        
        // Force collection
        for _ in 0..<10 {
            autoreleasepool { }
        }
        
        // Check for leaks
        XCTAssertNil(weakReference, "Memory leak detected - object not deallocated")
        
        return result
    }
}

// MARK: - Test Configuration

public extension ContextTestScenario {
}

// MARK: - CapabilityTestScenario

/// Testing scenario specifically for capabilities
public struct CapabilityTestScenario<Cap> {
    private let capabilityType: Cap.Type
    private let configuration: TestConfiguration
    
    public init(_ capabilityType: Cap.Type, configuration: TestConfiguration = .default) {
        self.capabilityType = capabilityType
        self.configuration = configuration
    }
    
    /// Start a test action with capability
    public func when<T>(
        timeout: TestDuration? = nil,
        _ action: @escaping (Cap) async throws -> T
    ) -> CapabilityTestAction<Cap, T> {
        return CapabilityTestAction(
            scenario: self,
            timeout: timeout ?? configuration.defaultTimeout,
            action: action
        )
    }
}

// MARK: - CapabilityTestAction

/// Test action specific to capabilities
public struct CapabilityTestAction<Cap, T> {
    private let scenario: CapabilityTestScenario<Cap>
    private let timeout: TestDuration
    private let action: (Cap) async throws -> T
    
    init(scenario: CapabilityTestScenario<Cap>, timeout: TestDuration, action: @escaping (Cap) async throws -> T) {
        self.scenario = scenario
        self.timeout = timeout
        self.action = action
    }
    
    /// Verify the result of the capability action
    @discardableResult
    public func then<U>(
        timeout: TestDuration? = nil,
        _ verification: @escaping (Cap) async throws -> U
    ) async throws -> U {
        // Create capability instance
        let capability = try await createCapability()
        
        // Execute action with timeout
        _ = try await executeWithTimeout(timeout ?? self.timeout) {
            try await self.action(capability)
        }
        
        // Allow state to propagate
        try await Task.sleep(for: .milliseconds(10))
        
        // Execute verification with timeout
        return try await executeWithTimeout(timeout ?? self.timeout) {
            try await verification(capability)
        }
    }
    
    /// Chain another action
    public func and<U>(
        timeout: TestDuration? = nil,
        _ action: @escaping (Cap) async throws -> U
    ) -> CapabilityTestAction<Cap, U> {
        return CapabilityTestAction<Cap, U>(
            scenario: scenario,
            timeout: timeout ?? self.timeout,
            action: action
        )
    }
    
    private func createCapability() async throws -> Cap {
        // Try to create capability using common patterns
        if let capType = Cap.self as? any (ExtendedCapability & DefaultInitializable).Type {
            return capType.init() as! Cap
        } else {
            // For MVP, require manual capability creation
            throw AsyncTestError.timeout("Capability type \(Cap.self) requires manual creation")
        }
    }
    
    private func executeWithTimeout<R>(_ timeout: TestDuration, operation: @escaping () async throws -> R) async throws -> R {
        try await withThrowingTaskGroup(of: R.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AsyncTestError.timeout("Operation exceeded timeout of \(timeout)")
            }
            
            guard let result = try await group.next() else {
                throw AsyncTestError.timeout("No result received")
            }
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Supporting Protocols

/// Protocol for types that can be default initialized
protocol DefaultInitializable {
    init()
}