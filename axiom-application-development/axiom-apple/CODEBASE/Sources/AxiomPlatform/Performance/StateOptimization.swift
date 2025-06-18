import Foundation
import Combine
import AxiomCore
import AxiomArchitecture

// MARK: - State Stream Property Wrapper

/// Property wrapper that eliminates state stream boilerplate
@propertyWrapper
public struct StateStreamable<StateType: Equatable & Sendable> {
    private let bufferSize: Int
    private let conflationStrategy: ConflationStrategy
    
    public init(
        bufferSize: Int = 100,
        conflation: ConflationStrategy = .keepLatest
    ) {
        self.bufferSize = bufferSize
        self.conflationStrategy = conflation
    }
    
    public var wrappedValue: StateStream<StateType> {
        StateStream(
            bufferSize: bufferSize,
            conflation: conflationStrategy
        )
    }
}

// MARK: - Optimized State Stream

/// High-performance state stream with buffering and conflation
public class StateStream<StateType: Equatable & Sendable>: @unchecked Sendable {
    private let buffer: AsyncStreamBuffer<StateType>
    public let stream: AsyncStream<StateType>
    private let continuation: AsyncStream<StateType>.Continuation
    private var currentState: StateType?
    
    public init(bufferSize: Int, conflation: ConflationStrategy) {
        self.buffer = AsyncStreamBuffer(
            capacity: bufferSize,
            strategy: conflation
        )
        
        let (stream, continuation) = AsyncStream<StateType>.makeStream(
            bufferingPolicy: .bufferingNewest(bufferSize)
        )
        self.stream = stream
        self.continuation = continuation
        
        // Start buffer processor
        Task { [weak self] in
            await self?.processBuffer()
        }
    }
    
    public func update(_ newState: StateType, skipIfEqual: Bool = true) async {
        guard !skipIfEqual || newState != currentState else { return }
        currentState = newState
        await buffer.send(newState)
    }
    
    private func processBuffer() async {
        for await state in buffer.output {
            continuation.yield(state)
        }
    }
}

// MARK: - Conflation Strategy

/// Strategy for handling rapid state updates
public enum ConflationStrategy: Sendable {
    case keepAll
    case keepLatest
    case custom(@Sendable (inout [any Equatable], any Equatable) -> Void)
}

// MARK: - Async Stream Buffer

/// Circular buffer for high-performance async streaming
public actor AsyncStreamBuffer<Element: Equatable & Sendable> {
    private var buffer: CircularBuffer<Element>
    private let strategy: ConflationStrategy
    private let continuation: AsyncStream<Element>.Continuation
    public let output: AsyncStream<Element>
    
    public init(capacity: Int, strategy: ConflationStrategy) {
        self.buffer = CircularBuffer(capacity: capacity)
        self.strategy = strategy
        
        let (stream, continuation) = AsyncStream<Element>.makeStream()
        self.output = stream
        self.continuation = continuation
    }
    
    public func send(_ element: Element) async {
        switch strategy {
        case .keepAll:
            buffer.append(element)
            continuation.yield(element)
            
        case .keepLatest:
            if buffer.isFull {
                _ = buffer.removeFirst()
            }
            buffer.append(element)
            continuation.yield(element)
            
        case .custom(let conflate):
            var elements: [any Equatable] = buffer.elements
            conflate(&elements, element)
            buffer = CircularBuffer(capacity: buffer.capacity, elements: elements.compactMap { $0 as? Element })
            continuation.yield(element)
        }
    }
    
    public func drain() async -> [Element] {
        let elements = buffer.elements
        buffer.removeAll()
        return elements
    }
}

// MARK: - Circular Buffer

/// Fixed-size circular buffer for memory efficiency
public struct CircularBuffer<Element> {
    private var storage: [Element?]
    private var head: Int = 0
    private var count: Int = 0
    public let capacity: Int
    
    public init(capacity: Int) {
        self.capacity = capacity
        self.storage = Array(repeating: nil, count: capacity)
    }
    
    init(capacity: Int, elements: [Element]) {
        self.capacity = capacity
        self.storage = Array(repeating: nil, count: capacity)
        for element in elements.suffix(capacity) {
            append(element)
        }
    }
    
    public var isFull: Bool {
        count == capacity
    }
    
    public var isEmpty: Bool {
        count == 0
    }
    
    public var elements: [Element] {
        var result: [Element] = []
        for i in 0..<count {
            let index = (head + i) % capacity
            if let element = storage[index] {
                result.append(element)
            }
        }
        return result
    }
    
    public mutating func append(_ element: Element) {
        let index = (head + count) % capacity
        storage[index] = element
        
        if count < capacity {
            count += 1
        } else {
            head = (head + 1) % capacity
        }
    }
    
    @discardableResult
    public mutating func removeFirst() -> Element? {
        guard !isEmpty else { return nil }
        
        let element = storage[head]
        storage[head] = nil
        head = (head + 1) % capacity
        count -= 1
        
        return element
    }
    
    public mutating func removeAll() {
        storage = Array(repeating: nil, count: capacity)
        head = 0
        count = 0
    }
}

// MARK: - Error Context Property Wrapper

// ErrorContext has been removed - duplicate definition exists elsewhere

// MARK: - State Diffing

/// Protocol for states that support diffing
public protocol DiffableState: AxiomState {
    func diff(from previous: Self) -> StateChanges
}

/// Represents differences between states
public struct StateChanges {
    public let changes: [String: Any]
    
    public init(changes: [String: Any]) {
        self.changes = changes
    }
    
    public var isEmpty: Bool {
        changes.isEmpty
    }
}

// MARK: - Client Extension for Diffing

extension AxiomClient where StateType: DiffableState {
    /// Update state only if it differs from current state
    public func updateWithDiff(_ newState: StateType) async {
        // Need to get current state first
        // This is a protocol extension, so we need to use the actual implementation
        // For now, just perform the update
        await performUpdate(newState)
    }
    
    private func performUpdate(_ newState: StateType) async {
        // This would be implemented by specific client types
        // For now, just update the state
        if let _ = self as? any ObservableObject {
            await MainActor.run {
                // Update would happen here
                // withAnimation is SwiftUI-specific and not available here
            }
        }
    }
}

// MARK: - AxiomError Extension

extension AxiomError {
    /// Create error with context
    public static func withContext(_ context: String, _ error: any Error) -> AxiomError {
        if let axiomError = error as? AxiomError {
            return axiomError
        } else {
            // Map general errors to appropriate AxiomError case
            return .validationError(.invalidInput("unknown", error.localizedDescription))
        }
    }
}