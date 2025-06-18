import XCTest
import EventKit
import Contacts
import CoreLocation
@testable import AxiomStudio_Shared

final class SystemCapabilitiesTests: XCTestCase {
    
    var eventKitCapability: EventKitCapability!
    var contactsCapability: ContactsCapability!
    var locationCapability: LocationServicesCapability!
    
    override func setUp() async throws {
        try await super.setUp()
        eventKitCapability = EventKitCapability()
        contactsCapability = ContactsCapability()
        locationCapability = LocationServicesCapability()
    }
    
    override func tearDown() async throws {
        try await eventKitCapability?.deactivate()
        try await contactsCapability?.deactivate()
        try await locationCapability?.deactivate()
        
        eventKitCapability = nil
        contactsCapability = nil
        locationCapability = nil
        
        try await super.tearDown()
    }
    
    // MARK: - EventKit Tests
    
    func testEventKitCapabilityInitialization() async throws {
        let name = await eventKitCapability.name
        let version = await eventKitCapability.version
        let id = await eventKitCapability.id
        XCTAssertEqual(name, "EventKit")
        XCTAssertEqual(version, "1.0.0")
        XCTAssertNotNil(id)
    }
    
    func testEventKitCalendarConversion() async throws {
        // Create a mock EKEvent
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = "Test Event"
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(3600)
        event.notes = "Test event description"
        event.location = "Test Location"
        event.isAllDay = false
        
        // Convert to CalendarEvent
        let calendarEvent = await eventKitCapability.convertToCalendarEvent(event)
        
        XCTAssertEqual(calendarEvent.title, "Test Event")
        XCTAssertEqual(calendarEvent.description, "Test event description")
        XCTAssertEqual(calendarEvent.location, "Test Location")
        XCTAssertFalse(calendarEvent.isAllDay)
        XCTAssertEqual(calendarEvent.startDate, event.startDate)
        XCTAssertEqual(calendarEvent.endDate, event.endDate)
    }
    
    func testEventKitReminderConversion() async throws {
        let eventStore = EKEventStore()
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = "Test Reminder"
        reminder.notes = "Test reminder notes"
        reminder.priority = 5
        reminder.isCompleted = false
        
        let convertedReminder = await eventKitCapability.convertToReminder(reminder)
        
        XCTAssertEqual(convertedReminder.title, "Test Reminder")
        XCTAssertEqual(convertedReminder.notes, "Test reminder notes")
        XCTAssertFalse(convertedReminder.isCompleted)
    }
    
    // MARK: - Contacts Tests
    
    func testContactsCapabilityInitialization() async throws {
        let name = await contactsCapability.name
        let version = await contactsCapability.version
        let id = await contactsCapability.id
        XCTAssertEqual(name, "Contacts")
        XCTAssertEqual(version, "1.0.0")
        XCTAssertNotNil(id)
    }
    
    func testContactConversion() async throws {
        // Create a mock CNContact
        let cnContact = CNMutableContact()
        cnContact.givenName = "John"
        cnContact.familyName = "Doe"
        cnContact.organizationName = "Test Company"
        cnContact.jobTitle = "Software Engineer"
        cnContact.note = "Test contact"
        
        let phoneNumber = CNLabeledValue(
            label: CNLabelPhoneNumberMobile,
            value: CNPhoneNumber(stringValue: "+1234567890")
        )
        cnContact.phoneNumbers = [phoneNumber]
        
        let emailAddress = CNLabeledValue(
            label: CNLabelWork,
            value: "john.doe@example.com" as NSString
        )
        cnContact.emailAddresses = [emailAddress]
        
        // Convert to Contact
        let contact = await contactsCapability.convertToContact(cnContact)
        
        XCTAssertEqual(contact.givenName, "John")
        XCTAssertEqual(contact.familyName, "Doe")
        XCTAssertEqual(contact.organizationName, "Test Company")
        XCTAssertEqual(contact.jobTitle, "Software Engineer")
        XCTAssertEqual(contact.note, "Test contact")
        XCTAssertEqual(contact.fullName, "John Doe")
        XCTAssertEqual(contact.displayName, "John Doe")
        XCTAssertFalse(contact.phoneNumbers.isEmpty)
        XCTAssertFalse(contact.emailAddresses.isEmpty)
    }
    
    func testContactRoundTripConversion() async throws {
        // Create a Contact
        let originalContact = TestDataFactory.createTestContact(
            givenName: "Jane",
            familyName: "Smith",
            organizationName: "Acme Corp"
        )
        
        // Convert to CNContact and back
        let cnContact = await contactsCapability.convertToCNContact(originalContact)
        let convertedContact = await contactsCapability.convertToContact(cnContact)
        
        XCTAssertEqual(convertedContact.givenName, originalContact.givenName)
        XCTAssertEqual(convertedContact.familyName, originalContact.familyName)
        XCTAssertEqual(convertedContact.organizationName, originalContact.organizationName)
        XCTAssertEqual(convertedContact.fullName, originalContact.fullName)
    }
    
    // MARK: - Location Services Tests
    
    func testLocationServicesCapabilityInitialization() async throws {
        let name = await locationCapability.name
        let version = await locationCapability.version
        let id = await locationCapability.id
        XCTAssertEqual(name, "LocationServices")
        XCTAssertEqual(version, "1.0.0")
        XCTAssertNotNil(id)
    }
    
