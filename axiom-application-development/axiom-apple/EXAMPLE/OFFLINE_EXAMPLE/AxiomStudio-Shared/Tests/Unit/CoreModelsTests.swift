import XCTest
@testable import AxiomStudio_Shared

final class CoreModelsTests: XCTestCase {
    
    func testStudioTaskCreation() {
        let task = TestDataFactory.createTestTask()
        
        XCTAssertFalse(task.title.isEmpty)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertEqual(task.category, .general)
        XCTAssertEqual(task.status, .pending)
        XCTAssertNotNil(task.createdAt)
        XCTAssertNotNil(task.updatedAt)
    }
    
    func testStudioTaskPriorityOrdering() {
        let lowPriority = TaskPriority.low
        let mediumPriority = TaskPriority.medium
        let highPriority = TaskPriority.high
        let criticalPriority = TaskPriority.critical
        
        XCTAssertLessThan(lowPriority.sortOrder, mediumPriority.sortOrder)
        XCTAssertLessThan(mediumPriority.sortOrder, highPriority.sortOrder)
        XCTAssertLessThan(highPriority.sortOrder, criticalPriority.sortOrder)
    }
    
    func testContactCreation() {
        let contact = TestDataFactory.createTestContact()
        
        XCTAssertFalse(contact.givenName.isEmpty)
        XCTAssertFalse(contact.familyName.isEmpty)
        XCTAssertEqual(contact.fullName, "John Doe")
        XCTAssertEqual(contact.displayName, "John Doe")
        XCTAssertFalse(contact.phoneNumbers.isEmpty)
        XCTAssertFalse(contact.emailAddresses.isEmpty)
    }
    
    func testContactDisplayNameLogic() {
        let contactWithName = TestDataFactory.createTestContact(
            givenName: "Jane",
            familyName: "Smith"
        )
        XCTAssertEqual(contactWithName.displayName, "Jane Smith")
        
        let contactWithOrganization = TestDataFactory.createTestContact(
            givenName: "",
            familyName: "",
            organizationName: "Acme Corp"
        )
        XCTAssertEqual(contactWithOrganization.displayName, "Acme Corp")
        
        let unknownContact = TestDataFactory.createTestContact(
            givenName: "",
            familyName: "",
            organizationName: nil
        )
        XCTAssertEqual(unknownContact.displayName, "Unknown Contact")
    }
    
    func testCalendarEventCreation() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)
        
        let event = TestDataFactory.createTestCalendarEvent(
            title: "Test Meeting",
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(event.title, "Test Meeting")
        XCTAssertEqual(event.startDate, startDate)
        XCTAssertEqual(event.endDate, endDate)
        XCTAssertFalse(event.isAllDay)
    }
    
    func testHealthMetricCreation() {
        let metric = TestDataFactory.createTestHealthMetric(
            type: .stepCount,
            value: 5000,
            unit: "steps"
        )
        
        XCTAssertEqual(metric.type, .stepCount)
        XCTAssertEqual(metric.value, 5000)
        XCTAssertEqual(metric.unit, "steps")
        XCTAssertNotNil(metric.date)
    }
    
    func testLocationDataCreation() {
        let location = TestDataFactory.createTestLocationData(
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        XCTAssertEqual(location.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(location.longitude, -74.0060, accuracy: 0.0001)
        XCTAssertNotNil(location.timestamp)
        XCTAssertEqual(location.horizontalAccuracy, 5.0)
    }
    
    func testDocumentCreation() {
        let document = TestDataFactory.createTestDocument(
            fileName: "test.pdf",
            fileType: .pdf,
            fileSize: 2048
        )
        
        XCTAssertEqual(document.fileName, "test.pdf")
        XCTAssertEqual(document.fileType, .pdf)
        XCTAssertEqual(document.fileSize, 2048)
        XCTAssertFalse(document.isProcessed)
        XCTAssertTrue(document.tags.isEmpty)
    }
    
    func testMLModelCreation() {
        let model = TestDataFactory.createTestMLModel(
            name: "SentimentModel",
            modelType: .sentimentAnalysis
        )
        
        XCTAssertEqual(model.name, "SentimentModel")
        XCTAssertEqual(model.modelType, .sentimentAnalysis)
        XCTAssertTrue(model.isLoaded)
        XCTAssertEqual(model.accuracy, 0.95)
    }
    
    func testTextAnalysisResultCreation() {
        let result = TestDataFactory.createTestTextAnalysisResult(
            sourceText: "I love this app!",
            analysisType: .sentiment,
            confidence: 0.95
        )
        
        XCTAssertEqual(result.sourceText, "I love this app!")
        XCTAssertEqual(result.analysisType, .sentiment)
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertNotNil(result.sentiment)
        XCTAssertEqual(result.sentiment?.sentiment, .positive)
    }
    
    func testMemoryUsageCalculations() {
        let memoryUsage = TestDataFactory.createTestMemoryUsage(
            totalMemory: 8_000_000_000,
            usedMemory: 4_000_000_000,
            appMemoryUsage: 200_000_000
        )
        
        XCTAssertEqual(memoryUsage.usagePercentage, 50.0, accuracy: 0.1)
        XCTAssertEqual(memoryUsage.appUsagePercentage, 2.5, accuracy: 0.1)
        XCTAssertEqual(memoryUsage.freeMemory, 4_000_000_000)
    }
    
    func testStudioRouteNavigation() {
        let personalInfoRoute = StudioRoute.personalInfo
        let taskListRoute = StudioRoute.taskList
        
        XCTAssertTrue(personalInfoRoute.isRootRoute)
        XCTAssertFalse(taskListRoute.isRootRoute)
        XCTAssertEqual(taskListRoute.category, .personalInfo)
        XCTAssertEqual(personalInfoRoute.category.rootRoute, .personalInfo)
    }
    
    func testApplicationStateInitialization() {
        let state = TestDataFactory.createTestApplicationState()
        
        XCTAssertEqual(state.personalInfo.tasks.count, 3)
        XCTAssertEqual(state.personalInfo.contacts.count, 2)
        XCTAssertEqual(state.healthLocation.healthMetrics.count, 1)
        XCTAssertEqual(state.contentProcessor.mlModels.count, 1)
        XCTAssertEqual(state.mediaHub.documents.count, 1)
        XCTAssertNotNil(state.performance.memoryUsage)
    }
    
    func testErrorRecoveryStrategies() {
        let personalInfoError = PersonalInfoError.taskNotFound(UUID())
        let healthLocationError = HealthLocationError.healthAccessDenied
        let contentProcessorError = ContentProcessorError.modelNotFound("TestModel")
        
        XCTAssertEqual(personalInfoError.recoveryStrategy, .refresh)
        XCTAssertEqual(healthLocationError.recoveryStrategy, .requestPermission)
        XCTAssertEqual(contentProcessorError.recoveryStrategy, .download)
    }
}