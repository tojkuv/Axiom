import XCTest
import Axiom
@testable import TestApp002Core

final class NotificationCapabilityTests: XCTestCase {
    private var capability: TestNotificationCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        capability = TestNotificationCapability()
    }
    
    override func tearDown() async throws {
        capability = nil
        try await super.tearDown()
    }
    
    // MARK: - Notification Scheduling Tests
    
    func testScheduleLocalNotification() async throws {
        // Set authorization first
        await capability.setMockAuthorizationStatus(.authorized)
        
        let notification = LocalNotification(
            id: "test-1",
            title: "Test Notification",
            body: "This is a test",
            scheduledDate: Date().addingTimeInterval(60) // 1 minute from now
        )
        
        // Schedule notification
        try await capability.schedule(notification)
        
        // Verify it was scheduled
        let scheduled = await capability.getScheduledNotifications()
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertEqual(scheduled.first?.id, "test-1")
    }
    
    func testCancelNotification() async throws {
        // Set authorization first
        await capability.setMockAuthorizationStatus(.authorized)
        
        let notification = LocalNotification(
            id: "test-cancel",
            title: "To Cancel",
            body: "Will be cancelled",
            scheduledDate: Date().addingTimeInterval(60)
        )
        
        // Schedule then cancel
        try await capability.schedule(notification)
        await capability.cancel(notificationId: "test-cancel")
        
        // Verify cancelled
        let scheduled = await capability.getScheduledNotifications()
        XCTAssertTrue(scheduled.isEmpty)
    }
    
    func testRequestAuthorizationGranted() async throws {
        // Set mock permission to granted
        await capability.setMockAuthorizationStatus(.authorized)
        
        let authorized = try await capability.requestAuthorization()
        XCTAssertTrue(authorized)
    }
    
    func testRequestAuthorizationDenied() async throws {
        // Set mock permission to denied
        await capability.setMockAuthorizationStatus(.denied)
        
        let authorized = try await capability.requestAuthorization()
        XCTAssertFalse(authorized)
    }
    
    func testScheduleWithoutPermission() async throws {
        // Set permission to denied
        await capability.setMockAuthorizationStatus(.denied)
        
        let notification = LocalNotification(
            id: "no-permission",
            title: "Unauthorized",
            body: "Should fail",
            scheduledDate: Date().addingTimeInterval(60)
        )
        
        // Should throw permission error
        do {
            try await capability.schedule(notification)
            XCTFail("Should have thrown permission error")
        } catch NotificationError.permissionDenied {
            // Expected
        }
    }
    
    func testMaximumNotificationLimit() async throws {
        await capability.setMockAuthorizationStatus(.authorized)
        
        // Schedule 64 notifications (iOS limit)
        for i in 0..<64 {
            let notification = LocalNotification(
                id: "notification-\(i)",
                title: "Notification \(i)",
                body: "Body \(i)",
                scheduledDate: Date().addingTimeInterval(Double(i * 60))
            )
            try await capability.schedule(notification)
        }
        
        // Verify count
        let scheduled = await capability.getScheduledNotifications()
        XCTAssertEqual(scheduled.count, 64)
        
        // Schedule one more (65th)
        let extraNotification = LocalNotification(
            id: "notification-64",
            title: "Extra",
            body: "Should replace oldest",
            scheduledDate: Date().addingTimeInterval(3600)
        )
        try await capability.schedule(extraNotification)
        
        // Should still be 64 (oldest replaced)
        let updatedScheduled = await capability.getScheduledNotifications()
        XCTAssertEqual(updatedScheduled.count, 64)
        XCTAssertTrue(updatedScheduled.contains { $0.id == "notification-64" })
        XCTAssertFalse(updatedScheduled.contains { $0.id == "notification-0" }) // Oldest removed
    }
    
    func testNotificationWithCategory() async throws {
        await capability.setMockAuthorizationStatus(.authorized)
        
        let notification = LocalNotification(
            id: "category-test",
            title: "Task Reminder",
            body: "Complete your task",
            scheduledDate: Date().addingTimeInterval(60),
            categoryIdentifier: "TASK_REMINDER",
            userInfo: ["taskId": "task-123"]
        )
        
        try await capability.schedule(notification)
        
        let scheduled = await capability.getScheduledNotifications()
        XCTAssertEqual(scheduled.first?.categoryIdentifier, "TASK_REMINDER")
        XCTAssertEqual(scheduled.first?.userInfo["taskId"], "task-123")
    }
    
    func testBatchScheduling() async throws {
        await capability.setMockAuthorizationStatus(.authorized)
        
        let notifications = (0..<10).map { i in
            LocalNotification(
                id: "batch-\(i)",
                title: "Batch \(i)",
                body: "Batch notification",
                scheduledDate: Date().addingTimeInterval(Double(i * 60))
            )
        }
        
        // Measure batch scheduling performance
        let start = Date()
        for notification in notifications {
            try await capability.schedule(notification)
        }
        let elapsed = Date().timeIntervalSince(start)
        
        // Should complete within reasonable time
        XCTAssertLessThan(elapsed, 1.0) // Less than 1 second for 10 notifications
        
        let scheduled = await capability.getScheduledNotifications()
        XCTAssertEqual(scheduled.count, 10)
    }
}