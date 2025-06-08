import Foundation

/// A utility for debouncing async operations
actor AsyncDebouncer {
    private let delay: TimeInterval
    private var currentTask: Task<Void, Never>?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    /// Debounce an async operation
    /// - Parameter operation: The operation to debounce
    /// - Returns: A task that completes when the debounced operation finishes (for testing)
    @discardableResult
    func debounce(operation: @escaping @Sendable () async -> Void) async -> Task<Void, Never> {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Create new task with delay
        let task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await operation()
            } catch {
                // Task was cancelled, ignore
            }
        }
        
        currentTask = task
        return task
    }
    
    /// Wait for any pending debounced operation to complete (for testing)
    func waitForPendingOperation() async {
        if let task = currentTask {
            await task.value
        }
    }
}