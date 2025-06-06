import Foundation
@testable import TestApp002Core

// Type alias to avoid naming conflict with our Task domain model
typealias SwiftTask = _Concurrency.Task

// MARK: - Mock Capabilities for Testing

/// In-memory storage capability for testing
actor InMemoryStorageCapability: StorageCapability {
    private var storage: [String: Data] = [:]
    
    var isAvailable: Bool { true }
    
    func initialize() async throws {
        // No-op for in-memory storage
    }
    
    func terminate() async {
        storage.removeAll()
    }
    
    func save<T: Codable>(_ object: T, key: String) async throws {
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
        for (_, data) in storage {
            if let object = try? JSONDecoder().decode(type, from: data) {
                results.append(object)
            }
        }
        return results
    }
    
    func deleteAll() async throws {
        storage.removeAll()
    }
}

/// Mock network capability for testing
actor MockNetworkCapability: NetworkCapability {
    enum MockError: Error {
        case notImplemented
    }
    
    var isAvailable: Bool { true }
    
    func initialize() async throws {
        // No-op for mock
    }
    
    func terminate() async {
        // No-op for mock
    }
    
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        throw MockError.notImplemented
    }
    
    func upload<T: Encodable & Sendable>(_ data: T, to endpoint: Endpoint) async throws {
        throw MockError.notImplemented
    }
}

/// Mock notification capability for testing
actor MockNotificationCapability: NotificationCapability {
    private var _scheduledNotifications: [String: LocalNotification] = [:]
    private var _cancelledNotificationIds: [String] = []
    private var authorizationGranted = true
    
    var isAvailable: Bool { true }
    
    func initialize() async throws {
        // No-op for mock
    }
    
    func terminate() async {
        _scheduledNotifications.removeAll()
        _cancelledNotificationIds.removeAll()
    }
    
    func schedule(_ notification: LocalNotification) async throws {
        _scheduledNotifications[notification.id] = notification
    }
    
    func cancel(notificationId: String) async {
        _scheduledNotifications.removeValue(forKey: notificationId)
        _cancelledNotificationIds.append(notificationId)
    }
    
    func requestAuthorization() async throws -> Bool {
        return authorizationGranted
    }
    
    // Test helpers
    func setAuthorizationGranted(_ granted: Bool) {
        authorizationGranted = granted
    }
    
    var scheduledNotifications: [LocalNotification] {
        Array(_scheduledNotifications.values)
    }
    
    var cancelledNotificationIds: [String] {
        _cancelledNotificationIds
    }
}

/// Test storage capability that uses the in-memory implementation
typealias TestStorageCapability = InMemoryStorageCapability
typealias MemoryStorageCapability = InMemoryStorageCapability