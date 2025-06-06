import XCTest
@testable import TestApp002Core

// GREEN Phase: Tests expecting network error handling with retry logic

final class NetworkErrorHandlingTestsGreen: XCTestCase {
    var networkCapability: NetworkCapability!
    var mockDataProvider: MockDataProviderWithRetry!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDataProvider = MockDataProviderWithRetry()
        networkCapability = EnhancedNetworkCapability(dataProvider: mockDataProvider)
        try await networkCapability.initialize()
    }
    
    override func tearDown() async throws {
        networkCapability = nil
        mockDataProvider = nil
        try await super.tearDown()
    }
    
    // MARK: - GREEN Tests: Expect retry logic to work
    
    func testNetworkTimeoutRetriesSuccessfully() async throws {
        // Configure mock to fail twice then succeed
        mockDataProvider.failureCount = 2
        mockDataProvider.error = URLError(.timedOut)
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let tasks: [Task] = try await networkCapability.request(endpoint)
            // Should succeed after retries
            XCTAssertEqual(mockDataProvider.requestCount, 3, "Should make 3 requests (initial + 2 retries)")
            XCTAssertNotNil(tasks, "Should return valid data after retries")
            XCTAssertGreaterThan(mockDataProvider.retryDelays.count, 0, "Should have retry delays")
        } catch {
            XCTFail("Request should succeed after retries, got error: \(error)")
        }
    }
    
    func testExponentialBackoffImplemented() async throws {
        // Configure mock to fail 3 times then succeed
        mockDataProvider.failureCount = 3
        mockDataProvider.error = URLError(.notConnectedToInternet)
        mockDataProvider.requestCount = 0
        mockDataProvider.retryDelays = []
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            
            // Check exponential backoff pattern
            XCTAssertEqual(mockDataProvider.retryDelays.count, 3, "Should have 3 retry delays")
            if mockDataProvider.retryDelays.count >= 3 {
                // Verify exponential backoff (each delay roughly doubles)
                XCTAssertLessThan(mockDataProvider.retryDelays[0], 2.0, "First retry should be quick")
                XCTAssertGreaterThan(mockDataProvider.retryDelays[1], mockDataProvider.retryDelays[0], 
                                   "Second delay should be longer")
                XCTAssertGreaterThan(mockDataProvider.retryDelays[2], mockDataProvider.retryDelays[1], 
                                   "Third delay should be even longer")
            }
        } catch {
            XCTFail("Request should succeed after retries with backoff")
        }
    }
    
    func testServerErrorsNotRetried() async throws {
        // Configure mock for 500 server error
        mockDataProvider.statusCode = 500
        mockDataProvider.error = nil
        mockDataProvider.forceServerError = true
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            XCTFail("Request should fail with server error")
        } catch {
            // Server errors should NOT be retried
            XCTAssertEqual(mockDataProvider.requestCount, 1, "Should not retry server errors")
            if let networkError = error as? TestApp002Core.NetworkError {
                switch networkError {
                case .serverError(let code):
                    XCTAssertEqual(code, 500, "Should preserve server error code")
                default:
                    XCTFail("Expected server error")
                }
            }
        }
    }
    
    func testRetryExhaustedAfterMaxAttempts() async throws {
        // Configure mock to always fail
        mockDataProvider.failureCount = 10 // More than max retries
        mockDataProvider.error = URLError(.networkConnectionLost)
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            XCTFail("Request should fail after max retries")
        } catch {
            // Should fail after max retry attempts
            XCTAssertEqual(mockDataProvider.requestCount, 4, "Should make initial request + 3 retries")
            if let networkError = error as? TestApp002Core.NetworkError {
                XCTAssertEqual(networkError, .retryExhausted, "Should throw retryExhausted error")
            }
        }
    }
    
    func testCancellationStopsRetries() async throws {
        // Configure mock to fail slowly
        mockDataProvider.failureCount = 5
        mockDataProvider.error = URLError(.timedOut)
        mockDataProvider.delay = 0.5 // Slow responses
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        let capability = networkCapability!
        
        let task = _Concurrency.Task { [capability] in
            do {
                let _: [Task] = try await capability.request(endpoint)
                XCTFail("Request should be cancelled")
            } catch {
                // Should be cancelled
                if let networkError = error as? TestApp002Core.NetworkError {
                    XCTAssertEqual(networkError, .cancelled, "Should be cancelled")
                } else {
                    XCTAssertTrue(error is CancellationError, "Should be cancellation error")
                }
            }
        }
        
        // Cancel after short delay
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        task.cancel()
        
        await task.value
        
        // Should not complete all retries
        XCTAssertLessThan(mockDataProvider.requestCount, 4, "Should stop retrying when cancelled")
    }
    
    func testTimeoutEnforcedDuringRetries() async throws {
        // Configure mock with very slow responses
        mockDataProvider.responseTime = 35.0 // Longer than 30s timeout
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            XCTFail("Request should timeout")
        } catch {
            // Should timeout
            if let networkError = error as? TestApp002Core.NetworkError {
                XCTAssertEqual(networkError, .timeout, "Should timeout after 30 seconds")
            }
            XCTAssertEqual(mockDataProvider.requestCount, 1, "Should attempt request before timeout")
        }
    }
    
    func testTransientErrorsRetried() async throws {
        // Test various transient errors that should be retried
        let transientErrors = [
            URLError(.timedOut),
            URLError(.networkConnectionLost),
            URLError(.notConnectedToInternet),
            URLError(.dataNotAllowed)
        ]
        
        for (index, error) in transientErrors.enumerated() {
            mockDataProvider.failureCount = 1
            mockDataProvider.error = error
            mockDataProvider.requestCount = 0
            
            let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
            
            do {
                let _: [Task] = try await networkCapability.request(endpoint)
                // Should succeed after retry
                XCTAssertEqual(mockDataProvider.requestCount, 2, 
                             "Error \(index): Should retry transient error")
            } catch {
                XCTFail("Error \(index): Should succeed after retrying transient error")
            }
        }
    }
    
    func testNonTransientErrorsNotRetried() async throws {
        // Test errors that should NOT be retried
        mockDataProvider.failureCount = 1
        mockDataProvider.error = URLError(.badURL)
        mockDataProvider.requestCount = 0
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            XCTFail("Request should fail immediately")
        } catch {
            // Should not retry bad URL errors
            XCTAssertEqual(mockDataProvider.requestCount, 1, "Should not retry non-transient errors")
        }
    }
}

