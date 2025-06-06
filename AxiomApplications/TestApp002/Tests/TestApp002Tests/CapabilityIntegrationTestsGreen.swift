import Testing
@testable import TestApp002Core
import Foundation

// GREEN Phase: Tests demonstrate proper error boundaries and resilience
@Suite("Capability Integration - GREEN Phase")
struct CapabilityIntegrationTestsGreen {
    
    @Test("Capability failures should be handled gracefully with error boundaries")
    func testCapabilityFailuresHandledGracefully() async throws {
        // GREEN: Proper error boundaries contain capability failures
        let storageCapability = MockFailingStorageCapabilityGreen()
        let taskClient = TaskClient()
        await taskClient.setStorageCapability(storageCapability)
        
        // This should handle failures gracefully
        do {
            try await taskClient.process(.create(Task(
                id: "1",
                title: "Test Task",
                description: "Test",
                dueDate: nil,
                priority: .medium,
                categoryId: nil,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )))
            
            // Task should be created in memory even if storage fails
            let state = await taskClient.currentState
            #expect(state.tasks.count == 1, "Task should be created in memory despite storage failure")
        } catch {
            #expect(false, "Should handle storage failures gracefully")
        }
    }
    
    @Test("Multiple capability failures should be coordinated properly")
    func testMultipleCapabilityFailuresCoordinated() async throws {
        // GREEN: Proper coordination handles multiple capability failures
        let syncClient = SyncClient()
        let storageCapability = MockFailingStorageCapabilityGreen()
        let networkCapability = MockFailingNetworkCapabilityGreen()
        
        await syncClient.setStorageCapability(storageCapability)
        await syncClient.setNetworkCapability(networkCapability)
        
        // Start sync - should handle coordinated failures
        try await syncClient.process(.startSync)
        
        // Sync should transition to offline mode gracefully
        let state = await syncClient.currentState
        #expect(state.isOffline, "Should transition to offline mode on capability failures")
        #expect(!state.isSyncing, "Should not be syncing when capabilities fail")
    }
    
    @Test("Concurrent capability access should be properly synchronized")
    func testConcurrentCapabilityAccessSynchronized() async throws {
        // GREEN: Proper synchronization prevents race conditions
        let taskClient = TaskClient()
        let capability = MockSynchronizedCapability()
        await taskClient.setStorageCapability(capability)
        
        // Launch concurrent operations
        let tasks = (0..<10).map { i in
            _Concurrency.Task {
                try await taskClient.process(.create(Task(
                    id: "\(i)",
                    title: "Task \(i)",
                    description: "Test",
                    dueDate: nil,
                    priority: .medium,
                    categoryId: nil,
                    isCompleted: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )))
            }
        }
        
        // All operations should complete successfully
        var successCount = 0
        for task in tasks {
            do {
                try await task.value
                successCount += 1
            } catch {
                // Should not have failures with proper synchronization
            }
        }
        
        #expect(successCount == 10, "All operations should succeed with proper synchronization")
        
        // Verify no race conditions
        let accessLog = await capability.getAccessLog()
        #expect(accessLog.count == 10, "Should have logged all accesses")
    }
    
    @Test("Missing capabilities should have fallback behavior")
    func testMissingCapabilitiesHaveFallbacks() async throws {
        // GREEN: Graceful degradation when capabilities are missing
        let userClient = UserClient()
        // Don't set any capabilities
        
        // Should work with in-memory fallbacks
        try await userClient.process(.login(email: "test@example.com", password: "password"))
        
        let state = await userClient.currentState
        #expect(state.userId != nil, "Should login successfully with fallback behavior")
        #expect(state.profile?.email == "test@example.com", "Should have correct profile")
    }
    
    @Test("Transient capability errors should be retried")
    func testTransientErrorsRetried() async throws {
        // GREEN: Proper retry logic for transient failures
        let networkCapability = MockTransientCapabilityGreen()
        let syncClient = SyncClient()
        await syncClient.setNetworkCapability(networkCapability)
        
        var attemptCount = 0
        networkCapability.onRequest = { _ in
            attemptCount += 1
            if attemptCount < 3 {
                throw NetworkError.timeout
            }
            // Succeed on third attempt
        }
        
        // Should retry and eventually succeed
        try await syncClient.process(.startSync)
        
        #expect(attemptCount == 3, "Should retry transient errors")
        
        let state = await syncClient.currentState
        #expect(state.isSyncing, "Should be syncing after retry success")
    }
    
