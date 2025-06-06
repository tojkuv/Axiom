import Testing
import Foundation
@testable import TestApp002Core

@Suite("Permission Error Handling - GREEN Phase")
struct PermissionErrorHandlingTestsGreen {
    
    // MARK: - File System Permission Tests
    
    @Test("Storage should use in-memory fallback when file system permissions are denied")
    func testStorageUsesInMemoryFallbackWhenPermissionsDenied() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .denied)
        
        let storageCapability = GracefulStorageCapability()
        await storageCapability.setPermissionManager(permissionManager)
        
        let task = TestApp002Core.Task(
            id: "test-task",
            title: "Test Task",
            description: "Test Description",
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Should succeed using in-memory storage
        try await storageCapability.save(task, key: "test-task")
        
        // Should be able to load from in-memory storage
        let loaded = try await storageCapability.load(TestApp002Core.Task.self, key: "test-task")
        #expect(loaded != nil, "Should load from in-memory fallback")
        #expect(loaded?.id == task.id, "Should load correct task")
        
        let fallbackUsed = await storageCapability.inMemoryFallbackUsed
        #expect(fallbackUsed == true, "Should use in-memory fallback")
    }
    
    @Test("Storage should maintain data consistency with in-memory fallback")
    func testStorageConsistencyWithInMemoryFallback() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .denied)
        
        let storageCapability = GracefulStorageCapability()
        await storageCapability.setPermissionManager(permissionManager)
        
        // Save multiple items
        for i in 1...5 {
            let task = TestApp002Core.Task(
                id: "task-\(i)",
                title: "Task \(i)",
                description: "Description \(i)",
                priority: .medium,
                isCompleted: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await storageCapability.save(task, key: "task-\(i)")
        }
        
        // Verify all can be loaded
        for i in 1...5 {
            let loaded = try await storageCapability.load(TestApp002Core.Task.self, key: "task-\(i)")
            #expect(loaded?.id == "task-\(i)", "Should maintain consistency for task \(i)")
        }
    }
    
    @Test("Storage should warn user about limited functionality")
    func testStorageWarnsAboutLimitedFunctionality() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .denied)
        
        let storageCapability = GracefulStorageCapability()
        await storageCapability.setPermissionManager(permissionManager)
        
        let task = TestApp002Core.Task(
            id: "test-task",
            title: "Test Task",
            description: "Test Description",
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await storageCapability.save(task, key: "test-task")
        
        let warningShown = await storageCapability.permissionWarningShown
        #expect(warningShown == true, "Should show warning about limited functionality")
    }
    
    // MARK: - Network Permission Tests
    
    @Test("Network should use cached data when permissions are denied")
    func testNetworkUsesCacheWhenPermissionsDenied() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.network, status: .denied)
        
        let networkCapability = GracefulNetworkCapability()
        await networkCapability.setPermissionManager(permissionManager)
        
        // Pre-populate cache
        let cachedTasks = [
            TestApp002Core.Task(id: "1", title: "Cached Task 1", description: "", priority: .medium, isCompleted: false, createdAt: Date(), updatedAt: Date()),
            TestApp002Core.Task(id: "2", title: "Cached Task 2", description: "", priority: .high, isCompleted: true, createdAt: Date(), updatedAt: Date())
        ]
        await networkCapability.setCachedResponse(cachedTasks, for: "https://api.example.com/tasks")
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Should return cached data
        let tasks: [TestApp002Core.Task] = try await networkCapability.request(endpoint)
        #expect(tasks.count == 2, "Should return cached tasks")
        #expect(tasks[0].id == "1", "Should return correct cached data")
        
        let cacheUsed = await networkCapability.cacheUsed
        #expect(cacheUsed == true, "Should use cache when permissions denied")
    }
    
    @Test("Network should queue requests for later when permissions are denied")
    func testNetworkQueuesRequestsWhenPermissionsDenied() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.network, status: .denied)
        
        let networkCapability = GracefulNetworkCapability()
        await networkCapability.setPermissionManager(permissionManager)
        
        let endpoint = Endpoint(url: URL(string: "https://api.example.com/tasks")!)
        
        // Make multiple requests
        for _ in 0..<3 {
            do {
                let _: [TestApp002Core.Task] = try await networkCapability.request(endpoint)
            } catch NetworkError.offline {
                // Expected when no cache available
            }
        }
        
        let queuedCount = await networkCapability.queuedRequestCount
        #expect(queuedCount == 3, "Should queue requests when permissions denied")
    }
    
    @Test("Network should indicate offline mode to user")
    func testNetworkIndicatesOfflineMode() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.network, status: .denied)
        
        let networkCapability = GracefulNetworkCapability()
        await networkCapability.setPermissionManager(permissionManager)
        
        let isOffline = await networkCapability.isInOfflineMode
        #expect(isOffline == true, "Should indicate offline mode when permissions denied")
        
        let offlineReason = await networkCapability.offlineReason
        #expect(offlineReason == .permissionDenied, "Should indicate permission denied as reason")
    }
    
    // MARK: - Notification Permission Tests
    
    @Test("Notifications should gracefully handle permission denial")
    func testNotificationsHandlePermissionDenialGracefully() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let notificationCapability = GracefulNotificationCapability()
        await notificationCapability.setPermissionManager(permissionManager)
        
        let notification = LocalNotification(
            id: "test-notification",
            title: "Task Reminder",
            body: "Don't forget your task!",
            scheduledDate: Date().addingTimeInterval(3600)
        )
        
        // Should not throw when permissions denied
        try await notificationCapability.schedule(notification)
        
        // Should track that notification was attempted
        let attemptedCount = await notificationCapability.attemptedNotificationCount
        #expect(attemptedCount == 1, "Should track attempted notifications")
        
        // But should not actually schedule
        let isScheduled = await notificationCapability.isScheduled(notification.id)
        #expect(isScheduled == false, "Should not actually schedule when permissions denied")
    }
    
    @Test("Should provide alternative reminder options when notifications denied")
    func testProvidesAlternativeReminderOptions() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let notificationCapability = GracefulNotificationCapability()
        await notificationCapability.setPermissionManager(permissionManager)
        
        let notification = LocalNotification(
            id: "test-notification",
            title: "Task Reminder",
            body: "Don't forget your task!",
            scheduledDate: Date().addingTimeInterval(3600)
        )
        
        try await notificationCapability.schedule(notification)
        
        let alternatives = await notificationCapability.getAlternativeReminderOptions()
        #expect(alternatives.count > 0, "Should provide alternative reminder options")
        #expect(alternatives.contains(.inAppReminder), "Should suggest in-app reminders")
        #expect(alternatives.contains(.calendarIntegration), "Should suggest calendar integration")
    }
    
    @Test("Should store notification preferences even when permissions denied")
    func testStoresPreferencesRegardlessOfPermissions() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let notificationCapability = GracefulNotificationCapability()
        await notificationCapability.setPermissionManager(permissionManager)
        
        let preferences = NotificationPreferences(
            enabled: true,
            soundEnabled: true,
            badgeEnabled: true,
            alertStyle: .banner
        )
        
        try await notificationCapability.updatePreferences(preferences)
        
        let storedPreferences = await notificationCapability.getStoredPreferences()
        #expect(storedPreferences != nil, "Should store preferences even when permissions denied")
        #expect(storedPreferences?.enabled == true, "Should preserve preference values")
    }
    
    // MARK: - Cross-Permission Tests
    
    @Test("Multiple permission denials should coordinate graceful degradation")
    func testCoordinatedGracefulDegradation() async throws {
        let permissionManager = MockPermissionManager()
        await permissionManager.setPermission(.fileSystem, status: .denied)
        await permissionManager.setPermission(.network, status: .denied)
        await permissionManager.setPermission(.notifications, status: .denied)
        
        let storageCapability = GracefulStorageCapability()
        await storageCapability.setPermissionManager(permissionManager)
        
        let networkCapability = GracefulNetworkCapability()
        await networkCapability.setPermissionManager(permissionManager)
        
        let notificationCapability = GracefulNotificationCapability()
        await notificationCapability.setPermissionManager(permissionManager)
        
        // All should work with graceful degradation
        var successCount = 0
        
        // Storage should use in-memory
        do {
            try await storageCapability.save(TestApp002Core.Task(id: "1", title: "Test", description: "", priority: .medium, isCompleted: false, createdAt: Date(), updatedAt: Date()), key: "test")
            successCount += 1
        } catch {
            // Should not throw
        }
        
        // Network should indicate offline
        let isOffline = await networkCapability.isInOfflineMode
        if isOffline {
            successCount += 1
        }
        
        // Notifications should track attempts
        try await notificationCapability.schedule(LocalNotification(id: "1", title: "Test", body: "Test", scheduledDate: Date()))
        let attempted = await notificationCapability.attemptedNotificationCount
        if attempted > 0 {
            successCount += 1
        }
        
        #expect(successCount == 3, "All capabilities should handle permissions gracefully")
        
        // Check coordination
        let storageAwareOfOthers = await storageCapability.isAwareOfOtherPermissionDenials
        let networkAwareOfOthers = await networkCapability.isAwareOfOtherPermissionDenials
        let notificationAwareOfOthers = await notificationCapability.isAwareOfOtherPermissionDenials
        
        #expect(storageAwareOfOthers == true, "Storage should be aware of other permission denials")
        #expect(networkAwareOfOthers == true, "Network should be aware of other permission denials")
        #expect(notificationAwareOfOthers == true, "Notification should be aware of other permission denials")
    }
}

