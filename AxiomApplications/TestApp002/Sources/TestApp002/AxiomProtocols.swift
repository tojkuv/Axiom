// Local Axiom protocol definitions for testing

import Foundation

// MARK: - Core Protocols

public protocol State: Sendable, Equatable {}

public protocol Client: Actor {
    associatedtype StateType: State
    associatedtype ActionType: Sendable
    
    var stateStream: AsyncStream<StateType> { get }
    var currentState: StateType { get async }
    func process(_ action: ActionType) async throws
}

public protocol Capability: Sendable {
    nonisolated var isAvailable: Bool { get }
    func initialize() async throws
    func terminate() async throws
}

public protocol Context: Actor {
    func initialize() async throws
    func invalidate() async
}

public protocol Orchestrator: Actor {
    func handleAction<A>(_ action: A) async throws
    func navigate(to route: Any) async throws
}

public protocol Presentation: Sendable {
    associatedtype Body
    var body: Body { get }
}

// MARK: - Testing Utilities

public struct TestingError: Error {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
}