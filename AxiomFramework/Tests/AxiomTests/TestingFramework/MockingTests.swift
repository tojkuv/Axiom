import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests for enhanced mocking capabilities
final class MockingTests: XCTestCase {
    
    // MARK: - Test Protocols and Types
    
    @AutoMockable
    protocol TestService {
        func performAction(_ action: String) async throws -> String
        func getCount() async -> Int
        func updateState(value: Int) async throws
        var isActive: Bool { get async }
    }
    
    @AutoMockable
    protocol TestDataSource {
        func fetchData(id: String) async throws -> TestData
        func saveData(_ data: TestData) async throws
        func deleteData(id: String) async throws -> Bool
    }
    
    struct TestData: Equatable {
        let id: String
        let value: String
        let timestamp: Date
    }
    
    @MainActor
    final class TestContext: ObservableContext {
        let service: TestService
        let dataSource: TestDataSource
        var lastResult: String?
        
        init(service: TestService, dataSource: TestDataSource) {
            self.service = service
            self.dataSource = dataSource
            super.init()
        }
        
        func performServiceAction(_ action: String) async throws {
            lastResult = try await service.performAction(action)
        }
    }
    
    // MARK: - @AutoMockable Tests
    
    func testAutoMockableGeneratesMock() throws {
        // This should fail - @AutoMockable doesn't exist yet
        let mockService = MockTestService()
        
        // Verify mock was generated with all protocol requirements
        XCTAssertNotNil(mockService.performActionMock)
        XCTAssertNotNil(mockService.getCountMock)
        XCTAssertNotNil(mockService.updateStateMock)
        XCTAssertNotNil(mockService.isActiveMock)
    }
    
    func testMockBehaviorConfiguration() async throws {
        // Test configuring mock behaviors
        let mockService = MockTestService()
        
        // Configure return value
        mockService.performActionMock.returns("Mocked Result")
        
        // Configure throwing error
        mockService.updateStateMock.throws(TestError.mockError)
        
        // Configure conditional behavior
        mockService.getCountMock.onCall { callCount in
            return callCount * 10
        }
        
        // Test configured behaviors
        let result = try await mockService.performAction("test")
        XCTAssertEqual(result, "Mocked Result")
        
        do {
            try await mockService.updateState(value: 42)
            XCTFail("Expected error to be thrown")
        } catch TestError.mockError {
            // Expected
        }
        
        let count1 = await mockService.getCount()
        let count2 = await mockService.getCount()
        XCTAssertEqual(count1, 10)
        XCTAssertEqual(count2, 20)
    }
    
    func testMockCallVerification() async throws {
        // Test verifying mock was called
        let mockService = MockTestService()
        mockService.performActionMock.returns("Result")
        
        // No calls yet
        XCTAssertFalse(mockService.performActionMock.wasCalled)
        XCTAssertEqual(mockService.performActionMock.callCount, 0)
        
        // Make a call
        _ = try await mockService.performAction("test")
        
        // Verify call
        XCTAssertTrue(mockService.performActionMock.wasCalled)
        XCTAssertEqual(mockService.performActionMock.callCount, 1)
        XCTAssertEqual(mockService.performActionMock.lastArguments, "test")
        
        // Make another call
        _ = try await mockService.performAction("another")
        
        // Verify multiple calls
        XCTAssertEqual(mockService.performActionMock.callCount, 2)
        XCTAssertEqual(mockService.performActionMock.allArguments, ["test", "another"])
    }
    
    func testMockSpyFunctionality() async throws {
        // Test spy functionality - records calls and passes through
        let realService = RealTestService()
        let spyService = SpyTestService(wrapping: realService)
        
        // Configure spy to pass through
        spyService.performActionMock.passThrough()
        
        // Call should pass through to real implementation
        let result = try await spyService.performAction("spy test")
        XCTAssertEqual(result, "Real: spy test")
        
        // But also record the call
        XCTAssertTrue(spyService.performActionMock.wasCalled)
        XCTAssertEqual(spyService.performActionMock.lastArguments, "spy test")
    }
    
