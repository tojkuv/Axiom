import XCTest
@testable import AxiomStudio_iOS
import AxiomStudio_Shared

final class AxiomStudio_iOSTests: XCTestCase {
    
    var orchestrator: StudioOrchestrator!
    
    override func setUp() async throws {
        try await super.setUp()
        orchestrator = try StudioOrchestrator()
    }
    
    override func tearDown() async throws {
        await orchestrator?.shutdown()
        orchestrator = nil
        try await super.tearDown()
    }
    
    func testOrchestratorInitialization() throws {
        XCTAssertNotNil(orchestrator)
        XCTAssertFalse(orchestrator.isInitialized)
        XCTAssertNil(orchestrator.initializationError)
    }
    
    func testOrchestratorInitializationProcess() async throws {
        await orchestrator.initialize()
        
        XCTAssertTrue(orchestrator.isInitialized)
        XCTAssertNil(orchestrator.initializationError)
    }
    
    func testApplicationStateAccess() async throws {
        await orchestrator.initialize()
        
        let state = orchestrator.applicationState
        
        XCTAssertNotNil(state.personalInfo)
        XCTAssertNotNil(state.healthLocation)
        XCTAssertNotNil(state.contentProcessor)
        XCTAssertNotNil(state.mediaHub)
        XCTAssertNotNil(state.performance)
        XCTAssertNotNil(state.navigation)
    }
    
    func testTaskCreation() async throws {
        await orchestrator.initialize()
        
        let task = StudioTask(
            title: "Test Task",
            description: "A test task for iOS app",
            isCompleted: false,
            priority: .medium,
            category: .work,
            dueDate: nil,
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["test"],
            subtasks: [],
            locationReminder: nil,
            contactIds: []
        )
        
        try await orchestrator.createTask(task)
        
        let tasks = await orchestrator.getCurrentTasks()
        XCTAssertTrue(tasks.contains { $0.title == "Test Task" })
    }
    
    func testNavigationActions() async throws {
        await orchestrator.initialize()
        
        try await orchestrator.navigate(to: .taskList)
        
        let navigationState = orchestrator.navigationService.saveNavigationState()
        XCTAssertEqual(navigationState.currentRoute, .taskList)
    }
    
    func testSystemHealthSummary() async throws {
        await orchestrator.initialize()
        
        let summary = await orchestrator.getSystemHealthSummary()
        
        XCTAssertNotNil(summary)
        XCTAssertGreaterThan(summary.memoryUsage, 0)
        XCTAssertGreaterThanOrEqual(summary.batteryLevel, 0.0)
        XCTAssertLessThanOrEqual(summary.batteryLevel, 1.0)
    }
    
    func testContentProcessing() async throws {
        await orchestrator.initialize()
        
        let testText = "This is a test text for sentiment analysis."
        
        try await orchestrator.processText(testText, analysisType: .sentiment)
        
        let state = orchestrator.applicationState
        XCTAssertFalse(state.contentProcessor.textAnalysisResults.isEmpty)
    }
    
    func testDocumentImport() async throws {
        await orchestrator.initialize()
        
        // Create a temporary test file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_document.txt")
        
        let testContent = "This is a test document for import testing."
        try testContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        try await orchestrator.importDocument(from: tempURL)
        
        let state = orchestrator.applicationState
        XCTAssertFalse(state.mediaHub.documents.isEmpty)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    func testClientStateStreaming() async throws {
        await orchestrator.initialize()
        
        // Test that state updates are reflected in the orchestrator
        let initialTaskCount = await orchestrator.getCurrentTasks().count
        
        let newTask = StudioTask(
            title: "Stream Test Task",
            description: nil,
            isCompleted: false,
            priority: .low,
            category: .personal,
            dueDate: nil,
            createdAt: Date(),
            updatedAt: Date(),
            tags: [],
            subtasks: [],
            locationReminder: nil,
            contactIds: []
        )
        
        try await orchestrator.createTask(newTask)
        
        let updatedTaskCount = await orchestrator.getCurrentTasks().count
        XCTAssertEqual(updatedTaskCount, initialTaskCount + 1)
    }
    
    func testErrorHandling() async throws {
        await orchestrator.initialize()
        
        // Test handling of invalid actions
        do {
            try await orchestrator.deleteTask(UUID())
            XCTFail("Should have thrown an error for non-existent task")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testPerformanceMetrics() async throws {
        await orchestrator.initialize()
        
        try await orchestrator.processAction(.performance(.startMonitoring))
        
        // Wait a bit for metrics to be collected
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let summary = await orchestrator.getSystemHealthSummary()
        XCTAssertNotNil(summary)
        
        try await orchestrator.processAction(.performance(.stopMonitoring))
    }
}