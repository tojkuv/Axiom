import Testing
@testable import TestApp002Core
import Foundation

// RED Phase: Tests expect capability integration failures
@Suite("Capability Integration - RED Phase")
struct CapabilityIntegrationTests {
    
    @Test("Capability failures should propagate to clients without error boundaries")
    func testCapabilityFailuresPropagateUnchecked() async throws {
        // RED: Expect that capability failures crash clients
        let storageCapability = MockFailingStorageCapability()
        let networkCapability = MockFailingNetworkCapability()
        
        let taskClient = TaskClient()
        await taskClient.setStorageCapability(storageCapability)
        
        // This should fail catastrophically without error boundaries
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
            #expect(false, "Should have failed without error boundaries")
        } catch {
            // RED: We expect unhandled errors to propagate
            #expect(error is StorageError || error is NetworkError)
        }
    }
    
    @Test("Multiple capability failures should cascade without coordination")
    func testMultipleCapabilityFailuresCascade() async throws {
        // RED: Expect cascading failures without proper coordination
        let syncClient = SyncClient()
        let storageCapability = MockFailingStorageCapability()
        let networkCapability = MockFailingNetworkCapability()
        
        await syncClient.setStorageCapability(storageCapability)
        await syncClient.setNetworkCapability(networkCapability)
        
        // Start sync - should fail with cascading errors
        do {
            try await syncClient.process(.startSync)
            #expect(false, "Should have failed with cascading errors")
        } catch {
            // RED: Expect uncoordinated failure handling
            #expect(error is SyncError || error is StorageError || error is NetworkError)
        }
    }
    
    @Test("Concurrent capability access should cause race conditions")
    func testConcurrentCapabilityAccessCausesRaces() async throws {
        // RED: Expect race conditions without proper synchronization
        let taskClient = TaskClient()
        let sharedCapability = MockSharedCapability()
        await taskClient.setStorageCapability(sharedCapability)
        
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
        
        // RED: Expect some operations to fail due to race conditions
        var failures = 0
        for task in tasks {
            do {
                try await task.value
            } catch {
                failures += 1
            }
        }
        
        #expect(failures > 0, "Should have race condition failures")
    }
    
    @Test("Capability unavailability should crash dependent clients")
    func testCapabilityUnavailabilityCrashesClients() async throws {
        // RED: Expect crashes when capabilities are nil
        let userClient = UserClient()
        // Don't set any capabilities
        
        do {
            try await userClient.process(.login(email: "test@example.com", password: "password"))
            #expect(false, "Should crash without capabilities")
        } catch {
            // RED: Expect force unwrap crash or similar
            #expect(true, "Expected crash due to missing capability")
        }
    }
    
    @Test("Transient capability errors should not be retried")
    func testTransientErrorsNotRetried() async throws {
        // RED: Expect no retry logic for transient failures
        let networkCapability = MockTransientFailureCapability()
        let syncClient = SyncClient()
        await syncClient.setNetworkCapability(networkCapability)
        
        var attemptCount = 0
        networkCapability.onRequest = { _ in
            attemptCount += 1
            throw NetworkError.connectionLost
        }
        
        do {
            try await syncClient.process(.startSync)
            #expect(false, "Should fail on first attempt")
        } catch {
            #expect(attemptCount == 1, "Should not retry transient errors")
        }
    }
    
    @Test("Capability failures during state restoration should corrupt state")
    func testCapabilityFailureDuringStateRestorationCorruptsState() async throws {
        // RED: Expect state corruption without proper error handling
        let taskClient = TaskClient()
        let failingStorage = MockPartialFailureStorageCapability()
        await taskClient.setStorageCapability(failingStorage)
        
        // Add some tasks
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
        failingStorage.shouldFailAfterCount = 3
        
        // Try to restore state - should get corrupted
        let restoredClient = TaskClient()
        await restoredClient.setStorageCapability(failingStorage)
        
        // RED: Expect incomplete/corrupted state
        let state = await restoredClient.currentState
        #expect(state.tasks.count < 5, "State should be corrupted")
    }
    
    @Test("Capability errors should leak implementation details")
    func testCapabilityErrorsLeakImplementationDetails() async throws {
        // RED: Expect raw errors without abstraction
        let notificationCapability = MockFailingNotificationCapability()
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
        
        do {
            try await taskClient.process(.create(task))
            #expect(false, "Should fail with implementation details")
        } catch {
            // RED: Expect raw system errors
            let errorDescription = String(describing: error)
            #expect(errorDescription.contains("CFError") || errorDescription.contains("NSError"), 
                   "Should leak implementation details")
        }
    }
    
    @Test("Sequential capability failures should not maintain transaction integrity")
    func testSequentialCapabilityFailuresBreakTransactions() async throws {
        // RED: Expect broken transaction integrity
        let taskClient = TaskClient()
        let storage = MockTransactionalStorageCapability()
        let notifications = MockTransactionalNotificationCapability()
        
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
        
        do {
            try await taskClient.process(.create(task))
            #expect(false, "Should fail during notification scheduling")
        } catch {
            // RED: Storage should have succeeded but notification failed
            // This breaks transaction integrity
            #expect(storage.savedItems.count == 1, "Storage succeeded despite notification failure")
            #expect(notifications.scheduledNotifications.isEmpty, "Notification failed as expected")
        }
    }
    
    @Test("Capability timeouts should block client operations indefinitely")
    func testCapabilityTimeoutsBlockClientsIndefinitely() async throws {
        // RED: Expect indefinite blocking without timeout handling
        let syncClient = SyncClient()
        let blockingCapability = MockBlockingNetworkCapability()
        await syncClient.setNetworkCapability(blockingCapability)
        
        let startTime = Date()
        
        // This should block indefinitely
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await syncClient.process(.startSync)
                } catch {
                    // Should timeout but won't in RED phase
                }
            }
            
            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                group.cancelAll()
            }
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        #expect(elapsedTime >= 2.0, "Should block for at least 2 seconds without timeout")
    }
    
    @Test("Capability replacement during operation should cause inconsistencies")
    func testCapabilityReplacementDuringOperationCausesInconsistencies() async throws {
        // RED: Expect inconsistencies when capabilities are replaced mid-operation
        let taskClient = TaskClient()
        let capability1 = MockVersionedStorageCapability(version: "1.0")
        let capability2 = MockVersionedStorageCapability(version: "2.0")
        
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
        
        // RED: Expect inconsistent state between capabilities
        #expect(capability1.savedItems.count > 0, "Some items saved to first capability")
        #expect(capability2.savedItems.count > 0, "Some items saved to second capability")
        #expect(capability1.savedItems.count + capability2.savedItems.count < 10, 
               "Total saved items should be less due to inconsistencies")
    }
}