    func testMockStubSequence() async throws {
        // Test stubbing a sequence of return values
        let mockService = MockTestService()
        
        mockService.getCountMock.returnsInSequence([1, 2, 3])
        
        let count1 = await mockService.getCount()
        let count2 = await mockService.getCount()
        let count3 = await mockService.getCount()
        let count4 = await mockService.getCount() // Should repeat last value
        
        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 2)
        XCTAssertEqual(count3, 3)
        XCTAssertEqual(count4, 3)
    }
    
    func testMockArgumentMatching() async throws {
        // Test argument matching for conditional behavior
        let mockDataSource = MockTestDataSource()
        
        // Configure different responses based on arguments
        mockDataSource.fetchDataMock.when { id in
            id == "special"
        }.returns(TestData(id: "special", value: "Special Data", timestamp: Date()))
        
        mockDataSource.fetchDataMock.whenNot { id in
            id == "special"
        }.returns(TestData(id: "default", value: "Default Data", timestamp: Date()))
        
        // Test matching
        let specialData = try await mockDataSource.fetchData(id: "special")
        XCTAssertEqual(specialData.value, "Special Data")
        
        let defaultData = try await mockDataSource.fetchData(id: "other")
        XCTAssertEqual(defaultData.value, "Default Data")
    }
    
    func testMockReset() async throws {
        // Test resetting mock state
        let mockService = MockTestService()
        mockService.performActionMock.returns("Result")
        
        _ = try await mockService.performAction("test")
        XCTAssertEqual(mockService.performActionMock.callCount, 1)
        
        // Reset mock
        mockService.reset()
        
        XCTAssertEqual(mockService.performActionMock.callCount, 0)
        XCTAssertFalse(mockService.performActionMock.wasCalled)
        XCTAssertNil(mockService.performActionMock.lastArguments)
    }
    
    func testMockInContextTesting() async throws {
        // Test using mocks in context testing
        let mockService = MockTestService()
        let mockDataSource = MockTestDataSource()
        
        // Configure mocks
        mockService.performActionMock.returns("Mocked Action Result")
        mockDataSource.fetchDataMock.returns(
            TestData(id: "1", value: "Test", timestamp: Date())
        )
        
        // Create context with mocks
        let context = TestContext(service: mockService, dataSource: mockDataSource)
        
        // Test context behavior with mocks
        try await context.performServiceAction("test action")
        
        XCTAssertEqual(context.lastResult, "Mocked Action Result")
        XCTAssertTrue(mockService.performActionMock.wasCalled)
        XCTAssertEqual(mockService.performActionMock.lastArguments, "test action")
    }
    
    func testMockDelayedResponse() async throws {
        // Test simulating delayed responses
        let mockService = MockTestService()
        
        mockService.performActionMock
            .returns("Delayed Result")
            .withDelay(.milliseconds(100))
        
        let start = ContinuousClock.now
        _ = try await mockService.performAction("test")
        let duration = ContinuousClock.now - start
        
        XCTAssertGreaterThan(duration, .milliseconds(90))
    }
    
    func testMockCallOrder() async throws {
        // Test verifying order of calls across multiple mocks
        let mockService = MockTestService()
        let mockDataSource = MockTestDataSource()
        
        mockService.performActionMock.returns("Result")
        mockDataSource.saveDataMock.returns()
        
        // Make calls in specific order
        _ = try await mockService.performAction("first")
        try await mockDataSource.saveData(TestData(id: "1", value: "test", timestamp: Date()))
        _ = try await mockService.performAction("second")
        
        // Verify call order
        let callOrder = MockCallOrderVerifier()
            .verify(mockService.performActionMock, was: .calledBefore(mockDataSource.saveDataMock))
            .verify(mockDataSource.saveDataMock, was: .calledBefore(mockService.performActionMock, onCall: 2))
        
        XCTAssertTrue(callOrder.isValid)
    }
    
    func testMockPropertyStubbing() async throws {
        // Test stubbing async properties
        let mockService = MockTestService()
        
        mockService.isActiveMock.returns(true)
        
        let isActive = await mockService.isActive
        XCTAssertTrue(isActive)
        XCTAssertTrue(mockService.isActiveMock.wasCalled)
    }
    
    func testPartialMocking() async throws {
        // Test partial mocking - some methods mocked, others real
        let partialMock = PartialMockTestService()
        
        // Mock only specific methods
        partialMock.mockOnly(.performAction)
        partialMock.performActionMock.returns("Mocked")
        
        // This should be mocked
        let mockedResult = try await partialMock.performAction("test")
        XCTAssertEqual(mockedResult, "Mocked")
        
        // This should use real implementation
        let realCount = await partialMock.getCount()
        XCTAssertEqual(realCount, 42) // Real implementation returns 42
    }
    
    // MARK: - Helper Types
    
    enum TestError: Error {
        case mockError
        case testError(String)
    }
    
    // Real implementation for spy testing
    class RealTestService: TestService {
        func performAction(_ action: String) async throws -> String {
            return "Real: \(action)"
        }
        
        func getCount() async -> Int {
            return 42
        }
        
        func updateState(value: Int) async throws {
            // Real implementation
        }
        
        var isActive: Bool {
            get async { true }
        }
    }
}

// MARK: - Expected Mock Generation

/*
The @AutoMockable macro should generate mocks like:

class MockTestService: TestService {
    let performActionMock = MockMethod<String, String>()
    let getCountMock = MockMethod<Void, Int>()
    let updateStateMock = MockMethod<Int, Void>()
    let isActiveMock = MockProperty<Bool>()
    
    func performAction(_ action: String) async throws -> String {
        try await performActionMock.call(with: action)
    }
    
    func getCount() async -> Int {
        await getCountMock.call()
    }
    
    func updateState(value: Int) async throws {
        try await updateStateMock.call(with: value)
    }
    
    var isActive: Bool {
        get async {
            await isActiveMock.get()
        }
    }
    
    func reset() {
        performActionMock.reset()
        getCountMock.reset()
        updateStateMock.reset()
        isActiveMock.reset()
    }
}

The MockMethod type should support:
- returns(_:) - Set return value
- throws(_:) - Set error to throw
- onCall(_:) - Dynamic behavior based on call count
- wasCalled - Check if called
- callCount - Number of calls
- lastArguments - Last call arguments
- allArguments - All call arguments
- passThrough() - Spy functionality
- returnsInSequence(_:) - Return different values
- when(_:) - Conditional behavior
- withDelay(_:) - Simulate delays
*/