// MARK: - Graceful Mock Implementations

actor GracefulStorageCapability: StorageCapability {
    private var permissionManager: MockPermissionManager?
    private var data: [String: Data] = [:]
    private var inMemoryData: [String: Data] = [:]
    private(set) var inMemoryFallbackUsed = false
    private(set) var permissionWarningShown = false
    private(set) var isAwareOfOtherPermissionDenials = false
    private var _isAvailable = true
    
    var isAvailable: Bool {
        return _isAvailable
    }
    
    func initialize() async throws {
        _isAvailable = true
    }
    
    func terminate() async {
        _isAvailable = false
    }
    
    func setPermissionManager(_ manager: MockPermissionManager) {
        self.permissionManager = manager
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
        guard let manager = permissionManager else {
            throw PermissionStorageError.unknown
        }
        
        if await manager.checkPermission(.fileSystem) == .denied {
            // Use in-memory fallback
            inMemoryFallbackUsed = true
            permissionWarningShown = true
            
            // Check other permissions
            let networkDenied = await manager.checkPermission(.network) == .denied
            let notificationsDenied = await manager.checkPermission(.notifications) == .denied
            if networkDenied || notificationsDenied {
                isAwareOfOtherPermissionDenials = true
            }
            
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(object)
            inMemoryData[key] = encoded
            return
        }
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(object)
        data[key] = encoded
    }
    
    func load<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let manager = permissionManager else {
            throw PermissionStorageError.unknown
        }
        
        if await manager.checkPermission(.fileSystem) == .denied {
            // Use in-memory fallback
            inMemoryFallbackUsed = true
            
            guard let encoded = inMemoryData[key] else {
                return nil
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: encoded)
        }
        
        guard let encoded = data[key] else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: encoded)
    }
    
    func delete(key: String) async throws {
        guard let manager = permissionManager else {
            throw PermissionStorageError.unknown
        }
        
        if await manager.checkPermission(.fileSystem) == .denied {
            inMemoryData.removeValue(forKey: key)
            return
        }
        
        data.removeValue(forKey: key)
    }
}

