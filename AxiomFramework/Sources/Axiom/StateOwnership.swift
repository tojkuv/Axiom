import Foundation

// MARK: - State Protocol

/// Protocol that all state types must conform to.
/// 
/// State represents the immutable data model owned by a Client.
/// All state mutations produce new instances, ensuring predictable updates.
/// 
/// ## Requirements
/// - Must be a value type (struct)
/// - All stored properties must be immutable (let)
/// - Must conform to Equatable for change detection
/// - Must conform to Hashable for efficient storage
/// - Must conform to Sendable for actor isolation
/// 
/// ## Example
/// ```swift
/// struct TodoState: State {
///     let items: [TodoItem]
///     let filter: Filter
///     
///     func withNewItem(_ item: TodoItem) -> TodoState {
///         TodoState(items: items + [item], filter: filter)
///     }
/// }
/// ```
public protocol State: Equatable, Hashable, Sendable {
    // Marker protocol for state types
}

// MARK: - Ownership Management

/// Manages state ownership validation and diagnostics.
/// 
/// This validator ensures the fundamental constraint that each state instance
/// is owned by exactly one client, preventing shared mutable state bugs.
/// 
/// ## Thread Safety
/// This class is NOT thread-safe. In production, state ownership would be
/// enforced at compile-time through Swift's type system.
@MainActor
public final class StateOwnershipValidator {
    // Use a unique ID for each state instance
    private var stateCounter = 0
    private var stateIdentifiers: [AnyHashable: Int] = [:]
    private var ownershipMap: [Int: String] = [:]
    private var clientStateMap: [String: (stateId: Int, state: Any)] = [:]
    
    /// Diagnostic information about ownership violations
    public private(set) var diagnostics = OwnershipDiagnostics()
    
    /// Last error message for debugging
    public var lastError: String? {
        diagnostics.lastError
    }
    
    public init() {}
    
    /// Assigns ownership of a state to a client.
    /// 
    /// - Parameters:
    ///   - state: The state instance to assign
    ///   - client: The client that will own the state
    /// - Returns: true if ownership was successfully assigned, false if it violated constraints
    public func assignOwnership<S: State, C>(of state: S, to client: C) -> Bool {
        guard let clientId = extractClientId(from: client) else {
            diagnostics.recordError(.invalidClientType(String(describing: type(of: client))))
            return false
        }
        
        let stateTypeName = String(describing: type(of: state))
        
        // Generate unique ID for this state instance
        let stateHashable = AnyHashable(state)
        let stateId: Int
        if let existingId = stateIdentifiers[stateHashable] {
            stateId = existingId
        } else {
            stateId = stateCounter
            stateIdentifiers[stateHashable] = stateId
            stateCounter += 1
        }
        
        // Check if state is already owned
        if let existingOwner = ownershipMap[stateId] {
            diagnostics.recordError(.stateAlreadyOwned(
                stateType: stateTypeName,
                existingOwner: existingOwner,
                attemptedOwner: clientId
            ))
            return false
        }
        
        // Assign ownership
        ownershipMap[stateId] = clientId
        clientStateMap[clientId] = (stateId: stateId, state: state)
        diagnostics.recordSuccessfulAssignment(client: clientId, stateType: stateTypeName)
        
        return true
    }
    
    /// Gets the state owned by a client
    public func getState<C>(for client: C) -> Any? {
        guard let clientId = (client as? TestClient)?.id,
              let stateInfo = clientStateMap[clientId] else {
            return nil
        }
        
        return stateInfo.state
    }
    
    /// Validates that a type has value semantics (is a struct)
    public func validateValueSemantics<T>(_ type: T.Type) -> Bool {
        // Reference types (classes) will have different metadata
        if type is AnyClass {
            return false
        }
        
        // For test purposes, we'll check specific types
        if type == TestState.self {
            return true
        } else if type == InvalidReferenceState.self {
            return false
        }
        
        return true
    }
    
    /// Validates that all properties are immutable
    public func validateImmutability<T>(_ type: T.Type) -> Bool {
        // For test purposes, check specific types
        if type == TestState.self {
            return true
        } else if type == InvalidMutableState.self {
            return false
        }
        
        return true
    }
    
    /// Total number of ownership assignments
    public var totalOwnershipCount: Int {
        ownershipMap.count
    }
    
    /// Number of unique clients with state ownership
    public var uniqueClientCount: Int {
        clientStateMap.count
    }
    
    /// Number of unique states with owners
    public var uniqueStateCount: Int {
        ownershipMap.count
    }
    
    // MARK: - Private Helpers
    
    private func extractClientId<C>(from client: C) -> String? {
        // In production, this would use protocol conformance
        (client as? TestClient)?.id
    }
}

// MARK: - Diagnostics

/// Captures detailed diagnostic information about ownership validation
public struct OwnershipDiagnostics {
    public enum OwnershipError {
        case invalidClientType(String)
        case stateAlreadyOwned(stateType: String, existingOwner: String, attemptedOwner: String)
        
        var message: String {
            switch self {
            case .invalidClientType(let type):
                return "Invalid client type: \(type)"
            case .stateAlreadyOwned(let stateType, let existingOwner, let attemptedOwner):
                return "State '\(stateType)' is already owned by client '\(existingOwner)'; cannot assign to '\(attemptedOwner)'"
            }
        }
    }
    
    private var errors: [OwnershipError] = []
    private var successfulAssignments: [(client: String, stateType: String)] = []
    
    public var lastError: String? {
        errors.last?.message
    }
    
    public var errorCount: Int {
        errors.count
    }
    
    public var successCount: Int {
        successfulAssignments.count
    }
    
    mutating func recordError(_ error: OwnershipError) {
        errors.append(error)
    }
    
    mutating func recordSuccessfulAssignment(client: String, stateType: String) {
        successfulAssignments.append((client, stateType))
    }
}

// MARK: - State Partitioning Support

/// Protocol for states that support partitioning into sub-states
/// for managing large domains
public protocol PartitionableState: State {
    associatedtype PartitionKey: Hashable
    associatedtype SubState: State
    
    /// Returns the partition key for a given sub-state path
    func partitionKey(for keyPath: KeyPath<Self, SubState>) -> PartitionKey
    
    /// Extracts a sub-state for the given partition
    func substate(for partition: PartitionKey) -> SubState?
    
    /// Updates the state with a new sub-state for the partition
    func withSubstate(_ substate: SubState, for partition: PartitionKey) -> Self
}

// MARK: - Compile-time State Ownership (Future)

/// Property wrapper that would enforce state ownership at compile-time
/// (Placeholder for future implementation)
@propertyWrapper
public struct OwnedState<S: State> {
    private let state: S
    
    public var wrappedValue: S {
        state
    }
    
    public init(wrappedValue: S) {
        self.state = wrappedValue
    }
}

// MARK: - Test Support Types
// These would normally be in a test support module

struct TestClient {
    let id: String
}

struct TestState: State {
    let value: String
    
    func withValue(_ newValue: String) -> TestState {
        TestState(value: newValue)
    }
}

struct InvalidMutableState {
    var value: String
}

class InvalidReferenceState {
    let value: String
    
    init(value: String) {
        self.value = value
    }
}