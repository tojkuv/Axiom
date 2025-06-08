import XCTest
import Foundation
@testable import TaskManager
import Axiom

final class OverdueStateTests: XCTestCase {
    
    // MARK: - RED Phase: Overdue State Management Tests
    
    func testOverdueStateCalculation() async {
        // Test real-time overdue status calculation
        // Framework insight: Performance of computed properties with dates?
        let now = Date()
        let tasks = [
            TaskItem(title: "Past due", dueDate: now.addingTimeInterval(-3600)),
            TaskItem(title: "Due now", dueDate: now),
            TaskItem(title: "Due soon", dueDate: now.addingTimeInterval(1800)),
            TaskItem(title: "Future", dueDate: now.addingTimeInterval(86400)),
            TaskItem(title: "No date", dueDate: nil)
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        let state = await client.state
        
        // Get overdue tasks
        let overdueTasks = state.tasks.filter { $0.isOverdue }
        XCTAssertEqual(overdueTasks.count, 1)
        XCTAssertEqual(overdueTasks.first?.title, "Past due")
        
        // Tasks due now should not be overdue (grace period)
        let dueNowTask = state.tasks.first { $0.title == "Due now" }
        XCTAssertFalse(dueNowTask?.isOverdue ?? true)
    }
    
    func testOverdueStateUpdates() async {
        // Test background updates for overdue state changes
        // Framework insight: How to handle time-based state updates?
        
        // Create a task that's already past the grace period
        let task = TaskItem(
            title: "Already overdue",
            dueDate: Date().addingTimeInterval(-120) // 2 minutes ago (past grace period)
        )
        
        let client = await TaskTestHelpers.makeClient(with: [task])
        let overdueMonitor = OverdueStateMonitor(client: client)
        
        // Check for overdue tasks
        await overdueMonitor.checkForOverdueTasks()
        
        // Should detect overdue task
        let overdueCount = await overdueMonitor.overdueTaskCount
        XCTAssertEqual(overdueCount, 1)
    }
    
    func testOverduePerformance() async {
        // Test performance with many tasks
        // Framework insight: Computed property performance at scale?
        let tasks = (0..<1000).map { i in
            let dueDate = i % 2 == 0 ? 
                Date().addingTimeInterval(-Double(i + 2) * 60) : // Past (start at -120 seconds to avoid grace period)
                Date().addingTimeInterval(Double(i) * 60)    // Future
            
            return TaskItem(
                title: "Task \(i)",
                dueDate: dueDate
            )
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        let startTime = Date()
        let state = await client.state
        let overdueTasks = state.tasks.filter { $0.isOverdue }
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(overdueTasks.count, 500)
        XCTAssertLessThan(duration * 1000, 10) // Should be < 10ms for 1000 tasks
    }
    
    func testOverdueWithTimezones() async {
        // Test overdue calculation across timezones
        // Framework insight: Timezone-aware date comparisons?
        let calendar = Calendar.current
        let now = Date()
        
        // Create task due at midnight EST
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/New_York")
        
        let midnightEST = calendar.date(from: components)!
        let task = TaskItem(
            title: "Midnight deadline",
            dueDate: midnightEST
        )
        
        // Check overdue status from different timezone
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        // Should use consistent comparison regardless of display timezone
        let isOverdue = task.isOverdue
        let expectedOverdue = midnightEST < Date()
        XCTAssertEqual(isOverdue, expectedOverdue)
    }
    
    func testOverdueNotificationTriggers() async {
        // Test notification triggers for overdue tasks
        let tasks = [
            TaskItem(title: "Just overdue", dueDate: Date().addingTimeInterval(-90)),
            TaskItem(title: "Long overdue", dueDate: Date().addingTimeInterval(-86400))
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Add and complete a task
        await client.send(.addTask(
            title: "Completed overdue",
            description: nil,
            dueDate: Date().addingTimeInterval(-3600)
        ))
        
        let state = await client.state
        if let completedTask = state.tasks.first(where: { $0.title == "Completed overdue" }) {
            await client.send(.updateTask(
                id: completedTask.id,
                title: nil,
                description: nil,
                categoryId: nil,
                priority: nil,
                dueDate: nil,
                isCompleted: true
            ))
        }
        
        let overdueMonitor = OverdueStateMonitor(client: client)
        
        // Check which tasks need overdue notifications
        let needsNotification = await overdueMonitor.tasksNeedingOverdueNotification()
        
        XCTAssertEqual(needsNotification.count, 2) // Not the completed one
        XCTAssertTrue(needsNotification.contains { $0.title == "Just overdue" })
        XCTAssertTrue(needsNotification.contains { $0.title == "Long overdue" })
    }
    
    func testOverdueVisualState() async {
        // Test visual state indicators for overdue tasks
        let task = TaskItem(
            title: "Overdue task",
            priority: .high,
            dueDate: Date().addingTimeInterval(-3600)
        )
        
        // Should have visual properties
        XCTAssertTrue(task.isOverdue)
        XCTAssertEqual(task.overdueLevel, .high) // High priority + overdue
        XCTAssertEqual(task.overdueSeverity, .mild) // Exactly 1 hour overdue (accounting for grace period)
        XCTAssertTrue(task.shouldShowOverdueIndicator)
    }
    
    func testOverdueFiltering() async {
        // Test filtering specifically for overdue tasks
        // Create tasks without the completed one first
        let tasks = [
            TaskItem(title: "Overdue 1", dueDate: Date().addingTimeInterval(-3600)),
            TaskItem(title: "Overdue 2", dueDate: Date().addingTimeInterval(-7200)),
            TaskItem(title: "Due soon", dueDate: Date().addingTimeInterval(1800)),
            TaskItem(title: "No date", dueDate: nil)
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Add the completed task
        await client.send(.addTask(
            title: "Completed",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: Date().addingTimeInterval(-3600)
        ))
        
        // Get the task and mark it as completed
        let currentState = await client.state
        if let completedTask = currentState.tasks.first(where: { $0.title == "Completed" }) {
            await client.send(.updateTask(
                id: completedTask.id,
                title: nil,
                description: nil,
                categoryId: nil,
                priority: nil,
                dueDate: nil,
                isCompleted: true
            ))
        }
        
        // Apply overdue filter
        await client.send(.setDueDateFilter(.overdue))
        let state = await client.state
        
        XCTAssertEqual(state.filteredTasks.count, 2)
        XCTAssertTrue(state.filteredTasks.allSatisfy { $0.isOverdue })
        XCTAssertFalse(state.filteredTasks.contains { $0.isCompleted })
    }
}

// Mock overdue monitor for testing
// Framework insight: Pattern for background monitoring?
actor OverdueStateMonitor {
    private let client: TaskClient
    private var monitoringTask: Task<Void, Never>?
    private(set) var overdueTaskCount: Int = 0
    
    init(client: TaskClient) {
        self.client = client
    }
    
    func startMonitoring() async {
        monitoringTask = Task {
            while !Task.isCancelled {
                await checkForOverdueTasks()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every minute
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    func checkForOverdueTasks() async {
        let state = await client.state
        let overdueTasks = state.tasks.filter { $0.isOverdue }
        overdueTaskCount = overdueTasks.count
        
        // In real implementation, would trigger state updates
        // for newly overdue tasks
    }
    
    func tasksNeedingOverdueNotification() async -> [TaskItem] {
        let state = await client.state
        return state.tasks.filter { task in
            task.isOverdue && !task.isCompleted
        }
    }
}

