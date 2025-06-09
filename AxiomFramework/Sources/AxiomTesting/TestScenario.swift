import Foundation
import XCTest
@testable import Axiom

// MARK: - Client Test Scenario

/// Builder for creating test scenarios focused on Client behavior
public actor ClientTestScenario<C: Client> {
    public typealias StateType = C.StateType
    public typealias ActionType = C.ActionType
    
    private let clientType: C.Type
    private var initialState: StateType?
    private var clientFactory: ((StateType) -> C)?
    private var actions: [ActionType] = []
    private var assertions: [(StateType) async throws -> Bool] = []
    private var validations: [(Int, (StateType) async throws -> Bool)] = []
    private var preconditions: [(StateType) async throws -> Bool] = []
    private var timeout: Duration = .seconds(10)
    private var captureHistory = false
    private var measureTime = false
    
    public private(set) var stateHistory: [StateType] = []
    public private(set) var executionMetrics: ExecutionMetrics?
    
    public init(_ clientType: C.Type) {
        self.clientType = clientType
    }
    
    /// Set the initial state
    public func given(_ state: StateType) -> Self {
        self.initialState = state
        return self
    }
    
    /// Set a custom client factory
    public func withClientFactory(_ factory: @escaping (StateType) -> C) -> Self {
        self.clientFactory = factory
        return self
    }
    
    /// Add a precondition that must be met
    public func require(_ condition: @escaping (StateType) async throws -> Bool) -> Self {
        preconditions.append(condition)
        return self
    }
    
    /// Add an action to execute
    public func when(_ action: ActionType) -> Self {
        actions.append(action)
        return self
    }
    
    /// Add an assertion for the final state
    public func then(_ assertion: @escaping (StateType) async throws -> Bool) -> Self {
        assertions.append(assertion)
        return self
    }
    
    /// Add an async assertion
    public func thenAsync(_ assertion: @escaping (StateType) async throws -> Bool) -> Self {
        assertions.append(assertion)
        return self
    }
    
    /// Validate state after a specific action
    public func validate(_ assertion: @escaping (StateType) async throws -> Bool) -> Self {
        validations.append((actions.count - 1, assertion))
        return self
    }
    
    /// Set custom timeout for actions
    public func withActionTimeout(_ timeout: Duration) -> Self {
        self.timeout = timeout
        return self
    }
    
    /// Enable state history capture
    public func captureStateHistory() -> Self {
        self.captureHistory = true
        return self
    }
    
    /// Enable execution time measurement
    public func measureExecutionTime() -> Self {
        self.measureTime = true
        return self
    }
    
    /// Execute the test scenario
    public func execute() async throws {
        let startTime = ContinuousClock.now
        
        guard let initialState = initialState else {
            throw ClientTestScenarioError.missingInitialState
        }
        
        // Create client
        let client: C
        if let factory = clientFactory {
            client = factory(initialState)
        } else if C.self is BaseClient<StateType, ActionType>.Type {
            // Create BaseClient instance directly
            let baseClient = BaseClient<StateType, ActionType>(initialState: initialState)
            client = baseClient as! C
        } else {
            throw ClientTestScenarioError.cannotCreateClient
        }
        
        // Check preconditions
        let currentState = await client.state
        for precondition in preconditions {
            let passed = try await precondition(currentState)
            if !passed {
                throw ClientTestScenarioError.preconditionFailed
            }
        }
        
        // Capture initial state
        if captureHistory {
            stateHistory.append(currentState)
        }
        
        // Execute actions and capture states
        for (index, action) in actions.enumerated() {
            try await client.process(action)
            
            let newState = await client.state
            if captureHistory {
                stateHistory.append(newState)
            }
            
            // Run intermediate validations
            for (validationIndex, validation) in validations {
                if validationIndex == index {
                    let passed = try await validation(newState)
                    if !passed {
                        throw ClientTestScenarioError.validationFailed(
                            actionIndex: index,
                            state: newState
                        )
                    }
                }
            }
        }
        
        // Run final assertions
        let finalState = await client.state
        for (index, assertion) in assertions.enumerated() {
            let passed = try await assertion(finalState)
            if !passed {
                throw ClientTestScenarioError.assertionFailed(
                    message: "Assertion \(index) failed",
                    actualState: finalState
                )
            }
        }
        
        if measureTime {
            let endTime = ContinuousClock.now
            executionMetrics = ExecutionMetrics(
                totalDuration: endTime - startTime,
                actionCount: actions.count,
                averageActionTime: (endTime - startTime) / actions.count
            )
        }
    }
}

// MARK: - Context Test Scenario

/// Builder for creating test scenarios focused on Context behavior
@MainActor
public class ContextTestScenario<C: Context> {
    private let contextType: C.Type
    private var contextFactory: (() async throws -> C)?
    private var client: (any Client)?
    private var childSetups: [(C) async throws -> any Context] = []
    private var actions: [(C, [any Context]) async throws -> Void] = []
    private var assertions: [(C) async throws -> Bool] = []
    private var validations: [(Int, (C) async throws -> Bool)] = []
    private var lifecycleActions: [LifecycleAction] = []
    private var shouldMeasureMemory = false
    
    public private(set) var memoryMetrics: MemoryMetrics?
    
    public init(_ contextType: C.Type) {
        self.contextType = contextType
    }
    
