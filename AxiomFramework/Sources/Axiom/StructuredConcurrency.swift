import Foundation

// MARK: - Structured Concurrency Utilities

/// Extension to support concurrent mapping operations on collections
public extension Collection where Element: Sendable {
    /// Process collection items concurrently
    func asyncMap<T: Sendable>(
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in enumerated() {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }
            
            var results = [(Int, T)]()
            for try await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }
    
    /// Process with concurrency limit
    func asyncMap<T: Sendable>(
        maxConcurrency: Int,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        precondition(maxConcurrency > 0, "Max concurrency must be positive")
        
        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var index = 0
            let elements = Array(self)
            
            // Initial batch
            for element in elements.prefix(maxConcurrency) {
                let currentIndex = index
                group.addTask {
                    let result = try await transform(element)
                    return (currentIndex, result)
                }
                index += 1
            }
            
            var results = [(Int, T)]()
            
            // Process remaining with sliding window
            for element in elements.dropFirst(maxConcurrency) {
                let (completedIndex, result) = try await group.next()!
                results.append((completedIndex, result))
                
                let currentIndex = index
                group.addTask {
                    let result = try await transform(element)
                    return (currentIndex, result)
                }
                index += 1
            }
            
            // Collect remaining
            for try await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }
    
    /// Process items concurrently without preserving order
    func asyncForEach(
        _ operation: @escaping @Sendable (Element) async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
            try await group.waitForAll()
        }
    }
    
    /// Process items with concurrency limit without preserving order
    func asyncForEach(
        maxConcurrency: Int,
        _ operation: @escaping @Sendable (Element) async throws -> Void
    ) async throws {
        precondition(maxConcurrency > 0, "Max concurrency must be positive")
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var iterator = makeIterator()
            
            // Start initial batch
            for _ in 0..<maxConcurrency {
                guard let element = iterator.next() else { break }
                group.addTask {
                    try await operation(element)
                }
            }
            
            // Process remaining with sliding window
            while let element = iterator.next() {
                // Wait for one to complete before adding next
                try await group.next()
                group.addTask {
                    try await operation(element)
                }
            }
            
            // Wait for remaining tasks
            try await group.waitForAll()
        }
    }
}

// MARK: - Async Sequence Utilities

/// Async sequence wrapper for state updates
public struct StateUpdates<State: Sendable>: AsyncSequence {
    public typealias Element = State
    
    private let stream: AsyncStream<State>
    
    public init(stream: AsyncStream<State>) {
        self.stream = stream
    }
    
    public func makeAsyncIterator() -> AsyncStream<State>.Iterator {
        stream.makeAsyncIterator()
    }
}

/// Extension for creating async sequences from various sources
public extension AsyncSequence {
    /// Collect all elements into an array
    func collect() async throws -> [Element] where Element: Sendable {
        var results: [Element] = []
        for try await element in self {
            results.append(element)
        }
        return results
    }
    
    /// Transform elements concurrently up to a maximum
    func asyncMap<T: Sendable>(
        maxConcurrency: Int = .max,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) -> AsyncThrowingMapSequence<Self, T> where Element: Sendable {
        AsyncThrowingMapSequence(base: self, transform: transform, maxConcurrency: maxConcurrency)
    }
}

/// Async sequence that maps elements with controlled concurrency
public struct AsyncThrowingMapSequence<Base: AsyncSequence, Output: Sendable>: AsyncSequence where Base.Element: Sendable {
    public typealias Element = Output
    
    let base: Base
    let transform: @Sendable (Base.Element) async throws -> Output
    let maxConcurrency: Int
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(
            baseIterator: base.makeAsyncIterator(),
            transform: transform,
            maxConcurrency: maxConcurrency
        )
    }
    
    public struct AsyncIterator: AsyncIteratorProtocol {
        var baseIterator: Base.AsyncIterator
        let transform: @Sendable (Base.Element) async throws -> Output
        let maxConcurrency: Int
        
        public mutating func next() async throws -> Output? {
            guard let element = try await baseIterator.next() else {
                return nil
            }
            return try await transform(element)
        }
    }
}

// MARK: - Task Extensions

public extension Task where Success == Never, Failure == Never {
    /// Sleep for a specific duration with cancellation support
    static func sleep(duration: AsyncDuration) async throws {
        try await Task.sleep(nanoseconds: UInt64(duration.components.seconds * 1_000_000_000 + duration.components.attoseconds / 1_000_000_000))
    }
}

/// Simplified duration type for async operations
public struct AsyncDuration: Sendable {
    public let components: (seconds: Int64, attoseconds: Int64)
    
    public static func seconds(_ value: Double) -> AsyncDuration {
        let seconds = Int64(value)
        let attoseconds = Int64((value - Double(seconds)) * 1e18)
        return AsyncDuration(components: (seconds, attoseconds))
    }
    
    public static func milliseconds(_ value: Int) -> AsyncDuration {
        AsyncDuration(components: (0, Int64(value) * 1_000_000_000_000_000))
    }
}

// MARK: - Async Stream Utilities

public extension AsyncStream {
    /// Create a stream with a yield function
    static func makeStream(
        of elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncStream<Element>, yield: (Element) -> Void) where Element: Sendable {
        var continuation: AsyncStream<Element>.Continuation!
        let stream = AsyncStream<Element>(bufferingPolicy: limit) { cont in
            continuation = cont
        }
        let yield: (Element) -> Void = { element in
            continuation.yield(element)
        }
        return (stream, yield)
    }
    
    /// Create a stream with full continuation control
    static func makeStreamWithContinuation(
        of elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncStream<Element>, continuation: AsyncStream<Element>.Continuation) where Element: Sendable {
        var continuation: AsyncStream<Element>.Continuation!
        let stream = AsyncStream<Element>(bufferingPolicy: limit) { cont in
            continuation = cont
        }
        return (stream, continuation)
    }
}

// MARK: - Actor Utilities

/// Protocol for actors that can be safely reset
public protocol ResettableActor: Actor {
    func reset() async
}

/// Coordinator for managing groups of actors
public actor ActorCoordinator<ActorType: ResettableActor> {
    private var actors: [String: ActorType] = [:]
    
    public init() {}
    
    /// Register an actor with an identifier
    public func register(_ actor: ActorType, id: String) {
        actors[id] = actor
    }
    
    /// Get an actor by identifier
    public func get(id: String) -> ActorType? {
        actors[id]
    }
    
    /// Reset all actors concurrently
    public func resetAll() async {
        await withTaskGroup(of: Void.self) { group in
            for actor in actors.values {
                group.addTask {
                    await actor.reset()
                }
            }
        }
    }
    
    /// Remove an actor
    public func remove(id: String) {
        actors.removeValue(forKey: id)
    }
}