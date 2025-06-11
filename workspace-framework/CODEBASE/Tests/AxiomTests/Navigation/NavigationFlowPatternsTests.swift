import XCTest
@testable import Axiom

final class NavigationFlowPatternsTests: XCTestCase {
    
    // MARK: - RED Phase Tests for NavigationFlow Protocol System
    
    func testNavigationFlowProtocolDefinition() throws {
        // Test basic NavigationFlow protocol implementation
        struct OnboardingFlow: NavigationFlow {
            let identifier: String = "onboarding"
            let steps: [FlowStep] = [
                WelcomeStep(),
                ProfileStep(),
                PreferencesStep()
            ]
            
            var metadata: FlowMetadata {
                FlowMetadata(
                    title: "User Onboarding",
                    description: "Complete your profile setup",
                    estimatedDuration: 300
                )
            }
        }
        
        let flow = OnboardingFlow()
        XCTAssertEqual(flow.identifier, "onboarding")
        XCTAssertEqual(flow.steps.count, 3)
        XCTAssertEqual(flow.metadata.title, "User Onboarding")
        XCTAssertEqual(flow.metadata.estimatedDuration, 300)
    }
    
    func testFlowStepProtocolDefinition() throws {
        // Test FlowStep protocol with validation and state management
        struct WelcomeStep: FlowStep {
            let identifier: String = "welcome"
            let isRequired: Bool = true
            let canSkip: Bool = false
            let order: Int = 0
            
            func validate(data: FlowData) -> ValidationResult {
                return .success
            }
            
            func onEnter(data: FlowData) async {
                // Setup step state
            }
            
            func onExit(data: FlowData) async throws {
                // Validate and save step data
            }
        }
        
        struct ProfileStep: FlowStep {
            let identifier: String = "profile"
            let isRequired: Bool = true
            let canSkip: Bool = false
            let order: Int = 1
            
            func validate(data: FlowData) -> ValidationResult {
                guard let profile = data.get("profile") as? UserProfile,
                      profile.isComplete else {
                    return .failure(message: "Profile must be complete")
                }
                return .success
            }
            
            func onEnter(data: FlowData) async {
                // Initialize profile editing
            }
            
            func onExit(data: FlowData) async throws {
                // Validate profile completion
                let result = validate(data: data)
                if case .failure(let message) = result {
                    throw FlowError.validationFailed(message)
                }
            }
        }
        
        let welcomeStep = WelcomeStep()
        let profileStep = ProfileStep()
        
        XCTAssertEqual(welcomeStep.identifier, "welcome")
        XCTAssertTrue(welcomeStep.isRequired)
        XCTAssertFalse(welcomeStep.canSkip)
        
        XCTAssertEqual(profileStep.identifier, "profile")
        XCTAssertTrue(profileStep.isRequired)
        
        // Test validation
        let emptyData = FlowData()
        let welcomeResult = welcomeStep.validate(data: emptyData)
        XCTAssertEqual(welcomeResult, .success)
        
        let profileResult = profileStep.validate(data: emptyData)
        if case .failure(let message) = profileResult {
            XCTAssertEqual(message, "Profile must be complete")
        } else {
            XCTFail("Expected validation failure")
        }
    }
    
    func testFlowCoordinatorLifecycleManagement() async throws {
        // Test FlowCoordinator for managing flow lifecycle
        struct TestFlow: NavigationFlow {
            let identifier: String = "test"
            let steps: [FlowStep] = [
                SimpleStep(id: "step1", order: 0),
                SimpleStep(id: "step2", order: 1),
                SimpleStep(id: "step3", order: 2)
            ]
            
            var metadata: FlowMetadata {
                FlowMetadata(title: "Test Flow", description: "Test", estimatedDuration: 60)
            }
        }
        
        let flow = TestFlow()
        let coordinator = FlowCoordinator(flow: flow)
        
        // Test initial state
        XCTAssertEqual(coordinator.currentStepIndex, -1)
        XCTAssertNil(coordinator.currentStep)
        XCTAssertEqual(coordinator.flowState, .notStarted)
        XCTAssertEqual(coordinator.progress, 0.0)
        
        // Test flow start
        await coordinator.start()
        XCTAssertEqual(coordinator.currentStepIndex, 0)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step1")
        XCTAssertEqual(coordinator.flowState, .inProgress)
        XCTAssertEqual(coordinator.progress, 1.0/3.0, accuracy: 0.01)
        
        // Test step progression
        try await coordinator.next()
        XCTAssertEqual(coordinator.currentStepIndex, 1)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step2")
        XCTAssertEqual(coordinator.progress, 2.0/3.0, accuracy: 0.01)
        
        try await coordinator.next()
        XCTAssertEqual(coordinator.currentStepIndex, 2)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step3")
        XCTAssertEqual(coordinator.progress, 1.0, accuracy: 0.01)
        
        // Test flow completion
        try await coordinator.next()
        XCTAssertEqual(coordinator.flowState, .completed)
        XCTAssertEqual(coordinator.progress, 1.0)
    }
    