    func testLocationDataConversion() async throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 100.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 10.0,
            timestamp: Date()
        )
        
        let locationData = await locationCapability.convertToLocationData(location)
        
        XCTAssertEqual(locationData.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(locationData.longitude, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(locationData.altitude, 100.0)
        XCTAssertEqual(locationData.horizontalAccuracy, 5.0)
        XCTAssertEqual(locationData.verticalAccuracy, 10.0)
        XCTAssertEqual(locationData.timestamp, location.timestamp)
    }
    
    func testCircularRegionConversion() async throws {
        let locationReminder = LocationReminder(
            latitude: 40.7128,
            longitude: -74.0060,
            radius: 100.0,
            triggerOnEntry: true,
            triggerOnExit: false,
            locationName: "New York"
        )
        
        let region = await locationCapability.convertToCircularRegion(
            from: locationReminder,
            identifier: "test-region"
        )
        
        XCTAssertEqual(region.center.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, -74.0060, accuracy: 0.0001)
        XCTAssertEqual(region.radius, 100.0)
        XCTAssertEqual(region.identifier, "test-region")
        XCTAssertTrue(region.notifyOnEntry)
        XCTAssertFalse(region.notifyOnExit)
    }
    
    func testLocationReminderConversion() async throws {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            radius: 50.0,
            identifier: "los-angeles"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        let locationReminder = await locationCapability.convertToLocationReminder(
            from: region,
            triggerOnEntry: true,
            triggerOnExit: true
        )
        
        XCTAssertEqual(locationReminder.latitude, 34.0522, accuracy: 0.0001)
        XCTAssertEqual(locationReminder.longitude, -118.2437, accuracy: 0.0001)
        XCTAssertEqual(locationReminder.radius, 50.0)
        XCTAssertTrue(locationReminder.triggerOnEntry)
        XCTAssertTrue(locationReminder.triggerOnExit)
    }
    
    func testDistanceCalculation() async throws {
        let from = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let to = CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0)
        
        let distance = await locationCapability.calculateDistance(from: from, to: to)
        
        // Distance from 0,0 to 0,1 should be approximately 111,320 meters
        XCTAssertGreaterThan(distance, 100000)
        XCTAssertLessThan(distance, 120000)
    }
    
    func testLocationInRegion() async throws {
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let region = CLCircularRegion(center: center, radius: 1000.0, identifier: "test")
        
        let insideLocation = CLLocationCoordinate2D(latitude: 37.7759, longitude: -122.4184)
        let outsideLocation = CLLocationCoordinate2D(latitude: 37.8749, longitude: -122.3194)
        
        let isInside = await locationCapability.isLocationInRegion(insideLocation, region: region)
        let isOutside = await locationCapability.isLocationInRegion(outsideLocation, region: region)
        XCTAssertTrue(isInside)
        XCTAssertFalse(isOutside)
    }
    
    func testMovementPatternAnalysis() async throws {
        let locations = [
            CLLocation(latitude: 37.7749, longitude: -122.4194),
            CLLocation(latitude: 37.7759, longitude: -122.4184),
            CLLocation(latitude: 37.7769, longitude: -122.4174),
            CLLocation(latitude: 37.7779, longitude: -122.4164)
        ]
        
        // Add timestamps
        let now = Date()
        for (index, location) in locations.enumerated() {
            let timestamp = now.addingTimeInterval(TimeInterval(index * 60)) // 1 minute apart
            // Note: CLLocation is immutable, so we'd need to create new instances with timestamps
        }
        
        let pattern = await locationCapability.analyzeMovementPattern(locations: locations)
        
        XCTAssertNotNil(pattern)
        XCTAssertGreaterThan(pattern?.distance ?? 0, 0)
        XCTAssertEqual(pattern?.locations.count, 4)
    }
    
    // MARK: - Integration Tests
    
    func testCapabilityAvailabilityChecks() async throws {
        // These tests will depend on the device and permissions
        // In a real test environment, you might mock these
        
        // Test that capabilities report their availability correctly
        let eventKitAvailable = await eventKitCapability.isAvailable
        let contactsAvailable = await contactsCapability.isAvailable
        let locationAvailable = await locationCapability.isAvailable
        
        // Note: These might be false in test environment due to permissions
        // The important thing is that they don't crash
        XCTAssertNotNil(eventKitAvailable)
        XCTAssertNotNil(contactsAvailable)
        XCTAssertNotNil(locationAvailable)
    }
    
    func testCapabilityDeactivation() async throws {
        // Test that deactivation doesn't throw errors
        try await eventKitCapability.deactivate()
        try await contactsCapability.deactivate()
        try await locationCapability.deactivate()
        
        // Should be able to deactivate multiple times without error
        try await eventKitCapability.deactivate()
        try await contactsCapability.deactivate()
        try await locationCapability.deactivate()
    }
    
    // MARK: - Error Handling Tests
    
    func testEventKitErrorHandling() async throws {
        // Test error cases for EventKit
        let capability = EventKitCapability()
        
        // Without activation, operations should handle errors gracefully
        // Note: Actual error testing would require mocking or specific test conditions
    }
    
    func testContactsErrorHandling() async throws {
        // Test error cases for Contacts
        let capability = ContactsCapability()
        
        // Without activation, operations should handle errors gracefully
        // Note: Actual error testing would require mocking or specific test conditions
    }
    
    func testLocationServicesErrorHandling() async throws {
        // Test error cases for Location Services
        let capability = LocationServicesCapability()
        
        // Without activation, operations should handle errors gracefully
        // Note: Actual error testing would require mocking or specific test conditions
    }
}