import Foundation
import Combine

// MARK: - State Stream Property Wrapper

/// Property wrapper that eliminates state stream boilerplate
@propertyWrapper
public struct StateStreamable<StateType: Equatable> {
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
public class StateStream<StateType: Equatable> {
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
        Task {
            await processBuffer()
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
public enum ConflationStrategy {
    case keepAll
    case keepLatest
    case custom((inout [any Equatable], any Equatable) -> Void)
}

// MARK: - Async Stream Buffer

/// Circular buffer for high-performance async streaming
public actor AsyncStreamBuffer<Element: Equatable> {
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
            var elements = buffer.elements
            conflate(&elements, element)
            buffer = CircularBuffer(capacity: buffer.capacity, elements: elements)
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

/// Property wrapper that automatically adds error context
@propertyWrapper
public struct ErrorContext {
    private let context: String
    
    public init(_ context: String) {
        self.context = context
    }
    
    public var wrappedValue: (@escaping () async throws -> Any) -> () async throws -> Any {
        return { operation in
            return {
                do {
                    return try await operation()
                } catch {
                    throw AxiomError.withContext(self.context, error)
                }
            }
        }
    }
}

// MARK: - State Diffing

/// Protocol for states that support diffing
public protocol DiffableState: State {
    func diff(from previous: Self) -> StateDiff
}

/// Represents differences between states
public struct StateDiff {
    public let changes: [String: Any]
    
    public init(changes: [String: Any]) {
        self.changes = changes
    }
    
    public var isEmpty: Bool {
        changes.isEmpty
    }
}

// MARK: - Client Extension for Diffing

extension Client where StateType: DiffableState {
    /// Update state only if it differs from current state
    public func updateWithDiff(_ newState: StateType) async {
        let diff = newState.diff(from: state)
        guard !diff.isEmpty else { return }
        await performUpdate(newState)
    }
    
    private func performUpdate(_ newState: StateType) async {
        // This would be implemented by specific client types
        // For now, just update the state
        if var mutableSelf = self as? any ObservableObject {
            await MainActor.run {
                withAnimation {
                    // Update would happen here
                }
            }
        }
    }
}

// MARK: - AxiomError Extension

extension AxiomError {
    /// Create error with context
    public static func withContext(_ context: String, _ error: Error) -> AxiomError {
        if let axiomError = error as? AxiomError {
            return axiomError
        } else {
            return .generalError(message: "\(context): \(error.localizedDescription)")
        }
    }
}