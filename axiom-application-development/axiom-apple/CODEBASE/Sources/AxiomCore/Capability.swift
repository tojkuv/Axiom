// MARK: - Capability Protocol
import Foundation

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
public protocol AxiomCapability: Actor {
    /// Indicates whether the capability is currently available for use
    var isAvailable: Bool { get async }
    
    /// Activate the capability and prepare it for use
    /// - Throws: If activation fails
    func activate() async throws
    
    /// Deactivate the capability and clean up resources
    func deactivate() async
}

// MARK: - Capability State

/// Represents the current state of a capability
public enum AxiomCapabilityState: Equatable, Sendable {
    /// The capability is available and ready for use
    case available
    /// The capability is not available (e.g., hardware not present)
    case unavailable
    /// The capability is restricted by system policies or user settings
    case restricted
    /// The capability state is unknown or being determined
    case unknown
    /// The capability is being initialized
    case initializing
    /// The capability is being terminated
    case terminating
}

/// Capability status for internal state management
public enum AxiomCapabilityStatus: Equatable, Sendable {
    /// The capability is idle and not currently active
    case idle
    /// The capability is ready for use
    case ready
    /// The capability is currently active/running
    case active
    /// The capability has failed or encountered an error
    case failed
}

// MARK: - Capability Type

/// Represents different types of capabilities supported by the framework
public enum AxiomCapabilityType: Sendable {
    case network
    case persistence
    case hardware
    case media
    case analytics
    case payment
    case ml
    case service
    case navigation
    case custom(String)
    
    public var rawValue: String {
        switch self {
        case .network: return "network"
        case .persistence: return "persistence"
        case .hardware: return "hardware"
        case .media: return "media"
        case .analytics: return "analytics"
        case .payment: return "payment"
        case .ml: return "ml"
        case .service: return "service"
        case .navigation: return "navigation"
        case .custom(let value): return value
        }
    }
    
    public static var allCases: [AxiomCapabilityType] {
        return [.network, .persistence, .hardware, .media, .analytics, .payment, .ml, .service, .navigation]
    }
}

// MARK: - Capability Errors
// CapabilityError is now defined in ErrorHandling.swift as part of AxiomError hierarchy

// MARK: - Standard Capability Implementation

/// Standard actor implementation providing common capability behaviors
/// 
/// This actor provides:
/// - State management with thread-safe transitions
/// - Default lifecycle implementations
/// - State observation support
/// - Unified lifecycle protocol adoption
/// - Configurable timeout management
public actor AxiomStandardCapability: AxiomCapability {
    /// Current state of the capability
    public private(set) var state: AxiomCapabilityState = .unknown
    
    /// Stream of state changes for observation
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    /// Configured activation timeout
    private var _activationTimeout: Duration = .milliseconds(10)
    
    /// Creates a stream of state changes
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?.state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    public init() {}
    
    /// Indicates whether the capability is currently available
    public var isAvailable: Bool {
        state == .available
    }
    
    /// Activate the capability
    /// Subclasses should override to provide specific activation logic
    public func activate() async throws {
        // Default implementation transitions to available
        // Subclasses can override for specific activation logic
        await transitionTo(.available)
    }
    
    /// Deactivate the capability and clean up resources
    /// Subclasses should override to provide specific cleanup
    public func deactivate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    /// Transition to a new state
    /// - Parameter newState: The state to transition to
    public func transitionTo(_ newState: AxiomCapabilityState) async {
        guard state != newState else { return }
        state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - StandardCapability ExtendedCapability Conformance

extension AxiomStandardCapability: AxiomExtendedCapability {
    /// Configured activation timeout for this capability
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    /// Configure custom activation timeout
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    /// Check if the capability is supported on this device
    public func isSupported() async -> Bool {
        // Default implementation - override in subclasses
        return true
    }
    
    /// Request permission if required
    public func requestPermission() async throws {
        // Default implementation - override in subclasses
    }
}

// MARK: - Extended Capability Protocol

/// Extended capability protocol with additional lifecycle management
public protocol AxiomExtendedCapability: AxiomCapability {
    /// The current state of the capability
    var state: AxiomCapabilityState { get async }
    
    /// Stream of state changes for observation
    var stateStream: AsyncStream<AxiomCapabilityState> { get async }
    
    /// Configured activation timeout for this capability
    var activationTimeout: Duration { get async }
    
    /// Check if the capability is supported on this device
    func isSupported() async -> Bool
    
    /// Request permission if required
    func requestPermission() async throws
    
    /// Configure custom activation timeout
    func setActivationTimeout(_ timeout: Duration) async
}

// MARK: - Protocol Extensions

extension AxiomCapability {
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
    
    /// Activate with custom timeout
    public func activate(timeout: Duration) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.activate()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw AxiomCapabilityError.initializationFailed("Activation timed out after \(timeout)")
            }
            
            try await group.next()
            group.cancelAll()
        }
    }
}

extension AxiomExtendedCapability {
    /// Check if the capability is in a specific state
    public func isInState(_ targetState: AxiomCapabilityState) async -> Bool {
        await state == targetState
    }
    
    /// Wait for a specific state with timeout
    public func waitForState(_ targetState: AxiomCapabilityState, timeout: Duration) async throws {
        let startTime = ContinuousClock.now
        
        for await currentState in await stateStream {
            if currentState == targetState {
                return
            }
            
            if ContinuousClock.now - startTime > timeout {
                throw AxiomCapabilityError.initializationFailed(
                    "Timeout waiting for state \(targetState)"
                )
            }
        }
    }
}

// MARK: - Capability Manager Protocol

/// Protocol for managing multiple capabilities
public protocol AxiomCapabilityManager: Actor {
    /// Register a capability with the manager
    func register<T: AxiomCapability>(_ capability: T, for key: String) async
    
    /// Retrieve a registered capability
    func capability<T: AxiomCapability>(for key: String, as type: T.Type) async -> T?
    
    /// Initialize all registered capabilities
    func initializeAll() async
    
    /// Terminate all registered capabilities
    func terminateAll() async
}

// MARK: - Capability Manager Implementation

/// Default implementation of capability manager
public actor AxiomDefaultCapabilityManager: AxiomCapabilityManager {
    private var capabilities: [String: any AxiomCapability] = [:]
    private var initializationOrder: [String] = []
    
    public init() {}
    
    public func register<T: AxiomCapability>(_ capability: T, for key: String) async {
        capabilities[key] = capability
        initializationOrder.append(key)
    }
    
    public func capability<T: AxiomCapability>(for key: String, as type: T.Type) async -> T? {
        capabilities[key] as? T
    }
    
    public func initializeAll() async {
        // Initialize in registration order
        for key in initializationOrder {
            if let capability = capabilities[key] {
                do {
                    try await capability.activate()
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
                await capability.deactivate()
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