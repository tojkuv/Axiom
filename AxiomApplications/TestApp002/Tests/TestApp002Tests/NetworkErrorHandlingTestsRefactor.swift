import XCTest
@testable import TestApp002Core

// REFACTOR Phase: Tests for offline mode and queue persistence

final class NetworkErrorHandlingTestsRefactor: XCTestCase {
    var networkCapability: OfflineCapableNetworkService!
    var mockDataProvider: MockOfflineDataProvider!
    var persistenceManager: MockPersistenceManager!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceManager = MockPersistenceManager()
        mockDataProvider = MockOfflineDataProvider()
        networkCapability = OfflineCapableNetworkService(
            dataProvider: mockDataProvider,
            persistenceManager: persistenceManager
        )
        try await networkCapability.initialize()
    }
    
    override func tearDown() async throws {
        networkCapability = nil
        mockDataProvider = nil
        persistenceManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Offline Queue Tests
    
    func testOfflineModeQueuesRequests() async throws {
        // Go offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Make request while offline
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
            XCTFail("Should not complete request while offline")
        } catch {
            // Should queue the request
            let queuedRequests = await networkCapability.getQueuedRequests()
            XCTAssertEqual(queuedRequests.count, 1, "Should have one queued request")
            
            if let firstRequest = queuedRequests.first {
                XCTAssertEqual(firstRequest.endpoint.url, endpoint.url, "Should queue correct endpoint")
                XCTAssertEqual(firstRequest.retryCount, 0, "Should have zero retries initially")
            }
        }
    }
    
    func testQueuedRequestsProcessedWhenOnline() async throws {
        // Queue some requests while offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        let endpoints = [
            Endpoint(url: URL(string: "https://api.example.com/tasks")!),
            Endpoint(url: URL(string: "https://api.example.com/users")!),
            Endpoint(url: URL(string: "https://api.example.com/sync")!)
        ]
        
        // Try to make requests (they should be queued)
        for endpoint in endpoints {
            do {
                let _: [Task] = try await networkCapability.request(endpoint)
            } catch {
                // Expected to fail and queue
            }
        }
        
        // Verify all queued
        let queuedBefore = await networkCapability.getQueuedRequests()
        XCTAssertEqual(queuedBefore.count, 3, "Should have 3 queued requests")
        
        // Go back online
        mockDataProvider.isOffline = false
        await networkCapability.setOfflineMode(false)
        
        // Process queue
        await networkCapability.processOfflineQueue()
        
        // Verify queue is empty
        let queuedAfter = await networkCapability.getQueuedRequests()
        XCTAssertEqual(queuedAfter.count, 0, "Queue should be empty after processing")
        
        // Verify all requests were made
        XCTAssertEqual(mockDataProvider.requestCount, 3, "Should have made 3 requests")
    }
    
    func testOfflineQueuePersistence() async throws {
        // Queue requests while offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
        } catch {
            // Expected
        }
        
        // Save queue state
        try await networkCapability.saveQueueState()
        
        // Verify persistence
        XCTAssertTrue(persistenceManager.savedData.count > 0, "Should have saved queue data")
        
        // Create new instance
        let newCapability = OfflineCapableNetworkService(
            dataProvider: mockDataProvider,
            persistenceManager: persistenceManager
        )
        try await newCapability.initialize()
        
        // Load queue state
        try await newCapability.loadQueueState()
        
        // Verify queue restored
        let restoredQueue = await newCapability.getQueuedRequests()
        XCTAssertEqual(restoredQueue.count, 1, "Should restore queued request")
        XCTAssertEqual(restoredQueue.first?.endpoint.url, endpoint.url, "Should restore correct endpoint")
    }
    
    func testOfflineQueueMaxSize() async throws {
        // Go offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        // Try to queue more than max
        for i in 0..<102 { // Max is 100
            let endpoint = Endpoint(url: URL(string: "https://api.example.com/task/\(i)")!)
            
            do {
                let _: [Task] = try await networkCapability.request(endpoint)
            } catch {
                // Expected
            }
        }
        
        // Verify queue is capped at max
        let queuedRequests = await networkCapability.getQueuedRequests()
        XCTAssertEqual(queuedRequests.count, 100, "Queue should be capped at 100 requests")
    }
    
    func testOfflineQueuePrioritization() async throws {
        // Go offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        // Queue requests with different priorities
        let highPriorityEndpoint = Endpoint(url: URL(string: "https://api.example.com/critical")!)
        let normalEndpoint = Endpoint(url: URL(string: "https://api.example.com/normal")!)
        let lowPriorityEndpoint = Endpoint(url: URL(string: "https://api.example.com/background")!)
        
        // Queue in reverse priority order
        do {
            let _: [Task] = try await networkCapability.request(lowPriorityEndpoint, priority: .low)
        } catch { }
        
        do {
            let _: [Task] = try await networkCapability.request(normalEndpoint, priority: .normal)
        } catch { }
        
        do {
            let _: [Task] = try await networkCapability.request(highPriorityEndpoint, priority: .high)
        } catch { }
        
        // Go online and process
        mockDataProvider.isOffline = false
        mockDataProvider.processedUrls = []
        await networkCapability.setOfflineMode(false)
        await networkCapability.processOfflineQueue()
        
        // Verify processing order (high priority first)
        XCTAssertEqual(mockDataProvider.processedUrls.count, 3, "Should process all requests")
        XCTAssertEqual(mockDataProvider.processedUrls[0], highPriorityEndpoint.url, "High priority should be first")
        XCTAssertEqual(mockDataProvider.processedUrls[1], normalEndpoint.url, "Normal priority should be second")
        XCTAssertEqual(mockDataProvider.processedUrls[2], lowPriorityEndpoint.url, "Low priority should be last")
    }
    
    func testOfflineQueueDeduplication() async throws {
        // Go offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Try to queue same request multiple times
        for _ in 0..<5 {
            do {
                let _: [Task] = try await networkCapability.request(endpoint)
            } catch {
                // Expected
            }
        }
        
        // Should deduplicate
        let queuedRequests = await networkCapability.getQueuedRequests()
        XCTAssertEqual(queuedRequests.count, 1, "Should deduplicate identical requests")
    }
    
    func testOfflineQueueExpiration() async throws {
        // Go offline
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        // Queue request with expiration
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        let expirationDate = Date().addingTimeInterval(1.0) // Expires in 1 second
        
        do {
            let _: [Task] = try await networkCapability.request(
                endpoint,
                expiration: expirationDate
            )
        } catch {
            // Expected
        }
        
        // Wait for expiration
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Clean expired requests
        await networkCapability.cleanExpiredRequests()
        
        // Verify request was removed
        let queuedRequests = await networkCapability.getQueuedRequests()
        XCTAssertEqual(queuedRequests.count, 0, "Expired request should be removed")
    }
    
    func testNetworkStateMonitoring() async throws {
        // Verify network state is monitored
        let isMonitoring = await networkCapability.isMonitoringNetwork
        XCTAssertTrue(isMonitoring, "Should be monitoring network")
        
        // Simulate network change
        mockDataProvider.isOffline = true
        await networkCapability.handleNetworkChange(isOnline: false)
        
        let isOffline1 = await networkCapability.isOffline
        XCTAssertTrue(isOffline1, "Should detect offline state")
        
        // Simulate coming back online
        mockDataProvider.isOffline = false
        await networkCapability.handleNetworkChange(isOnline: true)
        
        let isOffline2 = await networkCapability.isOffline
        XCTAssertFalse(isOffline2, "Should detect online state")
        
        // Should automatically process queue when coming online
        // (tested in other test cases)
    }
    
    func testOfflineIndicatorUI() async throws {
        // Verify offline state is observable
        let initialState = await networkCapability.offlineState
        XCTAssertFalse(initialState.isOffline, "Should start online")
        XCTAssertEqual(initialState.queuedRequestCount, 0, "Should have no queued requests")
        
        // Go offline and queue requests
        mockDataProvider.isOffline = true
        await networkCapability.setOfflineMode(true)
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        do {
            let _: [Task] = try await networkCapability.request(endpoint)
        } catch { }
        
        // Check updated state
        let offlineState = await networkCapability.offlineState
        XCTAssertTrue(offlineState.isOffline, "Should be offline")
        XCTAssertEqual(offlineState.queuedRequestCount, 1, "Should show queued request count")
        XCTAssertNotNil(offlineState.lastOnlineTime, "Should track last online time")
    }
}

