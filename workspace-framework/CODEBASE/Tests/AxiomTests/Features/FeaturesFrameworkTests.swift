import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Framework Features functionality
/// Tests async utilities, form bindings, launch actions, and other features using AxiomTesting framework
final class FeaturesFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Async Testing Utilities Tests
    
    func testAsyncStateCollectionUtilities() async throws {
        try await testEnvironment.runTest { env in
            let client = try await env.createClient(
                AsyncTestClient.self,
                id: "state-collection-client"
            ) {
                AsyncTestClient(initialState: TestFeatureState(count: 0))
            }
            
            // Test collecting states using framework utilities
            let states = try await TestHelpers.async.collectStates(
                from: client,
                count: 4,
                timeout: .seconds(1)
            ) { client in
                try await client.process(.setValue(1))
                try await client.process(.setValue(2))
                try await client.process(.setValue(3))
            }
            
            // Verify all states were collected
            XCTAssertEqual(states.count, 4)
            XCTAssertEqual(states[0].count, 0) // Initial state
            XCTAssertEqual(states[1].count, 1)
            XCTAssertEqual(states[2].count, 2)
            XCTAssertEqual(states[3].count, 3)
        }
    }
    
    func testAsyncStateWaitCondition() async throws {
        try await testEnvironment.runTest { env in
            let client = try await env.createClient(
                AsyncTestClient.self,
                id: "wait-condition-client"
            ) {
                AsyncTestClient(initialState: TestFeatureState(count: 0))
            }
            
            // Start async operation that will change state
            Task {
                try await Task.sleep(for: .milliseconds(50))
                try await client.process(.setValue(10))
            }
            
            // Wait for specific state using framework utilities
            let foundState = try await TestHelpers.async.waitForState(
                in: client,
                timeout: .seconds(1)
            ) { state in
                state.count == 10
            }
            
            XCTAssertEqual(foundState.count, 10)
        }
    }
    
    func testAsyncStateSequenceValidation() async throws {
        try await testEnvironment.runTest { env in
            let client = try await env.createClient(
                AsyncTestClient.self,
                id: "sequence-client"
            ) {
                AsyncTestClient(initialState: TestFeatureState(count: 0))
            }
            
            // Test state sequence validation using framework utilities
            try await TestHelpers.async.assertStateSequence(
                from: client,
                timeout: .seconds(1),
                sequence: [
                    { $0.count == 0 }, // Initial
                    { $0.count == 1 },
                    { $0.count == 2 },
                    { $0.count == 3 }
                ]
            ) { client in
                try await client.process(.increment)
                try await client.process(.increment)
                try await client.process(.increment)
            }
        }
    }
    
    func testAsyncActionRecording() async throws {
        try await testEnvironment.runTest { env in
            let recorder = TestActionRecorder<TestFeatureAction>()
            let client = try await env.createClient(
                AsyncTestClient.self,
                id: "action-recording-client"
            ) {
                AsyncTestClient(
                    initialState: TestFeatureState(count: 0),
                    actionRecorder: recorder
                )
            }
            
            // Perform actions and verify recording
            try await client.process(.increment)
            try await client.process(.setValue(42))
            try await client.process(.decrement)
            
            // Verify actions were recorded using framework utilities
            try await TestHelpers.async.assertActionSequence(
                in: recorder,
                timeout: .seconds(1),
                expectedSequence: [.increment, .setValue(42), .decrement]
            )
        }
    }
    
    func testAsyncTimingUtilities() async throws {
        try await testEnvironment.runTest { env in
            // Test timing utilities performance
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    var conditionMet = false
                    
                    Task {
                        try await Task.sleep(for: .milliseconds(50))
                        conditionMet = true
                    }
                    
                    // Use framework timing utilities
                    try await TestHelpers.async.waitUntilCondition(
                        timeout: .seconds(1),
                        pollingInterval: .milliseconds(10)
                    ) {
                        conditionMet
                    }
                    
                    XCTAssertTrue(conditionMet)
                },
                maxDuration: .milliseconds(200), // Should complete quickly
                maxMemoryGrowth: 1024, // 1KB max growth
                iterations: 1
            )
        }
    }
    
    // MARK: - Form Binding Utilities Tests
    
    func testOptionalStringBinding() async throws {
        try await testEnvironment.runTest { env in
            var optionalValue: String? = nil
            let binding = Binding(
                get: { optionalValue },
                set: { optionalValue = $0 }
            )
            
            // Test optional binding utilities using framework
            let nonOptionalBinding = TestHelpers.forms.createOptionalBinding(
                from: binding,
                emptyValue: ""
            )
            
            // Test nil handling
            XCTAssertEqual(nonOptionalBinding.wrappedValue, "")
            
            // Test empty string to nil conversion
            nonOptionalBinding.wrappedValue = ""
            XCTAssertNil(optionalValue)
            
            // Test value passing
            nonOptionalBinding.wrappedValue = "Hello"
            XCTAssertEqual(optionalValue, "Hello")
        }
    }
    
    func testOptionalNumericBinding() async throws {
        try await testEnvironment.runTest { env in
            var optionalValue: Int? = nil
            let binding = Binding(
                get: { optionalValue },
                set: { optionalValue = $0 }
            )
            
            // Test numeric optional binding using framework utilities
            let nonOptionalBinding = TestHelpers.forms.createOptionalBinding(
                from: binding,
                defaultValue: 0
            )
            
            // Test nil -> default value
            XCTAssertEqual(nonOptionalBinding.wrappedValue, 0)
            
            // Test value assignment
            nonOptionalBinding.wrappedValue = 42
            XCTAssertEqual(optionalValue, 42)
            
            // Test zero should not become nil (unlike empty string)
            nonOptionalBinding.wrappedValue = 0
            XCTAssertEqual(optionalValue, 0)
        }
    }
    
    func testFormValidationUtilities() async throws {
        try await testEnvironment.runTest { env in
            // Test validation using framework utilities
            let requiredValidator = TestHelpers.forms.createValidator(.required)
            let emailValidator = TestHelpers.forms.createValidator(.email)
            let minLengthValidator = TestHelpers.forms.createValidator(.minLength(5))
            
            // Test required validation
            var result = requiredValidator("")
            XCTAssertFalse(result.isValid)
            XCTAssertEqual(result.errorMessage, "This field is required")
            
            result = requiredValidator("Hello")
            XCTAssertTrue(result.isValid)
            
            // Test email validation
            result = emailValidator("not-an-email")
            XCTAssertFalse(result.isValid)
            
            result = emailValidator("test@example.com")
            XCTAssertTrue(result.isValid)
            
            // Test min length validation
            result = minLengthValidator("Hi")
            XCTAssertFalse(result.isValid)
            XCTAssertEqual(result.errorMessage, "Must be at least 5 characters")
            
            result = minLengthValidator("Hello World")
            XCTAssertTrue(result.isValid)
        }
    }
    
    func testFormFormatHelpers() async throws {
        try await testEnvironment.runTest { env in
            // Test phone number formatting using framework utilities
            let phoneFormatter = TestHelpers.forms.createFormatter(.phoneNumber)
            
            let formatted = phoneFormatter.format("5551234567")
            XCTAssertEqual(formatted, "(555) 123-4567")
            
            // Test phone number validation
            XCTAssertTrue(phoneFormatter.isValid("555-123-4567"))
            XCTAssertTrue(phoneFormatter.isValid("(555) 123-4567"))
            XCTAssertTrue(phoneFormatter.isValid("+1 555 123 4567"))
            XCTAssertFalse(phoneFormatter.isValid("abc-def-ghij"))
            
            // Test email validation
            let emailValidator = TestHelpers.forms.createFormatter(.email)
            XCTAssertTrue(emailValidator.isValid("test@example.com"))
            XCTAssertTrue(emailValidator.isValid("user.name+tag@example.co.uk"))
            XCTAssertFalse(emailValidator.isValid("not-an-email"))
            XCTAssertFalse(emailValidator.isValid("@example.com"))
            XCTAssertFalse(emailValidator.isValid("test@"))
        }
    }
    
    func testFormBindingPerformance() async throws {
        try await testEnvironment.runTest { env in
            // Test form binding performance under load
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Create many bindings and validate them
                    for i in 0..<100 {
                        var value: String? = nil
                        let binding = Binding(
                            get: { value },
                            set: { value = $0 }
                        )
                        
                        let nonOptionalBinding = TestHelpers.forms.createOptionalBinding(
                            from: binding,
                            emptyValue: ""
                        )
                        
                        // Perform binding operations
                        nonOptionalBinding.wrappedValue = "Test \(i)"
                        let validator = TestHelpers.forms.createValidator(.required)
                        let result = validator(nonOptionalBinding.wrappedValue)
                        XCTAssertTrue(result.isValid)
                    }
                },
                maxDuration: .milliseconds(100), // Should be fast
                maxMemoryGrowth: 5 * 1024, // 5KB max growth
                iterations: 1
            )
        }
    }
    
    // MARK: - Launch Action Tests
    
    func testLaunchActionPropertyWrapper() async throws {
        try await testEnvironment.runTest { env in
            let launchActionManager = TestLaunchActionManager<TestQuickAction>()
            
            // Test action queuing before ready using framework utilities
            let testAction = TestQuickAction(identifier: "test.action", value: "test")
            await launchActionManager.queueAction(testAction)
            
            // Action should be queued, not immediately available
            XCTAssertNil(await launchActionManager.currentAction)
            
            // Mark ready and verify action becomes available
            await launchActionManager.markReady()
            
            try await TestHelpers.context.assertState(
                in: launchActionManager,
                timeout: .seconds(1),
                condition: { _ in launchActionManager.currentAction == testAction },
                description: "Action should become available after marking ready"
            )
        }
    }
    
    func testMultipleActionsQueuing() async throws {
        try await testEnvironment.runTest { env in
            let launchActionManager = TestLaunchActionManager<TestQuickAction>()
            
            // Queue multiple actions before ready
            let action1 = TestQuickAction(identifier: "test.1", value: "first")
            let action2 = TestQuickAction(identifier: "test.2", value: "second")
            let action3 = TestQuickAction(identifier: "test.3", value: "third")
            
            await launchActionManager.queueAction(action1)
            await launchActionManager.queueAction(action2)
            await launchActionManager.queueAction(action3)
            
            // No action should be current yet
            XCTAssertNil(await launchActionManager.currentAction)
            
            // Mark ready and verify sequential processing
            await launchActionManager.markReady()
            
            // First action should be processed immediately
            try await TestHelpers.context.assertState(
                in: launchActionManager,
                condition: { _ in launchActionManager.currentAction == action1 },
                description: "First action should be processed immediately"
            )
            
            // Subsequent actions should be processed with delay
            try await TestHelpers.context.assertState(
                in: launchActionManager,
                timeout: .seconds(1),
                condition: { _ in launchActionManager.currentAction == action2 },
                description: "Second action should be processed after delay"
            )
            
            try await TestHelpers.context.assertState(
                in: launchActionManager,
                timeout: .seconds(1),
                condition: { _ in launchActionManager.currentAction == action3 },
                description: "Third action should be processed after delay"
            )
        }
    }
    
    func testColdLaunchSimulation() async throws {
        try await testEnvironment.runTest { env in
            // Test cold launch scenario using framework utilities
            try await TestHelpers.launchActions.simulateColdLaunch(
                actionType: TestQuickAction.self,
                action: TestQuickAction(identifier: "test.cold", value: "cold-launch"),
                appInitializationDelay: .milliseconds(200)
            ) { manager, action in
                // Verify action was queued before ready
                XCTAssertNil(await manager.currentAction)
                
                // Verify action becomes available after marking ready
                try await TestHelpers.context.assertState(
                    in: manager,
                    timeout: .seconds(1),
                    condition: { _ in manager.currentAction == action },
                    description: "Action should be processed after cold launch initialization"
                )
            }
        }
    }
    
    func testURLLaunchAction() async throws {
        try await testEnvironment.runTest { env in
            let url = URL(string: "myapp://task/123")!
            let urlAction = TestURLLaunchAction(url: url)
            
            // Test URL launch action properties
            XCTAssertEqual(urlAction.identifier, "com.app.url")
            XCTAssertEqual(urlAction.url, url)
            
            // Test route parsing (should be nil without parser)
            XCTAssertNil(urlAction.toRoute())
            
            // Test with route parser
            let actionWithParser = TestURLLaunchAction(
                url: url,
                routeParser: { url in
                    TestRoute.task(id: url.lastPathComponent)
                }
            )
            
            let route = actionWithParser.toRoute()
            XCTAssertNotNil(route)
            if case .task(let id) = route as? TestRoute {
                XCTAssertEqual(id, "123")
            } else {
                XCTFail("Expected task route with id 123")
            }
        }
    }
    
    func testLaunchActionPerformance() async throws {
        try await testEnvironment.runTest { env in
            // Test launch action performance with many actions
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    let manager = TestLaunchActionManager<TestQuickAction>()
                    
                    // Queue many actions quickly
                    for i in 0..<50 {
                        let action = TestQuickAction(
                            identifier: "test.perf.\(i)",
                            value: "performance-\(i)"
                        )
                        await manager.queueAction(action)
                    }
                    
                    // Mark ready and verify processing
                    await manager.markReady()
                    
                    // Verify first action is processed
                    XCTAssertNotNil(await manager.currentAction)
                },
                maxDuration: .milliseconds(200), // Should queue and start quickly
                maxMemoryGrowth: 10 * 1024, // 10KB max growth
                iterations: 1
            )
        }
    }
    
    func testLaunchActionMemoryManagement() async throws {
        try await testEnvironment.runTest { env in
            // Test memory management of launch actions
            try await TestHelpers.context.assertNoMemoryLeaks {
                var manager: TestLaunchActionManager<TestQuickAction>? = TestLaunchActionManager()
                
                // Queue actions
                for i in 0..<10 {
                    let action = TestQuickAction(
                        identifier: "test.memory.\(i)",
                        value: "memory-\(i)"
                    )
                    await manager?.queueAction(action)
                }
                
                await manager?.markReady()
                
                // Clear reference
                manager = nil
                
                // Allow cleanup
                try await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    // MARK: - Feature Integration Tests
    
    func testAsyncFormValidationIntegration() async throws {
        try await testEnvironment.runTest { env in
            let client = try await env.createClient(
                FormValidationTestClient.self,
                id: "form-validation-client"
            ) {
                FormValidationTestClient()
            }
            
            // Test async form validation using framework utilities
            try await client.process(.validateField("email", value: "invalid-email"))
            
            // Wait for validation result using async utilities
            let validationState = try await TestHelpers.async.waitForState(
                in: client,
                timeout: .seconds(1)
            ) { state in
                state.validationResults["email"] != nil
            }
            
            // Verify validation failed
            let emailResult = validationState.validationResults["email"]
            XCTAssertNotNil(emailResult)
            XCTAssertFalse(emailResult!.isValid)
            
            // Test valid email
            try await client.process(.validateField("email", value: "test@example.com"))
            
            let validState = try await TestHelpers.async.waitForState(
                in: client,
                timeout: .seconds(1)
            ) { state in
                state.validationResults["email"]?.isValid == true
            }
            
            XCTAssertTrue(validState.validationResults["email"]!.isValid)
        }
    }
    
    func testLaunchActionWithAsyncProcessing() async throws {
        try await testEnvironment.runTest { env in
            let manager = TestLaunchActionManager<TestQuickAction>()
            let actionProcessor = try await env.createContext(
                LaunchActionProcessorContext.self,
                id: "action-processor"
            ) {
                LaunchActionProcessorContext(manager: manager)
            }
            
            // Queue action and mark ready
            let action = TestQuickAction(identifier: "test.async", value: "async-processing")
            await manager.queueAction(action)
            await manager.markReady()
            
            // Verify action is processed asynchronously
            try await TestHelpers.context.assertState(
                in: actionProcessor,
                timeout: .seconds(1),
                condition: { _ in actionProcessor.processedActions.contains(action) },
                description: "Action should be processed asynchronously"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testFeaturesFrameworkCompliance() async throws {
        let asyncClient = AsyncTestClient(initialState: TestFeatureState(count: 0))
        let formClient = FormValidationTestClient()
        let launchManager = TestLaunchActionManager<TestQuickAction>()
        
        // Use framework compliance testing
        assertFrameworkCompliance(asyncClient)
        assertFrameworkCompliance(formClient)
        assertFrameworkCompliance(launchManager)
        
        // Features specific compliance
        XCTAssertTrue(asyncClient is Client, "Must implement Client protocol")
        XCTAssertTrue(formClient is Client, "Must implement Client protocol")
    }
}

// MARK: - Test Support Types

// Test Feature State
struct TestFeatureState: State, Equatable, Sendable {
    let count: Int
    let lastOperation: String
    
    init(count: Int, lastOperation: String = "") {
        self.count = count
        self.lastOperation = lastOperation
    }
}

// Test Feature Actions
enum TestFeatureAction: Equatable {
    case increment
    case decrement
    case setValue(Int)
    case setOperation(String)
}

// Async Test Client
actor AsyncTestClient: Client {
    typealias StateType = TestFeatureState
    typealias ActionType = TestFeatureAction
    
    private(set) var currentState: TestFeatureState
    private let stream: AsyncStream<TestFeatureState>
    private let continuation: AsyncStream<TestFeatureState>.Continuation
    private weak var actionRecorder: TestActionRecorder<TestFeatureAction>?
    
    var stateStream: AsyncStream<TestFeatureState> {
        stream
    }
    
    var id: String { "async-test-client" }
    
    init(initialState: TestFeatureState, actionRecorder: TestActionRecorder<TestFeatureAction>? = nil) {
        self.currentState = initialState
        self.actionRecorder = actionRecorder
        (stream, continuation) = AsyncStream.makeStream(of: TestFeatureState.self)
        continuation.yield(currentState)
    }
    
    func process(_ action: TestFeatureAction) async throws {
        await actionRecorder?.record(action)
        
        switch action {
        case .increment:
            currentState = TestFeatureState(
                count: currentState.count + 1,
                lastOperation: "increment"
            )
        case .decrement:
            currentState = TestFeatureState(
                count: currentState.count - 1,
                lastOperation: "decrement"
            )
        case .setValue(let value):
            currentState = TestFeatureState(
                count: value,
                lastOperation: "setValue(\(value))"
            )
        case .setOperation(let operation):
            currentState = TestFeatureState(
                count: currentState.count,
                lastOperation: operation
            )
        }
        
        continuation.yield(currentState)
    }
    
    deinit {
        continuation.finish()
    }
}

// Test Action Recorder
@MainActor
class TestActionRecorder<Action: Equatable> {
    private(set) var recordedActions: [Action] = []
    
    func record(_ action: Action) {
        recordedActions.append(action)
    }
    
    func reset() {
        recordedActions.removeAll()
    }
    
    func assertCount(_ expectedCount: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(recordedActions.count, expectedCount, file: file, line: line)
    }
    
    func assertSequence(_ expectedSequence: [Action], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(recordedActions, expectedSequence, file: file, line: line)
    }
}

// Test Quick Action
struct TestQuickAction: QuickAction, Equatable {
    let identifier: String
    let value: String
    
    func toRoute() -> Route? {
        nil
    }
}

// Test URL Launch Action
struct TestURLLaunchAction: QuickAction {
    let url: URL
    private let routeParser: ((URL) -> Route?)?
    
    var identifier: String { "com.app.url" }
    
    init(url: URL, routeParser: ((URL) -> Route?)? = nil) {
        self.url = url
        self.routeParser = routeParser
    }
    
    func toRoute() -> Route? {
        return routeParser?(url)
    }
}

// Test Route
enum TestRoute: Route {
    case task(id: String)
    case home
}

// Test Launch Action Manager
@MainActor
class TestLaunchActionManager<Action: QuickAction & Equatable> {
    private(set) var currentAction: Action?
    private var queuedActions: [Action] = []
    private var isReady: Bool = false
    private var processingTask: Task<Void, Never>?
    
    func queueAction(_ action: Action) {
        if isReady {
            currentAction = action
        } else {
            queuedActions.append(action)
        }
    }
    
    func markReady() {
        isReady = true
        processQueuedActions()
    }
    
    func clearAction() {
        currentAction = nil
    }
    
    private func processQueuedActions() {
        guard !queuedActions.isEmpty else { return }
        
        processingTask = Task { [weak self] in
            guard let self = self else { return }
            
            for (index, action) in await self.queuedActions.enumerated() {
                if index == 0 {
                    // Process first action immediately
                    await MainActor.run {
                        self.currentAction = action
                    }
                } else {
                    // Process subsequent actions with delay
                    try? await Task.sleep(for: .milliseconds(100))
                    await MainActor.run {
                        self.currentAction = action
                    }
                }
            }
            
            await MainActor.run {
                self.queuedActions.removeAll()
            }
        }
    }
    
    deinit {
        processingTask?.cancel()
    }
}

// Form Validation Test State
struct FormValidationTestState: State, Equatable, Sendable {
    let validationResults: [String: ValidationResult]
    
    init(validationResults: [String: ValidationResult] = [:]) {
        self.validationResults = validationResults
    }
}

// Form Validation Test Actions
enum FormValidationTestAction: Equatable {
    case validateField(String, value: String)
    case clearValidation(String)
}

// Validation Result
struct ValidationResult: Equatable, Sendable {
    let isValid: Bool
    let errorMessage: String?
    
    init(isValid: Bool, errorMessage: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

// Form Validation Test Client
actor FormValidationTestClient: Client {
    typealias StateType = FormValidationTestState
    typealias ActionType = FormValidationTestAction
    
    private(set) var currentState: FormValidationTestState
    private let stream: AsyncStream<FormValidationTestState>
    private let continuation: AsyncStream<FormValidationTestState>.Continuation
    
    var stateStream: AsyncStream<FormValidationTestState> {
        stream
    }
    
    var id: String { "form-validation-client" }
    
    init() {
        self.currentState = FormValidationTestState()
        (stream, continuation) = AsyncStream.makeStream(of: FormValidationTestState.self)
        continuation.yield(currentState)
    }
    
    func process(_ action: FormValidationTestAction) async throws {
        switch action {
        case .validateField(let field, let value):
            let result = validateField(field, value: value)
            var validationResults = currentState.validationResults
            validationResults[field] = result
            
            currentState = FormValidationTestState(validationResults: validationResults)
            continuation.yield(currentState)
            
        case .clearValidation(let field):
            var validationResults = currentState.validationResults
            validationResults.removeValue(forKey: field)
            
            currentState = FormValidationTestState(validationResults: validationResults)
            continuation.yield(currentState)
        }
    }
    
    private func validateField(_ field: String, value: String) -> ValidationResult {
        switch field {
        case "email":
            return validateEmail(value)
        case "password":
            return validatePassword(value)
        default:
            return validateRequired(value)
        }
    }
    
    private func validateEmail(_ value: String) -> ValidationResult {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: value)
        
        return ValidationResult(
            isValid: isValid,
            errorMessage: isValid ? nil : "Please enter a valid email address"
        )
    }
    
    private func validatePassword(_ value: String) -> ValidationResult {
        let isValid = value.count >= 8
        return ValidationResult(
            isValid: isValid,
            errorMessage: isValid ? nil : "Password must be at least 8 characters"
        )
    }
    
    private func validateRequired(_ value: String) -> ValidationResult {
        let isValid = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ValidationResult(
            isValid: isValid,
            errorMessage: isValid ? nil : "This field is required"
        )
    }
    
    deinit {
        continuation.finish()
    }
}

// Launch Action Processor Context
@MainActor
class LaunchActionProcessorContext: ObservableContext {
    private let manager: TestLaunchActionManager<TestQuickAction>
    private(set) var processedActions: Set<TestQuickAction> = []
    private var observationTask: Task<Void, Never>?
    
    init(manager: TestLaunchActionManager<TestQuickAction>) {
        self.manager = manager
        super.init()
        startObservingActions()
    }
    
    private func startObservingActions() {
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                if let action = await self?.manager.currentAction,
                   let self = self,
                   !self.processedActions.contains(action) {
                    await MainActor.run {
                        self.processedActions.insert(action)
                    }
                    await self.manager.clearAction()
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

// MARK: - Framework Extensions

// TestHelpers extensions for Features
extension TestHelpers {
    struct AsyncUtilities {
        /// Collect states from a client
        static func collectStates<C: Client>(
            from client: C,
            count: Int,
            timeout: Duration = .seconds(1),
            operation: (C) async throws -> Void
        ) async throws -> [C.StateType] {
            var states: [C.StateType] = []
            let task = Task {
                for await state in await client.stateStream {
                    states.append(state)
                    if states.count >= count {
                        break
                    }
                }
            }
            
            try await operation(client)
            
            let startTime = Date()
            while states.count < count && Date().timeIntervalSince(startTime) < timeout.timeInterval {
                try await Task.sleep(for: .milliseconds(10))
            }
            
            task.cancel()
            
            if states.count < count {
                throw AsyncTestError.timeout("Collected \(states.count) of \(count) states")
            }
            
            return states
        }
        
        /// Wait for a specific state condition
        static func waitForState<C: Client>(
            in client: C,
            timeout: Duration = .seconds(1),
            condition: @escaping (C.StateType) -> Bool
        ) async throws -> C.StateType {
            let startTime = Date()
            
            for await state in await client.stateStream {
                if condition(state) {
                    return state
                }
                
                if Date().timeIntervalSince(startTime) > timeout.timeInterval {
                    break
                }
            }
            
            throw AsyncTestError.timeout("State condition not met within timeout")
        }
        
        /// Assert state sequence
        static func assertStateSequence<C: Client>(
            from client: C,
            timeout: Duration = .seconds(1),
            sequence: [(C.StateType) -> Bool],
            operation: (C) async throws -> Void
        ) async throws {
            var sequenceIndex = 0
            var states: [C.StateType] = []
            
            let task = Task {
                for await state in await client.stateStream {
                    states.append(state)
                    if sequenceIndex < sequence.count && sequence[sequenceIndex](state) {
                        sequenceIndex += 1
                    }
                    if sequenceIndex >= sequence.count {
                        break
                    }
                }
            }
            
            try await operation(client)
            
            let startTime = Date()
            while sequenceIndex < sequence.count && Date().timeIntervalSince(startTime) < timeout.timeInterval {
                try await Task.sleep(for: .milliseconds(10))
            }
            
            task.cancel()
            
            if sequenceIndex < sequence.count {
                throw AsyncTestError.sequenceIncomplete("Completed \(sequenceIndex) of \(sequence.count) sequence steps")
            }
        }
        
        /// Assert action sequence
        static func assertActionSequence<Action: Equatable>(
            in recorder: TestActionRecorder<Action>,
            timeout: Duration = .seconds(1),
            expectedSequence: [Action]
        ) async throws {
            let startTime = Date()
            
            while await recorder.recordedActions.count < expectedSequence.count &&
                  Date().timeIntervalSince(startTime) < timeout.timeInterval {
                try await Task.sleep(for: .milliseconds(10))
            }
            
            await recorder.assertSequence(expectedSequence)
        }
        
        /// Wait until condition
        static func waitUntilCondition(
            timeout: Duration = .seconds(1),
            pollingInterval: Duration = .milliseconds(10),
            condition: @escaping () -> Bool
        ) async throws {
            let startTime = Date()
            
            while !condition() && Date().timeIntervalSince(startTime) < timeout.timeInterval {
                try await Task.sleep(for: pollingInterval)
            }
            
            if !condition() {
                throw AsyncTestError.timeout("Condition not met within timeout")
            }
        }
    }
    
    struct Forms {
        /// Create optional binding
        static func createOptionalBinding<T>(
            from binding: Binding<T?>,
            emptyValue: T
        ) -> Binding<T> where T: Equatable {
            Binding<T>(
                get: { binding.wrappedValue ?? emptyValue },
                set: { newValue in
                    if newValue == emptyValue && T.self == String.self {
                        binding.wrappedValue = nil
                    } else {
                        binding.wrappedValue = newValue
                    }
                }
            )
        }
        
        /// Create optional binding with default value
        static func createOptionalBinding<T>(
            from binding: Binding<T?>,
            defaultValue: T
        ) -> Binding<T> {
            Binding<T>(
                get: { binding.wrappedValue ?? defaultValue },
                set: { binding.wrappedValue = $0 }
            )
        }
        
        /// Create validator
        static func createValidator(_ type: ValidationType) -> (String) -> ValidationResult {
            switch type {
            case .required:
                return { value in
                    let isValid = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    return ValidationResult(
                        isValid: isValid,
                        errorMessage: isValid ? nil : "This field is required"
                    )
                }
            case .email:
                return { value in
                    let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
                    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                    let isValid = emailPredicate.evaluate(with: value)
                    return ValidationResult(
                        isValid: isValid,
                        errorMessage: isValid ? nil : "Please enter a valid email address"
                    )
                }
            case .minLength(let length):
                return { value in
                    let isValid = value.count >= length
                    return ValidationResult(
                        isValid: isValid,
                        errorMessage: isValid ? nil : "Must be at least \(length) characters"
                    )
                }
            }
        }
        
        /// Create formatter
        static func createFormatter(_ type: FormatterType) -> FormFormatter {
            switch type {
            case .phoneNumber:
                return PhoneNumberFormatter()
            case .email:
                return EmailFormatter()
            }
        }
    }
    
    struct LaunchActions {
        /// Simulate cold launch
        static func simulateColdLaunch<Action: QuickAction & Equatable>(
            actionType: Action.Type,
            action: Action,
            appInitializationDelay: Duration,
            test: (TestLaunchActionManager<Action>, Action) async throws -> Void
        ) async throws {
            let manager = TestLaunchActionManager<Action>()
            
            // Queue action before ready (simulating cold launch)
            await manager.queueAction(action)
            
            // Simulate app initialization delay
            try await Task.sleep(for: appInitializationDelay)
            
            // Mark ready and run test
            await manager.markReady()
            try await test(manager, action)
        }
    }
}

extension TestHelpers {
    static let async = AsyncUtilities.self
    static let forms = Forms.self
    static let launchActions = LaunchActions.self
}

// Supporting Enums and Types
enum ValidationType {
    case required
    case email
    case minLength(Int)
}

enum FormatterType {
    case phoneNumber
    case email
}

protocol FormFormatter {
    func format(_ input: String) -> String
    func isValid(_ input: String) -> Bool
}

struct PhoneNumberFormatter: FormFormatter {
    func format(_ input: String) -> String {
        let digits = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard digits.count == 10 else { return input }
        return "(\(digits.prefix(3))) \(digits.dropFirst(3).prefix(3))-\(digits.suffix(4))"
    }
    
    func isValid(_ input: String) -> Bool {
        let phoneRegex = "^\\+?1?[-\\s\\(\\)]?[0-9]{3}[-\\s\\)]?[0-9]{3}[-\\s]?[0-9]{4}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: input)
    }
}

struct EmailFormatter: FormFormatter {
    func format(_ input: String) -> String {
        return input.lowercased()
    }
    
    func isValid(_ input: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: input)
    }
}

// Quick Action Protocol
protocol QuickAction {
    var identifier: String { get }
    func toRoute() -> Route?
}

// Route Protocol
protocol Route {}

// Async Test Error
enum AsyncTestError: Error {
    case timeout(String)
    case sequenceIncomplete(String)
    case eventuallyFailed(String)
}

// Helper Extensions
private extension Duration {
    var timeInterval: TimeInterval {
        Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}