import Foundation

#if canImport(Axiom)
import Axiom

// MARK: - Counter Client Implementation

/// Real AxiomClient implementation for counter operations
/// Demonstrates actor-based state management with observer pattern
actor RealCounterClient: AxiomClient {
    
    // MARK: - AxiomClient Protocol
    
    typealias State = RealCounterState
    typealias DomainModelType = EmptyDomain
    
    private(set) var stateSnapshot: RealCounterState = RealCounterState()
    let capabilities: CapabilityManager
    
    private var observers: [ComponentID: any AxiomContext] = [:]
    
    // MARK: - Initialization
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
    }
    
    // MARK: - AxiomClient Methods
    
    func initialize() async throws {
        try await capabilities.validate(.businessLogic)
        try await capabilities.validate(.stateManagement)
        print("🎯 Real AxiomClient initialized")
    }
    
    func shutdown() async {
        observers.removeAll()
        print("🎯 Real AxiomClient shutdown")
    }
    
    func updateState<T>(_ update: @Sendable (inout RealCounterState) throws -> T) async rethrows -> T {
        let result = try update(&stateSnapshot)
        await notifyObservers()
        return result
    }
    
    func validateState() async throws {
        // Counter state is always valid for this simple example
    }
    
    func addObserver<T: AxiomContext>(_ context: T) async {
        let id = ComponentID.generate()
        observers[id] = context
    }
    
    func removeObserver<T: AxiomContext>(_ context: T) async {
        observers = observers.filter { _, observer in
            type(of: observer) != type(of: context)
        }
    }
    
    func notifyObservers() async {
        for (_, observer) in observers {
            await observer.onClientStateChange(self)
        }
    }
    
    // MARK: - Counter Operations
    
    func increment() async {
        await updateState { state in
            state.increment()
        }
        print("🔄 Real Framework: Counter incremented to \(stateSnapshot.count)")
    }
    
    func decrement() async {
        await updateState { state in
            state.decrement()
        }
        print("🔄 Real Framework: Counter decremented to \(stateSnapshot.count)")
    }
    
    func reset() async {
        await updateState { state in
            state.reset()
        }
        print("🔄 Real Framework: Counter reset")
    }
    
    func getCurrentCount() async -> Int {
        return stateSnapshot.count
    }
    
    // MARK: - Advanced Operations (for testing framework features)
    
    func setCount(_ newCount: Int) async {
        await updateState { state in
            state.count = newCount
            state.lastAction = "set to \(newCount)"
        }
    }
    
    func getStateDescription() async -> String {
        return stateSnapshot.description
    }
}

#else

// MARK: - Fallback Implementation (when Axiom not available)

actor RealCounterClient {
    private var count: Int = 0
    
    func initialize() async throws {
        print("⚠️ Fallback CounterClient initialized")
    }
    
    func increment() async {
        count += 1
        print("⚠️ Fallback: Counter incremented to \(count)")
    }
    
    func decrement() async {
        count -= 1
        print("⚠️ Fallback: Counter decremented to \(count)")
    }
    
    func reset() async {
        count = 0
        print("⚠️ Fallback: Counter reset")
    }
    
    func getCurrentCount() async -> Int {
        return count
    }
}

#endif