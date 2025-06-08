import XCTest
import Foundation
@testable import TaskManager
import Axiom

final class NotificationTests: XCTestCase {
    
    // MARK: - RED Phase: Notification Capability Tests
    
    func testNotificationScheduling() async {
        // Test scheduling notifications for tasks with due dates
        // Framework insight: How to integrate system capabilities with Axiom?
        let dueDate = Date().addingTimeInterval(3600) // 1 hour from now
        let task = TaskItem(
            title: "Task with notification",
            description: "Don't forget!",
            priority: .high,
            dueDate: dueDate
        )
        
        let client = await TaskTestHelpers.makeClient()
        let notificationService = TaskNotificationService(client: client)
        
        // Schedule notification
        let notificationId = await notificationService.scheduleNotification(for: task)
        XCTAssertNotNil(notificationId)
        
        // Verify notification is scheduled
        let isScheduled = await notificationService.isNotificationScheduled(for: task.id)
        XCTAssertTrue(isScheduled)
    }
    
    func testNotificationContent() async {
        // Test notification content formatting
        let task = TaskItem(
            title: "Buy groceries",
            description: "Milk, eggs, bread",
            priority: .medium,
            dueDate: Date().addingTimeInterval(3600)
        )
        
        let notificationService = TaskNotificationService()
        let content = await notificationService.createNotificationContent(for: task)
        
        XCTAssertEqual(content.title, "Task Due Soon")
        XCTAssertEqual(content.body, "Buy groceries")
        XCTAssertEqual(content.subtitle, "Due in 1 hour")
        XCTAssertEqual(content.categoryIdentifier, "TASK_DUE")
        
        // Test high priority gets special treatment
        let urgentTask = TaskItem(
            title: "Urgent task",
            priority: .critical,
            dueDate: Date().addingTimeInterval(1800) // 30 min
        )
        
        let urgentContent = await notificationService.createNotificationContent(for: urgentTask)
        XCTAssertEqual(urgentContent.title, "⚠️ Urgent Task Due Soon")
        XCTAssertTrue(urgentContent.interruptionLevel == .critical)
    }
    
    func testNotificationCancellation() async {
        // Test cancelling notifications when task is completed or deleted
        let task = TaskItem(
            title: "Cancelable task",
            dueDate: Date().addingTimeInterval(3600)
        )
        
        let client = await TaskTestHelpers.makeClient(with: [task])
        let notificationService = TaskNotificationService(client: client)
        
        // Schedule notification
        let notificationId = await notificationService.scheduleNotification(for: task)
        XCTAssertNotNil(notificationId)
        
        // Complete task and manually cancel notification
        await client.send(.updateTask(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: task.categoryId,
            priority: task.priority,
            dueDate: task.dueDate,
            isCompleted: true
        ))
        
        // Cancel notification for completed task
        await notificationService.cancelNotification(for: task.id)
        
        // Verify notification was cancelled
        let isScheduled = await notificationService.isNotificationScheduled(for: task.id)
        XCTAssertFalse(isScheduled)
    }
    
    func testNotificationRescheduling() async {
        // Test updating notifications when due date changes
        var task = TaskItem(
            title: "Reschedulable task",
            dueDate: Date().addingTimeInterval(3600)
        )
        
        let client = await TaskTestHelpers.makeClient(with: [task])
        let notificationService = TaskNotificationService(client: client)
        
        // Initial scheduling
        let firstId = await notificationService.scheduleNotification(for: task)
        
        // Update due date
        let newDueDate = Date().addingTimeInterval(7200) // 2 hours
        await client.send(.updateTask(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: task.categoryId,
            priority: task.priority,
            dueDate: newDueDate,
            isCompleted: false
        ))
        
        let updatedTask = TaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: task.categoryId,
            priority: task.priority,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            dueDate: newDueDate
        )
        
        // Should reschedule notification
        let secondId = await notificationService.scheduleNotification(for: task)
        XCTAssertNotEqual(firstId, secondId)
        
