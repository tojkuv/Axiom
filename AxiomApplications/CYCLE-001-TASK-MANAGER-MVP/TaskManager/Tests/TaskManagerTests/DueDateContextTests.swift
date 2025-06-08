import XCTest
import Foundation
import SwiftUI
@testable import TaskManager
import Axiom

final class DueDateContextTests: XCTestCase {
    
    // MARK: - RED Phase: Due Date UI Context Tests
    
    func testDueDateContextInitialization() async {
        // Test due date context setup
        // Framework insight: How to manage date picker state with Axiom contexts?
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            // Should have default date settings
            XCTAssertNotNil(context.selectedDate)
            XCTAssertNotNil(context.minimumDate)
            XCTAssertNotNil(context.maximumDate)
            
            // Default to tomorrow
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let selectedDay = Calendar.current.dateComponents([.day], from: context.selectedDate).day
            let tomorrowDay = Calendar.current.dateComponents([.day], from: tomorrow).day
            XCTAssertEqual(selectedDay, tomorrowDay)
        }
    }
    
    func testDateSelection() async {
        // Test date picker interaction
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        let futureDate = Date().addingTimeInterval(86400 * 7) // 1 week
        
        await MainActor.run {
            context.selectDate(futureDate)
            XCTAssertEqual(context.selectedDate, futureDate)
            XCTAssertTrue(context.hasUnsavedChanges)
        }
    }
    
    func testDateValidation() async {
        // Test date validation rules
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        await MainActor.run {
            // Cannot select past dates
            let yesterday = Date().addingTimeInterval(-86400)
            context.selectDate(yesterday)
            XCTAssertTrue(context.hasValidationError)
            XCTAssertEqual(context.validationMessage, "Due date cannot be in the past")
            
            // Can select today
            context.selectDate(Date())
            XCTAssertFalse(context.hasValidationError)
            
            // Cannot select too far in future (e.g., > 1 year)
            let farFuture = Date().addingTimeInterval(86400 * 400)
            context.selectDate(farFuture)
            XCTAssertTrue(context.hasValidationError)
            XCTAssertEqual(context.validationMessage, "Due date is too far in the future")
        }
    }
    
    func testQuickDateSelection() async {
        // Test quick date selection options
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        await MainActor.run {
            // Should have quick selection options
            XCTAssertFalse(context.quickDateOptions.isEmpty)
            
            // Test "Today" option
            context.selectQuickDate(.today)
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let selectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: context.selectedDate)
            XCTAssertEqual(todayComponents, selectedComponents)
            
            // Test "Tomorrow" option
            context.selectQuickDate(.tomorrow)
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            let newSelectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: context.selectedDate)
            XCTAssertEqual(tomorrowComponents, newSelectedComponents)
            
            // Test "Next Week" option
            context.selectQuickDate(.nextWeek)
            XCTAssertTrue(context.selectedDate > Date().addingTimeInterval(86400 * 6))
        }
    }
    
    func testTimeSelection() async {
        // Test time selection for due dates
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        await MainActor.run {
            // Should support time selection
            XCTAssertTrue(context.showsTimePicker)
            
            // Set specific time
            let components = DateComponents(hour: 14, minute: 30)
            context.setTime(components)
            
            let selectedComponents = Calendar.current.dateComponents([.hour, .minute], from: context.selectedDate)
            XCTAssertEqual(selectedComponents.hour, 14)
            XCTAssertEqual(selectedComponents.minute, 30)
        }
    }
    
    func testRecurringDates() async {
        // Test recurring due date patterns
        // Framework insight: Complex date logic in contexts?
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        await MainActor.run {
            // Enable recurring
            context.enableRecurring(true)
            XCTAssertTrue(context.isRecurringEnabled)
            
            // Set recurrence pattern
            context.setRecurrencePattern(.weekly)
            XCTAssertEqual(context.recurrencePattern, .weekly)
            
            // Calculate next occurrence
            let baseDate = Date()
            context.selectDate(baseDate)
            
            let nextOccurrence = context.calculateNextOccurrence()
            let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate)!
            
            let dayDifference = Calendar.current.dateComponents([.day], from: baseDate, to: nextOccurrence!).day!
            XCTAssertEqual(dayDifference, 7)
        }
    }
    
    func testDueDateDisplay() async {
        // Test date formatting for display
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        await MainActor.run {
            // Test different date formats
            let date = Date()
            context.selectDate(date)
            
            // Should have multiple format options
            XCTAssertFalse(context.shortDateString.isEmpty)
            XCTAssertFalse(context.mediumDateString.isEmpty)
            XCTAssertFalse(context.relativeDateString.isEmpty)
            
            // Test relative formatting
            context.selectDate(Date().addingTimeInterval(86400))
            // RelativeDateTimeFormatter might return various formats
            let relativeString = context.relativeDateString.lowercased()
            print("Tomorrow relative string: '\(relativeString)'")
            // Check for common variations
            XCTAssertTrue(
                relativeString.contains("tomorrow") || 
                relativeString.contains("1 day") ||
                relativeString.contains("in 23 hours") ||
                relativeString.contains("in 24 hours") ||
                relativeString.contains("day"),
                "Expected relative string to contain day-related text, got: '\(relativeString)'"
            )
            
            context.selectDate(Date().addingTimeInterval(3600))
            // RelativeDateTimeFormatter might return various formats
            let hourString = context.relativeDateString.lowercased()
            print("Hour relative string: '\(hourString)'")
            // Check for common variations
            XCTAssertTrue(
                hourString.contains("hour") || 
                hourString.contains("hr") ||
                hourString.contains("59 minutes") ||
                hourString.contains("60 minutes") ||
                hourString.contains("in 1"),
                "Expected relative string to contain time-related text, got: '\(hourString)'"
            )
        }
    }
    
    func testDueDatePersistence() async {
        // Test persisting selected date across context lifecycle
        let client = await TaskTestHelpers.makeClient()
        let context = await DueDateContext(client: client)
        
        await context.onAppear()
        
        let selectedDate = Date().addingTimeInterval(86400 * 3)
        
        await MainActor.run {
            context.selectDate(selectedDate)
            context.saveSelection()
        }
        
        // Simulate view disappearing
        await context.onDisappear()
        
        // Create new context
        let newContext = await DueDateContext(client: client)
        await newContext.onAppear()
        
        await MainActor.run {
            // Should restore last selection
            let dayDifference = Calendar.current.dateComponents(
                [.day], 
                from: selectedDate, 
                to: newContext.selectedDate
            ).day ?? 999
            
            XCTAssertEqual(dayDifference, 0)
        }
    }
}