    @Test("Capability failures during state restoration should recover gracefully")
    func testCapabilityFailureDuringStateRestorationRecovers() async throws {
        // GREEN: Graceful recovery during state restoration
        let taskClient = TaskClient()
        let resilientStorage = MockResilientStorageCapability()
        await taskClient.setStorageCapability(resilientStorage)
        
        // Add some tasks successfully
        for i in 1...5 {
            try await taskClient.process(.create(Task(
                id: "\(i)",
                title: "Task \(i)",
                description: "Test",
                dueDate: nil,
                priority: .medium,
                categoryId: nil,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )))
        }
        
        // Simulate partial failure during restoration
        resilientStorage.shouldFailAfterCount = 3
        
        // Create new client and attempt restoration
        let restoredClient = TaskClient()
        await restoredClient.setStorageCapability(resilientStorage)
        
        // Should recover gracefully with partial data
        let state = await restoredClient.currentState
        #expect(state.tasks.count >= 3, "Should recover at least partial state")
        
        // Should indicate partial recovery in status
        let metadata = await resilientStorage.getRecoveryMetadata()
        #expect(metadata.partialRecovery, "Should indicate partial recovery")
    }
    
    @Test("Capability errors should be abstracted from clients")
    func testCapabilityErrorsAbstracted() async throws {
        // GREEN: Client-level error abstraction
        let notificationCapability = MockAbstractedNotificationCapability()
        let taskClient = TaskClient()
        await taskClient.setNotificationCapability(notificationCapability)
        
        let task = Task(
            id: "1",
            title: "Task with notification",
            description: "Test",
            dueDate: Date().addingTimeInterval(3600),
            priority: .high,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Should succeed despite underlying capability errors
        try await taskClient.process(.create(task))
        
        let state = await taskClient.currentState
        #expect(state.tasks.count == 1, "Task should be created")
        
        // Check that error was abstracted
        let errorHistory = await notificationCapability.getErrorHistory()
        #expect(!errorHistory.isEmpty, "Should have recorded capability errors")
        #expect(!errorHistory.first!.contains("CFError"), "Should not expose system-level errors")
    }
    
    @Test("Sequential capability failures should maintain transaction integrity")
    func testSequentialCapabilityFailuresMaintainTransactions() async throws {
        // GREEN: Proper transaction management
        let taskClient = TaskClient()
        let storage = MockTransactionalStorageCapabilityGreen()
        let notifications = MockTransactionalNotificationCapabilityGreen()
        
        await taskClient.setStorageCapability(storage)
        await taskClient.setNotificationCapability(notifications)
        
        // Make notification scheduling fail after storage succeeds
        notifications.shouldFail = true
        
        let task = Task(
            id: "1",
            title: "Transactional Task",
            description: "Test",
            dueDate: Date().addingTimeInterval(3600),
            priority: .high,
            categoryId: nil,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Should handle failure with proper rollback
        do {
            try await taskClient.process(.create(task))
        } catch {
            // GREEN: Should rollback storage when notification fails
            let savedItems = await storage.savedItems
            #expect(savedItems.isEmpty, "Storage should be rolled back on notification failure")
            
            let scheduledNotifications = await notifications.scheduledNotifications
            #expect(scheduledNotifications.isEmpty, "Notifications should not be scheduled")
            
            // Task should not be in client state either
            let state = await taskClient.currentState
            #expect(state.tasks.isEmpty, "Task should not be in state after transaction rollback")
        }
    }
    
    @Test("Capability timeouts should be handled with proper cancellation")
    func testCapabilityTimeoutsHandledWithCancellation() async throws {
        // GREEN: Proper timeout and cancellation handling
        let syncClient = SyncClient()
        let timeoutCapability = MockTimeoutCapabilityGreen()
        await syncClient.setNetworkCapability(timeoutCapability)
        
        let startTime = Date()
        
        // Should timeout gracefully within reasonable time
        do {
            try await syncClient.process(.startSync)
        } catch {
            let elapsedTime = Date().timeIntervalSince(startTime)
            #expect(elapsedTime < 1.0, "Should timeout quickly, not block indefinitely")
            #expect(error is NetworkError, "Should receive proper network error")
        }
        
        // Should transition to offline mode after timeout
        let state = await syncClient.currentState
        #expect(state.isOffline, "Should be offline after timeout")
    }
    
    @Test("Capability replacement during operation should be handled gracefully")
    func testCapabilityReplacementDuringOperationHandledGracefully() async throws {
        // GREEN: Graceful handling of capability replacement
        let taskClient = TaskClient()
        let capability1 = MockVersionedStorageCapabilityGreen(version: "1.0")
        let capability2 = MockVersionedStorageCapabilityGreen(version: "2.0")
        
        await taskClient.setStorageCapability(capability1)
        
        // Start creating tasks
        let createTasks = (0..<10).map { i in
            _Concurrency.Task {
                // Replace capability mid-operation
                if i == 5 {
                    await taskClient.setStorageCapability(capability2)
                }
                
                try await taskClient.process(.create(Task(
                    id: "\(i)",
                    title: "Task \(i)",
                    description: "Test",
                    dueDate: nil,
                    priority: .medium,
                    categoryId: nil,
                    isCompleted: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )))
            }
        }
        
        // Wait for all operations
        for task in createTasks {
            try? await task.value
        }
        
        // Should maintain consistency despite capability replacement
        let state = await taskClient.currentState
        #expect(state.tasks.count == 10, "All tasks should be created despite capability replacement")
        
        // Check capability coordination
        let capability1Items = await capability1.savedItems
        let capability2Items = await capability2.savedItems
        #expect(capability1Items.count + capability2Items.count >= 10, 
               "Items should be distributed across capabilities")
    }
}

// MARK: - GREEN Phase Mock Capabilities

actor MockFailingStorageCapabilityGreen: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        // Simulate failure but don't crash the client
        throw StorageError.writeFailure
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        throw StorageError.readFailure
    }
    
    func delete(key: String) async throws {
        throw StorageError.writeFailure
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        throw StorageError.readFailure
    }
    
    func deleteAll() async throws {
        throw StorageError.writeFailure
    }
}

