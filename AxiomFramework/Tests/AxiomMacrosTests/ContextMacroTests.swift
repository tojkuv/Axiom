import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AxiomMacros

// MARK: - TDD Red Phase: Writing failing tests for @Context macro

final class ContextMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Context": ContextMacro.self,
    ]
    
    // Test 1: Basic @Context macro expansion
    func testBasicContextMacroExpansion() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            class UserContext {
                let userClient: UserClient
                
                init(userClient: UserClient) {
                    self.userClient = userClient
                }
            }
            """,
            expandedSource: """
            @MainActor
            class UserContext {
                let userClient: UserClient
                
                init(userClient: UserClient) {
                    self.userClient = userClient
                }

                struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }

                struct PresentationActions {
                    // TODO: Add action closures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: @Context with existing state and actions
    func testContextMacroWithExistingStateAndActions() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            class ProductContext: BaseContext<ProductContext.DerivedState, ProductContext.PresentationActions> {
                struct DerivedState: Axiom.State {
                    let productName: String
                    let price: String
                }
                
                struct PresentationActions {
                    let updatePrice: (Double) async -> Void
                }
                
                private let productClient: ProductClient
                
                // Reducer for the action
                private func updatePrice(_ newPrice: Double) async {
                    // Implementation
                }
            }
            """,
            expandedSource: """
            @MainActor
            class ProductContext: BaseContext<ProductContext.DerivedState, ProductContext.PresentationActions> {
                struct DerivedState: Axiom.State {
                    let productName: String
                    let price: String
                }
                
                struct PresentationActions {
                    let updatePrice: (Double) async -> Void
                }
                
                private let productClient: ProductClient
                
                // Reducer for the action
                private func updatePrice(_ newPrice: Double) async {
                    // Implementation
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: @Context applied to non-class should produce diagnostic
    func testContextMacroOnNonClassProducesDiagnostic() throws {
        assertMacroExpansion(
            """
            @Context
            struct MyContext {
            }
            """,
            expandedSource: """
            struct MyContext {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Context can only be applied to class declarations",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Replace 'struct' with 'class'")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 4: @Context without @MainActor still works
    func testContextMacroWithoutMainActor() throws {
        assertMacroExpansion(
            """
            @Context
            class OrderContext {
                let orderClient: OrderClient
            }
            """,
            expandedSource: """
            class OrderContext {
                let orderClient: OrderClient

                struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }

                struct PresentationActions {
                    // TODO: Add action closures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 5: @Context with action-reducer validation
    func testContextMacroWithActionReducerValidation() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            class CartContext {
                struct PresentationActions {
                    let addItem: (String) async -> Void
                    let removeItem: (String) async -> Void
                    let updateQuantity: (String, Int) async -> Void
                }
                
                // Missing reducers for removeItem and updateQuantity
                private func addItem(_ itemId: String) async {
                    // Implementation
                }
            }
            """,
            expandedSource: """
            @MainActor
            class CartContext {
                struct PresentationActions {
                    let addItem: (String) async -> Void
                    let removeItem: (String) async -> Void
                    let updateQuantity: (String, Int) async -> Void
                }
                
                // Missing reducers for removeItem and updateQuantity
                private func addItem(_ itemId: String) async {
                    // Implementation
                }

                struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Missing reducer for action 'removeItem'",
                    line: 1,
                    column: 1
                ),
                DiagnosticSpec(
                    message: "Missing reducer for action 'updateQuantity'",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
    
    // Test 6: @Context with custom base class
    func testContextMacroWithCustomBaseClass() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            class SettingsContext: CustomBaseContext {
                let settingsClient: SettingsClient
            }
            """,
            expandedSource: """
            @MainActor
            class SettingsContext: CustomBaseContext {
                let settingsClient: SettingsClient

                struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }

                struct PresentationActions {
                    // TODO: Add action closures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 7: @Context with public modifier
    func testContextMacroWithPublicModifier() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            public class AppContext {
                public let appClient: AppClient
                
                public init(appClient: AppClient) {
                    self.appClient = appClient
                }
            }
            """,
            expandedSource: """
            @MainActor
            public class AppContext {
                public let appClient: AppClient
                
                public init(appClient: AppClient) {
                    self.appClient = appClient
                }

                public struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }

                public struct PresentationActions {
                    // TODO: Add action closures
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 8: @Context with final modifier
    func testContextMacroWithFinalModifier() throws {
        assertMacroExpansion(
            """
            @Context
            @MainActor
            final class SessionContext {
                private let sessionClient: SessionClient
            }
            """,
            expandedSource: """
            @MainActor
            final class SessionContext {
                private let sessionClient: SessionClient

                struct DerivedState: Axiom.State {
                    // TODO: Add derived state properties
                }

                struct PresentationActions {
                    // TODO: Add action closures
                }
            }
            """,
            macros: testMacros
        )
    }
}