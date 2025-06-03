import Foundation
import SwiftUI
import Combine

// MARK: - Base Context Implementation

/// Base implementation for Context protocol
/// Provides client orchestration and SwiftUI integration
/// Contexts derive state and provide actions for presentation layer
@MainActor
open class BaseContext<S: State, A>: Context {
    public typealias State = S
    public typealias Actions = A
    
    /// Derived state for presentation layer
    @Published public private(set) var state: S
    
    /// Actions available to presentation layer
    public private(set) var actions: A
    
    /// Capability validation
    public private(set) var capabilities: [any Capability] = []
    
    /// Initialize with state, actions, and capabilities
    public init(state: S, actions: A, capabilities: [any Capability] = []) {
        self.state = state
        self.actions = actions
        self.capabilities = capabilities
    }
    
    /// Update derived state (triggers SwiftUI updates)
    public func updateState(_ newState: S) {
        self.state = newState
    }
    
    /// Update actions (for initialization patterns)
    public func setActions(_ newActions: A) {
        self.actions = newActions
    }
}

// MARK: - Context Helpers

extension Context {
    /// Check if context has a specific capability
    public func hasCapability(_ capability: some Capability) -> Bool {
        capabilities.contains { $0.id == capability.id }
    }
    
    /// Validate required capabilities
    public func validateCapabilities(_ required: [any Capability]) -> Bool {
        required.allSatisfy { requiredCap in
            capabilities.contains { $0.id == requiredCap.id }
        }
    }
}

// MARK: - Action Builder Helper

/// Helper for building context actions
public struct ContextActions<Context: Axiom.Context> {
    private weak var context: Context?
    
    public init(context: Context) {
        self.context = context
    }
    
    /// Create an action that executes async work
    public func action(_ work: @escaping (Context) async -> Void) -> () async -> Void {
        return { [weak context] in
            guard let context else { return }
            await work(context)
        }
    }
    
    /// Create an action with parameter
    public func action<T>(_ work: @escaping (Context, T) async -> Void) -> (T) async -> Void {
        return { [weak context] param in
            guard let context else { return }
            await work(context, param)
        }
    }
}