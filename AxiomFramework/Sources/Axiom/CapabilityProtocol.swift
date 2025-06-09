// MARK: - Capability Protocol

/// Core protocol for managing external system access with lifecycle methods.
/// 
/// Capabilities represent interfaces to external systems like camera, network, location services, etc.
/// They manage their own lifecycle and provide availability status.
/// 
/// Requirements:
/// - Must be actor-based for thread safety
/// - Manages lifecycle states: available, unavailable, restricted, unknown
/// - Provides async initialization and termination
/// - State transitions must complete in < 10ms
public protocol Capability: Actor {
    /// Indicates whether the capability is currently available for use
    var isAvailable: Bool { get async }
    
    /// Initialize the capability and prepare it for use
    /// - Throws: If initialization fails
    func initialize() async throws
    
    /// Terminate the capability and clean up resources
    func terminate() async
}

// MARK: - Capability State

/// Represents the current state of a capability
public enum CapabilityState: Equatable, Sendable {
    /// The capability is available and ready for use
    case available
    /// The capability is not available (e.g., hardware not present)
    case unavailable
    /// The capability is restricted by system policies or user settings
    case restricted
    /// The capability state is unknown or being determined
    case unknown
}

// MARK: - Capability Errors

/// Errors that can occur during capability operations
public enum CapabilityError: Error, Sendable, Equatable {
    /// Initialization of the capability failed
    case initializationFailed(reason: String)
    /// Resource allocation for the capability failed
    case resourceAllocationFailed(reason: String)
    /// Invalid state transition was attempted
    case invalidStateTransition(from: CapabilityState, to: CapabilityState)
    /// The capability is not available on this device
    case notAvailable
    /// The capability is restricted by system policy
    case restricted
    /// The capability requires user permission
    case permissionRequired
}

// MARK: - Base Capability Implementation

/// Base actor implementation providing common capability behaviors
/// 
/// This actor provides:
/// - State management with thread-safe transitions
/// - Default lifecycle implementations
/// - State observation support
public actor BaseCapability: Capability {
    /// Current state of the capability
    public private(set) var state: CapabilityState = .unknown
    
    /// Stream of state changes for observation
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    /// Creates a stream of state changes
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    public init() {}
    
    /// Indicates whether the capability is currently available
    public var isAvailable: Bool {
        state == .available
    }
    
    /// Initialize the capability
    /// Subclasses should override to provide specific initialization
    public func initialize() async throws {
        // Default implementation transitions to available
        // Subclasses can override for specific initialization logic
        await transitionTo(.available)
    }
    
    /// Terminate the capability and clean up resources
    /// Subclasses should override to provide specific cleanup
    public func terminate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    /// Transition to a new state
    /// - Parameter newState: The state to transition to
    public func transitionTo(_ newState: CapabilityState) async {
        guard state != newState else { return }
        state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Extended Capability Protocol

/// Extended capability protocol with additional lifecycle management
public protocol ExtendedCapability: Capability {
    /// The current state of the capability
    var state: CapabilityState { get async }
    
    /// Stream of state changes for observation
    var stateStream: AsyncStream<CapabilityState> { get async }
    
    /// Check if the capability is supported on this device
    func isSupported() async -> Bool
    
    /// Request permission if required
    func requestPermission() async throws
}

// MARK: - Protocol Extensions

extension Capability {
    /// Default timeout for state transitions (10ms)
    public static var transitionTimeout: Duration {
        .milliseconds(10)
    }
    
    /// Convenience method to check if capability is in a usable state
    public var isUsable: Bool {
        get async {
            await isAvailable
        }
    }
    
    /// Initialize with timeout
    public func initialize(timeout: Duration) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.initialize()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw CapabilityError.initializationFailed(reason: "Initialization timed out")
            }
            
            try await group.next()
            group.cancelAll()
        }
    }
}

extension ExtendedCapability {
    /// Check if the capability is in a specific state
    public func isInState(_ targetState: CapabilityState) async -> Bool {
        await state == targetState
    }
    
    /// Wait for a specific state with timeout
    public func waitForState(_ targetState: CapabilityState, timeout: Duration) async throws {
        let startTime = ContinuousClock.now
        
        for await currentState in await stateStream {
            if currentState == targetState {
                return
            }
            
            if ContinuousClock.now - startTime > timeout {
                throw CapabilityError.initializationFailed(
                    reason: "Timeout waiting for state \(targetState)"
                )
            }
        }
    }
}

// MARK: - Capability Manager Protocol

/// Protocol for managing multiple capabilities
public protocol CapabilityManager: Actor {
    /// Register a capability with the manager
    func register<T: Capability>(_ capability: T, for key: String) async
    
    /// Retrieve a registered capability
    func capability<T: Capability>(for key: String, as type: T.Type) async -> T?
    
    /// Initialize all registered capabilities
    func initializeAll() async
    
    /// Terminate all registered capabilities
    func terminateAll() async
}

// MARK: - Capability Manager Implementation

/// Default implementation of capability manager
public actor DefaultCapabilityManager: CapabilityManager {
    private var capabilities: [String: any Capability] = [:]
    private var initializationOrder: [String] = []
    
    public init() {}
    
    public func register<T: Capability>(_ capability: T, for key: String) async {
        capabilities[key] = capability
        initializationOrder.append(key)
    }
    
    public func capability<T: Capability>(for key: String, as type: T.Type) async -> T? {
        capabilities[key] as? T
    }
    
    public func initializeAll() async {
        // Initialize in registration order
        for key in initializationOrder {
            if let capability = capabilities[key] {
                do {
                    try await capability.initialize()
                } catch {
                    // Log error but continue with other capabilities
                    print("Failed to initialize capability \(key): \(error)")
                }
            }
        }
    }
    
    public func terminateAll() async {
        // Terminate in reverse order
        for key in initializationOrder.reversed() {
            if let capability = capabilities[key] {
                await capability.terminate()
            }
        }
        capabilities.removeAll()
        initializationOrder.removeAll()
    }
}

// MARK: - Capability Helpers

/// Helper to measure capability operation performance
public func measureCapabilityOperation<T>(
    _ operation: () async throws -> T
) async rethrows -> (result: T, duration: Duration) {
    let start = ContinuousClock.now
    let result = try await operation()
    let duration = ContinuousClock.now - start
    return (result, duration)
}