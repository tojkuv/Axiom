import XCTest
@testable import AxiomStudio_macOS
import AxiomStudio_Shared

final class AxiomStudio_macOSTests: XCTestCase {
    
    func testBasicStructCreation() throws {
        // Test basic model creation to ensure compilation works
        let task = StudioTask(
            title: "Test Task",
            description: "Test Description",
            priority: .medium,
            category: .work
        )
        
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.description, "Test Description")
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.category, .work)
    }
    
    func testContactCreation() throws {
        let contact = Contact(
            identifier: "test-id",
            givenName: "John",
            familyName: "Doe"
        )
        
        XCTAssertEqual(contact.givenName, "John")
        XCTAssertEqual(contact.familyName, "Doe")
        XCTAssertEqual(contact.fullName, "John Doe")
        XCTAssertEqual(contact.initials, "JD")
    }
    
    func testTaskPriorityProperties() throws {
        XCTAssertEqual(TaskPriority.low.displayName, "Low")
        XCTAssertEqual(TaskPriority.medium.displayName, "Medium")
        XCTAssertEqual(TaskPriority.high.displayName, "High")
        XCTAssertEqual(TaskPriority.critical.displayName, "Critical")
        
        XCTAssertEqual(TaskPriority.low.sortOrder, 1)
        XCTAssertEqual(TaskPriority.medium.sortOrder, 2)
        XCTAssertEqual(TaskPriority.high.sortOrder, 3)
        XCTAssertEqual(TaskPriority.critical.sortOrder, 4)
    }
    
    func testTaskCategoryProperties() throws {
        XCTAssertEqual(TaskCategory.general.displayName, "General")
        XCTAssertEqual(TaskCategory.work.displayName, "Work")
        XCTAssertEqual(TaskCategory.personal.displayName, "Personal")
    }
    
    func testTaskStatusProperties() throws {
        XCTAssertEqual(TaskStatus.pending.displayName, "Pending")
        XCTAssertEqual(TaskStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(TaskStatus.completed.displayName, "Completed")
        XCTAssertEqual(TaskStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(TaskStatus.deferred.displayName, "Deferred")
    }
    
    func testIsCompletedProperty() throws {
        let completedTask = StudioTask(
            title: "Completed Task",
            status: .completed
        )
        
        let pendingTask = StudioTask(
            title: "Pending Task",
            status: .pending
        )
        
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertFalse(pendingTask.isCompleted)
    }
    
    func testLocationReminderCreation() throws {
        let locationReminder = LocationReminder(
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 100.0,
            triggerOnEntry: true,
            triggerOnExit: false,
            locationName: "San Francisco"
        )
        
        XCTAssertEqual(locationReminder.latitude, 37.7749)
        XCTAssertEqual(locationReminder.longitude, -122.4194)
        XCTAssertEqual(locationReminder.radius, 100.0)
        XCTAssertTrue(locationReminder.triggerOnEntry)
        XCTAssertFalse(locationReminder.triggerOnExit)
        XCTAssertEqual(locationReminder.locationName, "San Francisco")
    }
    
    func testPhoneNumberIdentifiable() throws {
        let phoneNumber = PhoneNumber(value: "123-456-7890", label: "Work")
        XCTAssertNotNil(phoneNumber.id)
        XCTAssertEqual(phoneNumber.value, "123-456-7890")
        XCTAssertEqual(phoneNumber.label, "Work")
    }
    
    func testEmailAddressIdentifiable() throws {
        let emailAddress = EmailAddress(value: "test@example.com", label: "Home")
        XCTAssertNotNil(emailAddress.id)
        XCTAssertEqual(emailAddress.value, "test@example.com")
        XCTAssertEqual(emailAddress.label, "Home")
    }
    
    func testPostalAddressIdentifiable() throws {
        let postalAddress = PostalAddress(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "USA",
            label: "Home"
        )
        
        XCTAssertNotNil(postalAddress.id)
        XCTAssertEqual(postalAddress.street, "123 Main St")
        XCTAssertEqual(postalAddress.city, "San Francisco")
        XCTAssertEqual(postalAddress.state, "CA")
        XCTAssertEqual(postalAddress.postalCode, "94105")
        XCTAssertEqual(postalAddress.country, "USA")
        XCTAssertEqual(postalAddress.label, "Home")
    }
    
    func testContactFrequencyProperties() throws {
        XCTAssertEqual(ContactFrequency.daily.displayName, "Daily")
        XCTAssertEqual(ContactFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(ContactFrequency.monthly.displayName, "Monthly")
        
        XCTAssertEqual(ContactFrequency.daily.interval, 86400)
        XCTAssertEqual(ContactFrequency.weekly.interval, 604800)
        XCTAssertNil(ContactFrequency.never.interval)
    }
}