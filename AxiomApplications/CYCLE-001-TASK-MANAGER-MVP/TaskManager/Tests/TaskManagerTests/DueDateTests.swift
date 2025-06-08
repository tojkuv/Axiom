import XCTest
import Foundation
@testable import TaskManager
import Axiom

final class DueDateTests: XCTestCase {
    
    // MARK: - RED Phase: Due Date Model Tests
    
    func testTaskDueDateAssignment() async {
        // Test that tasks can have due dates assigned
        // Framework insight: How does State protocol handle optional Date properties?
        let dueDate = Date().addingTimeInterval(86400) // Tomorrow
        let task = TaskItem(
            title: "Task with due date",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: dueDate
        )
        
        XCTAssertNotNil(task.dueDate)
        XCTAssertEqual(task.dueDate, dueDate)
    }
    
    func testDueDateSerialization() async {
        // Test date serialization for State protocol
        // Framework insight: Does Axiom properly handle Date in Codable?
        // Use a date without fractional seconds for consistent serialization
        let dueDate = Date(timeIntervalSince1970: round(Date().timeIntervalSince1970))
        let task = TaskItem(
            title: "Serialization test",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: dueDate
        )
        
        // Encode and decode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(task)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedTask = try! decoder.decode(TaskItem.self, from: data)
        
        if let taskDate = task.dueDate, let decodedDate = decodedTask.dueDate {
            XCTAssertEqual(taskDate.timeIntervalSince1970, 
                          decodedDate.timeIntervalSince1970, 
                          accuracy: 0.001)
        } else {
            XCTAssertEqual(task.dueDate, decodedTask.dueDate)
        }
    }
    
    func testOverdueCalculation() async {
        // Test computed property for overdue status
        let yesterday = Date().addingTimeInterval(-86400)
        let tomorrow = Date().addingTimeInterval(86400)
        
        let overdueTask = TaskItem(
            title: "Overdue task",
            description: nil,
            categoryId: nil,
            priority: .high,
            dueDate: yesterday
        )
        
        let futureTask = TaskItem(
            title: "Future task",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: tomorrow
        )
        
        let noDateTask = TaskItem(
            title: "No date task",
            description: nil,
            categoryId: nil,
            priority: .low
        )
        
        XCTAssertTrue(overdueTask.isOverdue)
        XCTAssertFalse(futureTask.isOverdue)
        XCTAssertFalse(noDateTask.isOverdue)
        
        // Completed tasks should not be overdue
        let completedOverdue = TaskItem(
            id: overdueTask.id,
            title: overdueTask.title,
            description: overdueTask.description,
            categoryId: overdueTask.categoryId,
            priority: overdueTask.priority,
            isCompleted: true,
            createdAt: overdueTask.createdAt,
            updatedAt: overdueTask.updatedAt,
            dueDate: overdueTask.dueDate
        )
        XCTAssertFalse(completedOverdue.isOverdue)
    }
    
    func testDueDateTimeZoneHandling() async {
        // Test timezone edge cases
        // Framework insight: How does the framework handle timezone-aware dates?
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.timeZone = TimeZone(identifier: "America/New_York")
        
        let eastCoastDate = calendar.date(from: components)!
        
        let task = TaskItem(
            title: "Timezone test",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: eastCoastDate
        )
        
        // Change timezone context
        let utcTimeZone = TimeZone(identifier: "UTC")!
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = utcTimeZone
        
        // Due date should be consistent across timezones
        XCTAssertNotNil(task.dueDate)
        XCTAssertEqual(task.dueDate?.timeIntervalSince1970, eastCoastDate.timeIntervalSince1970)
    }
    
    func testDueDateFormatting() async {
        // Test date display formatting
        let date = Date()
        let task = TaskItem(
            title: "Format test",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: date
        )
        
        // Should have formatting helpers
        XCTAssertFalse(task.formattedDueDate.isEmpty)
        XCTAssertFalse(task.relativeDueDate.isEmpty)
        
        // Test relative formatting
        let tomorrow = Date().addingTimeInterval(86400)
        let tomorrowTask = TaskItem(
            title: "Tomorrow task",
            description: nil,
            categoryId: nil,
            priority: .medium,
            dueDate: tomorrow
        )
        
        // Relative date formatter output varies by locale and system settings
        // Just verify it's not empty and contains some expected patterns
        XCTAssertFalse(tomorrowTask.relativeDueDate.isEmpty)
        let relativeString = tomorrowTask.relativeDueDate.lowercased()
        XCTAssertTrue(
            relativeString.contains("tomorrow") || 
            relativeString.contains("1 day") ||
            relativeString.contains("24 hour") ||
            relativeString.contains("in ") // Common prefix for future dates
        )
    }
    
    func testDueDateFiltering() async {
        // Test filtering by due date ranges
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400) // 24 hours ago
        let today = now.addingTimeInterval(3600) // 1 hour from now (not overdue)
        let tomorrow = now.addingTimeInterval(86400)
        let nextWeek = now.addingTimeInterval(86400 * 7)
        
        let tasks = [
            TaskItem(title: "Overdue", dueDate: yesterday),
            TaskItem(title: "Due today", dueDate: today),
            TaskItem(title: "Due tomorrow", dueDate: tomorrow),
            TaskItem(title: "Due next week", dueDate: nextWeek),
            TaskItem(title: "No due date", dueDate: nil)
        ]
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Filter for overdue
        await client.send(.setDueDateFilter(.overdue))
        var state = await client.state
        XCTAssertEqual(state.filteredTasks.count, 1)
        XCTAssertEqual(state.filteredTasks.first?.title, "Overdue")
        
        // Filter for due today
        await client.send(.setDueDateFilter(.today))
        state = await client.state
        XCTAssertEqual(state.filteredTasks.count, 1)
        XCTAssertEqual(state.filteredTasks.first?.title, "Due today")
        
        // Filter for this week
        await client.send(.setDueDateFilter(.thisWeek))
        state = await client.state
        XCTAssertTrue(state.filteredTasks.count >= 2) // Today and tomorrow at minimum
    }
    
    func testDueDateSorting() async {
        // Test integration with existing sort functionality
        let dates = [
            Date().addingTimeInterval(86400 * 3), // 3 days
            Date().addingTimeInterval(86400),     // 1 day
            Date().addingTimeInterval(86400 * 7), // 1 week
            Date().addingTimeInterval(-86400),    // Yesterday
            nil                                   // No date
        ]
        
        let tasks = dates.enumerated().map { index, date in
            TaskItem(title: "Task \(index)", dueDate: date)
        }
        
        let client = await TaskTestHelpers.makeClient(with: tasks)
        
        // Sort by due date ascending
        await client.send(.setSortOrder(.dueDate))
        await client.send(.setSortDirection(.ascending))
        
        let state = await client.state
        let sorted = state.filteredTasks
        
        // Tasks with dates should come before tasks without
        let lastTaskWithDate = sorted.lastIndex { $0.dueDate != nil } ?? -1
        let firstTaskWithoutDate = sorted.firstIndex { $0.dueDate == nil } ?? sorted.count
        XCTAssertLessThan(lastTaskWithDate, firstTaskWithoutDate)
        
        // Verify date order for tasks with dates
        let tasksWithDates = sorted.filter { $0.dueDate != nil }
        for i in 0..<(tasksWithDates.count - 1) {
            if let date1 = tasksWithDates[i].dueDate,
               let date2 = tasksWithDates[i + 1].dueDate {
                XCTAssertLessThanOrEqual(date1, date2)
            }
        }
    }
}