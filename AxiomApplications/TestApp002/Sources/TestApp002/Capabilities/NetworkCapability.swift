import Foundation

// Protocol definition as per RFC
protocol NetworkCapability: Capability {
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws
}

// Endpoint definition
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryParameters: [String: String]
    
    init(path: String, method: HTTPMethod = .get, headers: [String: String] = [:], queryParameters: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
    }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}


// Network errors
enum NetworkError: Error, Equatable {
    case timeout
    case noConnection
    case serverError(Int)
    case invalidResponse
    case cancelled
    case retryExhausted
}

// GREEN Phase: NetworkCapability implementation with retry logic
actor TestNetworkCapability: NetworkCapability {
    private var isInitialized = false
    
    nonisolated var isAvailable: Bool {
        return true
    }
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func terminate() async {
        isInitialized = false
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await performRequestWithRetry(endpoint: endpoint) { [self] endpoint in
            try await self.performSingleRequest(endpoint)
        }
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        try await performRequestWithRetry(endpoint: endpoint) { [self] endpoint in
            try await self.performSingleUpload(data, to: endpoint)
        }
    }
    
    // MARK: - Private Implementation
    
    private func performRequestWithRetry<T: Sendable>(
        endpoint: Endpoint,
        operation: @escaping @Sendable (Endpoint) async throws -> T
    ) async throws -> T {
        let retryDelays: [TimeInterval] = [1.0, 2.0, 4.0] // Exponential backoff as per RFC
        var lastError: NetworkError = .noConnection
        
        // First attempt
        do {
            return try await withTimeout(seconds: 30) {
                try await operation(endpoint)
            }
        } catch NetworkError.cancelled {
            throw NetworkError.cancelled
        } catch let error as NetworkError {
            lastError = error
            
            // Don't retry on certain errors
            if error == .cancelled || error == .invalidResponse {
                throw error
            }
        } catch {
            lastError = .invalidResponse
        }
        
        // Retry attempts with exponential backoff
        for delay in retryDelays {
            try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check for cancellation
            try _Concurrency.Task.checkCancellation()
            
            do {
                return try await withTimeout(seconds: 30) {
                    try await operation(endpoint)
                }
            } catch NetworkError.cancelled {
                throw NetworkError.cancelled
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry on certain errors
                if error == .cancelled || error == .invalidResponse {
                    throw error
                }
            } catch {
                lastError = .invalidResponse
            }
        }
        
        // All retries exhausted
        throw NetworkError.retryExhausted
    }
    
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the operation
            group.addTask {
                try await operation()
            }
            
            // Add the timeout
            group.addTask {
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NetworkError.timeout
            }
            
            // Return first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func performSingleRequest<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        // Simulate network behavior for testing
        // In a real implementation, this would use URLSession
        
        // Check for cancellation
        try _Concurrency.Task.checkCancellation()
        
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // For testing purposes, return empty data that will decode properly
        if T.self == Array<Task>.self {
            return [] as! T
        } else if T.self == Task.self {
            let mockTask = Task(
                id: "mock",
                title: "Mock Task",
                description: "Mock Description",
                dueDate: nil,
                categoryId: nil,
                priority: .medium,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            return mockTask as! T
        }
        
        throw NetworkError.invalidResponse
    }
    
    private func performSingleUpload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        // Check for cancellation
        try _Concurrency.Task.checkCancellation()
        
        // Simulate upload delay
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Simulate successful upload (no return value)
    }
}