import Foundation

// MARK: - Core Identifiers

/// A unique identifier for components within the Axiom framework
public struct ComponentID: Hashable, Sendable, Codable, CustomStringConvertible {
    private let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public static func generate() -> ComponentID {
        ComponentID(UUID().uuidString)
    }
    
    public var description: String { value }
}

/// A version identifier for state tracking and validation
public struct StateVersion: Comparable, Hashable, Sendable, Codable, CustomStringConvertible {
    private let major: Int
    private let minor: Int
    private let timestamp: TimeInterval
    
    public init(major: Int = 1, minor: Int = 0, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.major = major
        self.minor = minor
        self.timestamp = timestamp
    }
    
    public static func < (lhs: StateVersion, rhs: StateVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.timestamp < rhs.timestamp
    }
    
    public func incrementMajor() -> StateVersion {
        StateVersion(major: major + 1, minor: 0)
    }
    
    public func incrementMinor() -> StateVersion {
        StateVersion(major: major, minor: minor + 1)
    }
    
    public var description: String { "\(major).\(minor)" }
}

/// A unique identifier for capabilities within the system
public struct CapabilityID: Hashable, Sendable, Codable, CustomStringConvertible {
    private let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public var description: String { value }
}


// MARK: - Sendable Wrapper Types

/// A thread-safe wrapper for any value type
@dynamicMemberLookup
public struct SendableValue<T: Sendable>: Sendable {
    private let value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
        value[keyPath: keyPath]
    }
}

/// A thread-safe wrapper for arrays
public struct SendableArray<Element: Sendable>: Sendable {
    private let elements: [Element]
    
    public init(_ elements: [Element]) {
        self.elements = elements
    }
    
    public var count: Int { elements.count }
    public var isEmpty: Bool { elements.isEmpty }
    
    public subscript(index: Int) -> Element {
        elements[index]
    }
    
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        try elements.map(transform)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try elements.filter(isIncluded)
    }
}

/// A thread-safe wrapper for dictionaries
public struct SendableDictionary<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private let dictionary: [Key: Value]
    
    public init(_ dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }
    
    public var count: Int { dictionary.count }
    public var isEmpty: Bool { dictionary.isEmpty }
    public var keys: [Key] { Array(dictionary.keys) }
    public var values: [Value] { Array(dictionary.values) }
    
    public subscript(key: Key) -> Value? {
        dictionary[key]
    }
}

// MARK: - Measurement Token

/// A token used for performance measurement tracking
public struct MeasurementToken: Sendable {
    let id: UUID
    let operation: String
    let startTime: TimeInterval
    
    init(operation: String) {
        self.id = UUID()
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    public var elapsed: TimeInterval {
        CFAbsoluteTimeGetCurrent() - startTime
    }
}

// MARK: - Type Aliases

/// A closure that performs a state update
public typealias StateUpdate<State> = @Sendable (inout State) throws -> Void

/// A closure that transforms state
public typealias StateTransform<State, T> = @Sendable (inout State) throws -> T

/// A closure that validates state
public typealias StateValidator<State> = @Sendable (State) throws -> Void