    func testFlowCoordinatorBackwardNavigation() async throws {
        // Test backward navigation within flows
        struct TestFlow: NavigationFlow {
            let identifier: String = "test"
            let steps: [FlowStep] = [
                SimpleStep(id: "step1", order: 0),
                SimpleStep(id: "step2", order: 1),
                SimpleStep(id: "step3", order: 2)
            ]
            
            var metadata: FlowMetadata {
                FlowMetadata(title: "Test Flow", description: "Test", estimatedDuration: 60)
            }
        }
        
        let flow = TestFlow()
        let coordinator = FlowCoordinator(flow: flow)
        
        // Start and advance to step 2
        await coordinator.start()
        try await coordinator.next()
        try await coordinator.next()
        
        XCTAssertEqual(coordinator.currentStepIndex, 2)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step3")
        
        // Test backward navigation
        try await coordinator.previous()
        XCTAssertEqual(coordinator.currentStepIndex, 1)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step2")
        
        try await coordinator.previous()
        XCTAssertEqual(coordinator.currentStepIndex, 0)
        XCTAssertEqual(coordinator.currentStep?.identifier, "step1")
        
        // Test cannot go before first step
        do {
            try await coordinator.previous()
            XCTFail("Should not be able to go before first step")
        } catch FlowError.invalidNavigation {
            // Expected
        }
    }
    
    func testFlowStateManagement() throws {
        // Test flow data persistence and management
        let flowData = FlowData()
        
        // Test data storage and retrieval
        flowData.set("username", value: "testuser")
        flowData.set("email", value: "test@example.com")
        flowData.set("profile", value: UserProfile(name: "Test User", isComplete: true))
        
        XCTAssertEqual(flowData.get("username") as? String, "testuser")
        XCTAssertEqual(flowData.get("email") as? String, "test@example.com")
        
        let profile = flowData.get("profile") as? UserProfile
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.name, "Test User")
        XCTAssertTrue(profile?.isComplete ?? false)
        
        // Test data removal
        flowData.remove("email")
        XCTAssertNil(flowData.get("email"))
        
        // Test data serialization for persistence
        let serializedData = try flowData.serialize()
        XCTAssertNotNil(serializedData)
        