actor GracefulNetworkCapability: NetworkCapability {
    private var permissionManager: MockPermissionManager?
    private var cache: [String: Any] = [:]
    private var queuedRequests: [QueuedRequest] = []
    private(set) var cacheUsed = false
    private(set) var isAwareOfOtherPermissionDenials = false
    private var _isAvailable = true
    
    var isAvailable: Bool {
        return _isAvailable
    }
    
    var queuedRequestCount: Int {
        return queuedRequests.count
    }
    
    var isInOfflineMode: Bool {
        get async {
            guard let manager = permissionManager else { return false }
            return await manager.checkPermission(.network) == .denied
        }
    }
    
    var offlineReason: OfflineReason {
        get async {
            guard let manager = permissionManager else { return .unknown }
            if await manager.checkPermission(.network) == .denied {
                return .permissionDenied
            }
            return .none
        }
    }
    
    func initialize() async throws {
        _isAvailable = true
    }
    
    func terminate() async {
        _isAvailable = false
    }
    
    func setPermissionManager(_ manager: MockPermissionManager) {
        self.permissionManager = manager
    }
    
    func setCachedResponse<T>(_ response: T, for url: String) {
        cache[url] = response
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        guard let manager = permissionManager else {
            throw PermissionNetworkError.unknown
        }
        
        if await manager.checkPermission(.network) == .denied {
            // Check other permissions
            let fileSystemDenied = await manager.checkPermission(.fileSystem) == .denied
            let notificationsDenied = await manager.checkPermission(.notifications) == .denied
            if fileSystemDenied || notificationsDenied {
                isAwareOfOtherPermissionDenials = true
            }
            
            // Try to use cache
            if let cached = cache[endpoint.url.absoluteString] as? T {
                cacheUsed = true
                return cached
            }
            
            // Queue the request
            let queuedRequest = QueuedRequest(
                endpoint: endpoint,
                timestamp: Date(),
                priority: .normal
            )
            queuedRequests.append(queuedRequest)
            
            throw NetworkError.offline
        }
        
        // Simulate network request
        throw PermissionNetworkError.noData
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        guard let manager = permissionManager else {
            throw PermissionNetworkError.unknown
        }
        
        if await manager.checkPermission(.network) == .denied {
            // Queue the upload
            let queuedRequest = QueuedRequest(
                endpoint: endpoint,
                timestamp: Date(),
                priority: .normal,
                uploadData: data
            )
            queuedRequests.append(queuedRequest)
            
            throw NetworkError.offline
        }
        
        // Simulate upload
    }
    
    private struct QueuedRequest {
        let endpoint: Endpoint
        let timestamp: Date
        let priority: PermissionRequestPriority
        let uploadData: Any?
        
        init(endpoint: Endpoint, timestamp: Date, priority: PermissionRequestPriority, uploadData: Any? = nil) {
            self.endpoint = endpoint
            self.timestamp = timestamp
            self.priority = priority
            self.uploadData = uploadData
        }
    }
}

