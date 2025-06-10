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
    
    // MARK: - Capability Macro Tests
    
    func testCapabilityMacroGeneratesLifecycleManagement() throws {
        assertMacroExpansion(
            """
            @Capability(.network)
            actor NetworkCapability {
                func fetchData(from url: URL) async throws -> Data {
                    return try await URLSession.shared.data(from: url).0
                }
            }
            """,
            expandedSource: """
            actor NetworkCapability {
                func fetchData(from url: URL) async throws -> Data {
                    return try await URLSession.shared.data(from: url).0
                }
                
                // Note: Add 'extension NetworkCapability: ExtendedCapability {}' to conform to the protocol
                
                private var _state: CapabilityState = .unknown
                
                private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
                
                public var state: CapabilityState {
                    get async { _state }
                }
                
                public var stateStream: AsyncStream<CapabilityState> {
                    get async {
                        AsyncStream { continuation in
                            self.stateStreamContinuation = continuation
                            continuation.yield(_state)
                        }
                    }
                }
                
                public var isAvailable: Bool {
                    get async { await state == .available }
                }
                
                public func initialize() async throws {
                    await transitionTo(.available)
                }
                
                public func terminate() async {
                    await transitionTo(.unavailable)
                    stateStreamContinuation?.finish()
                }
                
                public func isSupported() async -> Bool {
                    return true
                }
                
                public func requestPermission() async throws {
                    // Network capability doesn't require permission
                }
                
                private func transitionTo(_ newState: CapabilityState) async {
                    guard _state != newState else { return }
                    _state = newState
                    stateStreamContinuation?.yield(newState)
                }
            }
            """,
            macros: ["Capability": CapabilityMacro.self]
        )
    }
}