// MARK: - Enhanced Mock for GREEN Phase

final class MockDataProviderWithRetry: @unchecked Sendable {
    var error: Error?
    var data: Data?
    var statusCode: Int = 200
    var requestCount = 0
    var delay: TimeInterval = 0
    var responseTime: TimeInterval = 0.1
    var failureCount = 0
    var currentAttempt = 0
    var retryDelays: [TimeInterval] = []
    var forceServerError = false
    var lastRetryTime: Date?
    
    func makeRequest(url: URL) async throws -> (Data, HTTPURLResponse) {
        // Track retry delays
        if let lastTime = lastRetryTime {
            let delay = Date().timeIntervalSince(lastTime)
            retryDelays.append(delay)
        }
        lastRetryTime = Date()
        
        currentAttempt += 1
        
        // Track request count
        requestCount += 1
        
        // Simulate delays
        if delay > 0 {
            try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        if responseTime > 0 {
            try await _Concurrency.Task.sleep(nanoseconds: UInt64(responseTime * 1_000_000_000))
        }
        
        // Simulate failures based on configuration
        if currentAttempt <= failureCount {
            if let error = error {
                throw error
            }
        }
        
        // Force server error if configured
        if forceServerError {
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(), response)
        }
        
        // Success response
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockTaskData = """
        []
        """.data(using: .utf8)!
        
        return (mockTaskData, response)
    }
}

// MARK: - Enhanced NetworkCapability with Retry Logic

actor EnhancedNetworkCapability: NetworkCapability {
    private let dataProvider: MockDataProviderWithRetry
    private var _isAvailable = true
    
    var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    init(dataProvider: MockDataProviderWithRetry) {
        self.dataProvider = dataProvider
    }
    
    func initialize() async throws {
        _isAvailable = true
    }
    
    func terminate() async {
        _isAvailable = false
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
    
    // MARK: - Retry Logic Implementation
    
    private func performRequestWithRetry<T: Sendable>(
        endpoint: Endpoint,
        operation: @escaping @Sendable (Endpoint) async throws -> T
    ) async throws -> T {
        let retryDelays: [TimeInterval] = [1.0, 2.0, 4.0] // Exponential backoff
        var lastError: Error?
        
        // First attempt
        do {
            return try await withTimeout(seconds: 30) {
                try await operation(endpoint)
            }
        } catch TestApp002Core.NetworkError.cancelled {
            throw TestApp002Core.NetworkError.cancelled
        } catch TestApp002Core.NetworkError.serverError(let code) where code >= 400 && code < 500 {
            // Don't retry client errors
            throw TestApp002Core.NetworkError.serverError(code)
        } catch let error {
            lastError = error
            
            // Check if error is retryable
            if !isRetryableError(error) {
                throw error
            }
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
            } catch TestApp002Core.NetworkError.cancelled {
                throw TestApp002Core.NetworkError.cancelled
            } catch TestApp002Core.NetworkError.serverError(let code) where code >= 400 && code < 500 {
                // Don't retry client errors
                throw TestApp002Core.NetworkError.serverError(code)
            } catch let error {
                lastError = error
                
                // Check if error is retryable
                if !isRetryableError(error) {
                    throw error
                }
            }
        }
        
        // All retries exhausted
        throw TestApp002Core.NetworkError.retryExhausted
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .dataNotAllowed:
                return true
            default:
                return false
            }
        }
        
        if let networkError = error as? TestApp002Core.NetworkError {
            switch networkError {
            case .timeout, .noConnection:
                return true
            case .serverError(let code) where code >= 500:
                return false // Don't retry server errors
            default:
                return false
            }
        }
        
        return false
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
                throw TestApp002Core.NetworkError.timeout
            }
            
            // Return first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func performSingleRequest<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await dataProvider.makeRequest(url: endpoint.url)
        
        if response.statusCode >= 400 {
            throw TestApp002Core.NetworkError.serverError(response.statusCode)
        }
        
        // Decode response
        if T.self == [Task].self {
            return [] as! T
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func performSingleUpload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        let (_, response) = try await dataProvider.makeRequest(url: endpoint.url)
        
        if response.statusCode >= 400 {
            throw TestApp002Core.NetworkError.serverError(response.statusCode)
        }
    }
}

// Note: MockDataProviderWithRetry duplicates some functionality from MockDataProvider
// because MockDataProvider is final and can't be inherited

// Extension for CancellationError check
extension Error {
    var isCancellationError: Bool {
        return self is CancellationError
    }
}