actor GracefulNotificationCapability: NotificationCapability {
    private var permissionManager: MockPermissionManager?
    private var scheduledNotifications: Set<String> = []
    private(set) var attemptedNotificationCount = 0
    private var preferences: NotificationPreferences?
    private(set) var isAwareOfOtherPermissionDenials = false
    private var _isAvailable = true
    
    var isAvailable: Bool {
        return _isAvailable
    }
    
    func initialize() async throws {
        _isAvailable = true
    }
    
    func terminate() async {
        _isAvailable = false
    }
    
    func setPermissionManager(_ manager: MockPermissionManager) {
        self.permissionManager = manager
    }
    
    func schedule(_ notification: LocalNotification) async throws {
        guard let manager = permissionManager else {
            return
        }
        
        attemptedNotificationCount += 1
        
        if await manager.checkPermission(.notifications) == .denied {
            // Check other permissions
            let fileSystemDenied = await manager.checkPermission(.fileSystem) == .denied
            let networkDenied = await manager.checkPermission(.network) == .denied
            if fileSystemDenied || networkDenied {
                isAwareOfOtherPermissionDenials = true
            }
            
            // Don't actually schedule, but don't throw either
            return
        }
        
        scheduledNotifications.insert(notification.id)
    }
    
    func cancel(notificationId: String) async {
        scheduledNotifications.remove(notificationId)
    }
    
    func requestAuthorization() async throws -> Bool {
        return false
    }
    
    func isScheduled(_ notificationId: String) async -> Bool {
        return scheduledNotifications.contains(notificationId)
    }
    
    func updatePreferences(_ preferences: NotificationPreferences) async throws {
        // Store preferences regardless of permission status
        self.preferences = preferences
    }
    
    func getStoredPreferences() async -> NotificationPreferences? {
        return preferences
    }
    
    func getAlternativeReminderOptions() async -> Set<AlternativeReminder> {
        return [.inAppReminder, .calendarIntegration, .emailReminder]
    }
}

// MARK: - Supporting Types

enum OfflineReason {
    case none
    case permissionDenied
    case noConnection
    case unknown
}

enum AlternativeReminder {
    case inAppReminder
    case calendarIntegration
    case emailReminder
}

enum PermissionRequestPriority {
    case high
    case normal
    case low
}