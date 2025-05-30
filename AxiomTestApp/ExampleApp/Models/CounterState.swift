import Foundation
import Axiom

// MARK: - Counter State Definition

/// State model for the counter example
/// Demonstrates Axiom's Sendable state requirements and immutable update patterns
struct RealCounterState: Sendable {
    var count: Int = 0
    var isLoading: Bool = false
    var lastAction: String = "initialized"
    
    // MARK: - State Mutations
    
    mutating func increment() {
        count += 1
        lastAction = "incremented"
    }
    
    mutating func decrement() {
        count -= 1
        lastAction = "decremented"
    }
    
    mutating func reset() {
        count = 0
        lastAction = "reset"
    }
    
    // MARK: - Computed Properties
    
    var description: String {
        "Count: \(count), Last: \(lastAction)"
    }
    
    var canDecrement: Bool {
        count > 0
    }
}

// MARK: - Supporting Types

struct RealCounterClients: ClientDependencies {
    let counterClient: RealCounterClient
    
    init() {
        fatalError("RealCounterClients should be initialized with actual clients")
    }
    
    init(counterClient: RealCounterClient) {
        self.counterClient = counterClient
    }
}