    /// Set up context with a client
    public func withClient<Client: Axiom.Client>(_ client: Client) -> Self {
        self.client = client
        return self
    }
    
    /// Custom setup function
    public func withSetup(_ factory: @escaping () async throws -> C) -> Self {
        self.contextFactory = factory
        return self
    }
    
    /// Add a child context
    public func withChild(_ setup: @escaping (C) async throws -> any Context) -> Self {
        childSetups.append(setup)
        return self
    }
    
    /// Trigger onAppear lifecycle
    public func onAppear() -> Self {
        lifecycleActions.append(.appear)
        return self
    }
    
    /// Trigger onDisappear lifecycle
    public func onDisappear() -> Self {
        lifecycleActions.append(.disappear)
        return self
    }
    
    /// Add an action to execute
    public func when(_ action: @escaping (C) async throws -> Void) -> Self {
        actions.append { context, _ in
            try await action(context)
        }
        return self
    }
    
    /// Add an action with access to children
    public func when(_ action: @escaping (C, [any Context]) async throws -> Void) -> Self {
        actions.append(action)
        return self
    }
    
    /// Add an assertion
    public func then(_ assertion: @escaping (C) async throws -> Bool) -> Self {
        assertions.append(assertion)
        return self
    }
    
    /// Validate state after specific action
    public func validate(_ assertion: @escaping (C) async throws -> Bool) -> Self {
        validations.append((actions.count - 1, assertion))
        return self
    }
    
    /// Enable memory measurement
    public func measureMemory() -> Self {
        self.shouldMeasureMemory = true
        return self
    }
    
    /// Execute the test scenario
    public func execute() async throws {
        let baselineMemory = shouldMeasureMemory ? measureCurrentMemory() : 0
        
        // Create context
        let context: C
        if let factory = contextFactory {
            context = try await factory()
        } else {
            // Tests must provide a context factory via withSetup()
            throw ContextTestScenarioError.setupFailed
        }
        
        // Set up children
        var children: [any Context] = []
        for childSetup in childSetups {
            let child = try await childSetup(context)
            children.append(child)
        }
        
        // Execute lifecycle actions in order
        for lifecycleAction in lifecycleActions {
            switch lifecycleAction {
            case .appear:
                await context.onAppear()
            case .disappear:
                await context.onDisappear()
            }
            
            // Run any validations that should occur after lifecycle events
            for (index, validation) in validations {
                if index == -1 { // Special case for lifecycle validations
                    let passed = try await validation(context)
                    if !passed {
                        throw ContextTestScenarioError.validationFailed
                    }
                }
            }
        }
        
        // Execute actions
        for (index, action) in actions.enumerated() {
            try await action(context, children)
            
            // Run intermediate validations
            for (validationIndex, validation) in validations {
                if validationIndex == index {
                    let passed = try await validation(context)
                    if !passed {
                        throw ContextTestScenarioError.validationFailed
                    }
                }
            }
        }
        
        // Run final assertions
        for (index, assertion) in assertions.enumerated() {
            let passed = try await assertion(context)
            if !passed {
                throw ContextTestScenarioError.assertionFailed(index: index)
            }
        }
        
        if shouldMeasureMemory {
            let finalMemory = measureCurrentMemory()
            let isStable = abs(Double(finalMemory - baselineMemory)) / Double(baselineMemory) < 0.1
            memoryMetrics = MemoryMetrics(
                baseline: baselineMemory,
                final: finalMemory,
                isStable: isStable
            )
        }
    }
    
    private func measureCurrentMemory() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
}

// MARK: - Supporting Types

/// Execution metrics for client scenarios
public struct ExecutionMetrics: Sendable {
    public let totalDuration: Duration
    public let actionCount: Int
    public let averageActionTime: Duration
}

/// Memory metrics for context scenarios
public struct MemoryMetrics: Sendable {
    public let baseline: Int
    public let final: Int
    public let isStable: Bool
}

/// Lifecycle actions for contexts
public enum LifecycleAction {
    case appear
    case disappear
}

/// Errors for client test scenarios
public enum ClientTestScenarioError: Error {
    case missingInitialState
    case cannotCreateClient
    case preconditionFailed
    case validationFailed(actionIndex: Int, state: Any)
    case assertionFailed(message: String, actualState: Any)
}

/// Errors for context test scenarios
public enum ContextTestScenarioError: Error {
    case setupFailed
    case validationFailed
    case assertionFailed(index: Int)
}

// MARK: - BaseClient Extension for Testing

extension BaseClient {
    /// Convenience initializer for testing
    public static func createForTesting(initialState: Any) -> Self {
        guard let typedState = initialState as? S else {
            fatalError("Invalid state type for \(Self.self)")
        }
        return Self(initialState: typedState)
    }
}

// MARK: - Extension for Client state access

extension Client {
    /// Access current state (for testing)
    public var state: StateType {
        get async {
            // This is a workaround for testing. In real scenarios,
            // we'd access state through the stream or other means
            if let baseClient = self as? BaseClient<StateType, ActionType> {
                return await baseClient.state
            }
            
            // For other client types, we need to capture from stream
            var capturedState: StateType?
            for await state in stateStream {
                capturedState = state
                break
            }
            
            guard let state = capturedState else {
                fatalError("Could not capture state from client")
            }
            return state
        }
    }
}

