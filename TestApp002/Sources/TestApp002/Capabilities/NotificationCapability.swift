import Foundation
import Axiom

// MARK: - Protocol Definition

protocol NotificationCapability: Capability {
    func schedule(_ notification: LocalNotification) async throws
    func cancel(notificationId: String) async
    func requestAuthorization() async throws -> Bool
}

// MARK: - Test Implementation

actor TestNotificationCapability: NotificationCapability {
    private var scheduledNotifications: [LocalNotification] = []
    private var authorizationStatus: NotificationAuthorizationStatus = .notDetermined
    private let maxNotifications = 64 // iOS limit
    private var _isAvailable = true
    private var notificationQueue: [String: Date] = [:] // Track scheduling times for performance
    
    // MARK: - Capability Protocol
    
    var isAvailable: Bool {
        return _isAvailable
    }
    
    func initialize() async throws {
        _isAvailable = true
        // In real implementation, would:
        // 1. Register notification categories
        // 2. Check current authorization status
        // 3. Clear expired notifications
        // Note: Don't cleanup on init for tests
    }
    
    func terminate() async {
        _isAvailable = false
        scheduledNotifications.removeAll()
        notificationQueue.removeAll()
    }
    
    // Mock control for testing
    func setMockAuthorizationStatus(_ status: NotificationAuthorizationStatus) {
        self.authorizationStatus = status
    }
    
    func getScheduledNotifications() -> [LocalNotification] {
        // Return sorted by scheduled date for consistent ordering
        return scheduledNotifications.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    // MARK: - Private Helpers
    
    private func cleanupExpiredNotifications() {
        let now = Date()
        scheduledNotifications.removeAll { $0.scheduledDate < now }
    }
    
    // MARK: - NotificationCapability Implementation
    
    func schedule(_ notification: LocalNotification) async throws {
        // Check capability availability
        guard _isAvailable else {
            throw NotificationError.schedulingFailed("Capability not available")
        }
        
        // Check authorization with automatic request if needed
        switch authorizationStatus {
        case .notDetermined:
            // Auto-request permission on first use
            let granted = try await requestAuthorization()
            guard granted else {
                throw NotificationError.permissionDenied
            }
        case .denied:
            throw NotificationError.permissionDenied
        case .authorized:
            break // Continue with scheduling
        }
        
        // Validate date (allow dates in the near future for testing)
        guard notification.scheduledDate >= Date().addingTimeInterval(-1) else {
            throw NotificationError.invalidDate
        }
        
        // Clean up expired notifications before checking limit
        // Note: Disabled for tests that use immediate scheduling
        // cleanupExpiredNotifications()
        
        // Check limit and remove oldest if needed (FIFO)
        if scheduledNotifications.count >= maxNotifications {
            // Remove the oldest (first) notification
            if let removed = scheduledNotifications.first {
                scheduledNotifications.removeFirst()
                notificationQueue.removeValue(forKey: removed.id)
            }
        }
        
        // Add new notification with performance tracking
        scheduledNotifications.append(notification)
        notificationQueue[notification.id] = Date() // Track when scheduled
    }
    
    func cancel(notificationId: String) async {
        scheduledNotifications.removeAll { $0.id == notificationId }
        notificationQueue.removeValue(forKey: notificationId)
    }
    
    func requestAuthorization() async throws -> Bool {
        // In test implementation, just return based on mock status
        switch authorizationStatus {
        case .notDetermined:
            // Simulate user granting permission
            authorizationStatus = .authorized
            return true
        case .authorized:
            return true
        case .denied:
            return false
        }
    }
    
    // MARK: - Additional Methods for Better UX
    
    func cancelAll() async {
        scheduledNotifications.removeAll()
        notificationQueue.removeAll()
    }
    
    func scheduleBatch(_ notifications: [LocalNotification]) async throws {
        // Batch scheduling for better performance
        for notification in notifications {
            try await schedule(notification)
        }
    }
    
    func getNotificationStatus() async -> (scheduled: Int, available: Int, isAuthorized: Bool) {
        let scheduled = scheduledNotifications.count
        let available = maxNotifications - scheduled
        let isAuthorized = authorizationStatus == .authorized
        return (scheduled, available, isAuthorized)
    }
}

// MARK: - Supporting Types

struct LocalNotification: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date
    let categoryIdentifier: String?
    let userInfo: [String: String] // Changed from Any to String for Sendable
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        scheduledDate: Date,
        categoryIdentifier: String? = nil,
        userInfo: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.categoryIdentifier = categoryIdentifier
        self.userInfo = userInfo
    }
    
    static func == (lhs: LocalNotification, rhs: LocalNotification) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.body == rhs.body &&
        lhs.scheduledDate == rhs.scheduledDate &&
        lhs.categoryIdentifier == rhs.categoryIdentifier &&
        lhs.userInfo == rhs.userInfo
    }
}

enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case schedulingFailed(String)
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission denied"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .invalidDate:
            return "Notification date must be in the future"
        }
    }
}