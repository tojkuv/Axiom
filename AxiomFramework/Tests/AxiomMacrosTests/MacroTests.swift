import XCTest
import SwiftSyntaxMacrosTestSupport
import SwiftSyntax
import SwiftSyntaxBuilder
import AxiomMacros

final class MacroTests: XCTestCase {
    
    // MARK: - Context Macro Tests
    
    func testContextMacroGeneratesLifecycleManagement() throws {
        assertMacroExpansion(
            """
            @Context(observing: TaskClient.self)
            class TaskContext: AutoObservingContext<TaskClient> {
                // Custom implementation
            }
            """,
            expandedSource: """
            class TaskContext: AutoObservingContext<TaskClient> {
                // Custom implementation
                
                // Generated lifecycle management
                @Published private var updateTrigger = UUID()
                public private(set) var isActive = false
                private var appearanceCount = 0
                private var observationTask: Task<Void, Never>?
                
                public override func performAppearance() async {
                    guard appearanceCount == 0 else { return }
                    appearanceCount += 1
                    isActive = true
                    startObservation()
                    await super.performAppearance()
                }
                
                public override func performDisappearance() async {
                    stopObservation()
                    isActive = false
                    await super.performDisappearance()
                }
                
                private func startObservation() {
                    observationTask = Task { [weak self] in
                        guard let self = self else { return }
                        for await state in await self.client.stateStream {
                            await self.handleStateUpdate(state)
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                public func triggerUpdate() {
                    updateTrigger = UUID()
                }
            }
            """,
            macros: ["Context": ContextMacro.self]
        )
    }
    
    func testContextMacroWithCustomStateHandling() throws {
        assertMacroExpansion(
            """
            @Context(observing: UserClient.self)
            class UserContext: AutoObservingContext<UserClient> {
                override func handleStateUpdate(_ state: UserClient.StateType) async {
                    // Custom state handling
                    print("State updated: \\(state)")
                    triggerUpdate()
                }
            }
            """,
            expandedSource: """
            class UserContext: AutoObservingContext<UserClient> {
                override func handleStateUpdate(_ state: UserClient.StateType) async {
                    // Custom state handling
                    print("State updated: \\(state)")
                    triggerUpdate()
                }
                
                // Generated lifecycle management
                @Published private var updateTrigger = UUID()
                public private(set) var isActive = false
                private var appearanceCount = 0
                private var observationTask: Task<Void, Never>?
                
                public override func performAppearance() async {
                    guard appearanceCount == 0 else { return }
                    appearanceCount += 1
                    isActive = true
                    startObservation()
                    await super.performAppearance()
                }
                
                public override func performDisappearance() async {
                    stopObservation()
                    isActive = false
                    await super.performDisappearance()
                }
                
                private func startObservation() {
                    observationTask = Task { [weak self] in
                        guard let self = self else { return }
                        for await state in await self.client.stateStream {
                            await self.handleStateUpdate(state)
                        }
                    }
                }
                
                private func stopObservation() {
                    observationTask?.cancel()
                    observationTask = nil
                }
                
                public func triggerUpdate() {
                    updateTrigger = UUID()
                }
            }
            """,
            macros: ["Context": ContextMacro.self]
        )
    }
}