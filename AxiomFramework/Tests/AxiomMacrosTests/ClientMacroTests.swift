import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @Client macro

final class ClientMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Client": ClientMacro.self,
    ]
    
    // Test 1: Basic @Client macro expansion
    func testBasicClientMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Client(state: UserProfileState)
            actor UserProfileClient {
            }
            """,
            expandedSource: """
            actor UserProfileClient {

                typealias State = UserProfileState

                private (set) var state = UserProfileState()

                func updateState(_ transform: (inout UserProfileState) -> Void) async {
                    transform(&state)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Client with existing properties
    func testClientMacroWithExistingProperties() throws {
        assertMacroExpansion(
            """
            @Client(state: CounterState)
            actor CounterClient {
                let id = UUID()
                private let logger = Logger()
            }
            """,
            expandedSource: """
            actor CounterClient {
                let id = UUID()
                private let logger = Logger()

                typealias State = CounterState

                private (set) var state = CounterState()

                func updateState(_ transform: (inout CounterState) -> Void) async {
                    transform(&state)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @Client applied to non-actor should produce diagnostic
    func testClientMacroOnNonActorProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Client(state: MyState)
            class MyClient {
            }
            """,
            expandedSource: """
            class MyClient {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Client can only be applied to actor declarations",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Replace 'class' with 'actor'")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 4: @Client without state parameter should produce diagnostic
    func testClientMacroWithoutStateParameter() throws {
        assertMacroExpansion(
            """
            @Client
            actor MyClient {
            }
            """,
            expandedSource: """
            actor MyClient {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Client requires a 'state' parameter specifying the State type",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 5: @Client with custom initializer should not generate state initialization
    func testClientMacroWithCustomInitializer() throws {
        assertMacroExpansion(
            """
            @Client(state: AppState)
            actor AppClient {
                init(initialState: AppState) {
                    self.state = initialState
                }
            }
            """,
            expandedSource: """
            actor AppClient {
                init(initialState: AppState) {
                    self.state = initialState
                }

                typealias State = AppState

                private (set) var state: AppState

                func updateState(_ transform: (inout AppState) -> Void) async {
                    transform(&state)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 6: @Client with existing updateState method should not duplicate
    func testClientMacroWithExistingUpdateState() throws {
        assertMacroExpansion(
            """
            @Client(state: MyState)
            actor MyClient {
                func updateState(_ transform: (inout MyState) -> Void) async {
                    // Custom implementation
                    transform(&state)
                    print("State updated")
                }
            }
            """,
            expandedSource: """
            actor MyClient {
                func updateState(_ transform: (inout MyState) -> Void) async {
                    // Custom implementation
                    transform(&state)
                    print("State updated")
                }

                typealias State = MyState

                private (set) var state = MyState()
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 7: @Client with complex state type
    func testClientMacroWithComplexStateType() throws {
        assertMacroExpansion(
            """
            @Client(state: Feature.Module.ComplexState)
            actor ComplexClient {
            }
            """,
            expandedSource: """
            actor ComplexClient {

                typealias State = Feature.Module.ComplexState

                private (set) var state = Feature.Module.ComplexState()

                func updateState(_ transform: (inout Feature.Module.ComplexState) -> Void) async {
                    transform(&state)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @Client preserves access control modifiers
    func testClientMacroPreservesAccessControl() throws {
        assertMacroExpansion(
            """
            @Client(state: PublicState)
            public actor PublicClient {
            }
            """,
            expandedSource: """
            public actor PublicClient {

                public typealias State = PublicState

                private (set) var state = PublicState()

                public func updateState(_ transform: (inout PublicState) -> Void) async {
                    transform(&state)
                }
            }
            """,
            macros: testMacros
        )
    }
}