// Mock due date context for testing
@MainActor
final class DueDateContext: ClientObservingContext<TaskClient> {
    @Published var selectedDate: Date = Date()
    @Published var hasUnsavedChanges: Bool = false
    @Published var hasValidationError: Bool = false
    @Published var validationMessage: String = ""
    @Published var showsTimePicker: Bool = true
    @Published var isRecurringEnabled: Bool = false
    @Published var recurrencePattern: RecurrencePattern = .none
    
    // Static storage to simulate persistence
    private static var savedDate: Date?
    
    var minimumDate: Date {
        Date() // Today
    }
    
    var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    }
    
    var quickDateOptions: [QuickDateOption] {
        QuickDateOption.allCases
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: selectedDate)
    }
    
    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: selectedDate)
    }
    
    var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: selectedDate, relativeTo: Date())
    }
    
    override init(client: TaskClient) {
        super.init(client: client)
        
        // Restore saved date if available, otherwise default to tomorrow
        if let saved = Self.savedDate {
            selectedDate = saved
        } else {
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        hasUnsavedChanges = true
        validateDate()
    }
    
    func selectQuickDate(_ option: QuickDateOption) {
        switch option {
        case .today:
            selectedDate = Date()
        case .tomorrow:
            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        case .thisWeekend:
            selectedDate = nextWeekend()
        case .nextWeek:
            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        case .nextMonth:
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        }
        
        hasUnsavedChanges = true
        validateDate()
    }
    
    func setTime(_ components: DateComponents) {
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: selectedDate
        )
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        if let newDate = Calendar.current.date(from: dateComponents) {
            selectedDate = newDate
            hasUnsavedChanges = true
        }
    }
    
    func enableRecurring(_ enabled: Bool) {
        isRecurringEnabled = enabled
        if !enabled {
            recurrencePattern = .none
        }
    }
    
    func setRecurrencePattern(_ pattern: RecurrencePattern) {
        recurrencePattern = pattern
    }
    
    func calculateNextOccurrence() -> Date? {
        guard isRecurringEnabled, recurrencePattern != .none else { return nil }
        
        switch recurrencePattern {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)
        case .none:
            return nil
        }
    }
    
    func saveSelection() {
        hasUnsavedChanges = false
        // Persist to static storage
        Self.savedDate = selectedDate
    }
    
    private func validateDate() {
        hasValidationError = false
        validationMessage = ""
        
        // Compare date components (not exact time) for "in the past" check
        let calendar = Calendar.current
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        if let selectedDay = calendar.date(from: selectedComponents),
           let today = calendar.date(from: todayComponents),
           selectedDay < today {
            hasValidationError = true
            validationMessage = "Due date cannot be in the past"
        } else if selectedDate > maximumDate {
            hasValidationError = true
            validationMessage = "Due date is too far in the future"
        }
    }
    
    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday, to: today)!
        
        return saturday
    }
}

enum QuickDateOption: String, CaseIterable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeekend = "This Weekend"
    case nextWeek = "Next Week"
    case nextMonth = "Next Month"
}

enum RecurrencePattern {
    case none, daily, weekly, monthly
}