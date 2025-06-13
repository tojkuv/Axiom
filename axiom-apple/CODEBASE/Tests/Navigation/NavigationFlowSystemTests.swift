import XCTest
@testable import Axiom
import SwiftUI

final class NavigationFlowSystemTests: XCTestCase {
    
    func testBasicFlowCreation() async throws {
        // Test that we can create a basic flow
        struct TestFlow: NavigationFlowProtocol {
            struct FlowData {
                var name: String = ""
            }
            
            var flowData = FlowData()
            
            var body: some FlowStep {
                Step("welcome") {
                    Text("Welcome")
                }
                
                Step("profile") {
                    Text("Profile")
                }
            }
        }
        
        let flow = TestFlow()
        let steps = flow.body.flattened()
        
        XCTAssertEqual(steps.count, 2)
        XCTAssertEqual(steps[0].id, "welcome")
        XCTAssertEqual(steps[1].id, "profile")
    }
    
    func testFlowStorage() throws {
        // Test that flow storage works
        let storage = FlowStorage()
        
        // Test storing and retrieving values
        storage.set("name", value: "John")
        storage.set("age", value: 30)
        
        let name: String = storage.get("name", default: "")
        let age: Int = storage.get("age", default: 0)
        let unknownValue: String = storage.get("unknown", default: "default")
        
        XCTAssertEqual(name, "John")
        XCTAssertEqual(age, 30)
        XCTAssertEqual(unknownValue, "default")
    }
    
    func testFlowStatePropertyWrapper() throws {
        // Test that @FlowState property wrapper works
        let storage = FlowStorage()
        
        struct Container {
            @FlowState var username: String = ""
            @FlowState var isEnabled: Bool = false
            
            init(storage: FlowStorage) {
                _username = FlowState(key: "username", storage: storage, initialValue: "")
                _isEnabled = FlowState(key: "isEnabled", storage: storage, initialValue: false)
            }
        }
        
        var container = Container(storage: storage)
        
        // Test initial values
        XCTAssertEqual(container.username, "")
        XCTAssertEqual(container.isEnabled, false)
        
        // Test setting values
        container.username = "john_doe"
        container.isEnabled = true
        
        XCTAssertEqual(container.username, "john_doe")
        XCTAssertEqual(container.isEnabled, true)
        
        // Test that values persist in storage
        let retrievedName: String = storage.get("username", default: "")
        let retrievedEnabled: Bool = storage.get("isEnabled", default: false)
        
        XCTAssertEqual(retrievedName, "john_doe")
        XCTAssertEqual(retrievedEnabled, true)
    }
    
    func testFlowCoordinatorCreation() async throws {
        // Test that we can create a flow coordinator
        struct SimpleFlow: NavigationFlowProtocol {
            struct FlowData {
                var step: Int = 0
            }
            
            var flowData = FlowData()
            
            var body: some FlowStep {
                Step("step1") {
                    Text("Step 1")
                }
                
                Step("step2") {
                    Text("Step 2")
                }
            }
        }
        
        let flow = SimpleFlow()
        let navigationService = NavigationService()
        
        await MainActor.run {
            let coordinator = FlowCoordinator(flow: flow, navigator: navigationService)
            
            // Test initial state
            XCTAssertEqual(coordinator.currentStep, 0)
            XCTAssertTrue(coordinator.canGoNext)
            XCTAssertFalse(coordinator.canGoBack)
            XCTAssertEqual(coordinator.progress, 0.5, accuracy: 0.01) // 1/2 steps
        }
    }
    
    func testNavigationServiceFlowIntegration() async throws {
        // Test that NavigationService can work with flows
        struct TestFlow: NavigationFlowProtocol {
            struct FlowData {}
            var flowData = FlowData()
            
            var body: some FlowStep {
                Step("test") {
                    Text("Test")
                }
            }
        }
        
        let navigationService = NavigationService()
        let flow = TestFlow()
        
        let result = await navigationService.startFlow(flow)
        
        switch result {
        case .success():
            // Flow started successfully
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Flow should start successfully: \(error)")
        }
    }
    
    func testStepModification() throws {
        // Test step modification (skippable, onComplete)
        let baseStep = Step("test") {
            Text("Test")
        }
        
        // Test skippable
        let skippableStep = baseStep.skippable(when: true)
        XCTAssertTrue(skippableStep.skipCondition)
        XCTAssertEqual(skippableStep.id, "test")
        
        // Test completion handler
        var completionCalled = false
        let stepWithCompletion = baseStep.onComplete {
            completionCalled = true
        }
        
        if let modifiedStep = stepWithCompletion as? ModifiedFlowStep<Step<Text>> {
            modifiedStep.executeCompletion()
            XCTAssertTrue(completionCalled)
        }
    }
    
    func testCodeReductionExample() throws {
        // Demonstrate the code reduction achieved
        
        // Before: Manual flow management would require extensive boilerplate
        // After: Declarative flow definition
        struct OnboardingFlow: NavigationFlowProtocol {
            struct FlowData {
                var userName: String = ""
                var isGuest: Bool = false
            }
            
            var flowData = FlowData()
            
            var body: some FlowStep {
                Step("welcome") {
                    Text("Welcome")
                }
                
                Step("profile") {
                    Text("Profile Setup")
                }
                .skippable(when: flowData.isGuest)
                
                Step("complete") {
                    Text("Complete")
                }
                .onComplete {
                    // Analytics or completion logic
                }
            }
        }
        
        let flow = OnboardingFlow()
        let steps = flow.body.flattened()
        
        // Verify flow structure
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].id, "welcome")
        XCTAssertEqual(steps[1].id, "profile")
        XCTAssertEqual(steps[2].id, "complete")
        
        // This declarative approach significantly reduces boilerplate
        // compared to manual coordinator patterns
    }
}