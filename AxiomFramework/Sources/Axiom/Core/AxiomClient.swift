import Foundation

// MARK: - Base Client Implementation

/// Base implementation for Client protocol
/// Provides automatic state management and observation
public actor BaseClient<S: State>: Client {
    public typealias State = S
    
    /// The single state instance owned by this client
    public private(set) var state: S
    
    /// Initialize with default state
    public init() {
        self.state = S()
    }
    
    /// Initialize with specific state
    public init(state: S) {
        self.state = state
    }
    
    /// Update state with automatic observation
    public func updateState(_ transform: (inout S) -> Void) async {
        transform(&state)
    }
}

// MARK: - Client Helpers

/// Helper protocol for client initialization
public protocol ClientInitializable: Client {
    init()
    init(state: State)
}