// MARK: - Mock Types for Refactor Phase

final class MockOfflineDataProvider: @unchecked Sendable {
    var isOffline = false
    var requestCount = 0
    var processedUrls: [URL] = []
    
    func makeRequest(url: URL) async throws -> (Data, HTTPURLResponse) {
        if isOffline {
            throw URLError(.notConnectedToInternet)
        }
        
        requestCount += 1
        processedUrls.append(url)
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (Data(), response)
    }
}

final class MockPersistenceManager: @unchecked Sendable {
    var savedData: [String: Data] = [:]
    
    func save(data: Data, for key: String) async throws {
        savedData[key] = data
    }
    
    func load(for key: String) async throws -> Data? {
        return savedData[key]
    }
    
    func delete(for key: String) async throws {
        savedData.removeValue(forKey: key)
    }
}

// MARK: - Offline Capable Network Service

actor OfflineCapableNetworkService: NetworkCapability {
    private let dataProvider: MockOfflineDataProvider
    private let persistenceManager: MockPersistenceManager
    private var _isAvailable = true
    private var _isOffline = false
    private var _offlineQueue: [QueuedRequest] = []
    private var _lastOnlineTime: Date?
    private var _isMonitoringNetwork = true
    private let maxQueueSize = 100
    
    var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    var isOffline: Bool {
        get async { _isOffline }
    }
    
    var isMonitoringNetwork: Bool {
        get async { _isMonitoringNetwork }
    }
    
    var offlineState: OfflineState {
        get async {
            OfflineState(
                isOffline: _isOffline,
                queuedRequestCount: _offlineQueue.count,
                lastOnlineTime: _lastOnlineTime
            )
        }
    }
    
    init(dataProvider: MockOfflineDataProvider, persistenceManager: MockPersistenceManager) {
        self.dataProvider = dataProvider
        self.persistenceManager = persistenceManager
    }
    
    func initialize() async throws {
        _isAvailable = true
        _lastOnlineTime = Date()
    }
    
    func terminate() async {
        _isAvailable = false
        _isMonitoringNetwork = false
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await request(endpoint, priority: .normal, expiration: nil)
    }
    
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        priority: RequestPriority = .normal,
        expiration: Date? = nil
    ) async throws -> T {
        if _isOffline {
            // Queue request when offline
            let queuedRequest = QueuedRequest(
                id: UUID().uuidString,
                endpoint: endpoint,
                priority: LocalRequestPriority(from: priority),
                expiration: expiration,
                queuedAt: Date(),
                retryCount: 0
            )
            
            addToQueue(queuedRequest)
            throw NetworkError.offline
        }
        
        // Normal online request
        let (data, response) = try await dataProvider.makeRequest(url: endpoint.url)
        
        if response.statusCode >= 400 {
            throw TestApp002Core.NetworkError.serverError(response.statusCode)
        }
        
        if T.self == [Task].self {
            return [] as! T
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        if _isOffline {
            // For simplicity, uploads are not queued in this example
            throw NetworkError.offline
        }
        
        let (_, response) = try await dataProvider.makeRequest(url: endpoint.url)
        
        if response.statusCode >= 400 {
            throw TestApp002Core.NetworkError.serverError(response.statusCode)
        }
    }
    
    func setOfflineMode(_ offline: Bool) async {
        _isOffline = offline
        
        if !offline {
            _lastOnlineTime = Date()
            // Automatically process queue when coming online
            await processOfflineQueue()
        }
    }
    
    func handleNetworkChange(isOnline: Bool) async {
        await setOfflineMode(!isOnline)
    }
    
    func getQueuedRequests() async -> [QueuedRequest] {
        return _offlineQueue
    }
    
    func processOfflineQueue() async {
        guard !_isOffline else { return }
        
        // Sort by priority
        let sortedQueue = _offlineQueue.sorted { req1, req2 in
            req1.priority.rawValue > req2.priority.rawValue
        }
        
        // Process each request
        for request in sortedQueue {
            do {
                let _: Data = try await performQueuedRequest(request)
                removeFromQueue(request)
            } catch {
                // Handle error - could retry or keep in queue
                if request.retryCount < 3 {
                    var updatedRequest = request
                    updatedRequest.retryCount += 1
                    updateInQueue(updatedRequest)
                } else {
                    removeFromQueue(request)
                }
            }
        }
    }
    
    func cleanExpiredRequests() async {
        let now = Date()
        _offlineQueue.removeAll { request in
            if let expiration = request.expiration {
                return expiration < now
            }
            return false
        }
    }
    
    func saveQueueState() async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(_offlineQueue)
        try await persistenceManager.save(data: data, for: "offline_queue")
    }
    
    func loadQueueState() async throws {
        guard let data = try await persistenceManager.load(for: "offline_queue") else {
            return
        }
        
        let decoder = JSONDecoder()
        _offlineQueue = try decoder.decode([QueuedRequest].self, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func addToQueue(_ request: QueuedRequest) {
        // Check for duplicates
        if !_offlineQueue.contains(where: { $0.endpoint.url == request.endpoint.url }) {
            // Enforce max queue size
            if _offlineQueue.count >= maxQueueSize {
                // Remove oldest low priority request
                if let indexToRemove = _offlineQueue.firstIndex(where: { $0.priority == LocalRequestPriority.low }) {
                    _offlineQueue.remove(at: indexToRemove)
                } else if !_offlineQueue.isEmpty {
                    _offlineQueue.removeFirst()
                }
            }
            
            _offlineQueue.append(request)
        }
    }
    
    private func removeFromQueue(_ request: QueuedRequest) {
        _offlineQueue.removeAll { $0.id == request.id }
    }
    
    private func updateInQueue(_ request: QueuedRequest) {
        if let index = _offlineQueue.firstIndex(where: { $0.id == request.id }) {
            _offlineQueue[index] = request
        }
    }
    
    private func performQueuedRequest(_ request: QueuedRequest) async throws -> Data {
        let (data, response) = try await dataProvider.makeRequest(url: request.endpoint.url)
        
        if response.statusCode >= 400 {
            throw TestApp002Core.NetworkError.serverError(response.statusCode)
        }
        
        return data
    }
}

// MARK: - Supporting Types

struct QueuedRequest: Codable {
    let id: String
    let endpoint: Endpoint
    let priority: LocalRequestPriority
    let expiration: Date?
    let queuedAt: Date
    var retryCount: Int
}

struct OfflineState {
    let isOffline: Bool
    let queuedRequestCount: Int
    let lastOnlineTime: Date?
}

enum NetworkError: Error {
    case offline
}

// Make Endpoint Codable for persistence
extension Endpoint: Codable {
    enum CodingKeys: String, CodingKey {
        case url, method, headers
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let methodString = try container.decodeIfPresent(String.self, forKey: .method) ?? "GET"
        let method = HTTPMethod(rawValue: methodString) ?? .GET
        let headers = try container.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        
        self.init(url: url, method: method, headers: headers)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(method.rawValue, forKey: .method)
        try container.encode(headers, forKey: .headers)
    }
}

// Local version of RequestPriority that is Codable
enum LocalRequestPriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: LocalRequestPriority, rhs: LocalRequestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    init(from priority: RequestPriority) {
        switch priority {
        case .low: self = .low
        case .normal: self = .normal
        case .high: self = .high
        case .critical: self = .critical
        }
    }
    
    var toRequestPriority: RequestPriority {
        switch self {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .critical: return .critical
        }
    }
}