// MARK: - Mock Capabilities for RED Phase

actor MockFailingStorageCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func save<T: Codable>(_ object: T, key: String) async throws {
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

actor MockFailingNetworkCapability: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        throw NetworkError.serverError(500)
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        throw NetworkError.serverError(500)
    }
}

actor MockFailingNotificationCapability: NotificationCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func schedule(_ notification: LocalNotification) async throws {
        throw NSError(domain: "CFErrorDomainCFNetwork", code: -1009, userInfo: nil)
    }
    
    func cancel(notificationId: String) async {
        // No-op
    }
    
    func requestAuthorization() async throws -> Bool {
        return false
    }
}

actor MockSharedCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    private var storage: [String: Data] = [:]
    private var accessCount = 0
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        accessCount += 1
        // Simulate race condition
        if accessCount % 3 == 0 {
            throw StorageError.concurrentAccessViolation
        }
        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        storage.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func deleteAll() async throws {
        storage.removeAll()
    }
}

actor MockTransientFailureCapability: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var onRequest: ((Endpoint) async throws -> Void)?
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        if let onRequest = onRequest {
            try await onRequest(endpoint)
        }
        throw NetworkError.noConnection
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        throw NetworkError.noConnection
    }
}

actor MockPartialFailureStorageCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var shouldFailAfterCount: Int?
    private var saveCount = 0
    private var storage: [String: Data] = [:]
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        saveCount += 1
        if let failAfter = shouldFailAfterCount, saveCount > failAfter {
            throw StorageError.writeFailure
        }
        let data = try JSONEncoder().encode(object)
        storage[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
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
                throw StorageError.readFailure
            }
            let item = try JSONDecoder().decode(type, from: data)
            results.append(item)
        }
        return results
    }
    
    func deleteAll() async throws {
        storage.removeAll()
    }
}

actor MockTransactionalStorageCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var savedItems: [String: Data] = [:]
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        let data = try JSONEncoder().encode(object)
        savedItems[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let data = savedItems[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        savedItems.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func deleteAll() async throws {
        savedItems.removeAll()
    }
}

actor MockTransactionalNotificationCapability: NotificationCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    var shouldFail = false
    var scheduledNotifications: [String] = []
    
    func schedule(_ notification: LocalNotification) async throws {
        if shouldFail {
            throw NotificationError.schedulingFailed
        }
        scheduledNotifications.append(notification.id)
    }
    
    func cancel(notificationId: String) async {
        scheduledNotifications.removeAll { $0 == notificationId }
    }
    
    func requestAuthorization() async throws -> Bool {
        return true
    }
}

actor MockBlockingNetworkCapability: NetworkCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        // Block indefinitely
        try await _Concurrency.Task.sleep(nanoseconds: UInt64.max)
        throw NetworkError.timeout
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        // Block indefinitely
        try await _Concurrency.Task.sleep(nanoseconds: UInt64.max)
    }
}

actor MockVersionedStorageCapability: StorageCapability {
    var isAvailable: Bool { return true }
    
    func initialize() async throws {}
    func terminate() async {}
    
    let version: String
    var savedItems: [String: Data] = [:]
    
    init(version: String) {
        self.version = version
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        // Simulate version-specific behavior
        if version == "2.0" {
            try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        }
        let data = try JSONEncoder().encode(object)
        savedItems[key] = data
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let data = savedItems[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(key: String) async throws {
        savedItems.removeValue(forKey: key)
    }
    
    func loadAll<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func deleteAll() async throws {
        savedItems.removeAll()
    }
}

// MARK: - Supporting Types

enum NotificationError: Error {
    case schedulingFailed
    case authorizationDenied
}