        let restoredData = try FlowData.deserialize(from: serializedData)
        XCTAssertEqual(restoredData.get("username") as? String, "testuser")
        XCTAssertNil(restoredData.get("email")) // Removed data should not be restored
    }
    
    func testConditionalFlowSteps() throws {
        // Test conditional step navigation based on flow data
        struct ConditionalStep: FlowStep {
            let identifier: String = "conditional"
            let isRequired: Bool = true
            let canSkip: Bool = true
            let order: Int = 1
            
            func shouldSkip(data: FlowData) -> Bool {
                return data.get("skipCondition") as? Bool ?? false
            }
            
            func validate(data: FlowData) -> ValidationResult {
                return .success
            }
            
            func onEnter(data: FlowData) async {}
            func onExit(data: FlowData) async throws {}
        }
        
        let step = ConditionalStep()
        
        // Test step should not be skipped by default
        let defaultData = FlowData()
        XCTAssertFalse(step.shouldSkip(data: defaultData))
        
        // Test step should be skipped when condition is true
        let skipData = FlowData()
        skipData.set("skipCondition", value: true)
        XCTAssertTrue(step.shouldSkip(data: skipData))
    }
    
    func testFlowValidationErrors() async throws {
        // Test validation error handling in flows
        struct ValidatingStep: FlowStep {
            let identifier: String = "validating"
            let isRequired: Bool = true
            let canSkip: Bool = false
            let order: Int = 0
            
            func validate(data: FlowData) -> ValidationResult {
                guard let value = data.get("requiredValue") as? String,
                      !value.isEmpty else {
                    return .failure(message: "Required value is missing")
                }
                return .success
            }
            
            func onEnter(data: FlowData) async {}
            func onExit(data: FlowData) async throws {
                let result = validate(data: data)
                if case .failure(let message) = result {
                    throw FlowError.validationFailed(message)
                }
            }
        }
        
        struct TestFlow: NavigationFlow {
            let identifier: String = "validation_test"
            let steps: [FlowStep] = [ValidatingStep()]
            
            var metadata: FlowMetadata {
                FlowMetadata(title: "Validation Test", description: "Test", estimatedDuration: 30)
            }
        }
        
        let flow = TestFlow()
        let coordinator = FlowCoordinator(flow: flow)
        
        await coordinator.start()
        
        // Test validation failure prevents progression
        do {
            try await coordinator.next()
            XCTFail("Expected validation error")
        } catch FlowError.validationFailed(let message) {
            XCTAssertEqual(message, "Required value is missing")
        }
        
        // Test validation success allows progression
        coordinator.flowData.set("requiredValue", value: "valid")
        try await coordinator.next()
        XCTAssertEqual(coordinator.flowState, .completed)
    }
    
    func testNavigationServiceFlowIntegration() async throws {
        // Test integration with NavigationService
        struct TestFlow: NavigationFlow {
            let identifier: String = "integration_test"
            let steps: [FlowStep] = [SimpleStep(id: "step1", order: 0)]
            
            var metadata: FlowMetadata {
                FlowMetadata(title: "Integration Test", description: "Test", estimatedDuration: 30)
            }
        }
        
        let navigationService = NavigationService()
        let flow = TestFlow()
        
        // Test starting a flow through NavigationService
        let result = await navigationService.startFlow(flow)
        
        switch result {
        case .success:
            XCTAssertNotNil(navigationService.currentFlow)
            XCTAssertEqual(navigationService.currentFlow?.identifier, "integration_test")
        case .failure(let error):
            XCTFail("Flow start should succeed: \(error)")
        }
        
        // Test completing current flow
        let completeResult = await navigationService.completeCurrentFlow()
        
        switch completeResult {
        case .success:
            XCTAssertNil(navigationService.currentFlow)
        case .failure(let error):
            XCTFail("Flow completion should succeed: \(error)")
        }
    }
}

// MARK: - Supporting Types for Flow Pattern Tests

/// Basic flow metadata
struct FlowMetadata: Equatable {
    let title: String
    let description: String
    let estimatedDuration: TimeInterval
}

/// Flow state enumeration
enum FlowState: Equatable {
    case notStarted
    case inProgress
    case completed
    case cancelled
}

/// Validation result for flow steps
enum ValidationResult: Equatable {
    case success
    case failure(message: String)
}

/// Flow-specific errors
enum FlowError: Error, Equatable {
    case validationFailed(String)
    case invalidNavigation(String)
    case stepNotFound(String)
    case flowNotActive
}

/// Flow data container for state management
class FlowData {
    private var data: [String: Any] = [:]
    
    func set(_ key: String, value: Any) {
        data[key] = value
    }
    
    func get(_ key: String) -> Any? {
        return data[key]
    }
    
    func remove(_ key: String) {
        data.removeValue(forKey: key)
    }
    
    func serialize() throws -> Data {
        // Simplified serialization for testing
        let stringData = data.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else if let profile = value as? UserProfile {
                return "\(profile.name)|\(profile.isComplete)"
            }
            return nil
        }
        return try JSONSerialization.data(withJSONObject: stringData)
    }
    
    static func deserialize(from data: Data) throws -> FlowData {
        let flowData = FlowData()
        let stringData = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
        
        for (key, value) in stringData {
            if key == "profile" {
                let components = value.split(separator: "|")
                if components.count == 2 {
                    let name = String(components[0])
                    let isComplete = String(components[1]) == "true"
                    flowData.set(key, value: UserProfile(name: name, isComplete: isComplete))
                }
            } else {
                flowData.set(key, value: value)
            }
        }
        
        return flowData
    }
}

