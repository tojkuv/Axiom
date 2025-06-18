import Foundation
import XCTest
import AxiomCore

public struct TestScenarios {
    
    public static func runCapabilityActivationTest<T: AxiomCapability>(
        capability: T,
        expectedActivation: Bool = true,
        timeout: TimeInterval = 5.0
    ) async throws {
        let _ = await capability.isAvailable
        
        if expectedActivation {
            try await capability.activate()
            let isAvailableAfterActivation = await capability.isAvailable
            XCTAssertTrue(isAvailableAfterActivation, "Capability should be available after activation")
        } else {
            do {
                try await capability.activate()
                XCTFail("Capability activation should have failed")
            } catch {
                // Expected failure
            }
        }
    }
    
    public static func runStorageCapabilityTest<T: Codable & Equatable & Sendable>(
        storageCapability: MockStorageCapability,
        testObject: T,
        path: String = "test.json"
    ) async throws {
        try await storageCapability.activate()
        
        let existsBeforeSave = await storageCapability.exists(at: path)
        XCTAssertFalse(existsBeforeSave, "File should not exist before saving")
        
        try await storageCapability.save(testObject, to: path)
        
        let existsAfterSave = await storageCapability.exists(at: path)
        XCTAssertTrue(existsAfterSave, "File should exist after saving")
        
        let loadedObject = try await storageCapability.load(T.self, from: path)
        XCTAssertEqual(loadedObject, testObject, "Loaded object should equal saved object")
        
        try await storageCapability.delete(at: path)
        
        let existsAfterDelete = await storageCapability.exists(at: path)
        XCTAssertFalse(existsAfterDelete, "File should not exist after deletion")
    }
    
    public static func runPerformanceTest<T>(
        operation: () async throws -> T,
        expectedMaxDuration: TimeInterval,
        iterations: Int = 1
    ) async throws -> [TimeInterval] {
        var durations: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let duration = endTime - startTime
            durations.append(duration)
            
            XCTAssertLessThanOrEqual(
                duration,
                expectedMaxDuration,
                "Operation took \(duration)s, expected <= \(expectedMaxDuration)s"
            )
        }
        
        return durations
    }
    
    public static func runMemoryLeakTest<T>(
        objectCreation: () -> T,
        iterations: Int = 100
    ) async {
        weak var weakReference: AnyObject?
        
        autoreleasepool {
            for _ in 0..<iterations {
                let object = objectCreation()
                if let anyObject = object as? AnyObject {
                    weakReference = anyObject
                }
            }
        }
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertNil(weakReference, "Object should be deallocated after going out of scope")
    }
    
    public static func runConcurrencyTest<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T,
        concurrentCount: Int = 10,
        timeout: TimeInterval = 10.0
    ) async throws -> [T] {
        return try await withThrowingTaskGroup(of: T.self) { group in
            for _ in 0..<concurrentCount {
                group.addTask {
                    return try await operation()
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    public static func runErrorRecoveryTest<T>(
        operation: () async throws -> T,
        expectedError: Error,
        maxRetries: Int = 3
    ) async throws -> T? {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempts += 1
                
                if attempts < maxRetries {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
        
        if let lastError = lastError {
            throw lastError
        }
        
        return nil
    }
    
    public static func runStateConsistencyTest(
        initialState: StudioApplicationState,
        actions: [StudioAction],
        expectedFinalState: StudioApplicationState
    ) async throws {
        var currentState = initialState
        
        for action in actions {
            currentState = try await applyAction(action, to: currentState)
        }
        
        XCTAssertEqual(
            currentState.personalInfo.tasks.count,
            expectedFinalState.personalInfo.tasks.count,
            "Task count should match expected state"
        )
        
        XCTAssertEqual(
            currentState.personalInfo.contacts.count,
            expectedFinalState.personalInfo.contacts.count,
            "Contact count should match expected state"
        )
    }
    
    private static func applyAction(_ action: StudioAction, to state: StudioApplicationState) async throws -> StudioApplicationState {
        switch action {
        case .personalInfo(let personalInfoAction):
            let newPersonalInfoState = try await applyPersonalInfoAction(personalInfoAction, to: state.personalInfo)
            return StudioApplicationState(
                personalInfo: newPersonalInfoState,
                healthLocation: state.healthLocation,
                contentProcessor: state.contentProcessor,
                mediaHub: state.mediaHub,
                performance: state.performance,
                navigation: state.navigation
            )
        case .navigation(let navigationAction):
            let newNavigationState = try await applyNavigationAction(navigationAction, to: state.navigation)
            return StudioApplicationState(
                personalInfo: state.personalInfo,
                healthLocation: state.healthLocation,
                contentProcessor: state.contentProcessor,
                mediaHub: state.mediaHub,
                performance: state.performance,
                navigation: newNavigationState
            )
        default:
            return state
        }
    }
    
    private static func applyPersonalInfoAction(_ action: PersonalInfoAction, to state: PersonalInfoState) async throws -> PersonalInfoState {
        switch action {
        case .createTask(let task):
            var newTasks = state.tasks
            newTasks.append(task)
            return PersonalInfoState(
                tasks: newTasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: state.isLoading,
                error: state.error
            )
        case .deleteTask(let taskId):
            let newTasks = state.tasks.filter { $0.id != taskId }
            return PersonalInfoState(
                tasks: newTasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: state.isLoading,
                error: state.error
            )
        case .setLoading(let isLoading):
            return PersonalInfoState(
                tasks: state.tasks,
                calendarEvents: state.calendarEvents,
                contacts: state.contacts,
                reminders: state.reminders,
                isLoading: isLoading,
                error: state.error
            )
        default:
            return state
        }
    }
    
    private static func applyNavigationAction(_ action: NavigationAction, to state: NavigationState) async throws -> NavigationState {
        switch action {
        case .navigate(let route):
            var newStack = state.navigationStack
            newStack.append(state.currentRoute)
            return NavigationState(
                currentRoute: route,
                navigationStack: newStack,
                deepLinkingContext: state.deepLinkingContext
            )
        case .goBack:
            guard !state.navigationStack.isEmpty else { return state }
            var newStack = state.navigationStack
            let previousRoute = newStack.removeLast()
            return NavigationState(
                currentRoute: previousRoute,
                navigationStack: newStack,
                deepLinkingContext: state.deepLinkingContext
            )
        default:
            return state
        }
    }
}