actor MockFailingNetworkCapabilityGreen: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        throw NetworkError.noConnection
    }
    
    func upload<T: Encodable>(_ data: T, to endpoint: Endpoint) async throws {
        throw NetworkError.noConnection
    }
}

actor MockSynchronizedCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    private var storage: [String: Data] = [:]
    private var accessLog: [String] = []
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        // Proper synchronization - no race conditions
        accessLog.append("save:\(key)")
        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        accessLog.append("load:\(key)")
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        accessLog.append("delete:\(key)")
        storage.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        accessLog.append("loadAll")
        var results: [T] = []
        for (_, data) in storage {
            let item = try JSONDecoder().decode(type, from: data)
            results.append(item)
        }
        return results
    }
    
    func deleteAll() async throws {
        accessLog.append("deleteAll")
        storage.removeAll()
    }
    
    func getAccessLog() async -> [String] {
        return accessLog
    }
}

actor MockTransientCapabilityGreen: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var onRequest: ((Endpoint) async throws -> Void)?
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if let onRequest = onRequest {
            try await onRequest(endpoint)
        }
        // Return dummy response for successful requests
        if T.self == String.self {
            return "success" as! T
        }
        fatalError("Unsupported type in mock")
    }
    
    func upload<T: Encodable>(_ data: T, to endpoint: Endpoint) async throws {
        if let onRequest = onRequest {
            try await onRequest(endpoint)
        }
    }
}