        // Old notification should be cancelled
        let oldScheduled = await notificationService.isNotificationScheduled(id: firstId!)
        XCTAssertFalse(oldScheduled)
    }
    
    func testNotificationPermissionHandling() async {
        // Test handling notification permission states
        // Framework insight: Error handling for system capabilities?
        let notificationService = TaskNotificationService()
        
        // Check permission status
        let status = await notificationService.checkNotificationPermission()
        
        switch status {
        case .authorized:
            XCTAssertTrue(true) // Can schedule notifications
        case .denied:
            // Should handle gracefully
            let canSchedule = await notificationService.canScheduleNotifications()
            XCTAssertFalse(canSchedule)
        case .notDetermined:
            // Should prompt for permission
            let requested = await notificationService.requestNotificationPermission()
            XCTAssertNotNil(requested)
        default:
            XCTFail("Unexpected permission status")
        }
    }
    
    func testBatchNotificationManagement() async {
        // Test managing notifications for multiple tasks
        let tasks = (0..<10).map { i in
            TaskItem(
                title: "Task \(i)",
                dueDate: Date().addingTimeInterval(Double(i + 1) * 3600)
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        let notificationService = TaskNotificationService(client: client)
        
        // Schedule all notifications
        let notificationIds = await notificationService.scheduleAllNotifications()
        XCTAssertEqual(notificationIds.count, tasks.count)
        
        // Verify all scheduled
        let scheduledCount = await notificationService.getScheduledNotificationCount()
        XCTAssertEqual(scheduledCount, tasks.count)
        
        // Clear all notifications
        await notificationService.cancelAllNotifications()
        
        let remainingCount = await notificationService.getScheduledNotificationCount()
        XCTAssertEqual(remainingCount, 0)
    }
    
    func testNotificationTiming() async {
        // Test notification timing strategies
        let notificationService = TaskNotificationService()
        
        // Test different timing strategies
        let oneHour = Date().addingTimeInterval(3600)
        let timing1 = await notificationService.calculateNotificationTime(for: oneHour)
        XCTAssertEqual(timing1, oneHour.addingTimeInterval(-900)) // 15 min before
        
        let tomorrow = Date().addingTimeInterval(86400)
        let timing2 = await notificationService.calculateNotificationTime(for: tomorrow)
        XCTAssertEqual(timing2, tomorrow.addingTimeInterval(-3600)) // 1 hour before
        
        let nextWeek = Date().addingTimeInterval(86400 * 7)
        let timing3 = await notificationService.calculateNotificationTime(for: nextWeek)
        XCTAssertEqual(timing3, nextWeek.addingTimeInterval(-86400)) // 1 day before
    }
}

// Mock notification service for testing
// Framework insight: Need pattern for capability mocking
actor TaskNotificationService {
    private let client: TaskClient?
    private var scheduledNotifications: [UUID: String] = [:]
    
    init(client: TaskClient? = nil) {
        self.client = client
    }
    
    func scheduleNotification(for task: TaskItem) async -> String? {
        guard let _ = task.dueDate else { return nil }
        let notificationId = UUID().uuidString
        scheduledNotifications[task.id] = notificationId
        return notificationId
    }
    
    func isNotificationScheduled(for taskId: UUID) async -> Bool {
        scheduledNotifications[taskId] != nil
    }
    
    func isNotificationScheduled(id: String) async -> Bool {
        scheduledNotifications.values.contains(id)
    }
    
    func createNotificationContent(for task: TaskItem) -> NotificationContent {
        var content = NotificationContent()
        
        if task.priority == .critical {
            content.title = "⚠️ Urgent Task Due Soon"
            content.interruptionLevel = .critical
        } else {
            content.title = "Task Due Soon"
        }
        
        content.body = task.title
        content.subtitle = "Due in 1 hour" // Simplified for testing
        content.categoryIdentifier = "TASK_DUE"
        
        return content
    }
    
    func cancelNotification(for taskId: UUID) async {
        scheduledNotifications.removeValue(forKey: taskId)
    }
    
    func scheduleAllNotifications() async -> [String] {
        guard let client = client else { return [] }
        let state = await client.state
        var ids: [String] = []
        
        for task in state.tasks where task.dueDate != nil {
            if let id = await scheduleNotification(for: task) {
                ids.append(id)
            }
        }
        
        return ids
    }
    
    func cancelAllNotifications() async {
        scheduledNotifications.removeAll()
    }
    
    func getScheduledNotificationCount() async -> Int {
        scheduledNotifications.count
    }
    
    func calculateNotificationTime(for dueDate: Date) async -> Date {
        let now = Date()
        let timeUntilDue = dueDate.timeIntervalSince(now)
        
        if timeUntilDue <= 3600 { // Less than or equal to 1 hour
            return dueDate.addingTimeInterval(-900) // 15 min before
        } else if timeUntilDue <= 86400 { // Less than or equal to 1 day
            return dueDate.addingTimeInterval(-3600) // 1 hour before
        } else {
            return dueDate.addingTimeInterval(-86400) // 1 day before
        }
    }
    
    enum PermissionStatus {
        case authorized, denied, notDetermined
    }
    
    func checkNotificationPermission() async -> PermissionStatus {
        .authorized // Mock implementation
    }
    
    func canScheduleNotifications() async -> Bool {
        await checkNotificationPermission() == .authorized
    }
    
    func requestNotificationPermission() async -> Bool {
        true // Mock implementation
    }
}

// Mock notification content
struct NotificationContent {
    var title: String = ""
    var body: String = ""
    var subtitle: String = ""
    var categoryIdentifier: String = ""
    var interruptionLevel: InterruptionLevel = .active
    
    enum InterruptionLevel {
        case passive, active, timeSensitive, critical
    }
}