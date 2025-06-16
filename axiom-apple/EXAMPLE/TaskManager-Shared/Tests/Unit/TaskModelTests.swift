import XCTest
@testable import TaskManager_Shared
import Foundation

// MARK: - Task Model Tests

/// Unit tests for Task model and related types
final class TaskModelTests: XCTestCase {
    
    // MARK: - Task Creation Tests
    
    func testTaskInitialization() {
        let now = Date()
        let dueDate = Date().addingTimeInterval(86400) // Tomorrow
        
        let task = Task(
            title: "Test Task",
            taskDescription: "This is a test task",
            priority: .high,
            category: .work,
            dueDate: dueDate,
            notes: "Test notes"
        )
        
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.taskDescription, "This is a test task")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.category, .work)
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.notes, "Test notes")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertTrue(task.createdAt.timeIntervalSince(now) < 1.0) // Created recently
    }
    
    func testTaskWithMinimalData() {
        let task = Task(
            title: "Minimal Task",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        XCTAssertEqual(task.title, "Minimal Task")
        XCTAssertEqual(task.taskDescription, "")
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.category, .personal)
        XCTAssertNil(task.dueDate)
        XCTAssertEqual(task.notes, "")
        XCTAssertFalse(task.isCompleted)
    }
    
    // MARK: - Task Mutation Tests
    
    func testTaskTitleMutation() {
        let originalTask = Task(
            title: "Original Title",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let updatedTask = originalTask.withTitle("New Title")
        
        XCTAssertEqual(originalTask.title, "Original Title") // Original unchanged
        XCTAssertEqual(updatedTask.title, "New Title")
        XCTAssertEqual(updatedTask.id, originalTask.id) // ID preserved
        XCTAssertEqual(updatedTask.taskDescription, originalTask.taskDescription)
        XCTAssertEqual(updatedTask.priority, originalTask.priority)
        XCTAssertEqual(updatedTask.category, originalTask.category)
        XCTAssertEqual(updatedTask.createdAt, originalTask.createdAt) // Creation time preserved
    }
    
    func testTaskDescriptionMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Original Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let updatedTask = originalTask.withDescription("New Description")
        
        XCTAssertEqual(originalTask.taskDescription, "Original Description")
        XCTAssertEqual(updatedTask.taskDescription, "New Description")
        XCTAssertEqual(updatedTask.id, originalTask.id)
        XCTAssertEqual(updatedTask.title, originalTask.title)
    }
    
    func testTaskPriorityMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Description",
            priority: .low,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let updatedTask = originalTask.withPriority(.high)
        
        XCTAssertEqual(originalTask.priority, .low)
        XCTAssertEqual(updatedTask.priority, .high)
        XCTAssertEqual(updatedTask.id, originalTask.id)
    }
    
    func testTaskCategoryMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let updatedTask = originalTask.withCategory(.work)
        
        XCTAssertEqual(originalTask.category, .personal)
        XCTAssertEqual(updatedTask.category, .work)
        XCTAssertEqual(updatedTask.id, originalTask.id)
    }
    
    func testTaskDueDateMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let dueDate = Date().addingTimeInterval(86400)
        let updatedTask = originalTask.withDueDate(dueDate)
        
        XCTAssertNil(originalTask.dueDate)
        XCTAssertEqual(updatedTask.dueDate, dueDate)
        XCTAssertEqual(updatedTask.id, originalTask.id)
        
        // Test removing due date
        let taskWithoutDueDate = updatedTask.withDueDate(nil)
        XCTAssertNil(taskWithoutDueDate.dueDate)
    }
    
    func testTaskNotesMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let updatedTask = originalTask.withNotes("Important notes")
        
        XCTAssertEqual(originalTask.notes, "")
        XCTAssertEqual(updatedTask.notes, "Important notes")
        XCTAssertEqual(updatedTask.id, originalTask.id)
    }
    
    func testTaskCompletionMutation() {
        let originalTask = Task(
            title: "Title",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let completedTask = originalTask.withCompletion(true)
        
        XCTAssertFalse(originalTask.isCompleted)
        XCTAssertNil(originalTask.completedAt)
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertNotNil(completedTask.completedAt)
        XCTAssertEqual(completedTask.id, originalTask.id)
        
        // Test uncompleting task
        let uncompletedTask = completedTask.withCompletion(false)
        XCTAssertFalse(uncompletedTask.isCompleted)
        XCTAssertNil(uncompletedTask.completedAt)
    }
    
    // MARK: - Task Computed Properties Tests
    
    func testTaskIsOverdue() {
        let now = Date()
        
        // Task without due date should not be overdue
        let taskWithoutDueDate = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        XCTAssertFalse(taskWithoutDueDate.isOverdue)
        
        // Completed task should not be overdue
        let completedTask = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: now.addingTimeInterval(-86400), // Yesterday
            notes: ""
        ).withCompletion(true)
        XCTAssertFalse(completedTask.isOverdue)
        
        // Future due date should not be overdue
        let futureTask = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: now.addingTimeInterval(86400), // Tomorrow
            notes: ""
        )
        XCTAssertFalse(futureTask.isOverdue)
        
        // Past due date should be overdue
        let overdueTask = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: now.addingTimeInterval(-86400), // Yesterday
            notes: ""
        )
        XCTAssertTrue(overdueTask.isOverdue)
    }
    
    func testTaskHasNotes() {
        let taskWithoutNotes = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        XCTAssertFalse(taskWithoutNotes.hasNotes)
        
        let taskWithWhitespaceNotes = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: "   \n  \t  "
        )
        XCTAssertFalse(taskWithWhitespaceNotes.hasNotes)
        
        let taskWithNotes = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: "Important notes"
        )
        XCTAssertTrue(taskWithNotes.hasNotes)
    }
    
    func testTaskHasReminder() {
        // Currently always false since reminder functionality is not implemented
        let task = Task(
            title: "Title",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: Date(),
            notes: ""
        )
        XCTAssertFalse(task.hasReminder)
    }
    
    // MARK: - Task Filter Tests
    
    func testTaskFilterMatching() {
        let now = Date()
        
        let completedTask = Task(
            title: "Completed",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        ).withCompletion(true)
        
        let pendingTask = Task(
            title: "Pending",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let overdueTask = Task(
            title: "Overdue",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: now.addingTimeInterval(-86400), // Yesterday
            notes: ""
        )
        
        // Test all filter
        XCTAssertTrue(Task.Filter.all.matches(completedTask))
        XCTAssertTrue(Task.Filter.all.matches(pendingTask))
        XCTAssertTrue(Task.Filter.all.matches(overdueTask))
        
        // Test completed filter
        XCTAssertTrue(Task.Filter.completed.matches(completedTask))
        XCTAssertFalse(Task.Filter.completed.matches(pendingTask))
        XCTAssertFalse(Task.Filter.completed.matches(overdueTask))
        
        // Test pending filter
        XCTAssertFalse(Task.Filter.pending.matches(completedTask))
        XCTAssertTrue(Task.Filter.pending.matches(pendingTask))
        XCTAssertTrue(Task.Filter.pending.matches(overdueTask)) // Overdue is also pending
        
        // Test overdue filter
        XCTAssertFalse(Task.Filter.overdue.matches(completedTask))
        XCTAssertFalse(Task.Filter.overdue.matches(pendingTask))
        XCTAssertTrue(Task.Filter.overdue.matches(overdueTask))
    }
    
    // MARK: - Task Sort Order Tests
    
    func testTaskSortOrderComparison() {
        let now = Date()
        
        let taskA = Task(
            title: "A Task",
            taskDescription: "",
            priority: .high,
            category: .work,
            dueDate: now.addingTimeInterval(86400), // Tomorrow
            notes: ""
        )
        
        let taskB = Task(
            title: "B Task",
            taskDescription: "",
            priority: .low,
            category: .personal,
            dueDate: now.addingTimeInterval(172800), // Day after tomorrow
            notes: ""
        )
        
        // Title sorting
        XCTAssertTrue(Task.SortOrder.title.compare(taskA, taskB, ascending: true))
        XCTAssertFalse(Task.SortOrder.title.compare(taskA, taskB, ascending: false))
        
        // Priority sorting (high > medium > low)
        XCTAssertFalse(Task.SortOrder.priority.compare(taskA, taskB, ascending: true)) // High should come after low in ascending
        XCTAssertTrue(Task.SortOrder.priority.compare(taskA, taskB, ascending: false)) // High should come before low in descending
        
        // Due date sorting
        XCTAssertTrue(Task.SortOrder.dueDate.compare(taskA, taskB, ascending: true)) // Earlier date first
        XCTAssertFalse(Task.SortOrder.dueDate.compare(taskA, taskB, ascending: false)) // Later date first
        
        // Created date sorting
        // Since both tasks were created around the same time, we can't reliably test the order
        // But we can test that the comparison doesn't crash
        let _ = Task.SortOrder.createdDate.compare(taskA, taskB, ascending: true)
        let _ = Task.SortOrder.createdDate.compare(taskA, taskB, ascending: false)
    }
    
    // MARK: - Codable Tests
    
    func testTaskCodable() throws {
        let originalTask = Task(
            title: "Codable Test",
            taskDescription: "Testing JSON encoding/decoding",
            priority: .high,
            category: .work,
            dueDate: Date(),
            notes: "Test notes"
        ).withCompletion(true)
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalTask)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedTask = try decoder.decode(Task.self, from: jsonData)
        
        // Verify all properties are preserved
        XCTAssertEqual(decodedTask.id, originalTask.id)
        XCTAssertEqual(decodedTask.title, originalTask.title)
        XCTAssertEqual(decodedTask.taskDescription, originalTask.taskDescription)
        XCTAssertEqual(decodedTask.priority, originalTask.priority)
        XCTAssertEqual(decodedTask.category, originalTask.category)
        XCTAssertEqual(decodedTask.dueDate?.timeIntervalSince1970, originalTask.dueDate?.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(decodedTask.notes, originalTask.notes)
        XCTAssertEqual(decodedTask.isCompleted, originalTask.isCompleted)
        XCTAssertEqual(decodedTask.completedAt?.timeIntervalSince1970, originalTask.completedAt?.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(decodedTask.createdAt.timeIntervalSince1970, originalTask.createdAt.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Hashable and Equatable Tests
    
    func testTaskEquality() {
        let task1 = Task(
            title: "Test Task",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        let task2 = Task(
            title: "Test Task",
            taskDescription: "Description",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        // Different instances with different IDs should not be equal
        XCTAssertNotEqual(task1, task2)
        XCTAssertNotEqual(task1.hashValue, task2.hashValue)
        
        // Same task should be equal to itself
        XCTAssertEqual(task1, task1)
        XCTAssertEqual(task1.hashValue, task1.hashValue)
        
        // Mutated task with same ID should be equal
        let mutatedTask = task1.withTitle("New Title")
        XCTAssertEqual(task1.id, mutatedTask.id)
        XCTAssertEqual(task1, mutatedTask) // Equality based on ID
    }
    
    // MARK: - Edge Cases Tests
    
    func testTaskWithExtremeDates() {
        let distantPast = Date.distantPast
        let distantFuture = Date.distantFuture
        
        let taskWithDistantPast = Task(
            title: "Past Task",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: distantPast,
            notes: ""
        )
        
        let taskWithDistantFuture = Task(
            title: "Future Task",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: distantFuture,
            notes: ""
        )
        
        XCTAssertTrue(taskWithDistantPast.isOverdue)
        XCTAssertFalse(taskWithDistantFuture.isOverdue)
    }
    
    func testTaskWithEmptyStrings() {
        let task = Task(
            title: "",
            taskDescription: "",
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: ""
        )
        
        XCTAssertEqual(task.title, "")
        XCTAssertEqual(task.taskDescription, "")
        XCTAssertEqual(task.notes, "")
        XCTAssertFalse(task.hasNotes)
    }
    
    func testTaskWithVeryLongStrings() {
        let longString = String(repeating: "A", count: 10000)
        
        let task = Task(
            title: longString,
            taskDescription: longString,
            priority: .medium,
            category: .personal,
            dueDate: nil,
            notes: longString
        )
        
        XCTAssertEqual(task.title.count, 10000)
        XCTAssertEqual(task.taskDescription.count, 10000)
        XCTAssertEqual(task.notes.count, 10000)
        XCTAssertTrue(task.hasNotes)
    }
}

// MARK: - Priority Tests

final class PriorityTests: XCTestCase {
    
    func testPriorityDisplayNames() {
        XCTAssertEqual(Priority.low.displayName, "Low")
        XCTAssertEqual(Priority.medium.displayName, "Medium")
        XCTAssertEqual(Priority.high.displayName, "High")
    }
    
    func testPrioritySystemImages() {
        XCTAssertEqual(Priority.low.systemImageName, "arrow.down.circle")
        XCTAssertEqual(Priority.medium.systemImageName, "minus.circle")
        XCTAssertEqual(Priority.high.systemImageName, "arrow.up.circle")
    }
    
    func testPriorityRawValues() {
        XCTAssertEqual(Priority.low.rawValue, "low")
        XCTAssertEqual(Priority.medium.rawValue, "medium")
        XCTAssertEqual(Priority.high.rawValue, "high")
    }
    
    func testPriorityFromRawValue() {
        XCTAssertEqual(Priority(rawValue: "low"), .low)
        XCTAssertEqual(Priority(rawValue: "medium"), .medium)
        XCTAssertEqual(Priority(rawValue: "high"), .high)
        XCTAssertNil(Priority(rawValue: "invalid"))
    }
    
    func testPriorityAllCases() {
        XCTAssertEqual(Priority.allCases.count, 3)
        XCTAssertTrue(Priority.allCases.contains(.low))
        XCTAssertTrue(Priority.allCases.contains(.medium))
        XCTAssertTrue(Priority.allCases.contains(.high))
    }
}

// MARK: - Category Tests

final class CategoryTests: XCTestCase {
    
    func testCategoryDisplayNames() {
        XCTAssertEqual(Category.work.displayName, "Work")
        XCTAssertEqual(Category.personal.displayName, "Personal")
        XCTAssertEqual(Category.shopping.displayName, "Shopping")
        XCTAssertEqual(Category.health.displayName, "Health")
        XCTAssertEqual(Category.finance.displayName, "Finance")
    }
    
    func testCategorySystemImages() {
        XCTAssertEqual(Category.work.systemImageName, "briefcase")
        XCTAssertEqual(Category.personal.systemImageName, "person")
        XCTAssertEqual(Category.shopping.systemImageName, "cart")
        XCTAssertEqual(Category.health.systemImageName, "heart")
        XCTAssertEqual(Category.finance.systemImageName, "dollarsign.circle")
    }
    
    func testCategoryRawValues() {
        XCTAssertEqual(Category.work.rawValue, "work")
        XCTAssertEqual(Category.personal.rawValue, "personal")
        XCTAssertEqual(Category.shopping.rawValue, "shopping")
        XCTAssertEqual(Category.health.rawValue, "health")
        XCTAssertEqual(Category.finance.rawValue, "finance")
    }
    
    func testCategoryFromRawValue() {
        XCTAssertEqual(Category(rawValue: "work"), .work)
        XCTAssertEqual(Category(rawValue: "personal"), .personal)
        XCTAssertEqual(Category(rawValue: "shopping"), .shopping)
        XCTAssertEqual(Category(rawValue: "health"), .health)
        XCTAssertEqual(Category(rawValue: "finance"), .finance)
        XCTAssertNil(Category(rawValue: "invalid"))
    }
    
    func testCategoryAllCases() {
        XCTAssertEqual(Category.allCases.count, 5)
        XCTAssertTrue(Category.allCases.contains(.work))
        XCTAssertTrue(Category.allCases.contains(.personal))
        XCTAssertTrue(Category.allCases.contains(.shopping))
        XCTAssertTrue(Category.allCases.contains(.health))
        XCTAssertTrue(Category.allCases.contains(.finance))
    }
}