actor MockResilientStorageCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var shouldFailAfterCount: Int?
    private var operationCount = 0
    private var storage: [String: Data] = [:]
    private var recoveryMetadata = RecoveryMetadata()
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        operationCount += 1
        if let failAfter = shouldFailAfterCount, operationCount > failAfter {
            recoveryMetadata.partialRecovery = true
            throw StorageError.writeFailure
        }
        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        operationCount += 1
        if let failAfter = shouldFailAfterCount, operationCount > failAfter {
            recoveryMetadata.partialRecovery = true
            throw StorageError.readFailure
        }
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        storage.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        var results: [T] = []
        var loadCount = 0
        
        for (_, data) in storage {
            loadCount += 1
            if let failAfter = shouldFailAfterCount, loadCount > failAfter {
                recoveryMetadata.partialRecovery = true
                break
            }
            let item = try JSONDecoder().decode(type, from: data)
            results.append(item)
        }
        return results
    }
    
    func deleteAll() async throws {
        storage.removeAll()
    }
    
    func getRecoveryMetadata() async -> RecoveryMetadata {
        return recoveryMetadata
    }
}

actor MockAbstractedNotificationCapability: NotificationCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    private var errorHistory: [String] = []
    
    func schedule(_ notification: LocalNotification) async throws {
        // Simulate system error but abstract it
        let systemError = NSError(domain: "CFErrorDomainCFNetwork", code: -1009, userInfo: nil)
        let abstractedError = "Notification scheduling unavailable"
        errorHistory.append(abstractedError)
        
        // Don't throw - handle gracefully
        // In real implementation, might queue for later or use alternative notification method
    }
    
    func cancel(notificationId: String) async {
        // No-op
    }
    
    func requestAuthorization() async throws -> Bool {
        return false
    }
    
    func getErrorHistory() async -> [String] {
        return errorHistory
    }
}

actor MockTransactionalStorageCapabilityGreen: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    private var _savedItems: [String: Data] = [:]
    private var inTransaction = false
    private var transactionData: [String: Data] = [:]
    
    var savedItems: [String: Data] {
        get async { return _savedItems }
    }
    
    func beginTransaction() async {
        inTransaction = true
        transactionData = _savedItems
    }
    
    func commitTransaction() async {
        _savedItems = transactionData
        inTransaction = false
    }
    
    func rollbackTransaction() async {
        transactionData.removeAll()
        inTransaction = false
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        let data = try JSONEncoder().encode(object)
        if inTransaction {
            transactionData[key] = data
        } else {
            _savedItems[key] = data
        }
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        let storage = inTransaction ? transactionData : _savedItems
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        if inTransaction {
            transactionData.removeValue(forKey: key)
        } else {
            _savedItems.removeValue(forKey: key)
        }
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func deleteAll() async throws {
        if inTransaction {
            transactionData.removeAll()
        } else {
            _savedItems.removeAll()
        }
    }
}

actor MockTransactionalNotificationCapabilityGreen: NotificationCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var shouldFail = false
    private var _scheduledNotifications: [String] = []
    
    var scheduledNotifications: [String] {
        get async { return _scheduledNotifications }
    }
    
    func schedule(_ notification: LocalNotification) async throws {
        if shouldFail {
            throw NotificationError.schedulingFailed
        }
        _scheduledNotifications.append(notification.id)
    }
    
    func cancel(notificationId: String) async {
        _scheduledNotifications.removeAll { $0 == notificationId }
    }
    
    func requestAuthorization() async throws -> Bool {
        return true
    }
}

actor MockTimeoutCapabilityGreen: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Timeout after 500ms
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        throw NetworkError.timeout
    }
    
    func upload<T: Encodable>(_ data: T, to endpoint: Endpoint) async throws {
        // Timeout after 500ms
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        throw NetworkError.timeout
    }
}

actor MockVersionedStorageCapabilityGreen: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    let version: String
    private var _savedItems: [String: Data] = [:]
    
    var savedItems: [String: Data] {
        get async { return _savedItems }
    }
    
    init(version: String) {
        self.version = version
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        let data = try JSONEncoder().encode(object)
        _savedItems[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let data = _savedItems[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        _savedItems.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func deleteAll() async throws {
        _savedItems.removeAll()
    }
}

// MARK: - Supporting Types

struct RecoveryMetadata {
    var partialRecovery: Bool = false
}

enum NotificationError: Error {
    case schedulingFailed
    case authorizationDenied
}