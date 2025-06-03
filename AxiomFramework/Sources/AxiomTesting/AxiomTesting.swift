import Foundation
import Axiom

// MARK: - Axiom Testing

/// Testing utilities for Axiom framework
public struct AxiomTesting {
    public init() {}
}

// MARK: - Mock Implementations

/// Mock state for testing
public struct MockState: Axiom.State {
    public var value: Int = 0
    
    public init() {}
    public init(value: Int) {
        self.value = value
    }
}

/// Mock client for testing
public actor MockClient: Client {
    public typealias State = MockState
    
    public private(set) var state: MockState
    
    public init() {
        self.state = MockState()
    }
    
    public init(state: MockState) {
        self.state = state
    }
    
    public func updateState(_ transform: (inout MockState) -> Void) async {
        transform(&state)
    }
}

/// Mock context state
public struct MockContextState: Axiom.State {
    public let displayValue: String
    
    public init() {
        self.displayValue = "0"
    }
    
    public init(displayValue: String) {
        self.displayValue = displayValue
    }
}

/// Mock context actions
public struct MockContextActions {
    public let increment: () async -> Void
    public let decrement: () async -> Void
    public let reset: () async -> Void
}

/// Mock context for testing
@MainActor
public class MockContext: BaseContext<MockContextState, MockContextActions> {
    private let client: MockClient
    
    public init(client: MockClient) {
        self.client = client
        
        let actions = MockContextActions(
            increment: { },
            decrement: { },
            reset: { }
        )
        
        super.init(state: MockContextState(), actions: actions)
        
        // Set actions with self reference
        setActions(MockContextActions(
            increment: { [weak self] in await self?.increment() },
            decrement: { [weak self] in await self?.decrement() },
            reset: { [weak self] in await self?.reset() }
        ))
        
        Task {
            await refreshState()
        }
    }
    
    private func increment() async {
        await client.updateState { $0.value += 1 }
        await refreshState()
    }
    
    private func decrement() async {
        await client.updateState { $0.value -= 1 }
        await refreshState()
    }
    
    private func reset() async {
        await client.updateState { $0.value = 0 }
        await refreshState()
    }
    
    private func refreshState() async {
        let clientState = await client.state
        updateState(MockContextState(displayValue: "\(clientState.value)"))
    }
}

/// Mock capability for testing
public struct MockCapability: Capability {
    public let id: String
    private let available: Bool
    
    public init(id: String, available: Bool = true) {
        self.id = id
        self.available = available
    }
    
    public func isAvailable() -> Bool {
        available
    }
    
    public var description: String {
        "MockCapability(\(id): \(available ? "available" : "unavailable"))"
    }
}