/// Simple user profile for testing
struct UserProfile: Equatable {
    let name: String
    let isComplete: Bool
}

/// Simple step implementation for testing
struct SimpleStep: FlowStep {
    let identifier: String
    let isRequired: Bool = true
    let canSkip: Bool = false
    let order: Int
    
    init(id: String, order: Int) {
        self.identifier = id
        self.order = order
    }
    
    func validate(data: FlowData) -> ValidationResult {
        return .success
    }
    
    func onEnter(data: FlowData) async {}
    func onExit(data: FlowData) async throws {}
}

// MARK: - Protocol Definitions (Will be implemented in GREEN phase)

/// Protocol for defining navigation flows
protocol NavigationFlow {
    var identifier: String { get }
    var steps: [FlowStep] { get }
    var metadata: FlowMetadata { get }
}

/// Protocol for individual flow steps
protocol FlowStep {
    var identifier: String { get }
    var isRequired: Bool { get }
    var canSkip: Bool { get }
    var order: Int { get }
    
    func validate(data: FlowData) -> ValidationResult
    func onEnter(data: FlowData) async
    func onExit(data: FlowData) async throws
}

/// Optional protocol for conditional steps
extension FlowStep {
    func shouldSkip(data: FlowData) -> Bool {
        return false
    }
}

/// Flow coordinator for managing flow lifecycle
class FlowCoordinator {
    let flow: NavigationFlow
    let flowData: FlowData
    
    private(set) var currentStepIndex: Int = -1
    private(set) var flowState: FlowState = .notStarted
    
    var currentStep: FlowStep? {
        guard currentStepIndex >= 0 && currentStepIndex < flow.steps.count else {
            return nil
        }
        return flow.steps[currentStepIndex]
    }
    
    var progress: Double {
        guard !flow.steps.isEmpty else { return 0.0 }
        if flowState == .completed {
            return 1.0
        }
        return max(0.0, Double(currentStepIndex + 1) / Double(flow.steps.count))
    }
    
    init(flow: NavigationFlow) {
        self.flow = flow
        self.flowData = FlowData()
    }
    
    func start() async {
        currentStepIndex = 0
        flowState = .inProgress
        
        if let currentStep = currentStep {
            await currentStep.onEnter(data: flowData)
        }
    }
    
    func next() async throws {
        guard flowState == .inProgress else {
            throw FlowError.flowNotActive
        }
        
        // Validate current step before moving to next
        if let currentStep = currentStep {
            try await currentStep.onExit(data: flowData)
        }
        
        // Move to next step
        currentStepIndex += 1
        
        if currentStepIndex >= flow.steps.count {
            // Flow completed
            flowState = .completed
        } else {
            // Enter next step
            if let nextStep = currentStep {
                await nextStep.onEnter(data: flowData)
            }
        }
    }
    
    func previous() async throws {
        guard flowState == .inProgress else {
            throw FlowError.flowNotActive
        }
        
        guard currentStepIndex > 0 else {
            throw FlowError.invalidNavigation("Cannot go before first step")
        }
        
        // Exit current step
        if let currentStep = currentStep {
            try await currentStep.onExit(data: flowData)
        }
        
        // Move to previous step
        currentStepIndex -= 1
        
        if let previousStep = currentStep {
            await previousStep.onEnter(data: flowData)
        }
    }
}

/// NavigationService extension for flow support
extension NavigationService {
    var currentFlow: NavigationFlow? {
        // Will be implemented in GREEN phase
        return nil
    }
    
    func startFlow(_ flow: NavigationFlow) async -> Result<Void, AxiomError> {
        // Will be implemented in GREEN phase
        return .success(())
    }
    
    func completeCurrentFlow() async -> Result<Void, AxiomError> {
        // Will be implemented in GREEN phase
        return .success(())
    }
}